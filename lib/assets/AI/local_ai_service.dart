import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart' as io;
import 'package:engineering_project/assets/AI/local_ai_config.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class LocalAIService {
  static Future<String> getBaseUrl() async {
    return await LocalAIConfig.getBaseUrl();
  }

  static Map<String, String> _getHeaders() {
    final headers = LocalAIConfig.getHeaders();
    if (kIsWeb) {
      // Add CORS headers for web
      headers.addAll({
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
        'Access-Control-Allow-Headers': 'Content-Type, Authorization',
        'Access-Control-Max-Age': '86400', // 24 hours
      });
    }
    return headers;
  }

  static Future<bool> isAvailable() async {
    try {
      final baseUrl = await getBaseUrl();
      print('Checking AI availability at: $baseUrl/v1/models');
      
      final response = await http.get(
        Uri.parse('$baseUrl/v1/models'),
        headers: _getHeaders(),
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw TimeoutException('Connection timed out. Please check your internet connection and try again.');
        },
      );
      
      if (response.statusCode == 200) {
        print('AI service is available');
        return true;
      } else {
        print('AI service returned status code: ${response.statusCode}');
        print('Response body: ${response.body}');
        return false;
      }
    } on TimeoutException catch (e) {
      print('AI availability check timed out: $e');
      return false;
    } catch (e) {
      print('AI availability check failed: $e');
      return false;
    }
  }

  static Future<String> getChatCompletion(String message, String systemPrompt) async {
    try {
      final baseUrl = await getBaseUrl();
      print('Sending chat request to: $baseUrl/v1/chat/completions');

      final response = await http.post(
        Uri.parse('$baseUrl/v1/chat/completions'),
        headers: _getHeaders(),
        body: jsonEncode({
          'model': LocalAIConfig.modelName,
          'messages': [
            {'role': 'system', 'content': systemPrompt},
            {'role': 'user', 'content': message}
          ],
          ...LocalAIConfig.defaultParameters,
        }),
      ).timeout(
        const Duration(seconds: 45),
        onTimeout: () {
          throw TimeoutException('The AI response is taking too long. Please try again.');
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'];
      } else {
        print('Chat completion failed with status code: ${response.statusCode}');
        print('Response body: ${response.body}');
        throw Exception('Failed to get AI response: ${response.statusCode}');
      }
    } on TimeoutException catch (e) {
      print('Chat completion timed out: $e');
      throw TimeoutException('The AI response is taking too long. Please try again.');
    } catch (e) {
      print('Error in chat completion: $e');
      throw Exception('Failed to get AI response: $e');
    }
  }
} 