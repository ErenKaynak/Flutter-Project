import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../notification-system/models/notification_model.dart';

class NotificationHandler {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Save a discount code from a notification
  Future<void> saveDiscountCode(String notificationId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      // Get the notification
      final notificationDoc = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .doc(notificationId)
          .get();

      if (!notificationDoc.exists) return;

      final notification = NotificationModel.fromFirestore(notificationDoc);

      // Save the discount code to user's saved discounts
      if (notification.discountCode != null && notification.discountPercentage != null) {
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('saved_discounts')
            .doc(notification.discountId ?? notification.discountCode)
            .set({
          'code': notification.discountCode,
          'percentage': notification.discountPercentage,
          'savedAt': FieldValue.serverTimestamp(),
          'notificationId': notificationId,
        });
      }
    } catch (e) {
      print('Error saving discount code: $e');
      rethrow;
    }
  }

  // Get user's saved discount codes
  Stream<List<Map<String, dynamic>>> getSavedDiscountCodes() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('saved_discounts')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'code': data['code'] as String,
          'percentage': data['percentage'] as double,
          'savedAt': (data['savedAt'] as Timestamp).toDate(),
          'notificationId': data['notificationId'] as String,
        };
      }).toList();
    });
  }

  // Delete a saved discount code
  Future<void> deleteSavedDiscountCode(String discountId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('saved_discounts')
          .doc(discountId)
          .delete();
    } catch (e) {
      print('Error deleting saved discount code: $e');
      rethrow;
    }
  }
} 