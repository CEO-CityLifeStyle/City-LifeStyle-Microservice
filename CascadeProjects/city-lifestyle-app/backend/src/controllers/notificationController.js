const notificationService = require('../services/notificationService');

// Get user's notifications
const getNotifications = async (req, res) => {
  try {
    const { status = 'unread', page = 1, limit = 20 } = req.query;
    const result = await notificationService.getUserNotifications(
      req.user._id,
      status,
      parseInt(page),
      parseInt(limit)
    );
    res.json(result);
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
};

// Mark notifications as read
const markAsRead = async (req, res) => {
  try {
    const { notificationIds } = req.body;
    await notificationService.markAsRead(notificationIds, req.user._id);
    res.json({ message: 'Notifications marked as read' });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
};

// Archive notifications
const archiveNotifications = async (req, res) => {
  try {
    const { notificationIds } = req.body;
    await notificationService.archiveNotifications(notificationIds, req.user._id);
    res.json({ message: 'Notifications archived' });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
};

// Get event recommendations
const getRecommendations = async (req, res) => {
  try {
    await notificationService.sendEventRecommendations(req.user);
    res.json({ message: 'Recommendations generated' });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
};

module.exports = {
  getNotifications,
  markAsRead,
  archiveNotifications,
  getRecommendations,
};
