import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path;

class CacheEntry {
  final String key;
  final Map<String, dynamic> data;
  final DateTime expiresAt;

  const CacheEntry({
    required this.key,
    required this.data,
    required this.expiresAt,
  });

  factory CacheEntry.fromJson(Map<String, dynamic> json) {
    return CacheEntry(
      key: json['key'] as String,
      data: json['data'] as Map<String, dynamic>,
      expiresAt: DateTime.parse(json['expiresAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'key': key,
    'data': data,
    'expiresAt': expiresAt.toIso8601String(),
  };

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

class CacheService {
  static const String _tableName = 'cache';
  static const Duration _defaultExpiration = Duration(hours: 24);
  
  Database? _db;
  final _initCompleter = Completer<void>();

  CacheService() {
    _initDatabase();
  }

  Future<void> _initDatabase() async {
    try {
      final documentsDirectory = await getApplicationDocumentsDirectory();
      final databasePath = path.join(documentsDirectory.path, 'cache.db');

      _db = await openDatabase(
        databasePath,
        version: 1,
        onCreate: (Database db, int version) async {
          await db.execute('''
            CREATE TABLE $_tableName (
              key TEXT PRIMARY KEY,
              data TEXT NOT NULL,
              expiresAt TEXT NOT NULL
            )
          ''');
        },
      );

      _initCompleter.complete();
    } catch (e) {
      debugPrint('Failed to initialize cache database: $e');
      _initCompleter.completeError(e);
    }
  }

  Future<void> set(
    String key,
    Map<String, dynamic> data, {
    Duration? expiration,
  }) async {
    await _initCompleter.future;
    
    final db = _db;
    if (db == null) throw Exception('Database not initialized');

    final entry = CacheEntry(
      key: key,
      data: data,
      expiresAt: DateTime.now().add(expiration ?? _defaultExpiration),
    );

    await db.insert(
      _tableName,
      {
        'key': entry.key,
        'data': json.encode(entry.data),
        'expiresAt': entry.expiresAt.toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, dynamic>?> get(String key) async {
    await _initCompleter.future;
    
    final db = _db;
    if (db == null) throw Exception('Database not initialized');

    final results = await db.query(
      _tableName,
      where: 'key = ?',
      whereArgs: [key],
    );

    if (results.isEmpty) return null;

    final entry = CacheEntry.fromJson({
      'key': results.first['key'] as String,
      'data': json.decode(results.first['data'] as String) as Map<String, dynamic>,
      'expiresAt': results.first['expiresAt'] as String,
    });

    if (entry.isExpired) {
      await delete(key);
      return null;
    }

    return entry.data;
  }

  Future<void> delete(String key) async {
    await _initCompleter.future;
    
    final db = _db;
    if (db == null) throw Exception('Database not initialized');

    await db.delete(
      _tableName,
      where: 'key = ?',
      whereArgs: [key],
    );
  }

  Future<void> clear() async {
    await _initCompleter.future;
    
    final db = _db;
    if (db == null) throw Exception('Database not initialized');

    await db.delete(_tableName);
  }

  Future<void> clearExpired() async {
    await _initCompleter.future;
    
    final db = _db;
    if (db == null) throw Exception('Database not initialized');

    await db.delete(
      _tableName,
      where: 'expiresAt < ?',
      whereArgs: [DateTime.now().toIso8601String()],
    );
  }

  Future<void> close() async {
    final db = _db;
    if (db != null) {
      await db.close();
      _db = null;
    }
  }
}
