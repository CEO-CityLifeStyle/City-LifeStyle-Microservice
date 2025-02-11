const mongoose = require('mongoose');
const crypto = require('crypto');
const analyticsService = require('./analyticsService');

// Define experiment schema
const experimentSchema = new mongoose.Schema({
  name: { type: String, required: true },
  description: String,
  status: {
    type: String,
    enum: ['draft', 'active', 'paused', 'completed'],
    default: 'draft'
  },
  variants: [{
    name: String,
    weight: Number,
    config: mongoose.Schema.Types.Mixed
  }],
  startDate: Date,
  endDate: Date,
  targetUsers: {
    percentage: Number,
    criteria: mongoose.Schema.Types.Mixed
  },
  metrics: [{
    name: String,
    type: String,
    goal: Number
  }]
});

const Experiment = mongoose.model('Experiment', experimentSchema);

class ABTestingService {
  // Get active experiments for user
  async getActiveExperiments(userId) {
    try {
      const experiments = await Experiment.find({ status: 'active' });
      return experiments.filter(exp => this.isUserEligible(userId, exp));
    } catch (error) {
      throw new Error(`Failed to get active experiments: ${error.message}`);
    }
  }

  // Get user's variant for specific experiment
  async getUserVariant(userId, experimentId) {
    try {
      const experiment = await Experiment.findById(experimentId);
      if (!experiment || experiment.status !== 'active') {
        return null;
      }

      if (!this.isUserEligible(userId, experiment)) {
        return null;
      }

      return this.assignVariant(userId, experiment);
    } catch (error) {
      throw new Error(`Failed to get user variant: ${error.message}`);
    }
  }

  // Log experiment event
  async logEvent(userId, experimentId, eventData) {
    try {
      const experiment = await Experiment.findById(experimentId);
      if (!experiment || experiment.status !== 'active') {
        throw new Error('Experiment not active');
      }

      const variant = await this.getUserVariant(userId, experimentId);
      if (!variant) {
        throw new Error('User not in experiment');
      }

      // Log event to analytics
      await analyticsService.trackEvent('experiment_event', {
        experimentId,
        userId,
        variant: variant.name,
        ...eventData
      });

      return { success: true };
    } catch (error) {
      throw new Error(`Failed to log event: ${error.message}`);
    }
  }

  // Create new experiment
  async createExperiment(data) {
    try {
      const experiment = new Experiment(data);
      await experiment.save();
      return experiment;
    } catch (error) {
      throw new Error(`Failed to create experiment: ${error.message}`);
    }
  }

  // Update existing experiment
  async updateExperiment(id, data) {
    try {
      const experiment = await Experiment.findByIdAndUpdate(id, data, { new: true });
      if (!experiment) {
        throw new Error('Experiment not found');
      }
      return experiment;
    } catch (error) {
      throw new Error(`Failed to update experiment: ${error.message}`);
    }
  }

  // Delete experiment
  async deleteExperiment(id) {
    try {
      const experiment = await Experiment.findByIdAndDelete(id);
      if (!experiment) {
        throw new Error('Experiment not found');
      }
      return { success: true };
    } catch (error) {
      throw new Error(`Failed to delete experiment: ${error.message}`);
    }
  }

  // Get all experiments
  async getAllExperiments() {
    try {
      return await Experiment.find();
    } catch (error) {
      throw new Error(`Failed to get experiments: ${error.message}`);
    }
  }

  // Get experiment results
  async getExperimentResults(id) {
    try {
      const experiment = await Experiment.findById(id);
      if (!experiment) {
        throw new Error('Experiment not found');
      }

      // Get analytics data for experiment
      const results = await analyticsService.getExperimentResults(id);
      
      return {
        experiment,
        results,
        summary: this.calculateExperimentSummary(results)
      };
    } catch (error) {
      throw new Error(`Failed to get experiment results: ${error.message}`);
    }
  }

  // Start experiment
  async startExperiment(id) {
    try {
      const experiment = await Experiment.findByIdAndUpdate(
        id,
        {
          status: 'active',
          startDate: new Date()
        },
        { new: true }
      );
      if (!experiment) {
        throw new Error('Experiment not found');
      }
      return experiment;
    } catch (error) {
      throw new Error(`Failed to start experiment: ${error.message}`);
    }
  }

  // Stop experiment
  async stopExperiment(id) {
    try {
      const experiment = await Experiment.findByIdAndUpdate(
        id,
        {
          status: 'completed',
          endDate: new Date()
        },
        { new: true }
      );
      if (!experiment) {
        throw new Error('Experiment not found');
      }
      return experiment;
    } catch (error) {
      throw new Error(`Failed to stop experiment: ${error.message}`);
    }
  }

  // Reset experiment
  async resetExperiment(id) {
    try {
      const experiment = await Experiment.findByIdAndUpdate(
        id,
        {
          status: 'draft',
          startDate: null,
          endDate: null
        },
        { new: true }
      );
      if (!experiment) {
        throw new Error('Experiment not found');
      }
      
      // Clear experiment data from analytics
      await analyticsService.clearExperimentData(id);
      
      return experiment;
    } catch (error) {
      throw new Error(`Failed to reset experiment: ${error.message}`);
    }
  }

  // Helper: Check if user is eligible for experiment
  isUserEligible(userId, experiment) {
    if (!experiment.targetUsers) {
      return true;
    }

    // Generate deterministic number between 0-1 for user
    const hash = crypto.createHash('md5')
      .update(`${userId}:${experiment._id}`)
      .digest('hex');
    const number = parseInt(hash.substring(0, 8), 16) / 0xffffffff;

    // Check if user falls within target percentage
    if (number > (experiment.targetUsers.percentage / 100)) {
      return false;
    }

    // Check if user meets targeting criteria
    if (experiment.targetUsers.criteria) {
      // Implementation of criteria checking would go here
      return true;
    }

    return true;
  }

  // Helper: Assign variant to user
  assignVariant(userId, experiment) {
    // Generate deterministic number between 0-1 for user
    const hash = crypto.createHash('md5')
      .update(`${userId}:${experiment._id}:variant`)
      .digest('hex');
    const number = parseInt(hash.substring(0, 8), 16) / 0xffffffff;

    // Calculate cumulative weights
    let cumulativeWeight = 0;
    for (const variant of experiment.variants) {
      cumulativeWeight += variant.weight;
      if (number <= cumulativeWeight) {
        return variant;
      }
    }

    // Fallback to first variant
    return experiment.variants[0];
  }

  // Helper: Calculate experiment summary
  calculateExperimentSummary(results) {
    // Implementation would depend on the structure of analytics data
    return {
      totalParticipants: results.length,
      variantPerformance: results.reduce((acc, result) => {
        acc[result.variant] = acc[result.variant] || { count: 0, conversions: 0 };
        acc[result.variant].count++;
        if (result.converted) {
          acc[result.variant].conversions++;
        }
        return acc;
      }, {})
    };
  }
}

module.exports = new ABTestingService();
