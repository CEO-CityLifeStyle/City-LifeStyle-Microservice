const express = require('express');
const { body } = require('express-validator');
const auth = require('../middleware/auth');
const admin = require('../middleware/admin');
const batchOperationsController = require('../controllers/batchOperationsController');
const validate = require('../middleware/validate');

const router = express.Router();

// Middleware to check if user is admin
router.use(auth, admin);

// Validation middleware
const batchUpdateValidation = [
  body('reviewIds').isArray().notEmpty().withMessage('Review IDs array is required'),
  body('updates').isObject().notEmpty().withMessage('Updates object is required'),
];

const batchModerateValidation = [
  body('reviewIds').isArray().notEmpty().withMessage('Review IDs array is required'),
  body('moderationData.status')
    .isIn(['pending', 'approved', 'rejected'])
    .withMessage('Invalid status'),
  body('moderationData.moderationNote')
    .optional()
    .trim()
    .isLength({ min: 1, max: 500 })
    .withMessage('Moderation note must be between 1 and 500 characters'),
];

// Batch update reviews
router.post(
  '/update',
  batchUpdateValidation,
  validate,
  batchOperationsController.batchUpdateReviews
);

// Batch delete reviews
router.post(
  '/delete',
  [body('reviewIds').isArray().notEmpty()],
  validate,
  batchOperationsController.batchDeleteReviews
);

// Batch moderate reviews
router.post(
  '/moderate',
  batchModerateValidation,
  validate,
  batchOperationsController.batchModerateReviews
);

// Batch export reviews
router.post(
  '/export',
  [body('reviewIds').isArray().notEmpty()],
  validate,
  batchOperationsController.batchExportReviews
);

module.exports = router;
