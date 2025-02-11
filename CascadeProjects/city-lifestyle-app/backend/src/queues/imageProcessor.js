const logger = require('../config/logger');
const { imageProcessingQueue } = require('../config/bull');
const { optimizeImage, generateThumbnail } = require('../services/imageService');

imageProcessingQueue.process(async (job) => {
  const { imageUrl, sizes } = job.data;
  
  try {
    // Optimize original image
    await optimizeImage(imageUrl);
    
    // Generate thumbnails for different sizes
    const thumbnails = await Promise.all(
      sizes.map(size => generateThumbnail(imageUrl, size))
    );
    
    logger.info(`Image ${imageUrl} processed with ${thumbnails.length} thumbnails`);
    return { thumbnails };
  } catch (error) {
    logger.error('Image processing failed:', error);
    throw error; // Retry job
  }
});
