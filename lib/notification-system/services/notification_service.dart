import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_model.dart';

class NotificationService {
  static const String _baseUrl = 'https://notification-backend-production-314d.up.railway.app';
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get notifications for a specific user
  Stream<List<NotificationModel>> getUserNotifications(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return NotificationModel(
          id: doc.id,
          title: data['title'] as String,
          message: data['message'] as String,
          timestamp: (data['timestamp'] as Timestamp).toDate(),
          type: NotificationType.values.firstWhere(
            (e) => e.toString() == data['type'],
            orElse: () => NotificationType.general,
          ),
          imageUrl: data['imageUrl'] as String?,
          isRead: data['isRead'] as bool? ?? false,
          discountCode: data['discountCode'] as String?,
          discountPercentage: (data['discountPercentage'] as num?)?.toDouble(),
          discountId: data['discountId'] as String?,
        );
      }).toList();
    });
  }

  // Save a notification to Firestore
  Future<void> saveNotificationToFirestore({
    required String userId,
    required NotificationModel notification,
  }) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .doc(notification.id)
        .set({
      'title': notification.title,
      'message': notification.message,
      'timestamp': Timestamp.fromDate(notification.timestamp),
      'type': notification.type.toString(),
      'imageUrl': notification.imageUrl,
      'isRead': notification.isRead,
      'discountCode': notification.discountCode,
      'discountPercentage': notification.discountPercentage,
      'discountId': notification.discountId,
    });
  }

  // Mark a notification as read
  Future<void> markNotificationAsRead(String userId, String notificationId) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .doc(notificationId)
        .update({'isRead': true});
  }

  // Send notification to all users
  static Future<bool> sendToAllUsers({
    required String title,
    required String message,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final usersSnapshot = await FirebaseFirestore.instance.collection('users').get();
      
      for (var userDoc in usersSnapshot.docs) {
        final notification = NotificationModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: title,
          message: message,
          timestamp: DateTime.now(),
          type: NotificationType.general,
          imageUrl: additionalData?['imageUrl'] as String?,
        );
        
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userDoc.id)
            .collection('notifications')
            .doc(notification.id)
            .set({
          'title': notification.title,
          'message': notification.message,
          'timestamp': Timestamp.fromDate(notification.timestamp),
          'type': notification.type.toString(),
          'imageUrl': notification.imageUrl,
          'isRead': false,
        });
      }
      return true;
    } catch (e) {
      print('Error sending notification to all users: $e');
      return false;
    }
  }

  // Send notification to specific users
  static Future<bool> sendToUsers({
    required List<String> userIds,
    required String title,
    required String message,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      for (var userId in userIds) {
        final notification = NotificationModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: title,
          message: message,
          timestamp: DateTime.now(),
          type: NotificationType.general,
          imageUrl: additionalData?['imageUrl'] as String?,
        );
        
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('notifications')
            .doc(notification.id)
            .set({
          'title': notification.title,
          'message': notification.message,
          'timestamp': Timestamp.fromDate(notification.timestamp),
          'type': notification.type.toString(),
          'imageUrl': notification.imageUrl,
          'isRead': false,
        });
      }
      return true;
    } catch (e) {
      print('Error sending notification to specific users: $e');
      return false;
    }
  }

  // Send discount notification
  static Future<bool> sendDiscountNotification({
    required String title,
    required String message,
    required String discountCode,
    required double discountPercentage,
    DateTime? expiryDate,
    String? discountId,
  }) async {
    try {
      final usersSnapshot = await FirebaseFirestore.instance.collection('users').get();
      
      for (var userDoc in usersSnapshot.docs) {
        final notification = NotificationModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: title,
          message: message,
          timestamp: DateTime.now(),
          type: NotificationType.discount,
          discountCode: discountCode,
          discountPercentage: discountPercentage,
          discountId: discountId,
        );
        
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userDoc.id)
            .collection('notifications')
            .doc(notification.id)
            .set({
          'title': notification.title,
          'message': notification.message,
          'timestamp': Timestamp.fromDate(notification.timestamp),
          'type': notification.type.toString(),
          'isRead': false,
          'discountCode': notification.discountCode,
          'discountPercentage': notification.discountPercentage,
          'discountId': notification.discountId,
        });
      }
      return true;
    } catch (e) {
      print('Error sending discount notification: $e');
      return false;
    }
  }
} 