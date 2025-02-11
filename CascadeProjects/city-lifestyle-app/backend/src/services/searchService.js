const { Place } = require('../models/place');
const { redisClient } = require('../config/redis');
const { elasticClient } = require('../config/elasticsearch');

class SearchService {
  // Advanced search with multiple filters
  async searchPlaces({
    query,
    categories,
    location,
    radius,
    priceRange,
    rating,
    hours,
    amenities,
    page = 1,
    limit = 20
  }) {
    const cacheKey = this._generateCacheKey({
      query,
      categories,
      location,
      radius,
      priceRange,
      rating,
      hours,
      amenities,
      page,
      limit
    });

    // Try cache first
    const cachedResult = await redisClient.get(cacheKey);
    if (cachedResult) {
      return JSON.parse(cachedResult);
    }

    // Build Elasticsearch query
    const esQuery = {
      bool: {
        must: [],
        filter: []
      }
    };

    // Text search
    if (query) {
      esQuery.bool.must.push({
        multi_match: {
          query,
          fields: ['name^3', 'description^2', 'tags', 'amenities'],
          fuzziness: 'AUTO'
        }
      });
    }

    // Categories filter
    if (categories?.length) {
      esQuery.bool.filter.push({
        terms: { 'categories.keyword': categories }
      });
    }

    // Location filter
    if (location && radius) {
      esQuery.bool.filter.push({
        geo_distance: {
          distance: `${radius}km`,
          location: {
            lat: location.lat,
            lon: location.lon
          }
        }
      });
    }

    // Price range filter
    if (priceRange) {
      esQuery.bool.filter.push({
        range: {
          priceLevel: {
            gte: priceRange.min,
            lte: priceRange.max
          }
        }
      });
    }

    // Rating filter
    if (rating) {
      esQuery.bool.filter.push({
        range: {
          averageRating: {
            gte: rating
          }
        }
      });
    }

    // Operating hours filter
    if (hours) {
      const dayOfWeek = hours.day.toLowerCase();
      esQuery.bool.filter.push({
        nested: {
          path: 'operatingHours',
          query: {
            bool: {
              must: [
                { match: { 'operatingHours.day': dayOfWeek } },
                {
                  range: {
                    'operatingHours.open': { lte: hours.time }
                  }
                },
                {
                  range: {
                    'operatingHours.close': { gte: hours.time }
                  }
                }
              ]
            }
          }
        }
      });
    }

    // Amenities filter
    if (amenities?.length) {
      esQuery.bool.filter.push({
        terms: { 'amenities.keyword': amenities }
      });
    }

    // Execute search
    const result = await elasticClient.search({
      index: 'places',
      body: {
        query: esQuery,
        sort: [
          {
            _score: 'desc'
          },
          {
            averageRating: 'desc'
          }
        ],
        from: (page - 1) * limit,
        size: limit
      }
    });

    // Transform results
    const places = result.hits.hits.map(hit => ({
      ...hit._source,
      score: hit._score,
      distance: hit.sort?.[2]
    }));

    const response = {
      places,
      total: result.hits.total.value,
      page,
      totalPages: Math.ceil(result.hits.total.value / limit)
    };

    // Cache results
    await redisClient.set(cacheKey, JSON.stringify(response), 'EX', 300); // 5 minutes cache

    return response;
  }

  // Get trending places
  async getTrendingPlaces(location, radius = 10) {
    const cacheKey = `trending:${location.lat}:${location.lon}:${radius}`;
    const cachedResult = await redisClient.get(cacheKey);
    if (cachedResult) {
      return JSON.parse(cachedResult);
    }

    const result = await elasticClient.search({
      index: 'places',
      body: {
        query: {
          bool: {
            must: [
              {
                geo_distance: {
                  distance: `${radius}km`,
                  location: {
                    lat: location.lat,
                    lon: location.lon
                  }
                }
              }
            ]
          }
        },
        sort: [
          {
            viewCount: 'desc'
          },
          {
            averageRating: 'desc'
          }
        ],
        size: 20
      }
    });

    const places = result.hits.hits.map(hit => ({
      ...hit._source,
      score: hit._score
    }));

    await redisClient.set(cacheKey, JSON.stringify(places), 'EX', 1800); // 30 minutes cache

    return places;
  }

  // Get popular places by category
  async getPopularPlacesByCategory(category, location, radius = 5) {
    const cacheKey = `popular:${category}:${location.lat}:${location.lon}:${radius}`;
    const cachedResult = await redisClient.get(cacheKey);
    if (cachedResult) {
      return JSON.parse(cachedResult);
    }

    const result = await elasticClient.search({
      index: 'places',
      body: {
        query: {
          bool: {
            must: [
              {
                term: {
                  'categories.keyword': category
                }
              },
              {
                geo_distance: {
                  distance: `${radius}km`,
                  location: {
                    lat: location.lat,
                    lon: location.lon
                  }
                }
              }
            ]
          }
        },
        sort: [
          {
            popularityScore: 'desc'
          }
        ],
        size: 10
      }
    });

    const places = result.hits.hits.map(hit => ({
      ...hit._source,
      score: hit._score
    }));

    await redisClient.set(cacheKey, JSON.stringify(places), 'EX', 3600); // 1 hour cache

    return places;
  }

  // Private helper methods
  _generateCacheKey(params) {
    return `search:${JSON.stringify(params)}`;
  }
}

module.exports = new SearchService();
