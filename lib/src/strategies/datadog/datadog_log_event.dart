import '../../events/log_event.dart';

/// A specialized log event for Datadog logging strategy.
///
/// This class extends the base [LogEvent] to include Datadog-specific
/// metadata and formatting options. It provides structured data that
/// can be easily processed by Datadog's logging service.
///
/// Example:
/// ```dart
/// var datadogEvent = DatadogLogEvent(
///   eventName: 'user_action',
///   eventMessage: 'User completed purchase',
///   parameters: {'userId': '123', 'amount': 99.99},
///   tags: ['purchase', 'user_action'],
///   source: 'mobile_app',
/// );
/// ```
class DatadogLogEvent extends LogEvent {
  /// Additional tags for the event
  final List<String>? tags;

  /// Source of the event
  final String? source;

  /// Host where the event occurred
  final String? host;

  /// Service name
  final String? service;

  /// Environment name
  final String? env;

  /// Trace ID for distributed tracing
  final String? traceId;

  /// Span ID for distributed tracing
  final String? spanId;

  /// Custom attributes for the event
  final Map<String, dynamic>? attributes;

  /// Constructs a [DatadogLogEvent].
  ///
  /// [eventName] - The name of the event (required)
  /// [eventMessage] - Optional message describing the event
  /// [parameters] - Optional parameters associated with the event
  /// [tags] - Optional list of tags for categorization
  /// [source] - Optional source identifier
  /// [host] - Optional host identifier
  /// [service] - Optional service name
  /// [env] - Optional environment name
  /// [traceId] - Optional trace ID for distributed tracing
  /// [spanId] - Optional span ID for distributed tracing
  /// [attributes] - Optional custom attributes
  DatadogLogEvent({
    required super.eventName,
    super.eventMessage,
    super.parameters,
    this.tags,
    this.source,
    this.host,
    this.service,
    this.env,
    this.traceId,
    this.spanId,
    this.attributes,
  });

  /// Creates a [DatadogLogEvent] from a base [LogEvent]
  factory DatadogLogEvent.fromLogEvent(
    LogEvent event, {
    List<String>? tags,
    String? source,
    String? host,
    String? service,
    String? env,
    String? traceId,
    String? spanId,
    Map<String, dynamic>? attributes,
  }) {
    return DatadogLogEvent(
      eventName: event.eventName,
      eventMessage: event.eventMessage,
      parameters: event.parameters,
      tags: tags,
      source: source,
      host: host,
      service: service,
      env: env,
      traceId: traceId,
      spanId: spanId,
      attributes: attributes,
    );
  }

  /// Converts the event to a map with Datadog-specific formatting
  @override
  Map<String, dynamic> toMap() {
    final map = super.toMap();

    if (tags != null && tags!.isNotEmpty) {
      map['tags'] = tags;
    }

    if (source != null) {
      map['source'] = source;
    }

    if (host != null) {
      map['host'] = host;
    }

    if (service != null) {
      map['service'] = service;
    }

    if (env != null) {
      map['env'] = env;
    }

    if (traceId != null) {
      map['trace_id'] = traceId;
    }

    if (spanId != null) {
      map['span_id'] = spanId;
    }

    if (attributes != null && attributes!.isNotEmpty) {
      map['attributes'] = attributes;
    }

    return map;
  }

  /// Creates a copy of this event with updated values
  DatadogLogEvent copyWith({
    String? eventName,
    String? eventMessage,
    Map<String, Object>? parameters,
    List<String>? tags,
    String? source,
    String? host,
    String? service,
    String? env,
    String? traceId,
    String? spanId,
    Map<String, dynamic>? attributes,
  }) {
    return DatadogLogEvent(
      eventName: eventName ?? this.eventName,
      eventMessage: eventMessage ?? this.eventMessage,
      parameters: parameters ?? this.parameters,
      tags: tags ?? this.tags,
      source: source ?? this.source,
      host: host ?? this.host,
      service: service ?? this.service,
      env: env ?? this.env,
      traceId: traceId ?? this.traceId,
      spanId: spanId ?? this.spanId,
      attributes: attributes ?? this.attributes,
    );
  }

  @override
  String toString() {
    return 'DatadogLogEvent(eventName: $eventName, tags: $tags, source: $source, service: $service, env: $env)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! DatadogLogEvent) return false;

    return super == other &&
        tags == other.tags &&
        source == other.source &&
        host == other.host &&
        service == other.service &&
        env == other.env &&
        traceId == other.traceId &&
        spanId == other.spanId &&
        attributes == other.attributes;
  }

  @override
  int get hashCode {
    return Object.hash(
      super.hashCode,
      tags,
      source,
      host,
      service,
      env,
      traceId,
      spanId,
      attributes,
    );
  }
}
