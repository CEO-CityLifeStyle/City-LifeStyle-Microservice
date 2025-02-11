import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/logger.dart';
import '../../widgets/admin/dashboard_tab_widget.dart';
import '../../widgets/common/loading_overlay.dart';

class ResponsiveDashboardLayout extends StatefulWidget {
  const ResponsiveDashboardLayout({super.key});

  @override
  State<ResponsiveDashboardLayout> createState() => _ResponsiveDashboardLayoutState();
}

class _ResponsiveDashboardLayoutState extends State<ResponsiveDashboardLayout> {
  final _logger = getLogger('ResponsiveDashboardLayout');
  int _selectedIndex = 0;
  final bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkAdminAccess();
  }

  Future<void> _checkAdminAccess() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.hasAdminAccess) {
      _logger.severe('Non-admin user attempting to access admin dashboard');
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Admin Dashboard'),
      actions: [
        IconButton(
          icon: const Icon(Icons.filter_list),
          onPressed: _showFilterBottomSheet,
        ),
      ],
    ),
    body: Stack(
      children: [
        Row(
          children: [
            NavigationRail(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (index) {
                setState(() => _selectedIndex = index);
              },
              labelType: NavigationRailLabelType.selected,
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.dashboard),
                  label: Text('Overview'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.analytics),
                  label: Text('Analytics'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.settings),
                  label: Text('Settings'),
                ),
              ],
            ),
            const VerticalDivider(thickness: 1, width: 1),
            Expanded(
              child: IndexedStack(
                index: _selectedIndex,
                children: [
                  DashboardTabWidget(
                    title: 'Overview',
                    content: _buildOverviewTab(),
                    isLoading: _isLoading,
                  ),
                  DashboardTabWidget(
                    title: 'Analytics',
                    content: _buildAnalyticsTab(),
                    isLoading: _isLoading,
                  ),
                  DashboardTabWidget(
                    title: 'Settings',
                    content: _buildSettingsTab(),
                    isLoading: _isLoading,
                  ),
                ],
              ),
            ),
          ],
        ),
        if (_isLoading) LoadingOverlay(
          isLoading: _isLoading,
          child: const CircularProgressIndicator(),
        ),
      ],
    ),
  );

  Widget _buildOverviewTab() => const Center(
    child: Text('Overview Content'),
  );

  Widget _buildAnalyticsTab() => const Center(
    child: Text('Analytics Content'),
  );

  Widget _buildSettingsTab() => const Center(
    child: Text('Settings Content'),
  );

  void _showFilterBottomSheet() {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Filter Options',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.date_range),
              title: const Text('Date Range'),
              onTap: () {
                // Handle date range filter
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.category),
              title: const Text('Categories'),
              onTap: () {
                // Handle categories filter
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
