const Review = require('../models/review');
const Place = require('../models/place');
const User = require('../models/user');
const emailService = require('./emailService');

class BatchOperationsService {
  // Batch update reviews
  async batchUpdateReviews(reviewIds, updates, userId) {
    try {
      const session = await Review.startSession();
      let results = { success: [], failed: [] };

      await session.withTransaction(async () => {
        for (const reviewId of reviewIds) {
          try {
            const review = await Review.findById(reviewId);
            if (!review) {
              results.failed.push({ id: reviewId, error: 'Review not found' });
              continue;
            }

            // Apply updates
            Object.keys(updates).forEach(key => {
              review[key] = updates[key];
            });

            // Add moderation info if status is updated
            if (updates.status) {
              review.moderatedAt = new Date();
              review.moderatedBy = userId;
            }

            await review.save();

            // Update place rating if review status changed
            if (updates.status) {
              const stats = await Review.getAverageRating(review.place);
              await Place.findByIdAndUpdate(review.place, {
                rating: stats.averageRating,
                totalReviews: stats.totalReviews,
              });
            }

            results.success.push(reviewId);
          } catch (error) {
            results.failed.push({ id: reviewId, error: error.message });
          }
        }
      });

      await session.endSession();
      return results;
    } catch (error) {
      throw new Error(`Batch update failed: ${error.message}`);
    }
  }

  // Batch delete reviews
  async batchDeleteReviews(reviewIds, userId) {
    try {
      const session = await Review.startSession();
      let results = { success: [], failed: [] };

      await session.withTransaction(async () => {
        for (const reviewId of reviewIds) {
          try {
            const review = await Review.findById(reviewId);
            if (!review) {
              results.failed.push({ id: reviewId, error: 'Review not found' });
              continue;
            }

            // Store place ID for rating update
            const placeId = review.place;

            await review.remove();

            // Update place rating
            const stats = await Review.getAverageRating(placeId);
            await Place.findByIdAndUpdate(placeId, {
              rating: stats.averageRating,
              totalReviews: stats.totalReviews,
            });

            results.success.push(reviewId);
          } catch (error) {
            results.failed.push({ id: reviewId, error: error.message });
          }
        }
      });

      await session.endSession();
      return results;
    } catch (error) {
      throw new Error(`Batch delete failed: ${error.message}`);
    }
  }

  // Batch moderate reviews
  async batchModerateReviews(reviewIds, moderationData, userId) {
    try {
      const { status, moderationNote } = moderationData;
      const session = await Review.startSession();
      let results = { success: [], failed: [] };

      await session.withTransaction(async () => {
        for (const reviewId of reviewIds) {
          try {
            const review = await Review.findById(reviewId)
              .populate('user', 'email name')
              .populate('place', 'name');

            if (!review) {
              results.failed.push({ id: reviewId, error: 'Review not found' });
              continue;
            }

            // Update review status and moderation info
            review.status = status;
            review.moderationNote = moderationNote;
            review.moderatedAt = new Date();
            review.moderatedBy = userId;

            await review.save();

            // Update place rating
            const stats = await Review.getAverageRating(review.place._id);
            await Place.findByIdAndUpdate(review.place._id, {
              rating: stats.averageRating,
              totalReviews: stats.totalReviews,
            });

            // Send notification email to user
            await emailService.sendReviewModerationEmail(
              review.user.email,
              {
                userName: review.user.name,
                placeName: review.place.name,
                status,
                moderationNote,
              }
            );

            results.success.push(reviewId);
          } catch (error) {
            results.failed.push({ id: reviewId, error: error.message });
          }
        }
      });

      await session.endSession();
      return results;
    } catch (error) {
      throw new Error(`Batch moderation failed: ${error.message}`);
    }
  }

  // Batch export reviews
  async batchExportReviews(reviewIds, format = 'json') {
    try {
      const reviews = await Review.find({ _id: { $in: reviewIds } })
        .populate('user', 'name email')
        .populate('place', 'name category')
        .lean();

      if (format === 'csv') {
        return this._convertToCSV(reviews);
      }

      return reviews;
    } catch (error) {
      throw new Error(`Batch export failed: ${error.message}`);
    }
  }

  // Helper method to convert to CSV
  _convertToCSV(data) {
    const fields = [
      'id',
      'rating',
      'comment',
      'user.name',
      'place.name',
      'place.category',
      'status',
      'createdAt',
    ];

    const csv = data.map(item => {
      return fields.map(field => {
        const value = field.split('.').reduce((obj, key) => obj[key], item);
        return `"${value ? value.toString().replace(/"/g, '""') : ''}"`;
      }).join(',');
    });

    return `${fields.join(',')}\n${csv.join('\n')}`;
  }
}

module.exports = new BatchOperationsService();
