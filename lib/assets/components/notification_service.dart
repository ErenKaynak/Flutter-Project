import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class NotificationService {
  static bool _isInitialized = false;
  static bool get isConfigured => _isInitialized;
  static String? _restApiKey;
  static String? _appId;

  // Helper method to get headers for OneSignal API calls
  static Map<String, String> _getHeaders() {
    if (_restApiKey == null || _appId == null) {
      throw Exception('REST API key or App ID not initialized');
    }
    
    return {
      'Content-Type': 'application/json',
      'accept': 'application/json',
      'Authorization': 'Bearer $_restApiKey',
    };
  }

  // Initialize OneSignal
  static Future<void> initialize({
    required String appId,
    required String restApiKey,
  }) async {
    if (_isInitialized) return;

    try {
      print('Initializing OneSignal with AppId: $appId');
      _appId = appId;
      _restApiKey = restApiKey;
      
      // Enable verbose logging for debugging
      OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
      
      // Initialize OneSignal
      OneSignal.initialize(appId);
      print('OneSignal SDK initialized');
      
      // Enable in-app messaging
      await OneSignal.InAppMessages.paused(false);
      
      // Request notification permission
      print('Requesting notification permission...');
      final permission = await OneSignal.Notifications.requestPermission(true);
      print('Notification permission status: $permission');
      
      if (permission) {
        // Set external user ID for the current user
        final userId = FirebaseAuth.instance.currentUser?.uid;
        if (userId != null) {
          print('Setting external user ID: $userId');
          await OneSignal.login(userId);
        }

        // Set notification handlers
        OneSignal.Notifications.addClickListener(_handleNotificationOpened);
        OneSignal.Notifications.addForegroundWillDisplayListener(_handleNotificationWillDisplay);

        _isInitialized = true;
        print('OneSignal initialized successfully');
      } else {
        print('OneSignal: Notification permission denied');
        _isInitialized = false;
      }
    } catch (e) {
      print('Error initializing OneSignal: $e');
      _isInitialized = false;
      rethrow; // Rethrow to handle in the calling code
    }
  }

  // Update user ID when user signs in/out
  static Future<void> updateUserId(String? userId) async {
    if (!_isInitialized) {
      print('OneSignal not initialized');
      return;
    }

    try {
      if (userId != null) {
        await OneSignal.login(userId);
        print('OneSignal: User logged in with ID: $userId');
      } else {
        await OneSignal.logout();
        print('OneSignal: User logged out');
      }
    } catch (e) {
      print('Error updating OneSignal user ID: $e');
    }
  }

  // Add a tag to the current user
  static Future<void> addTag(String key, String value) async {
    if (!_isInitialized) return;
    try {
      await OneSignal.User.addTagWithKey(key, value);
      print('OneSignal: Added tag $key: $value');
    } catch (e) {
      print('Error adding OneSignal tag: $e');
    }
  }

  // Remove a tag from the current user
  static Future<void> removeTag(String key) async {
    if (!_isInitialized) return;
    try {
      await OneSignal.User.removeTag(key);
      print('OneSignal: Removed tag $key');
    } catch (e) {
      print('Error removing OneSignal tag: $e');
    }
  }

  // Handle when a notification will display in the foreground
  static void _handleNotificationWillDisplay(OSNotificationWillDisplayEvent event) {
    // You can either modify the notification here or prevent it from displaying
    print('OneSignal: Will display notification: ${event.notification.title}');
    event.notification.display(); // Actually display the notification
  }

  // Handle when a notification is opened
  static void _handleNotificationOpened(OSNotificationClickEvent event) {
    print('OneSignal: Notification opened: ${event.notification.title}');
    _storeNotification(
      title: event.notification.title ?? '',
      message: event.notification.body ?? '',
      additionalData: event.notification.additionalData ?? {},
    );
  }

  // Store notification in Firestore for history
  static Future<void> _storeNotification({
    required String title,
    required String message,
    required Map<String, dynamic> additionalData,
  }) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .add({
        'title': title,
        'message': message,
        'additionalData': additionalData,
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
      });
      
      print('OneSignal: Stored notification in Firestore');
    } catch (e) {
      print('Error storing notification: $e');
    }
  }

  // Send a notification to all users
  static Future<bool> sendToAllUsers({
    required String title,
    required String message,
    Map<String, dynamic>? additionalData,
  }) async {
    if (!_isInitialized || _restApiKey == null) return false;

    try {
      final endpoint = _restApiKey!.startsWith('os_v2_') 
        ? 'https://onesignal.com/api/v2/notifications'
        : 'https://onesignal.com/api/v1/notifications';

      final response = await http.post(
        Uri.parse(endpoint),
        headers: _getHeaders(),
        body: jsonEncode({
          'app_id': _appId,
          'included_segments': ['Subscribed Users'],
          'headings': {'en': title},
          'contents': {'en': message},
          if (additionalData != null) 'data': additionalData,
        }),
      );

      if (response.statusCode == 200) {
        print('OneSignal: Sent notification to all users. Response: ${response.body}');
        return true;
      } else {
        print('OneSignal: Failed to send notification. Response: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error sending OneSignal notification: $e');
      return false;
    }
  }

  // Send a notification to specific users
  static Future<bool> sendToUsers({
    required List<String> userIds,
    required String title,
    required String message,
    Map<String, dynamic>? additionalData,
  }) async {
    if (!_isInitialized || _restApiKey == null) return false;

    try {
      final response = await http.post(
        Uri.parse('https://onesignal.com/api/v1/notifications'),
        headers: _getHeaders(),
        body: jsonEncode({
          'app_id': _appId,
          'include_external_user_ids': userIds,
          'headings': {'en': title},
          'contents': {'en': message},
          'data': additionalData,
        }),
      );

      final responseData = jsonDecode(response.body);
      print('OneSignal: Sent notification to specific users. Response: $responseData');
      return response.statusCode == 200;
    } catch (e) {
      print('Error sending notification: $e');
      return false;
    }
  }

  // Test method to verify notification sending
  static Future<bool> sendTestNotification() async {
    if (!_isInitialized) {
      print('OneSignal not initialized');
      return false;
    }

    try {
      final url = Uri.parse('https://api.onesignal.com/api/v1/notifications');
      print('Sending test notification with AppId: $_appId');
      
      final response = await http.post(
        url,
        headers: _getHeaders(),
        body: json.encode({
          'app_id': _appId,
          'included_segments': ['Subscribed Users'],
          'contents': {'en': 'Test notification from app'},
          'headings': {'en': 'Test Title'},
          'data': {'test': 'test_value'}
        }),
      );

      final responseBody = json.decode(response.body);
      if (response.statusCode == 200) {
        print('Test notification sent successfully: $responseBody');
        return true;
      } else {
        print('Failed to send test notification. Status: ${response.statusCode}, Body: $responseBody');
        return false;
      }
    } catch (e) {
      print('Error sending test notification: $e');
      return false;
    }
  }

  // Mark a single notification as read
  static Future<void> markAsRead(String notificationId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});
      
      print('OneSignal: Marked notification as read: $notificationId');
    } catch (e) {
      print('Error marking notification as read: $e');
      rethrow;
    }
  }

  // Mark all notifications as read
  static Future<void> markAllAsRead() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final notificationsRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('notifications');
      
      final batch = FirebaseFirestore.instance.batch();
      
      final notifications = await notificationsRef
          .where('isRead', isEqualTo: false)
          .get();
      
      for (var doc in notifications.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      
      await batch.commit();
      print('OneSignal: Marked all notifications as read');
    } catch (e) {
      print('Error marking all notifications as read: $e');
      rethrow;
    }
  }

  // Delete a notification
  static Future<void> deleteNotification(String notificationId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .doc(notificationId)
          .delete();
      
      print('OneSignal: Deleted notification: $notificationId');
    } catch (e) {
      print('Error deleting notification: $e');
      rethrow;
    }
  }

  // Delete all notifications
  static Future<void> deleteAllNotifications() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final notifications = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .get();
      
      final batch = FirebaseFirestore.instance.batch();
      
      for (var doc in notifications.docs) {
        batch.delete(doc.reference);
      }
      
      await batch.commit();
      print('OneSignal: Deleted all notifications');
    } catch (e) {
      print('Error deleting all notifications: $e');
      rethrow;
    }
  }

  // Get unread notification count
  static Stream<int> getUnreadCount() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Stream.value(0);

    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Validate OneSignal configuration
  static Future<bool> validateConfiguration() async {
    if (!_isInitialized) {
      print('OneSignal not initialized');
      return false;
    }

    try {
      final url = Uri.parse('https://api.onesignal.com/api/v1/apps/$_appId');
      print('Validating OneSignal configuration...');
      
      final response = await http.get(
        url,
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        print('OneSignal configuration is valid');
        print('Response: ${response.body}');
        return true;
      } else {
        print('Failed to validate OneSignal configuration');
        print('Status code: ${response.statusCode}');
        print('Response: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error validating OneSignal configuration: $e');
      return false;
    }
  }
}
