import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

// Initialize logging configuration
void initLogging() {
  Logger.root.level = kDebugMode ? Level.ALL : Level.INFO;
  Logger.root.onRecord.listen((record) {
    if (kDebugMode) {
      print('${record.level.name}: ${record.time}: ${record.loggerName}: ${record.message}');
    }
  });
}

// Get a logger instance for a specific component
Logger getLogger(String name) => Logger(name);

// Convenience wrapper around Logger for simpler usage
class AppLogger {
  final Logger _logger;

  AppLogger(String tag) : _logger = Logger(tag);

  void info(String message) {
    _logger.info(message);
  }

  void warning(String message) {
    _logger.warning(message);
  }

  void severe(String message) {
    _logger.severe(message);
  }

  void fine(String message) {
    _logger.fine(message);
  }

  void debug(String message) {
    if (kDebugMode) {
      _logger.fine(message);
    }
  }
}
