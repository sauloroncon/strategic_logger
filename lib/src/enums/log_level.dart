/// Defines the severity levels for logging throughout the application.
///
/// Each level corresponds to a specific kind of information to be logged,
/// allowing for filtering and handling of log output based on the importance
/// and nature of the information.
///
/// Levels:
/// - [none]: No logging level specified. Generally used to disable logging.
/// - [debug]: Detailed information on the flow through the system. Used for debugging.
/// - [info]: Interesting runtime events (e.g., startup or shutdown). Use this level for general operational entries that highlight progress or state within the application.
/// - [warning]: Potential issues that are not necessarily errors or critical failures, but may warrant investigation.
/// - [error]: Error events that might still allow the application to continue running.
/// - [fatal]: Very severe error events that might cause the application to terminate.
///
/// Provides a method to convert string representations of log levels to their corresponding enum values.
///
/// Example:
/// ```dart
/// var logLevel = LogLevel.converter("error");
/// ```
enum LogLevel {
  none,
  debug,
  info,
  warning,
  error,
  fatal;

  /// Converts a string name to its corresponding [LogLevel] enum value.
  ///
  /// Throws a [StateError] if no matching level is found, ensuring that only valid log levels are used.
  ///
  /// [name] - The name of the log level to convert.
  /// Returns the [LogLevel] value matching the name.
  static LogLevel converter(String name) => LogLevel.values.firstWhere(
    (logLevel) => logLevel.name == name,
    orElse: () {
      throw StateError('Invalid log level name: $name');
    },
  );
}
