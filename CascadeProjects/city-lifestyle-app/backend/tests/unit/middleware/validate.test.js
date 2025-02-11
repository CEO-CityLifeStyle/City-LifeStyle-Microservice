const validate = require('../../../src/middleware/validate');
const Joi = require('joi');

describe('Validation Middleware', () => {
  let req, res, next;

  beforeEach(() => {
    req = {
      body: {},
      query: {},
      params: {}
    };
    res = {
      status: jest.fn().mockReturnThis(),
      json: jest.fn()
    };
    next = jest.fn();
  });

  it('should pass validation with valid data', () => {
    const schema = {
      body: Joi.object({
        name: Joi.string().required(),
        age: Joi.number().min(0)
      })
    };

    req.body = {
      name: 'Test User',
      age: 25
    };

    validate(schema)(req, res, next);
    expect(next).toHaveBeenCalled();
    expect(res.status).not.toHaveBeenCalled();
  });

  it('should fail validation with invalid data', () => {
    const schema = {
      body: Joi.object({
        name: Joi.string().required(),
        age: Joi.number().min(0)
      })
    };

    req.body = {
      age: -1 // Invalid age
    };

    validate(schema)(req, res, next);
    expect(next).not.toHaveBeenCalled();
    expect(res.status).toHaveBeenCalledWith(400);
    expect(res.json).toHaveBeenCalledWith(expect.objectContaining({
      error: expect.any(String)
    }));
  });

  it('should handle missing required fields', () => {
    const schema = {
      body: Joi.object({
        name: Joi.string().required(),
        email: Joi.string().email().required()
      })
    };

    req.body = {
      name: 'Test User'
      // Missing email
    };

    validate(schema)(req, res, next);
    expect(next).not.toHaveBeenCalled();
    expect(res.status).toHaveBeenCalledWith(400);
    expect(res.json).toHaveBeenCalledWith(expect.objectContaining({
      error: expect.stringContaining('email')
    }));
  });

  it('should validate query parameters', () => {
    const schema = {
      query: Joi.object({
        page: Joi.number().min(1),
        limit: Joi.number().min(1).max(100)
      })
    };

    req.query = {
      page: '2',
      limit: '50'
    };

    validate(schema)(req, res, next);
    expect(next).toHaveBeenCalled();
    expect(res.status).not.toHaveBeenCalled();
  });

  it('should validate params', () => {
    const schema = {
      params: Joi.object({
        id: Joi.string().length(24) // MongoDB ObjectId
      })
    };

    req.params = {
      id: '507f1f77bcf86cd799439011'
    };

    validate(schema)(req, res, next);
    expect(next).toHaveBeenCalled();
    expect(res.status).not.toHaveBeenCalled();
  });

  it('should handle invalid param format', () => {
    const schema = {
      params: Joi.object({
        id: Joi.string().length(24) // MongoDB ObjectId
      })
    };

    req.params = {
      id: 'invalid-id'
    };

    validate(schema)(req, res, next);
    expect(next).not.toHaveBeenCalled();
    expect(res.status).toHaveBeenCalledWith(400);
    expect(res.json).toHaveBeenCalledWith(expect.objectContaining({
      error: expect.stringContaining('id')
    }));
  });
});
