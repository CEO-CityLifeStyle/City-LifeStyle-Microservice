const { Category } = require('../models/category');
const { redisClient } = require('../config/redis');
const { elasticClient } = require('../config/elasticsearch');

class CategoryService {
  // Get category hierarchy
  async getCategoryHierarchy() {
    const cacheKey = 'category:hierarchy';
    const cachedResult = await redisClient.get(cacheKey);
    if (cachedResult) {
      return JSON.parse(cachedResult);
    }

    const categories = await Category.find()
      .populate('parent')
      .populate('subcategories')
      .lean();

    const hierarchy = this._buildHierarchy(categories);
    await redisClient.set(cacheKey, JSON.stringify(hierarchy), 'EX', 3600); // 1 hour cache

    return hierarchy;
  }

  // Get category recommendations
  async getCategoryRecommendations(userId, location) {
    const cacheKey = `category:recommendations:${userId}:${location.lat}:${location.lon}`;
    const cachedResult = await redisClient.get(cacheKey);
    if (cachedResult) {
      return JSON.parse(cachedResult);
    }

    // Get user's recent place views
    const userViews = await elasticClient.search({
      index: 'place_views',
      body: {
        query: {
          term: { userId }
        },
        sort: [{ timestamp: 'desc' }],
        size: 50
      }
    });

    // Extract categories from viewed places
    const viewedCategories = userViews.hits.hits.map(hit => hit._source.categories).flat();
    const categoryCounts = this._countCategories(viewedCategories);

    // Get popular categories in user's area
    const popularCategories = await this._getPopularCategoriesNearby(location);

    // Combine user preferences with local popularity
    const recommendations = this._combineRecommendations(categoryCounts, popularCategories);

    await redisClient.set(cacheKey, JSON.stringify(recommendations), 'EX', 1800); // 30 minutes cache

    return recommendations;
  }

  // Get trending categories
  async getTrendingCategories(location, timeframe = '24h') {
    const cacheKey = `category:trending:${location.lat}:${location.lon}:${timeframe}`;
    const cachedResult = await redisClient.get(cacheKey);
    if (cachedResult) {
      return JSON.parse(cachedResult);
    }

    const timestamp = this._getTimestampForTimeframe(timeframe);

    const result = await elasticClient.search({
      index: 'place_views',
      body: {
        query: {
          bool: {
            must: [
              {
                range: {
                  timestamp: {
                    gte: timestamp
                  }
                }
              },
              {
                geo_distance: {
                  distance: '10km',
                  location: {
                    lat: location.lat,
                    lon: location.lon
                  }
                }
              }
            ]
          }
        },
        aggs: {
          categories: {
            terms: {
              field: 'categories.keyword',
              size: 10
            }
          }
        }
      }
    });

    const trending = result.aggregations.categories.buckets.map(bucket => ({
      category: bucket.key,
      viewCount: bucket.doc_count
    }));

    await redisClient.set(cacheKey, JSON.stringify(trending), 'EX', 900); // 15 minutes cache

    return trending;
  }

  // Private helper methods
  _buildHierarchy(categories) {
    const rootCategories = categories.filter(cat => !cat.parent);
    return rootCategories.map(root => this._buildCategoryTree(root, categories));
  }

  _buildCategoryTree(category, allCategories) {
    const children = allCategories.filter(cat => 
      cat.parent && cat.parent._id.toString() === category._id.toString()
    );

    return {
      ...category,
      subcategories: children.map(child => this._buildCategoryTree(child, allCategories))
    };
  }

  _countCategories(categories) {
    return categories.reduce((acc, cat) => {
      acc[cat] = (acc[cat] || 0) + 1;
      return acc;
    }, {});
  }

  async _getPopularCategoriesNearby(location) {
    const result = await elasticClient.search({
      index: 'places',
      body: {
        query: {
          geo_distance: {
            distance: '10km',
            location: {
              lat: location.lat,
              lon: location.lon
            }
          }
        },
        aggs: {
          categories: {
            terms: {
              field: 'categories.keyword',
              size: 10
            }
          }
        }
      }
    });

    return result.aggregations.categories.buckets.map(bucket => ({
      category: bucket.key,
      count: bucket.doc_count
    }));
  }

  _combineRecommendations(userPreferences, localPopularity) {
    const combined = new Map();

    // Add user preferences with higher weight
    Object.entries(userPreferences).forEach(([category, count]) => {
      combined.set(category, count * 2);
    });

    // Add local popularity
    localPopularity.forEach(({ category, count }) => {
      const current = combined.get(category) || 0;
      combined.set(category, current + count);
    });

    // Sort and return top 10
    return Array.from(combined.entries())
      .sort((a, b) => b[1] - a[1])
      .slice(0, 10)
      .map(([category, score]) => ({ category, score }));
  }

  _getTimestampForTimeframe(timeframe) {
    const now = new Date();
    switch (timeframe) {
      case '24h':
        return new Date(now - 24 * 60 * 60 * 1000).toISOString();
      case '7d':
        return new Date(now - 7 * 24 * 60 * 60 * 1000).toISOString();
      case '30d':
        return new Date(now - 30 * 24 * 60 * 60 * 1000).toISOString();
      default:
        return new Date(now - 24 * 60 * 60 * 1000).toISOString();
    }
  }
}

module.exports = new CategoryService();
