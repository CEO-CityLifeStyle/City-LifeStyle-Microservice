import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class ChartCard extends StatelessWidget {
  final String title;
  final dynamic data;

  const ChartCard({
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
            child: data is List ? _buildLineChart() : _buildPieChart(),
          ),
        ],
      ),
    ),
  );

  Widget _buildLineChart() => LineChart(
    LineChartData(
      gridData: const FlGridData(show: false),
      titlesData: const FlTitlesData(show: false),
      borderData: FlBorderData(show: false),
      lineBarsData: [
        LineChartBarData(
          spots: (data as List).asMap().entries.map((entry) {
            return FlSpot(entry.key.toDouble(), (entry.value as num).toDouble());
          }).toList(),
          isCurved: true,
          color: Colors.blue,
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            color: Colors.blue.withOpacity(0.1),
          ),
        ),
      ],
    ),
  );

  Widget _buildPieChart() => PieChart(
    PieChartData(
      sections: (data as Map<String, dynamic>).entries.map((entry) {
        return PieChartSectionData(
          value: (entry.value as num).toDouble(),
          title: entry.key,
          color: Colors.primaries[
            entry.key.hashCode % Colors.primaries.length
          ],
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
}
