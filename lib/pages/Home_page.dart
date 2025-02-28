import 'package:engineering_project/assets/components/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  HomePage({super.key});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [IconButton(onPressed: AuthService().signOut, icon: Icon(Icons.logout))],
        backgroundColor: Colors.blue[300],
      ),
      body: Center(
        child: Text(
        AuthService().getCurrentUser()!.email.toString(),
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 40),
        
        )),
    );
  }
}
