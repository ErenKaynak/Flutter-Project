import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationService {
  static const String _baseUrl = 'https://notification-backend-production-314d.up.railway.app'; // Update with your actual backend URL
  
  /// Sends a discount notification to all users
  Future<bool> sendDiscountNotification({
    required String title,
    required String message,
    required String discountCode,
    required double discountPercentage,
    DateTime? expiryDate,
    required String discountId,
  }) async {
    try {
      final requestBody = {
        'title': title,
        'message': message,
        'discountCode': discountCode,
        'discountPercentage': discountPercentage,
        'expiryDate': expiryDate?.toIso8601String(),
        'discountId': discountId,
      };
      print('Sending notification request to: ${Uri.parse('$_baseUrl/notify/discount')}');
      print('Request body: $requestBody');
      
      final response = await http.post(
        Uri.parse('$_baseUrl/api/notify/discount'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['success'] == true) {
          // Also save notification to Firestore for history
          await FirebaseFirestore.instance.collection('notifications').add({
            'type': 'discount',
            'title': title,
            'body': message,
            'discountId': discountId,
            'timestamp': FieldValue.serverTimestamp(),
            'expiryDate': expiryDate,
          });
          
          return true;
        }
      }
      return false;
    } catch (e) {
      print('Error sending notification: $e');
      return false;
    }
  }
}
