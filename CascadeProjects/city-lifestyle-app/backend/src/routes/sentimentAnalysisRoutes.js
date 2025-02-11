const express = require('express');
const auth = require('../middleware/auth');
const admin = require('../middleware/admin');
const sentimentAnalysisController = require('../controllers/sentimentAnalysisController');

const router = express.Router();

// Middleware to check if user is authenticated
router.use(auth);

// Analyze sentiment of a single review
router.post('/analyze', sentimentAnalysisController.analyzeSentiment);

// Analyze sentiment of multiple reviews (admin only)
router.post('/analyze-batch', admin, sentimentAnalysisController.analyzeBatchSentiment);

// Get sentiment trends (admin only)
router.get('/trends', admin, sentimentAnalysisController.getSentimentTrends);

// Get place sentiment analysis
router.get('/place/:placeId', sentimentAnalysisController.getPlaceSentimentAnalysis);

module.exports = router;
