import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

class NotificationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static Stream<int> getUnreadCount() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value(0);
    }

    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: user.uid)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  static Future<void> markAsRead(String notificationId) async {
    await _firestore.collection('notifications').doc(notificationId).update({
      'isRead': true,
    });
  }

  static Future<void> markAllAsRead() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final batch = _firestore.batch();
    final notifications = await _firestore
        .collection('notifications')
        .where('userId', isEqualTo: user.uid)
        .where('isRead', isEqualTo: false)
        .get();

    for (var doc in notifications.docs) {
      batch.update(doc.reference, {'isRead': true});
    }

    await batch.commit();
  }

  static Stream<QuerySnapshot> getNotifications() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return Stream.empty();

    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  static Future<void> markMultipleAsRead(List<String> notificationIds) async {
    final batch = _firestore.batch();
    for (final id in notificationIds) {
      final docRef = _firestore.collection('notifications').doc(id);
      batch.update(docRef, {'isRead': true});
    }
    await batch.commit();
  }

  static Future<void> deleteNotification(String notificationId) async {
    await _firestore.collection('notifications').doc(notificationId).delete();
  }

  static Future<void> deleteMultipleNotifications(List<String> notificationIds) async {
    final batch = _firestore.batch();
    for (final id in notificationIds) {
      final docRef = _firestore.collection('notifications').doc(id);
      batch.delete(docRef);
    }
    await batch.commit();
  }

  static Future<bool> sendToAllUsers({
    required String title,
    required String message,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final users = await _firestore.collection('users').get();
      final batch = _firestore.batch();

      for (final user in users.docs) {
        final notificationRef = _firestore.collection('notifications').doc();
        batch.set(notificationRef, {
          'title': title,
          'message': message,
          'userId': user.id,
          'timestamp': FieldValue.serverTimestamp(),
          'isRead': false,
          if (additionalData != null) ...additionalData,
        });
      }

      await batch.commit();
      return true;
    } catch (e) {
      print('Error sending notification to all users: $e');
      return false;
    }
  }

  static Future<bool> sendToUsers({
    required List<String> userIds,
    required String title,
    required String message,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final batch = _firestore.batch();

      for (final userId in userIds) {
        final notificationRef = _firestore.collection('notifications').doc();
        batch.set(notificationRef, {
          'title': title,
          'message': message,
          'userId': userId,
          'timestamp': FieldValue.serverTimestamp(),
          'isRead': false,
          if (additionalData != null) ...additionalData,
        });
      }

      await batch.commit();
      return true;
    } catch (e) {
      print('Error sending notification to selected users: $e');
      return false;
    }
  }

  static Future<void> saveNotificationToFirestore({
    required String userId,
    required Map<String, dynamic> notification,
  }) async {
    await _firestore.collection('notifications').add({
      ...notification,
      'userId': userId,
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': false,
    });
  }
} 