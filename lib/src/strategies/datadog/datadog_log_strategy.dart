import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

import '../../core/isolate_manager.dart';
import '../../core/performance_monitor.dart';
import '../../enums/log_level.dart';
import '../../events/log_event.dart';
import '../log_strategy.dart';

/// A [LogStrategy] implementation that sends logs to Datadog.
///
/// This strategy provides integration with Datadog's logging service,
/// allowing for centralized log management and analysis. It supports
/// structured logging with metadata and context information.
///
/// Features:
/// - HTTP-based log transmission to Datadog
/// - Structured logging with metadata
/// - Batch processing for efficiency
/// - Error handling and retry logic
/// - Performance monitoring
///
/// Example:
/// ```dart
/// var datadogStrategy = DatadogLogStrategy(
///   apiKey: 'your-datadog-api-key',
///   service: 'my-app',
///   env: 'production',
/// );
/// var logger = StrategicLogger(strategies: [datadogStrategy]);
/// logger.log("Application started.");
/// ```
class DatadogLogStrategy extends LogStrategy {
  final String apiKey;
  final String service;
  final String env;
  final String? host;
  final String? source;
  final String? tags;
  final String datadogUrl;
  final int batchSize;
  final Duration batchTimeout;
  final int maxRetries;
  final Duration retryDelay;

  final List<Map<String, dynamic>> _batch = [];
  Timer? _batchTimer;
  final HttpClient _httpClient = HttpClient();

  /// Constructs a [DatadogLogStrategy].
  ///
  /// [apiKey] - Your Datadog API key (required)
  /// [service] - Service name for the logs (required)
  /// [env] - Environment name (required)
  /// [host] - Host name (optional)
  /// [source] - Source name (optional)
  /// [tags] - Additional tags (optional)
  /// [datadogUrl] - Datadog API URL (defaults to US region)
  /// [batchSize] - Number of logs to batch before sending
  /// [batchTimeout] - Maximum time to wait before sending batch
  /// [maxRetries] - Maximum number of retry attempts
  /// [retryDelay] - Delay between retry attempts
  /// [logLevel] - Minimum log level to process
  /// [supportedEvents] - Specific events to handle
  DatadogLogStrategy({
    required this.apiKey,
    required this.service,
    required this.env,
    this.host,
    this.source,
    this.tags,
    this.datadogUrl = 'https://http-intake.logs.datadoghq.com/v1/input',
    this.batchSize = 100,
    this.batchTimeout = const Duration(seconds: 5),
    this.maxRetries = 3,
    this.retryDelay = const Duration(seconds: 1),
    super.logLevel = LogLevel.none,
    super.supportedEvents,
  }) {
    _startBatchTimer();
  }

  /// Starts the batch timer for automatic log sending
  void _startBatchTimer() {
    _batchTimer = Timer.periodic(batchTimeout, (_) {
      if (_batch.isNotEmpty) {
        _sendBatch();
      }
    });
  }

  /// Logs a message or event to Datadog
  @override
  Future<void> log({dynamic message, LogEvent? event}) async {
    await _logToDatadog(LogLevel.info, message, event: event);
  }

  /// Logs an info message to Datadog
  @override
  Future<void> info({dynamic message, LogEvent? event}) async {
    await _logToDatadog(LogLevel.info, message, event: event);
  }

  /// Logs an error to Datadog
  @override
  Future<void> error({
    dynamic error,
    StackTrace? stackTrace,
    LogEvent? event,
  }) async {
    await _logToDatadog(
      LogLevel.error,
      error,
      event: event,
      stackTrace: stackTrace,
    );
  }

  /// Logs a fatal error to Datadog
  @override
  Future<void> fatal({
    dynamic error,
    StackTrace? stackTrace,
    LogEvent? event,
  }) async {
    await _logToDatadog(
      LogLevel.fatal,
      error,
      event: event,
      stackTrace: stackTrace,
    );
  }

  /// Internal method to log to Datadog
  Future<void> _logToDatadog(
    LogLevel level,
    dynamic message, {
    LogEvent? event,
    StackTrace? stackTrace,
  }) async {
    try {
      if (!shouldLog(event: event)) return;

      final logEntry = await _createLogEntry(
        level,
        message,
        event: event,
        stackTrace: stackTrace,
      );
      _batch.add(logEntry);

      // Send batch if it reaches the batch size
      if (_batch.length >= batchSize) {
        await _sendBatch();
      }
    } catch (e, stack) {
      developer.log(
        'Error in DatadogLogStrategy: $e',
        name: 'DatadogLogStrategy',
        error: e,
        stackTrace: stack,
      );
    }
  }

