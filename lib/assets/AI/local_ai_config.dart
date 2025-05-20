import 'package:engineering_project/assets/AI/ngrok_config.dart';

class LocalAIConfig {
  // Default local URL (fallback)
  static const String defaultBaseUrl = 'http://127.0.0.1:1234';
  static const String BaseUrl = 'https://paradisenc.loca.lt';
  
  // Get the current base URL (ngrok or local)
  static Future<String> getBaseUrl() async {
    try {
      final ngrokUrl = await NgrokConfig.getNgrokUrl();
      if (ngrokUrl != null) {
        print('Using ngrok URL: $ngrokUrl');
        return ngrokUrl;
      }
      print('Using default URL: $defaultBaseUrl');
      return defaultBaseUrl;
    } catch (e) {
      print('Error getting base URL: $e');
      return defaultBaseUrl;
    }
  }

  static const String modelName = 'mistral'; // Your local model name

  // Endpoints
  static const String chatCompletionEndpoint = '/v1/chat/completions';
  static const String modelsEndpoint = '/v1/models';

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