import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class ABTestResultsCard extends StatelessWidget {
  final String testId;
  final Map<String, dynamic> metrics;

  const ABTestResultsCard({
    Key? key,
    required this.testId,
    required this.metrics,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final variants = Map<String, dynamic>.from(metrics['variants'] ?? {});
    if (variants.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(
            child: Text('No test data available'),
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Test ID: $testId',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _buildConversionChart(variants),
            const SizedBox(height: 16),
            _buildVariantsList(variants),
          ],
        ),
      ),
    );
  }

  Widget _buildConversionChart(Map<String, dynamic> variants) {
    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: _getMaxConversionRate(variants) * 1.2,
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final variants = metrics['variants'] as Map<String, dynamic>;
                  final keys = variants.keys.toList();
                  if (value >= 0 && value < keys.length) {
                    return Text(
                      'Variant ${keys[value.toInt()]}',
                      style: const TextStyle(fontSize: 10),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  return Text(
                    '${(value * 100).toInt()}%',
                    style: const TextStyle(fontSize: 10),
                  );
                },
              ),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barGroups: _createBarGroups(variants),
        ),
      ),
    );
  }

  List<BarChartGroupData> _createBarGroups(Map<String, dynamic> variants) {
    return variants.entries.map((entry) {
      final index = variants.keys.toList().indexOf(entry.key);
      final variant = entry.value as Map<String, dynamic>;
      final conversionRate = variant['conversions'] / variant['impressions'];

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: conversionRate,
            color: _getVariantColor(index),
            width: 20,
            borderRadius: const BorderRadius.only(
              top: Radius.circular(4),
            ),
          ),
        ],
      );
    }).toList();
  }

  Widget _buildVariantsList(Map<String, dynamic> variants) {
    return Column(
      children: variants.entries.map((entry) {
        final variant = entry.value as Map<String, dynamic>;
        final conversionRate = variant['conversions'] / variant['impressions'] * 100;
        final index = variants.keys.toList().indexOf(entry.key);

        return ListTile(
          leading: Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: _getVariantColor(index),
              shape: BoxShape.circle,
            ),
          ),
          title: Text('Variant ${entry.key}'),
          subtitle: Text(
            'Impressions: ${variant['impressions']}, '
            'Conversions: ${variant['conversions']}',
          ),
          trailing: Text(
            '${conversionRate.toStringAsFixed(1)}%',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        );
      }).toList(),
    );
  }

  double _getMaxConversionRate(Map<String, dynamic> variants) {
    double maxRate = 0;
    for (final variant in variants.values) {
      final rate = variant['conversions'] / variant['impressions'];
      if (rate > maxRate) maxRate = rate;
    }
    return maxRate;
  }

  Color _getVariantColor(int index) {
    const colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
    ];
    return colors[index % colors.length];
  }
}
