import 'dart:async';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import '../config/api_config.dart';
import '../models/dashboard/performance_metrics.dart';
import '../models/dashboard/ab_test_result.dart';
import '../models/dashboard/recommendation_metrics.dart';
import 'secure_storage_service.dart';

class RealtimeService {
  static final RealtimeService _instance = RealtimeService._internal();
  factory RealtimeService() => _instance;

  WebSocketChannel? _channel;
  StreamController<dynamic>? _streamController;
  Timer? _heartbeatTimer;
  Timer? _reconnectTimer;
  bool _isConnected = false;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;
  static const Duration _reconnectDelay = Duration(seconds: 5);
  static const Duration _heartbeatInterval = Duration(seconds: 30);

  final _topicSubscriptions = <String, StreamController<dynamic>>{};

  RealtimeService._internal();

  Future<void> connect() async {
    if (_isConnected) return;

    try {
      final token = await SecureStorageService.getAuthToken();
      if (token == null) throw Exception('No auth token available');

      final wsUrl = Uri.parse(ApiConfig.websocketUrl)
          .replace(queryParameters: {'token': token});

      _channel = WebSocketChannel.connect(wsUrl);
      _streamController = StreamController<dynamic>.broadcast();

      _channel!.stream.listen(
        _handleMessage,
        onError: _handleError,
        onDone: _handleDisconnect,
        cancelOnError: false,
      );

      _startHeartbeat();
      _isConnected = true;
      _reconnectAttempts = 0;
    } catch (e) {
      _handleError(e);
    }
  }

  void _handleMessage(dynamic message) {
    if (message == 'pong') return; // Heartbeat response

    try {
      final data = message as Map<String, dynamic>;
      final topic = data['topic'] as String;
      final payload = data['payload'];

      if (_topicSubscriptions.containsKey(topic)) {
        _topicSubscriptions[topic]!.add(payload);
      }

      _streamController?.add(message);
    } catch (e) {
      print('Error handling message: $e');
    }
  }

  void _handleError(dynamic error) {
    print('WebSocket error: $error');
    _handleDisconnect();
  }

  void _handleDisconnect() {
    _isConnected = false;
    _stopHeartbeat();
    _channel?.sink.close(status.goingAway);
    
    if (_reconnectAttempts < _maxReconnectAttempts) {
      _reconnectTimer?.cancel();
      _reconnectTimer = Timer(_reconnectDelay, () {
        _reconnectAttempts++;
        connect();
      });
    }
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(_heartbeatInterval, (timer) {
      if (_isConnected) {
        _channel?.sink.add('ping');
      }
    });
  }

  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  Stream<PerformanceMetrics> subscribeToPerformanceMetrics() {
    const topic = 'dashboard.performance';
    return _subscribeToTopic<PerformanceMetrics>(
      topic,
      (data) => PerformanceMetrics.fromJson(data),
    );
  }

  Stream<List<ABTestResult>> subscribeToABTests() {
    const topic = 'dashboard.abtests';
    return _subscribeToTopic<List<ABTestResult>>(
      topic,
      (data) => (data as List)
          .map((item) => ABTestResult.fromJson(item))
          .toList(),
    );
  }

  Stream<RecommendationMetrics> subscribeToRecommendations() {
    const topic = 'dashboard.recommendations';
    return _subscribeToTopic<RecommendationMetrics>(
      topic,
      (data) => RecommendationMetrics.fromJson(data),
    );
  }

  Stream<T> _subscribeToTopic<T>(
    String topic,
    T Function(dynamic data) converter,
  ) {
    if (!_topicSubscriptions.containsKey(topic)) {
      _topicSubscriptions[topic] = StreamController<dynamic>.broadcast();
      
      if (_isConnected) {
        _channel?.sink.add({
          'action': 'subscribe',
          'topic': topic,
        });
      }
    }

    return _topicSubscriptions[topic]!.stream.map(converter);
  }

  void unsubscribeFromTopic(String topic) {
    if (_topicSubscriptions.containsKey(topic)) {
      if (_isConnected) {
        _channel?.sink.add({
          'action': 'unsubscribe',
          'topic': topic,
        });
      }
      _topicSubscriptions[topic]?.close();
      _topicSubscriptions.remove(topic);
    }
  }

  Future<void> disconnect() async {
    _isConnected = false;
    _stopHeartbeat();
    _reconnectTimer?.cancel();
    
    for (var controller in _topicSubscriptions.values) {
      await controller.close();
    }
    _topicSubscriptions.clear();
    
    await _streamController?.close();
    _streamController = null;
    
    await _channel?.sink.close(status.goingAway);
    _channel = null;
  }

  bool get isConnected => _isConnected;
}
