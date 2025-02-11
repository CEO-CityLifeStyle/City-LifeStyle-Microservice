const express = require('express');
const {
  getNotifications,
  markAsRead,
  archiveNotifications,
  getRecommendations,
} = require('../controllers/notificationController');
const auth = require('../middleware/auth');

const router = express.Router();

// All routes require authentication
router.use(auth);

// Get user's notifications
router.get('/', getNotifications);

// Mark notifications as read
router.post('/read', markAsRead);

// Archive notifications
router.post('/archive', archiveNotifications);

// Get event recommendations
router.get('/recommendations', getRecommendations);

module.exports = router;
