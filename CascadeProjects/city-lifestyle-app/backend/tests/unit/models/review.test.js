const mongoose = require('mongoose');
const Review = require('../../../src/models/review');

describe('Review Model', () => {
  beforeEach(async () => {
    await Review.deleteMany({});
  });

  it('should create a review with valid data', async () => {
    const validReview = {
      rating: 4,
      comment: 'Great place!',
      user: new mongoose.Types.ObjectId(),
      place: new mongoose.Types.ObjectId(),
      status: 'approved'
    };

    const review = await Review.create(validReview);
    expect(review.rating).toBe(validReview.rating);
    expect(review.comment).toBe(validReview.comment);
    expect(review.status).toBe(validReview.status);
  });

  it('should fail to create a review without required fields', async () => {
    const invalidReview = {
      rating: 4,
      status: 'approved'
    };

    await expect(Review.create(invalidReview)).rejects.toThrow();
  });

  it('should validate rating range', async () => {
    const reviewWithInvalidRating = {
      rating: 6, // Invalid rating (should be 1-5)
      comment: 'Great place!',
      user: new mongoose.Types.ObjectId(),
      place: new mongoose.Types.ObjectId(),
      status: 'approved'
    };

    await expect(Review.create(reviewWithInvalidRating)).rejects.toThrow();
  });

  it('should calculate average rating for a place', async () => {
    const placeId = new mongoose.Types.ObjectId();
    
    await Review.create([
      {
        rating: 4,
        comment: 'Good',
        user: new mongoose.Types.ObjectId(),
        place: placeId,
        status: 'approved'
      },
      {
        rating: 5,
        comment: 'Excellent',
        user: new mongoose.Types.ObjectId(),
        place: placeId,
        status: 'approved'
      }
    ]);

    const stats = await Review.getAverageRating(placeId);
    expect(stats.averageRating).toBe(4.5);
    expect(stats.totalReviews).toBe(2);
  });

  it('should only count approved reviews in average rating', async () => {
    const placeId = new mongoose.Types.ObjectId();
    
    await Review.create([
      {
        rating: 4,
        comment: 'Good',
        user: new mongoose.Types.ObjectId(),
        place: placeId,
        status: 'approved'
      },
      {
        rating: 1,
        comment: 'Bad',
        user: new mongoose.Types.ObjectId(),
        place: placeId,
        status: 'pending'
      }
    ]);

    const stats = await Review.getAverageRating(placeId);
    expect(stats.averageRating).toBe(4);
    expect(stats.totalReviews).toBe(1);
  });

  it('should validate review status enum', async () => {
    const reviewWithInvalidStatus = {
      rating: 4,
      comment: 'Good',
      user: new mongoose.Types.ObjectId(),
      place: new mongoose.Types.ObjectId(),
      status: 'invalid_status'
    };

    await expect(Review.create(reviewWithInvalidStatus)).rejects.toThrow();
  });

  it('should handle review likes', async () => {
    const userId = new mongoose.Types.ObjectId();
    const review = await Review.create({
      rating: 4,
      comment: 'Good',
      user: new mongoose.Types.ObjectId(),
      place: new mongoose.Types.ObjectId(),
      status: 'approved'
    });

    await review.like(userId);
    expect(review.likes).toContainEqual(userId);

    await review.unlike(userId);
    expect(review.likes).not.toContainEqual(userId);
  });

  it('should handle review replies', async () => {
    const userId = new mongoose.Types.ObjectId();
    const review = await Review.create({
      rating: 4,
      comment: 'Good',
      user: new mongoose.Types.ObjectId(),
      place: new mongoose.Types.ObjectId(),
      status: 'approved'
    });

    const reply = await review.addReply(userId, 'Thanks for the review!');
    expect(review.replies).toHaveLength(1);
    expect(review.replies[0].user).toEqual(userId);
    expect(review.replies[0].comment).toBe('Thanks for the review!');
  });
});
