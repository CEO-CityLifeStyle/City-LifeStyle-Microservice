import { db } from '../config/database';
import { cache } from '../config/cache';
import { pubsub } from '../config/pubsub';
import { logger } from '../utils/logger';
import { NotFoundError } from '../utils/errors';
import { socialGraphService } from './socialGraphService';

class ActivityService {
  constructor() {
    this.collection = db.collection('activities');
    this.CACHE_TTL = 1800; // 30 minutes
  }

  /**
   * Create a new activity
   */
  async createActivity(userId, type, targetId, targetType, metadata = {}, visibility = 'public') {
    const activity = {
      userId,
      type,
      targetId,
      targetType,
      metadata,
      visibility,
      createdAt: new Date(),
      interactions: {
        likes: 0,
        comments: 0,
        shares: 0
      }
    };

    await this.collection.insertOne(activity);

    // Invalidate feed cache for user's connections
    const connections = await socialGraphService.getConnections(userId);
    await Promise.all(
      connections.map(conn => this.invalidateFeedCache(conn.connectionId))
    );

    // Publish event
    await pubsub.publish('activity.created', { activity });

    return activity;
  }

  /**
   * Get user's activity feed
   */
  async getFeed(userId, page = 1, limit = 20) {
    const cacheKey = `feed:${userId}:${page}:${limit}`;
    const cached = await cache.get(cacheKey);

    if (cached) {
      return JSON.parse(cached);
    }

    // Get user's connections
    const connections = await socialGraphService.getConnections(userId);
    const connectionIds = connections.map(conn => conn.connectionId);

    // Get activities from user and connections
    const skip = (page - 1) * limit;
    const activities = await this.collection
      .find({
        $or: [
          { userId: { $in: [...connectionIds, userId] } },
          { visibility: 'public' }
        ]
      })
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(limit)
      .toArray();

    // Enrich activities with user data
    const enrichedActivities = await this.enrichActivities(activities);

    await cache.set(cacheKey, JSON.stringify(enrichedActivities), this.CACHE_TTL);
    return enrichedActivities;
  }

  /**
   * Get user's activities
   */
  async getUserActivities(userId, page = 1, limit = 20) {
    const skip = (page - 1) * limit;
    const activities = await this.collection
      .find({ userId })
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(limit)
      .toArray();

    return this.enrichActivities(activities);
  }

  /**
   * Add interaction to activity
   */
  async addInteraction(activityId, userId, type, metadata = {}) {
    const activity = await this.collection.findOne({ _id: activityId });
    if (!activity) {
      throw new NotFoundError('Activity not found');
    }

    // Check if user is blocked
    const isBlocked = await socialGraphService.isBlocked(activity.userId, userId);
    if (isBlocked) {
      throw new Error('User is blocked');
    }

    const interaction = {
      userId,
      type,
      metadata,
      createdAt: new Date()
    };

    await this.collection.updateOne(
      { _id: activityId },
      {
        $push: { interactions: interaction },
        $inc: { [`interactions.${type}s`]: 1 }
      }
    );

    // Invalidate cache
    await this.invalidateFeedCache(activity.userId);

    // Publish event
    await pubsub.publish('activity.interaction', {
      activityId,
      interaction
    });

    return interaction;
  }

  /**
   * Remove interaction from activity
   */
  async removeInteraction(activityId, userId, type) {
    const activity = await this.collection.findOne({ _id: activityId });
    if (!activity) {
      throw new NotFoundError('Activity not found');
    }

    await this.collection.updateOne(
      { _id: activityId },
      {
        $pull: { interactions: { userId, type } },
        $inc: { [`interactions.${type}s`]: -1 }
      }
    );

    // Invalidate cache
    await this.invalidateFeedCache(activity.userId);

    // Publish event
    await pubsub.publish('activity.interactionRemoved', {
      activityId,
      userId,
      type
    });
  }

  /**
   * Enrich activities with user and target data
   */
  async enrichActivities(activities) {
    const userIds = [...new Set(activities.map(a => a.userId))];
    const users = await db
      .collection('users')
      .find({ id: { $in: userIds } })
      .toArray();

    const targetIds = activities.map(a => a.targetId);
    const targets = await this.getTargets(activities);

    return activities.map(activity => ({
      ...activity,
      user: users.find(u => u.id === activity.userId),
      target: targets[activity.targetId]
    }));
  }

  /**
   * Get target objects for activities
   */
  async getTargets(activities) {
    const targetsByType = activities.reduce((acc, activity) => {
      if (!acc[activity.targetType]) {
        acc[activity.targetType] = new Set();
      }
      acc[activity.targetType].add(activity.targetId);
      return acc;
    }, {});

    const targets = {};
    await Promise.all(
      Object.entries(targetsByType).map(async ([type, ids]) => {
        const collection = this.getCollectionForType(type);
        const items = await collection
          .find({ id: { $in: Array.from(ids) } })
          .toArray();
        items.forEach(item => {
          targets[item.id] = item;
        });
      })
    );

    return targets;
  }

  /**
   * Get collection for target type
   */
  getCollectionForType(type) {
    switch (type) {
      case 'place':
        return db.collection('places');
      case 'event':
        return db.collection('events');
      case 'user':
        return db.collection('users');
      case 'review':
        return db.collection('reviews');
      default:
        throw new Error(`Unknown target type: ${type}`);
    }
  }

  /**
   * Invalidate feed cache
   */
  async invalidateFeedCache(userId) {
    const keys = await cache.keys(`feed:${userId}:*`);
    if (keys.length > 0) {
      await cache.del(keys);
    }
  }
}

export const activityService = new ActivityService();
