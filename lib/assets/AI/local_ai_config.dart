import 'package:engineering_project/assets/AI/ngrok_config.dart';

class LocalAIConfig {
  // Public URL for your AI server (via loca.lt)
  static const String defaultBaseUrl = 'https://paradisenc.loca.lt';

  // Always use loca.lt for now
  static Future<String> getBaseUrl() async {
    return defaultBaseUrl;
  }

  // Make sure this matches a model from your /v1/models endpoint!
  static const String modelName = 'mistral-7b-instruct-v0.1';

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