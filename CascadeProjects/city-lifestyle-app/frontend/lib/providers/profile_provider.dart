import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../models/user.dart';
import '../utils/connectivity.dart';
import '../utils/http_client.dart';
import '../utils/logger.dart';

class ProfileProvider with ChangeNotifier {
  ProfileProvider(this.token, this.initialUser) {
    _profile = initialUser;
    _loadCachedProfile();
    _syncPendingChanges();
  }

  final String? token;
  final User? initialUser;
  final _logger = getLogger('ProfileProvider');
  final _prefs = SharedPreferences.getInstance();
  final _pendingChanges = <Map<String, dynamic>>[];
  
  User? _profile;
  bool _isLoading = false;
  bool _isSyncing = false;

  User? get profile => _profile;
  bool get isLoading => _isLoading;
  bool get isSyncing => _isSyncing;

  Future<void> _loadCachedProfile() async {
    try {
      final prefs = await _prefs;
      final cachedProfile = prefs.getString('cached_profile');
      if (cachedProfile != null) {
        final Map<String, dynamic> jsonData = json.decode(cachedProfile) as Map<String, dynamic>;
        _profile = User.fromJson(jsonData);
        notifyListeners();
      }
    } catch (e) {
      _logger.warning('Failed to load cached profile: $e');
    }
  }

  Future<void> _cacheProfile(User profile) async {
    try {
      final prefs = await _prefs;
      await prefs.setString('cached_profile', json.encode(profile.toJson()));
    } catch (e) {
      _logger.warning('Failed to cache profile: $e');
    }
  }

  Future<void> fetchProfile() async {
    if (_isLoading) return;

    _isLoading = true;
    notifyListeners();

    try {
      if (!await isConnected()) {
        _isLoading = false;
        notifyListeners();
        return;
      }

      final response = await httpClient.get(
        Uri.parse('${ApiConfig.baseUrl}/profile'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body) as Map<String, dynamic>;
        _profile = User.fromJson(jsonData);
        await _cacheProfile(_profile!);
        notifyListeners();
      }
    } catch (e) {
      _logger.severe('Error fetching profile: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateProfile(Map<String, dynamic> updates) async {
    if (!await isConnected()) {
      _pendingChanges.add(updates);
      final Map<String, dynamic> mergedData = {
        ...?_profile?.toJson(),
        ...updates,
      };
      _profile = User.fromJson(mergedData);
      await _cacheProfile(_profile!);
      notifyListeners();
      return;
    }

    try {
      final response = await httpClient.put(
        Uri.parse('${ApiConfig.baseUrl}/profile'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(updates),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body) as Map<String, dynamic>;
        _profile = User.fromJson(jsonData);
        await _cacheProfile(_profile!);
        notifyListeners();
      }
    } catch (e) {
      _logger.severe('Error updating profile: $e');
      _pendingChanges.add(updates);
    }
  }

  Future<void> updateAvatar(File imageFile) async {
    if (!await isConnected()) {
      _logger.warning('Cannot upload avatar while offline');
      return;
    }

    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConfig.baseUrl}/profile/avatar'),
      );

      request.files.add(
        await http.MultipartFile.fromPath(
          'avatar',
          imageFile.path,
        ),
      );

      request.headers['Authorization'] = 'Bearer $token';

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body) as Map<String, dynamic>;
        _profile = User.fromJson(jsonData);
        await _cacheProfile(_profile!);
        notifyListeners();
      }
    } catch (e) {
      _logger.severe('Error uploading avatar: $e');
    }
  }

  Future<void> deleteAvatar() async {
    if (!await isConnected()) {
      _logger.warning('Cannot delete avatar while offline');
      return;
    }

    try {
      final response = await httpClient.delete(
        Uri.parse('${ApiConfig.baseUrl}/profile/avatar'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body) as Map<String, dynamic>;
        _profile = User.fromJson(jsonData);
        await _cacheProfile(_profile!);
        notifyListeners();
      }
    } catch (e) {
      _logger.severe('Error deleting avatar: $e');
    }
  }

  Future<void> _syncPendingChanges() async {
    if (_isSyncing || _pendingChanges.isEmpty || !await isConnected()) return;

    _isSyncing = true;
    notifyListeners();

    try {
      while (_pendingChanges.isNotEmpty) {
        final updates = _pendingChanges.first;
        await updateProfile(updates);
        _pendingChanges.removeAt(0);
      }
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> getPrivacySettings() async {
    if (!await isConnected()) {
      return _profile?.privacy ?? <String, dynamic>{};
    }

    try {
      final response = await httpClient.get(
        Uri.parse('${ApiConfig.baseUrl}/profile/privacy'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body) as Map<String, dynamic>;
        return jsonData;
      }
      return <String, dynamic>{};
    } catch (e) {
      _logger.severe('Error fetching privacy settings: $e');
      return <String, dynamic>{};
    }
  }

  Future<void> updatePrivacySettings(Map<String, dynamic> settings) async {
    if (!await isConnected()) {
      _pendingChanges.add({'privacy': settings});
      final Map<String, dynamic> mergedData = {
        ...?_profile?.toJson(),
        'privacy': settings,
      };
      _profile = User.fromJson(mergedData);
      await _cacheProfile(_profile!);
      notifyListeners();
      return;
    }

    try {
      final response = await httpClient.put(
        Uri.parse('${ApiConfig.baseUrl}/profile/privacy'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'privacy': settings}),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body) as Map<String, dynamic>;
        _profile = User.fromJson(jsonData);
        await _cacheProfile(_profile!);
        notifyListeners();
      }
    } catch (e) {
      _logger.severe('Error updating privacy settings: $e');
      _pendingChanges.add({'privacy': settings});
    }
  }
}
