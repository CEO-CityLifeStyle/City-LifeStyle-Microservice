const enhancedMLService = require('../services/enhancedMLService');

class EnhancedMLController {
  // Train new model
  async trainModel(req, res) {
    try {
      const status = await enhancedMLService.queueModelTraining(req.body);
      res.json(status);
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  }

  // Get model versions
  async getModelVersions(req, res) {
    try {
      const { modelName } = req.params;
      const versions = await enhancedMLService.getModelVersions(modelName);
      res.json(versions);
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  }

  // Deploy model version
  async deployModelVersion(req, res) {
    try {
      const { modelName, version } = req.params;
      const model = await enhancedMLService.deployModelVersion(modelName, version);
      res.json(model);
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  }

  // Archive model version
  async archiveModelVersion(req, res) {
    try {
      const { modelName, version } = req.params;
      const model = await enhancedMLService.archiveModelVersion(modelName, version);
      res.json(model);
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  }

  // Get model metrics
  async getModelMetrics(req, res) {
    try {
      const { modelName, version } = req.params;
      const metrics = await enhancedMLService.getModelMetrics(modelName, version);
      res.json(metrics);
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  }

  // Compare model versions
  async compareModelVersions(req, res) {
    try {
      const { modelName } = req.params;
      const { version1, version2 } = req.query;
      const comparison = await enhancedMLService.compareModelVersions(modelName, version1, version2);
      res.json(comparison);
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  }
}

module.exports = new EnhancedMLController();
