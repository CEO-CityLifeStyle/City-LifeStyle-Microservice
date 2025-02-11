const { Place } = require('../models/place');
const { redisClient } = require('../config/redis');
const { elasticClient } = require('../config/elasticsearch');
const { BigQuery } = require('@google-cloud/bigquery');

class AnalyticsService {
  constructor() {
    this.bigquery = new BigQuery();
  }

  // Track place view
  async trackPlaceView(placeId, userId, location) {
    const viewData = {
      placeId,
      userId,
      location,
      timestamp: new Date().toISOString()
    };

    // Store in Elasticsearch for real-time analytics
    await elasticClient.index({
      index: 'place_views',
      body: viewData
    });

    // Increment view count in Redis
    const viewCountKey = `place:${placeId}:views`;
    await redisClient.incr(viewCountKey);

    // Store in BigQuery for long-term analytics
    await this._storeToBigQuery('place_views', viewData);
  }

  // Get place analytics
  async getPlaceAnalytics(placeId, timeframe = '7d') {
    const timestamp = this._getTimestampForTimeframe(timeframe);

    // Get view counts
    const viewCounts = await elasticClient.search({
      index: 'place_views',
      body: {
        query: {
          bool: {
            must: [
              { term: { placeId } },
              {
                range: {
                  timestamp: {
                    gte: timestamp
                  }
                }
              }
            ]
          }
        },
        aggs: {
          views_over_time: {
            date_histogram: {
              field: 'timestamp',
              calendar_interval: this._getIntervalForTimeframe(timeframe)
            }
          },
          unique_visitors: {
            cardinality: {
              field: 'userId'
            }
          }
        }
      }
    });

    // Get search appearances
    const searchAppearances = await elasticClient.search({
      index: 'search_logs',
      body: {
        query: {
          bool: {
            must: [
              { term: { 'results.placeId': placeId } },
              {
                range: {
                  timestamp: {
                    gte: timestamp
                  }
                }
              }
            ]
          }
        },
        aggs: {
          appearances_over_time: {
            date_histogram: {
              field: 'timestamp',
              calendar_interval: this._getIntervalForTimeframe(timeframe)
            }
          },
          click_through_rate: {
            avg: {
              field: 'results.position'
            }
          }
        }
      }
    });

    return {
      viewCounts: viewCounts.aggregations.views_over_time.buckets,
      uniqueVisitors: viewCounts.aggregations.unique_visitors.value,
      searchAppearances: searchAppearances.aggregations.appearances_over_time.buckets,
      averagePosition: searchAppearances.aggregations.click_through_rate.value
    };
  }

  // Get peak hours analysis
  async getPeakHoursAnalysis(placeId) {
    const cacheKey = `place:${placeId}:peak_hours`;
    const cachedResult = await redisClient.get(cacheKey);
    if (cachedResult) {
      return JSON.parse(cachedResult);
    }

    const query = `
      SELECT
        EXTRACT(HOUR FROM timestamp) as hour,
        COUNT(*) as visit_count
      FROM \`place_views\`
      WHERE placeId = @placeId
        AND timestamp >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 30 DAY)
      GROUP BY hour
      ORDER BY hour
    `;

    const options = {
      query,
      params: { placeId }
    };

    const [rows] = await this.bigquery.query(options);
    const peakHours = this._analyzePeakHours(rows);

    await redisClient.set(cacheKey, JSON.stringify(peakHours), 'EX', 3600); // 1 hour cache

    return peakHours;
  }

  // Get seasonal patterns
  async getSeasonalPatterns(placeId) {
    const cacheKey = `place:${placeId}:seasonal_patterns`;
    const cachedResult = await redisClient.get(cacheKey);
    if (cachedResult) {
      return JSON.parse(cachedResult);
    }

    const query = `
      SELECT
        EXTRACT(MONTH FROM timestamp) as month,
        COUNT(*) as visit_count
      FROM \`place_views\`
      WHERE placeId = @placeId
        AND timestamp >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 1 YEAR)
      GROUP BY month
      ORDER BY month
    `;

    const options = {
      query,
      params: { placeId }
    };

    const [rows] = await this.bigquery.query(options);
    const patterns = this._analyzeSeasonalPatterns(rows);

    await redisClient.set(cacheKey, JSON.stringify(patterns), 'EX', 86400); // 24 hours cache

    return patterns;
  }

  // Private helper methods
  async _storeToBigQuery(table, data) {
    const dataset = this.bigquery.dataset('place_analytics');
    const tableRef = dataset.table(table);
    await tableRef.insert(data);
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
        return new Date(now - 7 * 24 * 60 * 60 * 1000).toISOString();
    }
  }

  _getIntervalForTimeframe(timeframe) {
    switch (timeframe) {
      case '24h':
        return 'hour';
      case '7d':
        return 'day';
      case '30d':
        return 'day';
      default:
        return 'day';
    }
  }

  _analyzePeakHours(hourlyData) {
    const peakThreshold = Math.max(...hourlyData.map(d => d.visit_count)) * 0.8;
    
    return hourlyData.map(data => ({
      hour: data.hour,
      visitCount: data.visit_count,
      isPeak: data.visit_count >= peakThreshold
    }));
  }

  _analyzeSeasonalPatterns(monthlyData) {
    const average = monthlyData.reduce((sum, d) => sum + d.visit_count, 0) / monthlyData.length;
    const threshold = average * 0.2; // 20% variation threshold

    return monthlyData.map(data => ({
      month: data.month,
      visitCount: data.visit_count,
      trend: data.visit_count > average + threshold ? 'high' :
             data.visit_count < average - threshold ? 'low' : 'normal'
    }));
  }
}

module.exports = new AnalyticsService();
