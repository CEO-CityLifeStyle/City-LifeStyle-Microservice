const { PubSub } = require('@google-cloud/pubsub');
const { BigQuery } = require('@google-cloud/bigquery');
const websocketService = require('./websocketService');
const performanceService = require('./performanceService');
const advancedAnalyticsService = require('./advancedAnalyticsService');

class RealtimeDashboardService {
  constructor() {
    this.pubsub = new PubSub();
    this.bigquery = new BigQuery();
    this.metrics = new Map();
    this.dashboards = new Map();
    this.updateInterval = 5000; // 5 seconds
    this.startRealtimeUpdates();
  }

  // Initialize realtime updates
  startRealtimeUpdates() {
    setInterval(() => this.broadcastMetrics(), this.updateInterval);
    this.subscribeToMetrics();
  }

  // Create custom dashboard
  async createDashboard(userId, config) {
    try {
      const dashboard = {
        id: `dashboard_${Date.now()}`,
        userId,
        config,
        widgets: await this.initializeDashboardWidgets(config.widgets),
        createdAt: new Date(),
        updatedAt: new Date()
      };

      this.dashboards.set(dashboard.id, dashboard);
      return dashboard;
    } catch (error) {
      throw new Error(`Failed to create dashboard: ${error.message}`);
    }
  }

  // Get dashboard data
  async getDashboardData(dashboardId) {
    try {
      const dashboard = this.dashboards.get(dashboardId);
      if (!dashboard) {
        throw new Error('Dashboard not found');
      }

      const data = await this.collectDashboardData(dashboard);
      return data;
    } catch (error) {
      throw new Error(`Failed to get dashboard data: ${error.message}`);
    }
  }

  // Update dashboard configuration
  async updateDashboard(dashboardId, config) {
    try {
      const dashboard = this.dashboards.get(dashboardId);
      if (!dashboard) {
        throw new Error('Dashboard not found');
      }

      dashboard.config = config;
      dashboard.widgets = await this.initializeDashboardWidgets(config.widgets);
      dashboard.updatedAt = new Date();

      this.dashboards.set(dashboardId, dashboard);
      return dashboard;
    } catch (error) {
      throw new Error(`Failed to update dashboard: ${error.message}`);
    }
  }

  // Export dashboard data
  async exportDashboard(dashboardId, format) {
    try {
      const data = await this.getDashboardData(dashboardId);
      
      switch (format.toLowerCase()) {
        case 'json':
          return JSON.stringify(data, null, 2);
        case 'csv':
          return this.convertToCSV(data);
        case 'pdf':
          return await this.generatePDF(data);
        default:
          throw new Error('Unsupported export format');
      }
    } catch (error) {
      throw new Error(`Failed to export dashboard: ${error.message}`);
    }
  }

  // Subscribe to real-time metrics
  async subscribeToMetrics() {
    try {
      const subscription = this.pubsub.subscription(process.env.METRICS_SUBSCRIPTION);
      
      subscription.on('message', message => {
        try {
          const data = JSON.parse(message.data.toString());
          this.updateMetrics(data);
          message.ack();
        } catch (error) {
          console.error('Error processing message:', error);
          message.nack();
        }
      });

      subscription.on('error', error => {
        console.error('Subscription error:', error);
      });
    } catch (error) {
      console.error('Failed to subscribe to metrics:', error);
    }
  }

  // Broadcast metrics to connected clients
  async broadcastMetrics() {
    try {
      const metrics = await this.collectAllMetrics();
      
      // Broadcast to all connected dashboard clients
      this.dashboards.forEach(dashboard => {
        const filteredMetrics = this.filterMetricsForDashboard(metrics, dashboard.config);
        websocketService.broadcast('dashboard_update', {
          dashboardId: dashboard.id,
          metrics: filteredMetrics
        });
      });
    } catch (error) {
      console.error('Failed to broadcast metrics:', error);
    }
  }

  // Initialize dashboard widgets
  async initializeDashboardWidgets(widgets) {
    return Promise.all(widgets.map(async widget => {
      const data = await this.initializeWidgetData(widget);
      return {
        ...widget,
        data
      };
    }));
  }

  // Initialize widget data
  async initializeWidgetData(widget) {
    switch (widget.type) {
      case 'chart':
        return this.initializeChartData(widget);
      case 'metric':
        return this.initializeMetricData(widget);
      case 'table':
        return this.initializeTableData(widget);
      case 'map':
        return this.initializeMapData(widget);
      default:
        return null;
    }
  }

