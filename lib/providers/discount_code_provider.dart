import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:engineering_project/assets/components/discount_code.dart';

class DiscountCodeProvider extends ChangeNotifier {
  bool _isLoading = false;
  
  bool get isLoading => _isLoading;

  DiscountCodeProvider() {
  }

  Future<void> saveDiscountFromNotification(Map<String, dynamic> data) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    print('saveDiscountFromNotification received data: $data');

    if (data['type'] == 'promotion' && data['discountCode'] != null) {
      try {
        final discountCodeData = {
          'id': data['discountId'] ?? '${user.uid}_${data['discountCode'] as String}',
          'code': data['discountCode'] as String,
          'name': data['title'] as String? ?? data['discountCode'] as String,
          'description': data['message'] as String? ?? 'Discount from notification',
          'discountPercentage': (data['discountPercentage'] as num?)?.toDouble() ?? 0.0,
          'minOrderAmount': (data['minOrderAmount'] as num?)?.toDouble() ?? 0.0,
          'expiryDate': data['expiryDate'] != null 
                      ? Timestamp.fromDate(DateTime.parse(data['expiryDate'] as String))
                      : null,
          'applicableCategories': data['applicableCategories'] != null 
                 ? List<String>.from(data['applicableCategories']) : null,
          'usageLimit': (data['usageLimit'] as int?) ?? 0,
          'usageCount': (data['usageCount'] as int?) ?? 0,
          'isActive': data['isActive'] as bool? ?? true,
          'perUserLimit': (data['perUserLimit'] as int?) ?? 0,
          'isUsed': false,
          'receivedAt': Timestamp.now(),
        };

        print('Attempting to save discount data to Firestore: $discountCodeData');

        final existingDiscounts = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('saved_discounts')
            .where('code', isEqualTo: discountCodeData['code'])
            .limit(1)
            .get();

        if (existingDiscounts.docs.isNotEmpty) {
           print('Discount code ${discountCodeData['code']} already saved for user.');
           return;
        }

        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('saved_discounts')
            .doc(discountCodeData['id'])
            .set(discountCodeData);

        print('Discount code ${discountCodeData['code']} saved to Firestore for user ${user.uid}');

      } catch (e) {
        print('Error saving discount from notification: $e');
      }
    }
  }

  Future<void> handleDiscountNotification(Map<String, dynamic> data) async {
    if (data['type'] == 'promotion' && data['discountCode'] != null) {
      await saveDiscountFromNotification(data);
    }
  }

  Future<void> saveDiscountCode(DiscountCode code) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('discountCodes')
        .doc(code.id)
        .set(code.toMap());
  }

  Future<void> loadDiscountCodes() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      _isLoading = true;
      notifyListeners();

      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('discountCodes')
          .orderBy('receivedAt', descending: true)
          .get();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('Error loading discount codes: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markAsUsed(String codeId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('discountCodes')
          .doc(codeId)
          .update({'isUsed': true});
    } catch (e) {
      print('Error marking discount code as used: $e');
    }
  }

  Future<void> deleteDiscountCode(String codeId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('discountCodes')
          .doc(codeId)
          .delete();
    } catch (e) {
      print('Error deleting discount code: $e');
    }
  }

  Future<List<DiscountCode>> getSavedDiscounts() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('saved_discounts')
          .get();

      final now = DateTime.now();

      return snapshot.docs.map((doc) {
          return DiscountCode.fromFirestore(doc);
        })
        .where((discount) {
           final bool expiredByExpiryDate = discount.expiryDate != null && now.isAfter(discount.expiryDate!);
           final bool expiredBy24HoursAndUnused = !discount.isUsed && now.difference(discount.receivedAt).inHours >= 24;

           return !expiredByExpiryDate && !expiredBy24HoursAndUnused;
        })
        .toList();

    } catch (e) {
      print('Error getting saved discounts: $e');
      return [];
    }
  }
}
