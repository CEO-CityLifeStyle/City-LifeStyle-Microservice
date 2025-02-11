import 'dart:math' as math;
import '../../models/place.dart';
import '../../models/review.dart';

class RecommendationAlgorithm {
  // Collaborative Filtering
  static Map<String, Map<String, double>> _calculateUserSimilarities(
    Map<String, Map<String, double>> userRatings,
    String targetUserId,
  ) {
    final similarities = <String, Map<String, double>>{};
    final targetUserRatings = userRatings[targetUserId] ?? {};

    for (final otherUserId in userRatings.keys) {
      if (otherUserId == targetUserId) continue;

      final otherUserRatings = userRatings[otherUserId] ?? {};
      double similarity = 0;
      double normA = 0;
      double normB = 0;

      // Calculate cosine similarity
      for (final placeId in targetUserRatings.keys) {
        if (otherUserRatings.containsKey(placeId)) {
          similarity += targetUserRatings[placeId]! * otherUserRatings[placeId]!;
          normA += targetUserRatings[placeId]! * targetUserRatings[placeId]!;
          normB += otherUserRatings[placeId]! * otherUserRatings[placeId]!;
        }
      }

      if (normA > 0 && normB > 0) {
        similarity = similarity / (math.sqrt(normA) * math.sqrt(normB));
        similarities[otherUserId] = {
          'similarity': similarity,
          'count': otherUserRatings.length.toDouble(),
        };
      }
    }

    return similarities;
  }

  static List<Place> getCollaborativeRecommendations({
    required Map<String, Map<String, double>> userRatings,
    required String userId,
    required List<Place> allPlaces,
    int limit = 10,
  }) {
    final similarities = _calculateUserSimilarities(userRatings, userId);
    final predictions = <String, double>{};
    final userRated = userRatings[userId] ?? {};

    // Calculate predicted ratings for unrated places
    for (final place in allPlaces) {
      if (userRated.containsKey(place.id)) continue;

      double weightedSum = 0;
      double similaritySum = 0;

      for (final entry in similarities.entries) {
        final otherUserId = entry.key;
        final similarity = entry.value['similarity'] ?? 0;
        final otherRatings = userRatings[otherUserId] ?? {};

        if (otherRatings.containsKey(place.id)) {
          weightedSum += similarity * otherRatings[place.id]!;
          similaritySum += similarity.abs();
        }
      }

      if (similaritySum > 0) {
        predictions[place.id] = weightedSum / similaritySum;
      }
    }

    // Sort places by predicted rating
    final recommendedPlaces = allPlaces
        .where((place) => predictions.containsKey(place.id))
        .toList()
      ..sort((a, b) =>
          (predictions[b.id] ?? 0).compareTo(predictions[a.id] ?? 0));

    return recommendedPlaces.take(limit).toList();
  }

  // Content-based Filtering
  static List<Place> getContentBasedRecommendations({
    required List<Place> userLikedPlaces,
    required List<Place> allPlaces,
    int limit = 10,
  }) {
    if (userLikedPlaces.isEmpty) return [];

    final userProfile = _createUserProfile(userLikedPlaces);
    final recommendations = <Place, double>{};

    for (final place in allPlaces) {
      if (userLikedPlaces.contains(place)) continue;

      double similarity = 0;
      // Calculate similarity based on categories
      final placeCategories = place.categories.toSet();
      similarity += _calculateJaccardSimilarity(
        userProfile['categories'] as Set<String>,
        placeCategories,
      );

      // Calculate similarity based on price range
      if (userProfile['priceRanges'].contains(place.priceRange)) {
        similarity += 0.3;
      }

      // Calculate similarity based on average rating
      final ratingDiff =
          1 - ((userProfile['avgRating'] - place.rating).abs() / 5);
      similarity += ratingDiff * 0.2;

      recommendations[place] = similarity;
    }

    return recommendations.entries
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value))
      ..take(limit)
        .map((e) => e.key)
        .toList();
  }

  static Map<String, dynamic> _createUserProfile(List<Place> likedPlaces) {
    final categories = <String>{};
    final priceRanges = <String>{};
    double totalRating = 0;

    for (final place in likedPlaces) {
      categories.addAll(place.categories);
      priceRanges.add(place.priceRange);
      totalRating += place.rating;
    }

    return {
      'categories': categories,
      'priceRanges': priceRanges,
      'avgRating': totalRating / likedPlaces.length,
    };
  }

  static double _calculateJaccardSimilarity(Set<String> a, Set<String> b) {
    if (a.isEmpty && b.isEmpty) return 0;
    final intersection = a.intersection(b);
    final union = a.union(b);
    return intersection.length / union.length;
  }

  // Hybrid Recommendations
  static List<Place> getHybridRecommendations({
    required Map<String, Map<String, double>> userRatings,
    required String userId,
    required List<Place> userLikedPlaces,
    required List<Place> allPlaces,
    int limit = 10,
  }) {
    final collaborative = getCollaborativeRecommendations(
      userRatings: userRatings,
      userId: userId,
      allPlaces: allPlaces,
      limit: limit,
    );

    final contentBased = getContentBasedRecommendations(
      userLikedPlaces: userLikedPlaces,
      allPlaces: allPlaces,
      limit: limit,
    );

    // Combine and deduplicate recommendations
    final hybrid = <Place>{};
    var i = 0;
    var j = 0;

    while (hybrid.length < limit &&
        (i < collaborative.length || j < contentBased.length)) {
      if (i < collaborative.length) {
        hybrid.add(collaborative[i]);
        i++;
      }
      if (j < contentBased.length) {
        hybrid.add(contentBased[j]);
        j++;
      }
    }

    return hybrid.take(limit).toList();
  }

  // Similar Places
  static List<Place> getSimilarPlaces({
    required Place targetPlace,
    required List<Place> allPlaces,
    int limit = 5,
  }) {
    final similarities = <Place, double>{};

    for (final place in allPlaces) {
      if (place.id == targetPlace.id) continue;

      double similarity = 0;

      // Category similarity (40% weight)
      similarity += _calculateJaccardSimilarity(
            targetPlace.categories.toSet(),
            place.categories.toSet(),
          ) *
          0.4;

      // Price range similarity (20% weight)
      if (place.priceRange == targetPlace.priceRange) {
        similarity += 0.2;
      }

      // Rating similarity (20% weight)
      similarity += (1 - (targetPlace.rating - place.rating).abs() / 5) * 0.2;

      // Location proximity (20% weight)
      final distance = _calculateDistance(
        targetPlace.latitude,
        targetPlace.longitude,
        place.latitude,
        place.longitude,
      );
      similarity += (1 - math.min(distance / 10000, 1)) * 0.2; // Max 10km

      similarities[place] = similarity;
    }

    return similarities.entries
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value))
      ..take(limit)
        .map((e) => e.key)
        .toList();
  }

  // Utility function to calculate distance between two points
  static double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const R = 6371e3; // Earth's radius in meters
    final phi1 = lat1 * math.pi / 180;
    final phi2 = lat2 * math.pi / 180;
    final deltaPhi = (lat2 - lat1) * math.pi / 180;
    final deltaLambda = (lon2 - lon1) * math.pi / 180;

    final a = math.sin(deltaPhi / 2) * math.sin(deltaPhi / 2) +
        math.cos(phi1) *
            math.cos(phi2) *
            math.sin(deltaLambda / 2) *
            math.sin(deltaLambda / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return R * c;
  }
}
