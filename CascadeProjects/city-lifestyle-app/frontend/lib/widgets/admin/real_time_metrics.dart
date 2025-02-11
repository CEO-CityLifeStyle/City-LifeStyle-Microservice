import 'dart:async';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:convert';
import 'package:frontend/utils/logger.dart';  
import '../../config/api_config.dart';
import 'package:logging/logging.dart';

class RealTimeMetrics extends StatefulWidget {
  const RealTimeMetrics({Key? key}) : super(key: key);

  @override
  State<RealTimeMetrics> createState() => _RealTimeMetricsState();
}

class _RealTimeMetricsState extends State<RealTimeMetrics> {
  late WebSocketChannel _channel;
  final _metrics = <String, List<MetricPoint>>{};
  final _maxDataPoints = 50;
  Timer? _reconnectTimer;
  bool _isConnected = false;
  final _logger = getLogger('RealTimeMetrics');  

  @override
  void initState() {
    super.initState();
    _connectToWebSocket();
  }

  void _connectToWebSocket() {
    try {
      _channel = WebSocketChannel.connect(
        Uri.parse('${ApiConfig.wsUrl}/metrics'),
      );
      _channel.stream.listen(
        _handleMetricUpdate,
        onError: _handleConnectionError,
        onDone: _handleConnectionClosed,
      );
      setState(() => _isConnected = true);
    } catch (e) {
      _logger.severe('WebSocket connection error: $e');
      _scheduleReconnect();
    }
  }

  void _handleMetricUpdate(dynamic message) {
    final data = json.decode(message as String);
    setState(() {
      for (final entry in data.entries) {
        final metricName = entry.key as String;
        final value = entry.value as num;
        final timestamp = DateTime.now();

        _metrics.putIfAbsent(metricName, () => []);
        _metrics[metricName]!.add(MetricPoint(timestamp, value.toDouble()));

        // Keep only the last N data points
        if (_metrics[metricName]!.length > _maxDataPoints) {
          _metrics[metricName]!.removeAt(0);
        }
      }
    });
  }

  void _handleConnectionError(error) {
    _logger.severe('WebSocket error: $error');
    setState(() => _isConnected = false);
    _scheduleReconnect();
  }

  void _handleConnectionClosed() {
    setState(() => _isConnected = false);
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 5), _connectToWebSocket);
  }

  @override
  void dispose() {
    _logger.fine('Disposing RealTimeMetrics widget');
    _channel.sink.close();
    _reconnectTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          color: _isConnected ? Colors.green[100] : Colors.red[100],
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _isConnected ? Icons.cloud_done : Icons.cloud_off,
                color: _isConnected ? Colors.green : Colors.red,
              ),
              const SizedBox(width: 8),
              Text(
                _isConnected
                    ? 'Connected to metrics stream'
                    : 'Disconnected - Attempting to reconnect...',
                style: TextStyle(
                  color: _isConnected ? Colors.green : Colors.red,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _metrics.isEmpty
              ? const Center(
                  child: Text('Waiting for metrics data...'),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _metrics.length,
                  itemBuilder: (context, index) {
                    final metricName = _metrics.keys.elementAt(index);
                    final metricData = _metrics[metricName]!;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              metricName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              height: 200,
                              child: _buildMetricChart(metricData),
                            ),
                            const SizedBox(height: 8),
                            _buildMetricStats(metricData),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildMetricChart(List<MetricPoint> data) {
    // Implement real-time chart using fl_chart
    return const Placeholder();
  }

  Widget _buildMetricStats(List<MetricPoint> data) {
    if (data.isEmpty) return const SizedBox();

    final current = data.last.value;
    final previous = data.length > 1 ? data[data.length - 2].value : current;
    final change = ((current - previous) / previous * 100).toStringAsFixed(1);
    final trend = current > previous ? '↑' : '↓';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('Current: ${current.toStringAsFixed(2)}'),
        Text(
          'Change: $change% $trend',
          style: TextStyle(
            color: current > previous ? Colors.green : Colors.red,
          ),
        ),
      ],
    );
  }
}

class MetricPoint {
  final DateTime timestamp;
  final double value;

  MetricPoint(this.timestamp, this.value);
}
