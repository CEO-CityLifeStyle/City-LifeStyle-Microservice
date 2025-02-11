const cron = require('node-cron');
const notificationService = require('./notificationService');
const User = require('../models/user');

class SchedulerService {
  constructor() {
    // Schedule event reminders to run every hour
    cron.schedule('0 * * * *', async () => {
      try {
        await notificationService.sendEventReminders();
      } catch (error) {
        console.error('Failed to send event reminders:', error);
      }
    });

    // Schedule event recommendations to run daily at 10 AM
    cron.schedule('0 10 * * *', async () => {
      try {
        const users = await User.find({
          'preferences.notificationSettings.eventReminders': true,
        });

        for (const user of users) {
          await notificationService.sendEventRecommendations(user);
        }
      } catch (error) {
        console.error('Failed to send event recommendations:', error);
      }
    });

    // Clean up old notifications weekly (keep last 3 months)
    cron.schedule('0 0 * * 0', async () => {
      try {
        const threeMonthsAgo = new Date();
        threeMonthsAgo.setMonth(threeMonthsAgo.getMonth() - 3);

        await Notification.deleteMany({
          status: 'archived',
          createdAt: { $lt: threeMonthsAgo },
        });
      } catch (error) {
        console.error('Failed to clean up old notifications:', error);
      }
    });
  }
}

module.exports = new SchedulerService();
