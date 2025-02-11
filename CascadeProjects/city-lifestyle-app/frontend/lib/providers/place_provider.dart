import 'package:flutter/foundation.dart';
import '../models/place.dart';
import '../services/place_service.dart';
import '../utils/logger.dart';

class PlaceProvider with ChangeNotifier {
  PlaceProvider(this._placeService);

  final PlaceService _placeService;
  final _logger = getLogger('PlaceProvider');
  List<Place> _places = [];
  bool _isLoading = false;
  String? _error;
  String? _token;

  List<Place> get places => [..._places];
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadPlaces({String? category, String? search}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final headers = _getAuthHeaders();
      final response = await _placeService.getPlaces(
        headers: headers,
        category: category,
        search: search,
      );

      _places = (response['places'] as List)
          .map((place) => Place.fromJson(place as Map<String, dynamic>))
          .toList();
      
      notifyListeners();
    } catch (e) {
      _logger.severe('Error loading places: $e');
      _error = 'Failed to load places. Please try again.';
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Place?> loadPlaceDetails(String placeId) async {
    try {
      final headers = _getAuthHeaders();
      final response = await _placeService.getPlaceDetails(
        headers: headers,
        placeId: placeId,
      );

      final place = Place.fromJson(response as Map<String, dynamic>);
      final index = _places.indexWhere((p) => p.id == placeId);
      if (index >= 0) {
        _places[index] = place;
        notifyListeners();
      }
      return place;
    } catch (e) {
      _logger.severe('Error loading place details: $e');
      _error = 'Failed to load place details. Please try again.';
      notifyListeners();
      return null;
    }
  }

  Future<Place?> createPlace(Place place) async {
    try {
      final headers = _getAuthHeaders();
      final response = await _placeService.createPlace(
        headers: headers,
        place: place.toJson(),
      );

      final newPlace = Place.fromJson(response as Map<String, dynamic>);
      _places.add(newPlace);
      notifyListeners();
      return newPlace;
    } catch (e) {
      _logger.severe('Error creating place: $e');
      _error = 'Failed to create place. Please try again.';
      notifyListeners();
      return null;
    }
  }

  Future<void> updatePlace(Place place) async {
    try {
      final headers = _getAuthHeaders();
      final updatedPlace = await _placeService.updatePlace(
        headers: headers,
        placeId: place.id,
        place: place.toJson(),
      );

      final index = _places.indexWhere((p) => p.id == place.id);
      if (index >= 0) {
        _places[index] = Place.fromJson(updatedPlace as Map<String, dynamic>);
        notifyListeners();
      }
    } catch (e) {
      _logger.severe('Error updating place: $e');
      rethrow;
    }
  }

  Future<bool> toggleFavorite(String placeId) async {
    try {
      final headers = _getAuthHeaders();
      final response = await _placeService.toggleFavorite(
        headers: headers,
        placeId: placeId,
      );

      final isFavorite = response['isFavorite'] as bool;
      final index = _places.indexWhere((p) => p.id == placeId);
      if (index >= 0) {
        _places[index] = _places[index].copyWith(isFavorite: isFavorite);
        notifyListeners();
      }
      return isFavorite;
    } catch (e) {
      _logger.severe('Error toggling favorite: $e');
      _error = 'Failed to update favorite status. Please try again.';
      notifyListeners();
      return false;
    }
  }

  Future<List<Place>> getFavorites() async {
    try {
      final headers = _getAuthHeaders();
      final response = await _placeService.getFavorites(headers: headers);

      return (response['places'] as List)
          .map((place) => Place.fromJson(place as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _logger.severe('Error loading favorites: $e');
      _error = 'Failed to load favorites. Please try again.';
      notifyListeners();
      return [];
    }
  }

  Map<String, String> _getAuthHeaders() => {
    'Authorization': 'Bearer $_token',
    'Content-Type': 'application/json',
  };

  void setToken(String? token) {
    _token = token;
    notifyListeners();
  }
}
