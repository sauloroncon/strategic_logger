import 'package:strategic_logger/logger.dart';

/// A subclass of [LogEvent] specifically tailored for logging events to the console.
///
/// This class extends [LogEvent] by providing a customized `toMap` method that
/// is particularly suited for console-based logging. It includes functionality
/// for handling additional data such as messages in a way that's optimal for
/// console output.
///
/// Example:
/// ```dart
/// var consoleEvent = ConsoleLogEvent(
///   eventName: 'user_login',
///   eventMessage: 'User logged in successfully',
///   parameters: {'userId': '12345'}
/// );
/// logger.log('A console-specific event', event: consoleEvent);
/// ```
class ConsoleLogEvent extends LogEvent {
  /// Constructs a [ConsoleLogEvent] with the necessary event attributes.
  ///
  /// [eventName] - A name describing the type of event. This is used as a primary identifier for the event type.
  /// [eventMessage] - Optional. A message providing additional details about the event. This is typically used for display in logs.
  /// [parameters] - Optional. A map containing additional data that should be logged with the event. This could include any context relevant to the event.
  ConsoleLogEvent({
    required super.eventName,
    super.eventMessage,
    super.parameters,
  });

  /// Converts the [ConsoleLogEvent] to a map, adapting the output specifically for console logging.
  ///
  /// This method overrides the base `toMap` to tailor the map output for better readability and formatting
  /// when dealing with console logs. The method organizes event data in a manner that enhances clarity
  /// when output to console.
  ///
  /// Returns a map representation of the console log event, which includes the event name and any relevant parameters.
  @override
  Map<String, dynamic> toMap() {
    return {
      'name': eventName,
      'parameters': {'message': eventMessage ?? 'No message provided'},
    };
  }
}
