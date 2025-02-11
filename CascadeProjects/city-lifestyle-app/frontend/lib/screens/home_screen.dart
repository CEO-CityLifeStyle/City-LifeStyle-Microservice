import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/place_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/place_card.dart';
import '../widgets/category_filter.dart';
import '../widgets/search_bar.dart';
import '../models/place.dart';
import '../utils/logger.dart';
import '../utils/firebase_test.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? selectedCategory;
  String searchQuery = '';
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadPlaces();
  }

  Future<void> _loadPlaces() async {
    final placeProvider = Provider.of<PlaceProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    setState(() => isLoading = true);

    try {
      await placeProvider.fetchPlaces(
        headers: {'Authorization': 'Bearer ${authProvider.token}'},
        category: selectedCategory,
        search: searchQuery.isNotEmpty ? searchQuery : null,
      );
    } catch (e) {
      logError('Error loading places: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load places. Please try again.')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _onCategorySelected(String? category) {
    setState(() {
      selectedCategory = category;
    });
    _loadPlaces();
  }

  void _onSearchSubmitted(String query) {
    setState(() {
      searchQuery = query;
    });
    _loadPlaces();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('City Lifestyle'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => Navigator.pushNamed(context, '/profile'),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                CustomSearchBar(
                  onSubmitted: _onSearchSubmitted,
                  hint: 'Search places...',
                ),
                const SizedBox(height: 16),
                CategoryFilter(
                  selectedCategory: selectedCategory,
                  onCategorySelected: _onCategorySelected,
                ),
              ],
            ),
          ),
          Expanded(
            child: Consumer<PlaceProvider>(
              builder: (context, placeProvider, child) {
                if (isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (placeProvider.places.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.location_city, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text(
                          'No places found',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        if (searchQuery.isNotEmpty || selectedCategory != null)
                          TextButton(
                            onPressed: () {
                              setState(() {
                                searchQuery = '';
                                selectedCategory = null;
                              });
                              _loadPlaces();
                            },
                            child: const Text('Clear filters'),
                          ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: _loadPlaces,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: placeProvider.places.length,
                    itemBuilder: (context, index) {
                      final place = placeProvider.places[index];
                      return PlaceCard(
                        place: place,
                        onTap: () => Navigator.pushNamed(
                          context,
                          '/place-details',
                          arguments: place.id,
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
          const FirebaseTestWidget(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/add-place'),
        child: const Icon(Icons.add),
        tooltip: 'Add new place',
      ),
    );
  }
}
