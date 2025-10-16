import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class LanguageProvider extends ChangeNotifier {
  static const String LANGUAGE_CODE = 'languageCode';
  
  Locale _currentLocale = const Locale('en');
  bool _isInitialized = false;
  SharedPreferences? _prefs;
  
  Locale get currentLocale => _currentLocale;
  bool get isInitialized => _isInitialized;

  LanguageProvider() {
    _initializeLanguage();
  }

  Future<void> _initializeLanguage() async {
    if (kIsWeb) {
      _isInitialized = true;
      notifyListeners();
      return;
    }

    try {
      _prefs = await SharedPreferences.getInstance();
      String? languageCode = _prefs?.getString(LANGUAGE_CODE);
      if (languageCode != null) {
        _currentLocale = Locale(languageCode);
      }
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      print('Error loading language: $e');
      _isInitialized = true;
      notifyListeners();
    }
  }

  Future<void> changeLanguage(String languageCode) async {
    if (kIsWeb) {
      _currentLocale = Locale(languageCode);
      notifyListeners();
      return;
    }

    try {
      _currentLocale = Locale(languageCode);
      if (_prefs == null) {
        _prefs = await SharedPreferences.getInstance();
      }
      await _prefs?.setString(LANGUAGE_CODE, languageCode);
      notifyListeners();
    } catch (e) {
      print('Error changing language: $e');
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