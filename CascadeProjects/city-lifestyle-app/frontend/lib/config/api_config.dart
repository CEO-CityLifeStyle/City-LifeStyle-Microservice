import '../utils/logger.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConfig {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8080',
  );

  static String get wsUrl {
    final wsBase = baseUrl.replaceFirst('http', 'ws');
    return '$wsBase/ws/notifications';
  }

  static const int defaultTimeout = 30; // seconds
  
  static const Map<String, String> defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // API Endpoints
  static const String dashboardEndpoint = '/api/dashboard';
  static const String metricsEndpoint = '$dashboardEndpoint/metrics';
  static const String abTestsEndpoint = '$dashboardEndpoint/ab-tests';
  static const String recommendationsEndpoint = '$dashboardEndpoint/recommendations';
  static const String exportEndpoint = '$dashboardEndpoint/export';

  // Error Messages
  static const String networkError = 'Network error occurred. Please check your connection.';
  static const String serverError = 'Server error occurred. Please try again later.';
  static const String unauthorizedError = 'Unauthorized access. Please log in again.';
  static const String notFoundError = 'Resource not found.';
  
  // Cache Configuration
  static const Duration cacheDuration = Duration(minutes: 5);
  static const bool enableCache = true;
  
  // Retry Configuration
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 1);

  // Initialize method to set up API configuration
  static Future<void> initialize() async {
    // Load environment variables from dotenv
    final apiUrl = dotenv.env['API_BASE_URL'];
    if (apiUrl != null && apiUrl.isNotEmpty) {
      // We can't modify baseUrl directly since it's const, but we can use it in other ways
      // For example, you could add a non-const getter that uses the environment value
      _logger.info('API Base URL configured: $apiUrl');
    }
  }
}

// Add logger instance
final _logger = getLogger('ApiConfig');
