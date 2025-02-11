const express = require('express');
const auth = require('../middleware/auth');
const admin = require('../middleware/admin');
const mlRecommendationController = require('../controllers/mlRecommendationController');

const router = express.Router();

// Middleware to check if user is authenticated
router.use(auth);

// Get collaborative filtering recommendations
router.get(
  '/collaborative/:userId',
  mlRecommendationController.getCollaborativeRecommendations
);

// Get content-based recommendations
router.get(
  '/content-based/:userId',
  mlRecommendationController.getContentBasedRecommendations
);

// Get hybrid recommendations
router.get(
  '/hybrid/:userId',
  mlRecommendationController.getHybridRecommendations
);

// Train recommendation models (admin only)
router.post('/train', admin, mlRecommendationController.trainModels);

module.exports = router;
