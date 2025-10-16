import 'package:shared_preferences/shared_preferences.dart';

class NgrokConfig {
  static const String _ngrokUrlKey = 'ngrok_url';
  static String? _cachedUrl;

  // Get the stored ngrok URL
  static Future<String?> getNgrokUrl() async {
    if (_cachedUrl != null) return _cachedUrl;
    
    final prefs = await SharedPreferences.getInstance();
    _cachedUrl = prefs.getString(_ngrokUrlKey);
    return _cachedUrl;
  }

  // Set a new ngrok URL
  static Future<void> setNgrokUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_ngrokUrlKey, url);
    _cachedUrl = url;
  }

  // Clear the stored URL
  static Future<void> clearNgrokUrl() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_ngrokUrlKey);
    _cachedUrl = null;
  }

  // Validate ngrok URL format
  static bool isValidNgrokUrl(String url) {
    return url.startsWith('https://') && 
           (url.contains('.ngrok.io') || url.contains('.ngrok-free.app'));
  }
} 