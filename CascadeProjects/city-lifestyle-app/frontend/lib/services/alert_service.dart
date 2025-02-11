import 'dart:async';
import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import '../config/api_config.dart';
import '../utils/http_utils.dart';
import 'error_reporting_service.dart';

class AlertType {
  const AlertType({
    required this.id,
    required this.name,
    required this.description,
    required this.severity,
  });

  factory AlertType.fromJson(Map<String, dynamic> json) => AlertType(
    id: json['id'] as String,
    name: json['name'] as String,
    description: json['description'] as String,
    severity: json['severity'] as String,
  );

  final String id;
  final String name;
  final String description;
  final String severity;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'severity': severity,
  };
}

class Alert {
  const Alert({
    required this.id,
    required this.type,
    required this.message,
    required this.timestamp,
    this.metadata = const {},
  });

  factory Alert.fromJson(Map<String, dynamic> json) => Alert(
    id: json['id'] as String,
    type: AlertType.fromJson(json['type'] as Map<String, dynamic>),
    message: json['message'] as String,
    timestamp: DateTime.parse(json['timestamp'] as String),
    metadata: (json['metadata'] as Map<String, dynamic>?) ?? {},
  );

  final String id;
  final AlertType type;
  final String message;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.toJson(),
    'message': message,
    'timestamp': timestamp.toIso8601String(),
    'metadata': metadata,
  };
}

class AlertService {
  factory AlertService() => _instance;
  AlertService._internal();

  static final AlertService _instance = AlertService._internal();
  final Logger _logger = Logger('AlertService');
  final ErrorReportingService _errorReporting = ErrorReportingService();
  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  final StreamController<Alert> _alertController = StreamController<Alert>.broadcast();

  Stream<Alert> get alertStream => _alertController.stream;

  Future<void> _initializeNotifications() async {
    const initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initializationSettingsIOS = DarwinInitializationSettings();
    const initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _notifications.initialize(initializationSettings);
  }

  Future<List<AlertType>> getAlertTypes() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/alert-types'),
        headers: HttpUtils.getAuthHeaders('GET'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> types = json.decode(response.body) as List<dynamic>;
        return types
            .map((type) => AlertType.fromJson(type as Map<String, dynamic>))
            .toList();
      } else {
        throw HttpException('Failed to fetch alert types: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      _logger.severe('Failed to fetch alert types', e, stackTrace);
      await _errorReporting.reportError(
        e,
        stackTrace,
        context: 'Fetching alert types',
      );
      rethrow;
    }
  }

  Future<List<Alert>> getAlerts({
    DateTime? startDate,
    DateTime? endDate,
    String? typeId,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (startDate != null) {
        queryParams['startDate'] = startDate.toIso8601String();
      }
      if (endDate != null) {
        queryParams['endDate'] = endDate.toIso8601String();
      }
      if (typeId != null) {
        queryParams['typeId'] = typeId;
      }

      final uri = Uri.parse('${ApiConfig.baseUrl}/api/alerts').replace(
        queryParameters: queryParams,
      );

      final response = await http.get(
        uri,
        headers: HttpUtils.getAuthHeaders('GET'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> alerts = json.decode(response.body) as List<dynamic>;
        return alerts
            .map((alert) => Alert.fromJson(alert as Map<String, dynamic>))
            .toList();
      } else {
        throw HttpException('Failed to fetch alerts: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      _logger.severe('Failed to fetch alerts', e, stackTrace);
      await _errorReporting.reportError(
        e,
        stackTrace,
        context: 'Fetching alerts',
        metadata: {
          'startDate': startDate?.toIso8601String(),
          'endDate': endDate?.toIso8601String(),
          'typeId': typeId,
        },
      );
      rethrow;
    }
  }

  Future<void> createAlert({
    required String typeId,
    required String message,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final alertData = {
        'typeId': typeId,
        'message': message,
        'timestamp': DateTime.now().toIso8601String(),
        if (metadata != null) 'metadata': metadata,
      };

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/alerts'),
        headers: HttpUtils.getAuthHeaders('POST'),
        body: json.encode(alertData),
      );

      if (response.statusCode != 201) {
        throw HttpException('Failed to create alert: ${response.statusCode}');
      }

      final createdAlert = Alert.fromJson(
        json.decode(response.body) as Map<String, dynamic>,
      );
      _alertController.add(createdAlert);
      await _showNotification(createdAlert);
    } catch (e, stackTrace) {
      _logger.severe('Failed to create alert', e, stackTrace);
      await _errorReporting.reportError(
        e,
        stackTrace,
        context: 'Creating alert',
        metadata: {
          'typeId': typeId,
          'message': message,
          'metadata': metadata,
        },
      );
      rethrow;
    }
  }

  Future<void> _showNotification(Alert alert) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        'alerts_channel',
        'Alerts',
        channelDescription: 'Notifications for important alerts',
        importance: Importance.high,
        priority: Priority.high,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.show(
        alert.hashCode,
        alert.type.name,
        alert.message,
        details,
      );
    } catch (e, stackTrace) {
      await _errorReporting.reportError(
        e,
        stackTrace,
        context: 'Showing notification',
        metadata: {'alertId': alert.id},
      );
    }
  }

  Future<void> deleteAlert(String alertId) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/api/alerts/$alertId'),
        headers: HttpUtils.getAuthHeaders('DELETE'),
      );

      if (response.statusCode != 204) {
        throw HttpException('Failed to delete alert: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      _logger.severe('Failed to delete alert', e, stackTrace);
      await _errorReporting.reportError(
        e,
        stackTrace,
        context: 'Deleting alert',
        metadata: {'alertId': alertId},
      );
      rethrow;
    }
  }

  void dispose() {
    _alertController.close();
  }
}
