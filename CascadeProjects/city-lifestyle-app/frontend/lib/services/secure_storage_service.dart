import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static const _storage = FlutterSecureStorage();
  
  // Storage keys
  static const String _authTokenKey = 'auth_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userIdKey = 'user_id';
  static const String _userRoleKey = 'user_role';

  // Android specific options
  static const AndroidOptions _androidOptions = AndroidOptions(
    encryptedSharedPreferences: true,
    resetOnError: true,
  );

  // iOS specific options
  static const IOSOptions _iosOptions = IOSOptions(
    accessibility: KeychainAccessibility.first_unlock,
    synchronizable: true,
  );

  // Store auth token
  static Future<void> storeAuthToken(String token) async {
    await _storage.write(
      key: _authTokenKey,
      value: token,
      aOptions: _androidOptions,
      iOptions: _iosOptions,
    );
  }

  // Get auth token
  static Future<String?> getAuthToken() async {
    return await _storage.read(
      key: _authTokenKey,
      aOptions: _androidOptions,
      iOptions: _iosOptions,
    );
  }

  // Store refresh token
  static Future<void> storeRefreshToken(String token) async {
    await _storage.write(
      key: _refreshTokenKey,
      value: token,
      aOptions: _androidOptions,
      iOptions: _iosOptions,
    );
  }

  // Get refresh token
  static Future<String?> getRefreshToken() async {
    return await _storage.read(
      key: _refreshTokenKey,
      aOptions: _androidOptions,
      iOptions: _iosOptions,
    );
  }

  // Store user ID
  static Future<void> storeUserId(String userId) async {
    await _storage.write(
      key: _userIdKey,
      value: userId,
      aOptions: _androidOptions,
      iOptions: _iosOptions,
    );
  }

  // Get user ID
  static Future<String?> getUserId() async {
    return await _storage.read(
      key: _userIdKey,
      aOptions: _androidOptions,
      iOptions: _iosOptions,
    );
  }

  // Store user role
  static Future<void> storeUserRole(String role) async {
    await _storage.write(
      key: _userRoleKey,
      value: role,
      aOptions: _androidOptions,
      iOptions: _iosOptions,
    );
  }

  // Get user role
  static Future<String?> getUserRole() async {
    return await _storage.read(
      key: _userRoleKey,
      aOptions: _androidOptions,
      iOptions: _iosOptions,
    );
  }

  // Clear all stored data
  static Future<void> clearAll() async {
    await _storage.deleteAll(
      aOptions: _androidOptions,
      iOptions: _iosOptions,
    );
  }

  static Future<String?> getToken() async {
    return await read(key: 'token');
  }

  static Future<String?> read({required String key}) async {
    try {
      return await _storage.read(
        key: key,
        aOptions: _androidOptions,
        iOptions: _iosOptions,
      );
    } catch (e) {
      return null;
    }
  }

  static Future<void> write({required String key, required String value}) async {
    await _storage.write(
      key: key,
      value: value,
      aOptions: _androidOptions,
      iOptions: _iosOptions,
    );
  }

  static Future<void> delete({required String key}) async {
    await _storage.delete(
      key: key,
      aOptions: _androidOptions,
      iOptions: _iosOptions,
    );
  }

  static Future<void> deleteAll() async {
    await _storage.deleteAll(
      aOptions: _androidOptions,
      iOptions: _iosOptions,
    );
  }
}
