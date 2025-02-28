import 'package:flutter/material.dart';

class SquareTile extends StatefulWidget {
  final String imagePath;
  final onPressed;
  const SquareTile({
    super.key, 
    required this.imagePath,
    required this.onPressed,
    });

  @override
  State<SquareTile> createState() => _SquareTileState();
}

class _SquareTileState extends State<SquareTile> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(5),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white),
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
      ),
      child: IconButton(
        onPressed: widget.onPressed,
        icon: Image.asset(widget.imagePath, height: 40),
      ),
    );
  }
}
