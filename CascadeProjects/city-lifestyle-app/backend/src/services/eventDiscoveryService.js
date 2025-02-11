const { Event } = require('../models/event');
const { User } = require('../models/user');
const cacheService = require('./cacheService');
const logger = require('../utils/logger');
const analyticsService = require('./analyticsService');
const mlRecommendationService = require('./mlRecommendationService');
const searchService = require('./searchService');

class EventDiscoveryService {
  constructor() {
    this.cacheKeyPrefix = 'event-discovery:';
    this.searchIndex = 'events';
  }

  async getTrendingEvents(location, radius = 10000) {
    try {
      const cacheKey = `${this.cacheKeyPrefix}trending:${location.latitude}:${location.longitude}:${radius}`;
      
      // Try cache first
      const cachedEvents = await cacheService.get(cacheKey);
      if (cachedEvents) {
        return cachedEvents;
      }

      // Get events with high engagement in the area
      const events = await Event.aggregate([
        {
          $geoNear: {
            near: {
              type: "Point",
              coordinates: [location.longitude, location.latitude]
            },
            distanceField: "distance",
            maxDistance: radius,
            spherical: true
          }
        },
        {
          $match: {
            startTime: { $gte: new Date() },
            status: 'published'
          }
        },
        {
          $addFields: {
            engagementScore: {
              $add: [
                { $size: "$attendees.confirmed" },
                { $multiply: [{ $size: "$attendees.waitlist" }, 0.5] },
                { $divide: ["$metadata.views", 10] },
                { $multiply: ["$metadata.shares", 2] }
              ]
            }
          }
        },
        {
          $sort: { engagementScore: -1 }
        },
        {
          $limit: 20
        }
      ]);

      // Populate necessary fields
      await Event.populate(events, [
        { path: 'placeId', select: 'name location' },
        { path: 'organizerId', select: 'name avatar' }
      ]);

      // Cache results
      await cacheService.set(cacheKey, events, 900); // 15 minutes

      return events;
    } catch (error) {
      logger.error('Error getting trending events:', error);
      throw error;
    }
  }

  async getRecommendedEvents(userId) {
    try {
      const cacheKey = `${this.cacheKeyPrefix}recommended:${userId}`;
      
      // Try cache first
      const cachedEvents = await cacheService.get(cacheKey);
      if (cachedEvents) {
        return cachedEvents;
      }

      // Get user preferences and history
      const user = await User.findById(userId);
      const userRSVPs = await this._getUserEventHistory(userId);
      
      // Get ML recommendations
      const recommendedEventIds = await mlRecommendationService.getEventRecommendations(
        userId,
        user.preferences,
        userRSVPs
      );

      // Fetch recommended events
      const events = await Event.find({
        _id: { $in: recommendedEventIds },
        startTime: { $gte: new Date() },
        status: 'published'
      })
      .populate('placeId', 'name location')
      .populate('organizerId', 'name avatar')
      .limit(20);

      // Cache results
      await cacheService.set(cacheKey, events, 3600); // 1 hour

      return events;
    } catch (error) {
      logger.error('Error getting recommended events:', error);
      throw error;
    }
  }

  async getNearbyEvents(location, radius = 5000) {
    try {
      const cacheKey = `${this.cacheKeyPrefix}nearby:${location.latitude}:${location.longitude}:${radius}`;
      
      // Try cache first
      const cachedEvents = await cacheService.get(cacheKey);
      if (cachedEvents) {
        return cachedEvents;
      }

      // Get nearby events
      const events = await Event.find({
        location: {
          $near: {
            $geometry: {
              type: "Point",
              coordinates: [location.longitude, location.latitude]
            },
            $maxDistance: radius
          }
        },
        startTime: { $gte: new Date() },
        status: 'published'
      })
      .populate('placeId', 'name location')
      .populate('organizerId', 'name avatar')
      .limit(50);

      // Cache results
      await cacheService.set(cacheKey, events, 300); // 5 minutes

      return events;
    } catch (error) {
      logger.error('Error getting nearby events:', error);
      throw error;
    }
  }

  async getEventsByCategory(category, location = null) {
    try {
      const query = {
        category,
        startTime: { $gte: new Date() },
        status: 'published'
      };

      if (location) {
        query.location = {
          $near: {
            $geometry: {
              type: "Point",
              coordinates: [location.longitude, location.latitude]
            }
          }
        };
      }

      const events = await Event.find(query)
        .populate('placeId', 'name location')
        .populate('organizerId', 'name avatar')
        .sort('startTime')
        .limit(50);

      return events;
    } catch (error) {
      logger.error('Error getting events by category:', error);
      throw error;
    }
  }

  async searchEventsByTags(tags, location = null) {
    try {
      const searchQuery = {
        bool: {
          must: [
            { terms: { tags: tags } },
            { range: { startTime: { gte: 'now' } } },
            { term: { status: 'published' } }
          ]
        }
      };

      if (location) {
        searchQuery.bool.must.push({
          geo_distance: {
            distance: '10km',
            location: {
              lat: location.latitude,
              lon: location.longitude
            }
          }
        });
      }

      const results = await searchService.search(this.searchIndex, searchQuery);
      const eventIds = results.map(result => result._id);

      const events = await Event.find({ _id: { $in: eventIds } })
        .populate('placeId', 'name location')
        .populate('organizerId', 'name avatar');

      return events;
    } catch (error) {
      logger.error('Error searching events by tags:', error);
      throw error;
    }
  }

  // Private methods
  async _getUserEventHistory(userId) {
    const rsvps = await RSVP.find({ userId })
      .sort('-timestamp')
      .limit(50)
      .populate('eventId', 'category tags');

    return rsvps.map(rsvp => ({
      category: rsvp.eventId.category,
      tags: rsvp.eventId.tags,
      status: rsvp.status,
      timestamp: rsvp.timestamp
    }));
  }
}

module.exports = new EventDiscoveryService();
