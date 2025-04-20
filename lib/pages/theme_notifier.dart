import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ThemeNotifier extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  bool _isBlackMode = false; // 🆕 Black Mode flag

  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode {
    if (_themeMode == ThemeMode.system) {
      final window = WidgetsBinding.instance.window;
      return window.platformBrightness == Brightness.dark;
    }
    return _themeMode == ThemeMode.dark;
  }

  bool get isBlackMode => _isBlackMode; // 🆕 Getter for Black Mode

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }

  void toggleTheme() {
    _themeMode = isDarkMode ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
  }

  void toggleBlackMode(bool value) {
    // 🆕 Black Mode setter
    _isBlackMode = value;
    notifyListeners();
  }
}
