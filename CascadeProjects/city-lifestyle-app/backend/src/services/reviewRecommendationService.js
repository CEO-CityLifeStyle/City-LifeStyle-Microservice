const Review = require('../models/review');
const Place = require('../models/place');
const User = require('../models/user');

class ReviewRecommendationService {
  // Get personalized review recommendations for a user
  async getPersonalizedRecommendations(userId, limit = 10) {
    try {
      // Get user's interests and preferences
      const user = await User.findById(userId);
      if (!user) {
        throw new Error('User not found');
      }

      // Get user's review history
      const userReviews = await Review.find({ user: userId })
        .populate('place', 'category');

      // Extract user's preferred categories
      const categoryPreferences = this._extractCategoryPreferences(userReviews);

      // Get recommended reviews based on user's preferences
      const recommendations = await Review.aggregate([
        {
          $match: {
            status: 'approved',
            user: { $ne: userId }, // Exclude user's own reviews
          },
        },
        // Lookup place details
        {
          $lookup: {
            from: 'places',
            localField: 'place',
            foreignField: '_id',
            as: 'place',
          },
        },
        { $unwind: '$place' },
        // Calculate relevance score
        {
          $addFields: {
            relevanceScore: {
              $add: [
                { $size: '$helpful' }, // Number of helpful votes
                { $multiply: [{ $size: '$likes' }, 0.5] }, // Number of likes (weighted less)
                {
                  $multiply: [
                    {
                      $cond: [
                        { $in: ['$place.category', Object.keys(categoryPreferences)] },
                        categoryPreferences['$place.category'] || 0,
                        0,
                      ],
                    },
                    2, // Category preference weight
                  ],
                },
              ],
            },
          },
        },
        // Sort by relevance score
        { $sort: { relevanceScore: -1 } },
        { $limit: limit },
        // Project needed fields
        {
          $project: {
            _id: 1,
            rating: 1,
            comment: 1,
            images: 1,
            helpful: 1,
            likes: 1,
            createdAt: 1,
            relevanceScore: 1,
            'place._id': 1,
            'place.name': 1,
            'place.category': 1,
          },
        },
      ]);

      return recommendations;
    } catch (error) {
      throw new Error(`Failed to get personalized recommendations: ${error.message}`);
    }
  }

  // Get trending reviews
  async getTrendingReviews(limit = 10, timeframe = '7d') {
    try {
      const timeframeDate = new Date();
      timeframeDate.setDate(timeframeDate.getDate() - parseInt(timeframe));

      const trending = await Review.aggregate([
        {
          $match: {
            status: 'approved',
            createdAt: { $gte: timeframeDate },
          },
        },
        // Calculate engagement score
        {
          $addFields: {
            engagementScore: {
              $add: [
                { $size: '$helpful' },
                { $size: '$likes' },
                { $size: '$replies' },
              ],
            },
          },
        },
        // Sort by engagement score
        { $sort: { engagementScore: -1 } },
        { $limit: limit },
        // Lookup place and user details
        {
          $lookup: {
            from: 'places',
            localField: 'place',
            foreignField: '_id',
            as: 'place',
          },
        },
        {
          $lookup: {
            from: 'users',
            localField: 'user',
            foreignField: '_id',
            as: 'user',
          },
        },
        { $unwind: '$place' },
        { $unwind: '$user' },
        // Project needed fields
        {
          $project: {
            _id: 1,
            rating: 1,
            comment: 1,
            images: 1,
            helpful: 1,
            likes: 1,
            replies: 1,
            createdAt: 1,
            engagementScore: 1,
            'place._id': 1,
            'place.name': 1,
            'place.category': 1,
            'user.name': 1,
            'user.avatar': 1,
          },
        },
      ]);

      return trending;
    } catch (error) {
      throw new Error(`Failed to get trending reviews: ${error.message}`);
    }
  }

  // Get similar reviews
  async getSimilarReviews(reviewId, limit = 5) {
    try {
      const sourceReview = await Review.findById(reviewId)
        .populate('place', 'category');

      if (!sourceReview) {
        throw new Error('Review not found');
      }

      const similar = await Review.aggregate([
        {
          $match: {
            _id: { $ne: reviewId },
            status: 'approved',
            rating: { $gte: sourceReview.rating - 1, $lte: sourceReview.rating + 1 },
          },
        },
        // Lookup place details
        {
          $lookup: {
            from: 'places',
            localField: 'place',
            foreignField: '_id',
            as: 'place',
          },
        },
        { $unwind: '$place' },
        // Calculate similarity score
        {
          $addFields: {
            similarityScore: {
              $add: [
                {
                  $cond: [
                    { $eq: ['$place.category', sourceReview.place.category] },
                    2,
                    0,
                  ],
                },
                {
                  $subtract: [
                    5,
                    { $abs: { $subtract: ['$rating', sourceReview.rating] } },
                  ],
                },
              ],
            },
          },
        },
        // Sort by similarity score
        { $sort: { similarityScore: -1 } },
        { $limit: limit },
        // Project needed fields
        {
          $project: {
            _id: 1,
            rating: 1,
            comment: 1,
            images: 1,
            helpful: 1,
            likes: 1,
            createdAt: 1,
            similarityScore: 1,
            'place._id': 1,
            'place.name': 1,
            'place.category': 1,
          },
        },
      ]);

      return similar;
    } catch (error) {
      throw new Error(`Failed to get similar reviews: ${error.message}`);
    }
  }

  // Get recommended reviews for a place
  async getPlaceRecommendations(placeId, limit = 5) {
    try {
      const place = await Place.findById(placeId);
      if (!place) {
        throw new Error('Place not found');
      }

      const recommended = await Review.aggregate([
        {
          $match: {
            place: place._id,
            status: 'approved',
          },
        },
        // Calculate quality score
        {
          $addFields: {
            qualityScore: {
              $add: [
                '$rating',
                { $multiply: [{ $size: '$helpful' }, 0.5] },
                { $multiply: [{ $size: '$likes' }, 0.3] },
                { $multiply: [{ $size: '$replies' }, 0.2] },
              ],
            },
          },
        },
        // Sort by quality score
        { $sort: { qualityScore: -1 } },
        { $limit: limit },
        // Lookup user details
        {
          $lookup: {
            from: 'users',
            localField: 'user',
            foreignField: '_id',
            as: 'user',
          },
        },
        { $unwind: '$user' },
        // Project needed fields
        {
          $project: {
            _id: 1,
            rating: 1,
            comment: 1,
            images: 1,
            helpful: 1,
            likes: 1,
            replies: 1,
            createdAt: 1,
            qualityScore: 1,
            'user.name': 1,
            'user.avatar': 1,
          },
        },
      ]);

      return recommended;
    } catch (error) {
      throw new Error(`Failed to get place recommendations: ${error.message}`);
    }
  }

  // Helper method to extract category preferences
  _extractCategoryPreferences(reviews) {
    const preferences = {};
    
    reviews.forEach(review => {
      const category = review.place.category;
      preferences[category] = (preferences[category] || 0) + 1;
    });

    // Normalize preferences
    const total = Object.values(preferences).reduce((sum, count) => sum + count, 0);
    Object.keys(preferences).forEach(category => {
      preferences[category] = preferences[category] / total;
    });

    return preferences;
  }
}

module.exports = new ReviewRecommendationService();
