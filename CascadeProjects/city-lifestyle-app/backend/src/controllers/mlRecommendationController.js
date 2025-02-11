const mlRecommendationService = require('../services/mlRecommendationService');

class MLRecommendationController {
  // Get collaborative filtering recommendations
  async getCollaborativeRecommendations(req, res) {
    try {
      const { userId } = req.params;
      const { limit } = req.query;

      if (!userId) {
        return res.status(400).json({ error: 'User ID is required' });
      }

      const recommendations = await mlRecommendationService.getCollaborativeRecommendations(
        userId,
        limit ? parseInt(limit) : 10
      );
      res.json(recommendations);
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  }

  // Get content-based recommendations
  async getContentBasedRecommendations(req, res) {
    try {
      const { userId } = req.params;
      const { limit } = req.query;

      if (!userId) {
        return res.status(400).json({ error: 'User ID is required' });
      }

      const recommendations = await mlRecommendationService.getContentBasedRecommendations(
        userId,
        limit ? parseInt(limit) : 10
      );
      res.json(recommendations);
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  }

  // Get hybrid recommendations
  async getHybridRecommendations(req, res) {
    try {
      const { userId } = req.params;
      const { limit } = req.query;

      if (!userId) {
        return res.status(400).json({ error: 'User ID is required' });
      }

      const recommendations = await mlRecommendationService.getHybridRecommendations(
        userId,
        limit ? parseInt(limit) : 10
      );
      res.json(recommendations);
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  }

  // Train recommendation models
  async trainModels(req, res) {
    try {
      await mlRecommendationService.trainModels();
      res.json({ message: 'Models trained successfully' });
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  }
}

module.exports = new MLRecommendationController();
