const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const realtimeDashboardController = require('../controllers/realtimeDashboardController');

// All routes require authentication
router.use(auth);

// Dashboard CRUD operations
router.post('/dashboards', realtimeDashboardController.createDashboard);
router.get('/dashboards/:dashboardId/data', realtimeDashboardController.getDashboardData);
router.put('/dashboards/:dashboardId', realtimeDashboardController.updateDashboard);
router.get('/dashboards/:dashboardId/export', realtimeDashboardController.exportDashboard);

module.exports = router;
