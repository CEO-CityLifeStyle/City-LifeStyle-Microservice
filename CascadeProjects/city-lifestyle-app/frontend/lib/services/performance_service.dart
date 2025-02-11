import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../utils/http_utils.dart';
import 'analytics_service.dart';
import 'error_reporting_service.dart';

class PerformanceService {
  static final PerformanceService _instance = PerformanceService._internal();
  factory PerformanceService() => _instance;

  final String baseUrl = ApiConfig.baseUrl;
  final _analytics = AnalyticsService();
  final _errorReporting = ErrorReportingService();
  final Map<String, Timer> _periodicChecks = {};
  final Map<String, List<double>> _metrics = {};
  final _metricsController = StreamController<Map<String, double>>.broadcast();

  static const _maxMetricHistory = 100;
  static const _defaultCheckInterval = Duration(minutes: 5);
  static const _criticalThreshold = 0.95; // 95th percentile
  static const _warningThreshold = 0.80; // 80th percentile

  PerformanceService._internal();

  Stream<Map<String, double>> get metricsStream => _metricsController.stream;

  Future<void> initialize() async {
    try {
      await _restoreMetrics();
      _startPeriodicChecks();
    } catch (e, stackTrace) {
      await _errorReporting.reportError(
        e,
        stackTrace,
        context: {'source': 'performance_init'},
      );
    }
  }

