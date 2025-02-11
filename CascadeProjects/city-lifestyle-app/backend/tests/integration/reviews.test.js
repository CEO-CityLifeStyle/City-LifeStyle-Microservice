const request = require('supertest');
const app = require('../../src/app');
const Review = require('../../src/models/review');
const Place = require('../../src/models/place');
const { createTestUser } = require('../utils/test-utils');

// Mock email service
jest.mock('../../src/services/emailService', () => ({
  sendTemplateEmail: jest.fn().mockResolvedValue(true),
  sendReviewNotification: jest.fn().mockResolvedValue(true)
}));

// Mock websocket service
jest.mock('../../src/services/websocketService', () => ({
  notifyUser: jest.fn().mockResolvedValue(true),
  broadcastToRoom: jest.fn().mockResolvedValue(true)
}));

// Mock visualization service
jest.mock('../../src/services/visualizationService', () => ({
  generateChart: jest.fn().mockResolvedValue('chart-data-url'),
  generateHeatmap: jest.fn().mockResolvedValue('heatmap-data-url')
}));

describe('Review Routes', () => {
  let token;
  let user;
  let place;

  beforeEach(async () => {
    await Review.deleteMany({});
    await Place.deleteMany({});
    
    const testData = await createTestUser();
    user = testData.user;
    token = testData.token;

    place = await Place.create({
      name: 'Test Place',
      description: 'Test Description',
      address: '123 Test St',
      category: 'restaurant',
      createdBy: user._id,
      location: {
        type: 'Point',
        coordinates: [0, 0]
      }
    });
  });

  describe('POST /api/reviews/:placeId', () => {
    it('should create a new review', async () => {
      const res = await request(app)
        .post(`/api/reviews/${place._id}`)
        .set('Authorization', `Bearer ${token}`)
        .send({
          rating: 4,
          comment: 'Great place!'
        })
        .expect(201);

      expect(res.body.rating).toBe(4);
      expect(res.body.comment).toBe('Great place!');
      expect(res.body.user).toBe(user._id.toString());
      expect(res.body.place).toBe(place._id.toString());
      expect(res.body.status).toBe('pending');

      // Check that place rating was updated
      const updatedPlace = await Place.findById(place._id);
      expect(updatedPlace.rating).toBe(4);
    });

    it('should not allow multiple reviews from same user', async () => {
      // Create first review
      await request(app)
        .post(`/api/reviews/${place._id}`)
        .set('Authorization', `Bearer ${token}`)
        .send({
          rating: 4,
          comment: 'Great place!'
        })
        .expect(201);

      // Try to create second review
      await request(app)
        .post(`/api/reviews/${place._id}`)
        .set('Authorization', `Bearer ${token}`)
        .send({
          rating: 5,
          comment: 'Still great!'
        })
        .expect(400);
    });

    it('should return 401 if no token provided', async () => {
      await request(app)
        .post(`/api/reviews/${place._id}`)
        .send({
          rating: 4,
          comment: 'Great place!'
        })
        .expect(401);
    });

    it('should return 404 if place not found', async () => {
      await request(app)
        .post('/api/reviews/123456789012345678901234')
        .set('Authorization', `Bearer ${token}`)
        .send({
          rating: 4,
          comment: 'Great place!'
        })
        .expect(404);
    });
  });

  describe('PUT /api/reviews/:id', () => {
    let review;

    beforeEach(async () => {
      review = await Review.create({
        rating: 3,
        comment: 'Original review',
        user: user._id,
        place: place._id,
        status: 'pending'
      });
    });

    it('should update review if owner', async () => {
      const res = await request(app)
        .put(`/api/reviews/${review._id}`)
        .set('Authorization', `Bearer ${token}`)
        .send({
          rating: 5,
          comment: 'Updated review'
        })
        .expect(200);

      expect(res.body.rating).toBe(5);
      expect(res.body.comment).toBe('Updated review');
      expect(res.body.status).toBe('pending');

      // Check that place rating was updated
      const updatedPlace = await Place.findById(place._id);
      expect(updatedPlace.rating).toBe(5);
    });

    it('should return 403 if not owner', async () => {
      const otherTestData = await createTestUser({ email: 'other@test.com' });
      const otherToken = otherTestData.token;

      await request(app)
        .put(`/api/reviews/${review._id}`)
        .set('Authorization', `Bearer ${otherToken}`)
        .send({
          rating: 5,
          comment: 'Updated review'
        })
        .expect(403);
    });

    it('should return 404 if review not found', async () => {
      await request(app)
        .put('/api/reviews/123456789012345678901234')
        .set('Authorization', `Bearer ${token}`)
        .send({
          rating: 5,
          comment: 'Updated review'
        })
        .expect(404);
    });
  });

  describe('DELETE /api/reviews/:id', () => {
    let review;

    beforeEach(async () => {
      review = await Review.create({
        rating: 3,
        comment: 'Test review',
        user: user._id,
        place: place._id,
        status: 'pending'
      });
    });

    it('should delete review if owner', async () => {
      await request(app)
        .delete(`/api/reviews/${review._id}`)
        .set('Authorization', `Bearer ${token}`)
        .expect(200);

      const deletedReview = await Review.findById(review._id);
      expect(deletedReview).toBeNull();

      // Check that place rating was updated
      const updatedPlace = await Place.findById(place._id);
      expect(updatedPlace.rating).toBe(0);
    });

    it('should return 403 if not owner', async () => {
      const otherTestData = await createTestUser({ email: 'other@test.com' });
      const otherToken = otherTestData.token;

      await request(app)
        .delete(`/api/reviews/${review._id}`)
        .set('Authorization', `Bearer ${otherToken}`)
        .expect(403);
    });

    it('should return 404 if review not found', async () => {
      await request(app)
        .delete('/api/reviews/123456789012345678901234')
        .set('Authorization', `Bearer ${token}`)
        .expect(404);
    });
  });

  describe('GET /api/reviews/place/:placeId', () => {
    beforeEach(async () => {
      // Create multiple reviews
      await Review.create([
        {
          rating: 4,
          comment: 'Great place!',
          user: user._id,
          place: place._id,
          status: 'pending'
        },
        {
          rating: 5,
          comment: 'Amazing!',
          user: (await createTestUser({ email: 'other1@test.com' })).user._id,
          place: place._id,
          status: 'pending'
        },
        {
          rating: 3,
          comment: 'Good but not great',
          user: (await createTestUser({ email: 'other2@test.com' })).user._id,
          place: place._id,
          status: 'pending'
        }
      ]);
    });

    it('should get paginated reviews for a place', async () => {
      const res = await request(app)
        .get(`/api/reviews/place/${place._id}?page=1&limit=2`)
        .expect(200);

      expect(res.body).toHaveProperty('reviews');
      expect(res.body).toHaveProperty('currentPage', 1);
      expect(res.body).toHaveProperty('totalPages', 2);
      expect(res.body).toHaveProperty('total', 3);
      expect(res.body.reviews).toHaveLength(2);
      expect(res.body.reviews[0]).toHaveProperty('rating');
      expect(res.body.reviews[0]).toHaveProperty('comment');
      expect(res.body.reviews[0]).toHaveProperty('user');
      expect(res.body.reviews[0]).toHaveProperty('status');
    });

    it('should get second page of reviews', async () => {
      const res = await request(app)
        .get(`/api/reviews/place/${place._id}?page=2&limit=2`)
        .expect(200);

      expect(res.body).toHaveProperty('reviews');
      expect(res.body).toHaveProperty('currentPage', 2);
      expect(res.body).toHaveProperty('totalPages', 2);
      expect(res.body).toHaveProperty('total', 3);
      expect(res.body.reviews).toHaveLength(1);
    });

    it('should return empty array if no reviews', async () => {
      const newPlace = await Place.create({
        name: 'New Place',
        description: 'New Description',
        address: '456 New St',
        category: 'cafe',
        createdBy: user._id,
        location: {
          type: 'Point',
          coordinates: [1, 1]
        }
      });

      const res = await request(app)
        .get(`/api/reviews/place/${newPlace._id}`)
        .expect(200);

      expect(res.body).toHaveProperty('reviews');
      expect(res.body.reviews).toHaveLength(0);
      expect(res.body).toHaveProperty('total', 0);
      expect(res.body).toHaveProperty('totalPages', 0);
    });
  });

  describe('GET /api/reviews/user', () => {
    beforeEach(async () => {
      // Create multiple reviews for the user
      await Review.create([
        {
          rating: 4,
          comment: 'Great place!',
          user: user._id,
          place: place._id,
          status: 'approved'
        },
        {
          rating: 5,
          comment: 'Amazing!',
          user: user._id,
          place: (await Place.create({
            name: 'Another Place',
            description: 'Another Description',
            address: '456 Test St',
            category: 'cafe',
            createdBy: user._id,
            location: {
              type: 'Point',
              coordinates: [1, 1]
            }
          }))._id,
          status: 'pending'
        }
      ]);
    });

    it('should get paginated reviews by user', async () => {
      const res = await request(app)
        .get('/api/reviews/user')
        .set('Authorization', `Bearer ${token}`)
        .expect(200);

      expect(res.body).toHaveProperty('reviews');
      expect(res.body).toHaveProperty('currentPage', 1);
      expect(res.body).toHaveProperty('totalPages', 1);
      expect(res.body).toHaveProperty('total', 2);
      expect(res.body.reviews).toHaveLength(2);
      expect(res.body.reviews[0].user).toBe(user._id.toString());
      expect(res.body.reviews[1].user).toBe(user._id.toString());
      expect(res.body.reviews[0]).toHaveProperty('status');
      expect(res.body.reviews[1]).toHaveProperty('status');
    });

    it('should return 401 if no token provided', async () => {
      await request(app)
        .get('/api/reviews/user')
        .expect(401);
    });
  });
});
