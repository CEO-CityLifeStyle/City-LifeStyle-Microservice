import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/logger.dart';

class SettingsProvider with ChangeNotifier {
  static final _logger = getLogger('SettingsProvider');
  late final SharedPreferences _prefs;

  // Notification settings
  late bool _pushNotificationsEnabled;
  late bool _emailNotificationsEnabled;
  late bool _eventRemindersEnabled;
  late bool _newPlaceAlertsEnabled;

  // Privacy settings
  late bool _locationEnabled;
  late bool _profileVisible;
  late bool _activityHistoryEnabled;

  SettingsProvider() {
    _initializePreferences();
  }

  Future<void> _initializePreferences() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      _pushNotificationsEnabled = _prefs.getBool('pushNotifications') ?? true;
      _emailNotificationsEnabled = _prefs.getBool('emailNotifications') ?? true;
      _eventRemindersEnabled = _prefs.getBool('eventReminders') ?? true;
      _newPlaceAlertsEnabled = _prefs.getBool('newPlaceAlerts') ?? true;
      _locationEnabled = _prefs.getBool('locationEnabled') ?? true;
      _profileVisible = _prefs.getBool('profileVisible') ?? true;
      _activityHistoryEnabled = _prefs.getBool('activityHistory') ?? true;
      notifyListeners();
    } catch (e) {
      _logger.severe('Error initializing preferences: $e');
      // Set default values in case of error
      _pushNotificationsEnabled = true;
      _emailNotificationsEnabled = true;
      _eventRemindersEnabled = true;
      _newPlaceAlertsEnabled = true;
      _locationEnabled = true;
      _profileVisible = true;
      _activityHistoryEnabled = true;
    }
  }

  // Notification getters
  bool get pushNotificationsEnabled => _pushNotificationsEnabled;
  bool get emailNotificationsEnabled => _emailNotificationsEnabled;
  bool get eventRemindersEnabled => _eventRemindersEnabled;
  bool get newPlaceAlertsEnabled => _newPlaceAlertsEnabled;

  // Privacy getters
  bool get locationEnabled => _locationEnabled;
  bool get profileVisible => _profileVisible;
  bool get activityHistoryEnabled => _activityHistoryEnabled;

  // Notification setters
  Future<void> setPushNotifications(bool value) async {
    try {
      await _prefs.setBool('pushNotifications', value);
      _pushNotificationsEnabled = value;
      notifyListeners();
    } catch (e) {
      _logger.severe('Error setting push notifications: $e');
    }
  }

  Future<void> setEmailNotifications(bool value) async {
    try {
      await _prefs.setBool('emailNotifications', value);
      _emailNotificationsEnabled = value;
      notifyListeners();
    } catch (e) {
      _logger.severe('Error setting email notifications: $e');
    }
  }

  Future<void> setEventReminders(bool value) async {
    try {
      await _prefs.setBool('eventReminders', value);
      _eventRemindersEnabled = value;
      notifyListeners();
    } catch (e) {
      _logger.severe('Error setting event reminders: $e');
    }
  }

  Future<void> setNewPlaceAlerts(bool value) async {
    try {
      await _prefs.setBool('newPlaceAlerts', value);
      _newPlaceAlertsEnabled = value;
      notifyListeners();
    } catch (e) {
      _logger.severe('Error setting new place alerts: $e');
    }
  }

  // Privacy setters
  Future<void> setLocationEnabled(bool value) async {
    try {
      await _prefs.setBool('locationEnabled', value);
      _locationEnabled = value;
      notifyListeners();
    } catch (e) {
      _logger.severe('Error setting location enabled: $e');
    }
  }

  Future<void> setProfileVisibility(bool value) async {
    try {
      await _prefs.setBool('profileVisible', value);
      _profileVisible = value;
      notifyListeners();
    } catch (e) {
      _logger.severe('Error setting profile visibility: $e');
    }
  }

  Future<void> setActivityHistory(bool value) async {
    try {
      await _prefs.setBool('activityHistory', value);
      _activityHistoryEnabled = value;
      notifyListeners();
    } catch (e) {
      _logger.severe('Error setting activity history: $e');
    }
  }

  // Reset all settings to defaults
  Future<void> resetToDefaults() async {
    try {
      await Future.wait([
        setPushNotifications(true),
        setEmailNotifications(true),
        setEventReminders(true),
        setNewPlaceAlerts(true),
        setLocationEnabled(true),
        setProfileVisibility(true),
        setActivityHistory(true),
      ]);
      _logger.info('Settings reset to defaults');
    } catch (e) {
      _logger.severe('Error resetting settings to defaults: $e');
    }
  }
}
