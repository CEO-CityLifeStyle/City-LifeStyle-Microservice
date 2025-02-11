const advancedAnalyticsService = require('../services/advancedAnalyticsService');

class AdvancedAnalyticsController {
  // Get real-time metrics
  async getRealtimeMetrics(req, res) {
    try {
      const metrics = await advancedAnalyticsService.getRealtimeMetrics();
      res.json(metrics);
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  }

  // Get trend analysis
  async getTrends(req, res) {
    try {
      const { startDate, endDate, metrics } = req.query;
      const trends = await advancedAnalyticsService.getTrends(startDate, endDate, metrics);
      res.json(trends);
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  }

  // Get user behavior analytics
  async getUserBehavior(req, res) {
    try {
      const { startDate, endDate, segment } = req.query;
      const behavior = await advancedAnalyticsService.getUserBehavior(startDate, endDate, segment);
      res.json(behavior);
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  }

  // Get performance metrics
  async getPerformanceMetrics(req, res) {
    try {
      const { startDate, endDate, type } = req.query;
      const metrics = await advancedAnalyticsService.getPerformanceMetrics(startDate, endDate, type);
      res.json(metrics);
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  }

  // Get engagement metrics
  async getEngagementMetrics(req, res) {
    try {
      const { startDate, endDate, segment } = req.query;
      const metrics = await advancedAnalyticsService.getEngagementMetrics(startDate, endDate, segment);
      res.json(metrics);
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  }

  // Get retention metrics
  async getRetentionMetrics(req, res) {
    try {
      const { cohort, timeframe } = req.query;
      const metrics = await advancedAnalyticsService.getRetentionMetrics(cohort, timeframe);
      res.json(metrics);
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  }

  // Get full analytics data
  async getFullAnalytics(req, res) {
    try {
      const { startDate, endDate } = req.query;
      const analytics = await advancedAnalyticsService.getFullAnalytics(startDate, endDate);
      res.json(analytics);
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  }

  // Get custom analytics
  async getCustomAnalytics(req, res) {
    try {
      const metrics = await advancedAnalyticsService.getCustomAnalytics(req.body);
      res.json(metrics);
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  }

  // Export analytics data
  async exportAnalytics(req, res) {
    try {
      const { format, metrics, startDate, endDate } = req.body;
      const exportData = await advancedAnalyticsService.exportAnalytics(format, metrics, startDate, endDate);
      
      res.setHeader('Content-Type', 'application/octet-stream');
      res.setHeader('Content-Disposition', `attachment; filename=analytics-export.${format}`);
      res.send(exportData);
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  }

  // Configure analytics alerts
  async configureAnalyticsAlerts(req, res) {
    try {
      const config = await advancedAnalyticsService.configureAlerts(req.body);
      res.json(config);
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  }

  // Get analytics reports
  async getAnalyticsReports(req, res) {
    try {
      const { type, startDate, endDate } = req.query;
      const reports = await advancedAnalyticsService.getReports(type, startDate, endDate);
      res.json(reports);
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  }

  // Configure tracking settings
  async configureTracking(req, res) {
    try {
      const config = await advancedAnalyticsService.configureTracking(req.body);
      res.json(config);
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  }
}

module.exports = new AdvancedAnalyticsController();
