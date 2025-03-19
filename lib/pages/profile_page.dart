import 'package:flutter/material.dart';
import 'package:engineering_project/assets/components/auth_service.dart';
import 'login_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: FloatingActionButton(
          backgroundColor: Colors.red.shade700,
          foregroundColor: Colors.grey[200],
          onPressed: () async {
            await _signOutAndNavigate(context); // Pass context properly
          },
          child: const Icon(Icons.arrow_forward, size: 25),
        ),
      ),
    );
  }

  Future<void> _signOutAndNavigate(BuildContext context) async {
    await AuthService().signOut();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => LoginPage()),
        (route) => false,
      );
    }
  }
}
//TODO: finish this screen
