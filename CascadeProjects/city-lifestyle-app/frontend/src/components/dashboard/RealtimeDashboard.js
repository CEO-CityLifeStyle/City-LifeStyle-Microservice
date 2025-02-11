import React, { useState, useEffect } from 'react';
import { Grid, Paper, Typography, Box } from '@mui/material';
import { Line, Bar, Pie } from 'react-chartjs-2';
import {
  Chart as ChartJS,
  CategoryScale,
  LinearScale,
  PointElement,
  LineElement,
  BarElement,
  ArcElement,
  Title,
  Tooltip,
  Legend,
} from 'chart.js';
import realtimeDashboardService from '../../services/realtimeDashboard';

// Register ChartJS components
ChartJS.register(
  CategoryScale,
  LinearScale,
  PointElement,
  LineElement,
  BarElement,
  ArcElement,
  Title,
  Tooltip,
  Legend
);

const RealtimeDashboard = ({ dashboardId }) => {
  const [dashboardData, setDashboardData] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    const fetchDashboard = async () => {
      try {
        const data = await realtimeDashboardService.getDashboardData(dashboardId);
        setDashboardData(data);
        setLoading(false);
      } catch (err) {
        setError(err.message);
        setLoading(false);
      }
    };

    fetchDashboard();

    // Subscribe to real-time updates
    const unsubscribe = realtimeDashboardService.subscribeToDashboard(
      dashboardId,
      (metrics) => {
        setDashboardData(prev => ({
          ...prev,
          metrics
        }));
      }
    );

    return () => unsubscribe();
  }, [dashboardId]);

  if (loading) {
    return <Box p={3}>Loading dashboard...</Box>;
  }

  if (error) {
    return <Box p={3}>Error: {error}</Box>;
  }

  if (!dashboardData) {
    return <Box p={3}>No dashboard data available</Box>;
  }

  return (
    <Box p={3}>
      <Typography variant="h4" gutterBottom>
        {dashboardData.config.title}
      </Typography>
      
      <Grid container spacing={3}>
        {dashboardData.widgets.map((widget) => (
          <Grid item xs={12} md={widget.size || 6} key={widget.id}>
            <Paper elevation={2}>
              <Box p={2}>
                <Typography variant="h6" gutterBottom>
                  {widget.title}
                </Typography>
                {renderWidget(widget)}
              </Box>
            </Paper>
          </Grid>
        ))}
      </Grid>
    </Box>
  );
};

// Helper function to render different widget types
const renderWidget = (widget) => {
  switch (widget.type) {
    case 'chart':
      return renderChart(widget);
    case 'metric':
      return renderMetric(widget);
    case 'table':
      return renderTable(widget);
    case 'map':
      return renderMap(widget);
    default:
      return null;
  }
};

// Render chart widget
const renderChart = (widget) => {
  const chartData = {
    labels: widget.data.map(d => new Date(d.timestamp).toLocaleTimeString()),
    datasets: widget.metrics.map(metric => ({
      label: metric,
      data: widget.data.map(d => d[metric]),
      fill: false,
      borderColor: getRandomColor(),
      tension: 0.1
    }))
  };

  const options = {
    responsive: true,
    plugins: {
      legend: {
        position: 'top',
      },
      title: {
        display: true,
        text: widget.title
      }
    },
    scales: {
      y: {
        beginAtZero: true
      }
    }
  };

  switch (widget.chartType) {
    case 'line':
      return <Line data={chartData} options={options} />;
    case 'bar':
      return <Bar data={chartData} options={options} />;
    case 'pie':
      return <Pie data={chartData} options={options} />;
    default:
      return <Line data={chartData} options={options} />;
  }
};

// Render metric widget
const renderMetric = (widget) => {
  return (
    <Box textAlign="center">
      <Typography variant="h3" color="primary">
        {formatMetricValue(widget.data[widget.metric])}
      </Typography>
      <Typography variant="body2" color="textSecondary">
        {widget.description}
      </Typography>
    </Box>
  );
};

// Render table widget
const renderTable = (widget) => {
  return (
    <Box sx={{ overflowX: 'auto' }}>
      <table style={{ width: '100%', borderCollapse: 'collapse' }}>
        <thead>
          <tr>
            {widget.columns.map(column => (
              <th key={column} style={tableHeaderStyle}>
                {column}
              </th>
            ))}
          </tr>
        </thead>
        <tbody>
          {widget.data.map((row, index) => (
            <tr key={index}>
              {widget.columns.map(column => (
                <td key={column} style={tableCellStyle}>
                  {row[column]}
                </td>
              ))}
            </tr>
          ))}
        </tbody>
      </table>
    </Box>
  );
};

// Render map widget
const renderMap = (widget) => {
  // Implementation would require a mapping library like Google Maps or Mapbox
  return (
    <Box>
      <Typography>Map visualization would go here</Typography>
    </Box>
  );
};

// Helper function to format metric values
const formatMetricValue = (value) => {
  if (typeof value === 'number') {
    if (value >= 1000000) {
      return `${(value / 1000000).toFixed(1)}M`;
    }
    if (value >= 1000) {
      return `${(value / 1000).toFixed(1)}K`;
    }
    return value.toFixed(1);
  }
  return value;
};

// Helper function to generate random colors for charts
const getRandomColor = () => {
  const letters = '0123456789ABCDEF';
  let color = '#';
  for (let i = 0; i < 6; i++) {
    color += letters[Math.floor(Math.random() * 16)];
  }
  return color;
};

// Styles for table
const tableHeaderStyle = {
  padding: '12px',
  textAlign: 'left',
  backgroundColor: '#f5f5f5',
  borderBottom: '2px solid #ddd'
};

const tableCellStyle = {
  padding: '8px',
  borderBottom: '1px solid #ddd'
};

export default RealtimeDashboard;
