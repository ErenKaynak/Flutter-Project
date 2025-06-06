import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:engineering_project/models/discount_code.dart';
import 'package:engineering_project/providers/discount_code_provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DiscountCodesScreen extends StatefulWidget {
  const DiscountCodesScreen({Key? key}) : super(key: key);

  @override
  State<DiscountCodesScreen> createState() => _DiscountCodesScreenState();
}

class _DiscountCodesScreenState extends State<DiscountCodesScreen> {
  List<DiscountCode> _savedDiscounts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSavedDiscounts();
  }

  Future<void> _loadSavedDiscounts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('savedDiscounts')
          .get();

      setState(() {
        _savedDiscounts = snapshot.docs.map((doc) {
          final data = doc.data();
          return DiscountCode(
            id: doc.id,
            code: data['code'] as String,
            description: data['description'] as String,
            value: (data['discountPercentage'] as num).toDouble(),
            isPercent: data['isPercent'] as bool,
            isUsed: data['isUsed'] as bool? ?? false,
            expiryDate: (data['expiryDate'] as Timestamp).toDate(),
            receivedAt: (data['receivedAt'] as Timestamp).toDate(),
          );
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading saved discounts: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _copyToClipboard(String code) {
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Discount code copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Widget _buildDiscountCard(BuildContext context, DiscountCode discount) {
    final isExpired = discount.expiryDate != null && 
                     discount.expiryDate!.isBefore(DateTime.now());
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        title: Row(
          children: [
            Text(
              discount.code,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                decoration: isExpired || discount.isUsed ? 
                  TextDecoration.lineThrough : null,
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.copy, size: 20),
              onPressed: () => _copyToClipboard(discount.code),
              tooltip: 'Copy code',
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(discount.description),
            const SizedBox(height: 4),
            Text(
              'Value: ${discount.getFormattedValue()}',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
            if (discount.expiryDate != null)
              Text(
                'Expires: ${DateFormat('MMM dd, yyyy').format(discount.expiryDate!)}',
                style: TextStyle(
                  color: isExpired ? Colors.red : null,
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Discount Codes'),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _savedDiscounts.isEmpty
              ? const Center(
                  child: Text('No discount codes available'),
                )
              : RefreshIndicator(
                  onRefresh: _loadSavedDiscounts,
                  child: ListView.builder(
                    itemCount: _savedDiscounts.length,
                    itemBuilder: (context, index) => 
                      _buildDiscountCard(context, _savedDiscounts[index]),
                  ),
                ),
    );
  }
}
