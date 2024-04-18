import 'package:strategic_logger/logger.dart';
import 'package:strategic_logger/src/strategies/analytics/firebase_analytics_log_event.dart';
import 'package:strategic_logger/src/strategies/analytics/firebase_analytics_log_strategy.dart';
import 'package:strategic_logger/src/strategies/crashlytics/firebase_crashlytics_log_event.dart';
import 'package:strategic_logger/src/strategies/crashlytics/firebase_crashlytics_log_strategy.dart';
import 'package:test/test.dart';

/// Test suite for the Strategic Logger to ensure correct functionality across various scenarios.
///
/// The tests cover:
/// - Initialization and reconfiguration of the logger to verify that the logger correctly handles setup and changes in configuration.
/// - Logging functionality to confirm that logs are processed correctly based on the configured log level and strategies.
/// - Event-specific logging to test the handling of logs by specific strategies and ensure logs are correctly routed based on event types.
void main() {
  group('Logger Initialization and Configuration', () {
    /// Tests that the logger initializes with specified settings without throwing an error.
    test('Logger should initialize with specified log level and strategies',
        () {
      expect(
          () => logger.initialize(
                level: LogLevel.error,
                strategies: [ConsoleLogStrategy()],
              ),
          returnsNormally);
    });

    /// Tests that the logger throws an error when an attempt is made to reinitialize it without reconfiguring.
    test(
        'Logger should throw an error when reinitialized without reconfiguration',
        () {
      expect(
          () => logger.initialize(
                level: LogLevel.info,
                strategies: [ConsoleLogStrategy()],
              ),
          throwsA(isA<AlreadyInitializedError>()));
    });

    /// Tests that the logger allows reconfiguration and applies new settings correctly.
    test('Logger should allow reconfiguration with new settings', () {
      expect(
          () => logger.reconfigure(
                level: LogLevel.debug,
                strategies: [
                  FirebaseCrashlyticsLogStrategy(),
                  FirebaseAnalyticsLogStrategy()
                ],
              ),
          returnsNormally);
    });
  });

  group('Logging Functionality', () {
    /// Tests that the logger logs messages that meet or exceed the configured log level.
    test('Logger should log messages at or above the configured log level', () {
      logger.log('This is an info level log',
          event: LogEvent(eventName: 'INFO_EVENT'));
      // Implement mock to verify log output
    });

    /// Tests that the logger does not log messages below the configured log level.
    test('Logger should not log messages below the configured log level', () {
      logger.log('This is a debug level log',
          event: LogEvent(eventName: 'DEBUG_EVENT'));
      // Implement mock to verify absence of log output
    });

    /// Tests that the logger correctly processes error logs.
    test('Logger should correctly handle error logs', () {
      logger.error('This is an error',
          event: FirebaseCrashlyticsLogEvent(eventName: 'ERROR_EVENT'));
      // Check that the error log is processed as expected
    });

    /// Tests that the logger correctly processes fatal logs.
    test('Logger should correctly handle fatal logs', () {
      logger.fatal('This is a fatal error',
          event: FirebaseAnalyticsLogEvent(eventName: 'FATAL_ERROR_EVENT'));
      // Check that the fatal log is processed as expected
    });
  });

  group('Event Specific Logging', () {
    /// Tests that the logger correctly processes events intended for console logging.
    test(
        'Logger should log with ConsoleLogStrategy for a console-specific event',
        () {
      logger.log('Console specific event log',
          event: ConsoleLogEvent(eventName: 'CONSOLE_EVENT'));
      // Verify that the ConsoleLogStrategy handled the log
    });

    /// Tests that the logger correctly processes events intended for Firebase Analytics.
    test(
        'Logger should log with FirebaseAnalyticsLogStrategy for an analytics-specific event',
        () {
      logger.log('Analytics specific event log',
          event: FirebaseAnalyticsLogEvent(eventName: 'ANALYTICS_EVENT'));
      // Verify that the FirebaseAnalyticsLogStrategy handled the log
    });

    /// Tests that the logger handles logs that are relevant to multiple strategies.
    test('Logger should handle multiple strategies for a generic event', () {
      logger.log('Generic event affecting multiple strategies',
          event: LogEvent(eventName: 'GENERIC_EVENT'));
      // Verify that all configured strategies handled the log
    });
  });
}
