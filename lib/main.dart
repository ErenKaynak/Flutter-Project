import 'package:engineering_project/pages/login_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:engineering_project/pages/root_page.dart';

// Diğer import'lar şu anda kullanılmıyor, bu yüzden kaldırıldı
// import 'package:engineering_project/admin-panel/admin_main.dart';
// import 'package:engineering_project/pages/home_page.dart';
// import 'package:engineering_project/pages/auth_page.dart';
// import 'package:engineering_project/pages/login_page.dart';
// import 'package:engineering_project/pages/register_page.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  ); // Initialize Firebase app
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(debugShowCheckedModeBanner: false, home: RootScreen());
  }
}
