const Review = require('../models/review');
const Place = require('../models/place');
const User = require('../models/user');
const emailService = require('./emailService');
const analyticsService = require('./analyticsService');
const reviewAnalyticsService = require('./reviewAnalyticsService');

class ReportingService {
  // Generate daily activity report
  async generateDailyReport() {
    try {
      const today = new Date();
      const yesterday = new Date(today);
      yesterday.setDate(yesterday.getDate() - 1);

      const [
        reviewMetrics,
        userMetrics,
        placeMetrics,
        moderationMetrics,
      ] = await Promise.all([
        this._getReviewMetrics(yesterday, today),
        this._getUserMetrics(yesterday, today),
        this._getPlaceMetrics(yesterday, today),
        this._getModerationMetrics(yesterday, today),
      ]);

      const report = {
        date: yesterday.toISOString().split('T')[0],
        reviews: reviewMetrics,
        users: userMetrics,
        places: placeMetrics,
        moderation: moderationMetrics,
        generatedAt: new Date(),
      };

      // Store report in database
      await this._storeReport(report);

      // Send report to admins
      await this._sendReportEmail(report, 'daily');

      return report;
    } catch (error) {
      throw new Error(`Failed to generate daily report: ${error.message}`);
    }
  }

  // Generate weekly report
  async generateWeeklyReport() {
    try {
      const today = new Date();
      const lastWeek = new Date(today);
      lastWeek.setDate(lastWeek.getDate() - 7);

      const [
        reviewTrends,
        topReviewers,
        categoryInsights,
        qualityMetrics,
      ] = await Promise.all([
        reviewAnalyticsService.getReviewTrends(lastWeek, today),
        reviewAnalyticsService.getTopReviewers(10),
        reviewAnalyticsService.getCategoryInsights(),
        reviewAnalyticsService.getReviewQualityMetrics(lastWeek, today),
      ]);

      const report = {
        startDate: lastWeek.toISOString().split('T')[0],
        endDate: today.toISOString().split('T')[0],
        trends: reviewTrends,
        topReviewers,
        categoryInsights,
        qualityMetrics,
        generatedAt: new Date(),
      };

      // Store report in database
      await this._storeReport(report);

      // Send report to admins
      await this._sendReportEmail(report, 'weekly');

      return report;
    } catch (error) {
      throw new Error(`Failed to generate weekly report: ${error.message}`);
    }
  }

  // Generate monthly report
  async generateMonthlyReport() {
    try {
      const today = new Date();
      const lastMonth = new Date(today);
      lastMonth.setMonth(lastMonth.getMonth() - 1);

      const [
        monthlyMetrics,
        topPlaces,
        userGrowth,
        engagementMetrics,
      ] = await Promise.all([
        this._getMonthlyMetrics(lastMonth, today),
        this._getTopPlaces(lastMonth, today),
        this._getUserGrowthMetrics(lastMonth, today),
        this._getEngagementMetrics(lastMonth, today),
      ]);

      const report = {
        startDate: lastMonth.toISOString().split('T')[0],
        endDate: today.toISOString().split('T')[0],
        metrics: monthlyMetrics,
        topPlaces,
        userGrowth,
        engagement: engagementMetrics,
        generatedAt: new Date(),
      };

      // Store report in database
      await this._storeReport(report);

      // Send report to admins
      await this._sendReportEmail(report, 'monthly');

      return report;
    } catch (error) {
      throw new Error(`Failed to generate monthly report: ${error.message}`);
    }
  }

  // Generate custom date range report
  async generateCustomReport(startDate, endDate, options = {}) {
    try {
      const {
        includeReviews = true,
        includeUsers = true,
        includePlaces = true,
        includeModeration = true,
      } = options;

      const metrics = {};

      if (includeReviews) {
        metrics.reviews = await this._getReviewMetrics(startDate, endDate);
      }
      if (includeUsers) {
        metrics.users = await this._getUserMetrics(startDate, endDate);
      }
      if (includePlaces) {
        metrics.places = await this._getPlaceMetrics(startDate, endDate);
      }
      if (includeModeration) {
        metrics.moderation = await this._getModerationMetrics(startDate, endDate);
      }

      const report = {
        startDate: startDate.toISOString().split('T')[0],
        endDate: endDate.toISOString().split('T')[0],
        metrics,
        generatedAt: new Date(),
      };

      // Store report in database
      await this._storeReport(report);

      return report;
    } catch (error) {
      throw new Error(`Failed to generate custom report: ${error.message}`);
    }
  }

