import 'dart:math';
import 'package:shared_preferences.dart';

class ABTestingService {
  static const String _abTestPrefix = 'ab_test_';
  final SharedPreferences _prefs;
  final Random _random;

  ABTestingService(this._prefs) : _random = Random();

  /// Assigns a user to a test variant
  String assignVariant({
    required String testId,
    required String userId,
    required Map<String, double> variants,
  }) {
    final key = _getTestKey(testId, userId);
    final existingVariant = _prefs.getString(key);
    
    if (existingVariant != null && variants.containsKey(existingVariant)) {
      return existingVariant;
    }

    // Normalize weights if they don't sum to 1
    final weightSum = variants.values.reduce((a, b) => a + b);
    final normalizedVariants = variants.map(
      (k, v) => MapEntry(k, v / weightSum),
    );

    // Random selection based on weights
    final rand = _random.nextDouble();
    double cumSum = 0;
    
    for (final entry in normalizedVariants.entries) {
      cumSum += entry.value;
      if (rand <= cumSum) {
        _prefs.setString(key, entry.key);
        _trackAssignment(testId, userId, entry.key);
        return entry.key;
      }
    }

    // Fallback to first variant
    final defaultVariant = variants.keys.first;
    _prefs.setString(key, defaultVariant);
    _trackAssignment(testId, userId, defaultVariant);
    return defaultVariant;
  }

  /// Tracks a conversion for a specific test
  Future<void> trackConversion({
    required String testId,
    required String userId,
    required String conversionType,
    Map<String, dynamic>? metadata,
  }) async {
    final variant = _prefs.getString(_getTestKey(testId, userId));
    if (variant == null) return;

    final conversion = {
      'userId': userId,
      'testId': testId,
      'variant': variant,
      'conversionType': conversionType,
      'timestamp': DateTime.now().toIso8601String(),
      if (metadata != null) ...metadata,
    };

    // Store conversion in local storage
    final conversionsKey = '${_abTestPrefix}conversions_$testId';
    final conversions = _prefs.getStringList(conversionsKey) ?? [];
    conversions.add(DateTime.now().toIso8601String());
    await _prefs.setStringList(conversionsKey, conversions);

    // Track conversion metrics
    await _updateMetrics(testId, variant, conversionType);
  }

  /// Gets test metrics for analysis
  Future<Map<String, dynamic>> getTestMetrics(String testId) async {
    final metricsKey = '${_abTestPrefix}metrics_$testId';
    final metricsStr = _prefs.getString(metricsKey);
    
    if (metricsStr == null) {
      return {
        'testId': testId,
        'variants': {},
        'totalAssignments': 0,
        'totalConversions': 0,
      };
    }

    return Map<String, dynamic>.from(_decodeMetrics(metricsStr));
  }

  /// Ends an A/B test and declares a winner
  Future<Map<String, dynamic>> endTest(String testId) async {
    final metrics = await getTestMetrics(testId);
    final variants = Map<String, dynamic>.from(metrics['variants'] ?? {});

    if (variants.isEmpty) {
      return {'error': 'No data available for test'};
    }

    // Calculate conversion rates and find winner
    String? winner;
    double maxRate = 0;

    for (final entry in variants.entries) {
      final variant = entry.key;
      final data = entry.value as Map<String, dynamic>;
      final assignments = data['assignments'] ?? 0;
      final conversions = data['conversions'] ?? 0;

      if (assignments > 0) {
        final rate = conversions / assignments;
        if (rate > maxRate) {
          maxRate = rate;
          winner = variant;
        }
      }
    }

    final results = {
      'testId': testId,
      'winner': winner,
      'metrics': metrics,
      'endDate': DateTime.now().toIso8601String(),
    };

    // Store test results
    await _prefs.setString(
      '${_abTestPrefix}results_$testId',
      _encodeMetrics(results),
    );

    return results;
  }

  // Private helper methods
  String _getTestKey(String testId, String userId) {
    return '$_abTestPrefix${testId}_$userId';
  }

  Future<void> _trackAssignment(
    String testId,
    String userId,
    String variant,
  ) async {
    final metricsKey = '${_abTestPrefix}metrics_$testId';
    final metrics = await getTestMetrics(testId);
    
    final variants = Map<String, dynamic>.from(metrics['variants'] ?? {});
    final variantData = Map<String, dynamic>.from(
      variants[variant] ?? {'assignments': 0, 'conversions': 0},
    );

    variantData['assignments'] = (variantData['assignments'] ?? 0) + 1;
    variants[variant] = variantData;
    metrics['variants'] = variants;
    metrics['totalAssignments'] = (metrics['totalAssignments'] ?? 0) + 1;

    await _prefs.setString(metricsKey, _encodeMetrics(metrics));
  }

  Future<void> _updateMetrics(
    String testId,
    String variant,
    String conversionType,
  ) async {
    final metricsKey = '${_abTestPrefix}metrics_$testId';
    final metrics = await getTestMetrics(testId);
    
    final variants = Map<String, dynamic>.from(metrics['variants'] ?? {});
    final variantData = Map<String, dynamic>.from(
      variants[variant] ?? {'assignments': 0, 'conversions': 0},
    );

    variantData['conversions'] = (variantData['conversions'] ?? 0) + 1;
    variants[variant] = variantData;
    metrics['variants'] = variants;
    metrics['totalConversions'] = (metrics['totalConversions'] ?? 0) + 1;

    await _prefs.setString(metricsKey, _encodeMetrics(metrics));
  }

  String _encodeMetrics(Map<String, dynamic> metrics) {
    return Uri.encodeFull(metrics.toString());
  }

  Map<String, dynamic> _decodeMetrics(String encoded) {
    final decoded = Uri.decodeFull(encoded);
    // Convert string representation of map to actual map
    return Map<String, dynamic>.from(
      Map<String, dynamic>.from(decoded as Map),
    );
  }
}
