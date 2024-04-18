import 'dart:developer' as developer;

import 'package:strategic_logger/logger_extension.dart';
import 'package:strategic_logger/logger_usage.dart';

/// A [LogStrategy] implementation that logs messages, errors, and fatal errors to the console.
///
/// This strategy provides a simple way to output log information directly to the console,
/// suitable for development and troubleshooting purposes. It supports distinguishing between
/// general log messages, errors, and fatal errors, and can handle structured [LogEvent] instances
/// if provided.
///
/// Example:
/// ```dart
/// var consoleStrategy = ConsoleLogStrategy(logLevel: LogLevel.info);
/// var logger = StrategicLogger(strategies: [consoleStrategy]);
/// logger.log("A simple log message.");
/// ```
class ConsoleLogStrategy extends LogStrategy {
  /// Constructs a [ConsoleLogStrategy].
  ///
  /// [logLevel] sets the log level at which this strategy becomes active.
  /// [supportedEvents] optionally specifies which types of [LogEvent] this strategy should handle.
  ConsoleLogStrategy({super.logLevel = LogLevel.none, super.supportedEvents});

  /// Logs a message or a structured event to the console.
  ///
  /// [message] - The message or data to log if no specific event is provided.
  /// [event] - An optional [LogEvent] providing structured data for logging.
  @override
  Future<void> log({dynamic message, LogEvent? event}) async {
    try {
      if (shouldLog(event: event)) {
        developer.log(
          '>>═══════════════════════CONSOLELOG STRATEGY [LOG]═══════════════════════>>',
          name: 'ConsoleLogStrategy',
        );
        if (event != null) {
          final ConsoleLogEvent consoleEvent = event as ConsoleLogEvent;
          developer.log(
            'eventName: ${consoleEvent.eventName} eventMessage: ${consoleEvent.eventMessage ?? "No message"} message: $message',
            name: 'ConsoleLogStrategy',
          );
        } else {
          developer.log('$message', name: 'ConsoleLogStrategy');
        }
        developer.log(
          '<<═══════════════════════CONSOLELOG STRATEGY [LOG]═══════════════════════<<',
          name: 'ConsoleLogStrategy',
        );
      }
    } catch (e, stack) {
      developer.log('Error during logging in ConsoleLogStrategy: $e',
          name: 'ConsoleLogStrategy', error: e, stackTrace: stack);
    }
  }

  /// Logs an error or a structured event with an error to the console.
  ///
  /// [error] - The error to log.
  /// [stackTrace] - The stack trace associated with the error.
  /// [event] - An optional [LogEvent] providing additional context for the error.
  @override
  Future<void> error(
      {dynamic error, StackTrace? stackTrace, LogEvent? event}) async {
    try {
      if (shouldLog(event: event)) {
        developer.log(
          '>>═══════════════════════CONSOLELOG STRATEGY [ERROR]═══════════════════════>>',
          name: 'ConsoleLogStrategy',
        );
        if (event != null) {
          final ConsoleLogEvent consoleEvent = event as ConsoleLogEvent;
          developer.log(
            'eventName: ${consoleEvent.eventName} eventMessage: ${consoleEvent.eventMessage ?? "No message"} error: $error',
            name: 'ConsoleLogStrategy',
            error: error,
            stackTrace: stackTrace,
          );
        } else {
          developer.log('$error',
              name: 'ConsoleLogStrategy', error: error, stackTrace: stackTrace);
        }
        developer.log(
          '<<═══════════════════════CONSOLELOG STRATEGY [ERROR]═══════════════════════<<',
          name: 'ConsoleLogStrategy',
        );
      }
    } catch (e, stack) {
      developer.log('Error during error handling in ConsoleLogStrategy: $e',
          name: 'ConsoleLogStrategy', error: e, stackTrace: stack);
    }
  }

  /// Marks an error as fatal and records it to the console.
  ///
  /// This method treats the error as a critical failure that should be prominently flagged in the console.
  ///
  /// [error] - The critical error to log.
  /// [stackTrace] - The stack trace associated with the critical error.
  /// [event] - An optional [LogEvent] providing additional context for the critical error.
  @override
  Future<void> fatal(
      {dynamic error, StackTrace? stackTrace, LogEvent? event}) async {
    try {
      if (shouldLog(event: event)) {
        developer.log(
          '>>═══════════════════════CONSOLELOG STRATEGY [FATAL]═══════════════════════>>',
          name: 'ConsoleLogStrategy',
        );
        if (event != null) {
          final ConsoleLogEvent consoleEvent = event as ConsoleLogEvent;
          developer.log(
            'eventName: ${consoleEvent.eventName} eventMessage: ${consoleEvent.eventMessage ?? "No message"} error: $error',
            name: 'ConsoleLogStrategy',
            error: error,
            stackTrace: stackTrace,
          );
        } else {
          developer.log('$error',
              name: 'ConsoleLogStrategy', error: error, stackTrace: stackTrace);
        }
        developer.log(
          '<<═══════════════════════CONSOLELOG STRATEGY [FATAL]═══════════════════════<<',
          name: 'ConsoleLogStrategy',
        );
      }
    } catch (e, stack) {
      developer.log(
          'Fatal Error during error handling in ConsoleLogStrategy: $e',
          name: 'ConsoleLogStrategy',
          error: e,
          stackTrace: stack);
    }
  }
}
