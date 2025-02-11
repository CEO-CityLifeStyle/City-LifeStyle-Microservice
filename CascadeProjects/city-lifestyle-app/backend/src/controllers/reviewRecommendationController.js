const reviewRecommendationService = require('../services/reviewRecommendationService');

class ReviewRecommendationController {
  // Get personalized recommendations
  async getPersonalizedRecommendations(req, res) {
    try {
      const userId = req.user._id;
      const { limit } = req.query;

      const recommendations = await reviewRecommendationService
        .getPersonalizedRecommendations(userId, parseInt(limit));

      res.json(recommendations);
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  }

  // Get trending reviews
  async getTrendingReviews(req, res) {
    try {
      const { limit, timeframe } = req.query;

      const trending = await reviewRecommendationService
        .getTrendingReviews(parseInt(limit), timeframe);

      res.json(trending);
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  }

  // Get similar reviews
  async getSimilarReviews(req, res) {
    try {
      const { reviewId } = req.params;
      const { limit } = req.query;

      const similar = await reviewRecommendationService
        .getSimilarReviews(reviewId, parseInt(limit));

      res.json(similar);
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  }

  // Get place recommendations
  async getPlaceRecommendations(req, res) {
    try {
      const { placeId } = req.params;
      const { limit } = req.query;

      const recommended = await reviewRecommendationService
        .getPlaceRecommendations(placeId, parseInt(limit));

      res.json(recommended);
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  }
}

module.exports = new ReviewRecommendationController();
