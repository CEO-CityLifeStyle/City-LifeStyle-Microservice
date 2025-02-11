import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class SentimentChart extends StatelessWidget {
  final String title;
  final Map<String, dynamic> data;

  const SentimentChart({
    super.key,
    required this.title,
    required this.data,
  });

  @override
  Widget build(BuildContext context) => Card(
    elevation: 2,
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
          SizedBox(
            height: 300,
            child: _buildPieChart(),
          ),
          const SizedBox(height: 16),
          _buildLegend(context),
        ],
      ),
    ),
  );

  Widget _buildPieChart() => PieChart(
    PieChartData(
      sections: data.entries.map((entry) {
        final color = _getSentimentColor(entry.key);
        return PieChartSectionData(
          value: (entry.value as num).toDouble(),
          title: '${((entry.value as num) * 100).toStringAsFixed(1)}%',
          color: color,
          radius: 100,
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        );
      }).toList(),
      sectionsSpace: 2,
      centerSpaceRadius: 0,
    ),
  );

  Widget _buildLegend(BuildContext context) => Wrap(
    spacing: 16,
    runSpacing: 8,
    children: data.keys.map((key) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: _getSentimentColor(key),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            key.split('_').map((word) => 
              word[0].toUpperCase() + word.substring(1)
            ).join(' '),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      );
    }).toList(),
  );

  Color _getSentimentColor(String sentiment) {
    switch (sentiment.toLowerCase()) {
      case 'positive':
        return Colors.green;
      case 'negative':
        return Colors.red;
      case 'neutral':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}
