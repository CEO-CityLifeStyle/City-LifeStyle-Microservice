import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class RecommendationMetricsChart extends StatelessWidget {
  final Map<String, dynamic> data;

  const RecommendationMetricsChart({
    Key? key,
    required this.data,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Performance Over Time',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                _buildLegend(),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: LineChart(
                _createChartData(),
                duration: const Duration(milliseconds: 300),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildLegendItem('CTR', Colors.blue),
        const SizedBox(width: 16),
        _buildLegendItem('Conversion', Colors.green),
        const SizedBox(width: 16),
        _buildLegendItem('Satisfaction', Colors.orange),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(label),
      ],
    );
  }

  LineChartData _createChartData() {
    return LineChartData(
      gridData: const FlGridData(
        show: true,
        drawVerticalLine: true,
        horizontalInterval: 0.2,
        verticalInterval: 1,
      ),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval: 1,
            getTitlesWidget: (value, meta) {
              if (value % 2 == 0) {
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text('Day ${value.toInt()}'),
                );
              }
              return const Text('');
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: 0.2,
            getTitlesWidget: (value, meta) {
              return Text(value.toStringAsFixed(1));
            },
            reservedSize: 42,
          ),
        ),
      ),
      borderData: FlBorderData(
        show: true,
        border: Border.all(color: const Color(0xff37434d), width: 1),
      ),
      minX: 0,
      maxX: 14,
      minY: 0,
      maxY: 1,
      lineBarsData: [
        _createLineChartBarData(
          'ctr',
          Colors.blue,
        ),
        _createLineChartBarData(
          'conversion',
          Colors.green,
        ),
        _createLineChartBarData(
          'satisfaction',
          Colors.orange,
        ),
      ],
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          tooltipBgColor: Colors.blueGrey.shade800,
          getTooltipItems: (touchedSpots) {
            return touchedSpots.map((spot) {
              final metric = spot.barIndex == 0
                  ? 'CTR'
                  : spot.barIndex == 1
                      ? 'Conversion'
                      : 'Satisfaction';
              return LineTooltipItem(
                '$metric: ${(spot.y * 100).toStringAsFixed(1)}%',
                TextStyle(
                  color: spot.bar.color ?? Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              );
            }).toList();
          },
        ),
      ),
    );
  }

  LineChartBarData _createLineChartBarData(String metric, Color color) {
    final metricData = (data[metric] as List? ?? [])
        .asMap()
        .entries
        .map((entry) => FlSpot(
              entry.key.toDouble(),
              entry.value as double,
            ))
        .toList();

    return LineChartBarData(
      spots: metricData,
      isCurved: true,
      color: color,
      barWidth: 3,
      isStrokeCapRound: true,
      dotData: const FlDotData(
        show: false,
      ),
      belowBarData: BarAreaData(
        show: true,
        color: color.withOpacity(0.1),
      ),
    );
  }
}
