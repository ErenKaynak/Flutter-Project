import 'package:engineering_project/assets/components/auth_service.dart';
import 'package:engineering_project/assets/components/square_tile.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(child: Text("Welcome to HomePage!")),
        foregroundColor: Colors.white,
        backgroundColor: Colors.red.shade500,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: 
          [
            Text(
              AuthService().getCurrentUser()!.email.toString(),
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 40),
            ),
            
            SwitchListTile(
              title: Text("Theme"),
              value: false, 
              onChanged: (value) {},
            ),
            
            Padding(
              padding: const EdgeInsets.fromLTRB(300,500,0,0),
              child: Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                border: Border.all(color: Colors.red.shade500),
                borderRadius: BorderRadius.circular(12),
                color: Colors.red.shade500,
                ),
                    child: IconButton(
                    icon: Icon(Icons.logout),
                    onPressed: AuthService().signOut,
                    color: Colors.white,
                  ),
              ),
            ),

          ],
        ),
      ),
    );
  }
}