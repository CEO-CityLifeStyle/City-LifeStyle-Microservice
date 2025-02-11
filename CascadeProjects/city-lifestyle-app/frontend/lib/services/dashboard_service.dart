import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/dashboard/performance_metrics.dart';
import '../models/dashboard/ab_test_result.dart';
import '../models/dashboard/recommendation_metrics.dart';
import 'secure_storage_service.dart';
import 'realtime_service.dart';
import 'error_reporting_service.dart';
import 'cache_service.dart';
import 'retry_service.dart';
import 'offline_manager.dart';
import 'background_sync_service.dart';
import 'cache_prefetch_service.dart';

class DashboardService {
  final String baseUrl = ApiConfig.baseUrl;
  final http.Client _client;
  final RealtimeService _realtimeService;
  final ErrorReportingService _errorReporting;
  final CacheService _cache;
  final RetryService _retry;
  final OfflineManager _offlineManager;
  final BackgroundSyncService _backgroundSync;
  final CachePrefetchService _prefetchService;
  
  DashboardService({http.Client? client})
      : _client = client ?? http.Client(),
        _realtimeService = RealtimeService(),
        _errorReporting = ErrorReportingService(),
        _cache = CacheService(),
        _retry = RetryService(),
        _offlineManager = OfflineManager(),
        _backgroundSync = BackgroundSyncService(),
        _prefetchService = CachePrefetchService();

  Future<void> initialize() async {
    await _backgroundSync.initialize();
    await _prefetchService.initialize();
  }

  Future<PerformanceMetrics> getPerformanceMetrics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final cacheKey = 'performance_metrics_${startDate?.toIso8601String()}_${endDate?.toIso8601String()}';
    
