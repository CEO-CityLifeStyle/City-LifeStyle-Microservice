import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/place.dart';
import '../../providers/auth_provider.dart';
import '../../services/recommendation_service.dart';
import '../../widgets/places/place_card.dart';
import '../../widgets/recommendations/category_recommendations.dart';
import '../../widgets/recommendations/trending_places.dart';

class RecommendationScreen extends StatefulWidget {
  static const routeName = '/recommendations';

  const RecommendationScreen({Key? key}) : super(key: key);

  @override
  State<RecommendationScreen> createState() => _RecommendationScreenState();
}

class _RecommendationScreenState extends State<RecommendationScreen>
    with SingleTickerProviderStateMixin {
  final _recommendationService = RecommendationService();
  late TabController _tabController;
  bool _isLoading = true;
  List<Place> _personalizedRecommendations = [];
  Map<String, List<Place>> _categoryRecommendations = {};
  List<Place> _trendingPlaces = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadRecommendations();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadRecommendations() async {
    setState(() => _isLoading = true);
    try {
      final userId = Provider.of<AuthProvider>(context, listen: false).userId;
      
      final futures = await Future.wait([
        _recommendationService.getHybridRecommendations(userId: userId),
        _recommendationService.getCategoryRecommendations(userId: userId),
        _recommendationService.getTrendingPlaces(),
      ]);

      setState(() {
        _personalizedRecommendations = futures[0] as List<Place>;
        _categoryRecommendations = futures[1] as Map<String, List<Place>>;
        _trendingPlaces = futures[2] as List<Place>;
        _isLoading = false;
      });
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading recommendations: $error')),
      );
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('For You'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Recommended'),
            Tab(text: 'Categories'),
            Tab(text: 'Trending'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadRecommendations,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildPersonalizedRecommendations(),
                  CategoryRecommendations(
                    recommendations: _categoryRecommendations,
                  ),
                  TrendingPlaces(places: _trendingPlaces),
                ],
              ),
            ),
    );
  }

  Widget _buildPersonalizedRecommendations() {
    if (_personalizedRecommendations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.recommend,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No recommendations yet',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Rate more places to get personalized recommendations',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _personalizedRecommendations.length,
      itemBuilder: (context, index) {
        final place = _personalizedRecommendations[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: PlaceCard(place: place),
        );
      },
    );
  }
}
