const Notification = require('../models/notification');
const Event = require('../models/event');
const Place = require('../models/place');
const User = require('../models/user');
const websocketService = require('./websocketService');
const pushNotificationService = require('./pushNotificationService');

class NotificationService {
  // Create a new notification
  async createNotification(data) {
    try {
      const notification = new Notification(data);
      await notification.save();

      // Send real-time notification via WebSocket
      if (websocketService.isUserConnected(data.recipient)) {
        websocketService.sendNotification(data.recipient, notification);
      }

      // Send push notification
      await pushNotificationService.sendPushNotification(data.recipient, {
        title: data.title,
        message: data.message,
        data: data.data,
      });

      return notification;
    } catch (error) {
      throw new Error(`Failed to create notification: ${error.message}`);
    }
  }

  // Send event reminder notifications
  async sendEventReminders() {
    try {
      const now = new Date();
      const oneDayFromNow = new Date(now.getTime() + 24 * 60 * 60 * 1000);

      // Find events starting within the next 24 hours
      const upcomingEvents = await Event.find({
        startDate: { $gte: now, $lte: oneDayFromNow },
        status: 'published',
      }).populate('registeredUsers.user');

      for (const event of upcomingEvents) {
        const registeredUsers = event.registeredUsers.filter(
          (reg) => reg.status === 'registered'
        );

        for (const registration of registeredUsers) {
          const user = registration.user;
          if (!user.preferences?.notificationSettings?.eventReminders) continue;

          const notification = await this.createNotification({
            recipient: user._id,
            type: 'event_reminder',
            title: 'Event Reminder',
            message: `Don't forget! "${event.title}" starts in 24 hours.`,
            data: { eventId: event._id },
            priority: 'high',
            expiresAt: event.startDate,
          });

          // Send push notification
          await pushNotificationService.sendEventReminderPush(event, user);
        }
      }
    } catch (error) {
      throw new Error(`Failed to send event reminders: ${error.message}`);
    }
  }

  // Send place update notifications to followers
  async sendPlaceUpdateNotification(place, updateType) {
    try {
      const followers = await User.find({
        favoritePlaces: place._id,
        'preferences.notificationSettings.placeUpdates': true,
      });

      const notifications = followers.map((user) => ({
        recipient: user._id,
        type: 'place_update',
        title: 'Place Update',
        message: `${place.name} has been updated with new ${updateType}.`,
        data: { placeId: place._id },
        priority: 'medium',
        expiresAt: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000), // 1 week
      }));

      await Notification.insertMany(notifications);

      // Send WebSocket updates
      const followerIds = followers.map((user) => user._id.toString());
      websocketService.sendPlaceUpdate(
        place._id,
        { type: updateType },
        followerIds
      );

      // Send push notifications
      await pushNotificationService.sendPlaceUpdatePush(
        place,
        updateType,
        followers
      );
    } catch (error) {
      throw new Error(`Failed to send place update notifications: ${error.message}`);
    }
  }

  // Send event cancellation notifications
  async sendEventCancellationNotifications(event) {
    try {
      const registeredUsers = event.registeredUsers.filter(
        (reg) => reg.status === 'registered' || reg.status === 'waitlist'
      );

      const notifications = registeredUsers.map((registration) => ({
        recipient: registration.user,
        type: 'event_cancelled',
        title: 'Event Cancelled',
        message: `Unfortunately, "${event.title}" has been cancelled.`,
        data: { eventId: event._id },
        priority: 'high',
        expiresAt: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000), // 1 week
      }));

      await Notification.insertMany(notifications);

      // Send WebSocket updates
      const userIds = registeredUsers.map((reg) => reg.user.toString());
      websocketService.sendEventUpdate(
        event._id,
        { status: 'cancelled' },
        userIds
      );

      // Send push notifications
      await pushNotificationService.sendEventCancellationPush(
        event,
        registeredUsers
      );
    } catch (error) {
      throw new Error(`Failed to send event cancellation notifications: ${error.message}`);
    }
  }

  // Send waitlist promotion notification
  async sendWaitlistPromotionNotification(event, user) {
    try {
      const notification = await this.createNotification({
        recipient: user._id,
        type: 'waitlist_promoted',
        title: 'Promoted from Waitlist',
        message: `Great news! You've been promoted from the waitlist for "${event.title}".`,
        data: { eventId: event._id },
        priority: 'high',
        expiresAt: event.startDate,
      });

      // Send WebSocket update
      websocketService.sendEventUpdate(
        event._id,
        { type: 'waitlist_promotion' },
        [user._id.toString()]
      );

      return notification;
    } catch (error) {
      throw new Error(`Failed to send waitlist promotion notification: ${error.message}`);
    }
  }

  // Send personalized event recommendations
  async sendEventRecommendations(user) {
    try {
      if (!user.preferences?.notificationSettings?.eventReminders) return;

      const userPreferences = user.preferences.categories || [];
      const now = new Date();

      // Find upcoming events matching user's preferences
      const recommendedEvents = await Event.find({
        category: { $in: userPreferences },
        startDate: { $gt: now },
        status: 'published',
        'registeredUsers.user': { $ne: user._id },
      })
        .limit(5)
        .sort('startDate');

      if (recommendedEvents.length === 0) return;

      const notification = await this.createNotification({
        recipient: user._id,
        type: 'recommendation',
        title: 'Event Recommendations',
        message: `We found ${recommendedEvents.length} events you might be interested in!`,
        data: {
          eventId: recommendedEvents.map((event) => event._id),
        },
        priority: 'low',
        expiresAt: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000), // 1 week
      });

      return notification;
    } catch (error) {
      throw new Error(`Failed to send event recommendations: ${error.message}`);
    }
  }

  // Get user's notifications
  async getUserNotifications(userId, status = 'unread', page = 1, limit = 20) {
    try {
      const notifications = await Notification.find({
        recipient: userId,
        status,
      })
        .sort('-createdAt')
        .skip((page - 1) * limit)
        .limit(limit)
        .populate('data.eventId')
        .populate('data.placeId');

      const total = await Notification.countDocuments({
        recipient: userId,
        status,
      });

      return {
        notifications,
        totalPages: Math.ceil(total / limit),
        currentPage: page,
        total,
      };
    } catch (error) {
      throw new Error(`Failed to get user notifications: ${error.message}`);
    }
  }

  // Mark notifications as read
  async markAsRead(notificationIds, userId) {
    try {
      await Notification.updateMany(
        {
          _id: { $in: notificationIds },
          recipient: userId,
        },
        {
          $set: {
            status: 'read',
            readAt: new Date(),
          },
        }
      );

      // Send WebSocket update
      websocketService.sendToUser(userId, {
        type: 'notifications_read',
        notificationIds,
      });
    } catch (error) {
      throw new Error(`Failed to mark notifications as read: ${error.message}`);
    }
  }

  // Archive notifications
  async archiveNotifications(notificationIds, userId) {
    try {
      await Notification.updateMany(
        {
          _id: { $in: notificationIds },
          recipient: userId,
        },
        {
          $set: {
            status: 'archived',
          },
        }
      );

      // Send WebSocket update
      websocketService.sendToUser(userId, {
        type: 'notifications_archived',
        notificationIds,
      });
    } catch (error) {
      throw new Error(`Failed to archive notifications: ${error.message}`);
    }
  }
}

module.exports = new NotificationService();
