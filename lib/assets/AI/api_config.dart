class APIConfig {
  // Make sure these are valid OpenRouter API keys
  static const String ApiKey =
      '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';
  static const String openRouterUrl =
      'https://openrouter.ai/api/v1/chat/completions';

  static const String imgurClientId ='025f0e0a98cb8a7';
  // Verify all keys start with 'sk-or-v1-'
  static const List<String> fallbackResponses = [
    'I apologize, but I\'m currently unavailable. Please try again later.',
    'Our system is experiencing high demand. Please try again in a few minutes.',
    'I\'m unable to process your request right now. Please contact support if this persists.',
  ];
}
