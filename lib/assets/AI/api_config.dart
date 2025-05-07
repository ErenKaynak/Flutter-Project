class APIConfig {
  // Make sure these are valid OpenRouter API keys
  static const String ApiKey = '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';
  static const String openRouterUrl =
      'https://openrouter.ai/api/v1/chat/completions';
  // Verify all keys start with 'sk-or-v1-'
  static const List<String> fallbackResponses = [
    'I apologize, but I\'m currently unavailable. Please try again later.',
    'Our system is experiencing high demand. Please try again in a few minutes.',
    'I\'m unable to process your request right now. Please contact support if this persists.',
  ];
}
