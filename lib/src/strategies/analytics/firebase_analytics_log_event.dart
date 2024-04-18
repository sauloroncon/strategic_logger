import 'package:strategic_logger/logger.dart';

/// A subclass of [LogEvent] designed for integration with Firebase Analytics.
///
/// This class extends [LogEvent] by providing additional functionality tailored for logging events
/// directly to Firebase Analytics. It encapsulates all necessary information for Firebase Analytics
/// events, including optional parameters that can be sent along with each event.
///
/// Example:
/// ```dart
/// var analyticsEvent = FirebaseAnalyticsLogEvent(
///   eventName: 'purchase',
///   eventMessage: 'User completed a purchase',
///   parameters: {'item_id': 'SKU123', 'price': '29.99'}
/// );
/// logger.log(event: analyticsEvent);
/// ```
class FirebaseAnalyticsLogEvent extends LogEvent {
  /// Constructs a [FirebaseAnalyticsLogEvent] with required and optional parameters.
  ///
  /// [eventName] - A name identifying the event. This is used as the primary identifier for the event type in Firebase Analytics.
  /// [eventMessage] - Optional. A message providing additional details about the event, used for context or further description.
  /// [parameters] - Optional. A map containing additional data that should be logged with the event. This can include any key-value pairs that Firebase Analytics supports.
  FirebaseAnalyticsLogEvent(
      {required super.eventName, super.eventMessage, super.parameters});

  /// Converts the [FirebaseAnalyticsLogEvent] to a map, suitable for submission to Firebase Analytics.
  ///
  /// Overrides the base `toMap` method to include the event name and any parameters in a format that Firebase Analytics expects.
  /// Returns a map representation of the Firebase Analytics log event, which includes the event name and associated parameters.
  @override
  Map<String, dynamic> toMap() {
    return {
      'name': eventName,
      'parameters': parameters,
    };
  }
}
