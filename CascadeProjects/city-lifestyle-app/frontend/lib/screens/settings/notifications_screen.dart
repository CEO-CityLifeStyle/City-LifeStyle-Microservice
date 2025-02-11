import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/settings_provider.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
      ),
      body: Consumer<SettingsProvider>(
        builder: (context, settings, _) => ListView(
          children: [
            SwitchListTile(
              title: const Text('Push Notifications'),
              subtitle: const Text('Receive notifications about new events and updates'),
              value: settings.pushNotificationsEnabled,
              onChanged: (bool value) {
                settings.setPushNotifications(value);
              },
            ),
            SwitchListTile(
              title: const Text('Email Notifications'),
              subtitle: const Text('Receive email updates about your favorite places'),
              value: settings.emailNotificationsEnabled,
              onChanged: (bool value) {
                settings.setEmailNotifications(value);
              },
            ),
            SwitchListTile(
              title: const Text('Event Reminders'),
              subtitle: const Text('Get reminded about upcoming events'),
              value: settings.eventRemindersEnabled,
              onChanged: (bool value) {
                settings.setEventReminders(value);
              },
            ),
            SwitchListTile(
              title: const Text('New Place Alerts'),
              subtitle: const Text('Get notified when new places are added in your area'),
              value: settings.newPlaceAlertsEnabled,
              onChanged: (bool value) {
                settings.setNewPlaceAlerts(value);
              },
            ),
          ],
        ),
      ),
    );
  }
}
