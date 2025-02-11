import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/search_filters.dart';
import '../utils/logger.dart';

class SearchProvider with ChangeNotifier {
  SearchProvider() {
    _logger = getLogger('SearchProvider');
  }

  late final _logger;
  String _searchQuery = '';
  SearchFilters _filters = SearchFilters();
  List<String>? _categories;
  List<String>? _priceRanges;
  List<double>? _ratings;
  bool _isLoading = false;
  Timer? _debounceTimer;

  // Getters
  String get searchQuery => _searchQuery;
  SearchFilters get filters => _filters;
  List<String>? get categories => _categories;
  List<String>? get priceRanges => _priceRanges;
  List<double>? get ratings => _ratings;
  bool get isLoading => _isLoading;

  Future<void> initializeFilters() async {
    try {
      _isLoading = true;
      notifyListeners();

      // Initialize with default values for now
      // TODO: Fetch from API when backend is ready
      _categories = [
        'Restaurants',
        'Shopping',
        'Entertainment',
        'Services',
        'Hotels',
      ];

      _priceRanges = [
        '\$',
        '\$\$',
        '\$\$\$',
        '\$\$\$\$',
      ];

      _ratings = [
        3.0,
        3.5,
        4.0,
        4.5,
        5.0,
      ];

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _logger.severe('Error initializing filters: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  void updateSearchQuery(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _searchQuery = query;
      notifyListeners();
      _performSearch();
    });
  }

  void updateFilters(SearchFilters filters) {
    _filters = filters;
    notifyListeners();
    _performSearch();
  }

  void clearSearch() {
    _searchQuery = '';
    _filters = SearchFilters();
    notifyListeners();
  }

  Future<void> _performSearch() async {
    try {
      _isLoading = true;
      notifyListeners();

      // TODO: Implement actual search logic when backend is ready
      await Future.delayed(const Duration(milliseconds: 500));

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _logger.severe('Error performing search: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}
