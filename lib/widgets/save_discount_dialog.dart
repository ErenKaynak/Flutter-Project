import 'package:flutter/material.dart';
import 'package:engineering_project/services/notification_handler.dart';
import 'package:engineering_project/l10n/app_localizations.dart';

class SaveDiscountDialog extends StatelessWidget {
  final String notificationId;
  final String discountCode;
  final double discountPercentage;

  const SaveDiscountDialog({
    super.key,
    required this.notificationId,
    required this.discountCode,
    required this.discountPercentage,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return AlertDialog(
      title: Text(l10n.newDiscount),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(l10n.discountCodeAvailable),
          const SizedBox(height: 8),
          Text(
            '$discountCode - ${discountPercentage}% ${l10n.off}',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        ElevatedButton(
          onPressed: () async {
            await NotificationHandler().saveDiscountCode(notificationId);
            if (context.mounted) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.discountSaved)),
              );
            }
          },
          child: Text(l10n.saveDiscount),
        ),
      ],
    );
  }
}