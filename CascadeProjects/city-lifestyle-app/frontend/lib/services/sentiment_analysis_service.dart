import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../utils/http_utils.dart';

class SentimentAnalysisService {
  final String baseUrl = ApiConfig.baseUrl;

  Future<Map<String, dynamic>> getSentimentAnalytics(String timeRange) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/analytics/sentiment?timeRange=$timeRange'),
        headers: HttpUtils.getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load sentiment analytics');
      }
    } catch (e) {
      throw Exception('Error connecting to server: $e');
    }
  }

  Future<Map<String, dynamic>> analyzeSentiment(String text) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/analytics/sentiment/analyze'),
        headers: HttpUtils.getAuthHeaders(),
        body: json.encode({'text': text}),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to analyze sentiment');
      }
    } catch (e) {
      throw Exception('Error connecting to server: $e');
    }
  }

  Future<Map<String, dynamic>> getAspectSentiment(String placeId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/analytics/sentiment/aspects/$placeId'),
        headers: HttpUtils.getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load aspect sentiment');
      }
    } catch (e) {
      throw Exception('Error connecting to server: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getKeyPhrases(String placeId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/analytics/sentiment/keyphrases/$placeId'),
        headers: HttpUtils.getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(json.decode(response.body));
      } else {
        throw Exception('Failed to load key phrases');
      }
    } catch (e) {
      throw Exception('Error connecting to server: $e');
    }
  }

  Future<Map<String, dynamic>> getSentimentTrends({
    required String placeId,
    required String timeRange,
  }) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$baseUrl/api/analytics/sentiment/trends/$placeId?timeRange=$timeRange',
        ),
        headers: HttpUtils.getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load sentiment trends');
      }
    } catch (e) {
      throw Exception('Error connecting to server: $e');
    }
  }
}
