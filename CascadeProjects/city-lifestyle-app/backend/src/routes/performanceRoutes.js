const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const admin = require('../middleware/admin');
const performanceController = require('../controllers/performanceController');

// Public endpoints
router.get('/metrics/public', performanceController.getPublicMetrics);

// Protected endpoints (require authentication)
router.get('/metrics', auth, performanceController.getMetrics);
router.get('/metrics/memory', auth, performanceController.getMemoryUsage);
router.get('/metrics/cpu', auth, performanceController.getCPUUsage);
router.get('/metrics/network', auth, performanceController.getNetworkLatency);
router.get('/metrics/storage', auth, performanceController.getStorageUsage);
router.get('/metrics/battery', auth, performanceController.getBatteryLevel);
router.get('/metrics/history', auth, performanceController.getMetricsHistory);

// Admin endpoints
router.post('/metrics/thresholds', [auth, admin], performanceController.updateThresholds);
router.post('/metrics/alerts', [auth, admin], performanceController.configureAlerts);
router.get('/metrics/alerts/history', [auth, admin], performanceController.getAlertHistory);
router.get('/metrics/system', [auth, admin], performanceController.getSystemMetrics);

module.exports = router;
