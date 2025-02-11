const Queue = require('bull');
const logger = require('./logger');

// Queue configurations
const defaultConfig = {
  redis: {
    port: process.env.REDIS_PORT || 6379,
    host: process.env.REDIS_HOST || 'localhost',
    password: process.env.REDIS_PASSWORD,
  },
  defaultJobOptions: {
    attempts: 3,
    backoff: {
      type: 'exponential',
      delay: 1000,
    },
    removeOnComplete: true,
  },
};

// Create queues
const emailQueue = new Queue('email', defaultConfig);
const notificationQueue = new Queue('notification', defaultConfig);
const imageProcessingQueue = new Queue('imageProcessing', defaultConfig);
const analyticsQueue = new Queue('analytics', defaultConfig);

// Error handling for queues
const queues = [emailQueue, notificationQueue, imageProcessingQueue, analyticsQueue];

queues.forEach(queue => {
  queue.on('error', (error) => {
    logger.error(`Queue ${queue.name} error:`, error);
  });

  queue.on('failed', (job, error) => {
    logger.error(`Job ${job.id} in ${queue.name} failed:`, error);
  });

  queue.on('completed', (job) => {
    logger.debug(`Job ${job.id} in ${queue.name} completed`);
  });
});

module.exports = {
  emailQueue,
  notificationQueue,
  imageProcessingQueue,
  analyticsQueue,
};
