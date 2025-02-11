import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../../config/api_config.dart';
import '../../providers/auth_provider.dart';
import '../../utils/logger.dart';
import '../../widgets/analytics/chart_card.dart';
import '../../widgets/analytics/data_table_card.dart';
import '../../widgets/analytics/metric_card.dart';
import '../../widgets/common/loading_overlay.dart';

class AnalyticsDashboardScreen extends StatefulWidget {
  const AnalyticsDashboardScreen({super.key});

  static const routeName = '/analytics/dashboard';

  @override
  State<AnalyticsDashboardScreen> createState() => _AnalyticsDashboardScreenState();
}

class _AnalyticsDashboardScreenState extends State<AnalyticsDashboardScreen> {
  final _logger = getLogger('AnalyticsDashboardScreen');
  bool _isLoading = false;
  Map<String, dynamic> _analyticsData = {};

  @override
  void initState() {
    super.initState();
    _fetchAnalyticsData();
  }

  Future<void> _fetchAnalyticsData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;
      
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/analytics/dashboard'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        setState(() {
          _analyticsData = data;
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load analytics data');
      }
    } catch (e) {
      _logger.severe('Error fetching analytics data: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Analytics Dashboard'),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _fetchAnalyticsData,
        ),
      ],
    ),
    body: _isLoading
        ? const LoadingOverlay(
            isLoading: true,
            child: CircularProgressIndicator(),
          )
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _analyticsData['title']?.toString() ?? 'Dashboard Overview',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 24),
                _buildMetricsGrid(),
                const SizedBox(height: 24),
                _buildCharts(),
                const SizedBox(height: 24),
                _buildDataTables(),
              ],
            ),
          ),
  );

  Widget _buildMetricsGrid() => GridView.count(
    crossAxisCount: 3,
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    mainAxisSpacing: 16,
    crossAxisSpacing: 16,
    children: [
      MetricCard(
        title: 'Total Users',
        value: (_analyticsData['metrics'] as Map<String, dynamic>?)?['totalUsers']?.toString() ?? '0',
        trend: 0.05,
        icon: Icons.people,
      ),
      MetricCard(
        title: 'Active Places',
        value: (_analyticsData['metrics'] as Map<String, dynamic>?)?['activePlaces']?.toString() ?? '0',
        trend: 0.03,
        icon: Icons.place,
      ),
      MetricCard(
        title: 'Reviews',
        value: (_analyticsData['metrics'] as Map<String, dynamic>?)?['totalReviews']?.toString() ?? '0',
        trend: 0.08,
        icon: Icons.star,
      ),
    ],
  );

  Widget _buildCharts() => Column(
    children: [
      ChartCard(
        title: 'User Growth',
        data: (_analyticsData['charts'] as Map<String, dynamic>?)?['userGrowth'] as List<dynamic>? ?? [],
      ),
      const SizedBox(height: 16),
      ChartCard(
        title: 'Place Categories',
        data: (_analyticsData['charts'] as Map<String, dynamic>?)?['placeCategories'] as Map<String, dynamic>? ?? {},
      ),
      const SizedBox(height: 16),
      ChartCard(
        title: 'Review Sentiment',
        data: (_analyticsData['charts'] as Map<String, dynamic>?)?['reviewSentiment'] as Map<String, dynamic>? ?? {},
      ),
    ],
  );

  Widget _buildDataTables() => Column(
    children: [
      DataTableCard(
        title: 'Top Places',
        data: (_analyticsData['tables'] as Map<String, dynamic>?)?['topPlaces'] as List<dynamic>? ?? [],
      ),
      const SizedBox(height: 16),
      DataTableCard(
        title: 'Recent Reviews',
        data: (_analyticsData['tables'] as Map<String, dynamic>?)?['recentReviews'] as List<dynamic>? ?? [],
      ),
    ],
  );
}
