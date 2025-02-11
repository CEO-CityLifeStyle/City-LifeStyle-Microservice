const request = require('supertest');
const mongoose = require('mongoose');
const { app } = require('../src/app');
const User = require('../src/models/user');
const { generateToken } = require('../src/utils/auth');
const avatarService = require('../src/services/avatarService');

describe('Profile Management API', () => {
  let token;
  let userId;

  beforeAll(async () => {
    // Connect to test database
    await mongoose.connect(process.env.MONGODB_TEST_URI);
  });

  beforeEach(async () => {
    // Create test user
    const user = await User.create({
      name: 'Test User',
      email: 'test@example.com',
      password: 'password123',
    });
    userId = user._id;
    token = generateToken(user);
  });

  afterEach(async () => {
    await User.deleteMany({});
  });

  afterAll(async () => {
    await mongoose.connection.close();
  });

  describe('GET /profile', () => {
    it('should return user profile', async () => {
      const response = await request(app)
        .get('/profile')
        .set('Authorization', `Bearer ${token}`);

      expect(response.status).toBe(200);
      expect(response.body).toHaveProperty('name', 'Test User');
      expect(response.body).toHaveProperty('email', 'test@example.com');
    });

    it('should return 401 without token', async () => {
      const response = await request(app).get('/profile');
      expect(response.status).toBe(401);
    });
  });

  describe('PUT /profile', () => {
    it('should update user profile', async () => {
      const updates = {
        name: 'Updated Name',
        bio: 'New bio',
      };

      const response = await request(app)
        .put('/profile')
        .set('Authorization', `Bearer ${token}`)
        .send(updates);

      expect(response.status).toBe(200);
      expect(response.body).toHaveProperty('name', 'Updated Name');
      expect(response.body).toHaveProperty('bio', 'New bio');
    });

    it('should prevent duplicate email', async () => {
      // Create another user
      await User.create({
        name: 'Other User',
        email: 'other@example.com',
        password: 'password123',
      });

      const response = await request(app)
        .put('/profile')
        .set('Authorization', `Bearer ${token}`)
        .send({ email: 'other@example.com' });

      expect(response.status).toBe(400);
      expect(response.body).toHaveProperty('message', 'Email is already taken');
    });
  });

  describe('POST /profile/avatar', () => {
    it('should upload avatar', async () => {
      const mockFile = Buffer.from('fake-image-content');
      const mockUrls = {
        thumbnail: 'thumbnail-url',
        medium: 'medium-url',
        large: 'large-url',
      };

      // Mock avatar service
      jest.spyOn(avatarService, 'uploadAvatar').mockResolvedValue({
        avatarId: 'test-avatar-id',
        urls: mockUrls,
      });

      const response = await request(app)
        .post('/profile/avatar')
        .set('Authorization', `Bearer ${token}`)
        .attach('avatar', mockFile, 'test-image.jpg');

      expect(response.status).toBe(200);
      expect(response.body.avatar).toEqual(mockUrls);
      expect(response.body.avatarId).toBe('test-avatar-id');
    });

    it('should validate file type', async () => {
      const mockFile = Buffer.from('fake-text-content');

      const response = await request(app)
        .post('/profile/avatar')
        .set('Authorization', `Bearer ${token}`)
        .attach('avatar', mockFile, 'test.txt');

      expect(response.status).toBe(400);
      expect(response.body).toHaveProperty('message', 'Invalid file type');
    });
  });

  describe('DELETE /profile/avatar', () => {
    it('should delete avatar', async () => {
      // First set an avatar
      await User.findByIdAndUpdate(userId, {
        avatar: {
          thumbnail: 'thumbnail-url',
          medium: 'medium-url',
          large: 'large-url',
        },
        avatarId: 'test-avatar-id',
      });

      const response = await request(app)
        .delete('/profile/avatar')
        .set('Authorization', `Bearer ${token}`);

      expect(response.status).toBe(200);
      expect(response.body.avatar).toBeUndefined();
      expect(response.body.avatarId).toBeUndefined();
    });
  });

  describe('GET /profile/privacy', () => {
    it('should return privacy settings', async () => {
      const response = await request(app)
        .get('/profile/privacy')
        .set('Authorization', `Bearer ${token}`);

      expect(response.status).toBe(200);
      expect(response.body).toHaveProperty('profileVisibility');
      expect(response.body).toHaveProperty('activityVisibility');
      expect(response.body).toHaveProperty('emailVisibility');
    });
  });

  describe('PUT /profile/privacy', () => {
    it('should update privacy settings', async () => {
      const settings = {
        profileVisibility: 'private',
        activityVisibility: 'friends',
        emailVisibility: 'private',
      };

      const response = await request(app)
        .put('/profile/privacy')
        .set('Authorization', `Bearer ${token}`)
        .send({ privacy: settings });

      expect(response.status).toBe(200);
      expect(response.body).toEqual(settings);
    });

    it('should validate privacy settings', async () => {
      const response = await request(app)
        .put('/profile/privacy')
        .set('Authorization', `Bearer ${token}`)
        .send({
          privacy: {
            profileVisibility: 'invalid',
          },
        });

      expect(response.status).toBe(400);
    });
  });
});
