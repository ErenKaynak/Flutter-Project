import 'package:engineering_project/assets/components/stripe_service.dart';
import 'package:engineering_project/pages/root_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await StripeService.initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Engineering Project',
      theme: ThemeData(
        primarySwatch: Colors.red,
      ),
      home: const RootScreen(), // Replace with your home page
    );
  }
}