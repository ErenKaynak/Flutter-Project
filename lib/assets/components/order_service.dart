import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:engineering_project/assets/components/email_service.dart';
import 'package:flutter/material.dart';

class OrderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> placeOrder({
    required List<Map<String, dynamic>> items,
    required double totalAmount,
    required String shippingAddress,
    required BuildContext context,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Get user details
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userData = userDoc.data() ?? {};
      
      // Generate order number
      final orderNumber = 'ORD-${DateTime.now().millisecondsSinceEpoch}';
      
      // Create order document
      final orderData = {
        'userId': user.uid,
        'orderNumber': orderNumber,
        'items': items,
        'totalAmount': totalAmount,
        'shippingAddress': shippingAddress,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('orders').doc(orderNumber).set(orderData);

      // Send receipt email
      await EmailService.sendReceipt(
        context: context,
        customerEmail: user.email ?? '',
        customerName: '${userData['name']} ${userData['surname']}',
        orderNumber: orderNumber,
        items: items,
        totalAmount: totalAmount,
        orderDate: DateTime.now(),
        shippingAddress: shippingAddress,
      );

      // Clear user's cart after successful order
      await _firestore.collection('cart').doc(user.uid).delete();

    } catch (e) {
      print('Error placing order: $e');
      throw Exception('Failed to place order: $e');
    }
  }

  // Get user's orders
  Future<List<Map<String, dynamic>>> getUserOrders() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final ordersSnapshot = await _firestore
          .collection('orders')
          .where('userId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .get();

      return ordersSnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'orderNumber': data['orderNumber'],
          'items': data['items'],
          'totalAmount': data['totalAmount'],
          'status': data['status'],
          'createdAt': (data['createdAt'] as Timestamp).toDate(),
          'shippingAddress': data['shippingAddress'],
        };
      }).toList();
    } catch (e) {
      print('Error getting user orders: $e');
      throw Exception('Failed to get user orders: $e');
    }
  }
} 