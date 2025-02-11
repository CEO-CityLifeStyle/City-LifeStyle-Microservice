import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../../config/api_config.dart';
import '../../providers/auth_provider.dart';
import '../../utils/logger.dart';
import '../../widgets/analytics/sentiment_chart.dart';
import '../../widgets/analytics/sentiment_table.dart';
import '../../widgets/analytics/trend_card.dart';
import '../../widgets/common/loading_overlay.dart';

class SentimentAnalysisScreen extends StatefulWidget {
  const SentimentAnalysisScreen({super.key});

  static const routeName = '/analytics/sentiment';

  @override
  State<SentimentAnalysisScreen> createState() => _SentimentAnalysisScreenState();
}

class _SentimentAnalysisScreenState extends State<SentimentAnalysisScreen> {
  final _logger = getLogger('SentimentAnalysisScreen');
  bool _isLoading = false;
  Map<String, dynamic> _sentimentData = {};
  String _selectedTimeframe = 'week';

  @override
  void initState() {
    super.initState();
    _fetchSentimentData();
  }

  Future<void> _fetchSentimentData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;
      
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/analytics/sentiment?timeframe=$_selectedTimeframe'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        setState(() {
          _sentimentData = data;
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load sentiment data');
      }
    } catch (e) {
      _logger.severe('Error fetching sentiment data: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Sentiment Analysis'),
      actions: [
        PopupMenuButton<String>(
          icon: const Icon(Icons.calendar_today),
          onSelected: (value) {
            setState(() => _selectedTimeframe = value);
            _fetchSentimentData();
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'day',
              child: Text('Last 24 Hours'),
            ),
            const PopupMenuItem(
              value: 'week',
              child: Text('Last Week'),
            ),
            const PopupMenuItem(
              value: 'month',
              child: Text('Last Month'),
            ),
          ],
        ),
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _fetchSentimentData,
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
                  'Sentiment Overview',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 24),
                _buildOverviewCards(),
                const SizedBox(height: 24),
                _buildSentimentCharts(),
                const SizedBox(height: 24),
                _buildSentimentTable(),
              ],
            ),
          ),
  );

  Widget _buildOverviewCards() => GridView.count(
    crossAxisCount: 3,
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    mainAxisSpacing: 16,
    crossAxisSpacing: 16,
    children: [
      TrendCard(
        title: 'Overall Sentiment',
        value: (_sentimentData['overview'] as Map<String, dynamic>?)?['overallScore'] as double? ?? 0.0,
        trend: 0.02,
        icon: Icons.sentiment_satisfied,
      ),
      TrendCard(
        title: 'Total Reviews',
        value: (_sentimentData['overview'] as Map<String, dynamic>?)?['totalReviews'] as double? ?? 0.0,
        trend: 0.05,
        icon: Icons.rate_review,
      ),
      TrendCard(
        title: 'Response Rate',
        value: (_sentimentData['overview'] as Map<String, dynamic>?)?['responseRate'] as double? ?? 0.0,
        trend: -0.01,
        icon: Icons.reply,
      ),
    ],
  );

  Widget _buildSentimentCharts() => Column(
    children: [
      SentimentChart(
        title: 'Sentiment Distribution',
        data: (_sentimentData['charts'] as Map<String, dynamic>?)?['distribution'] as List<dynamic>? ?? [],
      ),
      const SizedBox(height: 16),
      SentimentChart(
        title: 'Sentiment Trends',
        data: (_sentimentData['charts'] as Map<String, dynamic>?)?['trends'] as List<dynamic>? ?? [],
      ),
    ],
  );

  Widget _buildSentimentTable() => SentimentTable(
    title: 'Recent Reviews',
    data: (_sentimentData['reviews'] as Map<String, dynamic>?)?['recent'] as Map<String, dynamic>? ?? {},
  );
}
