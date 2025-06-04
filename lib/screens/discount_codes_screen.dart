import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:engineering_project/models/discount_code.dart';
import 'package:engineering_project/providers/discount_code_provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';

class DiscountCodesScreen extends StatefulWidget {
  const DiscountCodesScreen({Key? key}) : super(key: key);

  @override
  State<DiscountCodesScreen> createState() => _DiscountCodesScreenState();
}

class _DiscountCodesScreenState extends State<DiscountCodesScreen> {
  @override
  void initState() {
    super.initState();
    // Load discount codes when screen opens
    Future.microtask(() =>
      context.read<DiscountCodeProvider>().loadDiscountCodes()
    );
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
        trailing: PopupMenuButton<String>(
          onSelected: (value) async {
            if (value == 'delete') {
              await context.read<DiscountCodeProvider>()
                .deleteDiscountCode(discount.id);
            } else if (value == 'markUsed') {
              await context.read<DiscountCodeProvider>()
                .markAsUsed(discount.id);
            }
          },
          itemBuilder: (context) => [
            if (!discount.isUsed)
              const PopupMenuItem(
                value: 'markUsed',
                child: Text('Mark as used'),
              ),
            const PopupMenuItem(
              value: 'delete',
              child: Text('Delete'),
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
      body: Consumer<DiscountCodeProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (provider.discountCodes.isEmpty) {
            return const Center(
              child: Text('No discount codes available'),
            );
          }

          return ListView.builder(
            itemCount: provider.discountCodes.length,
            itemBuilder: (context, index) => 
              _buildDiscountCard(context, provider.discountCodes[index]),
          );
        },
      ),
    );
  }
}
