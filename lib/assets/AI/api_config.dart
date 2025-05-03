class APIConfig {
  // Replace with your actual API key
  static const String openAIApiKey = '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';

  // Add fallback responses for when API is unavailable
  static const List<String> fallbackResponses = [
    'I apologize, but I\'m currently unavailable. Please try again later.',
    'Our system is experiencing high demand. Please try again in a few minutes.',
    'I\'m unable to process your request right now. Please contact support if this persists.',
  ];
}
