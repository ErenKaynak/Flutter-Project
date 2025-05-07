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
import 'package:shared_preferences/shared_preferences.dart';

import 'theme_notifier.dart';
import 'address_screen.dart';
import 'past_orders_page.dart';
import 'welcome_screen.dart';
import '../admin-panel/admin_main.dart';

// SpecialColorTheme enum
enum SpecialColorTheme { blue, orange, yellow, green, purple }

// getThemeColor function
MaterialColor getThemeColor(SpecialColorTheme theme) {
  switch (theme) {
    case SpecialColorTheme.blue:
      return Colors.blue;
    case SpecialColorTheme.orange:
      return Colors.orange;
    case SpecialColorTheme.yellow:
      return Colors.yellow;
    case SpecialColorTheme.green:
      return Colors.green;
    case SpecialColorTheme.purple:
      return Colors.purple;
    default:
      return Colors.blue;
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

  final ImagePicker _picker = ImagePicker();

  // Special Mode toggle variables
  int _tapCount = 0;
  bool _showSpecialModeToggle = false;

  // Color picker variables
  bool isColorPickerVisible = false;
  SpecialColorTheme? _selectedTheme;

  @override
  void initState() {
    super.initState();
    _checkAISettings();
    fetchProfileData();
    _loadSelectedTheme(); // Load persisted theme
  }

  // Load selected theme from SharedPreferences
  Future<void> _loadSelectedTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeString = prefs.getString('selectedTheme');
    if (themeString != null) {
      setState(() {
        _selectedTheme = SpecialColorTheme.values.firstWhere(
          (e) => e.toString() == 'SpecialColorTheme.$themeString',
          orElse: () => SpecialColorTheme.blue,
        );
      });
    }
  }

  // Save selected theme to SharedPreferences
  Future<void> _saveSelectedTheme(SpecialColorTheme? theme) async {
    final prefs = await SharedPreferences.getInstance();
    if (theme != null) {
      await prefs.setString('selectedTheme', theme.toString().split('.').last);
    } else {
      await prefs.remove('selectedTheme');
    }
  }

  Future<void> _checkAISettings() async {
    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('settings')
              .doc('ai_settings')
              .get();

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

  void _handleProfileTitleTap() {
    setState(() {
      _tapCount++;
      if (_tapCount >= 3) {
        _showSpecialModeToggle = true;
        isColorPickerVisible =
            _selectedTheme != null; // Show color picker if theme is selected
        _tapCount = 0;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Special Mode toggle enabled!'),
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
          const SnackBar(
            content: Text('Profile picture removed'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Error removing profile picture: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to remove profile picture'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _showEditProfileDialog() {
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
            title: const Text('Edit Profile'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: surnameController,
                  decoration: const InputDecoration(labelText: 'Surname'),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  _updateUserProfile(
                    nameController.text.trim(),
                    surnameController.text.trim(),
                  );
                  Navigator.pop(context);
                },
                child: const Text('Save'),
              ),
            ],
          ),
    );
  }

  void _changeProfilePicture() {
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
                  title: const Text('Take a photo'),
                  onTap: () {
                    Navigator.pop(context);
                    _uploadImage(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Choose from gallery'),
                  onTap: () {
                    Navigator.pop(context);
                    _uploadImage(ImageSource.gallery);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.link),
                  title: const Text('Add from URL'),
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
                          _selectedTheme != null
                              ? getThemeColor(_selectedTheme!)
                              : Colors.red,
                    ),
                    title: Text(
                      'Remove Photo',
                      style: TextStyle(
                        color:
                            _selectedTheme != null
                                ? getThemeColor(_selectedTheme!)
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
    final TextEditingController urlController = TextEditingController();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Enter Image URL'),
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
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  if (urlController.text.isNotEmpty) {
                    _uploadImageFromUrl(urlController.text.trim());
                  }
                  Navigator.pop(context);
                },
                child: const Text('Add'),
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
        _selectedTheme != null
            ? getThemeColor(_selectedTheme!)
            : Colors.red.shade700;
    final borderColor =
        isDark
            ? Colors.white.withOpacity(0.2)
            : _selectedTheme != null
            ? getThemeColor(_selectedTheme!).withOpacity(0.3)
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
    final isDarkMode = themeNotifier.themeMode == ThemeMode.dark;
    final isBlackMode = themeNotifier.isBlackMode;
    final isDark =
        Theme.of(context).brightness == Brightness.dark || isBlackMode;
    final outlineColor =
        isDark
            ? Colors.white.withOpacity(0.2)
            : _selectedTheme != null
            ? getThemeColor(_selectedTheme!).withOpacity(0.3)
            : Colors.red.withOpacity(0.3);

    // Apply light mode when Special Mode is on, unless a special theme is selected
    final backgroundColor =
        _selectedTheme != null
            ? getThemeColor(_selectedTheme!).withOpacity(0.1)
            : isDark
            ? Colors.black
            : Colors.grey[100];
    final appBarColor =
        _selectedTheme != null
            ? getThemeColor(_selectedTheme!)
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
          title: Text(
            'Profile',
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
                                _selectedTheme != null
                                    ? getThemeColor(_selectedTheme!).shade900
                                    : Colors.red.shade900,
                                _selectedTheme != null
                                    ? getThemeColor(_selectedTheme!).shade900
                                    : Colors.grey.shade900,
                              ]
                              : [
                                _selectedTheme != null
                                    ? getThemeColor(_selectedTheme!).shade500
                                    : Colors.red.shade500,
                                _selectedTheme != null
                                    ? getThemeColor(_selectedTheme!).shade100
                                    : Colors.red.shade100,
                              ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: isDark ? Colors.black26 : Colors.black12,
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor:
                              isDark ? Colors.grey[800] : Colors.white,
                          child: Icon(
                            Icons.person_outline,
                            size: 60,
                            color: isDark ? Colors.white54 : Colors.grey[400],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Welcome, Guest',
                        style: TextStyle(
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
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Sign in to access all features',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.9),
                        ),
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
                            Icons.lock_outline,
                            color:
                                _selectedTheme != null
                                    ? getThemeColor(_selectedTheme!)
                                    : Colors.red.shade700,
                            size: 22,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Authentication',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => LoginPage(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              isDark
                                  ? (_selectedTheme != null
                                      ? getThemeColor(_selectedTheme!).shade900
                                      : Colors.red.shade900)
                                  : (_selectedTheme != null
                                      ? getThemeColor(_selectedTheme!).shade400
                                      : Colors.red.shade400),
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: const Text(
                          'Sign In',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => RegisterPage(),
                            ),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color:
                                _selectedTheme != null
                                    ? getThemeColor(_selectedTheme!).shade400
                                    : Colors.red.shade400,
                            width: 2,
                          ),
                          minimumSize: const Size.fromHeight(50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Create Account',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color:
                                _selectedTheme != null
                                    ? getThemeColor(_selectedTheme!).shade400
                                    : Colors.red.shade400,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: appBarColor,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(15)),
        ),
        elevation: 10,
        title: GestureDetector(
          onTap: _handleProfileTitleTap,
          child: Text(
            'Profile',
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
                                    _selectedTheme != null
                                        ? getThemeColor(
                                          _selectedTheme!,
                                        ).shade900
                                        : Colors.red.shade900,
                                    _selectedTheme != null
                                        ? getThemeColor(
                                          _selectedTheme!,
                                        ).shade900
                                        : Colors.grey.shade900,
                                  ]
                                  : [
                                    _selectedTheme != null
                                        ? getThemeColor(
                                          _selectedTheme!,
                                        ).shade500
                                        : Colors.red.shade500,
                                    _selectedTheme != null
                                        ? getThemeColor(
                                          _selectedTheme!,
                                        ).shade100
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
                                            : _selectedTheme != null
                                            ? getThemeColor(_selectedTheme!)
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
                                : 'Add Your Name',
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
                              child: const Text(
                                'ADMIN',
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
                                    _selectedTheme != null
                                        ? getThemeColor(_selectedTheme!)
                                        : Colors.red.shade700,
                                size: 22,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Account Settings',
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
                              'Admin Panel',
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
                          buildButton('My Addresses', Icons.location_on, () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AddressScreen(),
                              ),
                            );
                          }, themeNotifier),
                          buildButton('My Orders', Icons.history, () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const OrderHistoryPage(),
                              ),
                            );
                          }, themeNotifier),
                          buildButton(
                            'My Wallet',
                            Icons.account_balance_wallet,
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const WalletPage(),
                              ),
                            ),
                            themeNotifier,
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
                                    _selectedTheme != null
                                        ? getThemeColor(_selectedTheme!)
                                        : Colors.red.shade700,
                                size: 22,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Appearance',
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
                            'Dark Mode',
                            Icons.brightness_6,
                            isDarkMode,
                            (_) => themeNotifier.toggleTheme(),
                            isDark,
                          ),
                          if (_showSpecialModeToggle)
                            _buildThemeToggle(
                              'Special Mode',
                              Icons.color_lens,
                              isColorPickerVisible,
                              (val) {
                                setState(() {
                                  isColorPickerVisible = val;
                                  if (!val) {
                                    _selectedTheme =
                                        null; // Clear selected theme
                                    _saveSelectedTheme(null);
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
                                    SpecialColorTheme.values.map((theme) {
                                      final color = getThemeColor(theme);
                                      return GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _selectedTheme = theme;
                                            _showSpecialModeToggle =
                                                false; // Hide Special Mode toggle
                                            isColorPickerVisible =
                                                false; // Hide color picker
                                          });
                                          _saveSelectedTheme(
                                            theme,
                                          ); // Save theme
                                        },
                                        child: CircleAvatar(
                                          backgroundColor: color,
                                          radius: 24,
                                          child:
                                              _selectedTheme == theme
                                                  ? const Icon(
                                                    Icons.check,
                                                    color: Colors.white,
                                                  )
                                                  : null,
                                        ),
                                      );
                                    }).toList(),
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
                                  ? (_selectedTheme != null
                                      ? getThemeColor(_selectedTheme!).shade900
                                      : Colors.red.shade900)
                                  : (_selectedTheme != null
                                      ? getThemeColor(_selectedTheme!).shade700
                                      : Colors.red.shade700),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.all(16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          elevation: 4,
                        ),
                        child: const Text(
                          'Log Out',
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
                              _selectedTheme != null
                                  ? getThemeColor(_selectedTheme!).shade900
                                  : Colors.red.shade900,
                              _selectedTheme != null
                                  ? getThemeColor(_selectedTheme!).shade800
                                  : Colors.red.shade800,
                            ]
                            : [
                              _selectedTheme != null
                                  ? getThemeColor(_selectedTheme!).shade500
                                  : Colors.red.shade500,
                              _selectedTheme != null
                                  ? getThemeColor(_selectedTheme!).shade400
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
    );
  }

  Widget _buildThemeToggle(
    String label,
    IconData icon,
    bool value,
    Function(bool) onChanged,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
              isDark
                  ? Colors.white.withOpacity(0.1)
                  : (_selectedTheme != null
                      ? getThemeColor(_selectedTheme!).withOpacity(0.1)
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
                    _selectedTheme != null
                        ? getThemeColor(_selectedTheme!)
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
                _selectedTheme != null
                    ? getThemeColor(_selectedTheme!).shade700
                    : Colors.red.shade700,
          ),
        ],
      ),
    );
  }

  Widget _buildReferralCode() {
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
                  : (_selectedTheme != null
                      ? getThemeColor(_selectedTheme!).withOpacity(0.3)
                      : Colors.red.withOpacity(0.3)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Referral Code',
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
                referralCode ?? 'Loading...',
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
                      const SnackBar(
                        content: Text('Referral code copied to clipboard'),
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
}
