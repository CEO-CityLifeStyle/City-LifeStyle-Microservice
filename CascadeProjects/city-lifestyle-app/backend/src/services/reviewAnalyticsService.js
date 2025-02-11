const Review = require('../models/review');
const Place = require('../models/place');
const User = require('../models/user');

class ReviewAnalyticsService {
  // Get review trends
  async getReviewTrends(startDate, endDate) {
    try {
      const pipeline = [
        {
          $match: {
            createdAt: { $gte: startDate, $lte: endDate },
          },
        },
        {
          $group: {
            _id: {
              year: { $year: '$createdAt' },
              month: { $month: '$createdAt' },
              day: { $dayOfMonth: '$createdAt' },
            },
            count: { $sum: 1 },
            averageRating: { $avg: '$rating' },
            totalComments: { $sum: { $size: '$replies' } },
            totalLikes: { $sum: { $size: '$likes' } },
            totalHelpful: { $sum: { $size: '$helpful' } },
          },
        },
        {
          $sort: { '_id.year': 1, '_id.month': 1, '_id.day': 1 },
        },
      ];

      return await Review.aggregate(pipeline);
    } catch (error) {
      throw new Error(`Failed to get review trends: ${error.message}`);
    }
  }

  // Get sentiment analysis
  async getSentimentAnalysis(startDate, endDate) {
    try {
      const pipeline = [
        {
          $match: {
            createdAt: { $gte: startDate, $lte: endDate },
          },
        },
        {
          $group: {
            _id: '$rating',
            count: { $sum: 1 },
            averageHelpful: { $avg: { $size: '$helpful' } },
            averageLikes: { $avg: { $size: '$likes' } },
            totalComments: { $sum: { $size: '$replies' } },
          },
        },
        { $sort: { _id: 1 } },
      ];

      return await Review.aggregate(pipeline);
    } catch (error) {
      throw new Error(`Failed to get sentiment analysis: ${error.message}`);
    }
  }

  // Get top reviewers
  async getTopReviewers(limit = 10) {
    try {
      const pipeline = [
        {
          $group: {
            _id: '$user',
            totalReviews: { $sum: 1 },
            averageRating: { $avg: '$rating' },
            totalHelpful: { $sum: { $size: '$helpful' } },
            totalLikes: { $sum: { $size: '$likes' } },
          },
        },
        {
          $sort: { totalHelpful: -1, totalReviews: -1 },
        },
        { $limit: limit },
        {
          $lookup: {
            from: 'users',
            localField: '_id',
            foreignField: '_id',
            as: 'user',
          },
        },
        {
          $unwind: '$user',
        },
        {
          $project: {
            _id: 1,
            totalReviews: 1,
            averageRating: 1,
            totalHelpful: 1,
            totalLikes: 1,
            'user.name': 1,
            'user.avatar': 1,
            'user.reputation': 1,
          },
        },
      ];

      return await Review.aggregate(pipeline);
    } catch (error) {
      throw new Error(`Failed to get top reviewers: ${error.message}`);
    }
  }

  // Get place review analytics
  async getPlaceReviewAnalytics(placeId) {
    try {
      const pipeline = [
        {
          $match: { place: placeId },
        },
        {
          $group: {
            _id: null,
            totalReviews: { $sum: 1 },
            averageRating: { $avg: '$rating' },
            ratingDistribution: {
              $push: '$rating',
            },
            totalHelpful: { $sum: { $size: '$helpful' } },
            totalLikes: { $sum: { $size: '$likes' } },
            totalComments: { $sum: { $size: '$replies' } },
          },
        },
        {
          $project: {
            _id: 0,
            totalReviews: 1,
            averageRating: 1,
            ratingDistribution: 1,
            totalHelpful: 1,
            totalLikes: 1,
            totalComments: 1,
          },
        },
      ];

      const result = await Review.aggregate(pipeline);
      return result[0] || null;
    } catch (error) {
      throw new Error(`Failed to get place review analytics: ${error.message}`);
    }
  }

  // Get review quality metrics
  async getReviewQualityMetrics(startDate, endDate) {
    try {
      const pipeline = [
        {
          $match: {
            createdAt: { $gte: startDate, $lte: endDate },
          },
        },
        {
          $group: {
            _id: null,
            totalReviews: { $sum: 1 },
            averageLength: { $avg: { $strLenCP: '$comment' } },
            withImages: {
              $sum: { $cond: [{ $gt: [{ $size: '$images' }, 0] }, 1, 0] },
            },
            withReplies: {
              $sum: { $cond: [{ $gt: [{ $size: '$replies' }, 0] }, 1, 0] },
            },
            flaggedReviews: {
              $sum: { $cond: [{ $gt: [{ $size: '$flags' }, 0] }, 1, 0] },
            },
          },
        },
        {
          $project: {
            _id: 0,
            totalReviews: 1,
            averageLength: 1,
            withImages: 1,
            withReplies: 1,
            flaggedReviews: 1,
            imagePercentage: {
              $multiply: [
                { $divide: ['$withImages', '$totalReviews'] },
                100,
              ],
            },
            replyPercentage: {
              $multiply: [
                { $divide: ['$withReplies', '$totalReviews'] },
                100,
              ],
            },
            flaggedPercentage: {
              $multiply: [
                { $divide: ['$flaggedReviews', '$totalReviews'] },
                100,
              ],
            },
          },
        },
      ];

      const result = await Review.aggregate(pipeline);
      return result[0] || null;
    } catch (error) {
      throw new Error(`Failed to get review quality metrics: ${error.message}`);
    }
  }

