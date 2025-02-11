import 'package:flutter/material.dart';

class MetricItem {
  final String label;
  final String value;
  final double trend;

  const MetricItem({
    required this.label,
    required this.value,
    required this.trend,
  });
}

class PerformanceMetricsCard extends StatelessWidget {
  final String title;
  final List<MetricItem> metrics;

  const PerformanceMetricsCard({
    Key? key,
    required this.title,
    required this.metrics,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ...metrics.map((metric) => _buildMetricItem(context, metric)),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricItem(BuildContext context, MetricItem metric) {
    final isPositive = metric.trend >= 0;
    final trendColor = isPositive ? Colors.green : Colors.red;
    final trendIcon = isPositive ? Icons.arrow_upward : Icons.arrow_downward;
    final trendPercentage = (metric.trend * 100).abs().toStringAsFixed(1);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            metric.label,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          Row(
            children: [
              Text(
                metric.value,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: trendColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      trendIcon,
                      color: trendColor,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$trendPercentage%',
                      style: TextStyle(
                        color: trendColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
