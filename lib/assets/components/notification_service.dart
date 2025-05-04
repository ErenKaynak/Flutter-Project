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
}