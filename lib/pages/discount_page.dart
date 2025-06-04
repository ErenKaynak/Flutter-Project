import 'package:flutter/material.dart';
import 'package:engineering_project/l10n/app_localizations.dart';
import 'package:engineering_project/assets/components/discount_code.dart';
import 'package:engineering_project/assets/components/discount_service.dart';

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
  final TextEditingController _codeController = TextEditingController();
  final DiscountService _discountService = DiscountService();
  String? _errorMessage;
  bool _isLoading = false;
  List<DiscountCode> _availableDiscounts = [];

  @override
  void initState() {
    super.initState();
    _loadDiscounts();
  }

  Future<void> _loadDiscounts() async {
    if (!mounted) return;

    setState(() => _isLoading = true);
    try {
      final discounts = await _discountService.getAvailableDiscounts();
      if (!mounted) return;

      setState(() => _availableDiscounts = discounts);
    } on Exception catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.discountAndPromotionCodes),
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _codeController,
              decoration: InputDecoration(
                labelText: l10n.enterDiscountCode,
                suffixText: l10n.apply,
                suffixStyle: TextStyle(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                errorText: _errorMessage,
              ),
              onSubmitted: (_) => _applyCode(),
            ),
          ),
          Expanded(
            child: _isLoading
                ? Center(child: Text(l10n.loading))
                : _availableDiscounts.isEmpty
                    ? Center(child: Text(l10n.noDiscountsAvailable))
                    : ListView.builder(
                        itemCount: _availableDiscounts.length,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemBuilder: (context, index) {
                          final discount = _availableDiscounts[index];
                          final bool isApplicable =
                              widget.cartTotal >= discount.minOrderAmount;
                          final formattedAmount = l10n.currency(
                            discount.minOrderAmount.toStringAsFixed(2),
                          );

                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                border: Border.all(color: theme.dividerColor),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: ListTile(
                                leading: const Icon(
                                  Icons.star_rounded,
                                  color: Colors.amber,
                                ),
                                title: Text(
                                  discount.name,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      discount.description,
                                      style: theme.textTheme.bodyMedium,
                                    ),
                                    Text(
                                      l10n.minOrderAmount(formattedAmount),
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: isApplicable
                                            ? theme.colorScheme.primary
                                            : theme.colorScheme.error,
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: TextButton(
                                  onPressed: isApplicable
                                      ? () {
                                          widget.onDiscountSelected(discount);
                                          Navigator.pop(context);
                                        }
                                      : null,
                                  child: Text(
                                    l10n.apply,
                                    style: theme.textTheme.labelLarge?.copyWith(
                                      color: theme.colorScheme.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                isThreeLine: true,
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Future<void> _applyCode() async {
    final code = _codeController.text.trim();
    final l10n = AppLocalizations.of(context)!;
    
    if (code.isEmpty) {
      setState(() => _errorMessage = l10n.enterValidDiscountCode);
      return;
    }

    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    try {
      final discount = await _discountService.validateCode(code);
      if (!mounted) return;

      if (discount == null) {
        setState(() => _errorMessage = l10n.invalidDiscountCode);
        return;
      }

      widget.onDiscountSelected(discount);
      Navigator.pop(context);
    } on Exception catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }
}