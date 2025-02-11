const { Notification } = require('../models/notification');
const { User } = require('../models/user');
const { Event } = require('../models/event');
const { RSVP } = require('../models/rsvp');
const pushNotificationService = require('./pushNotificationService');
const emailService = require('./emailService');
const logger = require('../utils/logger');

class EventNotificationService {
  async notifyEventCreated(event) {
    try {
      // Get interested users (followers of organizer or place)
      const interestedUsers = await this._getInterestedUsers(event);

      // Create notifications
      const notifications = interestedUsers.map(userId => ({
        userId,
        type: 'event_created',
        title: 'New Event',
        message: `${event.title} has been created`,
        data: {
          eventId: event._id,
          placeId: event.placeId
        }
      }));

      await Notification.insertMany(notifications);

      // Send push notifications
      await this._sendPushNotifications(interestedUsers, {
        title: 'New Event',
        body: `${event.title} has been created`,
        data: {
          type: 'event_created',
          eventId: event._id.toString()
        }
      });

      // Send emails
      await this._sendEmails(interestedUsers, {
        subject: 'New Event: ' + event.title,
        template: 'event_created',
        data: {
          event: {
            title: event.title,
            description: event.description,
            startTime: event.startTime,
            location: event.location
          }
        }
      });
    } catch (error) {
      logger.error('Error sending event created notifications:', error);
      throw error;
    }
  }

  async notifyEventUpdated(event) {
    try {
      // Get all attendees
      const attendees = [
        ...event.attendees.confirmed,
        ...event.attendees.waitlist
      ];

      // Create notifications
      const notifications = attendees.map(userId => ({
        userId,
        type: 'event_updated',
        title: 'Event Updated',
        message: `${event.title} has been updated`,
        data: {
          eventId: event._id,
          placeId: event.placeId
        }
      }));

      await Notification.insertMany(notifications);

      // Send push notifications
      await this._sendPushNotifications(attendees, {
        title: 'Event Update',
        body: `${event.title} has been updated`,
        data: {
          type: 'event_updated',
          eventId: event._id.toString()
        }
      });

      // Send emails
      await this._sendEmails(attendees, {
        subject: 'Event Update: ' + event.title,
        template: 'event_updated',
        data: {
          event: {
            title: event.title,
            description: event.description,
            startTime: event.startTime,
            location: event.location,
            changes: event.changes // List of changed fields
          }
        }
      });
    } catch (error) {
      logger.error('Error sending event updated notifications:', error);
      throw error;
    }
  }

  async notifyEventCancelled(event) {
    try {
      // Get all attendees
      const attendees = [
        ...event.attendees.confirmed,
        ...event.attendees.waitlist
      ];

      // Create notifications
      const notifications = attendees.map(userId => ({
        userId,
        type: 'event_cancelled',
        title: 'Event Cancelled',
        message: `${event.title} has been cancelled`,
        data: {
          eventId: event._id,
          placeId: event.placeId
        }
      }));

      await Notification.insertMany(notifications);

      // Send push notifications
      await this._sendPushNotifications(attendees, {
        title: 'Event Cancelled',
        body: `${event.title} has been cancelled`,
        data: {
          type: 'event_cancelled',
          eventId: event._id.toString()
        }
      });

      // Send emails
      await this._sendEmails(attendees, {
        subject: 'Event Cancelled: ' + event.title,
        template: 'event_cancelled',
        data: {
          event: {
            title: event.title,
            startTime: event.startTime,
            refundInfo: event.refundInfo // If applicable
          }
        }
      });
    } catch (error) {
      logger.error('Error sending event cancelled notifications:', error);
      throw error;
    }
  }

