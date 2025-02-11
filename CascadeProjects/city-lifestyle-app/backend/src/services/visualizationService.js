const { ChartJSNodeCanvas } = require('chartjs-node-canvas');
const Review = require('../models/review');
const Place = require('../models/place');
const User = require('../models/user');

class VisualizationService {
  constructor() {
    this.width = 800;
    this.height = 400;
    this.chartJSNodeCanvas = new ChartJSNodeCanvas({
      width: this.width,
      height: this.height,
      backgroundColour: 'white',
    });
  }

  // Generate review trends chart
  async generateReviewTrendsChart(startDate, endDate) {
    try {
      const data = await this._getReviewTrendsData(startDate, endDate);
      
      const configuration = {
        type: 'line',
        data: {
          labels: data.map(d => d.date),
          datasets: [
            {
              label: 'Reviews',
              data: data.map(d => d.count),
              fill: false,
              borderColor: 'rgb(75, 192, 192)',
              tension: 0.1,
            },
            {
              label: 'Average Rating',
              data: data.map(d => d.averageRating),
              fill: false,
              borderColor: 'rgb(255, 99, 132)',
              tension: 0.1,
            },
          ],
        },
        options: {
          responsive: true,
          plugins: {
            title: {
              display: true,
              text: 'Review Trends',
            },
          },
          scales: {
            y: {
              beginAtZero: true,
            },
          },
        },
      };

      return await this.chartJSNodeCanvas.renderToBuffer(configuration);
    } catch (error) {
      throw new Error(`Failed to generate review trends chart: ${error.message}`);
    }
  }

  // Generate rating distribution chart
  async generateRatingDistributionChart(startDate, endDate) {
    try {
      const data = await this._getRatingDistributionData(startDate, endDate);

      const configuration = {
        type: 'bar',
        data: {
          labels: Object.keys(data),
          datasets: [
            {
              label: 'Number of Reviews',
              data: Object.values(data),
              backgroundColor: [
                'rgba(255, 99, 132, 0.5)',
                'rgba(255, 159, 64, 0.5)',
                'rgba(255, 205, 86, 0.5)',
                'rgba(75, 192, 192, 0.5)',
                'rgba(54, 162, 235, 0.5)',
              ],
              borderColor: [
                'rgb(255, 99, 132)',
                'rgb(255, 159, 64)',
                'rgb(255, 205, 86)',
                'rgb(75, 192, 192)',
                'rgb(54, 162, 235)',
              ],
              borderWidth: 1,
            },
          ],
        },
        options: {
          responsive: true,
          plugins: {
            title: {
              display: true,
              text: 'Rating Distribution',
            },
          },
          scales: {
            y: {
              beginAtZero: true,
            },
          },
        },
      };

      return await this.chartJSNodeCanvas.renderToBuffer(configuration);
    } catch (error) {
      throw new Error(`Failed to generate rating distribution chart: ${error.message}`);
    }
  }

  // Generate category performance chart
  async generateCategoryPerformanceChart() {
    try {
      const data = await this._getCategoryPerformanceData();

      const configuration = {
        type: 'radar',
        data: {
          labels: data.map(d => d.category),
          datasets: [
            {
              label: 'Average Rating',
              data: data.map(d => d.averageRating),
              fill: true,
              backgroundColor: 'rgba(54, 162, 235, 0.2)',
              borderColor: 'rgb(54, 162, 235)',
              pointBackgroundColor: 'rgb(54, 162, 235)',
              pointBorderColor: '#fff',
              pointHoverBackgroundColor: '#fff',
              pointHoverBorderColor: 'rgb(54, 162, 235)',
            },
          ],
        },
        options: {
          responsive: true,
          plugins: {
            title: {
              display: true,
              text: 'Category Performance',
            },
          },
          scales: {
            r: {
              beginAtZero: true,
              max: 5,
            },
          },
        },
      };

      return await this.chartJSNodeCanvas.renderToBuffer(configuration);
    } catch (error) {
      throw new Error(`Failed to generate category performance chart: ${error.message}`);
    }
  }

