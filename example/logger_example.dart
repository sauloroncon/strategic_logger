import 'package:strategic_logger/logger_usage.dart';

/// Example demonstrating the initialization, configuration, and usage of Strategic Logger with multiple log strategies.
///
/// This example initializes a logger with various strategies, including console logging,
/// Firebase Crashlytics, and Firebase Analytics. It shows how to log simple messages,
/// structured events, and handle reconfiguration of the logger based on environmental
/// changes or specific application needs.
///
/// The logger is initialized with a default log level and strategies, which can be reconfigured
/// as needed. The example also demonstrates how to log different types of events including
/// errors and purchases, which can be useful for tracking application usage and issues.
void main() {
  // Initialize the logger once with its strategies and log level.
  logger.initialize(
    level: LogLevel
        .error, // Define from which log level the logger will be triggered.
    strategies: [
      // Register the log strategies that the logger will call. Some strategies are already implemented for convenience.
      ConsoleLogStrategy(), // ConsoleLogStrategy uses the developer.log package.
      // Other strategies can be implemented by extending LogStrategy and registered here.
    ],
  );

  logger.log(
      'logging'); // Calls the log method of ConsoleLogStrategy() with just the message.
  logger.error(
      'error'); // Calls the error method of ConsoleLogStrategy() with just the error.
  logger.fatal(
      'fatal error'); // Calls the fatal log of ConsoleLogStrategy() with just the fatal error.

  // Reconfiguration of the logger after initialization is not recommended without a strong reason.
  logger.reconfigure(
    // Example: If you need to reconfigure the logger strategies or update the logLevel after loading environment variables and strategy dependencies, you can reconfigure, but not before using the logger.
    level: LogLevel
        .error, // Define from which log level the logger will be triggered.
    strategies: [
      // Register the log strategies that the logger will call. Some strategies are already implemented for convenience.
      ConsoleLogStrategy(), // ConsoleLogStrategy uses the developer.log package.
      FirebaseCrashlyticsLogStrategy(), // FirebaseCrashlyticsLogStrategy logs errors to Crashlytics (This strategy will use your environment configuration).
      FirebaseAnalyticsLogStrategy(), // FirebaseAnalyticsLogStrategy logs events to Firebase Analytics (This strategy will use your environment configuration).
      // Other strategies can be implemented by extending LogStrategy and registered here.
    ],
  );

  logger.log(
      'logging'); // Calls the log method of ConsoleLogStrategy(), FirebaseCrashlyticsLogStrategy(), FirebaseAnalyticsLogStrategy() with just the message.
  logger.error(
      'error'); // Calls the error method of ConsoleLogStrategy(), FirebaseCrashlyticsLogStrategy(), FirebaseAnalyticsLogStrategy() with just the error.
  logger.fatal(
      'fatal error'); // Calls the fatal log of ConsoleLogStrategy(), FirebaseCrashlyticsLogStrategy(), FirebaseAnalyticsLogStrategy() with just the fatal error.

  // To send more structured logs, we can send a LogEvent (all strategies will be called).
  logger.log(
    'purchase completed',
    event: LogEvent(
        eventName: 'PURCHASE_COMPLETED',
        parameters: {'key': 'value', 'key2': 'value'}),
  );

  // To register a specific event of a strategy, we can specialize the event (only Console Log will be called).
  logger.log(
    'purchase completed',
    event: ConsoleLogEvent(
        eventName: 'PURCHASE_COMPLETED',
        parameters: {'key': 'value', 'key2': 'value'}),
  );

  // To register a specific event of a strategy, we can specialize the event (only Firebase Analytics will be called).
  logger.log(
    'purchase completed',
    event: FirebaseAnalyticsLogEvent(
        eventName: 'PURCHASE_COMPLETED',
        parameters: {'key': 'value', 'key2': 'value'}),
  );

  // To register a specific event of a strategy, we can specialize the event (only Firebase Crashlytics will be called).
  logger.error(
    'non-fatal error',
    event: FirebaseCrashlyticsLogEvent(
        eventName: 'ERROR', parameters: {'key': 'value', 'key2': 'value'}),
  );
  logger.fatal(
    'fatal error',
    event: FirebaseAnalyticsLogEvent(
        eventName: 'FATAL_ERROR',
        parameters: {'key': 'value', 'key2': 'value'}),
  );

  // During logger initialization and reconfiguration, we can restrict the events that will be allowed to be logged in each strategy.
  logger.reconfigure(
    // Example: If you need to reconfigure the logger strategies or update the logLevel after loading environment variables and strategy dependencies, you can reconfigure, but not before using the logger.
    level: LogLevel
        .error, // Define from which log level the logger will be triggered.
    strategies: [
      // Register the log strategies that the logger will call. Some strategies are already implemented for convenience.
      ConsoleLogStrategy(supportedEvents: [
        ConsoleLogEvent(eventName: 'Event-A'),
        ConsoleLogEvent(eventName: 'Event-B')
      ]), // The logger will only be triggered for Event-A or Event-B for the ConsoleLog strategy.
      FirebaseAnalyticsLogStrategy(supportedEvents: [
        FirebaseAnalyticsLogEvent(eventName: 'Event-C'),
        FirebaseAnalyticsLogEvent(eventName: 'Event-D')
      ]), // The logger will only be triggered for Event-C or Event-D for the FirebaseAnalyticsLog strategy.
      FirebaseCrashlyticsLogStrategy(supportedEvents: [
        FirebaseCrashlyticsLogEvent(eventName: 'FATAL-ERROR-1'),
        FirebaseCrashlyticsLogEvent(eventName: 'FATAL-ERROR-2')
      ]), // The logger will only be triggered for FATAL-ERROR-1 or FATAL-ERROR-2 for the FirebaseCrashlyticsLog strategy.
      // Other strategies can be implemented by extending LogStrategy and registered here.
    ],
  );
}
