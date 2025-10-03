import 'dart:collection';
import 'dart:developer' as developer;

import '../enums/log_level.dart';

/// Object Pool for Strategic Logger
///
/// Provides efficient object reuse to reduce memory allocations
/// and garbage collection pressure for high-frequency logging operations.
class ObjectPool {
  static ObjectPool? _instance;
  static ObjectPool get instance => _instance ??= ObjectPool._();

  ObjectPool._();

  // Pools for different object types
  final Queue<LogEntry> _logEntryPool = Queue<LogEntry>();
  final Queue<LogEvent> _logEventPool = Queue<LogEvent>();
  final Queue<StringBuffer> _stringBufferPool = Queue<StringBuffer>();
  final Queue<Map<String, dynamic>> _contextMapPool =
      Queue<Map<String, dynamic>>();

  // Pool configuration
  final int _maxPoolSize = 1000;
  final int _initialPoolSize = 100;

  // Statistics
  int _logEntryAllocations = 0;
  int _logEntryReuses = 0;
  int _logEventAllocations = 0;
  int _logEventReuses = 0;
  int _stringBufferAllocations = 0;
  int _stringBufferReuses = 0;
  int _contextMapAllocations = 0;
  int _contextMapReuses = 0;

  /// Initializes the object pools
  void initialize() {
    _initializeLogEntryPool();
    _initializeLogEventPool();
    _initializeStringBufferPool();
    _initializeContextMapPool();

    developer.log(
      'ObjectPool initialized with ${_initialPoolSize} objects per pool',
      name: 'ObjectPool',
    );
  }

  /// Gets a LogEntry from the pool or creates a new one
  LogEntry getLogEntry({
    required LogLevel level,
    required String message,
    required DateTime timestamp,
    Map<String, Object>? context,
    LogEvent? event,
  }) {
    LogEntry entry;

    if (_logEntryPool.isNotEmpty) {
      entry = _logEntryPool.removeFirst();
      _logEntryReuses++;

      // Reset the entry
      entry._reset(
        level: level,
        message: message,
        timestamp: timestamp,
        context: context,
        event: event,
      );
    } else {
      entry = LogEntry._(
        level: level,
        message: message,
        timestamp: timestamp,
        context: context,
        event: event,
      );
      _logEntryAllocations++;
    }

    return entry;
  }

  /// Returns a LogEntry to the pool
  void returnLogEntry(LogEntry entry) {
    if (_logEntryPool.length < _maxPoolSize) {
      _logEntryPool.add(entry);
    }
  }

  /// Gets a LogEvent from the pool or creates a new one
  LogEvent getLogEvent({
    required String eventName,
    required String eventMessage,
    required DateTime timestamp,
    Map<String, Object>? context,
  }) {
    LogEvent event;

    if (_logEventPool.isNotEmpty) {
      event = _logEventPool.removeFirst();
      _logEventReuses++;

      // Reset the event
      event._reset(
        eventName: eventName,
        eventMessage: eventMessage,
        timestamp: timestamp,
        context: context,
      );
    } else {
      event = LogEvent._(
        eventName: eventName,
        eventMessage: eventMessage,
        timestamp: timestamp,
        context: context,
      );
      _logEventAllocations++;
    }

    return event;
  }

  /// Returns a LogEvent to the pool
  void returnLogEvent(LogEvent event) {
    if (_logEventPool.length < _maxPoolSize) {
      _logEventPool.add(event);
    }
  }

  /// Gets a StringBuffer from the pool or creates a new one
  StringBuffer getStringBuffer() {
    StringBuffer buffer;

    if (_stringBufferPool.isNotEmpty) {
      buffer = _stringBufferPool.removeFirst();
      _stringBufferReuses++;

      // Clear the buffer
      buffer.clear();
    } else {
      buffer = StringBuffer();
      _stringBufferAllocations++;
    }

    return buffer;
  }

  /// Returns a StringBuffer to the pool
  void returnStringBuffer(StringBuffer buffer) {
    if (_stringBufferPool.length < _maxPoolSize) {
      buffer.clear();
      _stringBufferPool.add(buffer);
    }
  }

