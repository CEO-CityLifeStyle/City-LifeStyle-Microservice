import 'dart:convert';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../utils/http_utils.dart';
import 'error_reporting_service.dart';

class AnalyticsService {
  AnalyticsService._internal();

  static final AnalyticsService _instance = AnalyticsService._internal();

  factory AnalyticsService() => _instance;

  final String baseUrl = ApiConfig.baseUrl;
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  final _errorReporting = ErrorReportingService();
  final Map<String, dynamic> _userProperties = {};
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    try {
      await _analytics.setAnalyticsCollectionEnabled(true);
      await _restoreUserProperties();
      _initialized = true;
    } catch (e, stackTrace) {
      await _errorReporting.reportError(
        e,
        stackTrace,
        context: {'source': 'analytics_init'},
      );
    }
  }

  Future<void> _restoreUserProperties() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final properties = prefs.getString('user_properties');
      if (properties != null) {
        final Map<String, dynamic> jsonData = json.decode(properties) as Map<String, dynamic>;
        _userProperties.addAll(jsonData);
        for (final entry in _userProperties.entries) {
          await _analytics.setUserProperty(
            name: entry.key,
            value: entry.value.toString(),
          );
        }
      }
    } catch (e, stackTrace) {
      await _errorReporting.reportError(
        e,
        stackTrace,
        context: {'source': 'restore_user_properties'},
      );
    }
  }

  Future<void> setUserProperty(String name, dynamic value) async {
    try {
      _userProperties[name] = value;
      await _analytics.setUserProperty(
        name: name,
        value: value.toString(),
      );
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_properties', json.encode(_userProperties));
    } catch (e, stackTrace) {
      await _errorReporting.reportError(
        e,
        stackTrace,
        context: {
          'source': 'set_user_property',
          'property': name,
          'value': value,
        },
      );
    }
  }

  Future<void> logEvent(String name, {Map<String, dynamic>? parameters}) async {
    try {
      await _analytics.logEvent(
        name: name,
        parameters: parameters,
      );
    } catch (e, stackTrace) {
      await _errorReporting.reportError(
        e,
        stackTrace,
        context: {
          'source': 'log_event',
          'event': name,
          'parameters': parameters,
        },
      );
    }
  }

  Future<void> setCurrentScreen(String screenName) async {
    try {
      await _analytics.logScreenView(screenName: screenName);
    } catch (e, stackTrace) {
      await _errorReporting.reportError(
        e,
        stackTrace,
        context: {
          'source': 'set_screen',
          'screen': screenName,
        },
      );
    }
  }

  Future<Map<String, dynamic>> getDashboardData() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/analytics/dashboard'),
        headers: HttpUtils.getAuthHeaders('Bearer'),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body) as Map<String, dynamic>;
        await logEvent(
          'view_dashboard',
          parameters: {
            'timestamp': DateTime.now().toIso8601String(),
          },
        );
        return data;
      } else {
        throw Exception('Failed to load analytics data');
      }
    } catch (e, stackTrace) {
      await _errorReporting.reportError(
        e,
        stackTrace,
        context: {'source': 'get_dashboard_data'},
      );
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getReviewTrends({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$baseUrl/api/analytics/reviews/trends?startDate=${startDate.toIso8601String()}&endDate=${endDate.toIso8601String()}',
        ),
        headers: HttpUtils.getAuthHeaders('Bearer'),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body) as Map<String, dynamic>;
        await logEvent(
          'view_review_trends',
          parameters: {
            'start_date': startDate.toIso8601String(),
            'end_date': endDate.toIso8601String(),
          },
        );
        return data;
      } else {
        throw Exception('Failed to load review trends');
      }
    } catch (e, stackTrace) {
      await _errorReporting.reportError(
        e,
        stackTrace,
        context: {'source': 'get_review_trends'},
      );
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getCategoryPerformance() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/analytics/categories/performance'),
        headers: HttpUtils.getAuthHeaders('Bearer'),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body) as Map<String, dynamic>;
        await logEvent('view_category_performance');
        return data;
      } else {
        throw Exception('Failed to load category performance');
      }
    } catch (e, stackTrace) {
      await _errorReporting.reportError(
        e,
        stackTrace,
        context: {'source': 'get_category_performance'},
      );
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getUserEngagement({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$baseUrl/api/analytics/users/engagement?startDate=${startDate.toIso8601String()}&endDate=${endDate.toIso8601String()}',
        ),
        headers: HttpUtils.getAuthHeaders('Bearer'),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body) as Map<String, dynamic>;
        await logEvent(
          'view_user_engagement',
          parameters: {
            'start_date': startDate.toIso8601String(),
            'end_date': endDate.toIso8601String(),
          },
        );
        return data;
      } else {
        throw Exception('Failed to load user engagement data');
      }
    } catch (e, stackTrace) {
      await _errorReporting.reportError(
        e,
        stackTrace,
        context: {'source': 'get_user_engagement'},
      );
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getRatingDistribution() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/analytics/ratings/distribution'),
        headers: HttpUtils.getAuthHeaders('Bearer'),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body) as Map<String, dynamic>;
        await logEvent('view_rating_distribution');
        return data;
      } else {
        throw Exception('Failed to load rating distribution');
      }
    } catch (e, stackTrace) {
      await _errorReporting.reportError(
        e,
        stackTrace,
        context: {'source': 'get_rating_distribution'},
      );
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getSentimentAnalysis({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$baseUrl/api/analytics/sentiment?startDate=${startDate.toIso8601String()}&endDate=${endDate.toIso8601String()}',
        ),
        headers: HttpUtils.getAuthHeaders('Bearer'),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body) as Map<String, dynamic>;
        await logEvent(
          'view_sentiment_analysis',
          parameters: {
            'start_date': startDate.toIso8601String(),
            'end_date': endDate.toIso8601String(),
          },
        );
        return data;
      } else {
        throw Exception('Failed to load sentiment analysis');
      }
    } catch (e, stackTrace) {
      await _errorReporting.reportError(
        e,
        stackTrace,
        context: {'source': 'get_sentiment_analysis'},
      );
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getPlaceAnalytics(String placeId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/analytics/places/$placeId'),
        headers: HttpUtils.getAuthHeaders('Bearer'),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body) as Map<String, dynamic>;
        await logEvent(
          'view_place_analytics',
          parameters: {
            'place_id': placeId,
          },
        );
        return data;
      } else {
        throw Exception('Failed to load place analytics');
      }
    } catch (e, stackTrace) {
      await _errorReporting.reportError(
        e,
        stackTrace,
        context: {'source': 'get_place_analytics'},
      );
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getPerformanceMetrics({
    required DateTime startDate,
    required DateTime endDate,
    required List<String> metrics,
  }) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$baseUrl/api/analytics/performance?startDate=${startDate.toIso8601String()}&endDate=${endDate.toIso8601String()}&metrics=${metrics.join(",")}',
        ),
        headers: HttpUtils.getAuthHeaders('Bearer'),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body) as Map<String, dynamic>;
        await logEvent(
          'view_performance_metrics',
          parameters: {
            'metrics': metrics,
            'start_date': startDate.toIso8601String(),
            'end_date': endDate.toIso8601String(),
          },
        );
        return data;
      } else {
        throw Exception('Failed to load performance metrics');
      }
    } catch (e, stackTrace) {
      await _errorReporting.reportError(
        e,
        stackTrace,
        context: {'source': 'get_performance_metrics'},
      );
      rethrow;
    }
  }
}
