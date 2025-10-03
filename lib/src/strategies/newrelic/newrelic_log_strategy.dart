import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

import '../../core/isolate_manager.dart';
import '../../core/performance_monitor.dart';
import '../../enums/log_level.dart';
import '../../events/log_event.dart';
import '../log_strategy.dart';

/// A [LogStrategy] implementation that sends logs to New Relic.
///
/// This strategy provides integration with New Relic's logging service,
/// allowing for centralized log management and analysis. It supports
/// structured logging with metadata and context information.
///
/// Features:
/// - HTTP-based log transmission to New Relic
/// - Structured logging with metadata
/// - Batch processing for efficiency
/// - Error handling and retry logic
/// - Performance monitoring
///
/// Example:
/// ```dart
/// var newrelicStrategy = NewRelicLogStrategy(
///   licenseKey: 'your-newrelic-license-key',
///   appName: 'my-app',
/// );
/// var logger = StrategicLogger(strategies: [newrelicStrategy]);
/// logger.log("Application started.");
/// ```
class NewRelicLogStrategy extends LogStrategy {
  final String licenseKey;
  final String appName;
  final String? host;
  final String? environment;
  final String newrelicUrl;
  final int batchSize;
  final Duration batchTimeout;
  final int maxRetries;
  final Duration retryDelay;

  final List<Map<String, dynamic>> _batch = [];
  Timer? _batchTimer;
  final HttpClient _httpClient = HttpClient();

  /// Constructs a [NewRelicLogStrategy].
  ///
  /// [licenseKey] - Your New Relic license key (required)
  /// [appName] - Application name (required)
  /// [host] - Host name (optional)
  /// [environment] - Environment name (optional)
  /// [newrelicUrl] - New Relic API URL (defaults to US region)
  /// [batchSize] - Number of logs to batch before sending
  /// [batchTimeout] - Maximum time to wait before sending batch
  /// [maxRetries] - Maximum number of retry attempts
  /// [retryDelay] - Delay between retry attempts
  /// [logLevel] - Minimum log level to process
  /// [supportedEvents] - Specific events to handle
  NewRelicLogStrategy({
    required this.licenseKey,
    required this.appName,
    this.host,
    this.environment,
    this.newrelicUrl = 'https://log-api.newrelic.com/log/v1',
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

  /// Logs a message or event to New Relic
  @override
  Future<void> log({dynamic message, LogEvent? event}) async {
    await _logToNewRelic(LogLevel.info, message, event: event);
  }

  /// Logs an info message to New Relic
  @override
  Future<void> info({dynamic message, LogEvent? event}) async {
    await _logToNewRelic(LogLevel.info, message, event: event);
  }

  /// Logs an error to New Relic
  @override
  Future<void> error({
    dynamic error,
    StackTrace? stackTrace,
    LogEvent? event,
  }) async {
    await _logToNewRelic(
      LogLevel.error,
      error,
      event: event,
      stackTrace: stackTrace,
    );
  }

  /// Logs a fatal error to New Relic
  @override
  Future<void> fatal({
    dynamic error,
    StackTrace? stackTrace,
    LogEvent? event,
  }) async {
    await _logToNewRelic(
      LogLevel.fatal,
      error,
      event: event,
      stackTrace: stackTrace,
    );
  }

  /// Internal method to log to New Relic
  Future<void> _logToNewRelic(
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
        'Error in NewRelicLogStrategy: $e',
        name: 'NewRelicLogStrategy',
        error: e,
        stackTrace: stack,
      );
    }
  }

  /// Creates a log entry for New Relic
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
      logEntry = await isolateManager.executeInIsolate('formatNewRelicLog', {
        'message': message.toString(),
        'level': level.name,
        'timestamp': timestamp.toIso8601String(),
        'appName': appName,
        'host': host,
        'environment': environment,
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
      'timestamp': timestamp.millisecondsSinceEpoch,
      'level': _mapLogLevelToNewRelic(level),
      'message': message.toString(),
      'appName': appName,
    };

    if (host != null) logEntry['host'] = host;
    if (environment != null) logEntry['environment'] = environment;

    // Add event information
    if (event != null) {
      logEntry['event'] = event.toMap();
      logEntry['eventName'] = event.eventName;
      if (event.eventMessage != null) {
        logEntry['eventMessage'] = event.eventMessage;
      }
      if (event.parameters != null && event.parameters!.isNotEmpty) {
        logEntry['attributes'] = event.parameters;
      }
    }

    // Add stack trace for errors
    if (stackTrace != null) {
      logEntry['stackTrace'] = stackTrace.toString();
    }

    // Add New Relic specific metadata
    logEntry['entity'] = {'name': appName, 'type': 'APPLICATION'};

    return logEntry;
  }

  /// Maps LogLevel to New Relic level
  String _mapLogLevelToNewRelic(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return 'DEBUG';
      case LogLevel.info:
        return 'INFO';
      case LogLevel.warning:
        return 'WARN';
      case LogLevel.error:
        return 'ERROR';
      case LogLevel.fatal:
        return 'FATAL';
      case LogLevel.none:
        return 'INFO';
    }
  }

  /// Sends the current batch to New Relic
  Future<void> _sendBatch() async {
    if (_batch.isEmpty) return;

    final batchToSend = List<Map<String, dynamic>>.from(_batch);
    _batch.clear();

    await performanceMonitor.measureOperation('sendNewRelicBatch', () async {
      await _sendBatchWithRetry(batchToSend);
    });
  }

  /// Sends batch with retry logic
  Future<void> _sendBatchWithRetry(List<Map<String, dynamic>> batch) async {
    int attempts = 0;

    while (attempts < maxRetries) {
      try {
        await _sendBatchToNewRelic(batch);
        return; // Success
      } catch (e) {
        attempts++;
        if (attempts >= maxRetries) {
          developer.log(
            'Failed to send batch to New Relic after $maxRetries attempts: $e',
            name: 'NewRelicLogStrategy',
            error: e,
          );
          rethrow;
        }

        // Wait before retry
        await Future.delayed(retryDelay * attempts);
      }
    }
  }

  /// Sends batch to New Relic API
  Future<void> _sendBatchToNewRelic(List<Map<String, dynamic>> batch) async {
    final request = await _httpClient.postUrl(Uri.parse(newrelicUrl));

    // Set headers
    request.headers.set('Content-Type', 'application/json');
    request.headers.set('Api-Key', licenseKey);

    // Set body
    final body = jsonEncode(batch);
    request.write(body);

    final response = await request.close();

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('New Relic API returned status ${response.statusCode}');
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
