class APIConfig {
  // OpenRouter API configuration
  static const String ApiKey =
      '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';
  static const String openRouterUrl =
      'https://openrouter.ai/api/v1/chat/completions';

  // Required headers for OpenRouter API
  static Map<String, String> getOpenRouterHeaders() {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $ApiKey',
      'HTTP-Referer': 'https://github.com/OpenRouterTeam/openrouter-examples',
      'X-Title': 'Flutter E-commerce App',
      'OpenRouter-Bypass-Cache': 'true',
    };
  }

  // Default model to use
  static const String defaultModel = 'openai/gpt-3.5-turbo';

  // Imgur configuration for image uploads
  static const String imgurClientId = '025f0e0a98cb8a7';

  // Fallback responses for API failures
  static const List<String> fallbackResponses = [
    'I apologize, but I\'m currently unavailable. Please try again later.',
    'Our system is experiencing high demand. Please try again in a few minutes.',
    'I\'m unable to process your request right now. Please contact support if this persists.',
  ];
}
