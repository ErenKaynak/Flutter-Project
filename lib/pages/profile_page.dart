import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:engineering_project/admin-panel/admin_main.dart';
import 'package:engineering_project/admin-panel/admin_root.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

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
    }
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
                    // Profile image
                    Center(
                      child: CircleAvatar(
                        radius: 50,
                        backgroundImage:
                            imageUrl != null && imageUrl!.isNotEmpty
                                ? NetworkImage(imageUrl!)
                                : const AssetImage(
                                      'lib/assets/Images/default_avatar.png',
                                    )
                                    as ImageProvider,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Name + Surname
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

                    // Buttons
                    /*buildButton(
                    'Past Orders',
                    Icons.history,
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const PastOrdersPage()),
                    ),
                  ),*/
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
                  ],
                ),
              ),
    );
  }
}