  /// Creates a log entry for Datadog
  Future<Map<String, dynamic>> _createLogEntry(
    LogLevel level,
    dynamic message, {
    LogEvent? event,
    StackTrace? stackTrace,
  }) async {
    final timestamp = DateTime.now().toUtc();

    // Use isolate for heavy processing if available
    Map<String, dynamic> logEntry;
    try {
      logEntry = await isolateManager.executeInIsolate('formatDatadogLog', {
        'message': message.toString(),
        'level': level.name,
        'timestamp': timestamp.toIso8601String(),
        'service': service,
        'env': env,
        'host': host,
        'source': source,
        'tags': tags,
        'event': event?.toMap(),
        'stackTrace': stackTrace?.toString(),
      });
    } catch (e) {
      // Fallback to direct processing
      logEntry = _formatLogEntryDirect(
        level,
        message,
        timestamp,
        event: event,
        stackTrace: stackTrace,
      );
    }

    return logEntry;
  }

  /// Direct log entry formatting (fallback)
  Map<String, dynamic> _formatLogEntryDirect(
    LogLevel level,
    dynamic message,
    DateTime timestamp, {
    LogEvent? event,
    StackTrace? stackTrace,
  }) {
    final logEntry = <String, dynamic>{
      'timestamp': timestamp.toIso8601String(),
      'status': _mapLogLevelToStatus(level),
      'message': message.toString(),
      'service': service,
      'env': env,
      'level': level.name,
    };

    if (host != null) logEntry['host'] = host;
    if (source != null) logEntry['source'] = source;
    if (tags != null) logEntry['tags'] = tags;

    // Add event information
    if (event != null) {
      logEntry['event'] = event.toMap();
      logEntry['event_name'] = event.eventName;
      if (event.eventMessage != null) {
        logEntry['event_message'] = event.eventMessage;
      }
      if (event.parameters != null && event.parameters!.isNotEmpty) {
        logEntry['parameters'] = event.parameters;
      }
    }

    // Add stack trace for errors
    if (stackTrace != null) {
      logEntry['stack_trace'] = stackTrace.toString();
    }

    // Add additional metadata
    logEntry['dd'] = {
      'trace_id': _generateTraceId(),
      'span_id': _generateSpanId(),
    };

    return logEntry;
  }

  /// Maps LogLevel to Datadog status
  String _mapLogLevelToStatus(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
      case LogLevel.info:
        return 'info';
      case LogLevel.warning:
        return 'warn';
      case LogLevel.error:
      case LogLevel.fatal:
        return 'error';
      case LogLevel.none:
        return 'info';
    }
  }

  /// Generates a trace ID for Datadog
  String _generateTraceId() {
    return DateTime.now().millisecondsSinceEpoch.toRadixString(36);
  }

  /// Generates a span ID for Datadog
  String _generateSpanId() {
    return DateTime.now().microsecondsSinceEpoch.toRadixString(36);
  }

  /// Sends the current batch to Datadog
  Future<void> _sendBatch() async {
    if (_batch.isEmpty) return;

    final batchToSend = List<Map<String, dynamic>>.from(_batch);
    _batch.clear();

    await performanceMonitor.measureOperation('sendDatadogBatch', () async {
      await _sendBatchWithRetry(batchToSend);
    });
  }

  /// Sends batch with retry logic
  Future<void> _sendBatchWithRetry(List<Map<String, dynamic>> batch) async {
    int attempts = 0;

    while (attempts < maxRetries) {
      try {
        await _sendBatchToDatadog(batch);
        return; // Success
      } catch (e) {
        attempts++;
        if (attempts >= maxRetries) {
          developer.log(
            'Failed to send batch to Datadog after $maxRetries attempts: $e',
            name: 'DatadogLogStrategy',
            error: e,
          );
          rethrow;
        }

        // Wait before retry
        await Future.delayed(retryDelay * attempts);
      }
    }
  }

  /// Sends batch to Datadog API
  Future<void> _sendBatchToDatadog(List<Map<String, dynamic>> batch) async {
    final request = await _httpClient.postUrl(Uri.parse(datadogUrl));

    // Set headers
    request.headers.set('Content-Type', 'application/json');
    request.headers.set('DD-API-KEY', apiKey);

    // Set body
    final body = jsonEncode(batch);
    request.write(body);

    final response = await request.close();

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Datadog API returned status ${response.statusCode}');
    }
  }

  /// Forces sending of all pending logs
  Future<void> flush() async {
    if (_batch.isNotEmpty) {
      await _sendBatch();
    }
  }

  /// Disposes the strategy and cleans up resources
  void dispose() {
    _batchTimer?.cancel();
    _httpClient.close();
    flush();
  }
}
