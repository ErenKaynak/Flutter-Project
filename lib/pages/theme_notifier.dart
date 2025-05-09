import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Special mode renk seçenekleri
enum SpecialTheme { none, yellow, orange, blue, green, purple }

class ThemeNotifier extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  bool _isBlackMode = false;
  SpecialTheme _specialTheme = SpecialTheme.none;

  // Getter'lar
  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode {
    if (_themeMode == ThemeMode.system) {
      final window = WidgetsBinding.instance.window;
      return window.platformBrightness == Brightness.dark;
    }
    return _themeMode == ThemeMode.dark;
  }

  bool get isBlackMode => _isBlackMode;

  SpecialTheme get specialTheme => _specialTheme;

  bool get isSpecialModeActive => _specialTheme != SpecialTheme.none;

  // Setter'lar
  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }

  void toggleTheme() {
    _themeMode = isDarkMode ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
  }

  void toggleBlackMode(bool value) {
    _isBlackMode = value;
    notifyListeners();
  }

  void setSpecialTheme(SpecialTheme theme) {
    _specialTheme = theme;
    notifyListeners();
  }

  // SpecialTheme'i MaterialColor'a dönüştüren yardımcı metod
  MaterialColor getThemeColor(SpecialTheme theme) {
    switch (theme) {
      case SpecialTheme.yellow:
        return Colors.yellow;
      case SpecialTheme.orange:
        return Colors.orange;
      case SpecialTheme.blue:
        return Colors.blue;
      case SpecialTheme.green:
        return Colors.green;
      case SpecialTheme.purple:
        return Colors.purple;
      case SpecialTheme.none:
      default:
        return Colors.red; // Varsayılan renk (special mode kapalıyken)
    }
  }
}
