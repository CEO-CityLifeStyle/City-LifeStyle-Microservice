const logger = require('../config/logger');
const { emailQueue } = require('../config/bull');
const { sendEmail } = require('../services/emailService');

emailQueue.process(async (job) => {
  const { to, subject, text, html } = job.data;
  
  try {
    await sendEmail({ to, subject, text, html });
    logger.info(`Email sent to ${to}`);
  } catch (error) {
    logger.error('Email sending failed:', error);
    throw error; // Retry job
  }
});
