import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_fortune_wheel/flutter_fortune_wheel.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WheelOfDiscount extends StatefulWidget {
  const WheelOfDiscount({Key? key}) : super(key: key);

  @override
  State<WheelOfDiscount> createState() => _WheelOfDiscountState();
}

class _WheelOfDiscountState extends State<WheelOfDiscount> {
  bool isSpinning = false;
  bool hasSpunThisWeek = false;
  final List<String> items = [
    '5%', '10%', '15%', '20%', '25%', 'Try Again',
    '30%', '40%', '50%', 'Try Again'
  ];

  @override
  void initState() {
    super.initState();
    _checkLastSpinDate();
  }

  Future<void> _checkLastSpinDate() async {
    final prefs = await SharedPreferences.getInstance();
    final lastSpinDate = prefs.getString('last_spin_date');
    
    if (lastSpinDate != null) {
      final lastSpin = DateTime.parse(lastSpinDate);
      final now = DateTime.now();
      final difference = now.difference(lastSpin).inDays;
      
      setState(() {
        hasSpunThisWeek = difference < 7;
      });
    }
  }

  Future<void> _saveSpinResult(String discount) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Save to Firestore
    await FirebaseFirestore.instance.collection('users').doc(user.uid)
        .collection('discounts').add({
      'discount': discount,
      'createdAt': FieldValue.serverTimestamp(),
      'used': false,
    });

    // Save last spin date
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_spin_date', DateTime.now().toIso8601String());

    setState(() {
      hasSpunThisWeek = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Wheel of Discount'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 300,
              child: FortuneWheel(
                animateFirst: false,
                selected: Stream.value(0),
                items: items.map((item) => FortuneItem(
                  child: Text(item, style: TextStyle(fontSize: 20)),
                )).toList(),
                onFling: () {
                  if (!hasSpunThisWeek && !isSpinning) {
                    _spinWheel();
                  }
                },
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: hasSpunThisWeek || isSpinning ? null : _spinWheel,
              child: Text(hasSpunThisWeek 
                ? 'Come back next week!' 
                : isSpinning 
                  ? 'Spinning...' 
                  : 'Spin the Wheel!'),
            ),
          ],
        ),
      ),
    );
  }

  void _spinWheel() {
    if (hasSpunThisWeek || isSpinning) return;

    setState(() {
      isSpinning = true;
    });

    final random = Random();
    final selected = random.nextInt(items.length);

    // Simulate spinning animation
    Future.delayed(Duration(seconds: 3), () {
      setState(() {
        isSpinning = false;
      });

      if (items[selected] != 'Try Again') {
        _saveSpinResult(items[selected]);
      }

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Congratulations!'),
          content: Text(items[selected] == 'Try Again' 
              ? 'Better luck next time!' 
              : 'You won ${items[selected]} discount!'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK'),
            ),
          ],
        ),
      );
    });
  }
}