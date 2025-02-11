const { BigQuery } = require('@google-cloud/bigquery');
const mongoose = require('mongoose');
const performanceService = require('./performanceService');

class AdvancedAnalyticsService {
  constructor() {
    this.bigquery = new BigQuery();
    this.dataset = this.bigquery.dataset(process.env.BIGQUERY_DATASET_ID);
    this.realtimeData = new Map();
    this.startRealtimeTracking();
  }

  // Start tracking realtime metrics
  startRealtimeTracking() {
    setInterval(() => this.updateRealtimeMetrics(), 60000); // Update every minute
  }

  // Get realtime metrics
  async getRealtimeMetrics() {
    try {
      const currentMetrics = {
        activeUsers: await this.getActiveUsers(),
        pageViews: this.realtimeData.get('pageViews') || 0,
        interactions: this.realtimeData.get('interactions') || 0,
        performance: await performanceService.getAllMetrics(),
        timestamp: new Date().toISOString()
      };

      return currentMetrics;
    } catch (error) {
      throw new Error(`Failed to get realtime metrics: ${error.message}`);
    }
  }

  // Get trend analysis
  async getTrends(startDate, endDate, metrics = []) {
    try {
      const query = `
        SELECT
          TIMESTAMP_TRUNC(timestamp, HOUR) as time_interval,
          ${metrics.join(', ')}
        FROM \`${process.env.BIGQUERY_DATASET_ID}.analytics\`
        WHERE timestamp BETWEEN @startDate AND @endDate
        GROUP BY time_interval
        ORDER BY time_interval ASC
      `;

      const options = {
        query,
        params: { startDate, endDate }
      };

      const [rows] = await this.bigquery.query(options);
      return rows;
    } catch (error) {
      throw new Error(`Failed to get trends: ${error.message}`);
    }
  }

  // Get user behavior analytics
  async getUserBehavior(startDate, endDate, segment) {
    try {
      const query = `
        SELECT
          user_id,
          COUNT(DISTINCT session_id) as sessions,
          AVG(session_duration) as avg_session_duration,
          COUNT(DISTINCT page_path) as unique_pages_viewed,
          COUNT(*) as total_interactions
        FROM \`${process.env.BIGQUERY_DATASET_ID}.user_events\`
        WHERE timestamp BETWEEN @startDate AND @endDate
        ${segment ? 'AND segment = @segment' : ''}
        GROUP BY user_id
      `;

      const options = {
        query,
        params: { startDate, endDate, segment }
      };

      const [rows] = await this.bigquery.query(options);
      return rows;
    } catch (error) {
      throw new Error(`Failed to get user behavior: ${error.message}`);
    }
  }

  // Get performance metrics
  async getPerformanceMetrics(startDate, endDate, type) {
    try {
      const query = `
        SELECT
          TIMESTAMP_TRUNC(timestamp, HOUR) as time_interval,
          AVG(response_time) as avg_response_time,
          AVG(cpu_usage) as avg_cpu_usage,
          AVG(memory_usage) as avg_memory_usage,
          COUNT(CASE WHEN status_code >= 400 THEN 1 END) as error_count
        FROM \`${process.env.BIGQUERY_DATASET_ID}.performance_metrics\`
        WHERE timestamp BETWEEN @startDate AND @endDate
        ${type ? 'AND metric_type = @type' : ''}
        GROUP BY time_interval
        ORDER BY time_interval ASC
      `;

      const options = {
        query,
        params: { startDate, endDate, type }
      };

      const [rows] = await this.bigquery.query(options);
      return rows;
    } catch (error) {
      throw new Error(`Failed to get performance metrics: ${error.message}`);
    }
  }

  // Get engagement metrics
  async getEngagementMetrics(startDate, endDate, segment) {
    try {
      const query = `
        SELECT
          date,
          COUNT(DISTINCT user_id) as daily_active_users,
          COUNT(DISTINCT session_id) as total_sessions,
          AVG(session_duration) as avg_session_duration,
          COUNT(*) / COUNT(DISTINCT user_id) as actions_per_user
        FROM \`${process.env.BIGQUERY_DATASET_ID}.user_engagement\`
        WHERE date BETWEEN @startDate AND @endDate
        ${segment ? 'AND segment = @segment' : ''}
        GROUP BY date
        ORDER BY date ASC
      `;

      const options = {
        query,
        params: { startDate, endDate, segment }
      };

      const [rows] = await this.bigquery.query(options);
      return rows;
    } catch (error) {
      throw new Error(`Failed to get engagement metrics: ${error.message}`);
    }
  }

  // Get retention metrics
  async getRetentionMetrics(cohort, timeframe) {
    try {
      const query = `
        WITH UserCohorts AS (
          SELECT
            user_id,
            DATE_TRUNC(first_seen_date, ${timeframe}) as cohort_date,
            DATE_DIFF(activity_date, first_seen_date, DAY) as day_number
          FROM \`${process.env.BIGQUERY_DATASET_ID}.user_activity\`
          WHERE cohort = @cohort
        )
        SELECT
          cohort_date,
          day_number,
          COUNT(DISTINCT user_id) as active_users
        FROM UserCohorts
        GROUP BY cohort_date, day_number
        ORDER BY cohort_date, day_number
      `;

      const options = {
        query,
        params: { cohort }
      };

      const [rows] = await this.bigquery.query(options);
      return rows;
    } catch (error) {
      throw new Error(`Failed to get retention metrics: ${error.message}`);
    }
  }

