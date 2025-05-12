import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {
  static const String LANGUAGE_CODE = 'languageCode';
  
  Locale _currentLocale = const Locale('en');
  
  Locale get currentLocale => _currentLocale;

  LanguageProvider() {
    loadSavedLanguage();
  }

  Future<void> loadSavedLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? languageCode = prefs.getString(LANGUAGE_CODE);
      if (languageCode != null) {
        _currentLocale = Locale(languageCode);
        notifyListeners();
      }
    } catch (e) {
      print('Error loading language: $e');
    }
  }

  Future<void> changeLanguage(String languageCode) async {
    try {
      _currentLocale = Locale(languageCode);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(LANGUAGE_CODE, languageCode);
      notifyListeners();
    } catch (e) {
      print('Error changing language: $e');
      // Revert to previous locale if there's an error
      notifyListeners();
    }
  }

  String getLanguageName(String code) {
    switch (code) {
      case 'en':
        return 'English';
      case 'tr':
        return 'Türkçe';
      case 'ar':
        return 'العربية';
      default:
        return 'English';
    }
  }
} 