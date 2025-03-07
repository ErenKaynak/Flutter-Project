import 'package:flutter/material.dart';
import 'package:engineering_project/assets/components/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_page.dart'; // Giriş sayfası import edilmeli

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade200,
      appBar: AppBar(
        title: const Text("Welcome to HomePage!"),
        foregroundColor: Colors.white,
        backgroundColor: Colors.red.shade500,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () {
            // Handle back button press here
          },
        ),
      ),
      body: Center(
        child: Container(
          height: 400, // Set a specific height value here
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  FirebaseAuth.instance.currentUser?.email ?? "No User",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 40,
                  ),
                ),
                SwitchListTile(
                  title: const Text("Theme"),
                  value: false,
                  onChanged: (value) {},
                ),
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.red.shade500),
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.red.shade500,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.logout),
                    onPressed: () async {
                      await _signOutAndNavigate();
                    },
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _signOutAndNavigate() async {
    await AuthService().signOut();
    if (mounted) {
      // Widget hala aktif mi kontrol ediyoruz.
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => LoginPage()),
        (route) => false,
      );
    }
  }
}
