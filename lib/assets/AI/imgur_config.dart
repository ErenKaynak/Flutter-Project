class ImgurConfig {
  static const String clientId = '025f0e0a98cb8a7';
  static const String uploadEndpoint = 'https://api.imgur.com/3/image';

  static Map<String, String> getHeaders() {
    return {
      'Authorization': 'Client-ID $clientId',
      'Content-Type': 'application/json',
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'POST',
      'Access-Control-Allow-Headers': 'Authorization, Content-Type',
    };
  }
} 