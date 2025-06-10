import 'package:flutter/material.dart';
import 'package:engineering_project/l10n/app_localizations.dart';
import 'package:engineering_project/assets/components/discount_code.dart';
import 'package:engineering_project/assets/components/discount_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:engineering_project/providers/discount_code_provider.dart';

class DiscountPage extends StatefulWidget {
  final Function(DiscountCode?) onDiscountSelected;
  final DiscountCode? currentDiscount;
  final double cartTotal;

  const DiscountPage({
    Key? key,
    required this.onDiscountSelected,
    this.currentDiscount,
    required this.cartTotal,
  }) : super(key: key);

  @override
  State<DiscountPage> createState() => _DiscountPageState();
}

class _DiscountPageState extends State<DiscountPage> {
  final DiscountService _discountService = DiscountService();
  String? _errorMessage;
  bool _isLoadingAvailable = false;
  List<DiscountCode> _availableDiscounts = [];
  List<DiscountCode> _savedDiscounts = [];
  bool _isLoadingSaved = false;

  @override
  void initState() {
    super.initState();
    _loadAvailableDiscounts();
    _loadSavedDiscounts();
  }

  Future<void> _loadAvailableDiscounts() async {
    if (!mounted) return;

    setState(() => _isLoadingAvailable = true);
    try {
      final discounts = await _discountService.getAvailableDiscounts();
      if (!mounted) return;

      setState(() => _availableDiscounts = discounts);
    } on Exception catch (e) {
      if (!mounted) return;
      print('Error loading available discounts: $e');
      setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoadingAvailable = false);
      }
    }
  }

  Future<void> _loadSavedDiscounts() async {
    if (!mounted) return;

    setState(() => _isLoadingSaved = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _savedDiscounts = [];
          _isLoadingSaved = false;
        });
        return;
      }

      // Fetch saved discounts from user's notifications
      final notificationsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .where('type', isEqualTo: 'discount')
          .get();

      final List<DiscountCode> savedDiscounts = [];
      
      for (var doc in notificationsSnapshot.docs) {
        final data = doc.data();
        if (data['discountCode'] != null) {
          final discountData = data['discountCode'] as Map<String, dynamic>;
          savedDiscounts.add(DiscountCode(
            id: doc.id,
            code: discountData['code'] ?? '',
            name: discountData['name'] ?? '',
            description: discountData['description'] ?? '',
            discountPercentage: (discountData['discountPercentage'] ?? 0).toDouble(),
            minOrderAmount: (discountData['minOrderAmount'] ?? 0).toDouble(),
            expiryDate: discountData['expiryDate'] != null 
                ? (discountData['expiryDate'] as Timestamp).toDate()
                : null,
            applicableCategories: discountData['applicableCategories'] != null 
                ? List<String>.from(discountData['applicableCategories']) 
                : null,
            usageLimit: discountData['usageLimit'] ?? 0,
            usageCount: discountData['usageCount'] ?? 0,
            isActive: discountData['isActive'] ?? true,
            perUserLimit: discountData['perUserLimit'] ?? 0,
            isUsed: discountData['isUsed'] ?? false,
            receivedAt: (data['timestamp'] as Timestamp).toDate(),
          ));
        }
      }

      if (!mounted) return;

      setState(() {
        _savedDiscounts = savedDiscounts;
        _isLoadingSaved = false;
      });
    } catch (e) {
      if (!mounted) return;
      print('Error loading saved discounts: $e');
      setState(() {
        _savedDiscounts = [];
        _isLoadingSaved = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.discountAndPromotionCodes,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: isDark 
            ? Colors.red.shade900 
            : Colors.red.shade700,
        iconTheme: const IconThemeData(
          color: Colors.white,
          size: 24,
        ),
        elevation: isDark ? 0 : 2,
      ),
      body: SingleChildScrollView(
        child: Padding(
           padding: const EdgeInsets.all(16.0),
           child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your Saved Discounts',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8.0),
              _buildSavedDiscountsList(context, l10n, theme),
              
              const SizedBox(height: 24.0),

              Text(
                  'Available Discounts',
                   style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              ),
              const SizedBox(height: 8.0),
              _buildAvailableDiscountsList(context, l10n, theme),

              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: Colors.red),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSavedDiscountsList(BuildContext context, AppLocalizations l10n, ThemeData theme) {
     if (_isLoadingSaved) {
       return Center(child: Text('Loading saved discounts...'));
     } else if (_savedDiscounts.isEmpty) {
       return Center(child: Text('No saved discounts yet.'));
     } else {
       return ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: _savedDiscounts.length,
          itemBuilder: (context, index) {
            final discount = _savedDiscounts[index];
            final now = DateTime.now();
            final bool expiredByExpiryDate = discount.expiryDate != null && now.isAfter(discount.expiryDate!);
            final bool expiredBy24HoursAndUnused = !discount.isUsed && now.difference(discount.receivedAt).inHours >= 24;
            final bool isInactive = !discount.isActive || expiredByExpiryDate || (discount.usageLimit > 0 && discount.usageCount >= discount.usageLimit) || expiredBy24HoursAndUnused;

            return Card(
              margin: const EdgeInsets.only(bottom: 8.0),
              elevation: 1.0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
              color: isInactive ? Colors.grey.shade200 : theme.cardColor,
              child: ListTile(
                leading: Icon(Icons.bookmark, color: isInactive ? Colors.grey : theme.colorScheme.secondary),
                title: Text(
                  discount.name.isNotEmpty ? discount.name : discount.code,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    decoration: isInactive ? TextDecoration.lineThrough : null,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isInactive ? (expiredByExpiryDate ? 'Expired' : 'Inactive') : discount.description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontStyle: isInactive ? FontStyle.italic : FontStyle.normal,
                        color: isInactive ? Colors.red : theme.textTheme.bodySmall?.color,
                      )
                    ),
                     if (discount.minOrderAmount > 0)
                       Text(
                        'Min Order: ${l10n.currency(discount.minOrderAmount.toStringAsFixed(2))}',
                         style: TextStyle(
                           fontSize: 12,
                           color: Colors.grey[600],
                         ),
                       ),
                     if (discount.expiryDate != null && !isInactive)
                       Text(
                         'Expires: ${DateFormat('MMM dd, yyyy').format(discount.expiryDate!)}',
                         style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                         ), 
                       ),
                     if (discount.usageLimit > 0 || discount.perUserLimit > 0 && !isInactive)
                       Text(
                        'Uses: ${discount.usageCount}' +
                        (discount.usageLimit > 0 ? '/${discount.usageLimit} total' : '') +
                        (discount.perUserLimit > 0 ? ' (${discount.perUserLimit} per user)' : ''),
                         style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                       ),
                  ],
                ),
                trailing: isInactive ? null : TextButton(
                  onPressed: () {
                     widget.onDiscountSelected(discount);
                     Navigator.pop(context);
                   },
                   child: Text(
                     l10n.apply,
                     style: theme.textTheme.labelLarge?.copyWith(
                       color: theme.colorScheme.primary,
                       fontWeight: FontWeight.bold,
                     ),
                   ),
                ),
              ),
            );
          },
       );
     }
  }

  Widget _buildAvailableDiscountsList(BuildContext context, AppLocalizations l10n, ThemeData theme) {
     if (_isLoadingAvailable) {
       return Center(child: Text(l10n.loading));
     } else if (_availableDiscounts.isEmpty) {
       return Center(child: Text('No available discounts at this time.'));
     } else {
       return ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: _availableDiscounts.length,
          itemBuilder: (context, index) {
            final discount = _availableDiscounts[index];
             final bool isApplicable =
                widget.cartTotal >= discount.minOrderAmount;
            final formattedAmount = l10n.currency(
              discount.minOrderAmount.toStringAsFixed(2),
            );

            return Card(
              margin: const EdgeInsets.only(bottom: 8.0),
              elevation: 1.0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
              color: theme.cardColor,
              child: ListTile(
                leading: const Icon(
                  Icons.star_rounded,
                  color: Colors.amber,
                ),
                title: Text(
                  discount.name,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      discount.description,
                      style: theme.textTheme.bodySmall,
                    ),
                    Text(
                      l10n.minOrderAmount(formattedAmount),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isApplicable
                            ? theme.colorScheme.primary
                            : theme.colorScheme.error,
                         fontWeight: isApplicable ? FontWeight.normal : FontWeight.bold,
                      ), 
                    ),
                  ],
                ),
                trailing: TextButton(
                  onPressed: isApplicable ? () {
                      widget.onDiscountSelected(discount);
                      Navigator.pop(context);
                    } : null,
                  child: Text(
                    l10n.apply,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: isApplicable ? theme.colorScheme.primary : Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            );
          },
       );
     }
  }

  @override
  void dispose() {
    super.dispose();
  }
}