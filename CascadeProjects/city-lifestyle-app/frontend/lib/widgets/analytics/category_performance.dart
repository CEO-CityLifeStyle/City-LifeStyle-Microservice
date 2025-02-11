import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class CategoryPerformance extends StatelessWidget {
  final Map<String, dynamic> data;

  const CategoryPerformance({Key? key, required this.data}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PieChart(
      PieChartData(
        sectionsSpace: 2,
        centerSpaceRadius: 40,
        sections: _createSections(),
        pieTouchData: PieTouchData(
          touchCallback: (FlTouchEvent event, pieTouchResponse) {
            // Handle touch events if needed
          },
        ),
      ),
    );
  }

  List<PieChartSectionData> _createSections() {
    final List<Color> colors = [
      Colors.blue,
      Colors.green,
      Colors.red,
      Colors.purple,
      Colors.orange,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
    ];

    return data.entries.map((entry) {
      final index = data.keys.toList().indexOf(entry.key);
      final color = colors[index % colors.length];

      return PieChartSectionData(
        color: color,
        value: (entry.value['rating'] as num).toDouble(),
        title: '${entry.key}\n${entry.value['rating'].toStringAsFixed(1)}★',
        radius: 100,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }
}
