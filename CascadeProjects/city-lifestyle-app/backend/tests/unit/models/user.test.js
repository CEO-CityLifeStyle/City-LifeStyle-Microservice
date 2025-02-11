const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');
const User = require('../../../src/models/user');

// Mock Review model for testing
const mockReviewModel = {
  aggregate: jest.fn().mockImplementation((pipeline) => {
    // Check if pipeline is for calculating review stats
    if (pipeline.length === 2 && 
        pipeline[0].$match && 
        pipeline[1].$group && 
        pipeline[1].$group.averageRating) {
      // Return mock stats only if there are review IDs
      const ids = pipeline[0].$match._id.$in;
      if (ids && ids.length > 0) {
        return Promise.resolve([{
          _id: null,
          totalReviews: ids.length,
          averageRating: 4.5
        }]);
      }
    }
    return Promise.resolve([]);
  }),
  find: jest.fn().mockImplementation((query) => {
    // Mock find method for getReviews
    if (query && query._id && query._id.$in) {
      const ids = query._id.$in;
      return {
        sort: () => ({
          skip: () => ({
            limit: () => Promise.resolve(ids.map(id => ({ _id: id })))
          })
        })
      };
    }
    return Promise.resolve([]);
  })
};

// Store original mongoose.model
const originalModel = mongoose.model.bind(mongoose);

// Mock mongoose.model for Review
mongoose.model = jest.fn((name, schema) => {
  if (name === 'Review') {
    return mockReviewModel;
  }
  if (schema) {
    return originalModel(name, schema);
  }
  return originalModel(name);
});

describe('User Model', () => {
  beforeEach(async () => {
    await User.deleteMany({});
    mockReviewModel.aggregate.mockClear();
    mockReviewModel.find.mockClear();
  });

  afterAll(async () => {
    // Restore original mongoose.model
    mongoose.model = originalModel;
  });

  describe('User Creation', () => {
    it('should create a user with valid data', async () => {
      const validUser = {
        name: 'Test User',
        email: 'test@example.com',
        password: 'password123',
        role: 'user'
      };

      const user = await User.create(validUser);
      expect(user.name).toBe(validUser.name);
      expect(user.email).toBe(validUser.email);
      expect(user.role).toBe(validUser.role);
      expect(user.reviewStats.totalReviews).toBe(0);
      expect(user.reviewStats.averageRating).toBe(0);
      // Check if password was hashed
      expect(user.password).not.toBe(validUser.password);
      expect(await user.comparePassword(validUser.password)).toBe(true);
    });

    it('should not create a user with invalid email', async () => {
      const invalidUser = {
        name: 'Test User',
        email: 'invalid-email',
        password: 'password123',
        role: 'user'
      };

      await expect(User.create(invalidUser)).rejects.toThrow();
    });

    it('should not create a user with password shorter than 7 characters', async () => {
      const invalidUser = {
        name: 'Test User',
        email: 'test@example.com',
        password: '123456',
        role: 'user'
      };

      await expect(User.create(invalidUser)).rejects.toThrow();
    });

    it('should not create a user with invalid role', async () => {
      const invalidUser = {
        name: 'Test User',
        email: 'test@example.com',
        password: 'password123',
        role: 'invalid-role'
      };

      await expect(User.create(invalidUser)).rejects.toThrow();
    });
  });

  describe('User Methods', () => {
    let user;

    beforeEach(async () => {
      user = await User.create({
        name: 'Test User',
        email: 'test@example.com',
        password: 'password123',
        role: 'user'
      });
    });

    it('should handle favorite places correctly', async () => {
      const placeId = new mongoose.Types.ObjectId();
      
      // Add to favorites
      await user.addToFavorites(placeId);
      expect(user.favoritePlaces).toHaveLength(1);
      expect(user.favoritePlaces[0].equals(placeId)).toBe(true);

      // Add same place again (should not duplicate)
      await user.addToFavorites(placeId);
      expect(user.favoritePlaces).toHaveLength(1);

      // Remove from favorites
      await user.removeFromFavorites(placeId);
      expect(user.favoritePlaces).toHaveLength(0);
    });

    it('should handle favorite events correctly', async () => {
      const eventId = new mongoose.Types.ObjectId();
      
      // Add to favorites
      await user.addEventToFavorites(eventId);
      expect(user.favoriteEvents).toHaveLength(1);
      expect(user.favoriteEvents[0].equals(eventId)).toBe(true);

      // Add same event again (should not duplicate)
      await user.addEventToFavorites(eventId);
      expect(user.favoriteEvents).toHaveLength(1);

      // Remove from favorites
      await user.removeEventFromFavorites(eventId);
      expect(user.favoriteEvents).toHaveLength(0);
    });

    it('should handle reviews and update review stats correctly', async () => {
      const reviewId = new mongoose.Types.ObjectId();
      
      // Add review
      const updatedUser = await user.addReview(reviewId);
      expect(updatedUser.reviews).toHaveLength(1);
      expect(updatedUser.reviews[0].equals(reviewId)).toBe(true);
      expect(updatedUser.reviewStats.totalReviews).toBe(1);
      expect(updatedUser.reviewStats.averageRating).toBe(4.5);

      // Add same review again (should not duplicate)
      const sameReviewUser = await user.addReview(reviewId);
      expect(sameReviewUser.reviews).toHaveLength(1);

      // Remove review
      const removedReviewUser = await user.removeReview(reviewId);
      expect(removedReviewUser.reviews).toHaveLength(0);
      expect(removedReviewUser.reviewStats.totalReviews).toBe(0);
      expect(removedReviewUser.reviewStats.averageRating).toBe(0);
    });

    it('should remove sensitive information when converting to JSON', () => {
      const userJson = user.toJSON();
      expect(userJson.password).toBeUndefined();
      expect(userJson.name).toBe(user.name);
      expect(userJson.email).toBe(user.email);
    });

    it('should compare password correctly', async () => {
      expect(await user.comparePassword('password123')).toBe(true);
      expect(await user.comparePassword('wrongpassword')).toBe(false);
    });

    it('should handle paginated response correctly', async () => {
      const reviews = Array.from({ length: 10 }, () => new mongoose.Types.ObjectId());
      await Promise.all(reviews.map(review => user.addReview(review)));

      const paginatedReviews = await user.getReviews({ skip: 0, limit: 5 });
      expect(paginatedReviews).toHaveLength(5);
      expect(reviews.slice(0, 5).some(id => paginatedReviews[0]._id.equals(id))).toBe(true);

      const paginatedReviews2 = await user.getReviews({ skip: 5, limit: 5 });
      expect(paginatedReviews2).toHaveLength(5);
      expect(reviews.slice(5, 10).some(id => paginatedReviews2[0]._id.equals(id))).toBe(true);
    });
  });
});
