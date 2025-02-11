const Redis = require('ioredis');
const config = require('../config/redis');
const logger = require('../utils/logger');

class CacheService {
  constructor() {
    this.redis = new Redis(config.redis);
    this.defaultTTL = 3600; // 1 hour

    // Cache key prefixes
    this.keyPrefixes = {
      place: 'place:',
      search: 'search:',
      category: 'category:',
      trending: 'trending:',
      analytics: 'analytics:'
    };

    // Initialize Redis connection
    this._initializeRedis();
  }

  async _initializeRedis() {
    this.redis.on('error', (error) => {
      logger.error('Redis connection error:', error);
    });

    this.redis.on('connect', () => {
      logger.info('Successfully connected to Redis');
    });
  }

  // Generic cache methods
  async get(key) {
    try {
      const value = await this.redis.get(key);
      return value ? JSON.parse(value) : null;
    } catch (error) {
      logger.error(`Error getting cache key ${key}:`, error);
      return null;
    }
  }

  async set(key, value, ttl = this.defaultTTL) {
    try {
      await this.redis.set(key, JSON.stringify(value), 'EX', ttl);
      return true;
    } catch (error) {
      logger.error(`Error setting cache key ${key}:`, error);
      return false;
    }
  }

  async delete(key) {
    try {
      await this.redis.del(key);
      return true;
    } catch (error) {
      logger.error(`Error deleting cache key ${key}:`, error);
      return false;
    }
  }

  // Place-specific cache methods
  async getPlace(placeId) {
    return this.get(`${this.keyPrefixes.place}${placeId}`);
  }

  async setPlace(placeId, placeData, ttl = 3600) {
    return this.set(`${this.keyPrefixes.place}${placeId}`, placeData, ttl);
  }

  async invalidatePlace(placeId) {
    return this.delete(`${this.keyPrefixes.place}${placeId}`);
  }

  // Search cache methods
  async getCachedSearch(query, filters) {
    const searchKey = this._generateSearchKey(query, filters);
    return this.get(`${this.keyPrefixes.search}${searchKey}`);
  }

  async setCachedSearch(query, filters, results, ttl = 300) { // 5 minutes
    const searchKey = this._generateSearchKey(query, filters);
    return this.set(`${this.keyPrefixes.search}${searchKey}`, results, ttl);
  }

  // Category cache methods
  async getCachedCategories() {
    return this.get(`${this.keyPrefixes.category}all`);
  }

  async setCachedCategories(categories, ttl = 86400) { // 24 hours
    return this.set(`${this.keyPrefixes.category}all`, categories, ttl);
  }

  // Trending places cache methods
  async getCachedTrending(location, radius) {
    const trendingKey = this._generateTrendingKey(location, radius);
    return this.get(`${this.keyPrefixes.trending}${trendingKey}`);
  }

  async setCachedTrending(location, radius, places, ttl = 900) { // 15 minutes
    const trendingKey = this._generateTrendingKey(location, radius);
    return this.set(`${this.keyPrefixes.trending}${trendingKey}`, places, ttl);
  }

  // Analytics cache methods
  async getCachedAnalytics(placeId, metric, timeframe) {
    const analyticsKey = this._generateAnalyticsKey(placeId, metric, timeframe);
    return this.get(`${this.keyPrefixes.analytics}${analyticsKey}`);
  }

  async setCachedAnalytics(placeId, metric, timeframe, data, ttl = 1800) { // 30 minutes
    const analyticsKey = this._generateAnalyticsKey(placeId, metric, timeframe);
    return this.set(`${this.keyPrefixes.analytics}${analyticsKey}`, data, ttl);
  }

  // Cache maintenance methods
  async clearExpiredKeys() {
    try {
      const script = `
        local keys = redis.call('keys', ARGV[1])
        local expired = {}
        for i, key in ipairs(keys) do
          if redis.call('ttl', key) <= 0 then
            redis.call('del', key)
            table.insert(expired, key)
          end
        end
        return expired
      `;
      
      const result = await this.redis.eval(script, 0, '*');
      logger.info(`Cleared ${result.length} expired keys`);
      return result;
    } catch (error) {
      logger.error('Error clearing expired keys:', error);
      return [];
    }
  }

  async warmupCache() {
    try {
      // Preload frequently accessed data
      const popularPlaces = await Place.find()
        .sort('-viewCount')
        .limit(100)
        .lean();

      const promises = popularPlaces.map(place =>
        this.setPlace(place._id, place, 7200) // 2 hours TTL
      );

      await Promise.all(promises);
      logger.info(`Warmed up cache with ${popularPlaces.length} popular places`);
    } catch (error) {
      logger.error('Error warming up cache:', error);
    }
  }

  // Private helper methods
  _generateSearchKey(query, filters) {
    const filterString = Object.entries(filters)
      .sort(([keyA], [keyB]) => keyA.localeCompare(keyB))
      .map(([key, value]) => `${key}:${JSON.stringify(value)}`)
      .join('|');
    
    return `${query}|${filterString}`;
  }

  _generateTrendingKey(location, radius) {
    const { latitude, longitude } = location;
    return `${latitude.toFixed(2)}:${longitude.toFixed(2)}:${radius}`;
  }

  _generateAnalyticsKey(placeId, metric, timeframe) {
    return `${placeId}:${metric}:${timeframe}`;
  }
}

module.exports = new CacheService();
