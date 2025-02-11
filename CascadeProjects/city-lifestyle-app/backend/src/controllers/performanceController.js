const performanceService = require('../services/performanceService');

class PerformanceController {
  // Get public performance metrics
  async getPublicMetrics(req, res) {
    try {
      const metrics = await performanceService.getPublicMetrics();
      res.json(metrics);
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  }

  // Get all performance metrics
  async getMetrics(req, res) {
    try {
      const metrics = await performanceService.getAllMetrics();
      res.json(metrics);
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  }

  // Get memory usage metrics
  async getMemoryUsage(req, res) {
    try {
      const memory = await performanceService.getMemoryUsage();
      res.json(memory);
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  }

  // Get CPU usage metrics
  async getCPUUsage(req, res) {
    try {
      const cpu = await performanceService.getCPUUsage();
      res.json(cpu);
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  }

  // Get network latency metrics
  async getNetworkLatency(req, res) {
    try {
      const network = await performanceService.getNetworkLatency();
      res.json(network);
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  }

  // Get storage usage metrics
  async getStorageUsage(req, res) {
    try {
      const storage = await performanceService.getStorageUsage();
      res.json(storage);
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  }

  // Get battery level metrics
  async getBatteryLevel(req, res) {
    try {
      const battery = await performanceService.getBatteryLevel();
      res.json(battery);
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  }

  // Get historical metrics
  async getMetricsHistory(req, res) {
    try {
      const { startDate, endDate, type } = req.query;
      const history = await performanceService.getMetricsHistory(startDate, endDate, type);
      res.json(history);
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  }

  // Update performance thresholds
  async updateThresholds(req, res) {
    try {
      const thresholds = await performanceService.updateThresholds(req.body);
      res.json(thresholds);
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  }

  // Configure performance alerts
  async configureAlerts(req, res) {
    try {
      const config = await performanceService.configureAlerts(req.body);
      res.json(config);
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  }

  // Get alert history
  async getAlertHistory(req, res) {
    try {
      const { startDate, endDate, severity } = req.query;
      const history = await performanceService.getAlertHistory(startDate, endDate, severity);
      res.json(history);
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  }

  // Get system-wide metrics
  async getSystemMetrics(req, res) {
    try {
      const metrics = await performanceService.getSystemMetrics();
      res.json(metrics);
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  }
}

module.exports = new PerformanceController();
