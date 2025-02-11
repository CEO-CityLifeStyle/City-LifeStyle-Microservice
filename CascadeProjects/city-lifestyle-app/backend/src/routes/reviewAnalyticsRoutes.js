const express = require('express');
const auth = require('../middleware/auth');
const admin = require('../middleware/admin');
const reviewAnalyticsController = require('../controllers/reviewAnalyticsController');

const router = express.Router();

// Middleware to check if user is admin
router.use(auth, admin);

// Dashboard overview
router.get('/dashboard', reviewAnalyticsController.getDashboardOverview);

// Review trends
router.get('/trends', reviewAnalyticsController.getReviewTrends);

// Sentiment analysis
router.get('/sentiment', reviewAnalyticsController.getSentimentAnalysis);

// Top reviewers
router.get('/top-reviewers', reviewAnalyticsController.getTopReviewers);

// Place review analytics
router.get('/places/:placeId', reviewAnalyticsController.getPlaceReviewAnalytics);

// Review quality metrics
router.get('/quality', reviewAnalyticsController.getReviewQualityMetrics);

// Category insights
router.get('/categories', reviewAnalyticsController.getCategoryInsights);

// Moderation metrics
router.get('/moderation', reviewAnalyticsController.getModerationMetrics);

// Search reviews
router.get('/search', reviewAnalyticsController.searchReviews);

// Export review data
router.get('/export', reviewAnalyticsController.exportReviewData);

module.exports = router;
