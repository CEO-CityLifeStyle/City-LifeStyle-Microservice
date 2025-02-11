import 'package:flutter_test/flutter_test.dart';
import 'package:city_lifestyle_app/services/ml/recommendation_algorithm.dart';
import 'package:city_lifestyle_app/models/place.dart';

void main() {
  group('RecommendationAlgorithm Tests', () {
    late List<Place> testPlaces;
    late Map<String, Map<String, double>> testUserRatings;

    setUp(() {
      // Setup test data
      testPlaces = [
        Place(
          id: '1',
          name: 'Restaurant A',
          categories: ['restaurant', 'italian'],
          rating: 4.5,
          priceRange: '\$\$',
          latitude: 25.1234,
          longitude: 55.1234,
        ),
        Place(
          id: '2',
          name: 'Cafe B',
          categories: ['cafe', 'breakfast'],
          rating: 4.2,
          priceRange: '\$',
          latitude: 25.1235,
          longitude: 55.1235,
        ),
        Place(
          id: '3',
          name: 'Restaurant C',
          categories: ['restaurant', 'japanese'],
          rating: 4.8,
          priceRange: '\$\$\$',
          latitude: 25.1236,
          longitude: 55.1236,
        ),
      ];

      testUserRatings = {
        'user1': {
          '1': 4.5,
          '2': 3.5,
        },
        'user2': {
          '1': 4.0,
          '3': 4.8,
        },
        'user3': {
          '2': 3.8,
          '3': 4.2,
        },
      };
    });

    test('Collaborative Filtering - getCollaborativeRecommendations', () {
      final recommendations = RecommendationAlgorithm.getCollaborativeRecommendations(
        userRatings: testUserRatings,
        userId: 'user1',
        allPlaces: testPlaces,
        limit: 2,
      );

      expect(recommendations, isNotEmpty);
      expect(recommendations.length, lessThanOrEqualTo(2));
      expect(recommendations.first, isA<Place>());
    });

    test('Content-based Filtering - getContentBasedRecommendations', () {
      final userLikedPlaces = [testPlaces[0]]; // User likes Italian restaurant

      final recommendations = RecommendationAlgorithm.getContentBasedRecommendations(
        userLikedPlaces: userLikedPlaces,
        allPlaces: testPlaces,
        limit: 2,
      );

      expect(recommendations, isNotEmpty);
      expect(recommendations.length, lessThanOrEqualTo(2));
      expect(recommendations.first, isA<Place>());
      // Should not recommend the same place
      expect(recommendations.contains(testPlaces[0]), isFalse);
    });

    test('Hybrid Recommendations - getHybridRecommendations', () {
      final userLikedPlaces = [testPlaces[0]];

      final recommendations = RecommendationAlgorithm.getHybridRecommendations(
        userRatings: testUserRatings,
        userId: 'user1',
        userLikedPlaces: userLikedPlaces,
        allPlaces: testPlaces,
        limit: 2,
      );

      expect(recommendations, isNotEmpty);
      expect(recommendations.length, lessThanOrEqualTo(2));
      expect(recommendations.first, isA<Place>());
    });

    test('Similar Places - getSimilarPlaces', () {
      final targetPlace = testPlaces[0];

      final recommendations = RecommendationAlgorithm.getSimilarPlaces(
        targetPlace: targetPlace,
        allPlaces: testPlaces,
        limit: 2,
      );

      expect(recommendations, isNotEmpty);
      expect(recommendations.length, lessThanOrEqualTo(2));
      expect(recommendations.first, isA<Place>());
      // Should not recommend the target place
      expect(recommendations.contains(targetPlace), isFalse);
    });

    test('Jaccard Similarity Calculation', () {
      final set1 = {'restaurant', 'italian'}.toSet();
      final set2 = {'restaurant', 'japanese'}.toSet();
      final set3 = {'cafe', 'breakfast'}.toSet();

      final similarity12 = RecommendationAlgorithm._calculateJaccardSimilarity(
        set1,
        set2,
      );
      final similarity13 = RecommendationAlgorithm._calculateJaccardSimilarity(
        set1,
        set3,
      );

      // Restaurant-Restaurant should have higher similarity than Restaurant-Cafe
      expect(similarity12, greaterThan(similarity13));
      expect(similarity12, greaterThanOrEqualTo(0));
      expect(similarity12, lessThanOrEqualTo(1));
    });

    test('Distance Calculation', () {
      const lat1 = 25.1234;
      const lon1 = 55.1234;
      const lat2 = 25.1235;
      const lon2 = 55.1235;

      final distance = RecommendationAlgorithm._calculateDistance(
        lat1,
        lon1,
        lat2,
        lon2,
      );

      expect(distance, isPositive);
      // Distance should be relatively small for nearby coordinates
      expect(distance, lessThan(1000)); // Less than 1km
    });
  });
}
