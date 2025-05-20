import 'dart:convert';
import 'package:http/http.dart' as http;
import 'local_ai_config.dart';

class LocalAIService {
  static Future<String> getChatCompletion(String message, String systemPrompt) async {
    try {
      final baseUrl = await LocalAIConfig.getBaseUrl();
      final endpoint = baseUrl + LocalAIConfig.chatCompletionEndpoint;
      print('Sending request to: $endpoint');
      
      final response = await http.post(
        Uri.parse(endpoint),
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
        print('Error response: ${response.body}');
        throw Exception('Failed to get AI response: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in AI service: $e');
      throw Exception('Error in AI service: $e');
    }
  }

  static Future<bool> isAvailable() async {
    try {
      final baseUrl = await LocalAIConfig.getBaseUrl();
      
      // First try the models endpoint
      final modelsEndpoint = baseUrl + LocalAIConfig.modelsEndpoint;
      print('Checking models endpoint: $modelsEndpoint');
      
      final response = await http.get(
        Uri.parse(modelsEndpoint),
        headers: LocalAIConfig.getHeaders(),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        print('Models endpoint available');
        return true;
      }

      // If models endpoint fails, try the chat completion endpoint
      final chatEndpoint = baseUrl + LocalAIConfig.chatCompletionEndpoint;
      print('Checking chat endpoint: $chatEndpoint');
      
      final chatResponse = await http.post(
        Uri.parse(chatEndpoint),
        headers: LocalAIConfig.getHeaders(),
        body: jsonEncode({
          'model': LocalAIConfig.modelName,
          'messages': [
            {
              'role': 'system',
              'content': 'Test connection',
            },
            {
              'role': 'user',
              'content': 'Test',
            },
          ],
          'max_tokens': 1,
        }),
      ).timeout(const Duration(seconds: 5));

      if (chatResponse.statusCode == 200) {
        print('Chat endpoint available');
        return true;
      }

      print('Both endpoints failed');
      return false;
    } catch (e) {
      print('Local AI availability check failed: $e');
      return false;
    }
  }
} 