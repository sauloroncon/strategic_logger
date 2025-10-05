import 'dart:developer' as developer;
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:strategic_logger/logger_extension.dart';
import 'package:strategic_logger/src/strategies/sentry/sentry_log_event.dart';

/// A [LogStrategy] implementation that logs messages and errors to Sentry.
///
/// This strategy provides the functionality to send log messages and detailed error reports,
/// including stack traces, to Sentry. It can be configured with a specific log level
/// and can handle both general log messages and structured [LogEvent] instances tailored for Sentry.
///
/// The strategy distinguishes between general messages, errors, and fatal errors, ensuring that each
/// type of log is appropriately reported to Sentry.
///
/// Example:
/// ```dart
/// var sentryStrategy = SentryLogStrategy(
///   logLevel: LogLevel.error,
/// );
/// var logger = StrategicLogger(strategies: [sentryStrategy]);
/// logger.error('Example error', stackTrace: StackTrace.current);
/// ```
class SentryLogStrategy extends LogStrategy {
  /// Constructs a [SentryLogStrategy].
  ///
  /// [logLevel] sets the log level at which this strategy becomes active.
  /// [supportedEvents] optionally specifies which types of [LogEvent] this strategy should handle.
  SentryLogStrategy({super.logLevel = LogLevel.none, super.supportedEvents});

  /// Logs a message or a structured event to Sentry.
  ///
  /// If an event is provided, the log will include structured data tailored for Sentry.
  /// Otherwise, it logs a general message.
  ///
  /// [message] - a general message to log if no event is provided.
  /// [event] - an optional [LogEvent] providing structured data for logging.
  @override
  Future<void> log({dynamic message, LogEvent? event}) async {
    try {
      if (shouldLog(event: event)) {
        developer.log('Logging to Sentry', name: 'SentryLogStrategy');
        if (event != null && event is SentryLogEvent) {
          Sentry.captureMessage('${event.eventName}: ${event.eventMessage}');
        } else {
          Sentry.captureMessage('Message: $message');
        }
      }
    } catch (e, stack) {
      developer.log(
        'Error during logging in Sentry Strategy',
        name: 'SentryLogStrategy',
        error: e,
        stackTrace: stack,
      );
    }
  }

  /// Logs a message or a structured event to Sentry.
  ///
  /// If an event is provided, the log will include structured data tailored for Sentry.
  /// Otherwise, it logs a general message.
  ///
  /// [message] - a general message to log if no event is provided.
  /// [event] - an optional [LogEvent] providing structured data for logging.
  @override
  Future<void> info({dynamic message, LogEvent? event}) async {
    try {
      log(message: message, event: event);
    } catch (e, stack) {
      developer.log(
        'Error during logging in Sentry Strategy',
        name: 'SentryLogStrategy',
        error: e,
        stackTrace: stack,
      );
    }
  }

  /// Records an error or a structured event with an error to Sentry.
  ///
  /// Errors are logged with their associated stack traces. If an event is provided,
  /// additional context is included in the report.
  ///
  /// [error] - the error to log.
  /// [stackTrace] - the stack trace associated with the error.
  /// [event] - an optional [LogEvent] providing additional context for the error.
  @override
  Future<void> error({
    dynamic error,
    StackTrace? stackTrace,
    LogEvent? event,
  }) async {
    try {
      if (shouldLog(event: event)) {
        developer.log('Reporting error to Sentry', name: 'SentryLogStrategy');
        if (event != null) {
          Sentry.captureException(error, stackTrace: stackTrace);
        }
      }
    } catch (e, stack) {
      developer.log(
        'Error during error handling in Sentry Strategy',
        name: 'SentryLogStrategy',
        error: e,
        stackTrace: stack,
      );
    }
  }

  /// Marks an error as fatal and records it to Sentry.
  ///
  /// Fatal errors are treated as critical failures that should be prominently flagged in Sentry.
  /// Additional context can be provided through a [LogEvent].
  ///
  /// [error] - the critical error to log.
  /// [stackTrace] - the stack trace associated with the critical error.
  /// [event] - an optional [LogEvent] providing additional context for the critical error.
  @override
  Future<void> fatal({
    dynamic error,
    StackTrace? stackTrace,
    LogEvent? event,
  }) async {
    try {
      if (shouldLog(event: event)) {
        developer.log(
          'Recording fatal error to Sentry',
          name: 'SentryLogStrategy',
        );
        if (event != null) {
          Sentry.captureException(error, stackTrace: stackTrace);
        }
      }
    } catch (e, stack) {
      developer.log(
        'Error during fatal error handling in Sentry Strategy',
        name: 'SentryLogStrategy',
        error: e,
        stackTrace: stack,
      );
    }
  }
}
