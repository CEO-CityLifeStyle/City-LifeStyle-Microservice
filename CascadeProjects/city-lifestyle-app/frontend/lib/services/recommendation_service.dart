import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../utils/http_utils.dart';
import '../models/place.dart';

class RecommendationService {
  final String baseUrl = ApiConfig.baseUrl;

  Future<List<Place>> getCollaborativeRecommendations({
    required String userId,
    int limit = 10,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/recommendations/collaborative/$userId?limit=$limit'),
        headers: HttpUtils.getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => Place.fromJson(item)).toList();
      } else {
        throw Exception('Failed to load collaborative recommendations');
      }
    } catch (e) {
      throw Exception('Error connecting to server: $e');
    }
  }

  Future<List<Place>> getContentBasedRecommendations({
    required String userId,
    int limit = 10,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/recommendations/content-based/$userId?limit=$limit'),
        headers: HttpUtils.getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => Place.fromJson(item)).toList();
      } else {
        throw Exception('Failed to load content-based recommendations');
      }
    } catch (e) {
      throw Exception('Error connecting to server: $e');
    }
  }

  Future<List<Place>> getHybridRecommendations({
    required String userId,
    int limit = 10,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/recommendations/hybrid/$userId?limit=$limit'),
        headers: HttpUtils.getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => Place.fromJson(item)).toList();
      } else {
        throw Exception('Failed to load hybrid recommendations');
      }
    } catch (e) {
      throw Exception('Error connecting to server: $e');
    }
  }

  Future<List<Place>> getSimilarPlaces({
    required String placeId,
    int limit = 5,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/recommendations/similar/$placeId?limit=$limit'),
        headers: HttpUtils.getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => Place.fromJson(item)).toList();
      } else {
        throw Exception('Failed to load similar places');
      }
    } catch (e) {
      throw Exception('Error connecting to server: $e');
    }
  }

  Future<List<Place>> getTrendingPlaces({
    String? category,
    int limit = 10,
  }) async {
    try {
      var url = '$baseUrl/api/recommendations/trending?limit=$limit';
      if (category != null) {
        url += '&category=$category';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: HttpUtils.getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => Place.fromJson(item)).toList();
      } else {
        throw Exception('Failed to load trending places');
      }
    } catch (e) {
      throw Exception('Error connecting to server: $e');
    }
  }

  Future<Map<String, List<Place>>> getCategoryRecommendations({
    required String userId,
    int limitPerCategory = 5,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/recommendations/categories/$userId?limit=$limitPerCategory'),
        headers: HttpUtils.getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return data.map((key, value) {
          final List<dynamic> places = value;
          return MapEntry(
            key,
            places.map((item) => Place.fromJson(item)).toList(),
          );
        });
      } else {
        throw Exception('Failed to load category recommendations');
      }
    } catch (e) {
      throw Exception('Error connecting to server: $e');
    }
  }
}
