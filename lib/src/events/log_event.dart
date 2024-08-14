/// A base class for creating log events, encapsulating information that can be logged.
///
/// This class provides the fundamental structure for log events, designed to be extended or used directly
/// for custom logging solutions. It includes essential details like the event name, an optional message,
/// and a parameters map that can be utilized to pass additional data relevant to the event.
///
/// Example:
/// ```dart
/// var loginEvent = LogEvent(
///   eventName: 'user_login_attempt',
///   eventMessage: 'User attempted to log in.',
///   parameters: {'username': 'exampleUser'}
/// );
/// logger.log('A user event', event: loginEvent);
/// ```
class LogEvent {
  /// The name of the event. This is a required field and is used to identify the type of the event.
  final String eventName;

  /// An optional message associated with the event, providing additional detail about the event's context or outcome.
  final String? eventMessage;

  /// A map of key-value pairs containing additional parameters that provide more context to the event.
  /// This is useful for passing additional data that may be relevant to specific logs.
  final Map<String, Object>? parameters;

  /// Constructs a [LogEvent] with a mandatory event name, an optional event message, and an optional map of parameters.
  ///
  /// [eventName] - A unique identifier for the type of log event.
  /// [eventMessage] - Optional. Provides additional details about the event.
  /// [parameters] - Optional. A map containing additional data about the event. Defaults to an empty map.
  LogEvent({
    required this.eventName,
    this.eventMessage,
    this.parameters = const {},
  });

  /// Converts the [LogEvent] to a map, which typically includes the event name and any parameters provided.
  ///
  /// This method can be overridden by subclasses to include additional or altered information.
  /// Returns a map representation of the log event, which can be directly used for logging or further processing.
  Map<String, dynamic> toMap() {
    return {'eventName': eventName, 'parameters': parameters};
  }

  /// Checks the equality of [LogEvent] instances based on the event name.
  ///
  /// This allows for comparison between instances, primarily focusing on the event name to determine equality.
  /// Useful in scenarios where event uniqueness is determined by the event name alone.
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! LogEvent) return false;
    return eventName == other.eventName;
  }

  /// Generates a hash code based on the event name.
  ///
  /// This is useful for maintaining efficiency in collections that are based on hash tables, like sets or maps.
  @override
  int get hashCode {
    return eventName.hashCode;
  }
}
