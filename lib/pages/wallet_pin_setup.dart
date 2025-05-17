import 'package:engineering_project/pages/theme_notifier.dart';
import 'package:flutter/material.dart';
import 'package:engineering_project/assets/components/wallet_auth_service.dart';
import 'package:engineering_project/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:engineering_project/pages/pin_entry_screen.dart';

class WalletPinSetup extends StatelessWidget {
  const WalletPinSetup({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PinEntryScreen(
      pinLength: 4,
      title: 'Set up PIN',
      subtitle: 'Enter PIN',
      showBiometrics: true,
      confirmMode: true,
      onPinEntered: (pin) async {
        // Save PIN using WalletAuthService
        final walletAuthService = WalletAuthService();
        await walletAuthService.setPin(pin);
        // Optionally enable biometrics if user used it
        return true;
      },
    );
  }
} 