  // Helper methods
  async _getReviewMetrics(startDate, endDate) {
    const pipeline = [
      {
        $match: {
          createdAt: { $gte: startDate, $lt: endDate },
        },
      },
      {
        $group: {
          _id: null,
          totalReviews: { $sum: 1 },
          averageRating: { $avg: '$rating' },
          totalLikes: { $sum: { $size: '$likes' } },
          totalHelpful: { $sum: { $size: '$helpful' } },
          totalReplies: { $sum: { $size: '$replies' } },
          ratingDistribution: { $push: '$rating' },
        },
      },
    ];

    const results = await Review.aggregate(pipeline);
    return results[0] || null;
  }

  async _getUserMetrics(startDate, endDate) {
    const pipeline = [
      {
        $match: {
          createdAt: { $gte: startDate, $lt: endDate },
        },
      },
      {
        $group: {
          _id: null,
          newUsers: { $sum: 1 },
          totalReviews: { $sum: { $size: '$reviews' } },
          averageReviews: { $avg: { $size: '$reviews' } },
        },
      },
    ];

    const results = await User.aggregate(pipeline);
    return results[0] || null;
  }

  async _getPlaceMetrics(startDate, endDate) {
    const pipeline = [
      {
        $match: {
          createdAt: { $gte: startDate, $lt: endDate },
        },
      },
      {
        $group: {
          _id: null,
          newPlaces: { $sum: 1 },
          averageRating: { $avg: '$rating' },
          totalReviews: { $sum: '$totalReviews' },
        },
      },
    ];

    const results = await Place.aggregate(pipeline);
    return results[0] || null;
  }

  async _getModerationMetrics(startDate, endDate) {
    const pipeline = [
      {
        $match: {
          moderatedAt: { $gte: startDate, $lt: endDate },
        },
      },
      {
        $group: {
          _id: '$status',
          count: { $sum: 1 },
        },
      },
    ];

    const results = await Review.aggregate(pipeline);
    return results.reduce((acc, curr) => {
      acc[curr._id] = curr.count;
      return acc;
    }, {});
  }

  async _getMonthlyMetrics(startDate, endDate) {
    // Implement monthly metrics aggregation
    return {};
  }

  async _getTopPlaces(startDate, endDate) {
    const pipeline = [
      {
        $match: {
          createdAt: { $gte: startDate, $lt: endDate },
        },
      },
      {
        $group: {
          _id: '$place',
          totalReviews: { $sum: 1 },
          averageRating: { $avg: '$rating' },
        },
      },
      {
        $sort: { totalReviews: -1 },
      },
      {
        $limit: 10,
      },
      {
        $lookup: {
          from: 'places',
          localField: '_id',
          foreignField: '_id',
          as: 'place',
        },
      },
      {
        $unwind: '$place',
      },
    ];

    return await Review.aggregate(pipeline);
  }

  async _getUserGrowthMetrics(startDate, endDate) {
    // Implement user growth metrics aggregation
    return {};
  }

  async _getEngagementMetrics(startDate, endDate) {
    // Implement engagement metrics aggregation
    return {};
  }

  async _storeReport(report) {
    // Implement report storage logic
    // This could store reports in MongoDB or another storage solution
  }

  async _sendReportEmail(report, type) {
    const emailTemplate = this._generateEmailTemplate(report, type);
    const adminEmails = await this._getAdminEmails();

    for (const email of adminEmails) {
      await emailService.sendEmail(
        email,
        `${type.charAt(0).toUpperCase() + type.slice(1)} Report - ${report.date || report.startDate}`,
        emailTemplate
      );
    }
  }

  _generateEmailTemplate(report, type) {
    // Implement email template generation
    return '';
  }

  async _getAdminEmails() {
    const admins = await User.find({ role: 'admin' }).select('email');
    return admins.map(admin => admin.email);
  }
}

module.exports = new ReportingService();
