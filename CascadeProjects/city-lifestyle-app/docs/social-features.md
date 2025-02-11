# Social Features Documentation

## Overview
The social features system provides comprehensive social networking capabilities including user connections, activity feeds, content sharing, and social interactions.

## Current Implementation

### 1. Social Graph Service

```javascript
// backend/src/services/socialGraphService.js
class SocialGraphService {
  constructor(db, cache, notificationService) {
    this.db = db;
    this.cache = cache;
    this.notificationService = notificationService;
  }

  async getConnections(userId, filter = {}) {
    const cacheKey = `connections:${userId}`;
    
    // Try cache first
    const cached = await this.cache.get(cacheKey);
    if (cached) return JSON.parse(cached);
    
    // Get from database
    const connections = await this.db.connections.find({
      userId,
      status: 'accepted',
      ...filter
    }).populate('connectionId');
    
    // Cache results
    await this.cache.set(cacheKey, JSON.stringify(connections), 3600);
    
    return connections;
  }

  async sendConnectionRequest(fromUserId, toUserId) {
    // Check if connection already exists
    const existing = await this.db.connections.findOne({
      userId: fromUserId,
      connectionId: toUserId
    });

    if (existing) {
      throw new Error('Connection already exists');
    }

    // Create connection request
    const connection = await this.db.connections.create({
      userId: fromUserId,
      connectionId: toUserId,
      status: 'pending',
      createdAt: new Date()
    });

    // Notify user
    await this.notificationService.notify(toUserId, {
      type: 'connection_request',
      from: fromUserId,
      data: connection
    });

    return connection;
  }

  async acceptConnection(userId, connectionId) {
    const connection = await this.db.connections.findOneAndUpdate(
      {
        userId: connectionId,
        connectionId: userId,
        status: 'pending'
      },
      { status: 'accepted', updatedAt: new Date() },
      { new: true }
    );

    if (!connection) {
      throw new Error('Connection request not found');
    }

    // Create reverse connection
    await this.db.connections.create({
      userId,
      connectionId,
      status: 'accepted',
      createdAt: new Date()
    });

    // Invalidate cache
    await this.cache.del(`connections:${userId}`);
    await this.cache.del(`connections:${connectionId}`);

    // Notify users
    await this.notificationService.notify(connectionId, {
      type: 'connection_accepted',
      from: userId,
      data: connection
    });

    return connection;
  }

  async rejectConnection(userId, connectionId) {
    const connection = await this.db.connections.findOneAndUpdate(
      {
        userId: connectionId,
        connectionId: userId,
        status: 'pending'
      },
      { status: 'rejected', updatedAt: new Date() },
      { new: true }
    );

    if (!connection) {
      throw new Error('Connection request not found');
    }

    return connection;
  }

  async blockUser(userId, blockedUserId) {
    // Create or update block
    await this.db.blocks.findOneAndUpdate(
      { userId, blockedUserId },
      { createdAt: new Date() },
      { upsert: true }
    );

    // Remove any existing connections
    await this.db.connections.deleteMany({
      $or: [
        { userId, connectionId: blockedUserId },
        { userId: blockedUserId, connectionId: userId }
      ]
    });

    // Invalidate cache
    await this.cache.del(`connections:${userId}`);
    await this.cache.del(`connections:${blockedUserId}`);
  }

  async getRecommendations(userId, limit = 10) {
    // Get user's interests and location
    const user = await this.db.users.findById(userId);
    const userConnections = await this.getConnections(userId);
    const connectionIds = new Set(userConnections.map(c => c.connectionId.toString()));

    // Find users with similar interests
    const recommendations = await this.db.users.aggregate([
      {
        $match: {
          _id: { $ne: userId },
          _id: { $nin: Array.from(connectionIds) }
        }
      },
      {
        $geoNear: {
          near: user.location,
          distanceField: "distance",
          maxDistance: 50000 // 50km
        }
      },
      {
        $lookup: {
          from: "interests",
          localField: "interests",
          foreignField: "_id",
          as: "interests"
        }
      },
      {
        $addFields: {
          commonInterests: {
            $size: {
              $setIntersection: ["$interests", user.interests]
            }
          }
        }
      },
      {
        $sort: {
          commonInterests: -1,
          distance: 1
        }
      },
      {
        $limit: limit
      }
    ]);

    return recommendations;
  }
}
```

### 2. Activity Service

