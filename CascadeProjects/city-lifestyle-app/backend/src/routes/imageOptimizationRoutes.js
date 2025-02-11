const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const admin = require('../middleware/admin');
const imageOptimizationController = require('../controllers/imageOptimizationController');
const upload = require('../middleware/upload');

// Public endpoints
router.get('/images/:id', imageOptimizationController.getOptimizedImage);
router.get('/images/:id/metadata', imageOptimizationController.getImageMetadata);

// Protected endpoints (require authentication)
router.post('/images/optimize', 
  [auth, upload.single('image')], 
  imageOptimizationController.optimizeImage
);
router.post('/images/batch-optimize', 
  [auth, upload.array('images', 10)], 
  imageOptimizationController.optimizeBatchImages
);
router.post('/images/url', 
  auth, 
  imageOptimizationController.optimizeImageFromUrl
);

// Admin endpoints
router.get('/images/stats', [auth, admin], imageOptimizationController.getOptimizationStats);
router.post('/images/settings', [auth, admin], imageOptimizationController.updateOptimizationSettings);
router.delete('/images/cache', [auth, admin], imageOptimizationController.clearImageCache);
router.get('/images/queue', [auth, admin], imageOptimizationController.getOptimizationQueue);

module.exports = router;
