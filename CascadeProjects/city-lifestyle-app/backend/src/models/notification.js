const mongoose = require('mongoose');

const notificationSchema = new mongoose.Schema({
  recipient: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
  },
  type: {
    type: String,
    enum: [
      'event_reminder',
      'event_update',
      'event_cancelled',
      'place_update',
      'place_review',
      'favorite_place_update',
      'registration_confirmed',
      'waitlist_promoted',
      'recommendation',
    ],
    required: true,
  },
  title: {
    type: String,
    required: true,
  },
  message: {
    type: String,
    required: true,
  },
  data: {
    // Additional data specific to notification type
    eventId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Event',
    },
    placeId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Place',
    },
  },
  priority: {
    type: String,
    enum: ['low', 'medium', 'high'],
    default: 'medium',
  },
  status: {
    type: String,
    enum: ['unread', 'read', 'archived'],
    default: 'unread',
  },
  createdAt: {
    type: Date,
    default: Date.now,
  },
  readAt: {
    type: Date,
  },
  expiresAt: {
    type: Date,
  },
});

// Index for querying user's notifications
notificationSchema.index({ recipient: 1, status: 1, createdAt: -1 });

// Index for cleaning up expired notifications
notificationSchema.index({ expiresAt: 1 }, { expireAfterSeconds: 0 });

// Mark notification as read
notificationSchema.methods.markAsRead = async function() {
  this.status = 'read';
  this.readAt = new Date();
  await this.save();
};

// Archive notification
notificationSchema.methods.archive = async function() {
  this.status = 'archived';
  await this.save();
};

const Notification = mongoose.model('Notification', notificationSchema);

module.exports = Notification;
