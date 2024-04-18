import 'dart:developer' as developer;

import 'enums/log_level.dart';

import 'errors/alread_initialized_error.dart';
import 'errors/not_initialized_error.dart';
import 'events/log_event.dart';
import 'strategies/log_strategy.dart';

/// A flexible and centralized logger that supports multiple logging strategies.
///
/// `StrategicLogger` is designed to handle logging across various levels and strategies,
/// allowing for detailed logging control throughout an application. It ensures that only a single
/// instance of the logger is initialized and used throughout the application lifecycle.
///
/// The logger must be initialized before use, with the desired log level and strategies provided.
/// After initialization, the logger can be reconfigured, but this should be used with caution to
/// avoid unintended side effects during the application lifecycle.
///
/// Example:
/// ```dart
/// await logger.initialize(strategies: [ConsoleLogStrategy()], level: LogLevel.info);
/// logger.log("Application started.");
/// ```
StrategicLogger logger = StrategicLogger();

class StrategicLogger {
  bool _isInitialized = false;

  /// Indicates whether the logger has been initialized.
  bool get isInitialized => _isInitialized;

  LogLevel _initLogLevel = LogLevel.none;

  /// Current log level of the logger.
  LogLevel get level => _initLogLevel;

  List<LogStrategy> _strategies = [];

  /// Reconfigures the logger even if it has been previously initialized.
  ///
  /// This should be used with caution, as reconfiguring a logger that is already in use can lead to inconsistent logging behavior.
  ///
  /// [strategies] - List of new strategies to use for logging.
  /// [level] - The minimum log level to log. Defaults to [LogLevel.none].
  Future<void> reconfigure({
    List<LogStrategy>? strategies,
    LogLevel level = LogLevel.none,    
  }) async {
    logger._initialize(strategies: strategies, level: level, force: true);
  }

  /// Configures the logger if it has not been initialized.
  ///
  /// This method should be used for the initial setup of the logger.
  ///
  /// [strategies] - List of strategies to use for logging.
  /// [level] - The minimum log level to log. Defaults to [LogLevel.none].
  Future<void> initialize({
    List<LogStrategy>? strategies,
    LogLevel level = LogLevel.none,    
  }) async {
    logger._initialize(strategies: strategies, level: level);    
  }

  /// Initializes or reinitializes the logger with specified strategies and log level.
  ///
  /// Throws [AlreadyInitializedError] if the logger is already initialized and [force] is not set to true.
  ///
  /// [strategies] - List of strategies to use for logging.
  /// [level] - The minimum log level to log. Defaults to [LogLevel.none].
  /// [force] - Forces reinitialization if set to true.
  Future<StrategicLogger> _initialize({
    List<LogStrategy>? strategies,
    LogLevel level = LogLevel.none,
    bool force = false,
  }) async {    
    if (_isInitialized && !force) {
      throw AlreadyInitializedError();
    } else {
      _initializeStrategies(strategies, level);
      _printStrategicLoggerInit();
      _isInitialized = true;
    }
    return logger;
  }

  /// Sets up the logging strategies and log level.
  void _initializeStrategies(List<LogStrategy>? strategies, LogLevel level) {
    logger._strategies = strategies ?? [];
    logger._initLogLevel = level;

    if (strategies != null && strategies.isNotEmpty) {
      for (var strategy in strategies) {
        if (strategy.logLevel == LogLevel.none) {
          strategy.logLevel = logger._initLogLevel;
        }
        strategy.loggerLogLevel = level;
      }
    }
  }

  /// Logs a message or event using the configured strategies.
  ///
  /// Throws [NotInitializedError] if the logger has not been initialized.
  ///
  /// [message] - The message to log.
  /// [event] - Optional. The specific log event associated with the message.
  Future<void> log(dynamic message, {LogEvent? event}) async {
    if (!_isInitialized) {
      throw NotInitializedError();
    }
    for (var strategy in logger._strategies) {
      await strategy.log(message: message, event: event);
    }
  }

  /// Logs an error using the configured strategies.
  ///
  /// Throws [NotInitializedError] if the logger has not been initialized.
  ///
  /// [error] - The error object to log.
  /// [stackTrace] - The stack trace associated with the error.
  /// [event] - Optional. The specific log event associated with the error.
  Future<void> error(dynamic error, {StackTrace? stackTrace, LogEvent? event}) async {
    if (!_isInitialized) {
      throw NotInitializedError();
    }
    for (var strategy in logger._strategies) {
      await strategy.error(error: error, stackTrace: stackTrace, event: event);
    }
  }

  /// Logs a fatal error using the configured strategies.
  ///
  /// Throws [NotInitializedError] if the logger has not been initialized.
  ///
  /// [error] - The critical error object to log as fatal.
  /// [stackTrace] - The stack trace associated with the fatal error.
  /// [event] - Optional. The specific log event associated with the fatal error.
  Future<void> fatal(dynamic error, {StackTrace? stackTrace, LogEvent? event}) async {
    if (!_isInitialized) {
      throw NotInitializedError();
    }
    for (var strategy in logger._strategies) {
      await strategy.fatal(error: error, stackTrace: stackTrace, event: event);
    }
  }  

  /// Prints initialization details of the logger, including whether it was a reconfiguration.
  void _printStrategicLoggerInit() {
    String strategiesFormatted = _strategies.map((s) => '    - ${s.toString()}').join('\n');

    String logMessage = [
        '══════════════════════════════ STRATEGIC LOGGER CONFIG ══════════════════════════════',
        _isInitialized ? '  ═══════════════════════════ !!RECONFIGURE WARNING!! ═══════════════════════════' : '',
        "  Strategies:",
        strategiesFormatted,
        "  InitLogLevel: $_initLogLevel",
        '═════════════════════════════════════════════════════════════════════════════════════',
    ].join('\n');

    developer.log(logMessage, name: 'StrategicLogger');
  }
}
