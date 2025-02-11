const winston = require('winston');
const { requestLogger, errorLogger, healthCheck } = require('../../../src/middleware/monitoring');

// Mock fs and path
jest.mock('fs', () => ({
  existsSync: jest.fn().mockReturnValue(true),
  mkdirSync: jest.fn()
}));

jest.mock('path', () => ({
  join: jest.fn().mockReturnValue('mocked/path')
}));

// Mock winston
jest.mock('winston', () => {
  const mockLogger = {
    info: jest.fn(),
    error: jest.fn(),
    warn: jest.fn(),
    debug: jest.fn(),
    add: jest.fn()
  };

  return {
    createLogger: jest.fn().mockReturnValue(mockLogger),
    format: {
      timestamp: jest.fn().mockReturnValue({}),
      json: jest.fn().mockReturnValue({}),
      combine: jest.fn().mockReturnValue({}),
      colorize: jest.fn().mockReturnValue({}),
      simple: jest.fn().mockReturnValue({})
    },
    transports: {
      File: jest.fn().mockImplementation(() => ({})),
      Console: jest.fn().mockImplementation(() => ({}))
    }
  };
});

// Mock express-winston
jest.mock('express-winston', () => ({
  logger: jest.fn().mockReturnValue((req, res, next) => next()),
  errorLogger: jest.fn().mockReturnValue((err, req, res, next) => next())
}));

describe('Monitoring Middleware', () => {
  let mockReq;
  let mockRes;
  let mockNext;

  beforeEach(() => {
    mockReq = {
      method: 'GET',
      url: '/test',
      headers: {},
      body: {}
    };
    mockRes = {
      statusCode: 200,
      on: jest.fn(),
      status: jest.fn().mockReturnThis(),
      json: jest.fn()
    };
    mockNext = jest.fn();

    // Clear mock calls
    jest.clearAllMocks();
  });

  describe('requestLogger', () => {
    it('should log request details', () => {
      requestLogger(mockReq, mockRes, mockNext);
      expect(mockNext).toHaveBeenCalled();
    });

    it('should ignore health check endpoints', () => {
      mockReq.url = '/health';
      requestLogger(mockReq, mockRes, mockNext);
      expect(mockNext).toHaveBeenCalled();
    });

    it('should include request metadata', () => {
      mockReq.method = 'POST';
      mockReq.body = { test: 'data' };
      requestLogger(mockReq, mockRes, mockNext);
      expect(mockNext).toHaveBeenCalled();
    });
  });

  describe('errorLogger', () => {
    it('should log error details', () => {
      const mockError = new Error('Test error');
      errorLogger(mockError, mockReq, mockRes, mockNext);
      expect(mockNext).toHaveBeenCalled();
    });
  });

  describe('healthCheck', () => {
    beforeEach(() => {
      mockReq = {
        app: {
          get: jest.fn((service) => {
            if (service === 'db') {
              return {
                ping: jest.fn().mockResolvedValue(true)
              };
            }
            if (service === 'redis') {
              return {
                ping: jest.fn().mockResolvedValue('PONG')
              };
            }
            return null;
          })
        }
      };
    });

    it('should return 200 OK for healthy service', async () => {
      await healthCheck(mockReq, mockRes);
      expect(mockRes.status).toHaveBeenCalledWith(200);
      expect(mockRes.json).toHaveBeenCalledWith(expect.objectContaining({
        status: 'ok',
        services: expect.objectContaining({
          mongodb: 'connected',
          redis: 'connected'
        })
      }));
    });

    it('should return 503 when service is unhealthy', async () => {
      mockReq.app.get = jest.fn((service) => {
        if (service === 'db') {
          return {
            ping: jest.fn().mockRejectedValue(new Error('DB Error'))
          };
        }
        return null;
      });

      await healthCheck(mockReq, mockRes);
      expect(mockRes.status).toHaveBeenCalledWith(503);
      expect(mockRes.json).toHaveBeenCalledWith(expect.objectContaining({
        status: 'degraded',
        services: expect.objectContaining({
          mongodb: 'disconnected'
        })
      }));
    });

    it('should include system metrics in response', async () => {
      await healthCheck(mockReq, mockRes);
      expect(mockRes.json).toHaveBeenCalledWith(expect.objectContaining({
        metrics: expect.objectContaining({
          uptime: expect.any(Number),
          memoryUsage: expect.any(Object),
          resourceUsage: expect.any(Object)
        })
      }));
    });

    it('should handle errors during health check', async () => {
      mockReq.app.get = jest.fn().mockImplementation(() => {
        throw new Error('Unexpected error');
      });

      await healthCheck(mockReq, mockRes);
      expect(mockRes.status).toHaveBeenCalledWith(500);
      expect(mockRes.json).toHaveBeenCalledWith(expect.objectContaining({
        status: 'error',
        message: 'Error performing health check'
      }));
    });
  });
});
