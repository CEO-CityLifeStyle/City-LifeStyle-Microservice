import 'package:flutter/material.dart';
import '../../models/user_profile.dart';

class ProfileStats extends StatelessWidget {
  final UserProfile profile;

  const ProfileStats({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildStatItem(context, 'Reviews', '0'),
        _buildStatItem(context, 'Places', '0'),
        _buildStatItem(context, 'Events', '0'),
      ],
    );
  }

  Widget _buildStatItem(BuildContext context, String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}
