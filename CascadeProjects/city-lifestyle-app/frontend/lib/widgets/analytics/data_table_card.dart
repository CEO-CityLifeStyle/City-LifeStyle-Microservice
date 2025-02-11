import 'package:flutter/material.dart';

class DataTableCard extends StatelessWidget {
  final String title;
  final List<dynamic> data;

  const DataTableCard({
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
              rows: _buildRows(),
            ),
          ),
        ],
      ),
    ),
  );

  List<DataColumn> _buildColumns() {
    if (data.isEmpty) return [];
    final firstRow = data.first as Map<String, dynamic>;
    return firstRow.keys.map((key) {
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

  List<DataRow> _buildRows() => data.map((row) {
    final Map<String, dynamic> rowData = row as Map<String, dynamic>;
    return DataRow(
      cells: rowData.values.map((value) {
        return DataCell(Text(value.toString()));
      }).toList(),
    );
  }).toList();
}
