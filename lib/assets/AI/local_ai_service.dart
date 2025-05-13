import 'dart:convert';
import 'package:http/http.dart' as http;
import 'local_ai_config.dart';

class LocalAIService {
  static Future<String> getChatCompletion(String message, String systemPrompt) async {
    try {
      final baseUrl = await LocalAIConfig.getBaseUrl();
      final response = await http.post(
        Uri.parse(baseUrl + LocalAIConfig.chatCompletionEndpoint),
        headers: LocalAIConfig.getHeaders(),
        body: jsonEncode({
          'model': LocalAIConfig.modelName,
          'messages': [
            {
              'role': 'system',
              'content': systemPrompt,
            },
            {
              'role': 'user',
              'content': message,
            },
          ],
          ...LocalAIConfig.defaultParameters,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'].toString();
      } else {
        throw Exception('Failed to get AI response: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error in AI service: $e');
    }
  }

  static Future<bool> isAvailable() async {
    try {
      final response = await http.get(
        Uri.parse(LocalAIConfig.BaseUrl + '/v1/models'),
        headers: LocalAIConfig.getHeaders(),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
} 