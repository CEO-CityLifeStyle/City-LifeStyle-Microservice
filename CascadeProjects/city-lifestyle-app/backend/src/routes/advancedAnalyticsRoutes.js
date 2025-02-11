const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const admin = require('../middleware/admin');
const advancedAnalyticsController = require('../controllers/advancedAnalyticsController');

// Protected endpoints (require authentication)
router.get('/analytics/realtime', auth, advancedAnalyticsController.getRealtimeMetrics);
router.get('/analytics/trends', auth, advancedAnalyticsController.getTrends);
router.get('/analytics/user-behavior', auth, advancedAnalyticsController.getUserBehavior);
router.get('/analytics/performance', auth, advancedAnalyticsController.getPerformanceMetrics);
router.get('/analytics/engagement', auth, advancedAnalyticsController.getEngagementMetrics);
router.get('/analytics/retention', auth, advancedAnalyticsController.getRetentionMetrics);

// Admin endpoints
router.get('/analytics/full', [auth, admin], advancedAnalyticsController.getFullAnalytics);
router.get('/analytics/custom', [auth, admin], advancedAnalyticsController.getCustomAnalytics);
router.post('/analytics/export', [auth, admin], advancedAnalyticsController.exportAnalytics);
router.post('/analytics/alerts', [auth, admin], advancedAnalyticsController.configureAnalyticsAlerts);
router.get('/analytics/reports', [auth, admin], advancedAnalyticsController.getAnalyticsReports);
router.post('/analytics/tracking', [auth, admin], advancedAnalyticsController.configureTracking);

module.exports = router;
