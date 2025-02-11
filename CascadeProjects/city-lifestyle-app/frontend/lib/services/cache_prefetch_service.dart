import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'cache_service.dart';
import 'dashboard_service.dart';
import 'error_reporting_service.dart';

class CachePrefetchService {
  static final CachePrefetchService _instance = CachePrefetchService._internal();
  factory CachePrefetchService() => _instance;

  final _connectivity = Connectivity();
  final _cache = CacheService();
  final _errorReporting = ErrorReportingService();
  final _dashboardService = DashboardService();

  bool _isPrefetching = false;
  Timer? _prefetchTimer;
  final _prefetchQueue = <PrefetchRequest>[];
  final _processingQueue = <String>{};

  CachePrefetchService._internal();

  Future<void> initialize() async {
    _setupPeriodicPrefetch();
    _setupConnectivityListener();
  }

  void _setupPeriodicPrefetch() {
    _prefetchTimer?.cancel();
    _prefetchTimer = Timer.periodic(
      const Duration(minutes: 30),
      (_) => _prefetchDashboardData(),
    );
  }

  void _setupConnectivityListener() {
    _connectivity.onConnectivityChanged.listen((ConnectivityResult result) {
      if (result != ConnectivityResult.none) {
        _processPrefetchQueue();
      }
    });
  }

  Future<void> prefetchDashboardData({
    DateTime? startDate,
    DateTime? endDate,
    bool force = false,
  }) async {
    final request = PrefetchRequest(
      type: PrefetchType.dashboard,
      parameters: {
        if (startDate != null) 'startDate': startDate.toIso8601String(),
        if (endDate != null) 'endDate': endDate.toIso8601String(),
      },
      force: force,
    );

    _enqueuePrefetchRequest(request);
    _processPrefetchQueue();
  }

  void _enqueuePrefetchRequest(PrefetchRequest request) {
    if (!_prefetchQueue.contains(request)) {
      _prefetchQueue.add(request);
    }
  }

  Future<void> _processPrefetchQueue() async {
    if (_isPrefetching) return;

    try {
      _isPrefetching = true;
      final connectivityResult = await _connectivity.checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) return;

      while (_prefetchQueue.isNotEmpty) {
        final request = _prefetchQueue.removeAt(0);
        if (_processingQueue.contains(request.cacheKey)) continue;

        _processingQueue.add(request.cacheKey);
        try {
          await _processPrefetchRequest(request);
        } finally {
          _processingQueue.remove(request.cacheKey);
        }
      }
    } catch (e, stackTrace) {
      await _errorReporting.reportError(
        e,
        stackTrace,
        context: {'source': 'cache_prefetch'},
      );
    } finally {
      _isPrefetching = false;
    }
  }

  Future<void> _processPrefetchRequest(PrefetchRequest request) async {
    try {
      if (!request.force) {
        // Check if we already have valid cached data
        final cachedData = await _cache.get(request.cacheKey);
        if (cachedData != null) return;
      }

      switch (request.type) {
        case PrefetchType.dashboard:
          await _prefetchDashboardData(
            startDate: request.parameters['startDate'] != null
                ? DateTime.parse(request.parameters['startDate']!)
                : null,
            endDate: request.parameters['endDate'] != null
                ? DateTime.parse(request.parameters['endDate']!)
                : null,
          );
          break;
        // Add other prefetch types here
      }
    } catch (e, stackTrace) {
      await _errorReporting.reportError(
        e,
        stackTrace,
        context: {
          'source': 'prefetch_request',
          'request': request.toString(),
        },
      );
    }
  }

  Future<void> _prefetchDashboardData({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      // Prefetch in parallel using compute to avoid blocking the main thread
      await Future.wait([
        compute(
          _prefetchPerformanceMetrics,
          {
            'startDate': startDate?.toIso8601String(),
            'endDate': endDate?.toIso8601String(),
          },
        ),
        compute(
          _prefetchABTestResults,
          null,
        ),
        compute(
          _prefetchRecommendationMetrics,
          {
            'startDate': startDate?.toIso8601String(),
            'endDate': endDate?.toIso8601String(),
          },
        ),
      ]);
    } catch (e, stackTrace) {
      await _errorReporting.reportError(
        e,
        stackTrace,
        context: {
          'source': 'dashboard_prefetch',
          'startDate': startDate?.toIso8601String(),
          'endDate': endDate?.toIso8601String(),
        },
      );
    }
  }

  static Future<void> _prefetchPerformanceMetrics(Map<String, String?> params) async {
    final dashboardService = DashboardService();
    final startDate = params['startDate'] != null
        ? DateTime.parse(params['startDate']!)
        : null;
    final endDate = params['endDate'] != null
        ? DateTime.parse(params['endDate']!)
        : null;

    await dashboardService.getPerformanceMetrics(
      startDate: startDate,
      endDate: endDate,
    );
  }

  static Future<void> _prefetchABTestResults(void _) async {
    final dashboardService = DashboardService();
    await dashboardService.getABTestResults();
  }

  static Future<void> _prefetchRecommendationMetrics(Map<String, String?> params) async {
    final dashboardService = DashboardService();
    final startDate = params['startDate'] != null
        ? DateTime.parse(params['startDate']!)
        : null;
    final endDate = params['endDate'] != null
        ? DateTime.parse(params['endDate']!)
        : null;

    await dashboardService.getRecommendationMetrics(
      startDate: startDate,
      endDate: endDate,
    );
  }

  void dispose() {
    _prefetchTimer?.cancel();
    _prefetchTimer = null;
    _prefetchQueue.clear();
    _processingQueue.clear();
  }
}

enum PrefetchType {
  dashboard,
  // Add other types as needed
}

class PrefetchRequest {
  final PrefetchType type;
  final Map<String, String> parameters;
  final bool force;

  PrefetchRequest({
    required this.type,
    this.parameters = const {},
    this.force = false,
  });

  String get cacheKey => '${type.toString()}_${parameters.toString()}';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PrefetchRequest &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          mapEquals(parameters, other.parameters);

  @override
  int get hashCode => type.hashCode ^ parameters.hashCode;

  @override
  String toString() =>
      'PrefetchRequest(type: $type, parameters: $parameters, force: $force)';
}
