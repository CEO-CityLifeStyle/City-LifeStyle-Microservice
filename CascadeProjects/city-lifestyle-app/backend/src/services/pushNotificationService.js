const webpush = require('web-push');
const User = require('../models/user');

class PushNotificationService {
  constructor() {
    // Configure web-push with VAPID keys
    webpush.setVapidDetails(
      `mailto:${process.env.VAPID_EMAIL}`,
      process.env.VAPID_PUBLIC_KEY,
      process.env.VAPID_PRIVATE_KEY
    );
  }

  // Save push subscription for a user
  async savePushSubscription(userId, subscription) {
    try {
      await User.findByIdAndUpdate(userId, {
        $set: { pushSubscription: subscription },
      });
    } catch (error) {
      throw new Error(`Failed to save push subscription: ${error.message}`);
    }
  }

  // Remove push subscription for a user
  async removePushSubscription(userId) {
    try {
      await User.findByIdAndUpdate(userId, {
        $unset: { pushSubscription: 1 },
      });
    } catch (error) {
      throw new Error(`Failed to remove push subscription: ${error.message}`);
    }
  }

  // Send push notification to a specific user
  async sendPushNotification(userId, notification) {
    try {
      const user = await User.findById(userId);
      if (!user?.pushSubscription) return;

      const payload = JSON.stringify({
        title: notification.title,
        body: notification.message,
        icon: '/icon.png',
        badge: '/badge.png',
        data: {
          url: this._getNotificationUrl(notification),
          ...notification.data,
        },
      });

      await webpush.sendNotification(user.pushSubscription, payload);
    } catch (error) {
      if (error.statusCode === 410) {
        // Subscription has expired or is no longer valid
        await this.removePushSubscription(userId);
      }
      throw new Error(`Failed to send push notification: ${error.message}`);
    }
  }

  // Send push notification to multiple users
  async sendPushNotifications(userIds, notification) {
    const promises = userIds.map(userId =>
      this.sendPushNotification(userId, notification).catch(error => {
        console.error(`Failed to send push notification to user ${userId}:`, error);
      })
    );
    await Promise.all(promises);
  }

  // Get VAPID public key
  getVapidPublicKey() {
    return process.env.VAPID_PUBLIC_KEY;
  }

  // Helper method to generate notification URL
  _getNotificationUrl(notification) {
    const baseUrl = process.env.CLIENT_URL;
    switch (notification.type) {
      case 'event_reminder':
      case 'event_update':
      case 'event_cancelled':
        return `${baseUrl}/events/${notification.data.eventId}`;
      case 'place_update':
      case 'place_review':
        return `${baseUrl}/places/${notification.data.placeId}`;
      case 'recommendation':
        return `${baseUrl}/events`;
      default:
        return baseUrl;
    }
  }

  // Create notification payload
  createNotificationPayload(title, message, data = {}) {
    return {
      title,
      message,
      data,
      timestamp: new Date(),
    };
  }

  // Send event reminder push notification
  async sendEventReminderPush(event, user) {
    const notification = this.createNotificationPayload(
      'Event Reminder',
      `Don't forget! "${event.title}" starts in 24 hours.`,
      {
        type: 'event_reminder',
        eventId: event._id,
      }
    );
    await this.sendPushNotification(user._id, notification);
  }

  // Send place update push notification
  async sendPlaceUpdatePush(place, updateType, followers) {
    const notification = this.createNotificationPayload(
      'Place Update',
      `${place.name} has been updated with new ${updateType}.`,
      {
        type: 'place_update',
        placeId: place._id,
      }
    );
    await this.sendPushNotifications(
      followers.map(user => user._id),
      notification
    );
  }

  // Send event cancellation push notification
  async sendEventCancellationPush(event, registeredUsers) {
    const notification = this.createNotificationPayload(
      'Event Cancelled',
      `Unfortunately, "${event.title}" has been cancelled.`,
      {
        type: 'event_cancelled',
        eventId: event._id,
      }
    );
    await this.sendPushNotifications(
      registeredUsers.map(reg => reg.user),
      notification
    );
  }
}

module.exports = new PushNotificationService();
