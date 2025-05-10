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
