import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../config/api_config.dart';
import 'error_reporting_service.dart';

class OfflineManager {
  static final OfflineManager _instance = OfflineManager._internal();
  factory OfflineManager() => _instance;

  late Database _database;
  final _connectivity = Connectivity();
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  final _pendingOperations = StreamController<PendingOperation>.broadcast();
  bool _isOnline = true;
  final ErrorReportingService _errorReporting = ErrorReportingService();

  OfflineManager._internal();

  Future<void> initialize() async {
    await _initDatabase();
    await _checkConnectivity();
    _setupConnectivityListener();
  }

  Future<void> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'offline_store.db');

    _database = await openDatabase(
      path,
      version: 1,
      onCreate: (Database db, int version) async {
        await db.execute('''
          CREATE TABLE pending_operations (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            operation TEXT NOT NULL,
            endpoint TEXT NOT NULL,
            data TEXT,
            headers TEXT,
            timestamp INTEGER NOT NULL,
            retries INTEGER DEFAULT 0,
            status TEXT DEFAULT 'pending'
          )
        ''');

        await db.execute('''
          CREATE TABLE offline_data (
            key TEXT PRIMARY KEY,
            data TEXT NOT NULL,
            timestamp INTEGER NOT NULL
          )
        ''');
      },
    );
  }

  Future<void> _checkConnectivity() async {
    final result = await _connectivity.checkConnectivity();
    _isOnline = result != ConnectivityResult.none;
  }

  void _setupConnectivityListener() {
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((result) {
      final wasOffline = !_isOnline;
      _isOnline = result != ConnectivityResult.none;

      if (wasOffline && _isOnline) {
        _processPendingOperations();
      }
    });
  }

  Future<void> queueOperation({
    required String operation,
    required String endpoint,
    Map<String, dynamic>? data,
    Map<String, String>? headers,
  }) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    await _database.insert(
      'pending_operations',
      {
        'operation': operation,
        'endpoint': endpoint,
        'data': data != null ? json.encode(data) : null,
        'headers': headers != null ? json.encode(headers) : null,
        'timestamp': timestamp,
      },
    );

    if (_isOnline) {
      _processPendingOperations();
    }
  }

  Future<void> _processPendingOperations() async {
    try {
      final operations = await _database.query(
        'pending_operations',
        where: 'status = ? AND retries < ?',
        whereArgs: ['pending', ApiConfig.maxRetries],
        orderBy: 'timestamp ASC',
      );

      for (final op in operations) {
        final operation = PendingOperation.fromMap(op);
        _pendingOperations.add(operation);

        try {
          await _executeOperation(operation);
          await _database.delete(
            'pending_operations',
            where: 'id = ?',
            whereArgs: [operation.id],
          );
        } catch (e, stackTrace) {
          await _errorReporting.reportError(e, stackTrace);
          await _database.update(
            'pending_operations',
            {
              'retries': operation.retries + 1,
              'status': operation.retries + 1 >= ApiConfig.maxRetries ? 'failed' : 'pending',
            },
            where: 'id = ?',
            whereArgs: [operation.id],
          );
        }
      }
    } catch (e, stackTrace) {
      await _errorReporting.reportError(e, stackTrace);
    }
  }

  Future<void> _executeOperation(PendingOperation operation) async {
    // Implementation will be provided by the API service
    throw UnimplementedError('Operation execution must be implemented by the API service');
  }

  Future<void> saveOfflineData(String key, dynamic data) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    await _database.insert(
      'offline_data',
      {
        'key': key,
        'data': json.encode(data),
        'timestamp': timestamp,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<T?> getOfflineData<T>(String key, T Function(Map<String, dynamic>) fromJson) async {
    final result = await _database.query(
      'offline_data',
      where: 'key = ?',
      whereArgs: [key],
    );

    if (result.isNotEmpty) {
      final data = json.decode(result.first['data'] as String);
      return fromJson(data);
    }

    return null;
  }

  Future<void> clearOfflineData() async {
    await _database.delete('offline_data');
  }

  Future<void> clearPendingOperations() async {
    await _database.delete('pending_operations');
  }

  Stream<PendingOperation> get pendingOperations => _pendingOperations.stream;

  bool get isOnline => _isOnline;

  Future<void> dispose() async {
    await _connectivitySubscription?.cancel();
    await _pendingOperations.close();
    await _database.close();
  }
}

class PendingOperation {
  final int id;
  final String operation;
  final String endpoint;
  final Map<String, dynamic>? data;
  final Map<String, String>? headers;
  final DateTime timestamp;
  final int retries;
  final String status;

  PendingOperation({
    required this.id,
    required this.operation,
    required this.endpoint,
    this.data,
    this.headers,
    required this.timestamp,
    required this.retries,
    required this.status,
  });

  factory PendingOperation.fromMap(Map<String, dynamic> map) {
    return PendingOperation(
      id: map['id'] as int,
      operation: map['operation'] as String,
      endpoint: map['endpoint'] as String,
      data: map['data'] != null ? json.decode(map['data'] as String) : null,
      headers: map['headers'] != null ? Map<String, String>.from(json.decode(map['headers'] as String)) : null,
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
      retries: map['retries'] as int,
      status: map['status'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'operation': operation,
      'endpoint': endpoint,
      'data': data != null ? json.encode(data) : null,
      'headers': headers != null ? json.encode(headers) : null,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'retries': retries,
      'status': status,
    };
  }
}
