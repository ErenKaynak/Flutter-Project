import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:flutter/material.dart';

class NotificationHandler {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  static const String oneSignalAppId = 'bb5b6419-07c9-4b72-9d85-e2c121f05591'; // Replace with your OneSignal App ID

  Future<void> initialize() async {
    try {
      // Enable OneSignal logging for debug
      OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
      
      // Initialize OneSignal
      OneSignal.initialize(oneSignalAppId);
      
      // Request permission for notifications
      await OneSignal.Notifications.requestPermission(true);
      
      // Add notification click listener
      OneSignal.Notifications.addClickListener((OSNotificationClickEvent event) {
        debugPrint("Clicked notification: ${event.notification.title}");
        
        // Handle discount notifications
        if (event.notification.additionalData?['type'] == 'discount') {
          final String? discountId = event.notification.additionalData?['discountId'];
          if (discountId != null) {
            saveDiscountCode(discountId);
          }
        }
      });

      // Keep Firestore listener for backup and history
      _setupFirestoreListener();
    } catch (e) {
      debugPrint('Error initializing notifications: $e');
    }
  }

  void _setupFirestoreListener() {
    _firestore
        .collection('notifications')
        .where('type', isEqualTo: 'discount')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          // We're using OneSignal for notifications now
          // This listener is kept for backup and history tracking
          debugPrint('New discount notification in Firestore: ${change.doc.id}');
        }
      }
    });
  }

  Future<void> saveDiscountCode(String notificationId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final notificationDoc = await _firestore
          .collection('notifications')
          .doc(notificationId)
          .get();
      
      if (!notificationDoc.exists) return;

      final data = notificationDoc.data()!;
      
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('savedDiscounts')
          .doc(data['discountId'] as String)
          .set({
            'savedAt': FieldValue.serverTimestamp(),
            'expiryDate': data['expiryDate'],
            'used': false,
          });
          
      debugPrint('Discount code saved successfully: $notificationId');
    } catch (e) {
      debugPrint('Error saving discount code: $e');
    }
  }
}
