const reviewAnalyticsService = require('../services/reviewAnalyticsService');

class ReviewAnalyticsController {
  // Get review dashboard overview
  async getDashboardOverview(req, res) {
    try {
      const { startDate, endDate } = req.query;
      const start = startDate ? new Date(startDate) : new Date(Date.now() - 30 * 24 * 60 * 60 * 1000);
      const end = endDate ? new Date(endDate) : new Date();

      const [
        trends,
        sentiment,
        topReviewers,
        qualityMetrics,
        categoryInsights,
        moderationMetrics,
      ] = await Promise.all([
        reviewAnalyticsService.getReviewTrends(start, end),
        reviewAnalyticsService.getSentimentAnalysis(start, end),
        reviewAnalyticsService.getTopReviewers(),
        reviewAnalyticsService.getReviewQualityMetrics(start, end),
        reviewAnalyticsService.getCategoryInsights(),
        reviewAnalyticsService.getModerationMetrics(start, end),
      ]);

      res.json({
        trends,
        sentiment,
        topReviewers,
        qualityMetrics,
        categoryInsights,
        moderationMetrics,
      });
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  }

  // Get review trends
  async getReviewTrends(req, res) {
    try {
      const { startDate, endDate } = req.query;
      const start = new Date(startDate);
      const end = new Date(endDate);

      const trends = await reviewAnalyticsService.getReviewTrends(start, end);
      res.json(trends);
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  }

  // Get sentiment analysis
  async getSentimentAnalysis(req, res) {
    try {
      const { startDate, endDate } = req.query;
      const start = new Date(startDate);
      const end = new Date(endDate);

      const sentiment = await reviewAnalyticsService.getSentimentAnalysis(start, end);
      res.json(sentiment);
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  }

  // Get top reviewers
  async getTopReviewers(req, res) {
    try {
      const { limit } = req.query;
      const topReviewers = await reviewAnalyticsService.getTopReviewers(parseInt(limit));
      res.json(topReviewers);
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  }

  // Get place review analytics
  async getPlaceReviewAnalytics(req, res) {
    try {
      const { placeId } = req.params;
      const analytics = await reviewAnalyticsService.getPlaceReviewAnalytics(placeId);
      res.json(analytics);
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  }

  // Get review quality metrics
  async getReviewQualityMetrics(req, res) {
    try {
      const { startDate, endDate } = req.query;
      const start = new Date(startDate);
      const end = new Date(endDate);

      const metrics = await reviewAnalyticsService.getReviewQualityMetrics(start, end);
      res.json(metrics);
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  }

  // Get category insights
  async getCategoryInsights(req, res) {
    try {
      const insights = await reviewAnalyticsService.getCategoryInsights();
      res.json(insights);
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  }

  // Get moderation metrics
  async getModerationMetrics(req, res) {
    try {
      const { startDate, endDate } = req.query;
      const start = new Date(startDate);
      const end = new Date(endDate);

      const metrics = await reviewAnalyticsService.getModerationMetrics(start, end);
      res.json(metrics);
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  }

  // Search reviews
  async searchReviews(req, res) {
    try {
      const { page = 1, limit = 10, sort = '-createdAt', ...filters } = req.query;

      // Convert sort string to object
      const sortObj = {};
      sort.split(',').forEach(s => {
        const [field, order] = s.startsWith('-') 
          ? [s.substring(1), -1] 
          : [s, 1];
        sortObj[field] = order;
      });

      const results = await reviewAnalyticsService.searchReviews(
        filters,
        sortObj,
        parseInt(page),
        parseInt(limit)
      );

      res.json(results);
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  }

  // Export review data
  async exportReviewData(req, res) {
    try {
      const { format = 'json', ...filters } = req.query;

      const data = await reviewAnalyticsService.exportReviewData(filters, format);

      if (format === 'csv') {
        res.setHeader('Content-Type', 'text/csv');
        res.setHeader('Content-Disposition', 'attachment; filename=reviews.csv');
      } else {
        res.setHeader('Content-Type', 'application/json');
        res.setHeader('Content-Disposition', 'attachment; filename=reviews.json');
      }

      res.send(data);
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  }
}

module.exports = new ReviewAnalyticsController();
