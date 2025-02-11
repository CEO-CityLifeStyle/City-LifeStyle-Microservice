const request = require('supertest');
const app = require('../../src/app');
const User = require('../../src/models/user');
const { createTestUser } = require('../utils/test-utils');

// Mock email service
jest.mock('../../src/services/emailService', () => ({
  sendTemplateEmail: jest.fn().mockResolvedValue(true)
}));

// Mock websocket service
jest.mock('../../src/services/websocketService', () => ({
  notifyUser: jest.fn().mockResolvedValue(true),
  broadcastToRoom: jest.fn().mockResolvedValue(true)
}));

describe('Auth Routes', () => {
  describe('POST /api/auth/register', () => {
    it('should register a new user', async () => {
      const userData = {
        email: 'newuser@example.com',
        password: 'password123',
        name: 'New User'
      };

      const response = await request(app)
        .post('/api/auth/register')
        .send(userData)
        .expect(201);

      expect(response.body).toHaveProperty('token');
      expect(response.body.user).toEqual(expect.objectContaining({
        email: userData.email,
        name: userData.name,
      }));
      expect(response.body.user).not.toHaveProperty('password');

      const user = await User.findOne({ email: userData.email });
      expect(user).toBeTruthy();
      expect(user.password).not.toBe(userData.password);
    });

    it('should not register a user with existing email', async () => {
      const { user } = await createTestUser();

      const response = await request(app)
        .post('/api/auth/register')
        .send({
          email: user.email,
          password: 'password123',
          name: 'Another User'
        })
        .expect(400);

      expect(response.body).toHaveProperty('error', 'User already exists');
    });
  });

  describe('POST /api/auth/login', () => {
    it('should login with correct credentials', async () => {
      const password = 'password123';
      const { user } = await createTestUser({ password });

      const response = await request(app)
        .post('/api/auth/login')
        .send({
          email: user.email,
          password
        })
        .expect(200);

      expect(response.body).toHaveProperty('token');
      expect(response.body.user).toEqual(expect.objectContaining({
        email: user.email,
        name: user.name,
      }));
      expect(response.body.user).not.toHaveProperty('password');

      const savedUser = await User.findOne({ email: user.email });
      expect(savedUser).toBeTruthy();
      expect(savedUser.password).not.toBe(password);
    });

    it('should not login with incorrect password', async () => {
      const { user } = await createTestUser();

      const response = await request(app)
        .post('/api/auth/login')
        .send({
          email: user.email,
          password: 'wrongpassword'
        })
        .expect(401);

      expect(response.body).toHaveProperty('error', 'Invalid credentials');
    });

    it('should not login with non-existent email', async () => {
      const response = await request(app)
        .post('/api/auth/login')
        .send({
          email: 'nonexistent@example.com',
          password: 'password123'
        })
        .expect(401);

      expect(response.body).toHaveProperty('error', 'Invalid credentials');
    });
  });

  describe('GET /api/auth/profile', () => {
    it('should get current user profile', async () => {
      const { user, token } = await createTestUser();

      const response = await request(app)
        .get('/api/auth/profile')
        .set('Authorization', `Bearer ${token}`)
        .expect(200);

      expect(response.body).toEqual(expect.objectContaining({
        email: user.email,
        name: user.name,
      }));
      expect(response.body).not.toHaveProperty('password');
    });

    it('should not get profile without auth token', async () => {
      const response = await request(app)
        .get('/api/auth/profile')
        .expect(401);

      expect(response.body).toHaveProperty('error', 'Please authenticate.');
    });

    it('should not get profile with invalid auth token', async () => {
      const response = await request(app)
        .get('/api/auth/profile')
        .set('Authorization', 'Bearer invalid-token')
        .expect(401);

      expect(response.body).toHaveProperty('error', 'Please authenticate.');
    });
  });

  describe('PUT /api/auth/profile', () => {
    it('should update user profile', async () => {
      const { user, token } = await createTestUser();
      const updateData = {
        name: 'Updated Name',
        email: 'updated@example.com'
      };

      const response = await request(app)
        .put('/api/auth/profile')
        .set('Authorization', `Bearer ${token}`)
        .send(updateData)
        .expect(200);

      expect(response.body).toEqual(expect.objectContaining({
        name: updateData.name,
        email: updateData.email,
      }));
      expect(response.body).not.toHaveProperty('password');

      const updatedUser = await User.findById(user._id);
      expect(updatedUser.name).toBe(updateData.name);
      expect(updatedUser.email).toBe(updateData.email);
    });

    it('should not update profile without auth token', async () => {
      const response = await request(app)
        .put('/api/auth/profile')
        .send({ name: 'Updated Name' })
        .expect(401);

      expect(response.body).toHaveProperty('error', 'Please authenticate.');
    });

    it('should not update profile with invalid updates', async () => {
      const { token } = await createTestUser();
      const response = await request(app)
        .put('/api/auth/profile')
        .set('Authorization', `Bearer ${token}`)
        .send({ invalidField: 'value' })
        .expect(400);

      expect(response.body).toHaveProperty('error', 'Invalid updates');
    });
  });
});
