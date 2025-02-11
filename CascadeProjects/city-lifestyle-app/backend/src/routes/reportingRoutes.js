const express = require('express');
const auth = require('../middleware/auth');
const admin = require('../middleware/admin');
const reportingController = require('../controllers/reportingController');

const router = express.Router();

// Middleware to check if user is admin
router.use(auth, admin);

// Generate daily report
router.get('/daily', reportingController.generateDailyReport);

// Generate weekly report
router.get('/weekly', reportingController.generateWeeklyReport);

// Generate monthly report
router.get('/monthly', reportingController.generateMonthlyReport);

// Generate custom report
router.post('/custom', reportingController.generateCustomReport);

module.exports = router;