```javascript
// backend/src/services/activityService.js
class ActivityService {
  constructor(db, cache, pubsub) {
    this.db = db;
    this.cache = cache;
    this.pubsub = pubsub;
  }

  async createActivity(userId, data) {
    const activity = await this.db.activities.create({
      userId,
      ...data,
      createdAt: new Date()
    });

    // Publish activity to subscribers
    await this.pubsub.publish('new_activity', {
      userId,
      activity
    });

    // Invalidate feed cache
    await this.invalidateFeedCache(userId);

    return activity;
  }

  async getFeed(userId, page = 1, limit = 20) {
    const cacheKey = `feed:${userId}:${page}`;
    
    // Try cache first
    const cached = await this.cache.get(cacheKey);
    if (cached) return JSON.parse(cached);

    // Get user's connections
    const connections = await this.db.connections
      .find({ userId, status: 'accepted' })
      .select('connectionId');

    const connectionIds = connections.map(c => c.connectionId);

    // Get activities from user and connections
    const activities = await this.db.activities
      .find({
        userId: { $in: [...connectionIds, userId] },
        visibility: { $in: ['public', 'connections'] }
      })
      .sort({ createdAt: -1 })
      .skip((page - 1) * limit)
      .limit(limit)
      .populate('userId', 'name avatar');

    // Cache feed
    await this.cache.set(cacheKey, JSON.stringify(activities), 300);

    return activities;
  }

  async likeActivity(userId, activityId) {
    const like = await this.db.likes.create({
      userId,
      activityId,
      createdAt: new Date()
    });

    // Update activity like count
    await this.db.activities.updateOne(
      { _id: activityId },
      { $inc: { likeCount: 1 } }
    );

    // Notify activity owner
    const activity = await this.db.activities.findById(activityId);
    if (activity.userId.toString() !== userId) {
      await this.notificationService.notify(activity.userId, {
        type: 'activity_liked',
        from: userId,
        data: { activityId }
      });
    }

    return like;
  }

  async addComment(userId, activityId, content) {
    const comment = await this.db.comments.create({
      userId,
      activityId,
      content,
      createdAt: new Date()
    });

    // Update activity comment count
    await this.db.activities.updateOne(
      { _id: activityId },
      { $inc: { commentCount: 1 } }
    );

    // Notify activity owner
    const activity = await this.db.activities.findById(activityId);
    if (activity.userId.toString() !== userId) {
      await this.notificationService.notify(activity.userId, {
        type: 'activity_commented',
        from: userId,
        data: { activityId, comment }
      });
    }

    return comment;
  }

  async shareActivity(userId, activityId, data = {}) {
    const originalActivity = await this.db.activities.findById(activityId);
    
    const share = await this.createActivity(userId, {
      type: 'share',
      originalActivity: activityId,
      ...data
    });

    // Update original activity share count
    await this.db.activities.updateOne(
      { _id: activityId },
      { $inc: { shareCount: 1 } }
    );

    // Notify original activity owner
    if (originalActivity.userId.toString() !== userId) {
      await this.notificationService.notify(originalActivity.userId, {
        type: 'activity_shared',
        from: userId,
        data: { activityId, share }
      });
    }

    return share;
  }
}
```

### 3. Content Service

```javascript
// backend/src/services/contentService.js
class ContentService {
  constructor(db, storage, cache) {
    this.db = db;
    this.storage = storage;
    this.cache = cache;
  }

  async createContent(userId, data, files = []) {
    // Upload files
    const uploadedFiles = await Promise.all(
      files.map(file => this.storage.uploadFile(file))
    );

    // Create content
    const content = await this.db.contents.create({
      userId,
      ...data,
      files: uploadedFiles,
      createdAt: new Date()
    });

    // Create activity for the content
    await this.activityService.createActivity(userId, {
      type: 'content_created',
      contentId: content._id,
      visibility: data.visibility
    });

    return content;
  }

  async updateContent(userId, contentId, updates) {
    const content = await this.db.contents.findOneAndUpdate(
      { _id: contentId, userId },
      { ...updates, updatedAt: new Date() },
      { new: true }
    );

    if (!content) {
      throw new Error('Content not found or unauthorized');
    }

    // Invalidate cache
    await this.cache.del(`content:${contentId}`);

    return content;
  }

  async deleteContent(userId, contentId) {
    const content = await this.db.contents.findOne({
      _id: contentId,
      userId
    });

    if (!content) {
      throw new Error('Content not found or unauthorized');
    }

    // Delete associated files
    await Promise.all(
      content.files.map(file => this.storage.deleteFile(file.id))
    );

    // Delete content
    await this.db.contents.deleteOne({ _id: contentId });

    // Delete associated activities
    await this.db.activities.deleteMany({
      'data.contentId': contentId
    });

    // Invalidate cache
    await this.cache.del(`content:${contentId}`);
  }

  async getContent(contentId) {
    const cacheKey = `content:${contentId}`;
    
    // Try cache first
    const cached = await this.cache.get(cacheKey);
    if (cached) return JSON.parse(cached);

    // Get from database
    const content = await this.db.contents
      .findById(contentId)
      .populate('userId', 'name avatar');

    if (!content) {
      throw new Error('Content not found');
    }

    // Cache content
    await this.cache.set(cacheKey, JSON.stringify(content), 3600);

    return content;
  }

  async getUserContent(userId, filter = {}) {
    return this.db.contents
      .find({ userId, ...filter })
      .sort({ createdAt: -1 })
      .populate('userId', 'name avatar');
  }
}
```

