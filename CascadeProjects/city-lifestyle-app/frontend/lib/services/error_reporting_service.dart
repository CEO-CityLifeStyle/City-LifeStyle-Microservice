import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../config/api_config.dart';
import '../utils/http_utils.dart';

class ErrorReport {
  final String error;
  final String stackTrace;
  final String context;
  final Map<String, dynamic> metadata;
  final DateTime timestamp;
  final String severity;

  const ErrorReport({
    required this.error,
    required this.stackTrace,
    required this.context,
    required this.metadata,
    required this.timestamp,
    required this.severity,
  });

  Map<String, dynamic> toJson() => {
    'error': error,
    'stackTrace': stackTrace,
    'context': context,
    'metadata': metadata,
    'timestamp': timestamp.toIso8601String(),
    'severity': severity,
  };
}

class ErrorReportingService {
  static final ErrorReportingService _instance = ErrorReportingService._internal();
  factory ErrorReportingService() => _instance;

  final ApiConfig _apiConfig;
  final Logger _logger = Logger('ErrorReportingService');
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  PackageInfo? _packageInfo;

  ErrorReportingService._internal() : _apiConfig = ApiConfig() {
    _initializePackageInfo();
  }

  Future<void> _initializePackageInfo() async {
    try {
      _packageInfo = await PackageInfo.fromPlatform();
    } catch (e) {
      _logger.warning('Failed to initialize package info: $e');
    }
  }

  Future<Map<String, dynamic>> _getDeviceInfo() async {
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        final androidInfo = await _deviceInfo.androidInfo;
        return {
          'platform': 'android',
          'model': androidInfo.model,
          'manufacturer': androidInfo.manufacturer,
          'version': androidInfo.version.release,
          'sdk': androidInfo.version.sdkInt.toString(),
        };
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        return {
          'platform': 'ios',
          'model': iosInfo.model,
          'version': iosInfo.systemVersion,
          'name': iosInfo.name,
          'systemName': iosInfo.systemName,
        };
      }
      return {'platform': 'unknown'};
    } catch (e) {
      _logger.warning('Failed to get device info: $e');
      return {'platform': 'unknown', 'error': e.toString()};
    }
  }

  Future<void> reportError(
    dynamic error,
    StackTrace stackTrace, {
    String context = 'unknown',
    Map<String, dynamic>? metadata,
    String severity = 'error',
  }) async {
    try {
      final deviceInfo = await _getDeviceInfo();
      final report = ErrorReport(
        error: error.toString(),
        stackTrace: stackTrace.toString(),
        context: context,
        metadata: {
          ...?metadata,
          'device': deviceInfo,
          'app': {
            'version': _packageInfo?.version ?? 'unknown',
            'buildNumber': _packageInfo?.buildNumber ?? 'unknown',
          },
        },
        timestamp: DateTime.now(),
        severity: severity,
      );

      await _sendErrorReport(report);
      _logger.warning('Error reported: ${error.toString()}');
    } catch (e) {
      _logger.severe('Failed to report error: $e');
    }
  }

  Future<void> _sendErrorReport(ErrorReport report) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/errors'),
        headers: {
          'Content-Type': 'application/json',
          ...await HttpUtils.getAuthHeaders(),
        },
        body: json.encode(report.toJson()),
      );

      if (response.statusCode != 200) {
        _logger.warning(
          'Failed to send error report: ${response.statusCode}',
        );
      }
    } catch (e) {
      _logger.severe('Failed to send error report: $e');
    }
  }

  Future<void> reportWarning(
    String message, {
    String context = 'unknown',
    Map<String, dynamic>? metadata,
  }) async {
    await reportError(
      message,
      StackTrace.current,
      context: context,
      metadata: metadata,
      severity: 'warning',
    );
  }

  Future<void> reportInfo(
    String message, {
    String context = 'unknown',
    Map<String, dynamic>? metadata,
  }) async {
    await reportError(
      message,
      StackTrace.current,
      context: context,
      metadata: metadata,
      severity: 'info',
    );
  }
}
