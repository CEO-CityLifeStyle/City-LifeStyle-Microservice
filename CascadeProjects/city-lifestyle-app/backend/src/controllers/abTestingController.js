const abTestingService = require('../services/abTestingService');

class ABTestingController {
  // Get active experiments for user
  async getActiveExperiments(req, res) {
    try {
      const experiments = await abTestingService.getActiveExperiments(req.user.id);
      res.json(experiments);
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  }

  // Get user's variant for specific experiment
  async getUserVariant(req, res) {
    try {
      const { id } = req.params;
      const variant = await abTestingService.getUserVariant(req.user.id, id);
      res.json(variant);
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  }

  // Log experiment event
  async logExperimentEvent(req, res) {
    try {
      const { id } = req.params;
      const event = await abTestingService.logEvent(req.user.id, id, req.body);
      res.json(event);
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  }

  // Create new experiment
  async createExperiment(req, res) {
    try {
      const experiment = await abTestingService.createExperiment(req.body);
      res.status(201).json(experiment);
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  }

  // Update existing experiment
  async updateExperiment(req, res) {
    try {
      const { id } = req.params;
      const experiment = await abTestingService.updateExperiment(id, req.body);
      res.json(experiment);
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  }

  // Delete experiment
  async deleteExperiment(req, res) {
    try {
      const { id } = req.params;
      await abTestingService.deleteExperiment(id);
      res.status(204).send();
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  }

  // Get all experiments (admin)
  async getAllExperiments(req, res) {
    try {
      const experiments = await abTestingService.getAllExperiments();
      res.json(experiments);
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  }

  // Get experiment results
  async getExperimentResults(req, res) {
    try {
      const { id } = req.params;
      const results = await abTestingService.getExperimentResults(id);
      res.json(results);
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  }

  // Start experiment
  async startExperiment(req, res) {
    try {
      const { id } = req.params;
      const experiment = await abTestingService.startExperiment(id);
      res.json(experiment);
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  }

  // Stop experiment
  async stopExperiment(req, res) {
    try {
      const { id } = req.params;
      const experiment = await abTestingService.stopExperiment(id);
      res.json(experiment);
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  }

  // Reset experiment
  async resetExperiment(req, res) {
    try {
      const { id } = req.params;
      const experiment = await abTestingService.resetExperiment(id);
      res.json(experiment);
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  }
}

module.exports = new ABTestingController();
