const winston = require('winston');
const expressWinston = require('express-winston');
const fs = require('fs');
const path = require('path');

// Ensure logs directory exists
const logsDir = path.join(__dirname, '../../logs');
if (!fs.existsSync(logsDir)) {
  fs.mkdirSync(logsDir, { recursive: true });
}

// Create Winston logger instance
const logger = winston.createLogger({
  level: process.env.LOG_LEVEL || 'info',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.json()
  ),
  transports: [
    new winston.transports.File({
      filename: path.join(logsDir, 'error.log'),
      level: 'error',
      maxsize: 5242880, // 5MB
      maxFiles: 5,
      handleExceptions: true
    }),
    new winston.transports.File({
      filename: path.join(logsDir, 'combined.log'),
      maxsize: 5242880, // 5MB
      maxFiles: 5,
      handleExceptions: true
    })
  ]
});

// Add console transport in development
if (process.env.NODE_ENV !== 'production') {
  logger.add(
    new winston.transports.Console({
      format: winston.format.combine(
        winston.format.colorize(),
        winston.format.simple()
      ),
      handleExceptions: true
    })
  );
}

// Express Winston middleware for request logging
const requestLogger = expressWinston.logger({
  winstonInstance: logger,
  meta: true,
  msg: 'HTTP {{req.method}} {{req.url}}',
  expressFormat: true,
  colorize: process.env.NODE_ENV !== 'production',
  ignoreRoute: (req) => {
    // Ignore health check endpoints
    return req.url === '/health' || req.url === '/ping';
  }
});

// Express Winston middleware for error logging
const errorLogger = expressWinston.errorLogger({
  winstonInstance: logger,
  meta: true,
  msg: '{{err.message}}',
  colorize: process.env.NODE_ENV !== 'production'
});

// Custom logging functions
const logInfo = (message, meta = {}) => {
  logger.info(message, { meta });
};

const logError = (message, error, meta = {}) => {
  logger.error(message, {
    error: error.message,
    stack: error.stack,
    ...meta
  });
};

const logWarning = (message, meta = {}) => {
  logger.warn(message, { meta });
};

const logDebug = (message, meta = {}) => {
  logger.debug(message, { meta });
};

// Custom middleware to log route performance
const performanceLogger = (req, res, next) => {
  const start = process.hrtime();

  res.on('finish', () => {
    const [seconds, nanoseconds] = process.hrtime(start);
    const duration = seconds * 1000 + nanoseconds / 1000000;

    logger.info(`${req.method} ${req.originalUrl}`, {
      method: req.method,
      url: req.originalUrl,
      status: res.statusCode,
      duration: `${duration.toFixed(3)} ms`
    });
  });

  next();
};

// Health check middleware
async function healthCheck(req, res) {
  try {
    // Check MongoDB connection
    const db = req.app.get('db');
    const mongoStatus = db && await db.ping().then(() => true).catch(() => false);

    // Check Redis connection if available
    const redis = req.app.get('redis');
    const redisStatus = redis ? await redis.ping().then(() => true).catch(() => false) : true;

    // Get system metrics
    const metrics = {
      uptime: process.uptime(),
      responseTime: process.hrtime(),
      memoryUsage: {
        heapTotal: Math.round(process.memoryUsage().heapTotal / 1024 / 1024) + 'MB',
        heapUsed: Math.round(process.memoryUsage().heapUsed / 1024 / 1024) + 'MB',
        rss: Math.round(process.memoryUsage().rss / 1024 / 1024) + 'MB'
      },
      resourceUsage: process.resourceUsage()
    };

    const response = {
      status: mongoStatus && redisStatus ? 'ok' : 'degraded',
      timestamp: new Date().toISOString(),
      services: {
        mongodb: mongoStatus ? 'connected' : 'disconnected',
        redis: redisStatus ? 'connected' : 'disconnected'
      },
      metrics
    };

    // Set appropriate status code
    const statusCode = response.status === 'ok' ? 200 : 503;
    return res.status(statusCode).json(response);

  } catch (error) {
    logger.error('Health check failed', error);
    return res.status(500).json({
      status: 'error',
      message: 'Error performing health check',
      error: error.message,
      timestamp: new Date().toISOString()
    });
  }
}

module.exports = {
  requestLogger,
  errorLogger,
  logInfo,
  logError,
  logWarning,
  logDebug,
  logger,
  performanceLogger,
  healthCheck
};
