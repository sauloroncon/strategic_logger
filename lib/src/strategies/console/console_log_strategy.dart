import 'dart:developer' as developer;

import '../../console/modern_console_formatter.dart';
import '../../core/isolate_manager.dart';
import '../../enums/log_level.dart';
import '../../events/log_event.dart';
import '../log_strategy.dart';

/// A [LogStrategy] implementation that logs messages, errors, and fatal errors to the console.
///
/// This strategy provides a modern way to output log information directly to the console,
/// suitable for development and troubleshooting purposes. It supports distinguishing between
/// general log messages, errors, and fatal errors, and can handle structured [LogEvent] instances
/// if provided.
///
/// Features:
/// - Modern console formatting with colors and emojis
/// - Isolate-based processing for heavy operations
/// - Performance monitoring
/// - Structured output with context and events
///
/// Example:
/// ```dart
/// var consoleStrategy = ConsoleLogStrategy(logLevel: LogLevel.info);
/// var logger = StrategicLogger(strategies: [consoleStrategy]);
/// logger.log("A simple log message.");
/// ```
class ConsoleLogStrategy extends LogStrategy {
  final bool _useModernFormatting;
  final bool _useColors;
  final bool _useEmojis;
  final bool _showTimestamp;
  final bool _showContext;

  /// Constructs a [ConsoleLogStrategy].
  ///
  /// [logLevel] sets the log level at which this strategy becomes active.
  /// [supportedEvents] optionally specifies which types of [LogEvent] this strategy should handle.
  /// [useModernFormatting] enables modern console formatting with colors and emojis.
  /// [useColors] enables colored output.
  /// [useEmojis] enables emoji indicators for log levels.
  /// [showTimestamp] shows timestamp in logs.
  /// [showContext] shows context information in logs.
  ConsoleLogStrategy({
    super.logLevel = LogLevel.none,
    super.supportedEvents,
    bool useModernFormatting = true,
    bool useColors = true,
    bool useEmojis = true,
    bool showTimestamp = true,
    bool showContext = true,
  }) : _useModernFormatting = useModernFormatting,
       _useColors = useColors,
       _useEmojis = useEmojis,
       _showTimestamp = showTimestamp,
       _showContext = showContext;

  /// Logs a message or a structured event to the console.
  ///
  /// [message] - The message or data to log if no specific event is provided.
  /// [event] - An optional [LogEvent] providing structured data for logging.
  @override
  Future<void> log({dynamic message, LogEvent? event}) async {
    // For the generic log method, we need to determine the level from context
    // Since we can't know the intended level, we'll use info as default
    await _logMessage(LogLevel.info, message, event: event);
  }

  /// Internal method to log with a specific level
  Future<void> logWithLevel(LogLevel level, {dynamic message, LogEvent? event}) async {
    await _logMessage(level, message, event: event);
  }

  /// Logs a message or a structured event to the console.
  ///
  /// [message] - The message or data to log if no specific event is provided.
  /// [event] - An optional [LogEvent] providing structured data for logging.
  @override
  Future<void> info({dynamic message, LogEvent? event}) async {
    await _logMessage(LogLevel.info, message, event: event);
  }

  /// Logs an error or a structured event with an error to the console.
  ///
  /// [error] - The error to log.
  /// [stackTrace] - The stack trace associated with the error.
  /// [event] - An optional [LogEvent] providing additional context for the error.
  @override
  Future<void> error({
    dynamic error,
    StackTrace? stackTrace,
    LogEvent? event,
  }) async {
    await _logMessage(
      LogLevel.error,
      error,
      event: event,
      stackTrace: stackTrace,
    );
  }

  /// Marks an error as fatal and records it to the console.
  ///
  /// This method treats the error as a critical failure that should be prominently flagged in the console.
  ///
  /// [error] - The critical error to log.
  /// [stackTrace] - The stack trace associated with the critical error.
  /// [event] - An optional [LogEvent] providing additional context for the critical error.
  @override
  Future<void> fatal({
    dynamic error,
    StackTrace? stackTrace,
    LogEvent? event,
  }) async {
    await _logMessage(
      LogLevel.fatal,
      error,
      event: event,
      stackTrace: stackTrace,
    );
  }

