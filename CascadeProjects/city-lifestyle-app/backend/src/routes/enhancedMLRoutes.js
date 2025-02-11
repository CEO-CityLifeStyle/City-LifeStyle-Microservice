const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const admin = require('../middleware/admin');
const enhancedMLController = require('../controllers/enhancedMLController');

// Protected endpoints (require authentication)
router.get('/models/:modelName/versions', auth, enhancedMLController.getModelVersions);
router.get('/models/:modelName/metrics/:version', auth, enhancedMLController.getModelMetrics);

// Admin endpoints
router.post('/models/train', [auth, admin], enhancedMLController.trainModel);
router.post('/models/:modelName/versions/:version/deploy', [auth, admin], enhancedMLController.deployModelVersion);
router.post('/models/:modelName/versions/:version/archive', [auth, admin], enhancedMLController.archiveModelVersion);
router.get('/models/:modelName/compare', [auth, admin], enhancedMLController.compareModelVersions);

module.exports = router;
