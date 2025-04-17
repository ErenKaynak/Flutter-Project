import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: Colors.red.shade700,
    scaffoldBackgroundColor: Colors.white,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.red.shade50,
      foregroundColor: Colors.white,
    ),
    cardColor: Colors.white,
    colorScheme: ColorScheme.light(
      primary: Colors.red.shade700,
      secondary: Colors.red.shade400,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
      ),
    ),
  );

  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: Colors.red.shade700,
    scaffoldBackgroundColor: Colors.grey.shade900,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.black,
      foregroundColor: Colors.white,
    ),
    cardColor: Colors.grey.shade900,
    colorScheme: ColorScheme.dark(
      primary: Colors.red.shade700,
      secondary: Colors.red.shade400,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
      ),
    ),
  );
}