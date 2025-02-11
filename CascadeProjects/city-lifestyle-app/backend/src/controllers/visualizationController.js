const visualizationService = require('../services/visualizationService');

class VisualizationController {
  // Generate review trends chart
  async generateReviewTrendsChart(req, res) {
    try {
      const { startDate, endDate } = req.query;

      if (!startDate || !endDate) {
        return res.status(400).json({ error: 'Start date and end date are required' });
      }

      const chartBuffer = await visualizationService.generateReviewTrendsChart(
        new Date(startDate),
        new Date(endDate)
      );

      res.setHeader('Content-Type', 'image/png');
      res.send(chartBuffer);
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  }

  // Generate rating distribution chart
  async generateRatingDistributionChart(req, res) {
    try {
      const { startDate, endDate } = req.query;

      if (!startDate || !endDate) {
        return res.status(400).json({ error: 'Start date and end date are required' });
      }

      const chartBuffer = await visualizationService.generateRatingDistributionChart(
        new Date(startDate),
        new Date(endDate)
      );

      res.setHeader('Content-Type', 'image/png');
      res.send(chartBuffer);
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  }

  // Generate category performance chart
  async generateCategoryPerformanceChart(req, res) {
    try {
      const chartBuffer = await visualizationService.generateCategoryPerformanceChart();

      res.setHeader('Content-Type', 'image/png');
      res.send(chartBuffer);
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  }

  // Generate user engagement chart
  async generateUserEngagementChart(req, res) {
    try {
      const { startDate, endDate } = req.query;

      if (!startDate || !endDate) {
        return res.status(400).json({ error: 'Start date and end date are required' });
      }

      const chartBuffer = await visualizationService.generateUserEngagementChart(
        new Date(startDate),
        new Date(endDate)
      );

      res.setHeader('Content-Type', 'image/png');
      res.send(chartBuffer);
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  }
}

module.exports = new VisualizationController();
