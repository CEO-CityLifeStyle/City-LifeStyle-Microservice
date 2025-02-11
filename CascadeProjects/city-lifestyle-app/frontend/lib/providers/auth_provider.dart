import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../models/auth_result.dart';
import '../utils/http_exception.dart';
import '../utils/logger.dart';

class AuthProvider with ChangeNotifier {
  final _logger = getLogger('AuthProvider');
  final _storage = const FlutterSecureStorage();
  
  String? _token;
  DateTime? _expiryDate;
  Timer? _authTimer;
  AuthResult? _authResult;
  String? _userRole;

  bool get isAuth => token != null;

  String? get token {
    if (_expiryDate != null &&
        _expiryDate!.isAfter(DateTime.now()) &&
        _token != null) {
      return _token;
    }
    return null;
  }

  AuthResult? get user => _authResult;

  bool get isAuthenticated => _token != null;

  bool get hasAdminAccess => isAuthenticated && _userRole == 'admin';

  Future<void> signup(String email, String password, String name) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/auth/signup');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'password': password,
          'name': name,
        }),
      );

      if (response.statusCode >= 400) {
        throw HttpException(
          (json.decode(response.body) as Map<String, dynamic>)['message'] as String? ?? 'Authentication failed',
          statusCode: response.statusCode,
        );
      }

      _logger.info('User signed up successfully');
      await login(email, password);
    } catch (e) {
      _logger.severe('Signup error: $e');
      rethrow;
    }
  }

  Future<void> login(String email, String password) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/auth/login');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode >= 400) {
        throw HttpException(
          (json.decode(response.body) as Map<String, dynamic>)['message'] as String? ?? 'Authentication failed',
          statusCode: response.statusCode,
        );
      }

      final responseData = json.decode(response.body) as Map<String, dynamic>;
      _authResult = AuthResult.fromJson(responseData);
      
      _token = _authResult!.token;
      _expiryDate = _authResult!.expiryDate;
      _userRole = _authResult!.userRole;

      _autoLogout();
      notifyListeners();

      // Store auth data
      final prefs = await SharedPreferences.getInstance();
      final userData = json.encode(_authResult!.toJson());
      await prefs.setString('userData', userData);

      _logger.info('User logged in successfully');
    } catch (e) {
      _logger.severe('Login error: $e');
      rethrow;
    }
  }

  Future<bool> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey('userData')) {
      return false;
    }

    try {
      final extractedUserData = json.decode(prefs.getString('userData')!) as Map<String, dynamic>;
      _authResult = AuthResult.fromJson(extractedUserData);
      
      _token = _authResult!.token;
      _expiryDate = _authResult!.expiryDate;
      _userRole = _authResult!.userRole;
      
      notifyListeners();
      _autoLogout();
      return true;
    } catch (e) {
      _logger.severe('Auto login error: $e');
      return false;
    }
  }

  Future<void> logout() async {
    _token = null;
    _expiryDate = null;
    _authResult = null;
    _userRole = null;
    
    if (_authTimer != null) {
      _authTimer!.cancel();
      _authTimer = null;
    }

    // Clear stored data
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userData');
    await _storage.delete(key: 'token');
    
    notifyListeners();
    _logger.info('User logged out successfully');
  }

  void _autoLogout() {
    if (_authTimer != null) {
      _authTimer!.cancel();
    }
    
    final timeToExpiry = _expiryDate?.difference(DateTime.now()).inSeconds ?? 0;
    if (timeToExpiry > 0) {
      _authTimer = Timer(Duration(seconds: timeToExpiry), logout);
    }
  }
}
