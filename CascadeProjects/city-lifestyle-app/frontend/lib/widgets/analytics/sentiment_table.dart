import 'package:flutter/material.dart';

class SentimentTable extends StatelessWidget {
  final String title;
  final List<Map<String, dynamic>> data;

  const SentimentTable({
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
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: _buildColumns(),
              rows: _buildRows(context),
            ),
          ),
        ],
      ),
    ),
  );

  List<DataColumn> _buildColumns() {
    if (data.isEmpty) return [];
    return data.first.keys.map((key) {
      return DataColumn(
        label: Text(
          key.split('_').map((word) => 
            word[0].toUpperCase() + word.substring(1)
          ).join(' '),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      );
    }).toList();
  }

  List<DataRow> _buildRows(BuildContext context) => data.map((row) {
    return DataRow(
      cells: row.entries.map((entry) {
        final value = entry.value;
        if (entry.key.toLowerCase().contains('sentiment')) {
          return DataCell(
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: _getSentimentColor(value.toString()).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                value.toString(),
                style: TextStyle(
                  color: _getSentimentColor(value.toString()),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        }
        return DataCell(Text(value.toString()));
      }).toList(),
    );
  }).toList();

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
