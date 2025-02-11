import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/auth_result.dart';
import '../models/user.dart';
import '../utils/http_utils.dart';

class AuthResult {
  final User user;
  final String token;

  AuthResult({required this.user, required this.token});

  factory AuthResult.fromJson(Map<String, dynamic> data) {
    return AuthResult(
      user: User.fromJson(data['user']),
      token: data['token'],
    );
  }
}

class AuthService {
  final ApiConfig _apiConfig;

  AuthService(this._apiConfig);

  static const String _tokenKey = 'auth_token';
  static const String _userDataKey = 'user_data';

  Future<AuthResult> register(String name, String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('${_apiConfig.baseUrl}/api/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'name': name,
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 201) {
        final Map<String, dynamic> data = json.decode(response.body) as Map<String, dynamic>;
        return AuthResult(
          user: User.fromJson(data['user']),
          token: data['token'],
        );
      }

      throw HttpException('Registration failed: ${response.statusCode}');
    } catch (e) {
      debugPrint('Registration error: $e');
      rethrow;
    }
  }

  Future<AuthResult> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('${_apiConfig.baseUrl}/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body) as Map<String, dynamic>;
        final String token = data['token'] as String;
        return AuthResult(
          user: User.fromJson(data['user']),
          token: token,
        );
      }

      throw HttpException('Login failed: ${response.statusCode}');
    } catch (e) {
      debugPrint('Login error: $e');
      rethrow;
    }
  }

  Future<User> getProfile(String token) async {
    try {
      final response = await http.get(
        Uri.parse('${_apiConfig.baseUrl}/api/auth/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body) as Map<String, dynamic>;
        return User.fromJson(data['user']);
      }

      throw HttpException('Failed to get profile: ${response.statusCode}');
    } catch (e) {
      debugPrint('Get profile error: $e');
      rethrow;
    }
  }

  Future<void> updateProfile(String token, Map<String, dynamic> updates) async {
    try {
      final response = await http.put(
        Uri.parse('${_apiConfig.baseUrl}/api/auth/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(updates),
      );

      if (response.statusCode != 200) {
        throw HttpException('Failed to update profile: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Update profile error: $e');
      rethrow;
    }
  }

  Future<void> changePassword(String token, String currentPassword, String newPassword) async {
    try {
      final response = await http.post(
        Uri.parse('${_apiConfig.baseUrl}/api/auth/change-password'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        }),
      );

      if (response.statusCode != 200) {
        throw HttpException('Failed to change password: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Change password error: $e');
      rethrow;
    }
  }
}