  // Get category insights
  async getCategoryInsights() {
    try {
      const pipeline = [
        {
          $lookup: {
            from: 'places',
            localField: 'place',
            foreignField: '_id',
            as: 'place',
          },
        },
        { $unwind: '$place' },
        {
          $group: {
            _id: '$place.category',
            totalReviews: { $sum: 1 },
            averageRating: { $avg: '$rating' },
            totalHelpful: { $sum: { $size: '$helpful' } },
            places: { $addToSet: '$place._id' },
          },
        },
        {
          $project: {
            _id: 1,
            totalReviews: 1,
            averageRating: 1,
            totalHelpful: 1,
            uniquePlaces: { $size: '$places' },
            averageHelpfulPerReview: {
              $divide: ['$totalHelpful', '$totalReviews'],
            },
          },
        },
        { $sort: { totalReviews: -1 } },
      ];

      return await Review.aggregate(pipeline);
    } catch (error) {
      throw new Error(`Failed to get category insights: ${error.message}`);
    }
  }

  // Get moderation metrics
  async getModerationMetrics(startDate, endDate) {
    try {
      const pipeline = [
        {
          $match: {
            createdAt: { $gte: startDate, $lte: endDate },
          },
        },
        {
          $group: {
            _id: '$status',
            count: { $sum: 1 },
            averageRating: { $avg: '$rating' },
            flaggedCount: {
              $sum: { $cond: [{ $gt: [{ $size: '$flags' }, 0] }, 1, 0] },
            },
          },
        },
        {
          $project: {
            status: '$_id',
            count: 1,
            averageRating: 1,
            flaggedCount: 1,
            flaggedPercentage: {
              $multiply: [
                { $divide: ['$flaggedCount', '$count'] },
                100,
              ],
            },
          },
        },
      ];

      return await Review.aggregate(pipeline);
    } catch (error) {
      throw new Error(`Failed to get moderation metrics: ${error.message}`);
    }
  }

  // Search reviews with advanced filters
  async searchReviews(filters, sort = { createdAt: -1 }, page = 1, limit = 10) {
    try {
      const query = {};

      // Apply filters
      if (filters.rating) {
        query.rating = parseInt(filters.rating);
      }
      if (filters.status) {
        query.status = filters.status;
      }
      if (filters.hasImages) {
        query['images.0'] = { $exists: true };
      }
      if (filters.hasReplies) {
        query['replies.0'] = { $exists: true };
      }
      if (filters.minHelpful) {
        query['helpful.0'] = { $exists: true };
        query.$expr = {
          $gte: [{ $size: '$helpful' }, parseInt(filters.minHelpful)],
        };
      }
      if (filters.dateRange) {
        query.createdAt = {
          $gte: new Date(filters.dateRange.start),
          $lte: new Date(filters.dateRange.end),
        };
      }
      if (filters.search) {
        query.$or = [
          { comment: new RegExp(filters.search, 'i') },
          { 'replies.comment': new RegExp(filters.search, 'i') },
        ];
      }

      // Execute query with pagination
      const reviews = await Review.find(query)
        .sort(sort)
        .skip((page - 1) * limit)
        .limit(limit)
        .populate('user', 'name avatar reputation')
        .populate('place', 'name category')
        .populate('replies.user', 'name avatar');

      const total = await Review.countDocuments(query);

      return {
        reviews,
        total,
        totalPages: Math.ceil(total / limit),
        currentPage: page,
      };
    } catch (error) {
      throw new Error(`Failed to search reviews: ${error.message}`);
    }
  }

  // Export review data
  async exportReviewData(filters, format = 'json') {
    try {
      const query = {};
      // Apply filters similar to searchReviews
      if (filters) {
        // ... apply filters
      }

      const reviews = await Review.find(query)
        .populate('user', 'name email')
        .populate('place', 'name category')
        .lean();

      if (format === 'csv') {
        return this._convertToCSV(reviews);
      }

      return reviews;
    } catch (error) {
      throw new Error(`Failed to export review data: ${error.message}`);
    }
  }

  // Helper method to convert to CSV
  _convertToCSV(data) {
    const fields = [
      'id',
      'rating',
      'comment',
      'user.name',
      'place.name',
      'place.category',
      'status',
      'createdAt',
    ];

    const csv = data.map(item => {
      return fields.map(field => {
        const value = field.split('.').reduce((obj, key) => obj[key], item);
        return `"${value ? value.toString().replace(/"/g, '""') : ''}"`;
      }).join(',');
    });

    return `${fields.join(',')}\n${csv.join('\n')}`;
  }
}

module.exports = new ReviewAnalyticsService();