  /// Internal method to log messages with modern formatting
  Future<void> _logMessage(
    LogLevel level,
    dynamic message, {
    LogEvent? event,
    StackTrace? stackTrace,
  }) async {
    try {
      if (!shouldLog(event: event)) return;

      String formattedMessage;

      if (_useModernFormatting) {
        // Use isolate for heavy formatting if available
        try {
          final formatted = await isolateManager.formatLog(
            message: message.toString(),
            level: level.name,
            timestamp: DateTime.now(),
            context: event?.parameters,
          );
          formattedMessage = formatted['formatted'] as String;
        } catch (e) {
          // Fallback to direct formatting
          // Disable emojis since we're using the formatted header
          formattedMessage = modernConsoleFormatter.formatLog(
            level: level,
            message: message.toString(),
            timestamp: DateTime.now(),
            event: event,
            stackTrace: stackTrace,
            useColors: _useColors,
            useEmojis: false, // Disabled because we have formatted header
            showTimestamp: _showTimestamp,
            showContext: _showContext,
          );
        }
      } else {
        // Legacy formatting
        formattedMessage = _formatLegacyMessage(
          level,
          message,
          event,
          stackTrace,
        );
      }

      // Add HYPN-TECH header to all logs with visual formatting
      final finalMessage = _formatLogHeader(level, formattedMessage);

      // Output to console (terminal)
      print(finalMessage);

      // Also log to developer console (DevTools)
      developer.log(
        finalMessage,
        name: 'ConsoleLogStrategy',
        error: level == LogLevel.error || level == LogLevel.fatal
            ? message
            : null,
        stackTrace: stackTrace,
      );
    } catch (e, stack) {
      developer.log(
        'Error during logging in ConsoleLogStrategy: $e',
        name: 'ConsoleLogStrategy',
        error: e,
        stackTrace: stack,
      );
    }
  }

  /// Formats the log header with visual styling and colors
  String _formatLogHeader(LogLevel level, String message) {
    if (!_useColors) {
      // Fallback to simple format without colors
      return '[HYPN-TECH][STRATEGIC-LOGGER][${level.name.toUpperCase()}] $message';
    }

    // ANSI color codes
    const String reset = '\x1B[0m';
    const String bold = '\x1B[1m';
    const String dim = '\x1B[2m';
    
    // HYPN-TECH colors (teal/cyan theme)
    const String hypnTechColor = '\x1B[36m'; // Cyan
    const String hypnTechBg = '\x1B[46m'; // Cyan background
    const String hypnTechText = '\x1B[30m'; // Black text on cyan background
    
    // STRATEGIC-LOGGER colors (blue theme)
    const String strategicLoggerColor = '\x1B[34m'; // Blue
    const String strategicLoggerBg = '\x1B[44m'; // Blue background
    const String strategicLoggerText = '\x1B[37m'; // White text on blue background
    
    // Level colors
    String levelColor;
    String levelBg;
    String levelText;
    
    switch (level) {
      case LogLevel.debug:
        levelColor = '\x1B[35m'; // Magenta
        levelBg = '\x1B[45m'; // Magenta background
        levelText = '\x1B[37m'; // White text
        break;
      case LogLevel.info:
        levelColor = '\x1B[32m'; // Green
        levelBg = '\x1B[42m'; // Green background
        levelText = '\x1B[30m'; // Black text
        break;
      case LogLevel.warning:
        levelColor = '\x1B[33m'; // Yellow
        levelBg = '\x1B[43m'; // Yellow background
        levelText = '\x1B[30m'; // Black text
        break;
      case LogLevel.error:
        levelColor = '\x1B[31m'; // Red
        levelBg = '\x1B[41m'; // Red background
        levelText = '\x1B[37m'; // White text
        break;
      case LogLevel.fatal:
        levelColor = '\x1B[91m'; // Bright red
        levelBg = '\x1B[101m'; // Bright red background
        levelText = '\x1B[37m'; // White text
        break;
      case LogLevel.none:
        levelColor = '\x1B[37m'; // White
        levelBg = '\x1B[47m'; // White background
        levelText = '\x1B[30m'; // Black text
        break;
    }

    // Format the header with visual styling
    final String hypnTechPart = '$hypnTechBg$hypnTechText$bold HYPN-TECH $reset';
    final String strategicLoggerPart = '$strategicLoggerBg$strategicLoggerText$bold STRATEGIC-LOGGER $reset';
    final String levelPart = '$levelBg$levelText$bold ${level.name.toUpperCase()} $reset';
    
    return '$hypnTechPart$strategicLoggerPart$levelPart$message';
  }

  /// Legacy message formatting for backward compatibility
  String _formatLegacyMessage(
    LogLevel level,
    dynamic message,
    LogEvent? event,
    StackTrace? stackTrace,
  ) {
    final buffer = StringBuffer();

    if (event != null) {
      buffer.write(
        'eventName: ${event.eventName} eventMessage: ${event.eventMessage ?? "No message"} message: $message',
      );
    } else {
      buffer.write('$message');
    }

    if (stackTrace != null) {
      buffer.write(' Stack Trace: $stackTrace');
    }

    return buffer.toString();
  }
}
