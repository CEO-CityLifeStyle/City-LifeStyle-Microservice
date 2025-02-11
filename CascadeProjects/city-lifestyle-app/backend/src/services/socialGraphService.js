import { db } from '../config/database';
import { cache } from '../config/cache';
import { pubsub } from '../config/pubsub';
import { logger } from '../utils/logger';
import { NotFoundError, ValidationError } from '../utils/errors';

class SocialGraphService {
  constructor() {
    this.collection = db.collection('connections');
    this.userCollection = db.collection('users');
    this.CACHE_TTL = 3600; // 1 hour
  }

  /**
   * Create a new connection request
   */
  async createConnection(userId, targetUserId, type = 'friend') {
    // Validate users exist
    const [user, targetUser] = await Promise.all([
      this.userCollection.findOne({ id: userId }),
      this.userCollection.findOne({ id: targetUserId })
    ]);

    if (!user || !targetUser) {
      throw new NotFoundError('User not found');
    }

    // Check if connection already exists
    const existingConnection = await this.collection.findOne({
      $or: [
        { userId, connectionId: targetUserId },
        { userId: targetUserId, connectionId: userId }
      ]
    });

    if (existingConnection) {
      throw new ValidationError('Connection already exists');
    }

    // Create connection
    const connection = {
      userId,
      connectionId: targetUserId,
      status: 'pending',
      type,
      createdAt: new Date(),
      updatedAt: new Date(),
      metadata: {
        mutualConnections: await this.getMutualConnectionsCount(userId, targetUserId),
        lastInteraction: new Date()
      }
    };

    await this.collection.insertOne(connection);

    // Invalidate cache
    await this.invalidateConnectionCache(userId);
    await this.invalidateConnectionCache(targetUserId);

    // Publish event
    await pubsub.publish('connection.created', { connection });

    return connection;
  }

  /**
   * Update connection status
   */
  async updateConnectionStatus(userId, connectionId, status) {
    const connection = await this.collection.findOne({
      connectionId: userId,
      userId: connectionId,
      status: 'pending'
    });

    if (!connection) {
      throw new NotFoundError('Connection request not found');
    }

    await this.collection.updateOne(
      { _id: connection._id },
      {
        $set: {
          status,
          updatedAt: new Date()
        }
      }
    );

    // If accepted, create reverse connection
    if (status === 'accepted') {
      await this.collection.insertOne({
        userId,
        connectionId,
        status: 'accepted',
        type: connection.type,
        createdAt: new Date(),
        updatedAt: new Date(),
        metadata: {
          mutualConnections: connection.metadata.mutualConnections,
          lastInteraction: new Date()
        }
      });
    }

    // Invalidate cache
    await this.invalidateConnectionCache(userId);
    await this.invalidateConnectionCache(connectionId);

    // Publish event
    await pubsub.publish('connection.updated', {
      connection: { ...connection, status }
    });

    return { ...connection, status };
  }

  /**
   * Get user's connections
   */
  async getConnections(userId, status = 'accepted', page = 1, limit = 20) {
    const cacheKey = `connections:${userId}:${status}:${page}:${limit}`;
    const cached = await cache.get(cacheKey);

    if (cached) {
      return JSON.parse(cached);
    }

    const skip = (page - 1) * limit;
    const connections = await this.collection
      .find({ userId, status })
      .skip(skip)
      .limit(limit)
      .toArray();

    // Get connected user details
    const userIds = connections.map(c => c.connectionId);
    const users = await this.userCollection
      .find({ id: { $in: userIds } })
      .toArray();

    const result = connections.map(conn => ({
      ...conn,
      user: users.find(u => u.id === conn.connectionId)
    }));

    await cache.set(cacheKey, JSON.stringify(result), this.CACHE_TTL);
    return result;
  }

  /**
   * Get mutual connections count
   */
  async getMutualConnectionsCount(userId1, userId2) {
    const [user1Connections, user2Connections] = await Promise.all([
      this.collection
        .find({ userId: userId1, status: 'accepted' })
        .toArray(),
      this.collection
        .find({ userId: userId2, status: 'accepted' })
        .toArray()
    ]);

    const user1ConnectionIds = user1Connections.map(c => c.connectionId);
    const user2ConnectionIds = user2Connections.map(c => c.connectionId);

    return user1ConnectionIds.filter(id => user2ConnectionIds.includes(id)).length;
  }

  /**
   * Get connection recommendations
   */
  async getConnectionRecommendations(userId, limit = 10) {
    const cacheKey = `connection_recommendations:${userId}:${limit}`;
    const cached = await cache.get(cacheKey);

    if (cached) {
      return JSON.parse(cached);
    }

    // Get user's current connections
    const userConnections = await this.collection
      .find({ userId, status: 'accepted' })
      .toArray();

    const connectionIds = userConnections.map(c => c.connectionId);

    // Get connections of connections
    const connectionsOfConnections = await this.collection
      .find({
        userId: { $in: connectionIds },
        status: 'accepted',
        connectionId: { $nin: [...connectionIds, userId] }
      })
      .toArray();

    // Count frequency of each potential connection
    const recommendationScores = {};
    connectionsOfConnections.forEach(conn => {
      recommendationScores[conn.connectionId] = (recommendationScores[conn.connectionId] || 0) + 1;
    });

    // Sort by score and get top recommendations
    const recommendations = Object.entries(recommendationScores)
      .sort(([, a], [, b]) => b - a)
      .slice(0, limit);

    // Get user details for recommendations
    const recommendedUserIds = recommendations.map(([id]) => id);
    const users = await this.userCollection
      .find({ id: { $in: recommendedUserIds } })
      .toArray();

    const result = recommendations.map(([id, score]) => ({
      user: users.find(u => u.id === id),
      mutualConnections: score
    }));

    await cache.set(cacheKey, JSON.stringify(result), this.CACHE_TTL);
    return result;
  }

  /**
   * Block a user
   */
  async blockUser(userId, targetUserId) {
    // Remove existing connections
    await this.collection.deleteMany({
      $or: [
        { userId, connectionId: targetUserId },
        { userId: targetUserId, connectionId: userId }
      ]
    });

    // Create block record
    const block = {
      userId,
      connectionId: targetUserId,
      status: 'blocked',
      type: 'block',
      createdAt: new Date(),
      updatedAt: new Date()
    };

    await this.collection.insertOne(block);

    // Invalidate cache
    await this.invalidateConnectionCache(userId);
    await this.invalidateConnectionCache(targetUserId);

    // Publish event
    await pubsub.publish('user.blocked', { block });

    return block;
  }

  /**
   * Check if user is blocked
   */
  async isBlocked(userId, targetUserId) {
    const block = await this.collection.findOne({
      userId,
      connectionId: targetUserId,
      status: 'blocked'
    });

    return !!block;
  }

  /**
   * Invalidate connection cache
   */
  async invalidateConnectionCache(userId) {
    const keys = await cache.keys(`connections:${userId}:*`);
    if (keys.length > 0) {
      await cache.del(keys);
    }
    await cache.del(`connection_recommendations:${userId}:*`);
  }
}

export const socialGraphService = new SocialGraphService();
