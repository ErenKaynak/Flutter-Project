import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:engineering_project/pages/address_screen.dart';
import 'package:engineering_project/pages/past_orders_page.dart';
import 'package:engineering_project/pages/welcome_screen.dart';
import 'package:engineering_project/admin-panel/admin_main.dart';

class ThemeNotifier extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;
  bool _isBlackMode = false;

  ThemeMode get themeMode => _themeMode;
  bool get isBlackMode => _isBlackMode;

  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  void toggleBlackMode(bool value) {
    _isBlackMode = value;
    notifyListeners();
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

  final ImagePicker _picker = ImagePicker();

  int _tapCount = 0;
  bool _showBlackModeToggle = false;

  @override
  void initState() {
    super.initState();
    fetchProfileData();
  }

  void _handleProfileTitleTap() {
    setState(() {
      _tapCount++;
      if (_tapCount >= 3) {
        _showBlackModeToggle = true;
        _tapCount = 0;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Black Mode toggle enabled!'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    });
  }

  Future<void> fetchProfileData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      setState(() => isLoading = false);
      return;
    }

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
      if (data != null && mounted) {
        setState(() {
          name = data['name'] ?? '';
          surname = data['surname'] ?? '';
          imageUrl = data['profileImageUrl'] ?? '';
          role = data['role'] ?? 'user';
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching profile data: $e');
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _uploadImage(ImageSource source) async {
    final XFile? pickedFile = await _picker.pickImage(source: source);
    if (pickedFile == null || !mounted) return;

    setState(() => isUploading = true);

    try {
      final File imageFile = File(pickedFile.path);
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) throw Exception('User not logged in');

      final ref =
          FirebaseStorage.instance.ref().child('profile_images/$uid.jpg');
      await ref.putFile(imageFile);
      final downloadUrl = await ref.getDownloadURL();

      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'profileImageUrl': downloadUrl,
      });

      if (mounted) {
        setState(() {
          imageUrl = downloadUrl;
          isUploading = false;
        });
      }
    } catch (e) {
      print('Error uploading image: $e');
      if (mounted) {
        setState(() => isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload image: $e'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _uploadImageFromUrl(String imageUrl) async {
    if (imageUrl.isEmpty || !Uri.parse(imageUrl).isAbsolute) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter a valid URL'),
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    setState(() => isUploading = true);

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) throw Exception('User not logged in');

      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'profileImageUrl': imageUrl,
      });

      if (mounted) {
        setState(() {
          this.imageUrl = imageUrl;
          isUploading = false;
        });
      }
    } catch (e) {
      print('Error uploading image from URL: $e');
      if (mounted) {
        setState(() => isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload image from URL: $e'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _updateUserProfile(String newName, String newSurname) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || !mounted) return;

    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'name': newName,
        'surname': newSurname,
      });

      if (mounted) {
        setState(() {
          name = newName;
          surname = newSurname;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Error updating profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile: $e'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _removeProfilePicture() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) throw Exception('User not logged in');

      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'profileImageUrl': '',
      });

      try {
        final ref =
            FirebaseStorage.instance.ref().child('profile_images/$uid.jpg');
        await ref.delete();
      } catch (e) {
        print('Error deleting image from storage: $e');
      }

      if (mounted) {
        setState(() {
          imageUrl = '';
        });
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
          SnackBar(
            content: Text('Failed to remove profile picture: $e'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _showEditProfileDialog() {
    final TextEditingController nameController = TextEditingController(text: name);
    final TextEditingController surnameController =
        TextEditingController(text: surname);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
            onPressed: () {
              nameController.dispose();
              surnameController.dispose();
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              _updateUserProfile(
                nameController.text.trim(),
                surnameController.text.trim(),
              );
              nameController.dispose();
              surnameController.dispose();
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _changeProfilePicture() {
    final themeNotifier = Provider.of<ThemeNotifier>(context, listen: false);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
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
                  color: themeNotifier.isBlackMode
                      ? Theme.of(context).colorScheme.secondary
                      : Colors.red,
                ),
                title: Text(
                  'Remove Photo',
                  style: TextStyle(
                    color: themeNotifier.isBlackMode
                        ? Theme.of(context).colorScheme.secondary
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
      builder: (context) => AlertDialog(
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
            onPressed: () {
              urlController.dispose();
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              _uploadImageFromUrl(urlController.text.trim());
              urlController.dispose();
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
        isBlack ? Theme.of(context).colorScheme.secondary : Colors.red.shade700;
    final borderColor = isDark
        ? Colors.white.withOpacity(0.2)
        : (isBlack
            ? Theme.of(context).colorScheme.secondary
            : Colors.red.withOpacity(0.3));

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
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final isDark = themeNotifier.themeMode == ThemeMode.dark || themeNotifier.isBlackMode;

    final bgColor = isDark ? Colors.black : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;
    final cardColor = isDark ? Colors.grey.shade900 : Colors.white;
    final borderColor = isDark
        ? Colors.white.withOpacity(0.2)
        : (themeNotifier.isBlackMode
            ? Theme.of(context).colorScheme.secondary.withOpacity(0.3)
            : Colors.red.shade300.withOpacity(0.5));

    return Scaffold(
      appBar: AppBar(
        backgroundColor: bgColor,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(15)),
        ),
        elevation: 10,
        title: GestureDetector(
          onTap: _handleProfileTitleTap,
          child: Text(
            'Profile',
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.edit, color: textColor),
            onPressed: _showEditProfileDialog,
          ),
        ],
      ),
      backgroundColor: bgColor,
      body: (isLoading || isUploading)
          ? Center(
              child: CircularProgressIndicator(
                color: themeNotifier.isBlackMode
                    ? Theme.of(context).colorScheme.secondary
                    : Colors.red.shade700,
              ),
            )
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
                        colors: isDark
                            ? [
                                themeNotifier.isBlackMode
                                    ? Theme.of(context).colorScheme.secondary
                                    : Colors.red.shade900,
                                Colors.grey.shade900,
                              ]
                            : [
                                themeNotifier.isBlackMode
                                    ? Colors.grey.shade50
                                    : Colors.red.shade500,
                                themeNotifier.isBlackMode
                                    ? Colors.grey.shade50
                                    : Colors.red.shade100,
                              ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: borderColor, width: 2),
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
                                  backgroundImage: imageUrl != null &&
                                          imageUrl!.isNotEmpty
                                      ? NetworkImage(imageUrl!)
                                      : const AssetImage(
                                          'lib/assets/Images/default_avatar.png',
                                        ) as ImageProvider,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.white
                                      : (themeNotifier.isBlackMode
                                          ? Theme.of(context).colorScheme.secondary
                                          : Colors.red.shade700),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isDark ? Colors.black : Colors.white,
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
                      color: cardColor,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: borderColor, width: 2),
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
                              color: themeNotifier.isBlackMode
                                  ? Theme.of(context).colorScheme.secondary
                                  : Colors.red.shade700,
                              size: 22,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Account Settings',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                          ],
                        ),
                        Divider(color: borderColor, thickness: 1, height: 32),
                        if (role == 'admin')
                          buildButton(
                            'Admin Panel',
                            Icons.admin_panel_settings,
                            () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const AdminPage()),
                              );
                            },
                            themeNotifier,
                          ),
                        buildButton(
                          'My Addresses',
                          Icons.location_on,
                          () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => AddressScreen()),
                            );
                          },
                          themeNotifier,
                        ),
                        buildButton(
                          'My Orders',
                          Icons.history,
                          () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const OrderHistoryPage()),
                            );
                          },
                          themeNotifier,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: borderColor, width: 2),
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
                              color: themeNotifier.isBlackMode
                                  ? Theme.of(context).colorScheme.secondary
                                  : Colors.red.shade700,
                              size: 22,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Appearance',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                          ],
                        ),
                        Divider(color: borderColor, thickness: 1, height: 32),
                        _buildThemeToggle(
                          'Dark Mode',
                          Icons.brightness_6,
                          themeNotifier.themeMode == ThemeMode.dark,
                          (_) => themeNotifier.toggleTheme(),
                          isDark,
                        ),
                        if (_showBlackModeToggle)
                          _buildThemeToggle(
                            'Black Mode',
                            Icons.dark_mode,
                            themeNotifier.isBlackMode,
                            (val) => themeNotifier.toggleBlackMode(val),
                            isDark,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: ElevatedButton(
                      onPressed: () async {
                        await FirebaseAuth.instance.signOut();
                        if (mounted) {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (_) => WelcomeScreen()),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: themeNotifier.isBlackMode
                            ? Theme.of(context).colorScheme.secondary
                            : (isDark ? Colors.red.shade900 : Colors.red.shade700),
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
          color: isDark
              ? Colors.white.withOpacity(0.1)
              : (themeNotifier.isBlackMode
                  ? Theme.of(context).colorScheme.secondary.withOpacity(0.1)
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
                color: themeNotifier.isBlackMode
                    ? Theme.of(context).colorScheme.secondary
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
            activeColor: themeNotifier.isBlackMode
                ? Theme.of(context).colorScheme.secondary
                : Colors.red.shade700,
          ),
        ],
      ),
    );
  }
}