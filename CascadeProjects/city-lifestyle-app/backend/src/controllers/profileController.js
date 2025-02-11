const { HttpException } = require('../utils/errors');
const avatarService = require('../services/avatarService');
const User = require('../models/user');
const Review = require('../models/review');
const Place = require('../models/place');
const Event = require('../models/event');
const { validateEmail } = require('../utils/validators');
const { redisClient } = require('../config/redis');

class ProfileController {
  async getProfile(req, res) {
    const userId = req.user.id;
    const cacheKey = `profile:${userId}`;

    // Try to get from cache first
    const cachedProfile = await redisClient.get(cacheKey);
    if (cachedProfile) {
      return res.json(JSON.parse(cachedProfile));
    }

    const user = await User.findById(userId).select('-password');
    if (!user) {
      throw new HttpException(404, 'User not found');
    }

    // Get user stats
    const stats = await this.getUserStats(userId);
    const profile = {
      ...user.toJSON(),
      stats,
    };

    // Cache for 5 minutes
    await redisClient.setex(cacheKey, 300, JSON.stringify(profile));

    res.json(profile);
  }

  async updateProfile(req, res) {
    const userId = req.user.id;
    const { name, email, bio, privacy } = req.body;

    // Validate email if provided
    if (email) {
      if (!validateEmail(email)) {
        throw new HttpException(400, 'Invalid email format');
      }

      // Check if email is already taken
      const existingUser = await User.findOne({ email, _id: { $ne: userId } });
      if (existingUser) {
        throw new HttpException(400, 'Email is already taken');
      }
    }

    // Update user
    const updatedUser = await User.findByIdAndUpdate(
      userId,
      {
        $set: {
          ...(name && { name }),
          ...(email && { email }),
          ...(bio && { bio }),
          ...(privacy && { privacy }),
          updatedAt: new Date(),
        },
      },
      { new: true, runValidators: true }
    ).select('-password');

    if (!updatedUser) {
      throw new HttpException(404, 'User not found');
    }

    // Invalidate cache
    await redisClient.del(`profile:${userId}`);

    res.json(updatedUser);
  }

  async updateAvatar(req, res) {
    const userId = req.user.id;
    const { file } = req;

    // Validate file
    await avatarService.validateImage(file);

    // Upload and optimize avatar
    const avatar = await avatarService.uploadAvatar(userId, file.buffer);

    // Update user with new avatar URLs
    const updatedUser = await User.findByIdAndUpdate(
      userId,
      {
        $set: {
          avatar: avatar.urls,
          avatarId: avatar.avatarId,
          updatedAt: new Date(),
        },
      },
      { new: true }
    ).select('-password');

    // Delete old avatar if exists
    if (updatedUser.avatarId && updatedUser.avatarId !== avatar.avatarId) {
      await avatarService.deleteAvatar(userId, updatedUser.avatarId);
    }

    // Invalidate cache
    await redisClient.del(`profile:${userId}`);

    res.json(updatedUser);
  }

  async deleteAvatar(req, res) {
    const userId = req.user.id;
    const user = await User.findById(userId);

    if (!user || !user.avatarId) {
      throw new HttpException(404, 'Avatar not found');
    }

    // Delete avatar files
    await avatarService.deleteAvatar(userId, user.avatarId);

    // Update user
    const updatedUser = await User.findByIdAndUpdate(
      userId,
      {
        $unset: { avatar: 1, avatarId: 1 },
        $set: { updatedAt: new Date() },
      },
      { new: true }
    ).select('-password');

    // Invalidate cache
    await redisClient.del(`profile:${userId}`);

    res.json(updatedUser);
  }

  async getUserStats(userId) {
    const [reviewCount, placesCount, eventsCount] = await Promise.all([
      Review.countDocuments({ userId }),
      Place.countDocuments({ userId }),
      Event.countDocuments({ userId }),
    ]);

    return {
      reviews: reviewCount,
      places: placesCount,
      events: eventsCount,
      lastActivity: new Date(),
    };
  }

  async getPrivacySettings(req, res) {
    const userId = req.user.id;
    const user = await User.findById(userId).select('privacy');

    if (!user) {
      throw new HttpException(404, 'User not found');
    }

    res.json(user.privacy || {});
  }

  async updatePrivacySettings(req, res) {
    const userId = req.user.id;
    const { privacy } = req.body;

    if (!privacy || typeof privacy !== 'object') {
      throw new HttpException(400, 'Invalid privacy settings');
    }

    const updatedUser = await User.findByIdAndUpdate(
      userId,
      {
        $set: {
          privacy,
          updatedAt: new Date(),
        },
      },
      { new: true }
    ).select('privacy');

    if (!updatedUser) {
      throw new HttpException(404, 'User not found');
    }

    // Invalidate cache
    await redisClient.del(`profile:${userId}`);

    res.json(updatedUser.privacy);
  }
}

module.exports = new ProfileController();
