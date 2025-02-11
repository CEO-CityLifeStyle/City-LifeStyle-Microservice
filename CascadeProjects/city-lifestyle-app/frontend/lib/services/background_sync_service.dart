import 'dart:async';
import 'package:workmanager/workmanager.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'offline_manager.dart';
import 'error_reporting_service.dart';

class BackgroundSyncService {
  static final BackgroundSyncService _instance = BackgroundSyncService._internal();
  factory BackgroundSyncService() => _instance;

  static const String periodicSyncTask = 'com.citylifestyle.periodicSync';
  static const String oneTimeSyncTask = 'com.citylifestyle.oneTimeSync';
  
  final _connectivity = Connectivity();
  final _offlineManager = OfflineManager();
  final _errorReporting = ErrorReportingService();
  bool _isInitialized = false;
  Timer? _backgroundSyncTimer;

  BackgroundSyncService._internal();

  Future<void> initialize() async {
    if (_isInitialized) return;

    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: false,
    );

    // Register periodic background sync
    await Workmanager().registerPeriodicTask(
      periodicSyncTask,
      periodicSyncTask,
      frequency: const Duration(minutes: 15),
      constraints: Constraints(
        networkType: NetworkType.connected,
        requiresBatteryNotLow: true,
        requiresDeviceIdle: false,
      ),
      existingWorkPolicy: ExistingWorkPolicy.replace,
    );

    // Start foreground sync timer
    _startForegroundSync();

    _isInitialized = true;
  }

  void _startForegroundSync() {
    _backgroundSyncTimer?.cancel();
    _backgroundSyncTimer = Timer.periodic(
      const Duration(minutes: 5),
      (timer) => _performForegroundSync(),
    );
  }

  Future<void> _performForegroundSync() async {
    try {
      final connectivityResult = await _connectivity.checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        return;
      }

      await _offlineManager.processPendingOperations();
    } catch (e, stackTrace) {
      await _errorReporting.reportError(
        e,
        stackTrace,
        context: {'source': 'foreground_sync'},
      );
    }
  }

  Future<void> requestImmediateSync() async {
    try {
      // Schedule a one-time task
      await Workmanager().registerOneOffTask(
        oneTimeSyncTask,
        oneTimeSyncTask,
        constraints: Constraints(
          networkType: NetworkType.connected,
          requiresBatteryNotLow: false,
        ),
      );

      // Also perform a foreground sync
      await _performForegroundSync();
    } catch (e, stackTrace) {
      await _errorReporting.reportError(
        e,
        stackTrace,
        context: {'source': 'immediate_sync_request'},
      );
    }
  }

  Future<void> syncSpecificData(String dataType) async {
    try {
      await Workmanager().registerOneOffTask(
        '${oneTimeSyncTask}_$dataType',
        oneTimeSyncTask,
        inputData: {'dataType': dataType},
        constraints: Constraints(
          networkType: NetworkType.connected,
          requiresBatteryNotLow: false,
        ),
      );
    } catch (e, stackTrace) {
      await _errorReporting.reportError(
        e,
        stackTrace,
        context: {
          'source': 'specific_sync_request',
          'dataType': dataType,
        },
      );
    }
  }

  void dispose() {
    _backgroundSyncTimer?.cancel();
    _backgroundSyncTimer = null;
  }
}

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      final offlineManager = OfflineManager();
      final errorReporting = ErrorReportingService();

      switch (task) {
        case BackgroundSyncService.periodicSyncTask:
          await offlineManager.processPendingOperations();
          break;

        case BackgroundSyncService.oneTimeSyncTask:
          if (inputData?.containsKey('dataType') ?? false) {
            // Handle specific data type sync
            final dataType = inputData!['dataType'] as String;
            await offlineManager.processPendingOperations(dataType: dataType);
          } else {
            // Handle general sync
            await offlineManager.processPendingOperations();
          }
          break;

        default:
          return false;
      }

      return true;
    } catch (e, stackTrace) {
      final errorReporting = ErrorReportingService();
      await errorReporting.reportError(
        e,
        stackTrace,
        context: {
          'source': 'background_sync',
          'task': task,
          'inputData': inputData,
        },
      );
      return false;
    }
  });
}
