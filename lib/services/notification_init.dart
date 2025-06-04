import 'package:flutter/foundation.dart';
import '../assets/components/notification_service.dart';
import 'notification_handler_new.dart';

class NotificationInitializer {
  static const String _oneSignalAppId = 'bb5b6419-07c9-4b72-9d85-e2c121f05591';
  static const String _oneSignalRestApiKey = 'os_v2_app_xnnwigihzffxfhmf4lasd4cvshp4lnkq7zsuoomolom6c6an5hh342rf54jd4eca3zykr2a6qbqo3cyls36fx27rzz3zh4rphqaaqty'; // Replace with your actual REST API key
  
  static bool _isInitialized = false;
  static NotificationHandler? _handler;

  /// Initialize the complete notification system
  static Future<bool> initialize() async {
    if (_isInitialized) {
      debugPrint('Notifications already initialized');
      return true;
    }

    try {
      debugPrint('Initializing notification system...');

      // Initialize the main notification service
      await NotificationService.initialize(
        appId: _oneSignalAppId,
        restApiKey: _oneSignalRestApiKey,
      );

      // Initialize the notification handler
      _handler = NotificationHandler();
      await _handler!.initialize();

      // Validate the setup
      final isConfigured = NotificationService.isConfigured;
      if (!isConfigured) {
        debugPrint('Warning: NotificationService configuration failed');
        return false;
      }

      _isInitialized = true;
      debugPrint('Notification system initialized successfully');
      return true;

    } catch (e) {
      debugPrint('Error initializing notification system: $e');
      _isInitialized = false;
      return false;
    }
  }

  /// Update user ID when authentication state changes
  static Future<void> updateUserId(String? userId) async {
    if (!_isInitialized) {
      debugPrint('Notifications not initialized, cannot update user ID');
      return;
    }

    try {
      await NotificationService.updateUserId(userId);
      debugPrint('User ID updated: ${userId ?? 'logged out'}');
    } catch (e) {
      debugPrint('Error updating user ID: $e');
    }
  }

  /// Subscribe user to notifications
  static Future<bool> subscribeUser() async {
    if (!_isInitialized) {
      debugPrint('Notifications not initialized, cannot subscribe user');
      return false;
    }

    try {
      final success = await NotificationService.subscribeUser();
      debugPrint('User subscription ${success ? 'successful' : 'failed'}');
      return success;
    } catch (e) {
      debugPrint('Error subscribing user: $e');
      return false;
    }
  }

  /// Unsubscribe user from notifications
  static Future<bool> unsubscribeUser() async {
    if (!_isInitialized) {
      debugPrint('Notifications not initialized, cannot unsubscribe user');
      return false;
    }

    try {
      final success = await NotificationService.unsubscribeUser();
      debugPrint('User unsubscription ${success ? 'successful' : 'failed'}');
      return success;
    } catch (e) {
      debugPrint('Error unsubscribing user: $e');
      return false;
    }
  }

  /// Check if user is subscribed to notifications
  static Future<bool> isUserSubscribed() async {
    if (!_isInitialized) {
      return false;
    }

    try {
      return await NotificationService.isSubscribed();
    } catch (e) {
      debugPrint('Error checking subscription status: $e');
      return false;
    }
  }

  /// Send test notification (admin function)
  static Future<bool> sendTestNotification() async {
    if (!_isInitialized) {
      debugPrint('Notifications not initialized, cannot send test notification');
      return false;
    }

    try {
      return await NotificationService.sendTestNotification();
    } catch (e) {
      debugPrint('Error sending test notification: $e');
      return false;
    }
  }

  /// Check if notification system is properly initialized
  static bool get isInitialized => _isInitialized;

  /// Get configuration status
  static bool get isConfigured => _isInitialized && NotificationService.isConfigured;

  /// Add user tag for targeting
  static Future<void> addUserTag(String key, String value) async {
    if (!_isInitialized) return;
    
    try {
      await NotificationService.addTag(key, value);
      debugPrint('Added user tag: $key = $value');
    } catch (e) {
      debugPrint('Error adding user tag: $e');
    }
  }

  /// Remove user tag
  static Future<void> removeUserTag(String key) async {
    if (!_isInitialized) return;
    
    try {
      await NotificationService.removeTag(key);
      debugPrint('Removed user tag: $key');
    } catch (e) {
      debugPrint('Error removing user tag: $e');
    }
  }
}