  // Collect all metrics
  async collectAllMetrics() {
    try {
      const [
        performanceMetrics,
        analyticsMetrics,
        customMetrics
      ] = await Promise.all([
        performanceService.getAllMetrics(),
        advancedAnalyticsService.getRealtimeMetrics(),
        this.getCustomMetrics()
      ]);

      return {
        performance: performanceMetrics,
        analytics: analyticsMetrics,
        custom: customMetrics,
        timestamp: new Date().toISOString()
      };
    } catch (error) {
      throw new Error(`Failed to collect metrics: ${error.message}`);
    }
  }

  // Get custom metrics
  async getCustomMetrics() {
    try {
      const query = `
        SELECT *
        FROM \`${process.env.BIGQUERY_DATASET_ID}.custom_metrics\`
        WHERE timestamp >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 5 MINUTE)
      `;

      const [rows] = await this.bigquery.query({ query });
      return rows;
    } catch (error) {
      console.error('Failed to get custom metrics:', error);
      return [];
    }
  }

  // Filter metrics for specific dashboard
  filterMetricsForDashboard(metrics, config) {
    const filtered = {};
    
    config.widgets.forEach(widget => {
      const metricPath = widget.metric.split('.');
      let value = metrics;
      
      for (const key of metricPath) {
        value = value?.[key];
        if (value === undefined) break;
      }

      if (value !== undefined) {
        filtered[widget.id] = value;
      }
    });

    return filtered;
  }

  // Initialize chart data
  async initializeChartData(widget) {
    try {
      const query = `
        SELECT ${widget.metrics.join(', ')}, timestamp
        FROM \`${process.env.BIGQUERY_DATASET_ID}.${widget.table}\`
        WHERE timestamp >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL ${widget.timeRange} MINUTE)
        ORDER BY timestamp DESC
        LIMIT ${widget.limit || 100}
      `;

      const [rows] = await this.bigquery.query({ query });
      return rows;
    } catch (error) {
      console.error('Failed to initialize chart data:', error);
      return [];
    }
  }

  // Initialize metric data
  async initializeMetricData(widget) {
    try {
      const query = `
        SELECT ${widget.metric}
        FROM \`${process.env.BIGQUERY_DATASET_ID}.${widget.table}\`
        WHERE timestamp >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 5 MINUTE)
        ORDER BY timestamp DESC
        LIMIT 1
      `;

      const [rows] = await this.bigquery.query({ query });
      return rows[0] || null;
    } catch (error) {
      console.error('Failed to initialize metric data:', error);
      return null;
    }
  }

  // Initialize table data
  async initializeTableData(widget) {
    try {
      const query = `
        SELECT ${widget.columns.join(', ')}
        FROM \`${process.env.BIGQUERY_DATASET_ID}.${widget.table}\`
        ${widget.where ? 'WHERE ' + widget.where : ''}
        ${widget.orderBy ? 'ORDER BY ' + widget.orderBy : ''}
        LIMIT ${widget.limit || 10}
      `;

      const [rows] = await this.bigquery.query({ query });
      return rows;
    } catch (error) {
      console.error('Failed to initialize table data:', error);
      return [];
    }
  }

  // Initialize map data
  async initializeMapData(widget) {
    try {
      const query = `
        SELECT latitude, longitude, ${widget.metrics.join(', ')}
        FROM \`${process.env.BIGQUERY_DATASET_ID}.${widget.table}\`
        WHERE timestamp >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL ${widget.timeRange} MINUTE)
      `;

      const [rows] = await this.bigquery.query({ query });
      return rows;
    } catch (error) {
      console.error('Failed to initialize map data:', error);
      return [];
    }
  }

  // Convert data to CSV
  convertToCSV(data) {
    if (!data || !data.length) return '';
    
    const headers = Object.keys(data[0]);
    const rows = data.map(row =>
      headers.map(header => JSON.stringify(row[header])).join(',')
    );
    
    return [headers.join(','), ...rows].join('\n');
  }

  // Generate PDF report
  async generatePDF(data) {
    // Implementation would require a PDF generation library
    // Return buffer or stream of PDF file
    return Buffer.from('PDF data');
  }
}

module.exports = new RealtimeDashboardService();
