import 'dart:developer' as developer;
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:strategic_logger/logger_extension.dart';

import 'firebase_crashlytics_log_event.dart';

/// A [LogStrategy] implementation that logs messages and errors to Firebase Crashlytics.
///
/// This strategy provides the functionality to send log messages and detailed error reports,
/// including stack traces, to Firebase Crashlytics. It can be configured with a specific log level
/// and can handle both general log messages and structured [LogEvent] instances tailored for Crashlytics.
///
/// The strategy distinguishes between general messages, errors, and fatal errors, ensuring that each
/// type of log is appropriately reported to Firebase Crashlytics.
///
/// Example:
/// ```dart
/// var crashlyticsStrategy = FirebaseCrashlyticsLogStrategy(
///   logLevel: LogLevel.error,
/// );
/// var logger = StrategicLogger(strategies: [crashlyticsStrategy]);
/// logger.error('Example error', stackTrace: StackTrace.current);
/// ```
class FirebaseCrashlyticsLogStrategy extends LogStrategy {
  /// Constructs a [FirebaseCrashlyticsLogStrategy].
  ///
  /// [logLevel] sets the log level at which this strategy becomes active.
  /// [supportedEvents] optionally specifies which types of [LogEvent] this strategy should handle.
  FirebaseCrashlyticsLogStrategy({
    super.logLevel = LogLevel.none,
    super.supportedEvents,
  });

  /// Logs a message or a structured event to Firebase Crashlytics.
  ///
  /// If an event is provided, the log will include structured data tailored for Firebase Crashlytics.
  /// Otherwise, it logs a general message.
  ///
  /// [message] - a general message to log if no event is provided.
  /// [event] - an optional [LogEvent] providing structured data for logging.
  @override
  Future<void> log({dynamic message, LogEvent? event}) async {
    try {
      if (shouldLog(event: event)) {
        developer.log(
          'Logging to Firebase Crashlytics',
          name: 'FirebaseCrashlyticsLogStrategy',
        );
        if (event != null) {
          if (event is FirebaseCrashlyticsLogEvent) {
            FirebaseCrashlytics.instance
                .log('${event.eventName}: ${event.eventMessage}');
          }
        } else {
          FirebaseCrashlytics.instance.log('Message: $message');
        }
      }
    } catch (e, stack) {
      developer.log(
        'Error during logging in Firebase Crashlytics Strategy',
        name: 'FirebaseCrashlyticsLogStrategy',
        error: e,
        stackTrace: stack,
      );
    }
  }

  /// Logs a message or a structured event to Firebase Crashlytics.
  ///
  /// If an event is provided, the log will include structured data tailored for Firebase Crashlytics.
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
        'Error during logging in Firebase Crashlytics Strategy',
        name: 'FirebaseCrashlyticsLogStrategy',
        error: e,
        stackTrace: stack,
      );
    }
  }

  /// Records an error or a structured event with an error to Firebase Crashlytics.
  ///
  /// Errors are logged with their associated stack traces. If an event is provided,
  /// additional context is included in the report.
  ///
  /// [error] - the error to log.
  /// [stackTrace] - the stack trace associated with the error.
  /// [event] - an optional [LogEvent] providing additional context for the error.
  @override
  Future<void> error(
      {dynamic error, StackTrace? stackTrace, LogEvent? event}) async {
    try {
      if (shouldLog(event: event)) {
        developer.log(
          'Reporting error to Firebase Crashlytics',
          name: 'FirebaseCrashlyticsLogStrategy',
        );
        if (event != null && event is FirebaseCrashlyticsLogEvent) {
          FirebaseCrashlytics.instance
              .recordError(error, stackTrace, reason: event.eventMessage);
        } else {
          FirebaseCrashlytics.instance.recordError(error, stackTrace);
        }
      }
    } catch (e, stack) {
      developer.log(
        'Error during error handling in Firebase Crashlytics Strategy',
        name: 'FirebaseCrashlyticsLogStrategy',
        error: e,
        stackTrace: stack,
      );
    }
  }

  /// Marks an error as fatal and records it to Firebase Crashlytics.
  ///
  /// Fatal errors are treated as critical failures that should be prominently flagged in Crashlytics.
  /// Additional context can be provided through a [LogEvent].
  ///
  /// [error] - the critical error to log.
  /// [stackTrace] - the stack trace associated with the critical error.
  /// [event] - an optional [LogEvent] providing additional context for the critical error.
  @override
  Future<void> fatal(
      {dynamic error, StackTrace? stackTrace, LogEvent? event}) async {
    try {
      if (shouldLog(event: event)) {
        developer.log(
          'Recording fatal error to Firebase Crashlytics',
          name: 'FirebaseCrashlyticsLogStrategy',
        );
        if (event != null && event is FirebaseCrashlyticsLogEvent) {
          FirebaseCrashlytics.instance.recordError(error, stackTrace,
              reason: event.eventMessage, fatal: true);
        } else {
          FirebaseCrashlytics.instance
              .recordError(error, stackTrace, fatal: true);
        }
      }
    } catch (e, stack) {
      developer.log(
        'Error during fatal error handling in Firebase Crashlytics Strategy',
        name: 'FirebaseCrashlyticsLogStrategy',
        error: e,
        stackTrace: stack,
      );
    }
  }
}
