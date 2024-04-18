import 'package:strategic_logger/logger.dart';

/// A subclass of [LogEvent] that encapsulates data specific to Firebase Crashlytics logging.
///
/// This class extends [LogEvent] to include functionality for logging errors with Firebase Crashlytics,
/// including optional stack trace information. It is tailored to log error messages and their associated
/// stack traces to Firebase Crashlytics, aiding in debugging and monitoring application health.
///
/// The class is designed to provide a structured format for error reporting, making it easier to
/// understand the context and specifics of an error when viewed in the Firebase Crashlytics dashboard.
///
/// Example:
/// ```dart
/// var crashlyticsEvent = FirebaseCrashlyticsLogEvent(
///   eventName: 'error_occurred',
///   eventMessage: 'Unexpected error encountered',
///   stackTrace: 'Stack trace here...',
/// );
/// logger.log('An error event', event: crashlyticsEvent);
/// ```
class FirebaseCrashlyticsLogEvent extends LogEvent {
  /// An optional stack trace string that provides details about the error's location and state at the time of error.
  ///
  /// This can be very helpful for debugging in production, where reading logs might be the primary way to diagnose issues.
  final String? stackTrace;

  /// Constructs a [FirebaseCrashlyticsLogEvent] with optional stack trace and required event attributes.
  ///
  /// [stackTrace] - A string representing the stack trace associated with the error.
  /// [eventName] - A name describing the type of event.
  /// [eventMessage] - A message providing additional details about the event.
  /// [parameters] - A map containing additional data that should be logged with the event.
  FirebaseCrashlyticsLogEvent({
    this.stackTrace,
    required super.eventName,
    super.eventMessage,
    super.parameters,
  });

  /// Converts the [FirebaseCrashlyticsLogEvent] to a map, including the event name, message, and stack trace.
  ///
  /// Overrides the [toMap] method to include additional logging information specific to this event type.
  /// Returns a map which can be directly used for logging to Firebase Crashlytics.
  @override
  Map<String, dynamic> toMap() {
    return {
      'name': eventName,
      'parameters': {
        'error': eventMessage,
        'stackTrace': stackTrace,
      },
    };
  }
}
