import 'package:flutter/material.dart';

class MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final double trend;
  final IconData icon;

  const MetricCard({
    super.key,
    required this.title,
    required this.value,
    required this.trend,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) => Card(
    elevation: 2,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 32, color: Theme.of(context).primaryColor),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          _buildTrendIndicator(context),
        ],
      ),
    ),
  );

  Widget _buildTrendIndicator(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Icon(
        trend >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
        color: trend >= 0 ? Colors.green : Colors.red,
        size: 16,
      ),
      const SizedBox(width: 4),
      Text(
        '${(trend * 100).abs().toStringAsFixed(1)}%',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: trend >= 0 ? Colors.green : Colors.red,
        ),
      ),
    ],
  );
}