  // Get full analytics data
  async getFullAnalytics(startDate, endDate) {
    try {
      const [
        realtimeMetrics,
        trends,
        userBehavior,
        performanceMetrics,
        engagementMetrics,
        retentionMetrics
      ] = await Promise.all([
        this.getRealtimeMetrics(),
        this.getTrends(startDate, endDate, ['pageviews', 'users', 'events']),
        this.getUserBehavior(startDate, endDate),
        this.getPerformanceMetrics(startDate, endDate),
        this.getEngagementMetrics(startDate, endDate),
        this.getRetentionMetrics('all', 'WEEK')
      ]);

      return {
        realtimeMetrics,
        trends,
        userBehavior,
        performanceMetrics,
        engagementMetrics,
        retentionMetrics
      };
    } catch (error) {
      throw new Error(`Failed to get full analytics: ${error.message}`);
    }
  }

  // Get custom analytics
  async getCustomAnalytics(config) {
    try {
      const query = this.buildCustomQuery(config);
      const [rows] = await this.bigquery.query({ query });
      return rows;
    } catch (error) {
      throw new Error(`Failed to get custom analytics: ${error.message}`);
    }
  }

  // Export analytics data
  async exportAnalytics(format, metrics, startDate, endDate) {
    try {
      const data = await this.getCustomAnalytics({
        metrics,
        startDate,
        endDate
      });

      switch (format.toLowerCase()) {
        case 'csv':
          return this.convertToCSV(data);
        case 'json':
          return JSON.stringify(data, null, 2);
        case 'excel':
          return this.convertToExcel(data);
        default:
          throw new Error('Unsupported export format');
      }
    } catch (error) {
      throw new Error(`Failed to export analytics: ${error.message}`);
    }
  }

  // Configure analytics alerts
  async configureAlerts(config) {
    try {
      // Store alert configuration in database
      const alertConfig = {
        metrics: config.metrics,
        thresholds: config.thresholds,
        notifications: config.notifications
      };

      // Implementation would depend on how alerts are stored
      return alertConfig;
    } catch (error) {
      throw new Error(`Failed to configure alerts: ${error.message}`);
    }
  }

  // Get analytics reports
  async getReports(type, startDate, endDate) {
    try {
      const query = this.getReportQuery(type, startDate, endDate);
      const [rows] = await this.bigquery.query({ query });
      return rows;
    } catch (error) {
      throw new Error(`Failed to get reports: ${error.message}`);
    }
  }

  // Configure tracking settings
  async configureTracking(config) {
    try {
      // Store tracking configuration
      const trackingConfig = {
        enabledEvents: config.enabledEvents,
        samplingRate: config.samplingRate,
        customDimensions: config.customDimensions
      };

      // Implementation would depend on how tracking config is stored
      return trackingConfig;
    } catch (error) {
      throw new Error(`Failed to configure tracking: ${error.message}`);
    }
  }

  // Helper: Update realtime metrics
  async updateRealtimeMetrics() {
    try {
      const metrics = await this.fetchLatestMetrics();
      this.realtimeData = new Map(Object.entries(metrics));
    } catch (error) {
      console.error('Failed to update realtime metrics:', error);
    }
  }

  // Helper: Get active users
  async getActiveUsers() {
    try {
      const query = `
        SELECT COUNT(DISTINCT user_id) as active_users
        FROM \`${process.env.BIGQUERY_DATASET_ID}.user_sessions\`
        WHERE timestamp >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 5 MINUTE)
      `;

      const [rows] = await this.bigquery.query({ query });
      return rows[0]?.active_users || 0;
    } catch (error) {
      return 0;
    }
  }

  // Helper: Build custom query
  buildCustomQuery(config) {
    // Implementation would depend on the custom query configuration structure
    return `
      SELECT ${config.metrics.join(', ')}
      FROM \`${process.env.BIGQUERY_DATASET_ID}.${config.table}\`
      WHERE timestamp BETWEEN '${config.startDate}' AND '${config.endDate}'
      ${config.filters ? 'AND ' + config.filters.join(' AND ') : ''}
      ${config.groupBy ? 'GROUP BY ' + config.groupBy.join(', ') : ''}
      ${config.orderBy ? 'ORDER BY ' + config.orderBy : ''}
      ${config.limit ? 'LIMIT ' + config.limit : ''}
    `;
  }

  // Helper: Get report query
  getReportQuery(type, startDate, endDate) {
    // Implementation would depend on the report types needed
    const queries = {
      daily: `
        SELECT
          DATE(timestamp) as date,
          COUNT(DISTINCT user_id) as users,
          COUNT(*) as events
        FROM \`${process.env.BIGQUERY_DATASET_ID}.events\`
        WHERE timestamp BETWEEN '${startDate}' AND '${endDate}'
        GROUP BY date
        ORDER BY date
      `,
      // Add more report types as needed
    };

    return queries[type] || queries.daily;
  }

  // Helper: Convert data to CSV
  convertToCSV(data) {
    if (!data.length) return '';
    
    const headers = Object.keys(data[0]);
    const rows = data.map(row =>
      headers.map(header => JSON.stringify(row[header])).join(',')
    );
    
    return [headers.join(','), ...rows].join('\n');
  }

  // Helper: Convert data to Excel
  convertToExcel(data) {
    // Implementation would require a library like 'xlsx'
    // Return buffer or stream of Excel file
    return Buffer.from('Excel data');
  }
}

module.exports = new AdvancedAnalyticsService();
