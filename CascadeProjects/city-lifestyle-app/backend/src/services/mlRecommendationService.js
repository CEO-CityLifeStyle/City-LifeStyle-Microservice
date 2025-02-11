const natural = require('natural');
const Review = require('../models/review');
const Place = require('../models/place');
const User = require('../models/user');

class MLRecommendationService {
  constructor() {
    this.tokenizer = new natural.WordTokenizer();
    this.tfidf = new natural.TfIdf();
    this.classifier = new natural.BayesClassifier();
  }

  // Get personalized recommendations using collaborative filtering
  async getCollaborativeRecommendations(userId, limit = 10) {
    try {
      // Get user's reviews and preferences
      const user = await User.findById(userId)
        .populate('reviews')
        .populate({
          path: 'reviews',
          populate: {
            path: 'place',
            select: 'category',
          },
        });

      if (!user) {
        throw new Error('User not found');
      }

      // Find similar users based on rating patterns
      const similarUsers = await this._findSimilarUsers(user);

      // Get recommendations based on similar users' highly rated places
      const recommendations = await this._getRecommendationsFromSimilarUsers(
        user,
        similarUsers,
        limit
      );

      return recommendations;
    } catch (error) {
      throw new Error(`Failed to get collaborative recommendations: ${error.message}`);
    }
  }

  // Get content-based recommendations
  async getContentBasedRecommendations(userId, limit = 10) {
    try {
      // Get user's reviews
      const userReviews = await Review.find({ user: userId })
        .populate('place')
        .sort({ rating: -1 });

      if (userReviews.length === 0) {
        return [];
      }

      // Build user profile based on reviewed places
      const userProfile = await this._buildUserProfile(userReviews);

      // Find similar places based on user profile
      const recommendations = await this._findSimilarPlaces(userProfile, userId, limit);

      return recommendations;
    } catch (error) {
      throw new Error(`Failed to get content-based recommendations: ${error.message}`);
    }
  }

  // Get hybrid recommendations combining collaborative and content-based approaches
  async getHybridRecommendations(userId, limit = 10) {
    try {
      const [collaborative, contentBased] = await Promise.all([
        this.getCollaborativeRecommendations(userId, limit),
        this.getContentBasedRecommendations(userId, limit),
      ]);

      // Combine and rank recommendations
      const hybridRecommendations = this._combineRecommendations(
        collaborative,
        contentBased,
        limit
      );

      return hybridRecommendations;
    } catch (error) {
      throw new Error(`Failed to get hybrid recommendations: ${error.message}`);
    }
  }

  // Train recommendation models
  async trainModels() {
    try {
      // Train classifier with review data
      const reviews = await Review.find({ status: 'approved' })
        .populate('place')
        .select('comment rating');

      reviews.forEach(review => {
        const sentiment = review.rating >= 4 ? 'positive' : 
                         review.rating <= 2 ? 'negative' : 'neutral';
        this.classifier.addDocument(review.comment, sentiment);
      });

      this.classifier.train();

      // Build TF-IDF model with place descriptions
      const places = await Place.find().select('description category');
      places.forEach(place => {
        this.tfidf.addDocument(`${place.description} ${place.category}`);
      });

      return true;
    } catch (error) {
      throw new Error(`Failed to train models: ${error.message}`);
    }
  }

  // Helper methods
  async _findSimilarUsers(targetUser) {
    try {
      // Get all users with their reviews
      const users = await User.find({ _id: { $ne: targetUser._id } })
        .populate('reviews')
        .populate({
          path: 'reviews',
          populate: {
            path: 'place',
            select: 'category',
          },
        });

      // Calculate similarity scores
      const similarities = users.map(user => ({
        user,
        similarity: this._calculateUserSimilarity(targetUser, user),
      }));

      // Sort by similarity and return top users
      return similarities
        .sort((a, b) => b.similarity - a.similarity)
        .slice(0, 10)
        .map(item => item.user);
    } catch (error) {
      throw error;
    }
  }

