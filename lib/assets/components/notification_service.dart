import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:engineering_project/models/order_models.dart';

class NotificationService {
  static bool _isInitialized = false;
  static bool get isConfigured => _isInitialized;
  static const String _backendUrl = 'https://notification-backend-production-314d.up.railway.app';
  static String? _restApiKey;

  // Helper method for making backend API calls
  static Future<http.Response> _makeBackendRequest(String endpoint, Map<String, dynamic> body) async {
    if (_restApiKey == null) {
      throw Exception('OneSignal REST API key not set. Make sure to call initialize() first.');
    }

    try {
      // Create the Basic auth header by encoding the API key
      final basicAuth = base64.encode(utf8.encode('$_restApiKey:'));
      
      final response = await http.post(
        Uri.parse('$_backendUrl$endpoint'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Basic $basicAuth'
        },
        body: jsonEncode(body),
      );
      return response;
    } catch (e) {
      print('Error calling backend: $e');
      rethrow;
    }
  }

  // Initialize OneSignal
  static Future<void> initialize({
    required String appId,
    required String restApiKey,
  }) async {
    if (_isInitialized) return;

    try {
      print('Initializing OneSignal with AppId: $appId');
      
      _restApiKey = restApiKey;

      // For web platform, OneSignal is initialized in index.html
      if (!kIsWeb) {
        // Set debug logging
        OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
        
        // Initialize OneSignal
        OneSignal.initialize(appId);
        
        // Configure default notification settings
        OneSignal.Notifications.clearAll();
        
        // Enable foreground notifications by requesting permission
        await OneSignal.Notifications.requestPermission(true);
        
        // Enable in-app messaging
        await OneSignal.InAppMessages.paused(false);
        
        // Request notification permission
        print('Requesting notification permission...');
        final permission = await OneSignal.Notifications.requestPermission(true);
        print('Notification permission status: $permission');
        
        if (!permission) {
          print('OneSignal: Notification permission denied');
          _isInitialized = false;
          return;
        }

        // Set handlers for notifications
        OneSignal.Notifications.addClickListener((event) {
          print('Notification clicked: ${event.notification.title}');
          
          // Handle discount code notifications
          final additionalData = event.notification.additionalData;
          if (additionalData != null && additionalData.containsKey('discountCode')) {
            // Assume we have Provider.of<DiscountCodeProvider> available in the UI context
            // The actual handling will be done in the UI when user interacts with notification
            print('Discount code notification received: ${additionalData['discountCode']}');
          }
        });

        OneSignal.Notifications.addForegroundWillDisplayListener((event) {
          print('Received notification: ${event.notification.title}');
          event.notification.display();
        });
      }

      // Set external user ID and subscribe the current user
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        print('Setting external user ID: $userId');
        await OneSignal.login(userId);
        
        // Attempt to subscribe the user
        final subscribed = await subscribeUser();
        if (!subscribed) {
          print('Warning: Failed to subscribe user to notifications');
        }
      }

      _isInitialized = true;
      print('OneSignal initialized successfully');

      // Validate configuration
      final isValid = await validateConfiguration();
      if (!isValid) {
        print('Warning: OneSignal configuration validation failed');
      }
    } catch (e) {
      print('Error initializing OneSignal: $e');
      _isInitialized = false;
      rethrow;
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

  // Validate OneSignal configuration
  static Future<bool> validateConfiguration() async {
    if (!_isInitialized) return false;

    try {
      final pushSubscription = OneSignal.User.pushSubscription;
      final optedIn = pushSubscription.optedIn ?? false;
      final token = pushSubscription.token;
      final userId = OneSignal.User.pushSubscription.id;
      
      print('OneSignal State - Push Token: $token, User ID: $userId, Opted In: $optedIn');
      
      if (token == null || userId == null || !optedIn) {
        print('Warning: Push notification not properly configured. Token: $token, User ID: $userId, Opted In: $optedIn');
        return false;
      }

      // Store the token in Firebase if needed
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(firebaseUser.uid)
            .set({
          'oneSignalUserId': userId,
          'pushToken': token,
          'lastTokenUpdate': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      return true;
    } catch (e) {
      print('Error validating OneSignal configuration: $e');
      return false;
    }
  }

  // Send a notification to all users
  static Future<bool> sendToAllUsers({
    required String title,
    required String message,
    Map<String, dynamic>? additionalData,
  }) async {
    if (!_isInitialized) return false;

    try {
      // First check if there are any subscribed users
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('pushToken', isNull: false)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        print('No subscribed users found');
        throw Exception('No subscribed users found to receive the notification');
      }

      final response = await _makeBackendRequest('/send-notification', {
        'title': title,
        'message': message,
        'additionalData': additionalData,
      });

      // Parse response
      final responseData = jsonDecode(response.body);
      
      if (response.statusCode == 200 && responseData['success'] == true) {
        print('Backend: Sent notification to all users successfully');
        return true;
      } else {
        final errorMessage = responseData['error'] ?? responseData['data']?['errors']?.join(', ') ?? 'Unknown error';
        print('Backend: Failed to send notification. Error: $errorMessage');
        throw Exception('Failed to send notification: $errorMessage');
      }
    } catch (e) {
      print('Error sending notification through backend: $e');
      rethrow;
    }
  }

  // Send a notification to specific users
  static Future<bool> sendToUsers({
    required List<String> userIds,
    required String title,
    required String message,
    Map<String, dynamic>? additionalData,
  }) async {
    if (!_isInitialized) return false;

    try {
      final response = await _makeBackendRequest('/send-notification', {
        'title': title,
        'message': message,
        'userIds': userIds,
        'additionalData': additionalData,
      });

      // Parse response
      final responseData = jsonDecode(response.body);
      
      if (response.statusCode == 200 && responseData['success'] == true) {
        print('Backend: Sent notification to specific users successfully');
        return true;
      } else {
        final errorMessage = responseData['error'] ?? 'Unknown error';
        print('Backend: Failed to send notification. Error: $errorMessage');
        throw Exception('Failed to send notification: $errorMessage');
      }
    } catch (e) {
      print('Error sending notification through backend: $e');
      return false;
    }
  }

  // Test notification sending
  static Future<bool> sendTestNotification() async {
    if (!_isInitialized) {
      print('OneSignal not initialized');
      return false;
    }

    try {
      final response = await _makeBackendRequest('/test-notification', {});

      if (response.statusCode == 200) {
        print('Backend: Test notification sent successfully. Response: ${response.body}');
        return true;
      } else {
        print('Backend: Failed to send test notification. Status: ${response.statusCode}, Body: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error sending test notification through backend: $e');
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
          .update({'read': true});
      
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
          .where('read', isEqualTo: false)
          .get();
      
      for (var doc in notifications.docs) {
        batch.update(doc.reference, {'read': true});
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
        .where('read', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Send a notification
  static Future<void> sendNotification({
    required String title,
    required String message,
    String? imageUrl,
    bool sendToAllUsers = true,
    List<String>? specificUserIds,
  }) async {
    try {
      final body = {
        'title': title,
        'message': message,
        if (imageUrl != null) 'imageUrl': imageUrl,
        'sendToAllUsers': sendToAllUsers,
        if (!sendToAllUsers && specificUserIds != null) 
          'specificUserIds': specificUserIds,
      };

      final response = await _makeBackendRequest('/send-notification', body);
      
      if (response.statusCode != 200) {
        throw Exception('Failed to send notification: ${response.body}');
      }
      
      print('Notification sent successfully');
    } catch (e) {
      print('Error sending notification: $e');
      rethrow;
    }
  }

  // Subscribe the current user to push notifications
  static Future<bool> subscribeUser() async {
    if (!_isInitialized) {
      print('OneSignal not initialized');
      return false;
    }

    try {
      // Request notification permission
      final permission = await OneSignal.Notifications.requestPermission(true);
      if (!permission) {
        print('Notification permission denied');
        return false;
      }

      // Enable push notifications
      await OneSignal.Notifications.clearAll();
      await OneSignal.User.pushSubscription.optIn();
      
      // Validate the subscription
      final pushSubscription = OneSignal.User.pushSubscription;
      final optedIn = pushSubscription.optedIn ?? false;
      final token = pushSubscription.token;
      final userId = OneSignal.User.pushSubscription.id;

      if (!optedIn || token == null || userId == null) {
        print('Failed to subscribe: Token=$token, UserId=$userId, OptedIn=$optedIn');
        return false;
      }

      // Store the token in Firebase
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(firebaseUser.uid)
            .set({
          'oneSignalUserId': userId,
          'pushToken': token,
          'lastTokenUpdate': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      print('User subscribed successfully');
      return true;
    } catch (e) {
      print('Error subscribing user: $e');
      return false;
    }
  }

  // Unsubscribe the current user from push notifications
  static Future<bool> unsubscribeUser() async {
    if (!_isInitialized) {
      print('OneSignal not initialized');
      return false;
    }

    try {
      await OneSignal.User.pushSubscription.optOut();
      
      // Remove the token from Firebase
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(firebaseUser.uid)
            .update({
          'pushToken': FieldValue.delete(),
          'oneSignalUserId': FieldValue.delete(),
          'lastTokenUpdate': FieldValue.serverTimestamp(),
        });
      }

      print('User unsubscribed successfully');
      return true;
    } catch (e) {
      print('Error unsubscribing user: $e');
      return false;
    }
  }

  // Check if the current user is subscribed to push notifications
  static Future<bool> isSubscribed() async {
    if (!_isInitialized) return false;
    
    try {
      final status = await OneSignal.User.pushSubscription.optedIn;
      return status ?? false;
    } catch (e) {
      print('Error checking subscription status: $e');
      return false;
    }
  }

  /// Parses a string into an OrderStatus enum
  static OrderStatus _parseOrderStatus(String statusStr) {
    switch (statusStr.toLowerCase()) {
      case 'pending':
        return OrderStatus.pending;
      case 'preparing':
        return OrderStatus.preparing;
      case 'on delivery':
        return OrderStatus.onDelivery;
      case 'delivered':
        return OrderStatus.delivered;
      case 'refund requested':
        return OrderStatus.refundRequested;
      case 'refund in review':
        return OrderStatus.refundInReview;
      case 'refund approved':
        return OrderStatus.refundApproved;
      case 'refund declined':
        return OrderStatus.refundDeclined;
      case 'refunded':
        return OrderStatus.refunded;
      case 'cancelled':
        return OrderStatus.cancelled;
      default:
        return OrderStatus.pending;
    }
  }
}
