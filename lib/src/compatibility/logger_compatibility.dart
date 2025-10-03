import 'package:meta/meta.dart';

import '../enums/log_level.dart';
import '../events/log_event.dart';

/// Interface for compatibility with popular logger packages
///
/// This interface ensures that StrategicLogger can be used as a drop-in replacement
/// for popular logger packages like `logger`, `logging`, `loggy`, etc.
@sealed
abstract class LoggerCompatibility {
  /// Logs a message at debug level
  void debug(dynamic message, [dynamic error, StackTrace? stackTrace]);

  /// Logs a message at info level
  void info(dynamic message, [dynamic error, StackTrace? stackTrace]);

  /// Logs a message at warning level
  void warning(dynamic message, [dynamic error, StackTrace? stackTrace]);

  /// Logs a message at error level
  void error(dynamic message, [dynamic error, StackTrace? stackTrace]);

  /// Logs a message at fatal level
  void fatal(dynamic message, [dynamic error, StackTrace? stackTrace]);

  /// Logs a message at verbose level (alias for debug)
  void verbose(dynamic message, [dynamic error, StackTrace? stackTrace]);

  /// Logs a message (alias for info)
  void log(dynamic message, [dynamic error, StackTrace? stackTrace]);

  /// Logs a message with custom level
  void logWithLevel(
    LogLevel level,
    dynamic message, [
    dynamic error,
    StackTrace? stackTrace,
  ]);

  /// Logs a message with additional context
  void logWithContext(
    LogLevel level,
    dynamic message, {
    Map<String, Object>? context,
    LogEvent? event,
    dynamic error,
    StackTrace? stackTrace,
  });
}

/// Extension methods for enhanced compatibility
extension LoggerCompatibilityExtensions on LoggerCompatibility {
  /// Logs a message with structured data
  void logStructured(
    LogLevel level,
    dynamic message, {
    Map<String, Object>? data,
    String? tag,
    DateTime? timestamp,
  }) {
    final event = LogEvent(
      eventName: tag ?? 'LOG',
      eventMessage: message.toString(),
      parameters: data,
    );

    logWithContext(level, message, event: event);
  }

  /// Logs an error with additional context
  void logError(
    dynamic error, {
    StackTrace? stackTrace,
    String? message,
    Map<String, Object>? context,
  }) {
    final logMessage = message ?? error.toString();
    final event = LogEvent(
      eventName: 'ERROR',
      eventMessage: logMessage,
      parameters: context,
    );

    logWithContext(
      LogLevel.error,
      logMessage,
      event: event,
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Logs a warning with additional context
  void logWarning(
    dynamic message, {
    Map<String, Object>? context,
    String? tag,
  }) {
    final event = LogEvent(
      eventName: tag ?? 'WARNING',
      eventMessage: message.toString(),
      parameters: context,
    );

    logWithContext(LogLevel.warning, message, event: event);
  }

  /// Logs an info message with additional context
  void logInfo(dynamic message, {Map<String, Object>? context, String? tag}) {
    final event = LogEvent(
      eventName: tag ?? 'INFO',
      eventMessage: message.toString(),
      parameters: context,
    );

    logWithContext(LogLevel.info, message, event: event);
  }

  /// Logs a debug message with additional context
  void logDebug(dynamic message, {Map<String, Object>? context, String? tag}) {
    final event = LogEvent(
      eventName: tag ?? 'DEBUG',
      eventMessage: message.toString(),
      parameters: context,
    );

    logWithContext(LogLevel.debug, message, event: event);
  }

  /// Logs a fatal error with additional context
  void logFatal(
    dynamic error, {
    StackTrace? stackTrace,
    String? message,
    Map<String, Object>? context,
  }) {
    final logMessage = message ?? error.toString();
    final event = LogEvent(
      eventName: 'FATAL',
      eventMessage: logMessage,
      parameters: context,
    );

    logWithContext(
      LogLevel.fatal,
      logMessage,
      event: event,
      error: error,
      stackTrace: stackTrace,
    );
  }
}

/// Compatibility mixin for logger packages
mixin LoggerCompatibilityMixin implements LoggerCompatibility {
  /// Abstract method to be implemented by concrete loggers
  Future<void> logMessage(
    LogLevel level,
    dynamic message, {
    LogEvent? event,
    Map<String, Object>? context,
    dynamic error,
    StackTrace? stackTrace,
  });

  @override
  void debug(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    logMessage(LogLevel.debug, message, error: error, stackTrace: stackTrace);
  }

  @override
  void info(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    logMessage(LogLevel.info, message, error: error, stackTrace: stackTrace);
  }

  @override
  void warning(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    logMessage(LogLevel.warning, message, error: error, stackTrace: stackTrace);
  }

  @override
  void error(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    logMessage(LogLevel.error, message, error: error, stackTrace: stackTrace);
  }

  @override
  void fatal(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    logMessage(LogLevel.fatal, message, error: error, stackTrace: stackTrace);
  }

  @override
  void verbose(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    debug(message, error, stackTrace);
  }

  @override
  void log(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    info(message, error, stackTrace);
  }

  @override
  void logWithLevel(
    LogLevel level,
    dynamic message, [
    dynamic error,
    StackTrace? stackTrace,
  ]) {
    logMessage(level, message, error: error, stackTrace: stackTrace);
  }

  @override
  void logWithContext(
    LogLevel level,
    dynamic message, {
    Map<String, Object>? context,
    LogEvent? event,
    dynamic error,
    StackTrace? stackTrace,
  }) {
    logMessage(
      level,
      message,
      event: event,
      context: context,
      error: error,
      stackTrace: stackTrace,
    );
  }
}
