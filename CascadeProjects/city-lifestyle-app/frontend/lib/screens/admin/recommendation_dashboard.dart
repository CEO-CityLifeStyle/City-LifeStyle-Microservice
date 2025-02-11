import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/ml/ab_testing_service.dart';
import '../../services/ml/recommendation_cache.dart';
import '../../utils/logger.dart';
import '../../widgets/admin/ab_test_results_card.dart';
import '../../widgets/admin/performance_metrics_card.dart';
import '../../widgets/admin/real_time_metrics.dart';
import '../../widgets/admin/recommendation_metrics_chart.dart';

class RecommendationDashboard extends StatefulWidget {
  const RecommendationDashboard({super.key});

  static const routeName = '/admin/recommendations';

  @override
  State<RecommendationDashboard> createState() => _RecommendationDashboardState();
}

class _RecommendationDashboardState extends State<RecommendationDashboard>
    with SingleTickerProviderStateMixin {
  final _logger = getLogger('RecommendationDashboard');
  late TabController _tabController;
  late RecommendationCache _recommendationCache;
  late ABTestingService _abTestingService;

  Map<String, dynamic> _cacheStats = {};
  Map<String, dynamic> _testMetrics = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _recommendationCache = RecommendationCache(prefs);
      _abTestingService = ABTestingService(prefs);
      await _loadDashboardData();
    } catch (e) {
      _logger.severe('Error initializing services: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadDashboardData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    
    try {
      final cacheStats = await _recommendationCache.getCacheStats();
      final testMetrics = await _abTestingService.getTestMetrics('main_recommendations');

      if (!mounted) return;
      setState(() {
        _cacheStats = Map<String, dynamic>.from(cacheStats);
        _testMetrics = Map<String, dynamic>.from(testMetrics);
        _isLoading = false;
      });
    } catch (e) {
      _logger.severe('Error loading dashboard data: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Recommendation Dashboard'),
      bottom: TabBar(
        controller: _tabController,
        tabs: const [
          Tab(text: 'Overview'),
          Tab(text: 'A/B Tests'),
          Tab(text: 'Real-time'),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _loadDashboardData,
        ),
      ],
    ),
    body: _isLoading
        ? const Center(child: CircularProgressIndicator())
        : TabBarView(
            controller: _tabController,
            children: [
              _buildOverviewTab(),
              _buildABTestsTab(),
              _buildRealTimeTab(),
            ],
          ),
  );

  Widget _buildOverviewTab() => SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'System Performance',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        PerformanceMetricsCard(
          title: 'Cache Performance',
          metrics: [
            MetricItem(
              label: 'Cache Hit Rate',
              value: '${(_cacheStats['hitRate'] as num? ?? 0 * 100).toStringAsFixed(1)}%',
              trend: 0.05,
            ),
            MetricItem(
              label: 'Active Entries',
              value: (_cacheStats['activeEntries'] as num?)?.toString() ?? '0',
              trend: 0.02,
            ),
            MetricItem(
              label: 'Memory Usage',
              value: '${((_cacheStats['totalSizeBytes'] as num? ?? 0) / 1024 / 1024).toStringAsFixed(2)} MB',
              trend: -0.01,
            ),
          ],
        ),
        const SizedBox(height: 16),
        RecommendationMetricsChart(
          data: _cacheStats['history'] as Map<String, dynamic>? ?? {},
        ),
      ],
    ),
  );

  Widget _buildABTestsTab() => SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'A/B Test Results',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ABTestResultsCard(
          testId: 'main_recommendations',
          metrics: _testMetrics,
        ),
      ],
    ),
  );

  Widget _buildRealTimeTab() => const SingleChildScrollView(
    padding: EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Real-time Metrics',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 16),
        RealTimeMetrics(),
      ],
    ),
  );
}