  async _getRecommendationsFromSimilarUsers(targetUser, similarUsers, limit) {
    try {
      const recommendedPlaces = new Map();
      const userReviewedPlaces = new Set(
        targetUser.reviews.map(review => review.place._id.toString())
      );

      for (const user of similarUsers) {
        for (const review of user.reviews) {
          const placeId = review.place._id.toString();
          
          // Skip places the target user has already reviewed
          if (userReviewedPlaces.has(placeId)) {
            continue;
          }

          if (!recommendedPlaces.has(placeId)) {
            recommendedPlaces.set(placeId, {
              place: review.place,
              score: 0,
              count: 0,
            });
          }

          const recommendation = recommendedPlaces.get(placeId);
          recommendation.score += review.rating;
          recommendation.count += 1;
        }
      }

      // Calculate average scores and sort recommendations
      const recommendations = Array.from(recommendedPlaces.values())
        .map(item => ({
          ...item,
          averageRating: item.score / item.count,
        }))
        .sort((a, b) => b.averageRating - a.averageRating)
        .slice(0, limit);

      return recommendations;
    } catch (error) {
      throw error;
    }
  }

  async _buildUserProfile(userReviews) {
    try {
      const profile = {
        categories: {},
        keywords: {},
        averageRating: 0,
        totalReviews: userReviews.length,
      };

      let totalRating = 0;

      userReviews.forEach(review => {
        // Update category preferences
        const category = review.place.category;
        profile.categories[category] = (profile.categories[category] || 0) + 1;

        // Update keyword preferences
        const tokens = this.tokenizer.tokenize(review.comment.toLowerCase());
        tokens.forEach(token => {
          profile.keywords[token] = (profile.keywords[token] || 0) + 1;
        });

        totalRating += review.rating;
      });

      profile.averageRating = totalRating / userReviews.length;

      return profile;
    } catch (error) {
      throw error;
    }
  }

  async _findSimilarPlaces(userProfile, userId, limit) {
    try {
      // Get all places not reviewed by the user
      const userReviews = await Review.find({ user: userId }).select('place');
      const reviewedPlaceIds = userReviews.map(review => review.place);

      const places = await Place.find({
        _id: { $nin: reviewedPlaceIds },
      });

      // Calculate similarity scores for each place
      const similarities = places.map(place => ({
        place,
        similarity: this._calculatePlaceSimilarity(place, userProfile),
      }));

      // Sort by similarity and return top recommendations
      return similarities
        .sort((a, b) => b.similarity - a.similarity)
        .slice(0, limit)
        .map(item => item.place);
    } catch (error) {
      throw error;
    }
  }

  _calculateUserSimilarity(user1, user2) {
    // Calculate Jaccard similarity between users' category preferences
    const categories1 = new Set(user1.reviews.map(review => review.place.category));
    const categories2 = new Set(user2.reviews.map(review => review.place.category));

    const intersection = new Set(
      [...categories1].filter(category => categories2.has(category))
    );

    const union = new Set([...categories1, ...categories2]);

    return intersection.size / union.size;
  }

  _calculatePlaceSimilarity(place, userProfile) {
    // Calculate similarity based on category and keywords
    let similarity = 0;

    // Category similarity
    if (userProfile.categories[place.category]) {
      similarity += userProfile.categories[place.category] / userProfile.totalReviews;
    }

    // Keyword similarity
    const placeTokens = this.tokenizer.tokenize(
      `${place.description} ${place.category}`.toLowerCase()
    );
    
    placeTokens.forEach(token => {
      if (userProfile.keywords[token]) {
        similarity += userProfile.keywords[token] / userProfile.totalReviews;
      }
    });

    return similarity;
  }

  _combineRecommendations(collaborative, contentBased, limit) {
    // Combine and normalize scores
    const recommendations = new Map();

    // Add collaborative recommendations
    collaborative.forEach((rec, index) => {
      recommendations.set(rec.place._id.toString(), {
        place: rec.place,
        score: (collaborative.length - index) / collaborative.length,
      });
    });

    // Add content-based recommendations
    contentBased.forEach((rec, index) => {
      const placeId = rec._id.toString();
      if (recommendations.has(placeId)) {
        recommendations.get(placeId).score += 
          (contentBased.length - index) / contentBased.length;
      } else {
        recommendations.set(placeId, {
          place: rec,
          score: (contentBased.length - index) / contentBased.length,
        });
      }
    });

    // Sort by combined score and return top recommendations
    return Array.from(recommendations.values())
      .sort((a, b) => b.score - a.score)
      .slice(0, limit);
  }
}

module.exports = new MLRecommendationService();
