const logger = require('../config/logger');
const { analyticsQueue } = require('../config/bull');
const { processAnalytics, generateReport } = require('../services/analyticsService');

analyticsQueue.process(async (job) => {
  const { type, data, options } = job.data;
  
  try {
    // Process analytics data
    const results = await processAnalytics(type, data);
    
    // Generate report if requested
    if (options?.generateReport) {
      await generateReport(results, options.reportFormat);
    }
    
    logger.info(`Analytics processed for type: ${type}`);
    return results;
  } catch (error) {
    logger.error('Analytics processing failed:', error);
    throw error; // Retry job
  }
});
