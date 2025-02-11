import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import '../config/api_config.dart';
import '../models/place.dart';
import '../models/review.dart';
import '../utils/logger.dart';

class PlaceService {
  final _logger = Logger('PlaceService');
  final _baseUrl = ApiConfig.baseUrl;

  Future<Map<String, dynamic>> getPlaces({
    required Map<String, String> headers,
    String? category,
    String? search,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (category != null) queryParams['category'] = category;
      if (search != null) queryParams['search'] = search;

      final uri = Uri.parse('$_baseUrl/places').replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('Failed to load places: ${response.statusCode}');
      }
    } catch (e) {
      _logger.error('Error getting places: $e');
      rethrow;
    }
  }

  Future<Place> getPlaceDetails({
    required Map<String, String> headers,
    required String placeId,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/places/$placeId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return Place.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to get place details: ${response.statusCode}');
      }
    } catch (e) {
      _logger.error('Error getting place details: $e');
      rethrow;
    }
  }

  Future<Place> createPlace({
    required Map<String, String> headers,
    required Map<String, dynamic> place,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/places'),
        headers: headers,
        body: json.encode(place),
      );

      if (response.statusCode == 201) {
        return Place.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to create place: ${response.statusCode}');
      }
    } catch (e) {
      _logger.error('Error creating place: $e');
      rethrow;
    }
  }

  Future<Place> updatePlace({
    required Map<String, String> headers,
    required String placeId,
    required Map<String, dynamic> place,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/places/$placeId'),
        headers: headers,
        body: json.encode(place),
      );

      if (response.statusCode == 200) {
        return Place.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to update place: ${response.statusCode}');
      }
    } catch (e) {
      _logger.error('Error updating place: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> toggleFavorite({
    required Map<String, String> headers,
    required String placeId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/places/$placeId/favorite'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('Failed to toggle favorite: ${response.statusCode}');
      }
    } catch (e) {
      _logger.error('Error toggling favorite: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getFavorites({
    required Map<String, String> headers,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/places/favorites'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('Failed to get favorites: ${response.statusCode}');
      }
    } catch (e) {
      _logger.error('Error getting favorites: $e');
      rethrow;
    }
  }

  Future<Place> addReview({
    required Map<String, String> headers,
    required String placeId,
    required Map<String, dynamic> review,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/places/$placeId/reviews'),
        headers: headers,
        body: json.encode(review),
      );

      if (response.statusCode == 200) {
        return Place.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to add review: ${response.statusCode}');
      }
    } catch (e) {
      _logger.error('Error adding review: $e');
      rethrow;
    }
  }

  Future<Place> createPlaceNew(Place place) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/places'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(place.toJson()),
      );

      if (response.statusCode == 201) {
        return Place.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to create place: ${response.statusCode}');
      }
    } catch (e) {
      _logger.severe('Error creating place: $e');
      rethrow;
    }
  }

  Future<Place> updatePlaceNew(Place place) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/places/${place.id}'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(place.toJson()),
      );

      if (response.statusCode == 200) {
        return Place.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to update place: ${response.statusCode}');
      }
    } catch (e) {
      _logger.severe('Error updating place: $e');
      rethrow;
    }
  }

  Future<Place> getPlaceDetailsNew(String placeId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/places/$placeId'),
      );

      if (response.statusCode == 200) {
        return Place.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to get place details: ${response.statusCode}');
      }
    } catch (e) {
      _logger.severe('Error getting place details: $e');
      rethrow;
    }
  }

  Future<Place> addReviewNew(String placeId, Review review) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/places/$placeId/reviews'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(review.toJson()),
      );

      if (response.statusCode == 200) {
        return Place.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to add review: ${response.statusCode}');
      }
    } catch (e) {
      _logger.severe('Error adding review: $e');
      rethrow;
    }
  }
}
