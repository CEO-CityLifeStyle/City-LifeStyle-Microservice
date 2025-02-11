import 'package:flutter/material.dart';
import '../../models/place.dart';
import '../places/place_card.dart';
import 'recommendation_explanation.dart';

class PersonalizedRecommendationCard extends StatefulWidget {
  final Place place;
  final List<String> recommendationReasons;
  final double matchScore;
  final VoidCallback? onTap;

  const PersonalizedRecommendationCard({
    Key? key,
    required this.place,
    required this.recommendationReasons,
    required this.matchScore,
    this.onTap,
  }) : super(key: key);

  @override
  State<PersonalizedRecommendationCard> createState() =>
      _PersonalizedRecommendationCardState();
}

class _PersonalizedRecommendationCardState
    extends State<PersonalizedRecommendationCard> {
  bool _showExplanation = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          children: [
            PlaceCard(
              place: widget.place,
              onTap: widget.onTap,
            ),
            Positioned(
              top: 8,
              right: 8,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.recommend,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${(widget.matchScore * 100).round()}% Match',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () {
                      setState(() {
                        _showExplanation = !_showExplanation;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _showExplanation
                            ? Icons.close
                            : Icons.info_outline,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (_showExplanation)
          RecommendationExplanation(
            place: widget.place,
            reasons: widget.recommendationReasons,
            similarity: widget.matchScore,
          ),
      ],
    );
  }
}
