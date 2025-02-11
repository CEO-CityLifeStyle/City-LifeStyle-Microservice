import 'dart:async';
import 'dart:convert';
import 'dart:io' show HttpException;
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../utils/http_utils.dart';
import 'analytics_service.dart';
import 'error_reporting_service.dart';

class ExperimentVariant {
  const ExperimentVariant({
    required this.id,
    required this.name,
    required this.config,
  });

  factory ExperimentVariant.fromJson(Map<String, dynamic> json) => ExperimentVariant(
    id: json['id'] as String,
    name: json['name'] as String,
    config: json['config'] as Map<String, dynamic>,
  );

  final String id;
  final String name;
  final Map<String, dynamic> config;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'config': config,
  };
}

class ABTestResult {
  const ABTestResult({
    required this.variant,
    required this.metadata,
    required this.timestamp,
  });

  factory ABTestResult.fromJson(Map<String, dynamic> json) => ABTestResult(
    variant: json['variant'] as String,
    metadata: (json['metadata'] as Map<String, dynamic>?) ?? {},
    timestamp: DateTime.parse(json['timestamp'] as String),
  );

  final String variant;
  final Map<String, dynamic> metadata;
  final DateTime timestamp;

  Map<String, dynamic> toJson() => {
    'variant': variant,
    'metadata': metadata,
    'timestamp': timestamp.toIso8601String(),
  };
}

class ABTestingService {
  factory ABTestingService() => _instance;
  ABTestingService._internal();

  static final ABTestingService _instance = ABTestingService._internal();

  final Logger _logger = Logger('ABTestingService');
  final ErrorReportingService _errorReporting = ErrorReportingService();
  final AnalyticsService _analytics = AnalyticsService();
  final Map<String, StreamController<String>> _experimentControllers = {};
  final Map<String, String> _activeVariants = {};
  final Map<String, Map<String, dynamic>> _experimentCache = {};
  
