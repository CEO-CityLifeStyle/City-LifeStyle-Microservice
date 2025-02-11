const express = require('express');
const auth = require('../middleware/auth');
const reviewController = require('../controllers/reviewController');
const validate = require('../middleware/validate');
const { createReviewSchema, updateReviewSchema } = require('../validations/reviewValidation');

const router = express.Router();

// Create review
router.post('/:placeId', auth, validate(createReviewSchema), reviewController.createReview);

// Update review
router.put('/:id', auth, validate(updateReviewSchema), reviewController.updateReview);

// Delete review
router.delete('/:id', auth, reviewController.deleteReview);

// Get reviews for a place
router.get('/place/:placeId', reviewController.getPlaceReviews);

// Get user's reviews
router.get('/user', auth, reviewController.getUserReviews);

module.exports = router;