  // Generate user engagement chart
  async generateUserEngagementChart(startDate, endDate) {
    try {
      const data = await this._getUserEngagementData(startDate, endDate);

      const configuration = {
        type: 'line',
        data: {
          labels: data.map(d => d.date),
          datasets: [
            {
              label: 'Reviews',
              data: data.map(d => d.reviews),
              fill: false,
              borderColor: 'rgb(75, 192, 192)',
              tension: 0.1,
            },
            {
              label: 'Likes',
              data: data.map(d => d.likes),
              fill: false,
              borderColor: 'rgb(255, 99, 132)',
              tension: 0.1,
            },
            {
              label: 'Helpful Votes',
              data: data.map(d => d.helpful),
              fill: false,
              borderColor: 'rgb(255, 205, 86)',
              tension: 0.1,
            },
          ],
        },
        options: {
          responsive: true,
          plugins: {
            title: {
              display: true,
              text: 'User Engagement Trends',
            },
          },
          scales: {
            y: {
              beginAtZero: true,
            },
          },
        },
      };

      return await this.chartJSNodeCanvas.renderToBuffer(configuration);
    } catch (error) {
      throw new Error(`Failed to generate user engagement chart: ${error.message}`);
    }
  }

  // Helper methods to fetch data
  async _getReviewTrendsData(startDate, endDate) {
    const pipeline = [
      {
        $match: {
          createdAt: { $gte: startDate, $lte: endDate },
        },
      },
      {
        $group: {
          _id: {
            year: { $year: '$createdAt' },
            month: { $month: '$createdAt' },
            day: { $dayOfMonth: '$createdAt' },
          },
          count: { $sum: 1 },
          averageRating: { $avg: '$rating' },
        },
      },
      {
        $sort: {
          '_id.year': 1,
          '_id.month': 1,
          '_id.day': 1,
        },
      },
    ];

    const results = await Review.aggregate(pipeline);

    return results.map(r => ({
      date: `${r._id.year}-${r._id.month}-${r._id.day}`,
      count: r.count,
      averageRating: r.averageRating,
    }));
  }

  async _getRatingDistributionData(startDate, endDate) {
    const pipeline = [
      {
        $match: {
          createdAt: { $gte: startDate, $lte: endDate },
        },
      },
      {
        $group: {
          _id: '$rating',
          count: { $sum: 1 },
        },
      },
      {
        $sort: { _id: 1 },
      },
    ];

    const results = await Review.aggregate(pipeline);
    return results.reduce((acc, curr) => {
      acc[curr._id] = curr.count;
      return acc;
    }, {});
  }

  async _getCategoryPerformanceData() {
    const pipeline = [
      {
        $lookup: {
          from: 'places',
          localField: 'place',
          foreignField: '_id',
          as: 'place',
        },
      },
      { $unwind: '$place' },
      {
        $group: {
          _id: '$place.category',
          averageRating: { $avg: '$rating' },
          totalReviews: { $sum: 1 },
        },
      },
      {
        $project: {
          category: '$_id',
          averageRating: 1,
          totalReviews: 1,
        },
      },
    ];

    return await Review.aggregate(pipeline);
  }

  async _getUserEngagementData(startDate, endDate) {
    const pipeline = [
      {
        $match: {
          createdAt: { $gte: startDate, $lte: endDate },
        },
      },
      {
        $group: {
          _id: {
            year: { $year: '$createdAt' },
            month: { $month: '$createdAt' },
            day: { $dayOfMonth: '$createdAt' },
          },
          reviews: { $sum: 1 },
          likes: { $sum: { $size: '$likes' } },
          helpful: { $sum: { $size: '$helpful' } },
        },
      },
      {
        $sort: {
          '_id.year': 1,
          '_id.month': 1,
          '_id.day': 1,
        },
      },
    ];

    const results = await Review.aggregate(pipeline);

    return results.map(r => ({
      date: `${r._id.year}-${r._id.month}-${r._id.day}`,
      reviews: r.reviews,
      likes: r.likes,
      helpful: r.helpful,
    }));
  }
}

module.exports = new VisualizationService();
