import 'package:engineering_project/assets/AI/ngrok_config.dart';

class LocalAIConfig {
  // Default local URL (fallback)
  static const String defaultBaseUrl = 'http://localhost:1234/v1';
  static const String BaseUrl = 'https://paradisepc.loca.lt';
  
  // Get the current base URL (ngrok or local)
  static Future<String> getBaseUrl() async {
    final ngrokUrl = await NgrokConfig.getNgrokUrl();
    return ngrokUrl != null ? '$ngrokUrl/v1' : defaultBaseUrl;
  }

  static const String modelName = 'mistral'; // Your local model name

  // Endpoints
  static const String chatCompletionEndpoint = '/chat/completions';

  // Headers
  static Map<String, String> getHeaders() {
    return {
      'Content-Type': 'application/json',
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