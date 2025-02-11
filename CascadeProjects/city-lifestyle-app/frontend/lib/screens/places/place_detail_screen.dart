import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/place_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/place.dart';
import '../../services/recommendation_service.dart';
import '../../widgets/place_card.dart';

class PlaceDetailScreen extends StatefulWidget {
  final String placeId;

  const PlaceDetailScreen({super.key, required this.placeId});

  @override
  State<PlaceDetailScreen> createState() => _PlaceDetailScreenState();
}

class _PlaceDetailScreenState extends State<PlaceDetailScreen> {
  final _reviewController = TextEditingController();
  double _rating = 5.0;
  final _recommendationService = RecommendationService();
  final List<Place> _similarPlaces = [];
  bool _isLoading = false;
  final _reviewFormKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _loadPlaceDetails();
  }

  Future<void> _loadPlaceDetails() async {
    setState(() => _isLoading = true);
    try {
      await Provider.of<PlaceProvider>(context, listen: false)
          .loadPlaceDetails(widget.placeId);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading place details: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _submitReview() async {
    if (!_reviewFormKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final review = Review(
        id: '',
        userId: Provider.of<AuthProvider>(context, listen: false).currentUser?.id ?? '',
        rating: _rating,
        comment: _reviewController.text,
        createdAt: DateTime.now(),
      );

      await Provider.of<PlaceProvider>(context, listen: false)
          .createReview(widget.placeId, review);

      if (!mounted) return;
      Navigator.of(context).pop();
      _loadPlaceDetails();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error submitting review: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showReviewDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Write a Review'),
        content: Form(
          key: _reviewFormKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Slider(
                value: _rating,
                min: 1,
                max: 5,
                divisions: 4,
                label: _rating.toString(),
                onChanged: (value) {
                  setState(() => _rating = value);
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _reviewController,
                decoration: const InputDecoration(
                  labelText: 'Your Review',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your review';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: _submitReview,
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  Future<void> _launchUrl(String url, String errorMessage) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        throw Exception('Could not launch $url');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    }
  }

  Future<void> _launchPhone(String phone) async {
    await _launchUrl('tel:$phone', 'Could not launch phone call');
  }

  Future<void> _launchEmail(String email) async {
    await _launchUrl('mailto:$email', 'Could not launch email');
  }

  Future<void> _launchWebsite(String website) async {
    await _launchUrl(website, 'Could not launch website');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<PlaceProvider>(
        builder: (context, placeProvider, child) {
          if (placeProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (placeProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(placeProvider.error!),
                  ElevatedButton(
                    onPressed: _loadPlaceDetails,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final place = placeProvider.selectedPlace;
          if (place == null) {
            return const Center(child: Text('Place not found'));
          }

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 300,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(place.name),
                  background: place.images.isNotEmpty
                      ? Image.network(
                          place.images.first,
                          fit: BoxFit.cover,
                        )
                      : Container(color: Colors.grey),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.star,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${place.rating.toStringAsFixed(1)} (${place.reviews.length} reviews)',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        place.description,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Location',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              place.location.address,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                      if (place.contact.phone != null ||
                          place.contact.email != null ||
                          place.contact.website != null) ...[
                        const SizedBox(height: 24),
                        Text(
                          'Contact',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        if (place.contact.phone != null)
                          ListTile(
                            leading: const Icon(Icons.phone),
                            title: Text(place.contact.phone!),
                            onTap: () => _launchPhone(place.contact.phone!),
                          ),
                        if (place.contact.email != null)
                          ListTile(
                            leading: const Icon(Icons.email),
                            title: Text(place.contact.email!),
                            onTap: () => _launchEmail(place.contact.email!),
                          ),
                        if (place.contact.website != null)
                          ListTile(
                            leading: const Icon(Icons.language),
                            title: Text(place.contact.website!),
                            onTap: () => _launchWebsite(place.contact.website!),
                          ),
                      ],
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Reviews',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          TextButton.icon(
                            onPressed: _showReviewDialog,
                            icon: const Icon(Icons.rate_review),
                            label: const Text('Add Review'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ...place.reviews.map((review) => ReviewCard(review: review)),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }
}

class ReviewCard extends StatelessWidget {
  final Review review;

  const ReviewCard({super.key, required this.review});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  child: Text(review.userName[0].toUpperCase()),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        review.userName,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        review.createdAt.toString().split(' ')[0],
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    Icon(
                      Icons.star,
                      size: 16,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(review.rating.toString()),
                  ],
                ),
              ],
            ),
            if (review.comment.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(review.comment),
            ],
          ],
        ),
      ),
    );
  }
}
