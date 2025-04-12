import 'package:engineering_project/admin-panel/admin_root.dart';
import 'package:engineering_project/admin-panel/admin_user.dart';
import 'package:engineering_project/firebase_options.dart';
import 'package:engineering_project/pages/login_page.dart';
import 'package:engineering_project/pages/register_page.dart';
import 'package:engineering_project/pages/root_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return CircularProgressIndicator(); // or splash screen
          }
          if (snapshot.hasData) {
            return RootScreen(); // User is logged in
          }
          return LoginPage(); // User not logged in
        },
      ),
    );
  }
}
      
