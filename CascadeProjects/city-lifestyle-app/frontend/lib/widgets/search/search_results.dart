import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/search_provider.dart';
import '../../models/place.dart';
import '../common/place_card.dart';
import '../common/loading_indicator.dart';

class SearchResults extends StatefulWidget {
  @override
  _SearchResultsState createState() => _SearchResultsState();
}

class _SearchResultsState extends State<SearchResults> {
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      _loadMoreResults();
    }
  }

  Future<void> _loadMoreResults() async {
    if (!_isLoadingMore) {
      setState(() {
        _isLoadingMore = true;
      });

      await Provider.of<SearchProvider>(context, listen: false).loadMoreResults();

      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SearchProvider>(
      builder: (context, searchProvider, child) {
        if (searchProvider.isLoading && searchProvider.searchResults.isEmpty) {
          return Center(child: LoadingIndicator());
        }

        if (searchProvider.searchResults.isEmpty) {
          return _buildEmptyState();
        }

        return RefreshIndicator(
          onRefresh: () => searchProvider.refreshSearch(),
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              SliverPadding(
                padding: EdgeInsets.all(16),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: _calculateCrossAxisCount(context),
                    childAspectRatio: 0.8,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (index < searchProvider.searchResults.length) {
                        return _buildPlaceCard(
                          searchProvider.searchResults[index],
                        );
                      } else if (searchProvider.hasMoreResults) {
                        return Center(child: CircularProgressIndicator());
                      }
                      return null;
                    },
                    childCount: searchProvider.hasMoreResults
                        ? searchProvider.searchResults.length + 1
                        : searchProvider.searchResults.length,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPlaceCard(Place place) {
    return PlaceCard(
      place: place,
      onTap: () {
        Provider.of<SearchProvider>(context, listen: false).selectPlace(place);
        Navigator.pushNamed(
          context,
          '/place-details',
          arguments: place,
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            'No places found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Try adjusting your search or filters',
            style: TextStyle(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  int _calculateCrossAxisCount(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    if (width > 1200) {
      return 4;
    } else if (width > 800) {
      return 3;
    } else if (width > 600) {
      return 2;
    }
    return 1;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
