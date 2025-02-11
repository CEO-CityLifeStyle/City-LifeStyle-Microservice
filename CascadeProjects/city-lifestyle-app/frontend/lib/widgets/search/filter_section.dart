import 'package:flutter/material.dart';
import '../../models/search_filters.dart';
import '../../utils/constants.dart';

class FilterSection extends StatefulWidget {
  final List<String> categories;
  final List<PriceRange> priceRanges;
  final List<double> ratings;
  final Function(SearchFilters) onFilterChanged;
  final SearchFilters currentFilters;

  FilterSection({
    required this.categories,
    required this.priceRanges,
    required this.ratings,
    required this.onFilterChanged,
    required this.currentFilters,
  });

  @override
  _FilterSectionState createState() => _FilterSectionState();
}

class _FilterSectionState extends State<FilterSection> {
  late SearchFilters _filters;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _filters = widget.currentFilters;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ExpansionTile(
        title: Text('Filters'),
        subtitle: _buildActiveFiltersText(),
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCategoryFilter(),
                SizedBox(height: 16),
                _buildPriceRangeFilter(),
                SizedBox(height: 16),
                _buildRatingFilter(),
                SizedBox(height: 16),
                _buildLocationFilter(),
                SizedBox(height: 16),
                _buildOperatingHoursFilter(),
                SizedBox(height: 16),
                _buildAmenitiesFilter(),
              ],
            ),
          ),
        ],
        onExpansionChanged: (expanded) {
          setState(() {
            _isExpanded = expanded;
          });
        },
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Categories',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: widget.categories.map((category) {
            final isSelected = _filters.categories.contains(category);
            return FilterChip(
              label: Text(category),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _filters.categories.add(category);
                  } else {
                    _filters.categories.remove(category);
                  }
                });
                widget.onFilterChanged(_filters);
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPriceRangeFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Price Range',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: widget.priceRanges.map((range) {
            final isSelected = _filters.priceRange == range;
            return ChoiceChip(
              label: Text(range.label),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _filters.priceRange = selected ? range : null;
                });
                widget.onFilterChanged(_filters);
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildRatingFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Minimum Rating',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        Slider(
          value: _filters.minRating ?? 0,
          min: 0,
          max: 5,
          divisions: 10,
          label: (_filters.minRating ?? 0).toString(),
          onChanged: (value) {
            setState(() {
              _filters.minRating = value;
            });
            widget.onFilterChanged(_filters);
          },
        ),
      ],
    );
  }

  Widget _buildLocationFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Distance',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        Slider(
          value: _filters.radius?.toDouble() ?? 5,
          min: 1,
          max: 50,
          divisions: 49,
          label: '${_filters.radius ?? 5} km',
          onChanged: (value) {
            setState(() {
              _filters.radius = value.round();
            });
            widget.onFilterChanged(_filters);
          },
        ),
      ],
    );
  }

  Widget _buildOperatingHoursFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Operating Hours',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        CheckboxListTile(
          title: Text('Open Now'),
          value: _filters.openNow ?? false,
          onChanged: (value) {
            setState(() {
              _filters.openNow = value;
            });
            widget.onFilterChanged(_filters);
          },
        ),
      ],
    );
  }

  Widget _buildAmenitiesFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Amenities',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: Constants.amenities.map((amenity) {
            final isSelected = _filters.amenities.contains(amenity);
            return FilterChip(
              label: Text(amenity),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _filters.amenities.add(amenity);
                  } else {
                    _filters.amenities.remove(amenity);
                  }
                });
                widget.onFilterChanged(_filters);
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildActiveFiltersText() {
    final List<String> activeFilters = [];

    if (_filters.categories.isNotEmpty) {
      activeFilters.add('${_filters.categories.length} categories');
    }
    if (_filters.priceRange != null) {
      activeFilters.add('Price: ${_filters.priceRange!.label}');
    }
    if (_filters.minRating != null && _filters.minRating! > 0) {
      activeFilters.add('Rating: ${_filters.minRating}+');
    }
    if (_filters.radius != null) {
      activeFilters.add('Within ${_filters.radius}km');
    }
    if (_filters.openNow ?? false) {
      activeFilters.add('Open Now');
    }
    if (_filters.amenities.isNotEmpty) {
      activeFilters.add('${_filters.amenities.length} amenities');
    }

    return Text(
      activeFilters.isEmpty
          ? 'No filters applied'
          : activeFilters.join(' • '),
      style: TextStyle(
        color: Colors.grey[600],
        fontSize: 12,
      ),
    );
  }
}
