class APIConfig {
  // Replace with your actual API key
  static const String ApiKey =
      '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';
  static const String ApiKey2 =
      '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';
  static const String ApiKey3 =
      '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';
  static const String ApiKey4 =
      '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';
  // Add fallback responses for when API is unavailable
  static const String ApiKey5 =
      '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';
  static const List<String> fallbackResponses = [
    'I apologize, but I\'m currently unavailable. Please try again later.',
    'Our system is experiencing high demand. Please try again in a few minutes.',
    'I\'m unable to process your request right now. Please contact support if this persists.',
  ];
}