  /// Gets a context Map from the pool or creates a new one
  Map<String, dynamic> getContextMap() {
    Map<String, dynamic> map;

    if (_contextMapPool.isNotEmpty) {
      map = _contextMapPool.removeFirst();
      _contextMapReuses++;

      // Clear the map
      map.clear();
    } else {
      map = <String, dynamic>{};
      _contextMapAllocations++;
    }

    return map;
  }

  /// Returns a context Map to the pool
  void returnContextMap(Map<String, dynamic> map) {
    if (_contextMapPool.length < _maxPoolSize) {
      map.clear();
      _contextMapPool.add(map);
    }
  }

  /// Initializes the LogEntry pool
  void _initializeLogEntryPool() {
    for (int i = 0; i < _initialPoolSize; i++) {
      _logEntryPool.add(
        LogEntry._(
          level: LogLevel.info,
          message: '',
          timestamp: DateTime.now(),
          context: null,
          event: null,
        ),
      );
    }
  }

  /// Initializes the LogEvent pool
  void _initializeLogEventPool() {
    for (int i = 0; i < _initialPoolSize; i++) {
      _logEventPool.add(
        LogEvent._(
          eventName: '',
          eventMessage: '',
          timestamp: DateTime.now(),
          context: null,
        ),
      );
    }
  }

  /// Initializes the StringBuffer pool
  void _initializeStringBufferPool() {
    for (int i = 0; i < _initialPoolSize; i++) {
      _stringBufferPool.add(StringBuffer());
    }
  }

  /// Initializes the context Map pool
  void _initializeContextMapPool() {
    for (int i = 0; i < _initialPoolSize; i++) {
      _contextMapPool.add(<String, dynamic>{});
    }
  }

  /// Gets pool statistics
  ObjectPoolStats getStats() {
    return ObjectPoolStats(
      logEntryPoolSize: _logEntryPool.length,
      logEntryAllocations: _logEntryAllocations,
      logEntryReuses: _logEntryReuses,
      logEventPoolSize: _logEventPool.length,
      logEventAllocations: _logEventAllocations,
      logEventReuses: _logEventReuses,
      stringBufferPoolSize: _stringBufferPool.length,
      stringBufferAllocations: _stringBufferAllocations,
      stringBufferReuses: _stringBufferReuses,
      contextMapPoolSize: _contextMapPool.length,
      contextMapAllocations: _contextMapAllocations,
      contextMapReuses: _contextMapReuses,
    );
  }

  /// Clears all pools
  void clear() {
    _logEntryPool.clear();
    _logEventPool.clear();
    _stringBufferPool.clear();
    _contextMapPool.clear();

    developer.log('ObjectPool cleared', name: 'ObjectPool');
  }

  /// Disposes the object pool
  void dispose() {
    clear();
    _instance = null;
  }
}

/// Pooled LogEntry implementation
class LogEntry {
  LogLevel _level;
  String _message;
  DateTime _timestamp;
  Map<String, Object>? _context;
  LogEvent? _event;

  LogEntry._({
    required LogLevel level,
    required String message,
    required DateTime timestamp,
    Map<String, Object>? context,
    LogEvent? event,
  }) : _level = level,
       _message = message,
       _timestamp = timestamp,
       _context = context,
       _event = event;

  /// Resets the LogEntry for reuse
  void _reset({
    required LogLevel level,
    required String message,
    required DateTime timestamp,
    Map<String, Object>? context,
    LogEvent? event,
  }) {
    _level = level;
    _message = message;
    _timestamp = timestamp;
    _context = context;
    _event = event;
  }

  LogLevel get level => _level;
  String get message => _message;
  DateTime get timestamp => _timestamp;
  Map<String, Object>? get context => _context;
  LogEvent? get event => _event;

  /// Returns this LogEntry to the pool
  void returnToPool() {
    ObjectPool.instance.returnLogEntry(this);
  }

  Map<String, dynamic> toJson() {
    return {
      'level': _level.name,
      'message': _message,
      'timestamp': _timestamp.toIso8601String(),
      'context': _context,
      'event': _event?.toMap(),
    };
  }

