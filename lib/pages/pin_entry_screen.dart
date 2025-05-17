import 'package:flutter/material.dart';
import 'package:engineering_project/assets/components/wallet_auth_service.dart';
import 'package:provider/provider.dart';
import 'theme_notifier.dart';

class PinEntryScreen extends StatefulWidget {
  final int pinLength;
  final String title;
  final String subtitle;
  final bool showBiometrics;
  final Future<bool> Function(String pin)? onPinEntered;
  final VoidCallback? onBiometricsSuccess;
  final bool confirmMode;

  const PinEntryScreen({
    Key? key,
    this.pinLength = 4,
    required this.title,
    required this.subtitle,
    this.showBiometrics = false,
    this.onPinEntered,
    this.onBiometricsSuccess,
    this.confirmMode = false,
  }) : super(key: key);

  @override
  State<PinEntryScreen> createState() => _PinEntryScreenState();
}

class _PinEntryScreenState extends State<PinEntryScreen> {
  List<String> _pin = [];
  List<String> _confirmPin = [];
  bool _isConfirming = false;
  String? _error;
  bool _biometricsAvailable = false;
  final WalletAuthService _walletAuthService = WalletAuthService();

  @override
  void initState() {
    super.initState();
    _checkBiometrics();
    if (widget.confirmMode) {
      _isConfirming = false;
    }
  }

  Future<void> _checkBiometrics() async {
    if (widget.showBiometrics) {
      final isAvailable = await _walletAuthService.isBiometricsAvailable();
      final availableBiometrics = await _walletAuthService.getAvailableBiometrics();
      setState(() {
        _biometricsAvailable = isAvailable && availableBiometrics.isNotEmpty;
      });
    }
  }

  void _onKeyPressed(String value) {
    setState(() {
      if (widget.confirmMode && _isConfirming) {
        if (value == 'back') {
          if (_confirmPin.isNotEmpty) _confirmPin.removeLast();
        } else if (_confirmPin.length < widget.pinLength) {
          _confirmPin.add(value);
          if (_confirmPin.length == widget.pinLength) {
            _onPinComplete();
          }
        }
      } else {
        if (value == 'back') {
          if (_pin.isNotEmpty) _pin.removeLast();
        } else if (_pin.length < widget.pinLength) {
          _pin.add(value);
          if (_pin.length == widget.pinLength) {
            if (widget.confirmMode) {
              _isConfirming = true;
            } else {
              _onPinComplete();
            }
          }
        }
      }
      _error = null;
    });
  }

  Future<void> _onPinComplete() async {
    if (widget.confirmMode && _isConfirming) {
      if (_pin.join() != _confirmPin.join()) {
        setState(() {
          _error = 'PINs do not match';
          _pin.clear();
          _confirmPin.clear();
          _isConfirming = false;
        });
        return;
      }
      if (widget.onPinEntered != null) {
        final result = await widget.onPinEntered!(_pin.join());
        if (result) Navigator.pop(context, true);
      } else {
        Navigator.pop(context, _pin.join());
      }
    } else {
      if (widget.onPinEntered != null) {
        final result = await widget.onPinEntered!(_pin.join());
        if (result) Navigator.pop(context, true);
        else setState(() { _error = 'Invalid PIN'; _pin.clear(); });
      } else {
        Navigator.pop(context, _pin.join());
      }
    }
  }

