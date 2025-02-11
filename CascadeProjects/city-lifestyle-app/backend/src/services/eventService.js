const { Event } = require('../models/event');
const { Place } = require('../models/place');
const cacheService = require('./cacheService');
const logger = require('../utils/logger');
const { NotFoundError, ValidationError } = require('../utils/errors');
const analyticsService = require('./analyticsService');
const notificationService = require('./notificationService');
const searchService = require('./searchService');

class EventService {
  constructor() {
    this.cacheKeyPrefix = 'event:';
    this.searchIndex = 'events';
  }

  async createEvent(eventData) {
    try {
      // Validate place exists
      const place = await Place.findById(eventData.placeId);
      if (!place) {
        throw new ValidationError('Invalid place ID');
      }

      // Create event
      const event = new Event(eventData);
      await event.save();

      // Index for search
      await searchService.indexDocument(this.searchIndex, {
        id: event._id,
        title: event.title,
        description: event.description,
        placeId: event.placeId,
        category: event.category,
        tags: event.tags,
        startTime: event.startTime,
        location: place.location
      });

      // Cache event
      await this._cacheEvent(event);

      // Track analytics
      analyticsService.trackEvent('event_created', {
        eventId: event._id,
        placeId: event.placeId,
        category: event.category
      });

      return event;
    } catch (error) {
      logger.error('Error creating event:', error);
      throw error;
    }
  }

  async updateEvent(eventId, updates) {
    try {
      const event = await Event.findById(eventId);
      if (!event) {
        throw new NotFoundError('Event not found');
      }

      // Update event
      Object.assign(event, updates);
      await event.save();

      // Update search index
      await searchService.updateDocument(this.searchIndex, eventId, {
        title: event.title,
        description: event.description,
        category: event.category,
        tags: event.tags,
        startTime: event.startTime
      });

      // Update cache
      await this._cacheEvent(event);

      // Notify attendees if significant changes
      if (this._hasSignificantChanges(updates)) {
        await notificationService.notifyEventUpdated(event);
      }

      return event;
    } catch (error) {
      logger.error('Error updating event:', error);
      throw error;
    }
  }

  async deleteEvent(eventId) {
    try {
      const event = await Event.findById(eventId);
      if (!event) {
        throw new NotFoundError('Event not found');
      }

      // Delete event
      await event.remove();

      // Remove from search index
      await searchService.deleteDocument(this.searchIndex, eventId);

      // Remove from cache
      await cacheService.delete(`${this.cacheKeyPrefix}${eventId}`);

      // Notify attendees
      await notificationService.notifyEventCancelled(event);

      return true;
    } catch (error) {
      logger.error('Error deleting event:', error);
      throw error;
    }
  }

  async getEvent(eventId) {
    try {
      // Try cache first
      const cachedEvent = await cacheService.get(`${this.cacheKeyPrefix}${eventId}`);
      if (cachedEvent) {
        return cachedEvent;
      }

      // Get from database
      const event = await Event.findById(eventId)
        .populate('placeId', 'name location')
        .populate('organizerId', 'name avatar');

      if (!event) {
        throw new NotFoundError('Event not found');
      }

      // Cache event
      await this._cacheEvent(event);

      // Track view
      analyticsService.trackEventView(eventId);

      return event;
    } catch (error) {
      logger.error('Error getting event:', error);
      throw error;
    }
  }

  async listEvents(filters = {}) {
    try {
      const query = this._buildQuery(filters);
      const events = await Event.find(query)
        .populate('placeId', 'name location')
        .populate('organizerId', 'name avatar')
        .sort({ startTime: 1 })
        .limit(filters.limit || 20)
        .skip(filters.offset || 0);

      return events;
    } catch (error) {
      logger.error('Error listing events:', error);
      throw error;
    }
  }

  async searchEvents(searchQuery) {
    try {
      const results = await searchService.search(this.searchIndex, searchQuery);
      const eventIds = results.map(result => result._id);

      const events = await Event.find({ _id: { $in: eventIds } })
        .populate('placeId', 'name location')
        .populate('organizerId', 'name avatar');

      return events;
    } catch (error) {
      logger.error('Error searching events:', error);
      throw error;
    }
  }

  async publishEvent(eventId) {
    try {
      const event = await Event.findById(eventId);
      if (!event) {
        throw new NotFoundError('Event not found');
      }

      event.status = 'published';
      await event.save();

      // Notify followers
      await notificationService.notifyEventPublished(event);

      return event;
    } catch (error) {
      logger.error('Error publishing event:', error);
      throw error;
    }
  }

  async cancelEvent(eventId) {
    try {
      const event = await Event.findById(eventId);
      if (!event) {
        throw new NotFoundError('Event not found');
      }

      event.status = 'cancelled';
      await event.save();

      // Notify attendees
      await notificationService.notifyEventCancelled(event);

      return event;
    } catch (error) {
      logger.error('Error cancelling event:', error);
      throw error;
    }
  }

  // Private methods
  async _cacheEvent(event) {
    await cacheService.set(
      `${this.cacheKeyPrefix}${event._id}`,
      event,
      3600 // 1 hour
    );
  }

  _buildQuery(filters) {
    const query = {};

    if (filters.category) {
      query.category = filters.category;
    }

    if (filters.tags) {
      query.tags = { $in: filters.tags };
    }

    if (filters.startDate) {
      query.startTime = { $gte: new Date(filters.startDate) };
    }

    if (filters.endDate) {
      query.endTime = { $lte: new Date(filters.endDate) };
    }

    if (filters.status) {
      query.status = filters.status;
    }

    if (filters.placeId) {
      query.placeId = filters.placeId;
    }

    if (filters.organizerId) {
      query.organizerId = filters.organizerId;
    }

    return query;
  }

  _hasSignificantChanges(updates) {
    const significantFields = ['startTime', 'endTime', 'location', 'status'];
    return Object.keys(updates).some(key => significantFields.includes(key));
  }
}

module.exports = new EventService();
