const batchOperationsService = require('../services/batchOperationsService');

class BatchOperationsController {
  // Batch update reviews
  async batchUpdateReviews(req, res) {
    try {
      const { reviewIds, updates } = req.body;
      const userId = req.user._id;

      if (!Array.isArray(reviewIds) || reviewIds.length === 0) {
        return res.status(400).json({ error: 'Review IDs array is required' });
      }

      const results = await batchOperationsService.batchUpdateReviews(
        reviewIds,
        updates,
        userId
      );

      res.json(results);
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  }

  // Batch delete reviews
  async batchDeleteReviews(req, res) {
    try {
      const { reviewIds } = req.body;
      const userId = req.user._id;

      if (!Array.isArray(reviewIds) || reviewIds.length === 0) {
        return res.status(400).json({ error: 'Review IDs array is required' });
      }

      const results = await batchOperationsService.batchDeleteReviews(
        reviewIds,
        userId
      );

      res.json(results);
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  }

  // Batch moderate reviews
  async batchModerateReviews(req, res) {
    try {
      const { reviewIds, moderationData } = req.body;
      const userId = req.user._id;

      if (!Array.isArray(reviewIds) || reviewIds.length === 0) {
        return res.status(400).json({ error: 'Review IDs array is required' });
      }

      if (!moderationData || !moderationData.status) {
        return res.status(400).json({ error: 'Moderation status is required' });
      }

      const results = await batchOperationsService.batchModerateReviews(
        reviewIds,
        moderationData,
        userId
      );

      res.json(results);
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  }

  // Batch export reviews
  async batchExportReviews(req, res) {
    try {
      const { reviewIds } = req.body;
      const { format = 'json' } = req.query;

      if (!Array.isArray(reviewIds) || reviewIds.length === 0) {
        return res.status(400).json({ error: 'Review IDs array is required' });
      }

      const data = await batchOperationsService.batchExportReviews(reviewIds, format);

      if (format === 'csv') {
        res.setHeader('Content-Type', 'text/csv');
        res.setHeader('Content-Disposition', 'attachment; filename=reviews.csv');
      } else {
        res.setHeader('Content-Type', 'application/json');
        res.setHeader('Content-Disposition', 'attachment; filename=reviews.json');
      }

      res.send(data);
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  }
}

module.exports = new BatchOperationsController();
