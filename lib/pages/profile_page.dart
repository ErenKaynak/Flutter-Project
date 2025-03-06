import 'package:flutter/material.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _SearchPageState();
}

class _SearchPageState extends State<ProfilePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:
        Center(child: Text('Profile Page',))
      );
  }
}

//TODO: finish this screen
