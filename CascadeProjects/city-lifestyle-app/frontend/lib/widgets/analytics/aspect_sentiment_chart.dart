import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class AspectSentimentChart extends StatelessWidget {
  final Map<String, dynamic> data;

  const AspectSentimentChart({Key? key, required this.data}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: 1.0,
        minY: -1.0,
        groupsSpace: 12,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            tooltipBgColor: Colors.blueGrey,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final aspect = data.keys.elementAt(group.x.toInt());
              final score = data[aspect]['score'].toStringAsFixed(2);
              final sentiment = _getSentimentLabel(data[aspect]['score']);
              return BarTooltipItem(
                '$aspect\nScore: $score\n$sentiment',
                const TextStyle(color: Colors.white),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= 0 && value.toInt() < data.length) {
                  final aspect = data.keys.elementAt(value.toInt());
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      aspect,
                      style: const TextStyle(fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  );
                }
                return const Text('');
              },
              reservedSize: 40,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(value.toStringAsFixed(1));
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
        gridData: const FlGridData(
          show: true,
          horizontalInterval: 0.2,
        ),
        borderData: FlBorderData(show: false),
        barGroups: _createBarGroups(),
      ),
    );
  }

  List<BarChartGroupData> _createBarGroups() {
    return List.generate(data.length, (index) {
      final aspect = data.keys.elementAt(index);
      final score = (data[aspect]['score'] as num).toDouble();
      
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: score,
            color: _getScoreColor(score),
            width: 20,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(4),
              bottom: Radius.circular(4),
            ),
          ),
        ],
      );
    });
  }

  Color _getScoreColor(double score) {
    if (score >= 0.6) return Colors.green;
    if (score >= 0.2) return Colors.lightGreen;
    if (score >= -0.2) return Colors.blue;
    if (score >= -0.6) return Colors.orange;
    return Colors.red;
  }

  String _getSentimentLabel(double score) {
    if (score >= 0.6) return 'Very Positive';
    if (score >= 0.2) return 'Positive';
    if (score >= -0.2) return 'Neutral';
    if (score >= -0.6) return 'Negative';
    return 'Very Negative';
  }
}
