import 'dart:io';
import 'package:engineering_project/assets/AI/ai_chat_screen.dart';
import 'package:engineering_project/pages/login_page.dart';
import 'package:engineering_project/pages/register_page.dart';
import 'package:engineering_project/pages/wallet.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:engineering_project/l10n/app_localizations.dart';
import 'package:engineering_project/providers/language_provider.dart';
import 'package:confetti/confetti.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/cupertino.dart';

import 'theme_notifier.dart';
import 'address_screen.dart';
import 'past_orders_page.dart';
import 'welcome_screen.dart';
import '../admin-panel/admin_main.dart';

const String _kSpecialModeActiveKey = 'special_mode_active';
const String _kSpecialThemeKey = 'special_theme';

class LanguageSelector extends StatelessWidget {
  const LanguageSelector({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeNotifier = Provider.of<ThemeNotifier>(context);

    return PopupMenuButton<String>(
      icon: Icon(
        Icons.language,
        color: isDark ? Colors.white : Colors.black87,
      ),
      onSelected: (String languageCode) {
        languageProvider.changeLanguage(languageCode);
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        PopupMenuItem<String>(
          value: 'en',
          child: Row(
            children: [
              Text('🇬🇧 '),
              Text(l10n.english),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'tr',
          child: Row(
            children: [
              Text('🇹🇷 '),
              Text(l10n.turkish),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'ar',
          child: Row(
            children: [
              Text('🇸🇦 '),
              Text(l10n.arabic),
            ],
          ),
        ),
      ],
    );
  }
}

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String? name;
  String? surname;
  String? imageUrl;
  String? role;
  bool isLoading = true;
  bool isUploading = false;
  String? referralCode;
  bool _showFloatingButton = true;
  bool passwordlessEnabled = false;
  bool isPasswordlessLoading = false;

  final ImagePicker _picker = ImagePicker();

  // Special Mode toggle variables
  int _tapCount = 0;
  bool _showSpecialModeToggle = false;
  bool isColorPickerVisible = false;

  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    _checkAISettings();
    fetchProfileData();
    _loadSpecialModePreferences();
    _loadPasswordlessSetting();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    FirebaseFirestore.instance
        .collection('settings')
        .doc('ai_settings')
        .snapshots()
        .listen((doc) {
          if (mounted) {
            setState(() {
              _showFloatingButton =
                  doc.exists && (doc.data()?['showFloatingButton'] ?? true);
            });
          }
        });
  }

  Future<void> _checkAISettings() async {
    try {
      final doc =
          await FirebaseFirestore.instance.collection('settings').doc('ai_settings').get();

      if (mounted) {
        setState(() {
          _showFloatingButton =
              doc.exists && (doc.data()?['showFloatingButton'] ?? true);
        });
      }
    } catch (e) {
      print('Error checking AI settings: $e');
    }
  }

  void _handleProfileTitleTap() {
    setState(() {
      _tapCount++;
      if (_tapCount >= 3) {
        final themeNotifier = Provider.of<ThemeNotifier>(context, listen: false); 
        _showSpecialModeToggle = true; // Always show toggle when condition met
        
        // If special mode is already active from a previous session, show colors immediately
        if (themeNotifier.isSpecialModeActive) {
          isColorPickerVisible = true;
          print("Profile title tapped 3 times. Special mode was already active. Showing color picker.");
        } else {
          // If not active, the switch will handle showing the color picker when turned on.
          // isColorPickerVisible will be false initially if mode wasn't active.
           print("Profile title tapped 3 times. Special mode not active. Toggle is now visible.");
        }

        _tapCount = 0; // Reset tap count
        print("Profile title tapped 3 times. Playing confetti.");
        _confettiController.play();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.specialMode),
            duration: Duration(seconds: 2),
          ),
        );
      }
    });
  }

  Future<void> fetchProfileData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      final userDoc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();

