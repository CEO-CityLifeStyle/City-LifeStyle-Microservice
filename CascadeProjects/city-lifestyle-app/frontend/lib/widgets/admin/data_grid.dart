import 'package:flutter/material.dart';
import '../../utils/accessibility_utils.dart';

class DataGrid extends StatefulWidget {
  final List<Map<String, dynamic>> data;
  final List<String> columns;
  final Map<String, List<String>> selectedFilters;
  final Function(String) onSort;
  final Function(Map<String, dynamic>) onRowSelected;

  const DataGrid({
    Key? key,
    required this.data,
    required this.columns,
    required this.selectedFilters,
    required this.onSort,
    required this.onRowSelected,
  }) : super(key: key);

  @override
  State<DataGrid> createState() => _DataGridState();
}

class _DataGridState extends State<DataGrid> {
  String? _sortColumn;
  bool _sortAscending = true;
  int? _selectedRowIndex;
  final ScrollController _horizontalController = ScrollController();
  final ScrollController _verticalController = ScrollController();

  @override
  void dispose() {
    _horizontalController.dispose();
    _verticalController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredData {
    return widget.data.where((row) {
      return widget.selectedFilters.entries.every((filter) {
        final column = filter.key;
        final values = filter.value;
        final cellValue = row[column]?.toString() ?? '';
        return values.isEmpty || values.contains(cellValue);
      });
    }).toList();
  }

  List<Map<String, dynamic>> get _sortedData {
    final data = List<Map<String, dynamic>>.from(_filteredData);
    if (_sortColumn != null) {
      data.sort((a, b) {
        final aValue = a[_sortColumn]?.toString() ?? '';
        final bValue = b[_sortColumn]?.toString() ?? '';
        return _sortAscending
            ? aValue.compareTo(bValue)
            : bValue.compareTo(aValue);
      });
    }
    return data;
  }

  void _handleSort(String column) {
    setState(() {
      if (_sortColumn == column) {
        _sortAscending = !_sortAscending;
      } else {
        _sortColumn = column;
        _sortAscending = true;
      }
    });
    widget.onSort(column);
  }

  @override
  Widget build(BuildContext context) {
    return AccessibilityUtils.wrapForAccessibility(
      label: 'Data Grid',
      child: Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(),
            Expanded(
              child: _buildGrid(),
            ),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Results (${_sortedData.length})',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Row(
            children: [
              if (_sortColumn != null)
                TextButton.icon(
                  icon: const Icon(Icons.clear),
                  label: const Text('Clear Sort'),
                  onPressed: () {
                    setState(() {
                      _sortColumn = null;
                    });
                  },
                  tooltip: 'Clear sorting',
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGrid() {
    return Scrollbar(
      controller: _verticalController,
      child: Scrollbar(
        controller: _horizontalController,
        notificationPredicate: (notification) => notification.depth == 1,
        child: SingleChildScrollView(
          controller: _verticalController,
          child: SingleChildScrollView(
            controller: _horizontalController,
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: _buildColumns(),
              rows: _buildRows(),
              sortColumnIndex: _sortColumn != null
                  ? widget.columns.indexOf(_sortColumn!)
                  : null,
              sortAscending: _sortAscending,
              showCheckboxColumn: false,
              horizontalMargin: 16,
              columnSpacing: 24,
            ),
          ),
        ),
      ),
    );
  }

  List<DataColumn> _buildColumns() {
    return widget.columns.map((column) {
      return DataColumn(
        label: Text(
          column,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        tooltip: 'Sort by $column',
        onSort: (_, __) => _handleSort(column),
      );
    }).toList();
  }

  List<DataRow> _buildRows() {
    return _sortedData.asMap().entries.map((entry) {
      final index = entry.key;
      final row = entry.value;
      return DataRow(
        selected: index == _selectedRowIndex,
        onSelectChanged: (_) {
          setState(() {
            _selectedRowIndex = index == _selectedRowIndex ? null : index;
          });
          widget.onRowSelected(row);
        },
        cells: widget.columns.map((column) {
          return DataCell(
            Text(row[column]?.toString() ?? ''),
            onTap: () {
              setState(() {
                _selectedRowIndex = index == _selectedRowIndex ? null : index;
              });
              widget.onRowSelected(row);
            },
          );
        }).toList(),
      );
    }).toList();
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            'Showing ${_sortedData.length} of ${widget.data.length} items',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
