import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_fortune_wheel/flutter_fortune_wheel.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:engineering_project/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:engineering_project/pages/theme_notifier.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:engineering_project/assets/components/discount_code.dart';
import 'package:engineering_project/assets/components/discount_service.dart';
import 'package:engineering_project/screens/discount_codes_screen.dart';

class WheelOfDiscount extends StatefulWidget {
  const WheelOfDiscount({Key? key}) : super(key: key);

  @override
  State<WheelOfDiscount> createState() => _WheelOfDiscountState();
}

class _WheelOfDiscountState extends State<WheelOfDiscount> with SingleTickerProviderStateMixin {
  bool isSpinning = false;
  bool hasSpunThisWeek = false;
  bool isInitialized = false;
  List<Map<String, dynamic>> wheelItems = [];
  List<FortuneItem> items = [];
  late AnimationController _animationController;
  late Animation<double> _animation;
  StreamController<int> _selectedController = StreamController<int>.broadcast();

  @override
  void initState() {
    super.initState();
    _checkLastSpinDate();
    _loadWheelItems().then((_) {
      setState(() {
        isInitialized = true;
      });
    });
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _selectedController.add(0); // Initialize with first item
  }

  @override
  void dispose() {
    _selectedController.close();
    _animationController.dispose();
    super.dispose();
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
          items = wheelItems.asMap().entries.map((entry) {
            int index = entry.key;
            Map<String, dynamic> item = entry.value;
            // Define a list of colors to cycle through
            final List<Color> segmentColors = [
              Colors.deepPurple.shade700,
              Colors.amber.shade700,
              Colors.teal.shade700,
              Colors.red.shade700,
              Colors.blue.shade700,
              Colors.pink.shade700,
              Colors.green.shade700,
              Colors.orange.shade700,
            ];
            // Get color based on index, cycling through the list
            final Color segmentColor = segmentColors[index % segmentColors.length];

            return FortuneItem(
              style: FortuneItemStyle(
                color: segmentColor, // Assign the determined color
                borderColor: Colors.black.withOpacity(0.4), // Keep border dark
                borderWidth: 4, // Keep border thickness
              ),
              child: Text(
                item['value'],
                style: const TextStyle(
                  fontSize: 18, // Keep font size
                  fontWeight: FontWeight.bold,
                  color: Colors.white, // Keep text color white
                ),
              ),
            );
          }).toList();
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
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
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

    try {
      // Generate a unique discount code
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final random = Random().nextInt(1000);
      final code = 'WHEEL${timestamp.toString().substring(8)}${random.toString().padLeft(3, '0')}';
      
      // Extract discount percentage from the wheel result
      final discountPercentage = double.parse(discount.replaceAll('%', ''));
      
      // Create a new document reference first
      final docRef = FirebaseFirestore.instance.collection('discountCodes').doc();
      
      // Create a new discount code with the generated document ID
      final discountCode = DiscountCode(
        id: docRef.id,
        code: code,
        name: 'Wheel of Fortune Discount',
        description: 'Won from the Wheel of Fortune! Minimum order amount: ₺10,000',
        discountPercentage: discountPercentage,
        minOrderAmount: 10000, // Set minimum order amount to 10,000 TL
        expiryDate: DateTime.now().add(const Duration(days: 7)), // Valid for 7 days
        applicableCategories: null, // Applicable to all categories
        usageLimit: 1, // One-time use
        usageCount: 0,
        perUserLimit: 1, // One per user
      );

      // Save to Firestore using the discount service
      final discountService = DiscountService();
      final success = await discountService.createDiscountCode(discountCode);

      if (success) {
        // Save to user's saved discounts collection
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('savedDiscounts')
            .doc(docRef.id)
            .set({
          'code': code,
          'discountPercentage': discountPercentage,
          'expiryDate': Timestamp.fromDate(discountCode.expiryDate!),
          'isUsed': false,
          'receivedAt': Timestamp.now(),
          'isPercent': true,
          'description': 'Wheel of Fortune Discount - Minimum order amount: ₺10,000',
          'minOrderAmount': 10000, // Add minimum order amount
        });

        // Save last spin date
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('last_spin_date', DateTime.now().toIso8601String());

        setState(() {
          hasSpunThisWeek = true;
        });

        // Show success message with the code and minimum order amount
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Your discount code is: $code\nMinimum order amount: ₺10,000'),
              duration: const Duration(seconds: 5),
              action: SnackBarAction(
                label: 'Copy',
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: code));
                },
              ),
            ),
          );
        }
      } else {
        throw Exception('Failed to create discount code');
      }
    } catch (e) {
      print('Error saving spin result: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error saving your discount. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isBlack = themeNotifier.isBlackMode;
    final isDarkMode = isDark || isBlack;
    
    final themeColor = themeNotifier.isSpecialModeActive 
        ? themeNotifier.getThemeColor(themeNotifier.specialTheme)
        : Colors.red.shade700;
    
    final backgroundColor = themeNotifier.isSpecialModeActive
        ? themeNotifier.getThemeColor(themeNotifier.specialTheme).withOpacity(0.1)
        : isDarkMode
            ? const Color(0xFF1A1A1A)
            : const Color(0xFFF5F5F5);
            
    final appBarColor = themeNotifier.isSpecialModeActive
        ? themeNotifier.getThemeColor(themeNotifier.specialTheme)
        : isDarkMode
            ? const Color(0xFF2C2C2C)
            : Colors.white;
            
    final outlineColor = isDarkMode
        ? Colors.white.withOpacity(0.2)
        : themeNotifier.isSpecialModeActive
            ? themeNotifier.getThemeColor(themeNotifier.specialTheme).withOpacity(0.3)
            : Colors.red.withOpacity(0.3);

    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: appBarColor,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
        ),
        elevation: 15,
        shadowColor: themeColor.withOpacity(0.5),
        title: Text(
          l10n.wheelManagement,
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 24,
            letterSpacing: 1.2,
          ),
        ),
        iconTheme: IconThemeData(
          color: isDarkMode ? Colors.white : Colors.black87,
          size: 28,
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDarkMode
                ? [
                    themeNotifier.isSpecialModeActive
                        ? themeNotifier.getThemeColor(themeNotifier.specialTheme).shade900
                        : const Color(0xFF2C2C2C),
                    themeNotifier.isSpecialModeActive
                        ? themeNotifier.getThemeColor(themeNotifier.specialTheme).shade800
                        : const Color(0xFF1A1A1A),
                  ]
                : [
                    themeNotifier.isSpecialModeActive
                        ? themeNotifier.getThemeColor(themeNotifier.specialTheme).shade100
                        : const Color(0xFFF8F8F8),
                    themeNotifier.isSpecialModeActive
                        ? themeNotifier.getThemeColor(themeNotifier.specialTheme).shade50
                        : Colors.white,
                  ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!isInitialized)
                const CircularProgressIndicator()
              else
                Container(
                  height: 380,
                  width: 380,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: themeColor.withOpacity(0.4),
                        blurRadius: 30,
                        spreadRadius: 10,
                      ),
                      BoxShadow(
                        color: isDarkMode ? Colors.black.withOpacity(0.3) : Colors.white.withOpacity(0.8),
                        blurRadius: 20,
                        spreadRadius: -5,
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              themeColor.withOpacity(0.2),
                              themeColor.withOpacity(0.1),
                              Colors.transparent,
                            ],
                            stops: const [0.0, 0.5, 1.0],
                          ),
                        ),
                      ),
                      FortuneWheel(
                        animateFirst: false,
                        selected: _selectedController.stream,
                        items: items,
                        onFling: null,
                        physics: CircularPanPhysics(
                          duration: const Duration(seconds: 3),
                          curve: Curves.easeOutCubic,
                        ),
                        onAnimationEnd: () {
                          setState(() {
                            isSpinning = false;
                          });
                        },
                        onAnimationStart: () {
                          setState(() {
                            isSpinning = true;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 50),
              Container(
                width: 220,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDarkMode
                        ? [
                            themeNotifier.isSpecialModeActive
                                ? themeNotifier.getThemeColor(themeNotifier.specialTheme).shade900
                                : Colors.red.shade900,
                            themeNotifier.isSpecialModeActive
                                ? themeNotifier.getThemeColor(themeNotifier.specialTheme).shade800
                                : Colors.red.shade800,
                          ]
                        : [
                            themeNotifier.isSpecialModeActive
                                ? themeNotifier.getThemeColor(themeNotifier.specialTheme).shade500
                                : Colors.red.shade500,
                            themeNotifier.isSpecialModeActive
                                ? themeNotifier.getThemeColor(themeNotifier.specialTheme).shade400
                                : Colors.red.shade400,
                          ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: themeColor.withOpacity(0.4),
                      blurRadius: 15,
                      spreadRadius: 3,
                    ),
                    BoxShadow(
                      color: isDarkMode ? Colors.black.withOpacity(0.2) : Colors.white.withOpacity(0.8),
                      blurRadius: 10,
                      spreadRadius: -2,
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: (!isInitialized || hasSpunThisWeek || isSpinning) ? null : _spinWheel,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  ),
                  child: Text(
                    !isInitialized
                        ? 'Loading...'
                        : hasSpunThisWeek 
                            ? l10n.comeBackNextWeek
                            : isSpinning 
                                ? l10n.spinning
                                : l10n.spinTheWheel,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),
              if (hasSpunThisWeek)
                Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: isDarkMode ? Colors.grey[800]?.withOpacity(0.5) : Colors.grey[200]?.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      l10n.comeBackNextWeek,
                      style: TextStyle(
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
            ],
          ),
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

    // Calculate the number of full rotations (5) plus the selected position
    final rotations = 5;
    final selectedPosition = selected;
    final totalItems = wheelItems.length;
    final degreesPerItem = 360 / totalItems;
    final targetRotation = (rotations * 360) + (selectedPosition * degreesPerItem);

    // Update the selected item stream to trigger the animation
    _selectedController.add(selected);

    // Show result after animation
    Future.delayed(const Duration(seconds: 3), () {
      if (wheelItems[selected]['value'] != 'Try Again') {
        _saveSpinResult(wheelItems[selected]['value']);
      }

      final themeNotifier = Provider.of<ThemeNotifier>(context, listen: false);
      final isDark = Theme.of(context).brightness == Brightness.dark;
      final themeColor = themeNotifier.isSpecialModeActive 
          ? themeNotifier.getThemeColor(themeNotifier.specialTheme)
          : Colors.red.shade700;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: isDark ? Colors.grey[900] : Colors.white,
          title: Text(
            AppLocalizations.of(context)!.congratulations,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                wheelItems[selected]['value'] == 'Try Again'
                    ? AppLocalizations.of(context)!.betterLuckNextTime
                    : '${AppLocalizations.of(context)!.youWonDiscount} ${wheelItems[selected]['value']}!',
                style: TextStyle(
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
              if (wheelItems[selected]['value'] != 'Try Again') ...[
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    // Navigate to discount codes screen
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const DiscountCodesScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.discount),
                  label: const Text('View My Discounts'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: themeColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'OK',
                style: TextStyle(
                  color: themeColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}