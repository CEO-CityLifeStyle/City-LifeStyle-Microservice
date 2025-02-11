const logger = require('../config/logger');
const { notificationQueue } = require('../config/bull');
const { sendPushNotification } = require('../services/notificationService');

notificationQueue.process(async (job) => {
  const { userId, title, message, data } = job.data;
  
  try {
    await sendPushNotification(userId, { title, message, data });
    logger.info(`Push notification sent to user ${userId}`);
  } catch (error) {
    logger.error('Push notification failed:', error);
    throw error; // Retry job
  }
});