## Implementation Status

### Completed Features
- [x] User Connections
  - Send/accept/reject connection requests
  - Block users
  - Connection recommendations
- [x] Activity Feed
  - Create activities
  - Like/comment/share
  - Feed generation
- [x] Content Management
  - Create/update/delete content
  - File uploads
  - Content visibility
- [x] Social Interactions
  - Comments system
  - Likes and reactions
  - Content sharing
- [x] Privacy Controls
  - Visibility settings
  - Blocking system
  - Content access control

### Remaining Implementation

#### 1. Enhanced Analytics

```javascript
// backend/src/services/socialAnalyticsService.js
class SocialAnalyticsService {
  async trackEngagement(userId, type, data) {
    await this.db.engagements.create({
      userId,
      type,
      data,
      timestamp: new Date()
    });
  }

  async getUserEngagementMetrics(userId, timeframe) {
    const metrics = await this.db.engagements.aggregate([
      {
        $match: {
          userId,
          timestamp: {
            $gte: new Date(Date.now() - timeframe)
          }
        }
      },
      {
        $group: {
          _id: '$type',
          count: { $sum: 1 }
        }
      }
    ]);

    return metrics;
  }

  async getContentPerformance(contentId) {
    const performance = await this.db.engagements.aggregate([
      {
        $match: {
          'data.contentId': contentId
        }
      },
      {
        $group: {
          _id: '$type',
          count: { $sum: 1 },
          uniqueUsers: { $addToSet: '$userId' }
        }
      }
    ]);

    return performance;
  }
}
```

#### 2. Advanced Recommendation Engine

```javascript
// backend/src/services/recommendationService.js
class RecommendationEngine {
  async generateRecommendations(userId) {
    const user = await this.db.users.findById(userId);
    
    // Get user's interests and behavior
    const interests = await this.getUserInterests(userId);
    const behavior = await this.getUserBehavior(userId);
    
    // Generate different types of recommendations
    const [
      contentRecs,
      connectionRecs,
      eventRecs
    ] = await Promise.all([
      this.getContentRecommendations(userId, interests, behavior),
      this.getConnectionRecommendations(userId, interests),
      this.getEventRecommendations(userId, interests, user.location)
    ]);

    return {
      content: contentRecs,
      connections: connectionRecs,
      events: eventRecs
    };
  }

  private async getContentRecommendations(userId, interests, behavior) {
    return this.db.contents.aggregate([
      {
        $match: {
          visibility: 'public',
          tags: { $in: interests }
        }
      },
      {
        $lookup: {
          from: 'engagements',
          localField: '_id',
          foreignField: 'contentId',
          as: 'engagements'
        }
      },
      {
        $addFields: {
          score: {
            $sum: [
              { $multiply: ['$likeCount', 1] },
              { $multiply: ['$commentCount', 2] },
              { $multiply: ['$shareCount', 3] }
            ]
          }
        }
      },
      {
        $sort: { score: -1 }
      },
      {
        $limit: 10
      }
    ]);
  }
}
```

## Implementation Timeline

### Week 1: Analytics Enhancement
- Implement engagement tracking
- Add performance metrics
- Create analytics dashboard
- Set up reporting

### Week 2: Recommendation System
- Build recommendation engine
- Add interest-based matching
- Implement behavior analysis
- Create personalization system

## Success Metrics
- User engagement increase > 30%
- Connection acceptance rate > 60%
- Content interaction rate > 40%
- Recommendation click-through > 25%

## Social Features Checklist
- [x] User connections
- [x] Activity feed
- [x] Content management
- [x] Social interactions
- [x] Privacy controls
- [ ] Enhanced analytics
- [ ] Advanced recommendations
- [ ] Engagement optimization
- [ ] Performance tracking
- [ ] A/B testing system
