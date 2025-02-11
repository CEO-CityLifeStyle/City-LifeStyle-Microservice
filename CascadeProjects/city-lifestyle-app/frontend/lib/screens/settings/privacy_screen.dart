import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/settings_provider.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy'),
      ),
      body: Consumer<SettingsProvider>(
        builder: (context, settings, _) => ListView(
          children: [
            SwitchListTile(
              title: const Text('Location Services'),
              subtitle: const Text('Allow app to access your location'),
              value: settings.locationEnabled,
              onChanged: (bool value) {
                settings.setLocationEnabled(value);
              },
            ),
            SwitchListTile(
              title: const Text('Profile Visibility'),
              subtitle: const Text('Make your profile visible to other users'),
              value: settings.profileVisible,
              onChanged: (bool value) {
                settings.setProfileVisibility(value);
              },
            ),
            SwitchListTile(
              title: const Text('Activity History'),
              subtitle: const Text('Save your activity history'),
              value: settings.activityHistoryEnabled,
              onChanged: (bool value) {
                settings.setActivityHistory(value);
              },
            ),
            ListTile(
              title: const Text('Delete Account'),
              subtitle: const Text('Permanently delete your account and all data'),
              trailing: const Icon(Icons.warning, color: Colors.red),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Delete Account'),
                    content: const Text(
                      'Are you sure you want to delete your account? This action cannot be undone.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('CANCEL'),
                      ),
                      TextButton(
                        onPressed: () {
                          // TODO: Implement account deletion
                          Navigator.pop(context);
                        },
                        child: const Text(
                          'DELETE',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
