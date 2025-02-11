const express = require('express');
const auth = require('../middleware/auth');
const reviewRecommendationController = require('../controllers/reviewRecommendationController');

const router = express.Router();

// Middleware to check if user is authenticated
router.use(auth);

// Get personalized recommendations
router.get('/personalized', reviewRecommendationController.getPersonalizedRecommendations);

// Get trending reviews
router.get('/trending', reviewRecommendationController.getTrendingReviews);

// Get similar reviews
router.get('/similar/:reviewId', reviewRecommendationController.getSimilarReviews);

// Get place recommendations
router.get('/places/:placeId', reviewRecommendationController.getPlaceRecommendations);

module.exports = router;
