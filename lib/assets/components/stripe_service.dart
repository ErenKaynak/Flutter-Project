import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_core/firebase_core.dart';

class StripeService {
  static const String publishableKey = 'pk_test_51R8eshJt242NYJCuRMJ20uAHQ1hlEjDR1ZUv1QE3RL6I2E8lTe8rzmG1pljTGc5kFLLXsWMYQ8WYGiyc4vaKrxux00JcbbTfOK';

  static Future<void> initialize() async {
    await Firebase.initializeApp();
    Stripe.publishableKey = publishableKey;
    await Stripe.instance.applySettings();
    print('Stripe initialized successfully');
  }

  static Future<Map<String, dynamic>> createPaymentIntent(
    String amount,
    String currency,
    String description,
  ) async {
    try {
      final amountInCents = (double.parse(amount) * 100).round();
      print('Sending to createPaymentIntent:');
      print('Amount: $amountInCents (original: $amount)');
      print('Currency: $currency');
      print('Description: $description');

      final functions = FirebaseFunctions.instance;
      final callable = functions.httpsCallable('createPaymentIntent');

      final payload = {
        'data': {
          'amount': amountInCents,
          'currency': currency.toLowerCase(),
          'description': description,
        }
      };
      print('Request payload: $payload'); // Add logging

      final result = await callable.call(payload);

      print('Payment intent response: ${result.data}');
      if (result.data == null || result.data['clientSecret'] == null) {
        throw Exception('Failed to create payment intent: Empty or invalid response');
      }

      return {'clientSecret': result.data['clientSecret']};
    } catch (e) {
      print('Error creating payment intent: $e');
      if (e is FirebaseFunctionsException) {
        print('Firebase Functions error details:');
        print('Code: ${e.code}');
        print('Message: ${e.message}');
        print('Details: ${e.details}');
      }
      rethrow;
    }
  }

  static Future<bool> processPayment(
    BuildContext context,
    String amount,
    String currency,
    String description,
  ) async {
    try {
      final paymentIntentData = await createPaymentIntent(
        amount,
        currency,
        description,
      );

      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: paymentIntentData['clientSecret'],
          merchantDisplayName: 'Your Store Name',
          style: ThemeMode.light,
          billingDetails: const BillingDetails(
            name: 'Test Customer',
            email: 'test@example.com',
          ),
        ),
      );

      await Stripe.instance.presentPaymentSheet();
      return true;
    } catch (e) {
      if (e is StripeException) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment error: ${e.error.localizedMessage}'),
            backgroundColor: Colors.red,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return false;
    }
  }
}