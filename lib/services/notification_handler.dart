import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

class NotificationHandler {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  Future<void> initialize() async {
    // Initialize OneSignal
    OneSignal.Debug.setLogLevel(OSLogLevel.verbose);

    OneSignal.initialize('bb5b6419-07c9-4b72-9d85-e2c121f05591'); // Replace with your OneSignal App ID
    
    // Request permission
    await OneSignal.Notifications.requestPermission(true);

    // Set notification handlers
    OneSignal.Notifications.addClickListener((event) {
      final notification = event.notification;
      final data = notification.additionalData;
      
      if (data?['type'] == 'discount') {
        final discountId = data?['discountId'] as String?;
        if (discountId != null) {
          saveDiscountCode(discountId);
        }
      }
    });

    // Listen for new discount notifications in Firestore for backup
    _firestore
        .collection('notifications')
        .where('type', isEqualTo: 'discount')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen(_handleNewNotification);
  }

  void _handleNewNotification(QuerySnapshot snapshot) {
    for (var change in snapshot.docChanges) {
      if (change.type == DocumentChangeType.added) {
        // Notifications are now handled by OneSignal
        // This is kept for backup and history tracking
      }
    }
  }

  Future<void> saveDiscountCode(String notificationId) async {
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
  }
}