      final referralDoc =
          await FirebaseFirestore.instance
              .collection('referral_codes')
              .where('userId', isEqualTo: uid)
              .get();

      if (userDoc.exists) {
        final data = userDoc.data();
        setState(() {
          name = data?['name'] ?? '';
          surname = data?['surname'] ?? '';
          imageUrl = data?['profileImageUrl'] ?? '';
          role = data?['role'] ?? '';
          referralCode = data?['referralCode'] ?? '';
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching profile data: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> _uploadImage(ImageSource source) async {
    final XFile? pickedFile = await _picker.pickImage(source: source);
    if (pickedFile == null) return;

    setState(() => isUploading = true);

    final File imageFile = File(pickedFile.path);
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final ref = FirebaseStorage.instance.ref().child('profile_images/$uid.jpg');
    await ref.putFile(imageFile);
    final downloadUrl = await ref.getDownloadURL();

    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'profileImageUrl': downloadUrl,
    });

    setState(() {
      imageUrl = downloadUrl;
      isUploading = false;
    });
  }

  Future<void> _uploadImageFromUrl(String imageUrl) async {
    if (imageUrl.isEmpty) return;

    setState(() => isUploading = true);

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'profileImageUrl': imageUrl,
      });

      setState(() {
        this.imageUrl = imageUrl;
        isUploading = false;
      });
    } catch (e) {
      print('Error uploading image from URL: $e');
      setState(() => isUploading = false);
    }
  }

  Future<void> _updateUserProfile(String newName, String newSurname) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'name': newName,
      'surname': newSurname,
    });

    setState(() {
      name = newName;
      surname = newSurname;
    });
  }

  Future<void> _removeProfilePicture() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'profileImageUrl': '',
      });

      try {
        final ref = FirebaseStorage.instance.ref().child(
          'profile_images/$uid.jpg',
        );
        await ref.delete();
      } catch (e) {
        print('Error deleting image from storage: $e');
      }

      setState(() {
        imageUrl = '';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.removePhoto),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Error removing profile picture: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.errorAddingToCart),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _showEditProfileDialog() {
    final l10n = AppLocalizations.of(context)!;
    final TextEditingController nameController = TextEditingController(
      text: name,
    );
    final TextEditingController surnameController = TextEditingController(
      text: surname,
    );

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(l10n.editProfile),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(labelText: l10n.name),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: surnameController,
                  decoration: InputDecoration(labelText: l10n.surname),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(l10n.cancel),
              ),
              TextButton(
                onPressed: () {
                  _updateUserProfile(
                    nameController.text.trim(),
                    surnameController.text.trim(),
                  );
                  Navigator.pop(context);
                },
                child: Text(l10n.save),
              ),
            ],
          ),
    );
  }

  void _changeProfilePicture() {
    final l10n = AppLocalizations.of(context)!;
    final themeNotifier = Provider.of<ThemeNotifier>(context, listen: false);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (_) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.photo_camera),
                  title: Text(l10n.takePhoto),
                  onTap: () {
                    Navigator.pop(context);
                    _uploadImage(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: Text(l10n.chooseFromGallery),
                  onTap: () {
                    Navigator.pop(context);
                    _uploadImage(ImageSource.gallery);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.link),
                  title: Text(l10n.addFromUrl),
                  onTap: () {
                    Navigator.pop(context);
                    _showUrlInputDialog();
                  },
                ),
                if (imageUrl != null && imageUrl!.isNotEmpty)
                  ListTile(
                    leading: Icon(
                      Icons.delete_outline,
                      color:
                          themeNotifier.isSpecialModeActive
                              ? themeNotifier.getThemeColor(
                                themeNotifier.specialTheme,
                              )
                              : Colors.red,
                    ),
                    title: Text(
                      l10n.removePhoto,
                      style: TextStyle(
                        color:
                            themeNotifier.isSpecialModeActive
                                ? themeNotifier.getThemeColor(
                                  themeNotifier.specialTheme,
                                )
                                : Colors.red,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _removeProfilePicture();
                    },
                  ),
              ],
            ),
          ),
    );
  }

  void _showUrlInputDialog() {
    final l10n = AppLocalizations.of(context)!;
    final TextEditingController urlController = TextEditingController();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(l10n.enterImageUrl),
            content: TextField(
              controller: urlController,
              decoration: const InputDecoration(
                hintText: 'https://example.com/image.jpg',
                labelText: 'Image URL',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(l10n.cancel),
              ),
              TextButton(
                onPressed: () {
                  if (urlController.text.isNotEmpty) {
                    _uploadImageFromUrl(urlController.text.trim());
                  }
                  Navigator.pop(context);
                },
                child: Text(l10n.add),
              ),
            ],
          ),
    );
  }

  Widget buildButton(
    String label,
    IconData icon,
    VoidCallback onTap,
    ThemeNotifier themeNotifier,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isBlack = themeNotifier.isBlackMode;

    final color = isBlack ? Colors.black : Theme.of(context).cardColor;
    final textColor = isBlack ? Colors.white : null;
    final iconColor =
        themeNotifier.isSpecialModeActive
            ? themeNotifier.getThemeColor(themeNotifier.specialTheme)
            : Colors.red.shade700;
    final borderColor =
        isDark
            ? Colors.white.withOpacity(0.2)
            : themeNotifier.isSpecialModeActive
            ? themeNotifier
                .getThemeColor(themeNotifier.specialTheme)
                .withOpacity(0.3)
            : Colors.red.withOpacity(0.3);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: isDark ? Colors.black12 : Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(icon, color: iconColor, size: 28),
              const SizedBox(width: 16),
              Text(
                label,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final l10n = AppLocalizations.of(context)!;
    final isDarkMode = themeNotifier.isDarkMode;
    final isBlackMode = themeNotifier.isBlackMode;
    final isDark =
        Theme.of(context).brightness == Brightness.dark || isBlackMode;
    final outlineColor =
        isDark
            ? Colors.white.withOpacity(0.2)
            : themeNotifier.isSpecialModeActive
            ? themeNotifier
                .getThemeColor(themeNotifier.specialTheme)
                .withOpacity(0.3)
            : Colors.red.withOpacity(0.3);

    final backgroundColor =
        themeNotifier.isSpecialModeActive
            ? themeNotifier
                .getThemeColor(themeNotifier.specialTheme)
                .withOpacity(0.1)
            : isDark
            ? Colors.black
            : Colors.grey[100];
    final appBarColor =
        themeNotifier.isSpecialModeActive
            ? themeNotifier.getThemeColor(themeNotifier.specialTheme)
            : isDark
            ? Colors.black
            : Colors.white;

    if (user == null) {
      return Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          backgroundColor: appBarColor,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(15)),
          ),
          elevation: 10,
          leading: const LanguageSelector(),
          title: Text(
            l10n.profile,
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black87,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // ... existing code for non-logged-in user ...
              ],
            ),
          ),
        ),
      );
    }

    // For logged-in user
    return Stack(
      alignment: Alignment.topCenter,
      children: [
        Scaffold(
          appBar: AppBar(
            backgroundColor: appBarColor,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(15)),
            ),
            elevation: 10,
            leading: const LanguageSelector(),
            title: GestureDetector(
              onTap: _handleProfileTitleTap,
              child: Text(
                l10n.profile,
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            centerTitle: true,
            actions: [
              IconButton(
                icon: Icon(
                  Icons.edit,
                  color: isDark ? Colors.white : Colors.black87,
                ),
                onPressed: _showEditProfileDialog,
              ),
            ],
          ),
          backgroundColor: backgroundColor,
          body:
              isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : isUploading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            vertical: 24,
                            horizontal: 16,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors:
                                  isDark
                                      ? [
                                        themeNotifier.isSpecialModeActive
                                            ? themeNotifier
                                                .getThemeColor(
                                                  themeNotifier.specialTheme,
                                                )
                                                .shade900
                                            : Colors.red.shade900,
                                        themeNotifier.isSpecialModeActive
                                            ? themeNotifier
                                                .getThemeColor(
                                                  themeNotifier.specialTheme,
                                                )
                                                .shade900
                                            : Colors.grey.shade900,
                                      ]
                                      : [
                                        themeNotifier.isSpecialModeActive
                                            ? themeNotifier
                                                .getThemeColor(
                                                  themeNotifier.specialTheme,
                                                )
                                                .shade500
                                            : Colors.red.shade500,
                                        themeNotifier.isSpecialModeActive
                                            ? themeNotifier
                                                .getThemeColor(
                                                  themeNotifier.specialTheme,
                                                )
                                                .shade100
                                            : Colors.red.shade100,
                                      ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(color: outlineColor, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: isDark ? Colors.black26 : Colors.black12,
                                blurRadius: 5,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              GestureDetector(
                                onTap: _changeProfilePicture,
                                child: Stack(
                                  alignment: Alignment.bottomRight,
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 3,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.2),
                                            blurRadius: 8,
                                            offset: const Offset(0, 3),
                                          ),
                                        ],
                                      ),
                                      child: CircleAvatar(
                                        radius: 60,
                                        backgroundImage:
                                            imageUrl != null && imageUrl!.isNotEmpty
                                                ? NetworkImage(imageUrl!)
                                                : const AssetImage(
                                                      'lib/assets/Images/default_avatar.png',
                                                    )
                                                    as ImageProvider,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color:
                                            isDark
                                                ? Colors.white
                                                : themeNotifier.isSpecialModeActive
                                                ? themeNotifier.getThemeColor(
                                                  themeNotifier.specialTheme,
                                                )
                                                : Colors.red.shade700,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color:
                                              isDark ? Colors.black : Colors.white,
                                          width: 2,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.3),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Icon(
                                        Icons.camera_alt,
                                        size: 20,
                                        color: isDark ? Colors.black : Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                (name?.isNotEmpty == true ||
                                        surname?.isNotEmpty == true)
                                    ? '$name $surname'.trim()
                                    : l10n.addYourName,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  shadows: [
                                    Shadow(
                                      offset: Offset(0, 1),
                                      blurRadius: 3,
                                      color: Color.fromARGB(130, 0, 0, 0),
                                    ),
                                  ],
                                ),
                                textAlign: TextAlign.center,
                              ),
                              if (role == 'admin') ...[
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.4),
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    l10n.admin,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.grey.shade900 : Colors.white,
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(color: outlineColor, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: isDark ? Colors.black26 : Colors.black12,
                                blurRadius: 5,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.settings,
                                    color:
                                        themeNotifier.isSpecialModeActive
                                            ? themeNotifier.getThemeColor(
                                              themeNotifier.specialTheme,
                                            )
                                            : Colors.red.shade700,
                                    size: 22,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    l10n.accountSettings,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? Colors.white : Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                              Divider(
                                color: outlineColor,
                                thickness: 1,
                                height: 32,
                              ),
                              if (role == 'admin')
                                buildButton(
                                  l10n.adminPanel,
                                  Icons.admin_panel_settings,
                                  () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const AdminPage(),
                                      ),
                                    );
                                  },
                                  themeNotifier,
                                ),
                              buildButton(l10n.myAddresses, Icons.location_on, () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => AddressScreen(),
                                  ),
                                );
                              }, themeNotifier),
                              buildButton(l10n.myOrders, Icons.history, () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const OrderHistoryPage(),
                                  ),
                                );
                              }, themeNotifier),
                              buildButton(
                                l10n.myWallet,
                                Icons.account_balance_wallet,
                                () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const WalletPage(),
                                  ),
                                ),
                                themeNotifier,
                              ),
                              buildButton(
                                l10n.reportBug,
                                Icons.bug_report,
                                () => _showBugReportDialog(),
                                themeNotifier,
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.fingerprint, color: themeNotifier.isSpecialModeActive ? themeNotifier.getThemeColor(themeNotifier.specialTheme) : Colors.red.shade700),
                                      const SizedBox(width: 12),
                                      Text(
                                        'Passwordless Sign In',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: isDark ? Colors.white : Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                  isPasswordlessLoading
                                    ? SizedBox(width: 32, height: 32, child: CircularProgressIndicator(strokeWidth: 2))
                                    : _adaptiveSwitch(
                                        value: passwordlessEnabled,
                                        onChanged: _togglePasswordless,
                                        activeColor: themeNotifier.isSpecialModeActive
                                            ? themeNotifier.getThemeColor(themeNotifier.specialTheme).shade700
                                            : Colors.red.shade700,
                                      ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.grey.shade900 : Colors.white,
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(color: outlineColor, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: isDark ? Colors.black26 : Colors.black12,
                                blurRadius: 5,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.palette,
                                    color:
                                        themeNotifier.isSpecialModeActive
                                            ? themeNotifier.getThemeColor(
                                              themeNotifier.specialTheme,
                                            )
                                            : Colors.red.shade700,
                                    size: 22,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    l10n.appearance,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? Colors.white : Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                              Divider(
                                color: outlineColor,
                                thickness: 1,
                                height: 32,
                              ),
                              _buildThemeToggle(
                                l10n.darkMode,
                                Icons.brightness_6,
                                isDarkMode,
                                (_) => themeNotifier.toggleTheme(),
                                isDark,
                              ),
                              if (_showSpecialModeToggle)
                                _buildThemeToggle(
                                  l10n.specialMode,
                                  Icons.color_lens,
                                  themeNotifier.isSpecialModeActive,
                                  (val) {
                                    setState(() {
                                      isColorPickerVisible = val;
                                      final themeNotifier = Provider.of<ThemeNotifier>(context, listen: false);
                                      if (!val) {
                                        themeNotifier.setSpecialTheme(SpecialTheme.none);
                                        _saveSpecialTheme(SpecialTheme.none);
                                        _saveSpecialModeActiveState(false);
                                        print("Special Mode Toggled OFF. Saved state: active=false, theme=none.");
                                        _showSpecialModeToggle = false;
                                        isColorPickerVisible = false;
                                      } else {
                                        _saveSpecialModeActiveState(true);
                                        print("Special Mode Toggled ON. Saved state: active=true. Waiting for theme selection.");
                                        _showSpecialModeToggle = true;
                                        isColorPickerVisible = true;
                                      }
                                    });
                                  },
                                  isDark,
                                ),
                              if (isColorPickerVisible)
                                Padding(
                                  padding: const EdgeInsets.only(top: 16.0),
                                  child: Wrap(
                                    spacing: 16,
                                    children:
                                        SpecialTheme.values
                                            .where(
                                              (theme) => theme != SpecialTheme.none,
                                            )
                                            .map((theme) {
                                              final color = themeNotifier
                                                  .getThemeColor(theme);
                                              return GestureDetector(
                                                onTap: () {
                                                  print("Color circle tapped. Theme: $theme");
                                                  final themeNotifier = Provider.of<ThemeNotifier>(context, listen: false);
                                                  themeNotifier.setSpecialTheme(theme);
                                                  _saveSpecialTheme(theme);
                                                  _saveSpecialModeActiveState(true);
                                                  print("Color selected: $theme. Saved state: active=true, theme=$theme.");

                                                  setState(() {});
                                                },
                                                child: CircleAvatar(
                                                  backgroundColor: color,
                                                  radius: 24,
                                                  child:
                                                      themeNotifier.specialTheme ==
                                                              theme
                                                          ? const Icon(
                                                            Icons.check,
                                                            color: Colors.white,
                                                          )
                                                          : null,
                                                ),
                                              );
                                            })
                                            .toList(),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        _buildReferralCode(),
                        const SizedBox(height: 24),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: ElevatedButton(
                            onPressed: () async {
                              await FirebaseAuth.instance.signOut();
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (_) => WelcomeScreen()),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  isDark
                                      ? (themeNotifier.isSpecialModeActive
                                          ? themeNotifier
                                              .getThemeColor(
                                                themeNotifier.specialTheme,
                                              )
                                              .shade900
                                          : Colors.red.shade900)
                                      : (themeNotifier.isSpecialModeActive
                                          ? themeNotifier
                                              .getThemeColor(
                                                themeNotifier.specialTheme,
                                              )
                                              .shade700
                                          : Colors.red.shade700),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.all(16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              elevation: 4,
                            ),
                            child: Text(
                              l10n.signOut,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
          floatingActionButton:
              _showFloatingButton
                  ? Container(
                    height: 70,
                    width: 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors:
                            isDark
                                ? [
                                  themeNotifier.isSpecialModeActive
                                      ? themeNotifier
                                          .getThemeColor(themeNotifier.specialTheme)
                                          .shade900
                                      : Colors.red.shade900,
                                  themeNotifier.isSpecialModeActive
                                      ? themeNotifier
                                          .getThemeColor(themeNotifier.specialTheme)
                                          .shade800
                                      : Colors.red.shade800,
                                ]
                                : [
                                  themeNotifier.isSpecialModeActive
                                      ? themeNotifier
                                          .getThemeColor(themeNotifier.specialTheme)
                                          .shade500
                                      : Colors.red.shade500,
                                  themeNotifier.isSpecialModeActive
                                      ? themeNotifier
                                          .getThemeColor(themeNotifier.specialTheme)
                                          .shade400
                                      : Colors.red.shade400,
                                ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: FloatingActionButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AIChatScreen(),
                          ),
                        );
                      },
                      elevation: 0,
                      backgroundColor: Colors.transparent,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Image.asset(
                          'lib/assets/Images/Mascot/mascot-head.png',
                          width: 120,
                          height: 120,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  )
                  : null,
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        ),
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirection: pi / 2,
            emissionFrequency: 0.05,
            numberOfParticles: 50,
            gravity: 0.15,
            shouldLoop: false,
            colors: const [
              Colors.green, Colors.blue, Colors.pink, Colors.orange, Colors.purple, Colors.yellow
            ],
            particleDrag: 0.05,
            maxBlastForce: 30,
            minBlastForce: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildThemeToggle(
    String label,
    IconData icon,
    bool value,
    Function(bool) onChanged,
    bool isDark,
  ) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
              isDark
                  ? Colors.white.withOpacity(0.1)
                  : (themeNotifier.isSpecialModeActive
                      ? themeNotifier
                          .getThemeColor(themeNotifier.specialTheme)
                          .withOpacity(0.1)
                      : Colors.red.withOpacity(0.1)),
          width: 1,
        ),
      ),
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const SizedBox(width: 12),
              Icon(
                icon,
                color:
                    themeNotifier.isSpecialModeActive
                        ? themeNotifier.getThemeColor(
                          themeNotifier.specialTheme,
                        )
                        : Colors.red.shade700,
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor:
                themeNotifier.isSpecialModeActive
                    ? themeNotifier
                        .getThemeColor(themeNotifier.specialTheme)
                        .shade700
                    : Colors.red.shade700,
          ),
        ],
      ),
    );
  }

  Widget _buildReferralCode() {
    final l10n = AppLocalizations.of(context)!;
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
              Theme.of(context).brightness == Brightness.dark
                  ? Colors.white.withOpacity(0.2)
                  : (themeNotifier.isSpecialModeActive
                      ? themeNotifier
                          .getThemeColor(themeNotifier.specialTheme)
                          .withOpacity(0.3)
                      : Colors.red.withOpacity(0.3)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.referralCode,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                referralCode ?? l10n.loading,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.copy),
                onPressed: () {
                  if (referralCode != null) {
                    Clipboard.setData(ClipboardData(text: referralCode!));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(l10n.copiedToClipboard),
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showBugReportDialog() {
    final l10n = AppLocalizations.of(context)!;
    final TextEditingController titleController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();
    final user = FirebaseAuth.instance.currentUser;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.reportBug),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  labelText: l10n.bugTitle,
                  hintText: l10n.enterBugTitle,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                maxLines: 5,
                decoration: InputDecoration(
                  labelText: l10n.bugDescription,
                  hintText: l10n.describeBugInDetail,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () async {
              if (titleController.text.trim().isEmpty || 
                  descriptionController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.pleaseEnterBugDetails)),
                );
                return;
              }

              try {
                await FirebaseFirestore.instance.collection('bug_reports').add({
                  'userId': user?.uid,
                  'userEmail': user?.email,
                  'title': titleController.text.trim(),
                  'description': descriptionController.text.trim(),
                  'status': 'pending',
                  'createdAt': FieldValue.serverTimestamp(),
                  'updatedAt': FieldValue.serverTimestamp(),
                });

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.bugReportSubmitted)),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.errorSubmittingBugReport)),
                );
              }
            },
            child: Text(l10n.save)),
        ],
      ),
    );
  }

  Future<void> _loadSpecialModePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final themeNotifier = Provider.of<ThemeNotifier>(context, listen: false);

    // Load special mode active state
    bool isSpecialModeActive = prefs.getBool(_kSpecialModeActiveKey) ?? false;
    if (isSpecialModeActive) {
      // Load the actual theme if mode was active
      String? themeName = prefs.getString(_kSpecialThemeKey);
      SpecialTheme loadedTheme = SpecialTheme.none;
      if (themeName != null) {
        try {
          loadedTheme = SpecialTheme.values.firstWhere((e) => e.toString() == themeName);
        } catch (e) {
          print("Error parsing saved theme: $e");
          loadedTheme = SpecialTheme.none; // Default to none on error
        }
      }
      themeNotifier.setSpecialTheme(loadedTheme); // This also updates isSpecialModeActive in notifier
      if (loadedTheme != SpecialTheme.none) {
         if (mounted) {
          setState(() {
            _showSpecialModeToggle = true; // Show the toggle if a theme was active
            isColorPickerVisible = true; // Show colors if a theme was active
          });
        }
      }
    } else {
      // Ensure special mode is off in notifier if not persisted as active
      themeNotifier.setSpecialTheme(SpecialTheme.none);
    }
    // No need to explicitly call _saveSpecialModeActiveState or _saveSpecialTheme here as we are loading
  }

  Future<void> _saveSpecialModeActiveState(bool isActive) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kSpecialModeActiveKey, isActive);
  }

  Future<void> _saveSpecialTheme(SpecialTheme theme) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kSpecialThemeKey, theme.toString());
  }

  Future<void> _loadPasswordlessSetting() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (doc.exists && doc.data()!.containsKey('passwordless_enabled')) {
      setState(() {
        passwordlessEnabled = doc['passwordless_enabled'] == true;
      });
    }
  }

  Future<void> _togglePasswordless(bool value) async {
    setState(() { isPasswordlessLoading = true; });
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'passwordless_enabled': value,
    }, SetOptions(merge: true));
    setState(() {
      passwordlessEnabled = value;
      isPasswordlessLoading = false;
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  Widget _adaptiveSwitch({required bool value, required ValueChanged<bool> onChanged, Color? activeColor}) {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
      return CupertinoSwitch(
        value: value,
        onChanged: onChanged,
        activeColor: activeColor,
      );
    } else {
      return Switch(
        value: value,
        onChanged: onChanged,
        activeColor: activeColor,
      );
    }
  }
}
