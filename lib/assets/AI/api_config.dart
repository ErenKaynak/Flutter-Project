class APIConfig {
  // Replace with your actual API key
  static const String openAIApiKey = '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';
  static const String openAIApiKey2 = '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';
  static const String openAIApiKey3 = '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';
  // Add fallback responses for when API is unavailable
  static const List<String> fallbackResponses = [
    'I apologize, but I\'m currently unavailable. Please try again later.',
    'Our system is experiencing high demand. Please try again in a few minutes.',
    'I\'m unable to process your request right now. Please contact support if this persists.',
  ];
}
