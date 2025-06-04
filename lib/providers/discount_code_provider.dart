import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:engineering_project/models/discount_code.dart';

class DiscountCodeProvider extends ChangeNotifier {
  final List<DiscountCode> _discountCodes = [];
  bool _isLoading = false;
  
  List<DiscountCode> get discountCodes => _discountCodes;
  bool get isLoading => _isLoading;

  Future<void> handleDiscountNotification(Map<String, dynamic> data) async {
    if (!data.containsKey('discountCode')) return;

    try {
      final discountData = data['discountCode'] as Map<String, dynamic>;
      final discountCode = DiscountCode.fromJson(discountData);
      
      // Save to Firestore first
      await saveDiscountCode(discountCode);
      
      // Add to local list and notify listeners
      _discountCodes.add(discountCode);
      notifyListeners();
    } catch (e) {
      print('Error handling discount notification: $e');
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
        .set(code.toJson());
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

      _discountCodes.clear();
      _discountCodes.addAll(
        snapshot.docs.map((doc) => DiscountCode.fromJson({
          'id': doc.id,
          ...doc.data(),
        }))
      );

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

      final index = _discountCodes.indexWhere((code) => code.id == codeId);
      if (index != -1) {
        _discountCodes[index] = DiscountCode(
          id: _discountCodes[index].id,
          code: _discountCodes[index].code,
          description: _discountCodes[index].description,
          value: _discountCodes[index].value,
          validFrom: _discountCodes[index].validFrom,
          expiryDate: _discountCodes[index].expiryDate,
          isPercent: _discountCodes[index].isPercent,
          isUsed: true,
          maxUses: _discountCodes[index].maxUses,
          perUserLimit: _discountCodes[index].perUserLimit,
          receivedAt: _discountCodes[index].receivedAt,
        );
        notifyListeners();
      }
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

      _discountCodes.removeWhere((code) => code.id == codeId);
      notifyListeners();
    } catch (e) {
      print('Error deleting discount code: $e');
    }
  }
}
