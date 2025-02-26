import 'package:flutter/material.dart';

class Signup extends StatelessWidget {
  const Signup({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
          child: Column( 
            children: <Widget>[
              Container(
                height:200,
                color: Colors.blue,
              )
            ]
          ),
        ),
      ),
    );
  }
}