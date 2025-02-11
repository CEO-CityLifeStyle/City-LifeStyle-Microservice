import 'dart:async';
import 'package:shared_preferences.dart';
import 'dart:convert';
import '../../models/place.dart';

class RecommendationCache {
  static const String _cacheKeyPrefix = 'recommendation_cache_';
  static const Duration _defaultCacheDuration = Duration(hours: 24);
  final SharedPreferences _prefs;

  RecommendationCache(this._prefs);

  Future<void> cacheRecommendations({
    required String userId,
    required String type,
    required List<Place> recommendations,
    Duration? cacheDuration,
  }) async {
    final key = _getCacheKey(userId, type);
    final data = {
      'timestamp': DateTime.now().toIso8601String(),
      'recommendations': recommendations.map((p) => p.toJson()).toList(),
    };

    await _prefs.setString(key, json.encode(data));
    await _prefs.setString(
      '${key}_expiry',
      DateTime.now()
          .add(cacheDuration ?? _defaultCacheDuration)
          .toIso8601String(),
    );
  }

  Future<List<Place>?> getCachedRecommendations({
    required String userId,
    required String type,
  }) async {
    final key = _getCacheKey(userId, type);
    final expiryKey = '${key}_expiry';

    final expiryStr = _prefs.getString(expiryKey);
    if (expiryStr == null) return null;

    final expiry = DateTime.parse(expiryStr);
    if (DateTime.now().isAfter(expiry)) {
      // Cache expired, clean up
      await _prefs.remove(key);
      await _prefs.remove(expiryKey);
      return null;
    }

    final cachedData = _prefs.getString(key);
    if (cachedData == null) return null;

    try {
      final data = json.decode(cachedData);
      final recommendations = (data['recommendations'] as List)
          .map((item) => Place.fromJson(item))
          .toList();
      return recommendations;
    } catch (e) {
      print('Error decoding cached recommendations: $e');
      return null;
    }
  }

  Future<void> invalidateCache(String userId, [String? type]) async {
    if (type != null) {
      final key = _getCacheKey(userId, type);
      await _prefs.remove(key);
      await _prefs.remove('${key}_expiry');
    } else {
      // Invalidate all recommendation types for user
      final keys = _prefs.getKeys().where(
            (key) => key.startsWith('$_cacheKeyPrefix${userId}_'),
          );
      for (final key in keys) {
        await _prefs.remove(key);
        await _prefs.remove('${key}_expiry');
      }
    }
  }

  Future<void> clearAllCaches() async {
    final keys = _prefs.getKeys().where(
          (key) => key.startsWith(_cacheKeyPrefix),
        );
    for (final key in keys) {
      await _prefs.remove(key);
    }
  }

  String _getCacheKey(String userId, String type) {
    return '$_cacheKeyPrefix${userId}_$type';
  }

  // Analytics methods for cache performance
  Future<Map<String, dynamic>> getCacheStats() async {
    int totalEntries = 0;
    int expiredEntries = 0;
    final types = <String>{};
    int totalSize = 0;

    final now = DateTime.now();
    final keys = _prefs.getKeys().where(
          (key) => key.startsWith(_cacheKeyPrefix) && !key.endsWith('_expiry'),
        );

    for (final key in keys) {
      totalEntries++;
      final data = _prefs.getString(key);
      if (data != null) {
        totalSize += data.length;
      }

      final type = key.split('_').last;
      types.add(type);

      final expiryStr = _prefs.getString('${key}_expiry');
      if (expiryStr != null) {
        final expiry = DateTime.parse(expiryStr);
        if (now.isAfter(expiry)) {
          expiredEntries++;
        }
      }
    }

    return {
      'totalEntries': totalEntries,
      'expiredEntries': expiredEntries,
      'activeEntries': totalEntries - expiredEntries,
      'uniqueTypes': types.length,
      'types': types.toList(),
      'totalSizeBytes': totalSize,
      'timestamp': now.toIso8601String(),
    };
  }
}
