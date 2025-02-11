const mongoose = require('mongoose');
const Review = require('../models/review');
const Place = require('../models/place');
const User = require('../models/user');
const emailService = require('../services/emailService');
const websocketService = require('../services/websocketService');
const { withTransaction } = require('../utils/db');

class ReviewController {
  // Create a new review
  async createReview(req, res) {
    try {
      const place = await Place.findById(req.params.placeId);
      if (!place) {
        return res.status(404).json({ message: 'Place not found' });
      }

      // Check if user has already reviewed this place
      const existingReview = await Review.findOne({
        place: req.params.placeId,
        user: req.user._id
      });

      if (existingReview) {
        return res.status(400).json({ message: 'You have already reviewed this place' });
      }

      const review = new Review({
        ...req.body,
        place: req.params.placeId,
        user: req.user._id
      });

      return withTransaction(async (session) => {
        await review.save({ session });
        await place.addReview(review._id);
        await req.user.addReview(review._id);
        
        // Populate user and place details
        await review.populate('user', 'name avatar');
        await review.populate('place', 'name');

        res.status(201).json(review);
      });
    } catch (error) {
      console.error('Error creating review:', error);
      res.status(500).json({ message: 'Error creating review' });
    }
  }

  // Update a review
  async updateReview(req, res) {
    try {
      const review = await Review.findById(req.params.id);
      if (!review) {
        return res.status(404).json({ message: 'Review not found' });
      }

      // Check if user owns the review
      if (review.user.toString() !== req.user._id.toString()) {
        return res.status(403).json({ message: 'You can only update your own reviews' });
      }

      // Update allowed fields
      const updates = req.body;
      const allowedUpdates = ['rating', 'comment'];
      const isValidOperation = Object.keys(updates).every(update => allowedUpdates.includes(update));

      if (!isValidOperation) {
        return res.status(400).json({ message: 'Invalid updates' });
      }

      return withTransaction(async (session) => {
        Object.assign(review, updates);
        await review.save({ session });

        const place = await Place.findById(review.place);
        await place.updateRating();

        // Populate user and place details
        await review.populate('user', 'name avatar');
        await review.populate('place', 'name');

        res.json(review);
      });
    } catch (error) {
      console.error('Error updating review:', error);
      res.status(500).json({ message: 'Error updating review' });
    }
  }

  // Delete a review
  async deleteReview(req, res) {
    try {
      const review = await Review.findById(req.params.id);
      if (!review) {
        return res.status(404).json({ message: 'Review not found' });
      }

      // Check if user owns the review
      if (review.user.toString() !== req.user._id.toString()) {
        return res.status(403).json({ message: 'You can only delete your own reviews' });
      }

      return withTransaction(async (session) => {
        const place = await Place.findById(review.place);
        const user = await User.findById(review.user);

        await review.deleteOne({ session });
        await place.removeReview(review._id);
        await user.removeReview(review._id);

        res.json({ message: 'Review deleted successfully' });
      });
    } catch (error) {
      console.error('Error deleting review:', error);
      res.status(500).json({ message: 'Error deleting review' });
    }
  }

  // Get reviews for a place
  async getPlaceReviews(req, res) {
    try {
      const { page = 1, limit = 10 } = req.query;

      if (!mongoose.Types.ObjectId.isValid(req.params.placeId)) {
        return res.status(400).json({ error: 'Invalid place ID' });
      }

      const skip = (parseInt(page) - 1) * parseInt(limit);
      const total = await Review.countDocuments({ place: req.params.placeId });

      const reviews = await Review.find({ place: req.params.placeId })
        .populate('user', 'name email avatar')
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(parseInt(limit));

      return res.json({
        reviews,
        currentPage: parseInt(page),
        totalPages: Math.ceil(total / parseInt(limit)),
        total
      });
    } catch (error) {
      if (error.name === 'CastError') {
        return res.status(400).json({ error: 'Invalid ID format' });
      }
      res.status(500).json({ error: 'Server error' });
    }
  }

  // Get user's reviews
  async getUserReviews(req, res) {
    try {
      const userId = req.user._id;
      const { page = 1, limit = 10 } = req.query;

      const skip = (parseInt(page) - 1) * parseInt(limit);
      const total = await Review.countDocuments({ user: userId });

      const reviews = await Review.find({ user: userId })
        .populate('place', 'name address category')
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(parseInt(limit));

      res.json({
        reviews,
        currentPage: parseInt(page),
        totalPages: Math.ceil(total / parseInt(limit)),
        total
      });
    } catch (error) {
      if (error.name === 'CastError') {
        return res.status(400).json({ error: 'Invalid ID format' });
      }
      res.status(500).json({ error: 'Server error' });
    }
  }
}

module.exports = new ReviewController();
