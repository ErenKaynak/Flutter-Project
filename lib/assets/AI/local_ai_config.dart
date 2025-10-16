import 'package:engineering_project/assets/AI/ngrok_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalAIConfig {
  // Public URL for your AI server (via ngrok)
  static const String defaultBaseUrl = 'https://set-chigger-apparently.ngrok-free.app';

  static const String _ngrokUrlKey = 'ngrok_url';
  
  // Remote server URL
  static const String _remoteServerUrl = 'https://set-chigger-apparently.ngrok-free.app';

  static Future<String> getBaseUrl() async {
    // Always return the remote server URL since we're using ngrok
    return _remoteServerUrl;
  }

  static Future<void> setNgrokUrl(String url) async {
    if (!isValidNgrokUrl(url)) {
      throw Exception('Invalid ngrok URL format');
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_ngrokUrlKey, url);
  }

  static Future<void> clearNgrokUrl() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_ngrokUrlKey);
  }

  static bool isValidNgrokUrl(String url) {
    // Accept both ngrok.io and ngrok-free.app URLs
    return url.startsWith('https://') && 
           (url.contains('.ngrok.io') || url.contains('.ngrok-free.app'));
  }

  // Make sure this matches a model from your /v1/models endpoint!
  static const String modelName = 'gemma-2-2b-it';

  // Endpoints
  static const String chatCompletionEndpoint = '/v1/chat/completions';
  static const String modelsEndpoint = '/v1/models/';

  // Headers
  static Map<String, String> getHeaders() {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
  }

  // Model parameters
  static const Map<String, dynamic> defaultParameters = {
    'temperature': 0.7,
    'max_tokens': 1000,
    'top_p': 0.95,
    'frequency_penalty': 0,
    'presence_penalty': 0,
  };
} 