import 'dart:async';
import 'dart:math' as math;
import '../config/api_config.dart';

typedef RetryableOperation<T> = Future<T> Function();

class RetryService {
  static final RetryService _instance = RetryService._internal();
  factory RetryService() => _instance;

  RetryService._internal();

  Future<T> retry<T>({
    required RetryableOperation<T> operation,
    int maxAttempts = ApiConfig.maxRetries,
    Duration? initialDelay,
    bool useExponentialBackoff = true,
    bool Function(Exception)? shouldRetry,
  }) async {
    initialDelay ??= ApiConfig.retryDelay;
    var attempts = 0;
    Exception? lastError;

    while (attempts < maxAttempts) {
      try {
        if (attempts > 0) {
          await _delay(attempts, initialDelay, useExponentialBackoff);
        }
        return await operation();
      } on Exception catch (e) {
        lastError = e;
        attempts++;

        if (shouldRetry != null && !shouldRetry(e)) {
          break;
        }

        if (attempts >= maxAttempts) {
          break;
        }
      }
    }

    throw RetryException(
      'Operation failed after $attempts attempts',
      lastError,
      attempts,
    );
  }

  Future<void> _delay(
    int attempt,
    Duration initialDelay,
    bool useExponentialBackoff,
  ) async {
    if (useExponentialBackoff) {
      final backoffFactor = math.min(math.pow(2, attempt - 1), 10);
      final jitter = math.Random().nextDouble() * 0.1 + 0.9; // 0.9-1.1
      final delay = initialDelay * backoffFactor * jitter;
      await Future.delayed(delay);
    } else {
      await Future.delayed(initialDelay);
    }
  }

  bool shouldRetryStatusCode(int statusCode) {
    // Retry on server errors and some specific client errors
    return statusCode >= 500 || // Server errors
           statusCode == 429 || // Too many requests
           statusCode == 408 || // Request timeout
           statusCode == 409;   // Conflict
  }

  bool shouldRetryException(Exception error) {
    // Retry on network-related errors
    return error.toString().toLowerCase().contains('network') ||
           error.toString().toLowerCase().contains('timeout') ||
           error.toString().toLowerCase().contains('connection');
  }
}

class RetryException implements Exception {
  final String message;
  final Exception? cause;
  final int attempts;

  RetryException(this.message, this.cause, this.attempts);

  @override
  String toString() {
    return 'RetryException: $message (attempts: $attempts, cause: $cause)';
  }
}