  Future<void> _restoreMetrics() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedMetrics = prefs.getString('performance_metrics');
      if (storedMetrics != null) {
        final decoded = json.decode(storedMetrics) as Map<String, dynamic>;
        decoded.forEach((key, value) {
          _metrics[key] = List<double>.from(value);
        });
      }
    } catch (e, stackTrace) {
      await _errorReporting.reportError(
        e,
        stackTrace,
        context: {'source': 'restore_metrics'},
      );
    }
  }

  void _startPeriodicChecks() {
    _startCheck('memory_usage', _checkMemoryUsage);
    _startCheck('cpu_usage', _checkCPUUsage);
    _startCheck('network_latency', _checkNetworkLatency);
    _startCheck('storage_usage', _checkStorageUsage);
    _startCheck('battery_level', _checkBatteryLevel);
  }

  void _startCheck(String metric, Future<double> Function() check) {
    _periodicChecks[metric]?.cancel();
    _periodicChecks[metric] = Timer.periodic(_defaultCheckInterval, (_) async {
      try {
        final value = await check();
        _updateMetric(metric, value);
      } catch (e, stackTrace) {
        await _errorReporting.reportError(
          e,
          stackTrace,
          context: {
            'source': 'periodic_check',
            'metric': metric,
          },
        );
      }
    });
  }

  void _updateMetric(String metric, double value) {
    if (!_metrics.containsKey(metric)) {
      _metrics[metric] = [];
    }

    _metrics[metric]!.add(value);
    if (_metrics[metric]!.length > _maxMetricHistory) {
      _metrics[metric]!.removeAt(0);
    }

    _checkThresholds(metric, value);
    _metricsController.add({metric: value});
    _persistMetrics();
  }

  Future<void> _persistMetrics() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('performance_metrics', json.encode(_metrics));
    } catch (e, stackTrace) {
      await _errorReporting.reportError(
        e,
        stackTrace,
        context: {'source': 'persist_metrics'},
      );
    }
  }

  void _checkThresholds(String metric, double value) {
    if (_metrics[metric]!.length < 10) return; // Need enough data points

    final sortedValues = List<double>.from(_metrics[metric]!)..sort();
    final criticalIndex = (sortedValues.length * _criticalThreshold).floor();
    final warningIndex = (sortedValues.length * _warningThreshold).floor();

    if (value > sortedValues[criticalIndex]) {
      _reportCriticalMetric(metric, value);
    } else if (value > sortedValues[warningIndex]) {
      _reportWarningMetric(metric, value);
    }
  }

  Future<void> _reportCriticalMetric(String metric, double value) async {
    await _analytics.logEvent('critical_performance', parameters: {
      'metric': metric,
      'value': value,
      'threshold': _criticalThreshold,
    });
  }

  Future<void> _reportWarningMetric(String metric, double value) async {
    await _analytics.logEvent('warning_performance', parameters: {
      'metric': metric,
      'value': value,
      'threshold': _warningThreshold,
    });
  }

  Future<double> _checkMemoryUsage() async {
    // This is a simplified example. In a real app, you'd use platform-specific code
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/performance/memory'),
        headers: HttpUtils.getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['usage'].toDouble();
      }
      throw Exception('Failed to get memory usage');
    } catch (e) {
      rethrow;
    }
  }

  Future<double> _checkCPUUsage() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/performance/cpu'),
        headers: HttpUtils.getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['usage'].toDouble();
      }
      throw Exception('Failed to get CPU usage');
    } catch (e) {
      rethrow;
    }
  }

  Future<double> _checkNetworkLatency() async {
    try {
      final stopwatch = Stopwatch()..start();
      final response = await http.get(
        Uri.parse('$baseUrl/api/health'),
        headers: HttpUtils.getAuthHeaders(),
      );
      stopwatch.stop();

      if (response.statusCode == 200) {
        return stopwatch.elapsedMilliseconds.toDouble();
      }
      throw Exception('Failed to check network latency');
    } catch (e) {
      rethrow;
    }
  }

  Future<double> _checkStorageUsage() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/performance/storage'),
        headers: HttpUtils.getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['usage'].toDouble();
      }
      throw Exception('Failed to get storage usage');
    } catch (e) {
      rethrow;
    }
  }

  Future<double> _checkBatteryLevel() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/performance/battery'),
        headers: HttpUtils.getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['level'].toDouble();
      }
      throw Exception('Failed to get battery level');
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, List<double>>> getMetricsHistory({
    List<String>? metrics,
    DateTime? startTime,
    DateTime? endTime,
  }) async {
    try {
      if (metrics == null) {
        return Map<String, List<double>>.from(_metrics);
      }

      return Map.fromEntries(
        metrics.map((metric) => MapEntry(metric, _metrics[metric] ?? [])),
      );
    } catch (e, stackTrace) {
      await _errorReporting.reportError(
        e,
        stackTrace,
        context: {'source': 'get_metrics_history'},
      );
      rethrow;
    }
  }

  Future<Map<String, double>> getMetricsAverages({List<String>? metrics}) async {
    try {
      final result = <String, double>{};
      final targetMetrics = metrics ?? _metrics.keys;

      for (final metric in targetMetrics) {
        final values = _metrics[metric];
        if (values != null && values.isNotEmpty) {
          result[metric] = values.reduce((a, b) => a + b) / values.length;
        }
      }

      return result;
    } catch (e, stackTrace) {
      await _errorReporting.reportError(
        e,
        stackTrace,
        context: {'source': 'get_metrics_averages'},
      );
      rethrow;
    }
  }

  Future<void> setCheckInterval(String metric, Duration interval) async {
    try {
      _periodicChecks[metric]?.cancel();
      _startCheck(metric, _getCheckFunction(metric));
    } catch (e, stackTrace) {
      await _errorReporting.reportError(
        e,
        stackTrace,
        context: {
          'source': 'set_check_interval',
          'metric': metric,
        },
      );
    }
  }

  Future<void> Function() _getCheckFunction(String metric) {
    switch (metric) {
      case 'memory_usage':
        return _checkMemoryUsage;
      case 'cpu_usage':
        return _checkCPUUsage;
      case 'network_latency':
        return _checkNetworkLatency;
      case 'storage_usage':
        return _checkStorageUsage;
      case 'battery_level':
        return _checkBatteryLevel;
      default:
        throw ArgumentError('Unknown metric: $metric');
    }
  }

  void dispose() {
    for (var timer in _periodicChecks.values) {
      timer.cancel();
    }
    _periodicChecks.clear();
    _metricsController.close();
  }
}
