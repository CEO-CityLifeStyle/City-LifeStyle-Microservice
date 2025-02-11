const User = require('../models/user');
const Event = require('../models/event');
const Place = require('../models/place');
const Review = require('../models/review');
const analyticsService = require('../services/analyticsService');

class AdminController {
  // Get dashboard overview
  async getDashboardOverview(req, res) {
    try {
      const overview = await analyticsService.getPlatformOverview();
      res.json(overview);
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  }

  // Get analytics data
  async getAnalytics(req, res) {
    try {
      const { startDate, endDate } = req.query;
      const start = startDate ? new Date(startDate) : new Date(Date.now() - 30 * 24 * 60 * 60 * 1000);
      const end = endDate ? new Date(endDate) : new Date();

      const [userAnalytics, eventAnalytics, placeAnalytics, reviewAnalytics] = await Promise.all([
        analyticsService.getUserAnalytics(start, end),
        analyticsService.getEventAnalytics(start, end),
        analyticsService.getPlaceAnalytics(start, end),
        analyticsService.getReviewAnalytics(start, end),
      ]);

      res.json({
        users: userAnalytics,
        events: eventAnalytics,
        places: placeAnalytics,
        reviews: reviewAnalytics,
      });
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  }

  // Manage users
  async getUsers(req, res) {
    try {
      const { page = 1, limit = 10, sort = '-createdAt', search, role, status } = req.query;

      const query = {};
      if (search) {
        query.$or = [
          { name: new RegExp(search, 'i') },
          { email: new RegExp(search, 'i') },
        ];
      }
      if (role) query.role = role;
      if (status) query.status = status;

      const users = await User.find(query)
        .sort(sort)
        .skip((page - 1) * limit)
        .limit(parseInt(limit))
        .select('-password');

      const total = await User.countDocuments(query);

      res.json({
        users,
        totalPages: Math.ceil(total / limit),
        currentPage: parseInt(page),
        total,
      });
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  }

  // Update user
  async updateUser(req, res) {
    try {
      const { userId } = req.params;
      const updates = req.body;

      // Prevent updating sensitive fields
      delete updates.password;
      delete updates.email;

      const user = await User.findByIdAndUpdate(
        userId,
        { $set: updates },
        { new: true }
      ).select('-password');

      if (!user) {
        return res.status(404).json({ error: 'User not found' });
      }

      res.json(user);
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  }

  // Manage events
  async getEvents(req, res) {
    try {
      const { page = 1, limit = 10, sort = '-createdAt', search, status, category } = req.query;

      const query = {};
      if (search) {
        query.$or = [
          { title: new RegExp(search, 'i') },
          { description: new RegExp(search, 'i') },
        ];
      }
      if (status) query.status = status;
      if (category) query.category = category;

      const events = await Event.find(query)
        .sort(sort)
        .skip((page - 1) * limit)
        .limit(parseInt(limit))
        .populate('organizer', 'name email');

      const total = await Event.countDocuments(query);

      res.json({
        events,
        totalPages: Math.ceil(total / limit),
        currentPage: parseInt(page),
        total,
      });
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  }

  // Update event
  async updateEvent(req, res) {
    try {
      const { eventId } = req.params;
      const updates = req.body;

      const event = await Event.findByIdAndUpdate(
        eventId,
        { $set: updates },
        { new: true }
      ).populate('organizer', 'name email');

      if (!event) {
        return res.status(404).json({ error: 'Event not found' });
      }

      res.json(event);
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  }

  // Manage places
  async getPlaces(req, res) {
    try {
      const { page = 1, limit = 10, sort = '-createdAt', search, category } = req.query;

      const query = {};
      if (search) {
        query.$or = [
          { name: new RegExp(search, 'i') },
          { description: new RegExp(search, 'i') },
          { 'location.address': new RegExp(search, 'i') },
        ];
      }
      if (category) query.category = category;

      const places = await Place.find(query)
        .sort(sort)
        .skip((page - 1) * limit)
        .limit(parseInt(limit))
        .populate('owner', 'name email');

      const total = await Place.countDocuments(query);

      res.json({
        places,
        totalPages: Math.ceil(total / limit),
        currentPage: parseInt(page),
        total,
      });
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  }

  // Update place
  async updatePlace(req, res) {
    try {
      const { placeId } = req.params;
      const updates = req.body;

      const place = await Place.findByIdAndUpdate(
        placeId,
        { $set: updates },
        { new: true }
      ).populate('owner', 'name email');

      if (!place) {
        return res.status(404).json({ error: 'Place not found' });
      }

      res.json(place);
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  }

  // Manage reviews
  async getReviews(req, res) {
    try {
      const { page = 1, limit = 10, sort = '-createdAt', status, rating } = req.query;

      const query = {};
      if (status) query.status = status;
      if (rating) query.rating = parseInt(rating);

      const reviews = await Review.find(query)
        .sort(sort)
        .skip((page - 1) * limit)
        .limit(parseInt(limit))
        .populate('user', 'name email')
        .populate('place', 'name');

      const total = await Review.countDocuments(query);

      res.json({
        reviews,
        totalPages: Math.ceil(total / limit),
        currentPage: parseInt(page),
        total,
      });
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  }

  // Moderate review
  async moderateReview(req, res) {
    try {
      const { reviewId } = req.params;
      const { status, moderationNote } = req.body;

      const review = await Review.findByIdAndUpdate(
        reviewId,
        {
          $set: {
            status,
            moderationNote,
            moderatedAt: new Date(),
            moderatedBy: req.user._id,
          },
        },
        { new: true }
      )
        .populate('user', 'name email')
        .populate('place', 'name');

      if (!review) {
        return res.status(404).json({ error: 'Review not found' });
      }

      // Update place rating if review status changed
      if (status === 'approved' || status === 'rejected') {
        const stats = await Review.getAverageRating(review.place);
        await Place.findByIdAndUpdate(review.place, {
          rating: stats.averageRating,
          totalReviews: stats.totalReviews,
        });
      }

      res.json(review);
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  }

  // Get user activity
  async getUserActivity(req, res) {
    try {
      const { userId } = req.params;
      const metrics = await analyticsService.getUserEngagementMetrics(userId);
      res.json(metrics);
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  }

  // Get system health
  async getSystemHealth(req, res) {
    try {
      const health = {
        status: 'healthy',
        timestamp: new Date(),
        services: {
          database: mongoose.connection.readyState === 1 ? 'connected' : 'disconnected',
          storage: await this._checkStorageHealth(),
          cache: await this._checkCacheHealth(),
        },
        metrics: {
          memory: process.memoryUsage(),
          uptime: process.uptime(),
        },
      };

      res.json(health);
    } catch (error) {
      res.status(500).json({
        status: 'unhealthy',
        error: error.message,
        timestamp: new Date(),
      });
    }
  }

  // Helper methods
  async _checkStorageHealth() {
    try {
      await Storage.bucket(process.env.GOOGLE_CLOUD_BUCKET).exists();
      return 'connected';
    } catch (error) {
      return 'disconnected';
    }
  }

  async _checkCacheHealth() {
    try {
      // Implement cache health check based on your caching solution
      return 'connected';
    } catch (error) {
      return 'disconnected';
    }
  }
}

module.exports = new AdminController();
