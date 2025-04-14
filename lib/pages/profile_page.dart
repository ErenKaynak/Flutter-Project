import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:engineering_project/admin-panel/admin_main.dart';
import 'package:engineering_project/pages/login_page.dart';
import 'package:engineering_project/pages/past_orders_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:engineering_project/assets/components/auth_service.dart';

class ProfilePage extends StatefulWidget {
  final dynamic themeNotifier; // <-- Tema kontrolcüsü eklendi

  const ProfilePage({super.key, required this.themeNotifier});

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

  @override
  void initState() {
    super.initState();
    fetchProfileData();
  }

  Future<void> fetchProfileData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      final doc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final data = doc.data();

      if (data != null) {
        setState(() {
          name = data['name'];
          surname = data['surname'];
          imageUrl = data['profileImageUrl'];
          role = data['role'];
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching profile: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _uploadImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      setState(() {
        isUploading = true;
      });

      final File imageFile = File(pickedFile.path);
      final uid = FirebaseAuth.instance.currentUser?.uid;

      if (uid == null) {
        setState(() {
          isUploading = false;
        });
        return;
      }

      final storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_images')
          .child('$uid.jpg');

      final uploadTask = storageRef.putFile(
        imageFile,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'profileImageUrl': downloadUrl,
      });

      setState(() {
        imageUrl = downloadUrl;
        isUploading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile picture updated successfully')),
      );
    } catch (e) {
      setState(() {
        isUploading = false;
      });
      print('Error uploading image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update profile picture: $e')),
      );
    }
  }

  Future<void> _changeProfilePicture() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => SafeArea(
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
                if (imageUrl != null && imageUrl!.isNotEmpty)
                  ListTile(
                    leading: const Icon(Icons.delete, color: Colors.red),
                    title: const Text(
                      'Remove photo',
                      style: TextStyle(color: Colors.red),
                    ),
                    onTap: () async {
                      Navigator.pop(context);
                      final uid = FirebaseAuth.instance.currentUser?.uid;
                      if (uid == null) return;

                      setState(() {
                        isUploading = true;
                      });

                      try {
                        await FirebaseFirestore.instance
                            .collection('users')
                            .doc(uid)
                            .update({'profileImageUrl': ''});

                        try {
                          await FirebaseStorage.instance
                              .ref()
                              .child('profile_images')
                              .child('$uid.jpg')
                              .delete();
                        } catch (e) {
                          print('Error deleting image from storage: $e');
                        }

                        setState(() {
                          imageUrl = '';
                          isUploading = false;
                        });

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Profile picture removed'),
                          ),
                        );
                      } catch (e) {
                        setState(() {
                          isUploading = false;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to remove photo: $e')),
                        );
                      }
                    },
                  ),
              ],
            ),
          ),
    );
  }

  Widget buildButton(String label, IconData icon, VoidCallback onPressed) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.shade300,
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(icon, color: Colors.red.shade700, size: 28),
              const SizedBox(width: 16),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
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
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        backgroundColor: Colors.grey[200],
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Profile',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: _changeProfilePicture,
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          isUploading
                              ? const CircleAvatar(
                                radius: 50,
                                child: CircularProgressIndicator(),
                              )
                              : CircleAvatar(
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
                    Center(
                      child: Text(
                        '$name $surname',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    buildButton(
                      'Past Orders',
                      Icons.history,
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => OrderHistoryPage(),
                        ),
                      ),
                    ),
                    if (role == 'admin')
                      buildButton(
                        'Admin Panel',
                        Icons.admin_panel_settings,
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AdminPage(),
                          ),
                        ),
                      ),

                    // 🌙 Tema değiştirici
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: GestureDetector(
                        onTap: () {
                          // İsteğe bağlı: Kutunun kendisine tıklanırsa da değişebilir
                          setState(() {
                            widget.themeNotifier.toggleTheme(
                              !widget.themeNotifier.isDarkMode,
                            );
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          height: 60, // Diğer butonlarla aynı yükseklik
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.shade300,
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.brightness_6,
                                    color: Colors.red.shade700,
                                    size: 28,
                                  ),
                                  const SizedBox(width: 16),
                                  const Text(
                                    "Karanlık Tema",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              Switch(
                                value: widget.themeNotifier.isDarkMode,
                                onChanged: (val) {
                                  setState(() {
                                    widget.themeNotifier.toggleTheme(val);
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // 🔓 Çıkış
                    buildButton('Log Out', Icons.logout, () async {
                      await FirebaseAuth.instance.signOut();
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (context) => LoginPage()),
                      );
                    }),
                  ],
                ),
              ),
    );
  }
}
