const { RSVP } = require('../models/rsvp');
const { Event } = require('../models/event');
const cacheService = require('./cacheService');
const logger = require('../utils/logger');
const { NotFoundError, ValidationError } = require('../utils/errors');
const analyticsService = require('./analyticsService');
const notificationService = require('./notificationService');

class RSVPService {
  constructor() {
    this.cacheKeyPrefix = 'rsvp:';
  }

  async createRSVP(eventId, userId, details) {
    try {
      // Get event
      const event = await Event.findById(eventId);
      if (!event) {
        throw new NotFoundError('Event not found');
      }

      // Check if user already has RSVP
      const existingRSVP = await RSVP.findOne({ eventId, userId });
      if (existingRSVP) {
        throw new ValidationError('User already has RSVP for this event');
      }

      // Validate ticket count
      if (details.ticketCount > event.settings.maxTicketsPerUser) {
        throw new ValidationError(`Cannot request more than ${event.settings.maxTicketsPerUser} tickets`);
      }

      // Check capacity
      const confirmedCount = event.attendees.confirmed.length;
      if (confirmedCount + details.ticketCount > event.capacity) {
        if (event.settings.allowWaitlist) {
          details.status = 'waitlisted';
        } else {
          throw new ValidationError('Event is at capacity');
        }
      }

      // Create RSVP
      const rsvp = new RSVP({
        eventId,
        userId,
        status: details.status || 'confirmed',
        ticketCount: details.ticketCount,
        notes: details.notes,
        timestamp: new Date()
      });

      await rsvp.save();

      // Update event attendees
      if (rsvp.status === 'confirmed') {
        event.attendees.confirmed.push(userId);
      } else if (rsvp.status === 'waitlisted') {
        event.attendees.waitlist.push(userId);
      }
      await event.save();

      // Cache RSVP
      await this._cacheRSVP(rsvp);

      // Track analytics
      analyticsService.trackRSVP(eventId, userId, rsvp.status);

      // Send notifications
      await notificationService.notifyRSVPCreated(rsvp, event);

      return rsvp;
    } catch (error) {
      logger.error('Error creating RSVP:', error);
      throw error;
    }
  }

  async updateRSVP(rsvpId, updates) {
    try {
      const rsvp = await RSVP.findById(rsvpId);
      if (!rsvp) {
        throw new NotFoundError('RSVP not found');
      }

      const event = await Event.findById(rsvp.eventId);
      if (!event) {
        throw new NotFoundError('Event not found');
      }

      // Handle status change
      if (updates.status && updates.status !== rsvp.status) {
        await this._handleStatusChange(rsvp, updates.status, event);
      }

      // Update RSVP
      Object.assign(rsvp, updates);
      await rsvp.save();

      // Update cache
      await this._cacheRSVP(rsvp);

      // Track update
      analyticsService.trackRSVPUpdate(rsvp.eventId, rsvp.userId, rsvp.status);

      return rsvp;
    } catch (error) {
      logger.error('Error updating RSVP:', error);
      throw error;
    }
  }

  async cancelRSVP(rsvpId) {
    try {
      const rsvp = await RSVP.findById(rsvpId);
      if (!rsvp) {
        throw new NotFoundError('RSVP not found');
      }

      const event = await Event.findById(rsvp.eventId);
      if (!event) {
        throw new NotFoundError('Event not found');
      }

      // Remove from event attendees
      if (rsvp.status === 'confirmed') {
        event.attendees.confirmed = event.attendees.confirmed.filter(id => id.toString() !== rsvp.userId.toString());
      } else if (rsvp.status === 'waitlisted') {
        event.attendees.waitlist = event.attendees.waitlist.filter(id => id.toString() !== rsvp.userId.toString());
      }
      await event.save();

      // Process waitlist if there was a confirmed spot
      if (rsvp.status === 'confirmed' && event.settings.allowWaitlist) {
        await this._processWaitlist(event);
      }

      // Delete RSVP
      await rsvp.remove();

      // Remove from cache
      await cacheService.delete(`${this.cacheKeyPrefix}${rsvpId}`);

      // Track cancellation
      analyticsService.trackRSVPCancellation(rsvp.eventId, rsvp.userId);

      return true;
    } catch (error) {
      logger.error('Error cancelling RSVP:', error);
      throw error;
    }
  }

  async getRSVP(rsvpId) {
    try {
      // Try cache first
      const cachedRSVP = await cacheService.get(`${this.cacheKeyPrefix}${rsvpId}`);
      if (cachedRSVP) {
        return cachedRSVP;
      }

      // Get from database
      const rsvp = await RSVP.findById(rsvpId)
        .populate('eventId', 'title startTime')
        .populate('userId', 'name avatar');

      if (!rsvp) {
        throw new NotFoundError('RSVP not found');
      }

      // Cache RSVP
      await this._cacheRSVP(rsvp);

      return rsvp;
    } catch (error) {
      logger.error('Error getting RSVP:', error);
      throw error;
    }
  }

  async listEventRSVPs(eventId, status) {
    try {
      const query = { eventId };
      if (status) {
        query.status = status;
      }

      const rsvps = await RSVP.find(query)
        .populate('userId', 'name avatar')
        .sort({ timestamp: 1 });

      return rsvps;
    } catch (error) {
      logger.error('Error listing event RSVPs:', error);
      throw error;
    }
  }

  async listUserRSVPs(userId, status) {
    try {
      const query = { userId };
      if (status) {
        query.status = status;
      }

      const rsvps = await RSVP.find(query)
        .populate('eventId', 'title startTime')
        .sort({ timestamp: -1 });

      return rsvps;
    } catch (error) {
      logger.error('Error listing user RSVPs:', error);
      throw error;
    }
  }

  // Private methods
  async _cacheRSVP(rsvp) {
    await cacheService.set(
      `${this.cacheKeyPrefix}${rsvp._id}`,
      rsvp,
      3600 // 1 hour
    );
  }

  async _handleStatusChange(rsvp, newStatus, event) {
    // Remove from old status list
    if (rsvp.status === 'confirmed') {
      event.attendees.confirmed = event.attendees.confirmed.filter(id => id.toString() !== rsvp.userId.toString());
    } else if (rsvp.status === 'waitlisted') {
      event.attendees.waitlist = event.attendees.waitlist.filter(id => id.toString() !== rsvp.userId.toString());
    }

    // Add to new status list
    if (newStatus === 'confirmed') {
      event.attendees.confirmed.push(rsvp.userId);
    } else if (newStatus === 'waitlisted') {
      event.attendees.waitlist.push(rsvp.userId);
    }

    await event.save();

    // Notify user of status change
    await notificationService.notifyRSVPStatusChanged(rsvp, newStatus);
  }

  async _processWaitlist(event) {
    if (event.attendees.waitlist.length === 0) {
      return;
    }

    const availableSpots = event.capacity - event.attendees.confirmed.length;
    if (availableSpots <= 0) {
      return;
    }

    // Get oldest waitlisted RSVPs
    const waitlistedRSVPs = await RSVP.find({
      eventId: event._id,
      status: 'waitlisted'
    }).sort({ timestamp: 1 }).limit(availableSpots);

    // Move to confirmed
    for (const rsvp of waitlistedRSVPs) {
      await this.updateRSVP(rsvp._id, { status: 'confirmed' });
    }
  }
}

module.exports = new RSVPService();
