import 'dart:async';
import 'dart:collection';

import 'package:meta/meta.dart';

import '../enums/log_level.dart';
import '../events/log_event.dart';

/// A queue for managing log entries with backpressure control
@internal
class LogQueue {
  final Queue<LogEntry> _queue = Queue<LogEntry>();
  final StreamController<LogEntry> _controller =
      StreamController<LogEntry>.broadcast();
  final int _maxSize;
  final Duration _flushInterval;
  Timer? _flushTimer;
  bool _isProcessing = false;

  LogQueue({
    int maxSize = 1000,
    Duration flushInterval = const Duration(seconds: 5),
  }) : _maxSize = maxSize,
       _flushInterval = flushInterval;

  /// Stream of log entries
  Stream<LogEntry> get stream => _controller.stream;

  /// Current queue size
  int get size => _queue.length;

  /// Whether the queue is full
  bool get isFull => _queue.length >= _maxSize;

  /// Adds a log entry to the queue
  void enqueue(LogEntry entry) {
    if (isFull) {
      // Remove oldest entry to make room (backpressure)
      _queue.removeFirst();
    }

    _queue.add(entry);

    // Start processing if not already running
    if (!_isProcessing) {
      _startProcessing();
    }
  }

  /// Starts processing the queue
  void _startProcessing() {
    if (_isProcessing) return;

    _isProcessing = true;
    _flushTimer = Timer(_flushInterval, () {
      _processBatch();
    });
  }

  /// Processes a batch of log entries
  void _processBatch() {
    if (_queue.isEmpty) {
      _isProcessing = false;
      return;
    }

    final batch = <LogEntry>[];
    final batchSize = _queue.length > 100 ? 100 : _queue.length;

    for (int i = 0; i < batchSize; i++) {
      if (_queue.isNotEmpty) {
        batch.add(_queue.removeFirst());
      }
    }

    // Emit batch for processing
    for (final entry in batch) {
      _controller.add(entry);
    }

    // Continue processing if queue is not empty
    if (_queue.isNotEmpty) {
      _startProcessing();
    } else {
      _isProcessing = false;
    }
  }

  /// Forces immediate processing of all queued entries
  void flush() {
    _flushTimer?.cancel();
    _processBatch();
  }

  /// Clears the queue
  void clear() {
    _queue.clear();
    _flushTimer?.cancel();
    _isProcessing = false;
  }

  /// Disposes the queue and cleans up resources
  void dispose() {
    _flushTimer?.cancel();
    _controller.close();
    _queue.clear();
  }
}

/// Represents a log entry in the queue
@internal
class LogEntry {
  final dynamic message;
  final LogLevel level;
  final DateTime timestamp;
  final LogEvent? event;
  final Map<String, dynamic>? context;
  final StackTrace? stackTrace;

  LogEntry({
    required this.message,
    required this.level,
    required this.timestamp,
    this.event,
    this.context,
    this.stackTrace,
  });

  /// Creates a log entry from parameters
  factory LogEntry.fromParams({
    required dynamic message,
    required LogLevel level,
    LogEvent? event,
    Map<String, dynamic>? context,
    StackTrace? stackTrace,
  }) {
    return LogEntry(
      message: message,
      level: level,
      timestamp: DateTime.now(),
      event: event,
      context: context,
      stackTrace: stackTrace,
    );
  }

  /// Converts to map for serialization
  Map<String, dynamic> toMap() {
    return {
      'message': message,
      'level': level.name,
      'timestamp': timestamp.toIso8601String(),
      'event': event?.toMap(),
      'context': context,
      'stackTrace': stackTrace?.toString(),
    };
  }

  @override
  String toString() {
    return 'LogEntry(level: $level, message: $message, timestamp: $timestamp)';
  }
}
