import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';

import 'core/isolate_manager.dart';
import 'core/log_queue.dart';
import 'core/performance_monitor.dart';
import 'enums/log_level.dart';

import 'errors/alread_initialized_error.dart';
import 'errors/not_initialized_error.dart';
import 'events/log_event.dart';
import 'strategies/log_strategy.dart';

// Platform detection
import 'package:flutter/foundation.dart' show kIsWeb;

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
/// Features:
/// - Isolate-based processing for heavy operations
/// - Performance monitoring and metrics
/// - Modern console formatting with colors and emojis
/// - Compatibility with popular logger packages
/// - Async queue with backpressure control
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

  /// Determines if isolates are supported on the current platform.
  ///
  /// Returns false for web platform and true for all other platforms.
  bool _isIsolateSupported() {
    if (kIsWeb) {
      return false; // Isolates not supported on web
    }
    return true; // Isolates supported on mobile/desktop
  }

  LogLevel _initLogLevel = LogLevel.none;

  /// Current log level of the logger.
  LogLevel get level => _initLogLevel;

  List<LogStrategy> _strategies = [];

  // Modern features
  late final LogQueue _logQueue;
  bool _useIsolates = true;
  bool _enablePerformanceMonitoring = true;
  bool _enableModernConsole = true;

  /// Stream controller for real-time log updates
  final _logStreamController = StreamController<LogEntry>.broadcast();

  /// Stream of log entries for real-time console updates
  Stream<LogEntry> get logStream => _logStreamController.stream;

  /// Reconfigures the logger even if it has been previously initialized.
  ///
  /// This should be used with caution, as reconfiguring a logger that is already in use can lead to inconsistent logging behavior.
  ///
  /// [strategies] - List of new strategies to use for logging.
  /// [level] - The minimum log level to log. Defaults to [LogLevel.none].
  /// [useIsolates] - Whether to use isolates for heavy operations. Defaults to true.
  /// [enablePerformanceMonitoring] - Whether to enable performance monitoring. Defaults to true.
  /// [enableModernConsole] - Whether to enable modern console formatting. Defaults to true.
  Future<void> reconfigure({
    List<LogStrategy>? strategies,
    LogLevel level = LogLevel.none,
    bool useIsolates = true,
    bool enablePerformanceMonitoring = true,
    bool enableModernConsole = true,
  }) async {
    await logger._initialize(
      strategies: strategies,
      level: level,
      force: true,
      useIsolates: useIsolates,
      enablePerformanceMonitoring: enablePerformanceMonitoring,
      enableModernConsole: enableModernConsole,
    );
  }

  /// Configures the logger if it has not been initialized.
  ///
  /// This method should be used for the initial setup of the logger.
  ///
  /// [strategies] - List of strategies to use for logging.
  /// [level] - The minimum log level to log. Defaults to [LogLevel.none].
  /// [useIsolates] - Whether to use isolates for heavy operations. Defaults to true.
  /// [enablePerformanceMonitoring] - Whether to enable performance monitoring. Defaults to true.
  /// [enableModernConsole] - Whether to enable modern console formatting. Defaults to true.
  Future<void> initialize({
    List<LogStrategy>? strategies,
    LogLevel level = LogLevel.none,
    bool? useIsolates, // Made nullable to allow auto-detection
    bool enablePerformanceMonitoring = true,
    bool enableModernConsole = true,
  }) async {
    // Auto-detect platform support for isolates
    final shouldUseIsolates = useIsolates ?? _isIsolateSupported();

    await logger._initialize(
      strategies: strategies,
      level: level,
      useIsolates: shouldUseIsolates,
      enablePerformanceMonitoring: enablePerformanceMonitoring,
      enableModernConsole: enableModernConsole,
    );
  }

  /// Initializes or reinitializes the logger with specified strategies and log level.
  ///
  /// Throws [AlreadyInitializedError] if the logger is already initialized and [force] is not set to true.
  ///
  /// [strategies] - List of strategies to use for logging.
  /// [level] - The minimum log level to log. Defaults to [LogLevel.none].
  /// [force] - Forces reinitialization if set to true.
  /// [useIsolates] - Whether to use isolates for heavy operations.
  /// [enablePerformanceMonitoring] - Whether to enable performance monitoring.
  /// [enableModernConsole] - Whether to enable modern console formatting.
  Future<StrategicLogger> _initialize({
    List<LogStrategy>? strategies,
    LogLevel level = LogLevel.none,
    bool force = false,
    bool useIsolates = true,
    bool enablePerformanceMonitoring = true,
    bool enableModernConsole = true,
  }) async {
    if (_isInitialized && !force) {
      throw AlreadyInitializedError();
    } else {
      // Initialize modern features
      _useIsolates = useIsolates;
      _enablePerformanceMonitoring = enablePerformanceMonitoring;
      _enableModernConsole = enableModernConsole;

      // Initialize isolate manager if enabled
      if (_useIsolates) {
        await isolateManager.initialize();
      }

      // Initialize log queue
      _logQueue = LogQueue();
      _setupLogQueueListener();

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

  /// Sets up the log queue listener for processing logs
  void _setupLogQueueListener() {
    _logQueue.stream.listen((entry) async {
      await _processLogEntry(entry);
    });
  }

  /// Processes a log entry using strategies
  Future<void> _processLogEntry(LogEntry entry) async {
    // Emit to stream for real-time console updates
    _logStreamController.add(entry);

    if (_enablePerformanceMonitoring) {
      await performanceMonitor.measureOperation('processLogEntry', () async {
        for (var strategy in _strategies) {
          await _executeStrategy(strategy, entry);
        }
      });
    } else {
      for (var strategy in _strategies) {
        await _executeStrategy(strategy, entry);
      }
    }
  }

  /// Executes a strategy for a log entry
  Future<void> _executeStrategy(LogStrategy strategy, LogEntry entry) async {
    try {
      switch (entry.level) {
        case LogLevel.debug:
          await strategy.log(message: entry.message, event: entry.event);
          break;
        case LogLevel.info:
          await strategy.info(message: entry.message, event: entry.event);
          break;
        case LogLevel.warning:
          await strategy.log(message: entry.message, event: entry.event);
          break;
        case LogLevel.error:
          await strategy.error(
            error: entry.message,
            stackTrace: entry.stackTrace,
            event: entry.event,
          );
          break;
        case LogLevel.fatal:
          await strategy.fatal(
            error: entry.message,
            stackTrace: entry.stackTrace,
            event: entry.event,
          );
          break;
        case LogLevel.none:
          // Do nothing
          break;
      }
    } catch (e, stackTrace) {
      // Log strategy execution error
      developer.log(
        'Error executing strategy ${strategy.runtimeType}: $e',
        name: 'StrategicLogger',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Logs a message or event using the configured strategies.
  ///
  /// Throws [NotInitializedError] if the logger has not been initialized.
  ///
  /// [message] - The message to log.
  /// [event] - Optional. The specific log event associated with the message.
  /// [context] - Optional. Additional context data.
  Future<void> log(
    dynamic message, {
    LogEvent? event,
    Map<String, Object>? context,
  }) async {
    if (!_isInitialized) {
      throw NotInitializedError();
    }

    final entry = LogEntry.fromParams(
      message: message,
      level: LogLevel.info,
      event: event,
      context: context,
    );

    _logQueue.enqueue(entry);
  }

  /// Logs a message or event using the configured strategies.
  ///
  /// Throws [NotInitializedError] if the logger has not been initialized.
  ///
  /// [message] - The message to log.
  /// [event] - Optional. The specific log event associated with the message.
  /// [context] - Optional. Additional context data.
  Future<void> info(
    dynamic message, {
    LogEvent? event,
    Map<String, Object>? context,
  }) async {
    if (!_isInitialized) {
      throw NotInitializedError();
    }

    final entry = LogEntry.fromParams(
      message: message,
      level: LogLevel.info,
      event: event,
      context: context,
    );

    _logQueue.enqueue(entry);
  }

  /// Logs an error using the configured strategies.
  ///
  /// Throws [NotInitializedError] if the logger has not been initialized.
  ///
  /// [error] - The error object to log.
  /// [stackTrace] - The stack trace associated with the error.
  /// [event] - Optional. The specific log event associated with the error.
  /// [context] - Optional. Additional context data.
  Future<void> error(
    dynamic error, {
    StackTrace? stackTrace,
    LogEvent? event,
    Map<String, Object>? context,
  }) async {
    if (!_isInitialized) {
      throw NotInitializedError();
    }

    final entry = LogEntry.fromParams(
      message: error,
      level: LogLevel.error,
      event: event,
      context: context,
      stackTrace: stackTrace,
    );

    _logQueue.enqueue(entry);
  }

  /// Logs a fatal error using the configured strategies.
  ///
  /// Throws [NotInitializedError] if the logger has not been initialized.
  ///
  /// [error] - The critical error object to log as fatal.
  /// [stackTrace] - The stack trace associated with the fatal error.
  /// [event] - Optional. The specific log event associated with the fatal error.
  /// [context] - Optional. Additional context data.
  Future<void> fatal(
    dynamic error, {
    StackTrace? stackTrace,
    LogEvent? event,
    Map<String, Object>? context,
  }) async {
    if (!_isInitialized) {
      throw NotInitializedError();
    }

    final entry = LogEntry.fromParams(
      message: error,
      level: LogLevel.fatal,
      event: event,
      context: context,
      stackTrace: stackTrace,
    );

    _logQueue.enqueue(entry);
  }

  /// Synchronous debug logging (compatibility with popular logger packages)
  void debugSync(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    if (!_isInitialized) return;

    final entry = LogEntry.fromParams(
      message: message,
      level: LogLevel.debug,
      stackTrace: stackTrace,
    );

    _logQueue.enqueue(entry);
  }

  /// Synchronous info logging (compatibility with popular logger packages)
  void infoSync(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    if (!_isInitialized) return;

    final entry = LogEntry.fromParams(
      message: message,
      level: LogLevel.info,
      stackTrace: stackTrace,
    );

    _logQueue.enqueue(entry);
  }

  /// Synchronous warning logging (compatibility with popular logger packages)
  void warningSync(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    if (!_isInitialized) return;

    final entry = LogEntry.fromParams(
      message: message,
      level: LogLevel.warning,
      stackTrace: stackTrace,
    );

    _logQueue.enqueue(entry);
  }

  /// Synchronous error logging (compatibility with popular logger packages)
  void errorSync(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    if (!_isInitialized) return;

    final entry = LogEntry.fromParams(
      message: message,
      level: LogLevel.error,
      stackTrace: stackTrace,
    );

    _logQueue.enqueue(entry);
  }

  /// Synchronous fatal logging (compatibility with popular logger packages)
  void fatalSync(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    if (!_isInitialized) return;

    final entry = LogEntry.fromParams(
      message: message,
      level: LogLevel.fatal,
      stackTrace: stackTrace,
    );

    _logQueue.enqueue(entry);
  }

  /// Synchronous verbose logging (alias for debug)
  void verboseSync(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    debugSync(message, error, stackTrace);
  }

  /// Synchronous log method (alias for info)
  void logSync(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    infoSync(message, error, stackTrace);
  }

  /// Logs a message with structured data
  Future<void> logStructured(
    LogLevel level,
    dynamic message, {
    Map<String, Object>? data,
    String? tag,
    DateTime? timestamp,
  }) async {
    if (!_isInitialized) {
      throw NotInitializedError();
    }

    final event = LogEvent(
      eventName: tag ?? 'LOG',
      eventMessage: message.toString(),
      parameters: data,
    );

    final entry = LogEntry.fromParams(
      message: message,
      level: level,
      event: event,
    );

    _logQueue.enqueue(entry);
  }

  /// Adds debug level logging
  Future<void> debug(
    dynamic message, {
    LogEvent? event,
    Map<String, Object>? context,
  }) async {
    if (!_isInitialized) {
      throw NotInitializedError();
    }

    final entry = LogEntry.fromParams(
      message: message,
      level: LogLevel.debug,
      event: event,
      context: context,
    );

    _logQueue.enqueue(entry);
  }

  /// Adds warning level logging
  Future<void> warning(
    dynamic message, {
    LogEvent? event,
    Map<String, Object>? context,
  }) async {
    if (!_isInitialized) {
      throw NotInitializedError();
    }

    final entry = LogEntry.fromParams(
      message: message,
      level: LogLevel.warning,
      event: event,
      context: context,
    );

    _logQueue.enqueue(entry);
  }

  /// Adds verbose level logging (alias for debug)
  Future<void> verbose(
    dynamic message, {
    LogEvent? event,
    Map<String, Object>? context,
  }) async {
    await debug(message, event: event, context: context);
  }

  /// Forces flush of all queued logs
  void flush() {
    _logQueue.flush();
  }

  /// Gets performance statistics
  Map<String, dynamic> getPerformanceStats() {
    return performanceMonitor.getAllStats().map(
      (key, value) => MapEntry(key, value.toString()),
    );
  }

  /// Disposes the logger and cleans up resources
  void dispose() {
    _logQueue.dispose();
    if (_useIsolates) {
      isolateManager.dispose();
    }
    performanceMonitor.dispose();
    _logStreamController.close();
    _isInitialized = false;
  }

  /// Prints initialization details of the logger, including whether it was a reconfiguration.
  void _printStrategicLoggerInit() {
    final appName = _getAppName();

    // ASCII Art Banner
    final asciiArt = _generateAsciiArt(appName);

    String strategiesFormatted = _strategies
        .map((s) => '[HYPN-TECH]     └─ ${s.toString()}')
        .join('\n');

    String logMessage = [
      asciiArt,
      '',
      '[HYPN-TECH] 🚀 STRATEGIC LOGGER CONFIGURATION',
      '[HYPN-TECH] ✅ Logger initialized successfully!',
      '[HYPN-TECH] 📋 CONFIGURATION:',
      '[HYPN-TECH]     • Log Level: $_initLogLevel',
      '[HYPN-TECH]     • Use Isolates: $_useIsolates',
      '[HYPN-TECH]     • Performance Monitoring: $_enablePerformanceMonitoring',
      '[HYPN-TECH]     • Modern Console: $_enableModernConsole',
      '[HYPN-TECH] 🎯 ACTIVE STRATEGIES:',
      strategiesFormatted,
      '[HYPN-TECH] 🌐 Platform: ${_isIsolateSupported() ? '✅ Isolates Supported' : '❌ Isolates Not Supported'}',
      '[HYPN-TECH] 📱 App: $appName',
    ].join('\n');

    // Log to console (terminal)
    print(logMessage);

    // Also log to DevTools
    developer.log(logMessage, name: 'StrategicLogger');

    // Also emit to stream for Live Console
    final initLogEntry = LogEntry(
      level: LogLevel.info,
      message: logMessage,
      timestamp: DateTime.now(),
    );
    _logStreamController.add(initLogEntry);
  }

  /// Generates ASCII art banner for the logger initialization
  String _generateAsciiArt(String appName) {
    final version = _getPackageVersion();
    return '''
███████████████████████████████████████████████████████████████████
█          ___ _____ ___    _ _____ ___ ___ ___ ___               █
█         / __|_   _| _ \\  /_\\_   _| __/ __|_ _/ __|              █
█         \\__ \\ | | |   / / _ \\| | | _| (_ || | (__               █
█         |___/ |_| |_|_\\/_/ \\_\\_| |___\\___|___\\___|              █
█            / /   / __ \\/ ____/ ____/ ____/ __ \\                 █
█           / /   / / / / / __/ / __/ __/ / /_/ /                 █
█          / /___/ /_/ / /_/ / /_/ / /___/ _, _/                  █
█         /_____/\\____/\\____/\\____/_____/_/ |_| v$version            █
█                                                                 █
█                    🚀 Powered by Hypn Tech                      █
█                            (hypn.com.br)                        █
███████████████████████████████████████████████████████████████████''';
  }

  /// Gets the package version from pubspec.yaml
  String _getPackageVersion() {
    try {
      // Try to read from pubspec.yaml
      final pubspecFile = File('pubspec.yaml');
      if (pubspecFile.existsSync()) {
        final content = pubspecFile.readAsStringSync();
        final versionMatch = RegExp(
          r'^version:\s*(.+)$',
          multiLine: true,
        ).firstMatch(content);
        if (versionMatch != null) {
          return versionMatch.group(1)?.trim() ?? '1.0.0';
        }
      }
    } catch (e) {
      // Fallback if file reading fails
    }
    return '1.2.1'; // Fallback version
  }

  /// Gets the application name from various sources
  String _getAppName() {
    try {
      // Try to get app name from Flutter
      if (!kIsWeb) {
        // For mobile/desktop, we can try to get package name
        return 'Flutter App';
      } else {
        // For web, try to get from document title
        return 'Web App';
      }
    } catch (e) {
      return 'Unknown App';
    }
  }
}
