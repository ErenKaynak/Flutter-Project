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
      
      // Check if code is expired
      if (discountCode.expiryDate != null && 
          discountCode.expiryDate!.isBefore(DateTime.now())) {
        // Deactivate the expired code
        await deactivateExpiredCode(discountCode.id);
        return null;
      }
      
      // Check if usage limit is reached
      if (discountCode.usageLimit > 0 && 
          discountCode.usageCount >= discountCode.usageLimit) {
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
      // Get the current discount code
      final docRef = _firestore.collection('discountCodes').doc(discountId);
      final doc = await docRef.get();
      
      if (!doc.exists) {
        return false;
      }

      final currentCode = DiscountCode.fromFirestore(doc);
      
      // Check if we can still use this code
      if (currentCode.usageLimit > 0 && 
          currentCode.usageCount >= currentCode.usageLimit) {
        return false;
      }

      // Start a batch write
      final batch = _firestore.batch();
      
      // Update usage count
      batch.update(docRef, {
        'usageCount': FieldValue.increment(1),
      });
      
      // Commit the batch
      await batch.commit();
      
      return true;
    } catch (e) {
      print('Error applying discount: $e');
      return false;
    }
  }
  
  Future<List<DiscountCode>> getAllDiscountCodes() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('discountCodes')
          .get();

      return snapshot.docs.map((doc) => 
        DiscountCode.fromMap(doc.data(), doc.id)  // Pass the document ID
      ).toList();
    } catch (e) {
      print('Error getting discount codes: $e');
      return [];
    }
  }
  
  Future<bool> createDiscountCode(DiscountCode discountCode) async {
    try {
      // Check if code already exists (case-insensitive)
      final existingCodes = await _firestore
          .collection('discountCodes')
          .where('code', isEqualTo: discountCode.code.trim())
          .get();
      
      if (existingCodes.docs.isNotEmpty) {
        print('Discount code already exists');
        return false;
      }
      
      // Create new document with the code
      final docRef = _firestore.collection('discountCodes').doc();
      await docRef.set({
        ...discountCode.toMap(),
        'id': docRef.id,
        'isActive': true, // Add active status
        'createdAt': FieldValue.serverTimestamp(),
      });
      
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

  Future<void> deactivateExpiredCode(String codeId) async {
    try {
      await _firestore
          .collection('discountCodes')
          .doc(codeId)
          .update({'isActive': false});
    } catch (e) {
      print('Error deactivating expired code: $e');
    }
  }
}