  @override
  String toString() {
    return 'LogEntry(level: $_level, message: $_message, timestamp: $_timestamp)';
  }
}

/// Pooled LogEvent implementation
class LogEvent {
  String _eventName;
  String _eventMessage;
  DateTime _timestamp;
  Map<String, Object>? _context;

  LogEvent._({
    required String eventName,
    required String eventMessage,
    required DateTime timestamp,
    Map<String, Object>? context,
  }) : _eventName = eventName,
       _eventMessage = eventMessage,
       _timestamp = timestamp,
       _context = context;

  /// Resets the LogEvent for reuse
  void _reset({
    required String eventName,
    required String eventMessage,
    required DateTime timestamp,
    Map<String, Object>? context,
  }) {
    _eventName = eventName;
    _eventMessage = eventMessage;
    _timestamp = timestamp;
    _context = context;
  }

  String get eventName => _eventName;
  String get eventMessage => _eventMessage;
  DateTime get timestamp => _timestamp;
  Map<String, Object>? get context => _context;

  /// Returns this LogEvent to the pool
  void returnToPool() {
    ObjectPool.instance.returnLogEvent(this);
  }

  Map<String, dynamic> toMap() {
    return {
      'eventName': _eventName,
      'eventMessage': _eventMessage,
      'timestamp': _timestamp.toIso8601String(),
      'context': _context,
    };
  }

  @override
  String toString() {
    return 'LogEvent(name: $_eventName, message: $_eventMessage, timestamp: $_timestamp)';
  }
}

/// Object Pool Statistics
class ObjectPoolStats {
  final int logEntryPoolSize;
  final int logEntryAllocations;
  final int logEntryReuses;
  final int logEventPoolSize;
  final int logEventAllocations;
  final int logEventReuses;
  final int stringBufferPoolSize;
  final int stringBufferAllocations;
  final int stringBufferReuses;
  final int contextMapPoolSize;
  final int contextMapAllocations;
  final int contextMapReuses;

  ObjectPoolStats({
    required this.logEntryPoolSize,
    required this.logEntryAllocations,
    required this.logEntryReuses,
    required this.logEventPoolSize,
    required this.logEventAllocations,
    required this.logEventReuses,
    required this.stringBufferPoolSize,
    required this.stringBufferAllocations,
    required this.stringBufferReuses,
    required this.contextMapPoolSize,
    required this.contextMapAllocations,
    required this.contextMapReuses,
  });

  /// Total allocations across all pools
  int get totalAllocations =>
      logEntryAllocations +
      logEventAllocations +
      stringBufferAllocations +
      contextMapAllocations;

  /// Total reuses across all pools
  int get totalReuses =>
      logEntryReuses + logEventReuses + stringBufferReuses + contextMapReuses;

  /// Reuse rate across all pools
  double get reuseRate => totalReuses / (totalAllocations + totalReuses);

  /// Memory efficiency score (0.0 to 1.0)
  double get efficiencyScore => totalReuses / (totalAllocations + totalReuses);

  Map<String, dynamic> toJson() {
    return {
      'logEntryPoolSize': logEntryPoolSize,
      'logEntryAllocations': logEntryAllocations,
      'logEntryReuses': logEntryReuses,
      'logEventPoolSize': logEventPoolSize,
      'logEventAllocations': logEventAllocations,
      'logEventReuses': logEventReuses,
      'stringBufferPoolSize': stringBufferPoolSize,
      'stringBufferAllocations': stringBufferAllocations,
      'stringBufferReuses': stringBufferReuses,
      'contextMapPoolSize': contextMapPoolSize,
      'contextMapAllocations': contextMapAllocations,
      'contextMapReuses': contextMapReuses,
      'totalAllocations': totalAllocations,
      'totalReuses': totalReuses,
      'reuseRate': reuseRate,
      'efficiencyScore': efficiencyScore,
    };
  }

  @override
  String toString() {
    return 'ObjectPoolStats(allocations: $totalAllocations, reuses: $totalReuses, efficiency: ${(efficiencyScore * 100).toStringAsFixed(1)}%)';
  }
}