    try {
      // Try to get from cache first
      final cachedData = await _cache.get<Map<String, dynamic>>(cacheKey);
      if (cachedData != null) {
        // Prefetch next data range in background
        _prefetchNextDataRange(startDate, endDate);
        return PerformanceMetrics.fromJson(cachedData);
      }

      // Try to get from offline storage if we're offline
      if (!_offlineManager.isOnline) {
        final offlineData = await _offlineManager.getOfflineData<PerformanceMetrics>(
          cacheKey,
          (json) => PerformanceMetrics.fromJson(json),
        );
        if (offlineData != null) {
          return offlineData;
        }
      }

      return await _retry.retry(
        operation: () async {
          final queryParams = {
            if (startDate != null) 'startDate': startDate.toIso8601String(),
            if (endDate != null) 'endDate': endDate.toIso8601String(),
          };

          final response = await _client.get(
            Uri.parse('$baseUrl/api/dashboard/metrics').replace(queryParameters: queryParams),
            headers: await _getHeaders(),
          );

          if (response.statusCode == 200) {
            final data = json.decode(response.body);
            final metrics = PerformanceMetrics.fromJson(data);
            
            // Cache the response
            await _cache.set(cacheKey, data, expiry: ApiConfig.cacheDuration);
            // Store for offline use
            await _offlineManager.saveOfflineData(cacheKey, data);
            // Prefetch next data range
            _prefetchNextDataRange(startDate, endDate);
            
            return metrics;
          } else if (response.statusCode == 401) {
            throw Exception(ApiConfig.unauthorizedError);
          } else {
            throw Exception('Failed to load performance metrics: ${response.statusCode}');
          }
        },
        shouldRetry: (e) => _retry.shouldRetryException(e),
      );
    } catch (e, stackTrace) {
      await _errorReporting.reportError(
        e,
        stackTrace,
        context: {
          'startDate': startDate?.toIso8601String(),
          'endDate': endDate?.toIso8601String(),
        },
      );
      rethrow;
    }
  }

  void _prefetchNextDataRange(DateTime? startDate, DateTime? endDate) {
    if (startDate != null && endDate != null) {
      final duration = endDate.difference(startDate);
      final nextStartDate = endDate;
      final nextEndDate = endDate.add(duration);

      _prefetchService.prefetchDashboardData(
        startDate: nextStartDate,
        endDate: nextEndDate,
      );
    }
  }

  Stream<PerformanceMetrics> streamPerformanceMetrics() {
    return _realtimeService.subscribeToPerformanceMetrics();
  }

  Future<List<ABTestResult>> getABTestResults() async {
    const cacheKey = 'ab_test_results';
    
    try {
      // Try to get from cache first
      final cachedData = await _cache.get<List<dynamic>>(cacheKey);
      if (cachedData != null) {
        return cachedData.map((json) => ABTestResult.fromJson(json)).toList();
      }

      // Try to get from offline storage if we're offline
      if (!_offlineManager.isOnline) {
        final offlineData = await _offlineManager.getOfflineData<List<ABTestResult>>(
          cacheKey,
          (json) => (json['data'] as List).map((item) => ABTestResult.fromJson(item)).toList(),
        );
        if (offlineData != null) {
          return offlineData;
        }
      }

      return await _retry.retry(
        operation: () async {
          final response = await _client.get(
            Uri.parse('$baseUrl/api/dashboard/ab-tests'),
            headers: await _getHeaders(),
          );

          if (response.statusCode == 200) {
            final data = json.decode(response.body) as List<dynamic>;
            final results = data.map((json) => ABTestResult.fromJson(json)).toList();
            
            // Cache the response
            await _cache.set(cacheKey, data, expiry: ApiConfig.cacheDuration);
            // Store for offline use
            await _offlineManager.saveOfflineData(cacheKey, {'data': data});
            
            return results;
          } else if (response.statusCode == 401) {
            throw Exception(ApiConfig.unauthorizedError);
          } else {
            throw Exception('Failed to load A/B test results: ${response.statusCode}');
          }
        },
        shouldRetry: (e) => _retry.shouldRetryException(e),
      );
    } catch (e, stackTrace) {
      await _errorReporting.reportError(e, stackTrace);
      rethrow;
    }
  }

  Stream<List<ABTestResult>> streamABTestResults() {
    return _realtimeService.subscribeToABTests();
  }

  Future<RecommendationMetrics> getRecommendationMetrics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final cacheKey = 'recommendation_metrics_${startDate?.toIso8601String()}_${endDate?.toIso8601String()}';
    
    try {
      // Try to get from cache first
      final cachedData = await _cache.get<Map<String, dynamic>>(cacheKey);
      if (cachedData != null) {
        // Prefetch next data range in background
        _prefetchNextDataRange(startDate, endDate);
        return RecommendationMetrics.fromJson(cachedData);
      }

      // Try to get from offline storage if we're offline
      if (!_offlineManager.isOnline) {
        final offlineData = await _offlineManager.getOfflineData<RecommendationMetrics>(
          cacheKey,
          (json) => RecommendationMetrics.fromJson(json),
        );
        if (offlineData != null) {
          return offlineData;
        }
      }

      return await _retry.retry(
        operation: () async {
          final queryParams = {
            if (startDate != null) 'startDate': startDate.toIso8601String(),
            if (endDate != null) 'endDate': endDate.toIso8601String(),
          };

          final response = await _client.get(
            Uri.parse('$baseUrl/api/dashboard/recommendations').replace(queryParameters: queryParams),
            headers: await _getHeaders(),
          );

          if (response.statusCode == 200) {
            final data = json.decode(response.body);
            final metrics = RecommendationMetrics.fromJson(data);
            
            // Cache the response
            await _cache.set(cacheKey, data, expiry: ApiConfig.cacheDuration);
            // Store for offline use
            await _offlineManager.saveOfflineData(cacheKey, data);
            // Prefetch next data range
            _prefetchNextDataRange(startDate, endDate);
            
            return metrics;
          } else if (response.statusCode == 401) {
            throw Exception(ApiConfig.unauthorizedError);
          } else {
            throw Exception('Failed to load recommendation metrics: ${response.statusCode}');
          }
        },
        shouldRetry: (e) => _retry.shouldRetryException(e),
      );
    } catch (e, stackTrace) {
      await _errorReporting.reportError(
        e,
        stackTrace,
        context: {
          'startDate': startDate?.toIso8601String(),
          'endDate': endDate?.toIso8601String(),
        },
      );
      rethrow;
    }
  }

  Stream<RecommendationMetrics> streamRecommendationMetrics() {
    return _realtimeService.subscribeToRecommendations();
  }

  Future<Map<String, dynamic>> exportDashboardData({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      if (!_offlineManager.isOnline) {
        // Queue the export operation for when we're back online
        await _offlineManager.queueOperation(
          operation: 'export',
          endpoint: '/api/dashboard/export',
          data: {
            'startDate': startDate?.toIso8601String(),
            'endDate': endDate?.toIso8601String(),
          },
        );
        throw Exception('Cannot export data while offline. Operation queued for later.');
      }

      return await _retry.retry(
        operation: () async {
          final queryParams = {
            if (startDate != null) 'startDate': startDate.toIso8601String(),
            if (endDate != null) 'endDate': endDate.toIso8601String(),
          };

          final response = await _client.get(
            Uri.parse('$baseUrl/api/dashboard/export').replace(queryParameters: queryParams),
            headers: await _getHeaders(),
          );

          if (response.statusCode == 200) {
            return json.decode(response.body);
          } else if (response.statusCode == 401) {
            throw Exception(ApiConfig.unauthorizedError);
          } else {
            throw Exception('Failed to export dashboard data: ${response.statusCode}');
          }
        },
        shouldRetry: (e) => _retry.shouldRetryException(e),
      );
    } catch (e, stackTrace) {
      await _errorReporting.reportError(
        e,
        stackTrace,
        context: {
          'startDate': startDate?.toIso8601String(),
          'endDate': endDate?.toIso8601String(),
        },
      );
      rethrow;
    }
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = await SecureStorageService.getAuthToken();
    if (token == null) {
      throw Exception(ApiConfig.unauthorizedError);
    }
    
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<void> connectRealtimeUpdates() async {
    await _realtimeService.connect();
  }

  Future<void> disconnectRealtimeUpdates() async {
    await _realtimeService.disconnect();
  }

  void dispose() {
    _client.close();
    disconnectRealtimeUpdates();
    _cache.dispose();
    _offlineManager.dispose();
    _backgroundSync.dispose();
    _prefetchService.dispose();
  }
}
