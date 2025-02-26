import 'package:flutter/material.dart';

class SquareTile extends StatelessWidget {
  final String imagePath;
  const SquareTile({
    super.key,
    required this.imagePath,
    });

  @override
  Widget build(BuildContext context) {
   return Container(
    padding: EdgeInsets.all(5),
    decoration: BoxDecoration(
      border: Border.all(color: Colors.white,),
        borderRadius: BorderRadius.circular(12),
        color: Colors.white
        ),
      child: Image.asset(
        imagePath,
        height: 40.0, // Added '.0' to make the value a double
      ),
    );
  }
}
