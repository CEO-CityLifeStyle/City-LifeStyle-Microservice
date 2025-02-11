const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const admin = require('../middleware/admin');
const abTestingController = require('../controllers/abTestingController');

// Protected endpoints (require authentication)
router.get('/experiments/active', auth, abTestingController.getActiveExperiments);
router.get('/experiments/:id/variant', auth, abTestingController.getUserVariant);
router.post('/experiments/:id/event', auth, abTestingController.logExperimentEvent);

// Admin endpoints
router.post('/experiments', [auth, admin], abTestingController.createExperiment);
router.put('/experiments/:id', [auth, admin], abTestingController.updateExperiment);
router.delete('/experiments/:id', [auth, admin], abTestingController.deleteExperiment);
router.get('/experiments', [auth, admin], abTestingController.getAllExperiments);
router.get('/experiments/:id/results', [auth, admin], abTestingController.getExperimentResults);
router.post('/experiments/:id/start', [auth, admin], abTestingController.startExperiment);
router.post('/experiments/:id/stop', [auth, admin], abTestingController.stopExperiment);
router.post('/experiments/:id/reset', [auth, admin], abTestingController.resetExperiment);

module.exports = router;
