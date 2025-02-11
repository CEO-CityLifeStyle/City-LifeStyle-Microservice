import { db } from '../config/database';
import { storage } from '../config/storage';
import { cache } from '../config/cache';
import { pubsub } from '../config/pubsub';
import { logger } from '../utils/logger';
import { NotFoundError, ValidationError } from '../utils/errors';
import { activityService } from './activityService';

class ContentService {
  constructor() {
    this.collection = db.collection('content');
    this.CACHE_TTL = 3600; // 1 hour
  }

  /**
   * Create new content
   */
  async createContent(userId, type, content, metadata = {}, visibility = 'public') {
    const contentItem = {
      userId,
      type,
      content,
      metadata,
      visibility,
      createdAt: new Date(),
      updatedAt: new Date(),
      stats: {
        views: 0,
        likes: 0,
        comments: 0,
        shares: 0
      }
    };

    await this.collection.insertOne(contentItem);

    // Create activity for the new content
    await activityService.createActivity(
      userId,
      'content_created',
      contentItem._id,
      'content',
      { contentType: type },
      visibility
    );

    // Publish event
    await pubsub.publish('content.created', { content: contentItem });

    return contentItem;
  }

  /**
   * Update content
   */
  async updateContent(contentId, userId, updates) {
    const content = await this.collection.findOne({ _id: contentId });
    if (!content) {
      throw new NotFoundError('Content not found');
    }

    if (content.userId !== userId) {
      throw new ValidationError('Unauthorized to update content');
    }

    const updatedContent = {
      ...content,
      ...updates,
      updatedAt: new Date()
    };

    await this.collection.updateOne(
      { _id: contentId },
      { $set: updatedContent }
    );

    // Invalidate cache
    await this.invalidateContentCache(contentId);

    // Publish event
    await pubsub.publish('content.updated', { content: updatedContent });

    return updatedContent;
  }

  /**
   * Get content by id
   */
  async getContent(contentId) {
    const cacheKey = `content:${contentId}`;
    const cached = await cache.get(cacheKey);

    if (cached) {
      return JSON.parse(cached);
    }

    const content = await this.collection.findOne({ _id: contentId });
    if (!content) {
      throw new NotFoundError('Content not found');
    }

    // Increment view count
    await this.collection.updateOne(
      { _id: contentId },
      { $inc: { 'stats.views': 1 } }
    );

    const enrichedContent = await this.enrichContent(content);
    await cache.set(cacheKey, JSON.stringify(enrichedContent), this.CACHE_TTL);
    return enrichedContent;
  }

  /**
   * Get user's content
   */
  async getUserContent(userId, type = null, page = 1, limit = 20) {
    const skip = (page - 1) * limit;
    const query = { userId };
    if (type) {
      query.type = type;
    }

    const content = await this.collection
      .find(query)
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(limit)
      .toArray();

    return Promise.all(content.map(item => this.enrichContent(item)));
  }

  /**
   * Upload media for content
   */
  async uploadMedia(userId, file, type = 'image') {
    const filename = `${userId}/${type}/${Date.now()}-${file.originalname}`;
    const fileBuffer = await file.buffer;

    // Upload to Cloud Storage
    const bucket = storage.bucket(process.env.MEDIA_BUCKET);
    const blob = bucket.file(filename);
    await blob.save(fileBuffer, {
      metadata: {
        contentType: file.mimetype
      }
    });

    // Make file public and get URL
    await blob.makePublic();
    const url = `https://storage.googleapis.com/${process.env.MEDIA_BUCKET}/${filename}`;

    return {
      url,
      filename,
      type: file.mimetype,
      size: file.size
    };
  }

  /**
   * Add interaction to content
   */
  async addInteraction(contentId, userId, type, metadata = {}) {
    const content = await this.collection.findOne({ _id: contentId });
    if (!content) {
      throw new NotFoundError('Content not found');
    }

    const interaction = {
      userId,
      type,
      metadata,
      createdAt: new Date()
    };

    await this.collection.updateOne(
      { _id: contentId },
      {
        $push: { interactions: interaction },
        $inc: { [`stats.${type}s`]: 1 }
      }
    );

    // Create activity for the interaction
    await activityService.createActivity(
      userId,
      `content_${type}d`,
      contentId,
      'content',
      metadata,
      'public'
    );

    // Invalidate cache
    await this.invalidateContentCache(contentId);

    // Publish event
    await pubsub.publish('content.interaction', {
      contentId,
      interaction
    });

    return interaction;
  }

  /**
   * Remove interaction from content
   */
  async removeInteraction(contentId, userId, type) {
    const content = await this.collection.findOne({ _id: contentId });
    if (!content) {
      throw new NotFoundError('Content not found');
    }

    await this.collection.updateOne(
      { _id: contentId },
      {
        $pull: { interactions: { userId, type } },
        $inc: { [`stats.${type}s`]: -1 }
      }
    );

    // Invalidate cache
    await this.invalidateContentCache(contentId);

    // Publish event
    await pubsub.publish('content.interactionRemoved', {
      contentId,
      userId,
      type
    });
  }

  /**
   * Enrich content with user data and interactions
   */
  async enrichContent(content) {
    const user = await db
      .collection('users')
      .findOne({ id: content.userId });

    return {
      ...content,
      user: {
        id: user.id,
        username: user.username,
        avatar: user.avatar
      }
    };
  }

  /**
   * Invalidate content cache
   */
  async invalidateContentCache(contentId) {
    await cache.del(`content:${contentId}`);
  }
}

export const contentService = new ContentService();
