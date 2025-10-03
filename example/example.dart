import 'package:strategic_logger/logger.dart';

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
///
/// New features demonstrated:
/// - Modern console formatting with colors and emojis
/// - Isolate-based processing for heavy operations
/// - Performance monitoring
/// - Compatibility with popular logger packages
/// - Async queue with backpressure control
void main() async {
  // Initialize the logger once with its strategies and log level.
  await logger.initialize(
    level: LogLevel
        .debug, // Define from which log level the logger will be triggered.
    strategies: [
      // Register the log strategies that the logger will call. Some strategies are already implemented for convenience.
      ConsoleLogStrategy(
        useModernFormatting: true,
        useColors: true,
        useEmojis: true,
        showTimestamp: true,
        showContext: true,
      ), // ConsoleLogStrategy with modern formatting
      // Other strategies can be implemented by extending LogStrategy and registered here.
    ],
    useIsolates: true, // Enable isolate-based processing
    enablePerformanceMonitoring: true, // Enable performance monitoring
    enableModernConsole: true, // Enable modern console formatting
  );

  // Demonstrate modern logging features
  await logger.debug('Debug message with modern formatting');
  await logger.info(
    'Info message with context',
    context: {'userId': '123', 'action': 'login'},
  );
  await logger.warning(
    'Warning message with event',
    event: LogEvent(eventName: 'WARNING_EVENT'),
  );
  await logger.error(
    'Error message with stack trace',
    stackTrace: StackTrace.current,
  );
  await logger.fatal('Fatal error message');

  // Demonstrate compatibility with popular logger packages
  loggerCompatibility.debug('Debug message (compatibility mode)');
  loggerCompatibility.info('Info message (compatibility mode)');
  loggerCompatibility.error('Error message (compatibility mode)');

  // Demonstrate structured logging
  await logger.logStructured(
    LogLevel.info,
    'User action completed',
    data: {'userId': '123', 'action': 'purchase', 'amount': 99.99},
    tag: 'USER_ACTION',
  );

  // Demonstrate performance monitoring
  print('Performance Stats: ${logger.getPerformanceStats()}');

  // Reconfiguration of the logger after initialization is not recommended without a strong reason.
  await logger.reconfigure(
    // Example: If you need to reconfigure the logger strategies or update the logLevel after loading environment variables and strategy dependencies, you can reconfigure, but not before using the logger.
    level: LogLevel
        .info, // Define from which log level the logger will be triggered.
    strategies: [
      // Register the log strategies that the logger will call. Some strategies are already implemented for convenience.
      ConsoleLogStrategy(
        useModernFormatting: true,
        useColors: true,
        useEmojis: true,
      ), // ConsoleLogStrategy with modern formatting
      FirebaseCrashlyticsLogStrategy(), // FirebaseCrashlyticsLogStrategy logs errors to Crashlytics (This strategy will use your environment configuration).
      FirebaseAnalyticsLogStrategy(), // FirebaseAnalyticsLogStrategy logs events to Firebase Analytics (This strategy will use your environment configuration).
      // New modern strategies
      DatadogLogStrategy(
        apiKey: 'your-datadog-api-key',
        service: 'my-app',
        env: 'production',
        host: 'mobile-app',
        source: 'flutter',
        tags: 'team:mobile,version:1.0.0',
      ), // DatadogLogStrategy for centralized logging

      NewRelicLogStrategy(
        licenseKey: 'your-newrelic-license-key',
        appName: 'my-app',
        host: 'mobile-app',
        environment: 'production',
      ), // NewRelicLogStrategy for application monitoring
      // Other strategies can be implemented by extending LogStrategy and registered here.
    ],
    useIsolates: true,
    enablePerformanceMonitoring: true,
    enableModernConsole: true,
  );

  logger.log(
    'logging',
  ); // Calls the log method of ConsoleLogStrategy(), FirebaseCrashlyticsLogStrategy(), FirebaseAnalyticsLogStrategy() with just the message.
  logger.error(
    'error',
  ); // Calls the error method of ConsoleLogStrategy(), FirebaseCrashlyticsLogStrategy(), FirebaseAnalyticsLogStrategy() with just the error.
  logger.fatal(
    'fatal error',
  ); // Calls the fatal log of ConsoleLogStrategy(), FirebaseCrashlyticsLogStrategy(), FirebaseAnalyticsLogStrategy() with just the fatal error.

  // To send more structured logs, we can send a LogEvent (all strategies will be called).
  logger.log(
    'purchase completed',
    event: ConsoleLogEvent(
      eventName: 'PURCHASE_COMPLETED',
      parameters: {'key': 'value', 'key2': 'value'},
    ),
  );

  // To register a specific event of a strategy, we can specialize the event (only Console Log will be called).
  logger.log(
    'purchase completed',
    event: ConsoleLogEvent(
      eventName: 'PURCHASE_COMPLETED',
      parameters: {'key': 'value', 'key2': 'value'},
    ),
  );

  // To register a specific event of a strategy, we can specialize the event (only Firebase Analytics will be called).
  logger.log(
    'purchase completed',
    event: FirebaseAnalyticsLogEvent(
      eventName: 'PURCHASE_COMPLETED',
      parameters: {'key': 'value', 'key2': 'value'},
    ),
  );

  // To register a specific event of a strategy, we can specialize the event (only Firebase Crashlytics will be called).
  logger.error(
    'non-fatal error',
    event: FirebaseCrashlyticsLogEvent(
      eventName: 'ERROR',
      parameters: {'key': 'value', 'key2': 'value'},
    ),
  );
  logger.fatal(
    'fatal error',
    event: FirebaseAnalyticsLogEvent(
      eventName: 'FATAL_ERROR',
      parameters: {'key': 'value', 'key2': 'value'},
    ),
  );

  // During logger initialization and reconfiguration, we can restrict the events that will be allowed to be logged in each strategy.
  logger.reconfigure(
    // Example: If you need to reconfigure the logger strategies or update the logLevel after loading environment variables and strategy dependencies, you can reconfigure, but not before using the logger.
    level: LogLevel
        .error, // Define from which log level the logger will be triggered.
    strategies: [
      // Register the log strategies that the logger will call. Some strategies are already implemented for convenience.
      ConsoleLogStrategy(
        supportedEvents: [
          ConsoleLogEvent(eventName: 'Event-A'),
          ConsoleLogEvent(eventName: 'Event-B'),
        ],
      ), // The logger will only be triggered for Event-A or Event-B for the ConsoleLog strategy.
      FirebaseAnalyticsLogStrategy(
        supportedEvents: [
          FirebaseAnalyticsLogEvent(eventName: 'Event-C'),
          FirebaseAnalyticsLogEvent(eventName: 'Event-D'),
        ],
      ), // The logger will only be triggered for Event-C or Event-D for the FirebaseAnalyticsLog strategy.
      FirebaseCrashlyticsLogStrategy(
        supportedEvents: [
          FirebaseCrashlyticsLogEvent(eventName: 'FATAL-ERROR-1'),
          FirebaseCrashlyticsLogEvent(eventName: 'FATAL-ERROR-2'),
        ],
      ), // The logger will only be triggered for FATAL-ERROR-1 or FATAL-ERROR-2 for the FirebaseCrashlyticsLog strategy.
      // Other strategies can be implemented by extending LogStrategy and registered here.
    ],
  );
}
