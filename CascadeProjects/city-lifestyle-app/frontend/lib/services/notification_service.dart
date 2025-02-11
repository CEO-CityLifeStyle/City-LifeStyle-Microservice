import 'dart:async';
import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:logging/logging.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../config/api_config.dart';
import '../utils/http_utils.dart';
import 'error_reporting_service.dart';

class NotificationData {
  final String id;
  final String title;
  final String body;
  final Map<String, dynamic>? payload;
  final DateTime? scheduledDate;

  const NotificationData({
    required this.id,
    required this.title,
    required this.body,
    this.payload,
    this.scheduledDate,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'body': body,
    'payload': payload,
    'scheduledDate': scheduledDate?.toIso8601String(),
  };

  factory NotificationData.fromJson(Map<String, dynamic> json) {
    return NotificationData(
      id: json['id'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      payload: json['payload'] as Map<String, dynamic>?,
      scheduledDate: json['scheduledDate'] != null 
          ? DateTime.parse(json['scheduledDate'] as String)
          : null,
    );
  }
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  final ApiConfig _apiConfig;
  final ErrorReportingService _errorReporting;
  final Logger _logger = Logger('NotificationService');
  final StreamController<NotificationData> _notificationController = StreamController<NotificationData>.broadcast();

  Stream<NotificationData> get notificationStream => _notificationController.stream;

  NotificationService._internal()
      : _apiConfig = ApiConfig(),
        _errorReporting = ErrorReportingService() {
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      tz.initializeTimeZones();

      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      await _requestPermissions();
      _logger.info('Notification service initialized successfully');
    } catch (e, stackTrace) {
      await _errorReporting.reportError(
        e,
        stackTrace,
        context: 'Initializing notification service',
      );
    }
  }

  Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
    int? badgeNumber,
  }) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        'default_channel',
        'Default Channel',
        channelDescription: 'Default notification channel',
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

      final id = DateTime.now().millisecondsSinceEpoch % 2147483647;
      await _notifications.show(
        id,
        title,
        body,
        details,
        payload: payload,
      );

      final notification = NotificationData(
        id: id.toString(),
        title: title,
        body: body,
        payload: payload != null ? json.decode(payload) as Map<String, dynamic> : null,
      );

      _notificationController.add(notification);
      await _logNotification(notification);
    } catch (e, stackTrace) {
      await _errorReporting.reportError(
        e,
        stackTrace,
        context: 'Showing notification',
        metadata: {
          'title': title,
          'body': body,
        },
      );
    }
  }

  Future<void> scheduleNotification({
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        'scheduled_channel',
        'Scheduled Channel',
        channelDescription: 'Channel for scheduled notifications',
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

      final id = DateTime.now().millisecondsSinceEpoch % 2147483647;
      await _notifications.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(scheduledDate, tz.local),
        details,
        androidAllowWhileIdle: true,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
      );

      final notification = NotificationData(
        id: id.toString(),
        title: title,
        body: body,
        payload: payload != null ? json.decode(payload) as Map<String, dynamic> : null,
        scheduledDate: scheduledDate,
      );

      await _logNotification(notification);
    } catch (e, stackTrace) {
      await _errorReporting.reportError(
        e,
        stackTrace,
        context: 'Scheduling notification',
        metadata: {
          'title': title,
          'body': body,
          'scheduledDate': scheduledDate.toIso8601String(),
        },
      );
    }
  }

  Future<void> cancelNotification(String id) async {
    try {
      await _notifications.cancel(int.parse(id));
      _logger.info('Cancelled notification: $id');
    } catch (e, stackTrace) {
      await _errorReporting.reportError(
        e,
        stackTrace,
        context: 'Cancelling notification',
        metadata: {'id': id},
      );
    }
  }

  Future<void> cancelAllNotifications() async {
    try {
      await _notifications.cancelAll();
      _logger.info('Cancelled all notifications');
    } catch (e, stackTrace) {
      await _errorReporting.reportError(
        e,
        stackTrace,
        context: 'Cancelling all notifications',
      );
    }
  }

  Future<void> _requestPermissions() async {
    try {
      if (await _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>() != null) {
        await _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()!
            .requestPermission();
      }

      if (await _notifications.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>() != null) {
        await _notifications.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()!
            .requestPermissions(
              alert: true,
              badge: true,
              sound: true,
            );
      }
    } catch (e, stackTrace) {
      await _errorReporting.reportError(
        e,
        stackTrace,
        context: 'Requesting notification permissions',
      );
    }
  }

  void _onNotificationTapped(NotificationResponse response) {
    try {
      if (response.payload != null) {
        final payload = json.decode(response.payload!) as Map<String, dynamic>;
        final notification = NotificationData(
          id: response.id.toString(),
          title: response.notification?.title ?? '',
          body: response.notification?.body ?? '',
          payload: payload,
        );
        _notificationController.add(notification);
      }
    } catch (e, stackTrace) {
      _errorReporting.reportError(
        e,
        stackTrace,
        context: 'Processing notification tap',
        metadata: {'payload': response.payload},
      );
    }
  }

  Future<void> _logNotification(NotificationData notification) async {
    try {
      await http.post(
        Uri.parse('${_apiConfig.baseUrl}/api/notifications/log'),
        headers: {
          'Content-Type': 'application/json',
          ...await HttpUtils.getAuthHeaders(),
        },
        body: json.encode(notification.toJson()),
      );
    } catch (e, stackTrace) {
      await _errorReporting.reportError(
        e,
        stackTrace,
        context: 'Logging notification',
        metadata: {'notification': notification.toJson()},
      );
    }
  }

  void dispose() {
    _notificationController.close();
  }
}
