const request = require('supertest');
const app = require('../../src/app');
const Place = require('../../src/models/place');
const { createTestUser, createTestPlaces } = require('../utils/test-utils');

// Mock email service
jest.mock('../../src/services/emailService', () => ({
  sendTemplateEmail: jest.fn().mockResolvedValue(true)
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

describe('Places Routes', () => {
  let token;
  let user;
  let place;

  beforeEach(async () => {
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

  describe('GET /api/places', () => {
    it('should get all places', async () => {
      const res = await request(app)
        .get('/api/places')
        .expect(200);

      expect(res.body).toHaveLength(1);
      expect(res.body[0].name).toBe('Test Place');
    });

    it('should filter places by category', async () => {
      await Place.create({
        name: 'Another Place',
        description: 'Another Description',
        address: '456 Test St',
        category: 'cafe',
        createdBy: user._id,
        location: {
          type: 'Point',
          coordinates: [1, 1]
        }
      });

      const res = await request(app)
        .get('/api/places?category=restaurant')
        .expect(200);

      expect(res.body).toHaveLength(1);
      expect(res.body[0].name).toBe('Test Place');
    });

    it('should search places by name', async () => {
      await Place.create({
        name: 'Different Place',
        description: 'Different Description',
        address: '789 Test St',
        category: 'restaurant',
        createdBy: user._id,
        location: {
          type: 'Point',
          coordinates: [2, 2]
        }
      });

      const res = await request(app)
        .get('/api/places?search=Test')
        .expect(200);

      expect(res.body).toHaveLength(1);
      expect(res.body[0].name).toBe('Test Place');
    });
  });

  describe('GET /api/places/:id', () => {
    it('should get place by id', async () => {
      const res = await request(app)
        .get(`/api/places/${place._id}`)
        .expect(200);

      expect(res.body.name).toBe('Test Place');
    });

    it('should return 404 if place not found', async () => {
      await request(app)
        .get('/api/places/123456789012345678901234')
        .expect(404);
    });

    it('should return 400 if invalid id', async () => {
      await request(app)
        .get('/api/places/invalid-id')
        .expect(400);
    });
  });

  describe('POST /api/places', () => {
    it('should create a new place', async () => {
      const res = await request(app)
        .post('/api/places')
        .set('Authorization', `Bearer ${token}`)
        .send({
          name: 'New Place',
          description: 'New Description',
          address: '123 New St',
          category: 'restaurant',
          location: {
            type: 'Point',
            coordinates: [3, 3]
          }
        })
        .expect(201);

      expect(res.body.name).toBe('New Place');
      expect(res.body.createdBy).toBe(user._id.toString());
    });

    it('should return 400 if invalid data', async () => {
      await request(app)
        .post('/api/places')
        .set('Authorization', `Bearer ${token}`)
        .send({
          name: '',
          description: 'New Description',
          address: '123 New St',
          category: 'restaurant',
          location: {
            type: 'Point',
            coordinates: [4, 4]
          }
        })
        .expect(400);
    });

    it('should return 401 if no token provided', async () => {
      await request(app)
        .post('/api/places')
        .send({
          name: 'New Place',
          description: 'New Description',
          address: '123 New St',
          category: 'restaurant',
          location: {
            type: 'Point',
            coordinates: [5, 5]
          }
        })
        .expect(401);
    });
  });

  describe('PUT /api/places/:id', () => {
    it('should update place if owner', async () => {
      const res = await request(app)
        .put(`/api/places/${place._id}`)
        .set('Authorization', `Bearer ${token}`)
        .send({
          name: 'Updated Place',
          description: 'Updated Description',
          address: '123 Updated St',
          category: 'cafe',
          location: {
            type: 'Point',
            coordinates: [6, 6]
          }
        })
        .expect(200);

      expect(res.body.name).toBe('Updated Place');
      expect(res.body.category).toBe('cafe');
    });

    it('should return 403 if not owner', async () => {
      const otherTestData = await createTestUser({ email: 'other@test.com' });
      const otherToken = otherTestData.token;

      await request(app)
        .put(`/api/places/${place._id}`)
        .set('Authorization', `Bearer ${otherToken}`)
        .send({
          name: 'Updated Place',
          description: 'Updated Description',
          address: '123 Updated St',
          category: 'cafe',
          location: {
            type: 'Point',
            coordinates: [7, 7]
          }
        })
        .expect(403);
    });

    it('should return 404 if place not found', async () => {
      await request(app)
        .put('/api/places/123456789012345678901234')
        .set('Authorization', `Bearer ${token}`)
        .send({
          name: 'Updated Place',
          description: 'Updated Description',
          address: '123 Updated St',
          category: 'cafe',
          location: {
            type: 'Point',
            coordinates: [8, 8]
          }
        })
        .expect(404);
    });
  });

  describe('DELETE /api/places/:id', () => {
    it('should delete place if owner', async () => {
      await request(app)
        .delete(`/api/places/${place._id}`)
        .set('Authorization', `Bearer ${token}`)
        .expect(200);

      const deletedPlace = await Place.findById(place._id);
      expect(deletedPlace).toBeNull();
    });

    it('should return 403 if not owner', async () => {
      const otherTestData = await createTestUser({ email: 'other@test.com' });
      const otherToken = otherTestData.token;

      await request(app)
        .delete(`/api/places/${place._id}`)
        .set('Authorization', `Bearer ${otherToken}`)
        .expect(403);
    });

    it('should return 404 if place not found', async () => {
      await request(app)
        .delete('/api/places/123456789012345678901234')
        .set('Authorization', `Bearer ${token}`)
        .expect(404);
    });
  });
});
