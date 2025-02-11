const reportingService = require('../services/reportingService');

class ReportingController {
  // Generate daily report
  async generateDailyReport(req, res) {
    try {
      const report = await reportingService.generateDailyReport();
      res.json(report);
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  }

  // Generate weekly report
  async generateWeeklyReport(req, res) {
    try {
      const report = await reportingService.generateWeeklyReport();
      res.json(report);
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  }

  // Generate monthly report
  async generateMonthlyReport(req, res) {
    try {
      const report = await reportingService.generateMonthlyReport();
      res.json(report);
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  }

  // Generate custom report
  async generateCustomReport(req, res) {
    try {
      const { startDate, endDate, options } = req.body;

      if (!startDate || !endDate) {
        return res.status(400).json({ error: 'Start date and end date are required' });
      }

      const report = await reportingService.generateCustomReport(
        new Date(startDate),
        new Date(endDate),
        options
      );

      res.json(report);
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  }
}

module.exports = new ReportingController();