  Widget _buildPinBoxes(List<String> pin, {bool isError = false}) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final specialColor = themeNotifier.isSpecialModeActive
        ? themeNotifier.getThemeColor(themeNotifier.specialTheme)
        : null;
    final borderColor = isError
        ? Colors.red
        : (themeNotifier.isSpecialModeActive
            ? specialColor?.shade400 ?? Colors.red.shade400
            : Colors.red.shade400);
    final fillColor = isDark
        ? (themeNotifier.isSpecialModeActive
            ? specialColor?.shade900.withOpacity(0.2) ?? Colors.red.shade900.withOpacity(0.2)
            : Colors.red.shade900.withOpacity(0.2))
        : (themeNotifier.isSpecialModeActive
            ? specialColor?.shade50.withOpacity(0.2) ?? Colors.red.shade50.withOpacity(0.2)
            : Colors.red.shade50.withOpacity(0.2));
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(widget.pinLength, (index) {
        bool isFilled = index < pin.length;
        return AnimatedContainer(
          duration: Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 8),
          width: 48,
          height: 60,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: borderColor,
              width: 2,
            ),
            color: isFilled ? fillColor : Colors.transparent,
            boxShadow: [
              if (isFilled)
                BoxShadow(
                  color: borderColor.withOpacity(0.2),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
            ],
          ),
          child: Center(
            child: isFilled
                ? Icon(Icons.circle, size: 16, color: borderColor)
                : SizedBox.shrink(),
          ),
        );
      }),
    );
  }

  Widget _buildKeypad() {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final specialColor = themeNotifier.isSpecialModeActive
        ? themeNotifier.getThemeColor(themeNotifier.specialTheme)
        : null;
    final mainColor = themeNotifier.isSpecialModeActive
        ? specialColor?.shade400 ?? Colors.red.shade400
        : Colors.red.shade400;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark
        ? (themeNotifier.isSpecialModeActive
            ? specialColor?.shade900 ?? Colors.red.shade900
            : Colors.red.shade900)
        : (themeNotifier.isSpecialModeActive
            ? specialColor?.shade50 ?? Colors.red.shade50
            : Colors.red.shade50);
    final keys = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['back', '0', 'bio'],
    ];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: keys.map((row) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: row.map((key) {
              if (key == '') return SizedBox(width: 64);
              if (key == 'bio') {
                if (!_biometricsAvailable || !widget.showBiometrics) return SizedBox(width: 64);
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: GestureDetector(
                    onTap: () async {
                      final authenticated = await _walletAuthService.authenticateWithBiometrics();
                      if (authenticated) {
                        if (widget.onBiometricsSuccess != null) widget.onBiometricsSuccess!();
                        Navigator.pop(context, true);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Biometric authentication failed.')),
                        );
                      }
                    },
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: [
                          BoxShadow(
                            color: mainColor.withOpacity(0.08),
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Icon(Icons.fingerprint, color: mainColor, size: 28),
                      ),
                    ),
                  ),
                );
              }
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: GestureDetector(
                  onTap: () => _onKeyPressed(key),
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(
                          color: mainColor.withOpacity(0.08),
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: key == 'back'
                          ? Icon(Icons.backspace, color: mainColor, size: 28)
                          : Text(
                              key,
                              style: TextStyle(
                                color: mainColor,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ),
              );
            }).toList(),
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final specialColor = themeNotifier.isSpecialModeActive
        ? themeNotifier.getThemeColor(themeNotifier.specialTheme)
        : null;
    final mainColor = themeNotifier.isSpecialModeActive
        ? specialColor?.shade400 ?? Colors.red.shade400
        : Colors.red.shade400;
    return Scaffold(
      backgroundColor: isDark
          ? (themeNotifier.isSpecialModeActive
              ? specialColor?.shade900 ?? Colors.red.shade900
              : Colors.red.shade900)
          : (themeNotifier.isSpecialModeActive
              ? specialColor?.shade50 ?? Colors.red.shade50
              : Colors.red.shade50),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: mainColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.confirmMode
              ? (_isConfirming ? 'Confirm PIN' : widget.title)
              : widget.title,
          style: TextStyle(color: mainColor, fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 16),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.top -
                  kToolbarHeight,
            ),
            child: IntrinsicHeight(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  SizedBox(height: 32),
                  Container(
                    decoration: BoxDecoration(
                      color: mainColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: mainColor.withOpacity(0.15),
                          blurRadius: 16,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                    padding: EdgeInsets.all(32),
                    child: Icon(Icons.lock_outline, color: Colors.white, size: 64),
                  ),
                  SizedBox(height: 32),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    decoration: BoxDecoration(
                      border: Border.all(color: mainColor, width: 4),
                      borderRadius: BorderRadius.circular(16),
                      color: isDark
                          ? Colors.white.withOpacity(0.02)
                          : Colors.white.withOpacity(0.08),
                    ),
                    child: Column(
                      children: [
                        _buildPinBoxes(_isConfirming ? _confirmPin : _pin, isError: _error != null),
                        SizedBox(height: 12),
                        Text(
                          widget.confirmMode
                              ? (_isConfirming ? 'Confirm PIN' : widget.subtitle)
                              : widget.subtitle,
                          style: TextStyle(color: mainColor, fontSize: 18),
                        ),
                        if (_error != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              _error!,
                              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                            ),
                          ),
                      ],
                    ),
                  ),
                  SizedBox(height: 24),
                  Spacer(),
                  _buildKeypad(),
                  SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
} 