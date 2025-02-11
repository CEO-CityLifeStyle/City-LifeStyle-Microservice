const sentimentAnalysisService = require('../services/sentimentAnalysisService');

class SentimentAnalysisController {
  // Analyze sentiment of a single review
  async analyzeSentiment(req, res) {
    try {
      const { text } = req.body;

      if (!text) {
        return res.status(400).json({ error: 'Text is required' });
      }

      const analysis = await sentimentAnalysisService.analyzeSentiment(text);
      res.json(analysis);
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  }

  // Analyze sentiment of multiple reviews
  async analyzeBatchSentiment(req, res) {
    try {
      const { reviewIds } = req.body;

      if (!reviewIds || !Array.isArray(reviewIds)) {
        return res.status(400).json({ error: 'Review IDs array is required' });
      }

      const analysis = await sentimentAnalysisService.analyzeBatchSentiment(reviewIds);
      res.json(analysis);
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  }

  // Get sentiment trends
  async getSentimentTrends(req, res) {
    try {
      const { startDate, endDate } = req.query;

      if (!startDate || !endDate) {
        return res.status(400).json({ error: 'Start date and end date are required' });
      }

      const trends = await sentimentAnalysisService.getSentimentTrends(
        new Date(startDate),
        new Date(endDate)
      );
      res.json(trends);
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  }

  // Get place sentiment analysis
  async getPlaceSentimentAnalysis(req, res) {
    try {
      const { placeId } = req.params;

      if (!placeId) {
        return res.status(400).json({ error: 'Place ID is required' });
      }

      const analysis = await sentimentAnalysisService.getPlaceSentimentAnalysis(placeId);
      res.json(analysis);
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  }
}

module.exports = new SentimentAnalysisController();
