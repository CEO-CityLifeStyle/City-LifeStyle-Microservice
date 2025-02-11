const express = require('express');
const { body } = require('express-validator');
const auth = require('../middleware/auth');
const admin = require('../middleware/admin');
const adminController = require('../controllers/adminController');
const validate = require('../middleware/validate');

const router = express.Router();

// Middleware to check if user is admin
router.use(auth, admin);

// Validation middleware
const userUpdateValidation = [
  body('role')
    .optional()
    .isIn(['user', 'admin', 'moderator'])
    .withMessage('Invalid role'),
  body('status')
    .optional()
    .isIn(['active', 'inactive', 'suspended'])
    .withMessage('Invalid status'),
];

const reviewModerationValidation = [
  body('status')
    .isIn(['pending', 'approved', 'rejected'])
    .withMessage('Invalid status'),
  body('moderationNote')
    .optional()
    .trim()
    .isLength({ min: 1, max: 500 })
    .withMessage('Moderation note must be between 1 and 500 characters'),
];

// Dashboard routes
router.get('/dashboard', adminController.getDashboardOverview.bind(adminController));
router.get('/analytics', adminController.getAnalytics.bind(adminController));
router.get('/health', adminController.getSystemHealth.bind(adminController));

// User management routes
router.get('/users', adminController.getUsers.bind(adminController));
router.patch(
  '/users/:userId',
  userUpdateValidation,
  validate,
  adminController.updateUser.bind(adminController)
);
router.get(
  '/users/:userId/activity',
  adminController.getUserActivity.bind(adminController)
);

// Event management routes
router.get('/events', adminController.getEvents.bind(adminController));
router.patch(
  '/events/:eventId',
  adminController.updateEvent.bind(adminController)
);

// Place management routes
router.get('/places', adminController.getPlaces.bind(adminController));
router.patch(
  '/places/:placeId',
  adminController.updatePlace.bind(adminController)
);

// Review management routes
router.get('/reviews', adminController.getReviews.bind(adminController));
router.patch(
  '/reviews/:reviewId/moderate',
  reviewModerationValidation,
  validate,
  adminController.moderateReview.bind(adminController)
);

module.exports = router;
