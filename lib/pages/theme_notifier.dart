import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ThemeNotifier extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  bool _isBlackMode = false; // Black Mode flag

  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode {
    if (_themeMode == ThemeMode.system) {
      final window =
          WidgetsBinding.instance.platformDispatcher.platformBrightness;
      return window == Brightness.dark;
    }
    return _themeMode == ThemeMode.dark;
  }

  bool get isBlackMode => _isBlackMode; // Getter for Black Mode

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

  ThemeData get currentTheme {
    if (_isBlackMode) {
      return blackTheme;
    }

    if (isDarkMode) {
      return ThemeData.dark().copyWith(
        colorScheme: const ColorScheme.dark(
          primary: Colors.blueGrey,
          secondary: Colors.red, // Dark modda kırmızı
        ),
        scaffoldBackgroundColor: Colors.grey[850],
      );
    } else {
      return ThemeData.light().copyWith(
        colorScheme: const ColorScheme.light(
          primary: Colors.blue,
          secondary: Colors.red, // Light modda kırmızı
        ),
        scaffoldBackgroundColor: Colors.white,
      );
    }
  }

  // Özel Black Theme
  ThemeData get blackTheme => ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: Colors.black,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.black,
      foregroundColor: Colors.white,
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Colors.white),
      bodyMedium: TextStyle(color: Colors.white70),
    ),
    colorScheme: ColorScheme.dark(
      background: Colors.black,
      primary: Colors.white,
      secondary: Colors.grey[700]!, // Kırmızı yerine gri
    ),
    // Butonlar için
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: Colors.grey[700], // Kırmızı yerine gri
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: Colors.grey[700], // Kırmızı yerine gri
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Colors.grey, // Kırmızı yerine gri
      foregroundColor: Colors.white,
    ),
    // İkonlar için
    iconTheme: IconThemeData(
      color: Colors.grey[700], // Kırmızı yerine gri
    ),
    // Kartlar ve diğer UI elemanları
    cardColor: Colors.grey[900],
    dividerColor: Colors.grey[800],
    // Ekstra tema özellikleri
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.grey[700]!), // Kırmızı yerine gri
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.grey[700]!), // Kırmızı yerine gri
      ),
    ),
  );
}
