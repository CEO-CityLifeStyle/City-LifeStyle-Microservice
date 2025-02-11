const redis = require('../config/redis');
const logger = require('../config/logger');

const DEFAULT_EXPIRATION = 3600; // 1 hour

/**
 * Cache middleware factory
 * @param {number} duration - Cache duration in seconds
 * @returns {Function} Express middleware
 */
const cache = (duration = DEFAULT_EXPIRATION) => {
  return async (req, res, next) => {
    // Skip caching for non-GET requests
    if (req.method !== 'GET') {
      return next();
    }

    const key = `cache:${req.originalUrl}`;

    try {
      const cachedData = await redis.get(key);
      
      if (cachedData) {
        logger.debug(`Cache hit for ${key}`);
        return res.json(JSON.parse(cachedData));
      }

      // Store original send function
      const sendResponse = res.json.bind(res);
      
      // Override res.json method
      res.json = async (body) => {
        try {
          await redis.setex(key, duration, JSON.stringify(body));
          logger.debug(`Cached ${key} for ${duration}s`);
        } catch (err) {
          logger.error('Cache storage error:', err);
        }
        return sendResponse(body);
      };

      next();
    } catch (err) {
      logger.error('Cache middleware error:', err);
      next();
    }
  };
};

/**
 * Clear cache by pattern
 * @param {string} pattern - Cache key pattern to clear
 */
const clearCache = async (pattern) => {
  try {
    const keys = await redis.keys(`cache:${pattern}`);
    if (keys.length > 0) {
      await redis.del(keys);
      logger.info(`Cleared cache for pattern: ${pattern}`);
    }
  } catch (err) {
    logger.error('Cache clear error:', err);
  }
};

module.exports = {
  cache,
  clearCache
};
