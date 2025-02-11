import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/search_filters.dart';
import '../providers/search_provider.dart';
import '../widgets/search/filter_section.dart';
import '../widgets/search/map_view.dart';
import '../widgets/search/search_results.dart';

class AdvancedSearchScreen extends StatefulWidget {
  const AdvancedSearchScreen({super.key});

  @override
  State<AdvancedSearchScreen> createState() => _AdvancedSearchScreenState();
}

class _AdvancedSearchScreenState extends State<AdvancedSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _showMap = false;
  SearchFilters _filters = SearchFilters();

  @override
  void initState() {
    super.initState();
    _initializeSearch();
  }

  Future<void> _initializeSearch() async {
    await Provider.of<SearchProvider>(context, listen: false).initializeFilters();
  }

  Widget _buildSearchBar() => Container(
        padding: const EdgeInsets.all(16),
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search places...',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _searchController.clear();
                Provider.of<SearchProvider>(context, listen: false).clearSearch();
              },
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onChanged: (value) {
            Provider.of<SearchProvider>(context, listen: false)
                .updateSearchQuery(value);
          },
        ),
      );

  Widget _buildFilterSection() => Consumer<SearchProvider>(
        builder: (context, searchProvider, child) => FilterSection(
          categories: searchProvider.categories ?? [],
          priceRanges: searchProvider.priceRanges ?? [],
          ratings: searchProvider.ratings ?? [],
          onFilterChanged: (filters) {
            setState(() {
              _filters = filters;
            });
            searchProvider.updateFilters(filters);
          },
          currentFilters: _filters,
        ),
      );

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Advanced Search'),
          actions: [
            IconButton(
              icon: Icon(_showMap ? Icons.list : Icons.map),
              onPressed: () {
                setState(() {
                  _showMap = !_showMap;
                });
              },
            ),
          ],
        ),
        body: Column(
          children: [
            _buildSearchBar(),
            _buildFilterSection(),
            Expanded(
              child: _showMap ? const MapView() : const SearchResults(),
            ),
          ],
        ),
      );

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
