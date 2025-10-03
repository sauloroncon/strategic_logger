import '../enums/log_level.dart';
import '../strategic_logger.dart';

/// Synchronous compatibility methods for StrategicLogger
///
/// This extension provides synchronous methods that match popular logger packages
/// while internally using the async StrategicLogger implementation.
extension StrategicLoggerSyncCompatibility on StrategicLogger {
  /// Synchronous debug logging (compatibility with popular logger packages)
  void debugSync(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _logSync(LogLevel.debug, message, error: error, stackTrace: stackTrace);
  }

  /// Synchronous info logging (compatibility with popular logger packages)
  void infoSync(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _logSync(LogLevel.info, message, error: error, stackTrace: stackTrace);
  }

  /// Synchronous warning logging (compatibility with popular logger packages)
  void warningSync(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _logSync(LogLevel.warning, message, error: error, stackTrace: stackTrace);
  }

  /// Synchronous error logging (compatibility with popular logger packages)
  void errorSync(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _logSync(LogLevel.error, message, error: error, stackTrace: stackTrace);
  }

  /// Synchronous fatal logging (compatibility with popular logger packages)
  void fatalSync(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _logSync(LogLevel.fatal, message, error: error, stackTrace: stackTrace);
  }

  /// Synchronous verbose logging (alias for debug)
  void verboseSync(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    debugSync(message, error, stackTrace);
  }

  /// Synchronous log method (alias for info)
  void logSync(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    infoSync(message, error, stackTrace);
  }

  /// Internal synchronous logging method
  void _logSync(
    LogLevel level,
    dynamic message, {
    dynamic error,
    StackTrace? stackTrace,
  }) {
    if (!isInitialized) {
      throw Exception('Logger not initialized');
    }

    // Use the async method and handle errors silently
    log(message).catchError((e) {
      // Silently handle errors in sync methods
      print('Error in sync logging: $e');
    });
  }
}

/// Compatibility wrapper that implements popular logger interfaces
class StrategicLoggerCompatibilityWrapper {
  final StrategicLogger _logger;

  StrategicLoggerCompatibilityWrapper(this._logger);

  /// Debug logging (compatible with logger package)
  void debug(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _logger.debugSync(message, error, stackTrace);
  }

  /// Info logging (compatible with logger package)
  void info(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _logger.infoSync(message, error, stackTrace);
  }

  /// Warning logging (compatible with logger package)
  void warning(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _logger.warningSync(message, error, stackTrace);
  }

  /// Error logging (compatible with logger package)
  void error(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _logger.errorSync(message, error, stackTrace);
  }

  /// Fatal logging (compatible with logger package)
  void fatal(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _logger.fatalSync(message, error, stackTrace);
  }

  /// Verbose logging (compatible with logger package)
  void verbose(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _logger.verboseSync(message, error, stackTrace);
  }

  /// Log method (compatible with logger package)
  void log(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _logger.logSync(message, error, stackTrace);
  }

  /// Log with custom level (compatible with logger package)
  void logWithLevel(
    LogLevel level,
    dynamic message, [
    dynamic error,
    StackTrace? stackTrace,
  ]) {
    switch (level) {
      case LogLevel.debug:
        debug(message, error, stackTrace);
        break;
      case LogLevel.info:
        info(message, error, stackTrace);
        break;
      case LogLevel.warning:
        warning(message, error, stackTrace);
        break;
      case LogLevel.error:
        error(message, error, stackTrace);
        break;
      case LogLevel.fatal:
        fatal(message, error, stackTrace);
        break;
      case LogLevel.none:
        // Do nothing
        break;
    }
  }
}

/// Global compatibility wrapper instance
final loggerCompatibility = StrategicLoggerCompatibilityWrapper(logger);
