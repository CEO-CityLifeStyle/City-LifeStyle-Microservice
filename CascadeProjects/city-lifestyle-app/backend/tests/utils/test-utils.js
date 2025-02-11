const jwt = require('jsonwebtoken');
const mongoose = require('mongoose');
const User = require('../../src/models/user');

// Mock Review model for testing
const mockReviewModel = {
  aggregate: jest.fn().mockImplementation((pipeline) => {
    // Check if pipeline is for calculating review stats
    if (pipeline.length === 2 && 
        pipeline[0].$match && 
        pipeline[1].$group && 
        pipeline[1].$group.averageRating) {
      return Promise.resolve([{
        _id: null,
        totalReviews: 1,
        averageRating: 4.5
      }]);
    }
    return Promise.resolve([]);
  }),
  findOne: jest.fn().mockImplementation(() => Promise.resolve(null)),
  find: jest.fn().mockImplementation(() => ({
    populate: jest.fn().mockReturnThis(),
    sort: jest.fn().mockReturnThis(),
    skip: jest.fn().mockReturnThis(),
    limit: jest.fn().mockReturnThis(),
    exec: jest.fn().mockResolvedValue([
      {
        _id: new mongoose.Types.ObjectId(),
        rating: 4,
        comment: 'Great place!',
        user: new mongoose.Types.ObjectId(),
        place: new mongoose.Types.ObjectId(),
        status: 'pending',
        createdAt: new Date(),
        updatedAt: new Date()
      }
    ])
  })),
  deleteOne: jest.fn().mockImplementation(() => Promise.resolve({ deletedCount: 1 })),
  countDocuments: jest.fn().mockImplementation(() => Promise.resolve(2))
};

// Mock mongoose.model for Review
const originalModel = mongoose.model.bind(mongoose);
mongoose.model = jest.fn((name, schema) => {
  if (name === 'Review') {
    return mockReviewModel;
  }
  if (schema) {
    return originalModel(name, schema);
  }
  return originalModel(name);
});

/**
 * Create a test user and generate JWT token
 * @param {Object} userData - Optional user data to override defaults
 * @returns {Promise<{user: Object, token: string}>}
 */
const createTestUser = async (userData = {}) => {
  const defaultUser = {
    email: 'test@example.com',
    password: 'password123',
    name: 'Test User',
    role: 'user',
    reviewStats: {
      totalReviews: 0,
      averageRating: 0,
      lastReviewDate: null
    },
    favoritePlaces: [],
    favoriteEvents: [],
    reviews: [],
    ...userData
  };

  const user = await User.create(defaultUser);
  const token = jwt.sign(
    { _id: user._id },
    process.env.JWT_SECRET || 'test-secret',
    { expiresIn: '1h' }
  );

  return { 
    user,
    token 
  };
};

/**
 * Generate a valid MongoDB ObjectId
 * @returns {string}
 */
const generateObjectId = () => new mongoose.Types.ObjectId().toString();

/**
 * Create test data for places
 * @param {number} count - Number of places to create
 * @param {string} [userId] - Optional user ID for createdBy field
 * @returns {Array<Object>}
 */
const createTestPlaces = (count = 1, userId = generateObjectId()) => {
  return Array.from({ length: count }, (_, index) => ({
    name: `Test Place ${index + 1}`,
    description: `Description for test place ${index + 1}`,
    address: `${index + 1} Test Street, Test City`,
    category: 'restaurant',
    location: {
      type: 'Point',
      coordinates: [
        -73.935242 + (index * 0.01), // longitude
        40.730610 + (index * 0.01)   // latitude
      ]
    },
    rating: 4.5,
    reviews: [],
    photos: [],
    createdBy: userId,
    openingHours: {
      monday: { open: '09:00', close: '17:00' },
      tuesday: { open: '09:00', close: '17:00' },
      wednesday: { open: '09:00', close: '17:00' },
      thursday: { open: '09:00', close: '17:00' },
      friday: { open: '09:00', close: '17:00' }
    },
    amenities: ['wifi', 'parking'],
    priceRange: 'moderate',
    contactInfo: {
      phone: '+1234567890',
      email: 'test@example.com',
      website: 'http://example.com'
    }
  }));
};

/**
 * Create a test review
 * @param {Object} reviewData - Optional review data to override defaults
 * @returns {Object}
 */
const createTestReview = (reviewData = {}) => ({
  rating: 4,
  comment: 'Test review comment',
  photos: [],
  likes: 0,
  createdBy: generateObjectId(),
  ...reviewData
});

module.exports = {
  createTestUser,
  generateObjectId,
  createTestPlaces,
  createTestReview,
  mockReviewModel
};
