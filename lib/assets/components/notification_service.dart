import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class NotificationService {
  static final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  static String? _serverKey; // Make it nullable

  static bool get isConfigured => _serverKey != null;

  // Initialize notifications
  static Future<void> init() async {
    try {
      // Request permission
      await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      // Get FCM token
      String? token = await _fcm.getToken();
      if (token != null) {
        await saveTokenToFirestore(token);
      }

      // Listen to token refresh
      _fcm.onTokenRefresh.listen(saveTokenToFirestore);

      // Handle background messages
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        _handleForegroundMessage(message);
      });

      // Handle notification tap when app is in background but opened
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        _handleNotificationTap(message);
      });

    } catch (e) {
      print('Notification initialization error: $e');
      // Continue without notifications if there's an error
    }
  }

  static void configure(String serverKey) {
    _serverKey = serverKey;
  }

  // Save FCM token to Firestore
  static Future<void> saveTokenToFirestore(String token) async {
    await FirebaseFirestore.instance
        .collection('fcmTokens')
        .doc(token)
        .set({
      'token': token,
      'createdAt': FieldValue.serverTimestamp(),
      'platform': Platform.operatingSystem,
    });
  }

  // Send notification to all users
  static Future<bool> sendToAllUsers({
    required String title,
    required String message,
    String? imageUrl,
  }) async {
    if (_serverKey == null) {
      print('FCM not configured: Notifications are disabled');
      return false;
    }

    try {
      // Get all FCM tokens
      final tokensSnapshot = await FirebaseFirestore.instance
          .collection('fcmTokens')
          .get();

      final List<String> tokens = tokensSnapshot.docs
          .map((doc) => doc.data()['token'] as String)
          .toList();

      if (tokens.isEmpty) {
        print('No tokens found to send notifications');
        return false;
      }

      // Create notification data
      final notificationData = {
        'registration_ids': tokens,
        'notification': {
          'title': title,
          'body': message,
          'sound': 'default',
        },
        'data': {
          'click_action': 'FLUTTER_NOTIFICATION_CLICK',
          'type': 'general',
          if (imageUrl != null) 'image': imageUrl,
        },
      };

      // Send notification using FCM
      final response = await http.post(
        Uri.parse('https://fcm.googleapis.com/fcm/send'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'key=$_serverKey',
        },
        body: json.encode(notificationData),
      );

      // Store notification in Firestore
      await FirebaseFirestore.instance.collection('notifications').add({
        'title': title,
        'message': message,
        'timestamp': FieldValue.serverTimestamp(),
        'type': 'general',
        if (imageUrl != null) 'imageUrl': imageUrl,
        'status': response.statusCode == 200 ? 'sent' : 'failed',
        'isRead': false,
      });

      return response.statusCode == 200;
    } catch (e) {
      print('Error sending notification to all users: $e');
      return false;
    }
  }

  // Handle background messages
  static Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
    print('Handling background message: ${message.messageId}');
    await _saveNotificationToFirestore(message);
  }

  // Handle foreground messages
  static void _handleForegroundMessage(RemoteMessage message) async {
    print('Received foreground message: ${message.messageId}');
    await _saveNotificationToFirestore(message);
  }

  // Handle notification tap
  static void _handleNotificationTap(RemoteMessage message) async {
    print('Notification tapped: ${message.messageId}');
    // You can add navigation logic here
  }

  // Save notification to Firestore
  static Future<void> _saveNotificationToFirestore(RemoteMessage message) async {
    try {
      await FirebaseFirestore.instance.collection('notifications').add({
        'title': message.notification?.title,
        'message': message.notification?.body,
        'timestamp': FieldValue.serverTimestamp(),
        'data': message.data,
        'messageId': message.messageId,
        'isRead': false,
      });
    } catch (e) {
      print('Error saving notification to Firestore: $e');
    }
  }

  // Send notification to specific topic
  static Future<bool> sendToTopic({
    required String topic,
    required String title,
    required String message,
  }) async {
    if (_serverKey == null) {
      print('FCM not configured: Notifications are disabled');
      return false;
    }

    try {
      final response = await http.post(
        Uri.parse('https://fcm.googleapis.com/fcm/send'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'key=$_serverKey',
        },
        body: json.encode({
          'to': '/topics/$topic',
          'notification': {
            'title': title,
            'body': message,
            'sound': 'default',
          },
          'data': {
            'click_action': 'FLUTTER_NOTIFICATION_CLICK',
            'status': 'done',
          },
        }),
      );

      // Store notification in Firestore
      await FirebaseFirestore.instance.collection('notifications').add({
        'title': title,
        'message': message,
        'topic': topic,
        'timestamp': FieldValue.serverTimestamp(),
        'status': response.statusCode == 200 ? 'sent' : 'failed',
      });

      return response.statusCode == 200;
    } catch (e) {
      print('Error sending notification: $e');
      return false;
    }
  }

  // Send notification to specific users
  static Future<bool> sendToUsers({
    required List<String> userTokens,
    required String title,
    required String message,
  }) async {
    if (_serverKey == null) {
      print('FCM not configured: Notifications are disabled');
      return false;
    }

    try {
      final response = await http.post(
        Uri.parse('https://fcm.googleapis.com/fcm/send'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'key=$_serverKey',
        },
        body: json.encode({
          'registration_ids': userTokens,
          'notification': {
            'title': title,
            'body': message,
            'sound': 'default',
          },
          'data': {
            'click_action': 'FLUTTER_NOTIFICATION_CLICK',
            'status': 'done',
          },
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error sending notification: $e');
      return false;
    }
  }

  // Mark notification as read
  static Future<void> markAsRead(String notificationId) async {
    try {
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  // Mark all notifications as read
  static Future<void> markAllAsRead() async {
    try {
      final QuerySnapshot notifications = await FirebaseFirestore.instance
          .collection('notifications')
          .where('isRead', isEqualTo: false)
          .get();

      if (notifications.docs.isEmpty) {
        return;
      }

      final batch = FirebaseFirestore.instance.batch();
      for (var doc in notifications.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();
    } catch (e) {
      print('Error marking all notifications as read: $e');
      rethrow;
    }
  }

  // Get unread notification count
  static Stream<int> getUnreadCount() {
    return FirebaseFirestore.instance
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.size);
  }
}