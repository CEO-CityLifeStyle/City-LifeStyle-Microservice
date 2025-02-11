import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:city_lifestyle_app/services/ml/recommendation_cache.dart';
import 'package:city_lifestyle_app/models/place.dart';

void main() {
  group('RecommendationCache Tests', () {
    late RecommendationCache cache;
    late SharedPreferences prefs;
    late List<Place> testRecommendations;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      cache = RecommendationCache(prefs);

      testRecommendations = [
        Place(
          id: '1',
          name: 'Test Place 1',
          categories: ['restaurant'],
          rating: 4.5,
          priceRange: '\$\$',
          latitude: 25.1234,
          longitude: 55.1234,
        ),
        Place(
          id: '2',
          name: 'Test Place 2',
          categories: ['cafe'],
          rating: 4.0,
          priceRange: '\$',
          latitude: 25.1235,
          longitude: 55.1235,
        ),
      ];
    });

    test('Cache Recommendations', () async {
      await cache.cacheRecommendations(
        userId: 'user1',
        type: 'collaborative',
        recommendations: testRecommendations,
      );

      final cached = await cache.getCachedRecommendations(
        userId: 'user1',
        type: 'collaborative',
      );

      expect(cached, isNotNull);
      expect(cached!.length, equals(2));
      expect(cached.first.id, equals('1'));
      expect(cached.last.id, equals('2'));
    });

    test('Cache Expiration', () async {
      // Cache with short duration
      await cache.cacheRecommendations(
        userId: 'user1',
        type: 'collaborative',
        recommendations: testRecommendations,
        cacheDuration: const Duration(milliseconds: 100),
      );

      // Wait for cache to expire
      await Future.delayed(const Duration(milliseconds: 150));

      final cached = await cache.getCachedRecommendations(
        userId: 'user1',
        type: 'collaborative',
      );

      expect(cached, isNull);
    });

    test('Cache Invalidation', () async {
      await cache.cacheRecommendations(
        userId: 'user1',
        type: 'collaborative',
        recommendations: testRecommendations,
      );

      await cache.invalidateCache('user1', 'collaborative');

      final cached = await cache.getCachedRecommendations(
        userId: 'user1',
        type: 'collaborative',
      );

      expect(cached, isNull);
    });

    test('Clear All Caches', () async {
      // Cache multiple types
      await cache.cacheRecommendations(
        userId: 'user1',
        type: 'collaborative',
        recommendations: testRecommendations,
      );

      await cache.cacheRecommendations(
        userId: 'user1',
        type: 'content-based',
        recommendations: testRecommendations,
      );

      await cache.clearAllCaches();

      final collaborative = await cache.getCachedRecommendations(
        userId: 'user1',
        type: 'collaborative',
      );
      final contentBased = await cache.getCachedRecommendations(
        userId: 'user1',
        type: 'content-based',
      );

      expect(collaborative, isNull);
      expect(contentBased, isNull);
    });

    test('Cache Stats', () async {
      await cache.cacheRecommendations(
        userId: 'user1',
        type: 'collaborative',
        recommendations: testRecommendations,
      );

      await cache.cacheRecommendations(
        userId: 'user2',
        type: 'content-based',
        recommendations: testRecommendations,
      );

      final stats = await cache.getCacheStats();

      expect(stats['totalEntries'], equals(2));
      expect(stats['expiredEntries'], equals(0));
      expect(stats['activeEntries'], equals(2));
      expect(stats['uniqueTypes'], equals(2));
      expect(stats['types'], contains('collaborative'));
      expect(stats['types'], contains('content-based'));
      expect(stats['totalSizeBytes'], isPositive);
    });

    test('Multiple User Caches', () async {
      await cache.cacheRecommendations(
        userId: 'user1',
        type: 'collaborative',
        recommendations: testRecommendations,
      );

      await cache.cacheRecommendations(
        userId: 'user2',
        type: 'collaborative',
        recommendations: testRecommendations,
      );

      final user1Cache = await cache.getCachedRecommendations(
        userId: 'user1',
        type: 'collaborative',
      );
      final user2Cache = await cache.getCachedRecommendations(
        userId: 'user2',
        type: 'collaborative',
      );

      expect(user1Cache, isNotNull);
      expect(user2Cache, isNotNull);
      expect(user1Cache!.length, equals(user2Cache!.length));
    });

    test('Invalid Cache Data', () async {
      // Manually set invalid cache data
      await prefs.setString(
        'recommendation_cache_user1_collaborative',
        'invalid_json_data',
      );

      final cached = await cache.getCachedRecommendations(
        userId: 'user1',
        type: 'collaborative',
      );

      expect(cached, isNull);
    });
  });
}
