const os = require('os');
const v8 = require('v8');
const mongoose = require('mongoose');
const notificationService = require('./notificationService');

class PerformanceService {
  constructor() {
    this.thresholds = {
      memory: 85, // percentage
      cpu: 80, // percentage
      storage: 90, // percentage
      latency: 1000 // milliseconds
    };
    this.metricsHistory = new Map();
    this.startMonitoring();
  }

  // Start periodic monitoring
  startMonitoring() {
    setInterval(() => this.checkMetrics(), 60000); // Check every minute
  }

  // Get public metrics
  async getPublicMetrics() {
    return {
      status: 'healthy',
      uptime: process.uptime(),
      timestamp: new Date().toISOString()
    };
  }

  // Get all metrics
  async getAllMetrics() {
    const metrics = {
      memory: await this.getMemoryUsage(),
      cpu: await this.getCPUUsage(),
      network: await this.getNetworkLatency(),
      storage: await this.getStorageUsage(),
      battery: await this.getBatteryLevel(),
      system: await this.getSystemMetrics()
    };
    return metrics;
  }

  // Get memory usage
  async getMemoryUsage() {
    const used = process.memoryUsage();
    const heapStats = v8.getHeapStatistics();
    const total = os.totalmem();
    const free = os.freemem();
    
    return {
      heapUsed: used.heapUsed,
      heapTotal: used.heapTotal,
      external: used.external,
      rss: used.rss,
      heapSizeLimit: heapStats.heap_size_limit,
      totalSystemMemory: total,
      freeSystemMemory: free,
      percentageUsed: ((total - free) / total) * 100
    };
  }

  // Get CPU usage
  async getCPUUsage() {
    const cpus = os.cpus();
    const loadAvg = os.loadavg();
    
    const cpuUsage = cpus.map(cpu => {
      const total = Object.values(cpu.times).reduce((acc, tv) => acc + tv, 0);
      const idle = cpu.times.idle;
      return {
        model: cpu.model,
        speed: cpu.speed,
        usage: ((total - idle) / total) * 100
      };
    });

    return {
      cpus: cpuUsage,
      loadAverage: loadAvg,
      averageUsage: cpuUsage.reduce((acc, cpu) => acc + cpu.usage, 0) / cpuUsage.length
    };
  }

  // Get network latency
  async getNetworkLatency() {
    const startTime = process.hrtime();
    try {
      await mongoose.connection.db.admin().ping();
      const [seconds, nanoseconds] = process.hrtime(startTime);
      const latency = (seconds * 1000) + (nanoseconds / 1000000);
      return {
        dbLatency: latency,
        timestamp: new Date().toISOString()
      };
    } catch (error) {
      return {
        error: 'Database connection error',
        timestamp: new Date().toISOString()
      };
    }
  }

  // Get storage usage
  async getStorageUsage() {
    const dbStats = await mongoose.connection.db.stats();
    return {
      dataSize: dbStats.dataSize,
      storageSize: dbStats.storageSize,
      indexes: dbStats.indexes,
      indexSize: dbStats.indexSize,
      collections: dbStats.collections,
      timestamp: new Date().toISOString()
    };
  }

  // Get battery level (mock implementation)
  async getBatteryLevel() {
    return {
      level: 100,
      charging: true,
      timestamp: new Date().toISOString()
    };
  }

  // Get metrics history
  async getMetricsHistory(startDate, endDate, type) {
    const history = Array.from(this.metricsHistory.entries())
      .filter(([timestamp]) => {
        const date = new Date(timestamp);
        return (!startDate || date >= new Date(startDate)) &&
               (!endDate || date <= new Date(endDate));
      })
      .map(([timestamp, metrics]) => ({
        timestamp,
        metrics: type ? metrics[type] : metrics
      }));

    return history;
  }

  // Update performance thresholds
  async updateThresholds(newThresholds) {
    this.thresholds = { ...this.thresholds, ...newThresholds };
    return this.thresholds;
  }

  // Configure performance alerts
  async configureAlerts(config) {
    // Store alert configuration
    this.alertConfig = { ...this.alertConfig, ...config };
    return this.alertConfig;
  }

  // Get alert history
  async getAlertHistory(startDate, endDate, severity) {
    // Implementation would depend on how alerts are stored
    return [];
  }

  // Get system metrics
  async getSystemMetrics() {
    return {
      platform: process.platform,
      arch: process.arch,
      version: process.version,
      uptime: process.uptime(),
      nodeEnv: process.env.NODE_ENV,
      hostname: os.hostname(),
      type: os.type(),
      release: os.release(),
      totalMemory: os.totalmem(),
      freeMemory: os.freemem(),
      cpus: os.cpus().length
    };
  }

  // Check metrics and trigger alerts if needed
  async checkMetrics() {
    const metrics = await this.getAllMetrics();
    const timestamp = new Date().toISOString();
    
    // Store metrics history
    this.metricsHistory.set(timestamp, metrics);

    // Clean up old metrics (keep last 24 hours)
    const dayAgo = new Date(Date.now() - 24 * 60 * 60 * 1000);
    for (const [key] of this.metricsHistory) {
      if (new Date(key) < dayAgo) {
        this.metricsHistory.delete(key);
      }
    }

    // Check thresholds and trigger alerts
    if (metrics.memory.percentageUsed > this.thresholds.memory) {
      await this.triggerAlert('memory', 'high', metrics.memory);
    }
    if (metrics.cpu.averageUsage > this.thresholds.cpu) {
      await this.triggerAlert('cpu', 'high', metrics.cpu);
    }
    if (metrics.network.dbLatency > this.thresholds.latency) {
      await this.triggerAlert('latency', 'high', metrics.network);
    }
  }

  // Trigger performance alert
  async triggerAlert(type, severity, data) {
    const alert = {
      type,
      severity,
      data,
      timestamp: new Date().toISOString()
    };

    // Send notification
    await notificationService.createNotification({
      title: `Performance Alert: ${type}`,
      message: `${severity} ${type} usage detected`,
      type: 'performance',
      severity,
      data: alert
    });

    return alert;
  }
}

module.exports = new PerformanceService();
