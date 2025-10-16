import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:engineering_project/assets/components/discount_code.dart';
import 'package:engineering_project/providers/discount_code_provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';

class DiscountCodesScreen extends StatefulWidget {
  const DiscountCodesScreen({Key? key}) : super(key: key);

  @override
  State<DiscountCodesScreen> createState() => _DiscountCodesScreenState();
}

class _DiscountCodesScreenState extends State<DiscountCodesScreen> {
  List<DiscountCode> _savedDiscounts = [];
  bool _isLoading = true;

  late VoidCallback _discountCodeListener;

  @override
  void initState() {
    super.initState();
    _loadSavedDiscounts();

    final discountProvider = Provider.of<DiscountCodeProvider>(context, listen: false);
    _discountCodeListener = () {
       // Re-fetch if needed, or rely on the provider's state if it were managing the list
       // For now, we just load once in initState, as the list is fetched when the screen opens.
    };
    // discountProvider.addListener(_discountCodeListener); // No need to listen if we refetch
  }
  
  @override
  void dispose() {
    // final discountProvider = Provider.of<DiscountCodeProvider>(context, listen: false);
    // discountProvider.removeListener(_discountCodeListener); // Remove listener if added
    super.dispose();
  }

  Future<void> _loadSavedDiscounts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final discountProvider = Provider.of<DiscountCodeProvider>(context, listen: false);
      final discounts = await discountProvider.getSavedDiscounts();

      setState(() {
        _savedDiscounts = discounts;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading saved discounts in DiscountCodesScreen: $e');
      setState(() {
        _isLoading = false;
        _savedDiscounts = []; // Clear list on error
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
     final isUsed = discount.usageCount > 0;
     final bool isInactive = !discount.isActive || isExpired || (discount.usageLimit > 0 && discount.usageCount >= discount.usageLimit);
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: isInactive ? Colors.grey.shade200 : null,
      child: ListTile(
        title: Row(
          children: [
            Text(
              discount.code,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                decoration: isInactive ? 
                  TextDecoration.lineThrough : null,
              ),
            ),
            const SizedBox(width: 8),
            if (!isInactive)
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
              'Discount: ${discount.discountPercentage.toStringAsFixed(0)}%',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
             if (discount.minOrderAmount > 0)
               Text(
                'Min Order: ₺${discount.minOrderAmount.toStringAsFixed(2)}',
                 style: TextStyle(
                   fontSize: 12,
                   color: Colors.grey[600],
                 ),
               ),
            if (discount.expiryDate != null)
              Text(
                'Expires: ${DateFormat('MMM dd, yyyy').format(discount.expiryDate!)}',
                style: TextStyle(
                  color: isExpired ? Colors.red : null,
                   fontSize: 12,
                ), 
              ),
             if (discount.usageLimit > 0 || discount.perUserLimit > 0)
               Text(
                'Uses: ${discount.usageCount}' +
                (discount.usageLimit > 0 ? '/${discount.usageLimit} total' : '') +
                (discount.perUserLimit > 0 ? ' (${discount.perUserLimit} per user)' : ''),
                 style: TextStyle(fontSize: 12, color: Colors.grey[600]),
               ),
             if (isInactive)
               Text(
                isExpired ? 'Status: Expired' : (discount.usageLimit > 0 && discount.usageCount >= discount.usageLimit) ? 'Status: Limit Reached' : 'Status: Inactive',
                 style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12),
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
