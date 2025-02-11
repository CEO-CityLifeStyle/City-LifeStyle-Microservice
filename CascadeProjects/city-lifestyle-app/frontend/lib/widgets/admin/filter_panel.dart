import 'package:flutter/material.dart';
import '../../utils/accessibility_utils.dart';

class FilterPanel extends StatefulWidget {
  final Map<String, List<String>> filterOptions;
  final Map<String, List<String>> selectedFilters;
  final Function(Map<String, List<String>>) onFiltersChanged;
  final VoidCallback onClose;

  const FilterPanel({
    Key? key,
    required this.filterOptions,
    required this.selectedFilters,
    required this.onFiltersChanged,
    required this.onClose,
  }) : super(key: key);

  @override
  State<FilterPanel> createState() => _FilterPanelState();
}

class _FilterPanelState extends State<FilterPanel> {
  late Map<String, List<String>> _selectedFilters;
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selectedFilters = Map.from(widget.selectedFilters);
  }

  @override
  void dispose() {
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _toggleFilter(String category, String value) {
    setState(() {
      if (!_selectedFilters.containsKey(category)) {
        _selectedFilters[category] = [];
      }

      if (_selectedFilters[category]!.contains(value)) {
        _selectedFilters[category]!.remove(value);
        if (_selectedFilters[category]!.isEmpty) {
          _selectedFilters.remove(category);
        }
      } else {
        _selectedFilters[category]!.add(value);
      }
    });
    widget.onFiltersChanged(_selectedFilters);
  }

  void _clearFilters() {
    setState(() {
      _selectedFilters.clear();
      _searchQuery = '';
    });
    widget.onFiltersChanged(_selectedFilters);
  }

  bool _matchesSearch(String text) {
    if (_searchQuery.isEmpty) return true;
    return text.toLowerCase().contains(_searchQuery.toLowerCase());
  }

  @override
  Widget build(BuildContext context) {
    return AccessibilityUtils.wrapForAccessibility(
      label: 'Filter Panel',
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 16),
              _buildSearchBar(),
              const SizedBox(height: 16),
              Expanded(
                child: _buildFilterList(),
              ),
              const SizedBox(height: 16),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Filters',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: widget.onClose,
          tooltip: 'Close Filters (Esc)',
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      focusNode: _searchFocusNode,
      decoration: InputDecoration(
        hintText: 'Search filters...',
        prefixIcon: const Icon(Icons.search),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
      onChanged: (value) {
        setState(() {
          _searchQuery = value;
        });
      },
    );
  }

  Widget _buildFilterList() {
    return ListView.builder(
      itemCount: widget.filterOptions.length,
      itemBuilder: (context, index) {
        final category = widget.filterOptions.keys.elementAt(index);
        final values = widget.filterOptions[category]!;
        final filteredValues = values.where((v) => _matchesSearch(v)).toList();

        if (filteredValues.isEmpty) return const SizedBox.shrink();

        return ExpansionTile(
          title: Text(category),
          initiallyExpanded: _selectedFilters.containsKey(category),
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: filteredValues.map((value) {
                final isSelected = _selectedFilters[category]?.contains(value) ?? false;
                return FilterChip(
                  label: Text(value),
                  selected: isSelected,
                  onSelected: (selected) => _toggleFilter(category, value),
                  tooltip: 'Toggle $value filter',
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }

  Widget _buildFooter() {
    final hasFilters = _selectedFilters.isNotEmpty;
    final filterCount = _selectedFilters.values
        .fold(0, (sum, list) => sum + list.length);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (hasFilters) ...[
          Text(
            '$filterCount filter${filterCount == 1 ? '' : 's'} selected',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          TextButton.icon(
            icon: const Icon(Icons.clear_all),
            label: const Text('Clear All'),
            onPressed: _clearFilters,
            tooltip: 'Clear all filters',
          ),
        ],
      ],
    );
  }
}