  async notifyRSVPConfirmed(rsvp, event) {
    try {
      // Create notification
      const notification = new Notification({
        userId: rsvp.userId,
        type: 'rsvp_confirmed',
        title: 'RSVP Confirmed',
        message: `Your RSVP for ${event.title} has been confirmed`,
        data: {
          eventId: event._id,
          rsvpId: rsvp._id
        }
      });

      await notification.save();

      // Send push notification
      await this._sendPushNotifications([rsvp.userId], {
        title: 'RSVP Confirmed',
        body: `Your RSVP for ${event.title} has been confirmed`,
        data: {
          type: 'rsvp_confirmed',
          eventId: event._id.toString(),
          rsvpId: rsvp._id.toString()
        }
      });

      // Send email
      await this._sendEmails([rsvp.userId], {
        subject: 'RSVP Confirmed: ' + event.title,
        template: 'rsvp_confirmed',
        data: {
          event: {
            title: event.title,
            startTime: event.startTime,
            location: event.location
          },
          rsvp: {
            ticketCount: rsvp.ticketCount,
            qrCode: rsvp.qrCode // If using QR codes
          }
        }
      });
    } catch (error) {
      logger.error('Error sending RSVP confirmed notifications:', error);
      throw error;
    }
  }

  async notifyRSVPWaitlisted(rsvp, event) {
    try {
      // Create notification
      const notification = new Notification({
        userId: rsvp.userId,
        type: 'rsvp_waitlisted',
        title: 'Added to Waitlist',
        message: `You've been added to the waitlist for ${event.title}`,
        data: {
          eventId: event._id,
          rsvpId: rsvp._id
        }
      });

      await notification.save();

      // Send push notification
      await this._sendPushNotifications([rsvp.userId], {
        title: 'Added to Waitlist',
        body: `You've been added to the waitlist for ${event.title}`,
        data: {
          type: 'rsvp_waitlisted',
          eventId: event._id.toString(),
          rsvpId: rsvp._id.toString()
        }
      });

      // Send email
      await this._sendEmails([rsvp.userId], {
        subject: 'Waitlisted: ' + event.title,
        template: 'rsvp_waitlisted',
        data: {
          event: {
            title: event.title,
            startTime: event.startTime
          },
          rsvp: {
            position: await this._getWaitlistPosition(event._id, rsvp._id)
          }
        }
      });
    } catch (error) {
      logger.error('Error sending RSVP waitlisted notifications:', error);
      throw error;
    }
  }

  // Private methods
  async _getInterestedUsers(event) {
    // Get users who follow the organizer or place
    const [organizerFollowers, placeFollowers] = await Promise.all([
      User.find({ 'following.users': event.organizerId }).select('_id'),
      User.find({ 'following.places': event.placeId }).select('_id')
    ]);

    // Combine and deduplicate
    const interestedUsers = new Set([
      ...organizerFollowers.map(u => u._id.toString()),
      ...placeFollowers.map(u => u._id.toString())
    ]);

    return Array.from(interestedUsers);
  }

  async _sendPushNotifications(userIds, notification) {
    try {
      // Get user devices
      const users = await User.find({
        _id: { $in: userIds },
        'devices.token': { $exists: true }
      }).select('devices');

      // Send to each device
      const promises = users.flatMap(user =>
        user.devices.map(device =>
          pushNotificationService.sendNotification(device.token, notification)
        )
      );

      await Promise.allSettled(promises);
    } catch (error) {
      logger.error('Error sending push notifications:', error);
    }
  }

  async _sendEmails(userIds, emailData) {
    try {
      // Get user emails
      const users = await User.find({
        _id: { $in: userIds },
        email: { $exists: true }
      }).select('email preferences.notifications');

      // Send emails to users who haven't disabled email notifications
      const promises = users
        .filter(user => user.preferences.notifications.email)
        .map(user =>
          emailService.sendTemplateEmail(user.email, emailData)
        );

      await Promise.allSettled(promises);
    } catch (error) {
      logger.error('Error sending emails:', error);
    }
  }

  async _getWaitlistPosition(eventId, rsvpId) {
    const waitlistedRSVPs = await RSVP.find({
      eventId,
      status: 'waitlisted'
    }).sort('timestamp');

    return waitlistedRSVPs.findIndex(rsvp => rsvp._id.toString() === rsvpId.toString()) + 1;
  }
}

module.exports = new EventNotificationService();