  late SharedPreferences _prefs;
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _prefs = await SharedPreferences.getInstance();
      await _fetchExperiments();
      _isInitialized = true;
      _logger.info('AB Testing Service initialized successfully');
    } catch (e, stackTrace) {
      _logger.severe('Failed to initialize AB Testing Service', e, stackTrace);
      await _errorReporting.reportError(
        e,
        stackTrace,
        context: 'Initializing AB Testing Service',
      );
      rethrow;
    }
  }

  Future<void> _fetchExperiments() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/experiments'),
        headers: HttpUtils.getAuthHeaders('GET'),
      );

      if (response.statusCode == 200) {
        final experiments = json.decode(response.body) as Map<String, dynamic>;
        await _assignVariants(experiments);
      } else {
        throw HttpException('Failed to fetch experiments: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      await _errorReporting.reportError(
        e,
        stackTrace,
        context: 'Fetching experiments',
      );
      rethrow;
    }
  }

  Future<void> _assignVariants(Map<String, dynamic> experiments) async {
    try {
      for (final entry in experiments.entries) {
        final experimentId = entry.key;
        final variants = entry.value as Map<String, dynamic>;
        
        // Check if we have a stored variant
        final storedVariant = _prefs.getString('ab_test_$experimentId');
        if (storedVariant != null) {
          _activeVariants[experimentId] = storedVariant;
          continue;
        }

        // Select and store new variant
        final selectedVariant = _selectVariant(variants);
        await _prefs.setString('ab_test_$experimentId', selectedVariant);
        _activeVariants[experimentId] = selectedVariant;
        
        _notifyExperimentSubscribers(experimentId, selectedVariant);
      }
    } catch (e, stackTrace) {
      await _errorReporting.reportError(
        e,
        stackTrace,
        context: 'Assigning variants',
      );
    }
  }

  String _selectVariant(Map<String, dynamic> variants) {
    final weights = variants.map((key, value) => 
      MapEntry(key, (value as Map<String, dynamic>)['weight'] as int? ?? 1),
    );
    
    final totalWeight = weights.values.fold<int>(0, (sum, weight) => sum + weight);
    int random = DateTime.now().millisecondsSinceEpoch % totalWeight;
    
    for (final entry in weights.entries) {
      random -= entry.value;
      if (random < 0) return entry.key;
    }
    
    return weights.keys.first;
  }

  Stream<String> subscribeToExperiment(String experimentId) => 
    _experimentControllers.putIfAbsent(
      experimentId,
      StreamController<String>.broadcast,
    ).stream;

  String? getVariant(String experimentId) => _activeVariants[experimentId];

  Future<void> logExperimentEvent(
    String experimentId,
    String eventName, {
    Map<String, dynamic>? parameters,
  }) async {
    try {
      final variant = _activeVariants[experimentId];
      if (variant == null) {
        _logger.warning('No active variant for experiment: $experimentId');
        return;
      }

      final eventData = {
        'experimentId': experimentId,
        'variant': variant,
        'eventName': eventName,
        'timestamp': DateTime.now().toIso8601String(),
        if (parameters != null) 'parameters': parameters,
      };

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/experiments/$experimentId/events'),
        headers: HttpUtils.getAuthHeaders('POST'),
        body: json.encode(eventData),
      );

      if (response.statusCode != 200) {
        throw HttpException('Failed to log experiment event: ${response.statusCode}');
      }

      await _analytics.logEvent(
        'experiment_event',
        parameters: {
          'experimentId': experimentId,
          'variant': variant,
          'eventName': eventName,
          ...?parameters,
        },
      );
    } catch (e, stackTrace) {
      await _errorReporting.reportError(
        e,
        stackTrace,
        context: 'Logging experiment event',
        metadata: {
          'experimentId': experimentId,
          'eventName': eventName,
          'parameters': parameters,
        },
      );
    }
  }

  Future<void> overrideVariant(String experimentId, String variant) async {
    try {
      await _prefs.setString('ab_test_$experimentId', variant);
      _activeVariants[experimentId] = variant;
      _notifyExperimentSubscribers(experimentId, variant);

      await _analytics.logEvent(
        'experiment_override',
        parameters: {
          'experimentId': experimentId,
          'variant': variant,
        },
      );
    } catch (e, stackTrace) {
      await _errorReporting.reportError(
        e,
        stackTrace,
        context: 'Overriding variant',
        metadata: {
          'experimentId': experimentId,
          'variant': variant,
        },
      );
    }
  }

  Future<List<ABTestResult>> getExperimentResults(String experimentId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/experiments/$experimentId/results'),
        headers: HttpUtils.getAuthHeaders('GET'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> results = json.decode(response.body) as List<dynamic>;
        return results
            .map((result) => ABTestResult.fromJson(result as Map<String, dynamic>))
            .toList();
      } else {
        throw HttpException('Failed to get experiment results: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      await _errorReporting.reportError(
        e,
        stackTrace,
        context: 'Getting experiment results',
        metadata: {'experimentId': experimentId},
      );
      rethrow;
    }
  }

  Future<void> clearCache() async {
    try {
      _experimentCache.clear();
      final keys = _prefs.getKeys().where((key) => key.startsWith('ab_test_'));
      for (final key in keys) {
        await _prefs.remove(key);
      }
      _activeVariants.clear();
      await _fetchExperiments();
    } catch (e, stackTrace) {
      await _errorReporting.reportError(
        e,
        stackTrace,
        context: 'Clearing AB testing cache',
      );
    }
  }

  Future<void> clearCacheForTest(String testId) async {
    try {
      _experimentCache.remove(testId);
      await _prefs.remove('ab_test_$testId');
      _activeVariants.remove(testId);
      await _fetchExperiments();
    } catch (e, stackTrace) {
      await _errorReporting.reportError(
        e,
        stackTrace,
        context: 'Clearing cache for test',
        metadata: {'testId': testId},
      );
    }
  }

  void _notifyExperimentSubscribers(String experimentId, String variant) {
    _experimentControllers[experimentId]?.add(variant);
  }

  void dispose() {
    for (final controller in _experimentControllers.values) {
      controller.close();
    }
    _experimentControllers.clear();
  }
}
