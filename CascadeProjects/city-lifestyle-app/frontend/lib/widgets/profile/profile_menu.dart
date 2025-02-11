import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user_profile.dart';
import '../../providers/auth_provider.dart';
import '../../utils/logger.dart';

class ProfileMenu extends StatelessWidget {
  final UserProfile profile;
  final _logger = getLogger('ProfileMenu');

  ProfileMenu({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildMenuItem(
            context,
            icon: Icons.favorite,
            label: 'My Favorites',
            onTap: () => Navigator.pushNamed(context, '/favorites'),
          ),
          const SizedBox(height: 8),
          _buildMenuItem(
            context,
            icon: Icons.event,
            label: 'My Events',
            onTap: () => Navigator.pushNamed(context, '/events'),
          ),
          const SizedBox(height: 8),
          _buildMenuItem(
            context,
            icon: Icons.star,
            label: 'My Reviews',
            onTap: () => Navigator.pushNamed(context, '/reviews'),
          ),
          const SizedBox(height: 16),
          _buildLogoutButton(context),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return ElevatedButton.icon(
      icon: Icon(icon),
      label: Text(label),
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(200, 40),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return ElevatedButton.icon(
      icon: const Icon(Icons.logout, color: Colors.red),
      label: const Text('Logout', style: TextStyle(color: Colors.red)),
      onPressed: () => _handleLogout(context),
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(200, 40),
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    try {
      await Provider.of<AuthProvider>(context, listen: false).logout();
      if (context.mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/login',
          (route) => false,
        );
      }
    } catch (e) {
      _logger.severe('Error during logout: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logout failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
