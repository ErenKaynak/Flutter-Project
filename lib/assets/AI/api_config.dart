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
      'OpenRouter-Bypass-Cache': 'true'
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
