import '../../events/log_event.dart';

/// A specialized log event for New Relic logging strategy.
///
/// This class extends the base [LogEvent] to include New Relic-specific
/// metadata and formatting options. It provides structured data that
/// can be easily processed by New Relic's logging service.
///
/// Example:
/// ```dart
/// var newrelicEvent = NewRelicLogEvent(
///   eventName: 'user_action',
///   eventMessage: 'User completed purchase',
///   parameters: {'userId': '123', 'amount': 99.99},
///   attributes: {'custom_attr': 'value'},
///   entityName: 'my-app',
/// );
/// ```
class NewRelicLogEvent extends LogEvent {
  /// Custom attributes for the event
  final Map<String, dynamic>? attributes;

  /// Entity name (application name)
  final String? entityName;

  /// Entity type
  final String? entityType;

  /// Host where the event occurred
  final String? host;

  /// Environment name
  final String? environment;

  /// Trace ID for distributed tracing
  final String? traceId;

  /// Span ID for distributed tracing
  final String? spanId;

  /// Constructs a [NewRelicLogEvent].
  ///
  /// [eventName] - The name of the event (required)
  /// [eventMessage] - Optional message describing the event
  /// [parameters] - Optional parameters associated with the event
  /// [attributes] - Optional custom attributes
  /// [entityName] - Optional entity name (application name)
  /// [entityType] - Optional entity type
  /// [host] - Optional host identifier
  /// [environment] - Optional environment name
  /// [traceId] - Optional trace ID for distributed tracing
  /// [spanId] - Optional span ID for distributed tracing
  NewRelicLogEvent({
    required super.eventName,
    super.eventMessage,
    super.parameters,
    this.attributes,
    this.entityName,
    this.entityType,
    this.host,
    this.environment,
    this.traceId,
    this.spanId,
  });

  /// Creates a [NewRelicLogEvent] from a base [LogEvent]
  factory NewRelicLogEvent.fromLogEvent(
    LogEvent event, {
    Map<String, dynamic>? attributes,
    String? entityName,
    String? entityType,
    String? host,
    String? environment,
    String? traceId,
    String? spanId,
  }) {
    return NewRelicLogEvent(
      eventName: event.eventName,
      eventMessage: event.eventMessage,
      parameters: event.parameters,
      attributes: attributes,
      entityName: entityName,
      entityType: entityType,
      host: host,
      environment: environment,
      traceId: traceId,
      spanId: spanId,
    );
  }

  /// Converts the event to a map with New Relic-specific formatting
  @override
  Map<String, dynamic> toMap() {
    final map = super.toMap();

    if (attributes != null && attributes!.isNotEmpty) {
      map['attributes'] = attributes;
    }

    if (entityName != null) {
      map['entityName'] = entityName;
    }

    if (entityType != null) {
      map['entityType'] = entityType;
    }

    if (host != null) {
      map['host'] = host;
    }

    if (environment != null) {
      map['environment'] = environment;
    }

    if (traceId != null) {
      map['traceId'] = traceId;
    }

    if (spanId != null) {
      map['spanId'] = spanId;
    }

    return map;
  }

  /// Creates a copy of this event with updated values
  NewRelicLogEvent copyWith({
    String? eventName,
    String? eventMessage,
    Map<String, Object>? parameters,
    Map<String, dynamic>? attributes,
    String? entityName,
    String? entityType,
    String? host,
    String? environment,
    String? traceId,
    String? spanId,
  }) {
    return NewRelicLogEvent(
      eventName: eventName ?? this.eventName,
      eventMessage: eventMessage ?? this.eventMessage,
      parameters: parameters ?? this.parameters,
      attributes: attributes ?? this.attributes,
      entityName: entityName ?? this.entityName,
      entityType: entityType ?? this.entityType,
      host: host ?? this.host,
      environment: environment ?? this.environment,
      traceId: traceId ?? this.traceId,
      spanId: spanId ?? this.spanId,
    );
  }

  @override
  String toString() {
    return 'NewRelicLogEvent(eventName: $eventName, entityName: $entityName, entityType: $entityType, environment: $environment)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! NewRelicLogEvent) return false;

    return super == other &&
        attributes == other.attributes &&
        entityName == other.entityName &&
        entityType == other.entityType &&
        host == other.host &&
        environment == other.environment &&
        traceId == other.traceId &&
        spanId == other.spanId;
  }

  @override
  int get hashCode {
    return Object.hash(
      super.hashCode,
      attributes,
      entityName,
      entityType,
      host,
      environment,
      traceId,
      spanId,
    );
  }
}
