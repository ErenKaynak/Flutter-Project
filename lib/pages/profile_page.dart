import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import 'theme_notifier.dart';
import 'address_screen.dart';
import 'past_orders_page.dart';
import 'welcome_screen.dart';
import '../admin-panel/admin_main.dart';

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

  final ImagePicker _picker = ImagePicker();

  int _tapCount = 0;
  bool _blackMode = false;
  bool _showBlackModeToggle = false;

  @override
  void initState() {
    super.initState();
    fetchProfileData();
  }

  @override
  void dispose() {
    _blackMode = false;
    _showBlackModeToggle = false;
    super.dispose();
  }

  void _handleProfileTitleTap() {
    setState(() {
      _tapCount++;
      if (_tapCount >= 5) {
        _showBlackModeToggle = true;
        _tapCount = 0;
      }
    });
  }

  Future<void> fetchProfileData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      final userDoc = FirebaseFirestore.instance.collection('users').doc(uid);
      final docSnapshot = await userDoc.get();

      if (!docSnapshot.exists) {
        await userDoc.set({
          'name': '',
          'surname': '',
          'profileImageUrl': '',
          'role': 'user',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      final data = (await userDoc.get()).data();
      if (data != null) {
        setState(() {
          name = data['name'] ?? '';
          surname = data['surname'] ?? '';
          imageUrl = data['profileImageUrl'] ?? '';
          role = data['role'] ?? '';
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
              ],
            ),
          ),
    );
  }

  Widget buildButton(String label, IconData icon, VoidCallback onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color =
        _blackMode ? Colors.grey.shade900 : Theme.of(context).cardColor;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? Colors.grey.shade700 : Colors.transparent,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(icon, color: Colors.red.shade700, size: 28),
              const SizedBox(width: 16),
              Text(
                label,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: _blackMode ? Colors.white : null,
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
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final isDarkMode = themeNotifier.themeMode == ThemeMode.dark;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final scaffoldBgColor =
        _blackMode ? Colors.black : Theme.of(context).scaffoldBackgroundColor;
    final cardColor =
        _blackMode ? Colors.grey.shade900 : Theme.of(context).cardColor;
    final textColor =
        _blackMode
            ? Colors.white
            : Theme.of(context).textTheme.titleLarge?.color;

    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: _handleProfileTitleTap,
          child: const Text('Profile'),
        ),
        centerTitle: true,
        backgroundColor:
            _blackMode
                ? Colors.black
                : (isDark ? Colors.black : Colors.red.shade700),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _showEditProfileDialog,
          ),
        ],
      ),
      backgroundColor: scaffoldBgColor,
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: _changeProfilePicture,
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundImage:
                                imageUrl != null && imageUrl!.isNotEmpty
                                    ? NetworkImage(imageUrl!)
                                    : const AssetImage(
                                          'lib/assets/Images/default_avatar.png',
                                        )
                                        as ImageProvider,
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.red.shade700,
                              shape: BoxShape.circle,
                            ),
                            padding: const EdgeInsets.all(5),
                            child: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '$name $surname',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 32),

                    buildButton('My Orders', Icons.history, () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const OrderHistoryPage(),
                        ),
                      );
                    }),

                    buildButton('My Addresses', Icons.location_on, () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => AddressScreen()),
                      );
                    }),

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
                      ),

                    if (_showBlackModeToggle)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          height: 60,
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color:
                                  isDark
                                      ? Colors.grey.shade700
                                      : Colors.transparent,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.dark_mode,
                                    color: Colors.red,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    "Black Mode",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: textColor,
                                    ),
                                  ),
                                ],
                              ),
                              Switch(
                                value: _blackMode,
                                onChanged: (val) {
                                  setState(() {
                                    _blackMode = val;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      ),

                    const SizedBox(height: 16),

                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      height: 60,
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color:
                              isDark
                                  ? Colors.grey.shade700
                                  : Colors.transparent,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.brightness_6, color: Colors.red),
                              SizedBox(width: 12),
                              Text(
                                "Dark Mode",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          Switch(
                            value: isDarkMode,
                            onChanged: (_) {
                              themeNotifier.toggleTheme();
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    buildButton('Log Out', Icons.logout, () async {
                      await FirebaseAuth.instance.signOut();
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => WelcomeScreen()),
                      );
                    }),
                  ],
                ),
              ),
    );
  }
}
