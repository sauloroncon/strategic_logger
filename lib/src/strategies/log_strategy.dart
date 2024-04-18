import '../enums/log_level.dart';
import '../events/log_event.dart';

/// An abstract class that represents a logging strategy.
///
/// This class provides the structure for implementing various logging strategies,
/// allowing for detailed control over how messages, errors, and fatal errors are logged
/// depending on their level and the events they are associated with.
///
/// Implementations of this class should define how messages, errors, and fatal errors
/// are logged, potentially using different mechanisms or external systems.
abstract class LogStrategy {
  /// The minimum log level that this strategy handles for logging.
  LogLevel logLevel;

  /// The log level set by the logger using this strategy. Used to determine if a message should be logged.
  LogLevel loggerLogLevel;

  /// A list of specific [LogEvent] types that this strategy supports. If null, all events are considered supported.
  List<LogEvent>? supportedEvents;

  /// Constructs a [LogStrategy].
  ///
  /// [loggerLogLevel] - The log level of the logger. Defaults to [LogLevel.none].
  /// [logLevel] - The minimum log level that this strategy will handle. Defaults to [LogLevel.none].
  /// [supportedEvents] - Optional. Specifies the events that are explicitly supported by this strategy.
  LogStrategy({
    this.loggerLogLevel = LogLevel.none,
    this.logLevel = LogLevel.none,
    this.supportedEvents,
  });

  /// Determines whether a log operation should proceed based on the event and log level.
  ///
  /// [event] - Optional. The specific log event being checked. If provided, the method checks
  /// whether the event is supported by this strategy.
  /// Returns true if the log should be processed, false otherwise.
  bool shouldLog({LogEvent? event}) {
    if (event != null) {
      return supportedEvents?.contains(event) ?? true;
    } else {
      return logLevel.index <= loggerLogLevel.index;
    }
  }

  /// Abstract method to log a message or event.
  ///
  /// [message] - The message or data to log.
  /// [event] - Optional. The specific log event associated with the message.
  Future<void> log({dynamic message, LogEvent? event});

  /// Abstract method to log an error.
  ///
  /// [error] - The error object to log.
  /// [stackTrace] - Optional. The stack trace associated with the error.
  /// [event] - Optional. The specific log event associated with the error.
  Future<void> error({dynamic error, StackTrace? stackTrace, LogEvent? event});

  /// Abstract method to log a fatal error.
  ///
  /// [error] - The error object to log as fatal.
  /// [stackTrace] - Optional. The stack trace associated with the fatal error.
  /// [event] - Optional. The specific log event associated with the fatal error.
  Future<void> fatal({dynamic error, StackTrace? stackTrace, LogEvent? event});

  /// Provides a string representation of the strategy including its type and log level.
  @override
  String toString() {
    return '$runtimeType(LogLevel: $logLevel)';
  }
}
