import api from './api';
import { io } from 'socket.io-client';

class RealtimeDashboardService {
  constructor() {
    this.socket = io(process.env.REACT_APP_WS_URL);
    this.dashboardCallbacks = new Map();
    this.setupSocketListeners();
  }

  // Setup WebSocket listeners
  setupSocketListeners() {
    this.socket.on('dashboard_update', (data) => {
      const callback = this.dashboardCallbacks.get(data.dashboardId);
      if (callback) {
        callback(data.metrics);
      }
    });
  }

  // Subscribe to dashboard updates
  subscribeToDashboard(dashboardId, callback) {
    this.dashboardCallbacks.set(dashboardId, callback);
    return () => this.dashboardCallbacks.delete(dashboardId);
  }

  // Create dashboard
  async createDashboard(config) {
    const response = await api.post('/api/realtime-dashboard/dashboards', config);
    return response.data;
  }

  // Get dashboard data
  async getDashboardData(dashboardId) {
    const response = await api.get(`/api/realtime-dashboard/dashboards/${dashboardId}/data`);
    return response.data;
  }

  // Update dashboard
  async updateDashboard(dashboardId, config) {
    const response = await api.put(`/api/realtime-dashboard/dashboards/${dashboardId}`, config);
    return response.data;
  }

  // Export dashboard
  async exportDashboard(dashboardId, format) {
    const response = await api.get(
      `/api/realtime-dashboard/dashboards/${dashboardId}/export`,
      {
        params: { format },
        responseType: format === 'pdf' ? 'blob' : 'json'
      }
    );
    return response.data;
  }
}

export default new RealtimeDashboardService();
