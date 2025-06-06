import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_fortune_wheel/flutter_fortune_wheel.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:engineering_project/l10n/app_localizations.dart';

class WheelOfDiscount extends StatefulWidget {
  const WheelOfDiscount({Key? key}) : super(key: key);

  @override
  State<WheelOfDiscount> createState() => _WheelOfDiscountState();
}

class _WheelOfDiscountState extends State<WheelOfDiscount> {
  bool isSpinning = false;
  bool hasSpunThisWeek = false;
  List<Map<String, dynamic>> wheelItems = [];
  List<FortuneItem> items = [];

  @override
  void initState() {
    super.initState();
    _checkLastSpinDate();
    _loadWheelItems();
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

  Future<void> _loadWheelItems() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('settings')
          .doc('wheel_settings')
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        setState(() {
          wheelItems = List<Map<String, dynamic>>.from(data['items'] ?? []);
          items = wheelItems.map((item) => FortuneItem(
            child: Text(
              item['value'],
              style: TextStyle(fontSize: 20),
            ),
          )).toList();
        });
      } else {
        // Default items if no settings exist
        setState(() {
          wheelItems = [
            {'value': '5%', 'weight': 20},
            {'value': '10%', 'weight': 15},
            {'value': '15%', 'weight': 10},
            {'value': '20%', 'weight': 8},
            {'value': '25%', 'weight': 5},
            {'value': 'Try Again', 'weight': 25},
            {'value': '30%', 'weight': 3},
            {'value': '40%', 'weight': 2},
            {'value': '50%', 'weight': 1},
            {'value': 'Try Again', 'weight': 11},
          ];
          items = wheelItems.map((item) => FortuneItem(
            child: Text(
              item['value'],
              style: TextStyle(fontSize: 20),
            ),
          )).toList();
        });
      }
    } catch (e) {
      print('Error loading wheel items: $e');
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
        title: Text(AppLocalizations.of(context)!.wheelManagement),
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
                items: items,
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
                ? AppLocalizations.of(context)!.comeBackNextWeek
                : isSpinning 
                  ? AppLocalizations.of(context)!.spinning
                  : AppLocalizations.of(context)!.spinTheWheel),
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

    // Calculate weighted random selection
    int totalWeight = wheelItems.fold(0, (sum, item) => sum + (item['weight'] as int));
    int randomWeight = Random().nextInt(totalWeight);
    int selected = 0;
    int currentWeight = 0;

    for (int i = 0; i < wheelItems.length; i++) {
      currentWeight += wheelItems[i]['weight'] as int;
      if (randomWeight < currentWeight) {
        selected = i;
        break;
      }
    }

    // Simulate spinning animation
    Future.delayed(Duration(seconds: 3), () {
      setState(() {
        isSpinning = false;
      });

      if (wheelItems[selected]['value'] != 'Try Again') {
        _saveSpinResult(wheelItems[selected]['value']);
      }

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(AppLocalizations.of(context)!.congratulations),
          content: Text(wheelItems[selected]['value'] == 'Try Again'
              ? AppLocalizations.of(context)!.betterLuckNextTime
              : '${AppLocalizations.of(context)!.youWonDiscount} ${wheelItems[selected]['value']}!'),
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