const express = require('express');
const auth = require('../middleware/auth');
const admin = require('../middleware/admin');
const visualizationController = require('../controllers/visualizationController');

const router = express.Router();

// Middleware to check if user is admin
router.use(auth, admin);

// Generate review trends chart
router.get('/review-trends', visualizationController.generateReviewTrendsChart);

// Generate rating distribution chart
router.get('/rating-distribution', visualizationController.generateRatingDistributionChart);

// Generate category performance chart
router.get('/category-performance', visualizationController.generateCategoryPerformanceChart);

// Generate user engagement chart
router.get('/user-engagement', visualizationController.generateUserEngagementChart);

module.exports = router;
