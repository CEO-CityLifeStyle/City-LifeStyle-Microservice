const realtimeDashboardService = require('../services/realtimeDashboardService');

class RealtimeDashboardController {
  // Create dashboard
  async createDashboard(req, res) {
    try {
      const dashboard = await realtimeDashboardService.createDashboard(
        req.user.id,
        req.body
      );
      res.json(dashboard);
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  }

  // Get dashboard data
  async getDashboardData(req, res) {
    try {
      const { dashboardId } = req.params;
      const data = await realtimeDashboardService.getDashboardData(dashboardId);
      res.json(data);
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  }

  // Update dashboard
  async updateDashboard(req, res) {
    try {
      const { dashboardId } = req.params;
      const dashboard = await realtimeDashboardService.updateDashboard(
        dashboardId,
        req.body
      );
      res.json(dashboard);
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  }

  // Export dashboard
  async exportDashboard(req, res) {
    try {
      const { dashboardId } = req.params;
      const { format } = req.query;
      const data = await realtimeDashboardService.exportDashboard(dashboardId, format);
      
      // Set appropriate headers based on format
      switch (format.toLowerCase()) {
        case 'json':
          res.setHeader('Content-Type', 'application/json');
          res.setHeader('Content-Disposition', `attachment; filename=dashboard_${dashboardId}.json`);
          break;
        case 'csv':
          res.setHeader('Content-Type', 'text/csv');
          res.setHeader('Content-Disposition', `attachment; filename=dashboard_${dashboardId}.csv`);
          break;
        case 'pdf':
          res.setHeader('Content-Type', 'application/pdf');
          res.setHeader('Content-Disposition', `attachment; filename=dashboard_${dashboardId}.pdf`);
          break;
      }
      
      res.send(data);
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  }
}

module.exports = new RealtimeDashboardController();
