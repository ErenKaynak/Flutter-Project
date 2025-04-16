import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:engineering_project/assets/components/discount_code.dart';

class DiscountService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  Future<DiscountCode?> validateCode(String code) async {
    try {
      final querySnapshot = await _firestore
          .collection('discountCodes')
          .where('code', isEqualTo: code)
          .limit(1)
          .get();
      
      if (querySnapshot.docs.isEmpty) {
        return null;
      }
      
      final discountCode = DiscountCode.fromFirestore(querySnapshot.docs.first);
      
      if (!discountCode.isValid()) {
        return null;
      }
      
      return discountCode;
    } catch (e) {
      print('Error validating discount code: $e');
      return null;
    }
  }
  
  Future<bool> applyDiscount(String discountId) async {
    try {
      // Increment usage count
      await _firestore
          .collection('discountCodes')
          .doc(discountId)
          .update({'usageCount': FieldValue.increment(1)});
      
      return true;
    } catch (e) {
      print('Error applying discount: $e');
      return false;
    }
  }
  
  Future<List<DiscountCode>> getAllDiscountCodes() async {
    try {
      final querySnapshot = await _firestore
          .collection('discountCodes')
          .get();
      
      return querySnapshot.docs
          .map((doc) => DiscountCode.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error fetching discount codes: $e');
      return [];
    }
  }
  
  Future<bool> createDiscountCode(DiscountCode discountCode) async {
    try {
      // Check if code already exists
      final existingCodes = await _firestore
          .collection('discountCodes')
          .where('code', isEqualTo: discountCode.code)
          .get();
      
      if (existingCodes.docs.isNotEmpty) {
        return false; // Code already exists
      }
      
      await _firestore
          .collection('discountCodes')
          .add(discountCode.toMap());
      
      return true;
    } catch (e) {
      print('Error creating discount code: $e');
      return false;
    }
  }
  
  Future<bool> deleteDiscountCode(String id) async {
    try {
      await _firestore
          .collection('discountCodes')
          .doc(id)
          .delete();
      
      return true;
    } catch (e) {
      print('Error deleting discount code: $e');
      return false;
    }
  }
}