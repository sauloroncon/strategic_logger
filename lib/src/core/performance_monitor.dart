import 'dart:async';

import 'package:meta/meta.dart';

/// Monitors performance metrics for the logger
@internal
class PerformanceMonitor {
  static final PerformanceMonitor _instance = PerformanceMonitor._internal();
  factory PerformanceMonitor() => _instance;
  PerformanceMonitor._internal();

  final Map<String, List<Duration>> _operationTimes = {};
  final Map<String, int> _operationCounts = {};
  final Map<String, int> _operationErrors = {};
  final StreamController<PerformanceMetric> _metricsController =
      StreamController<PerformanceMetric>.broadcast();

  /// Stream of performance metrics
  Stream<PerformanceMetric> get metricsStream => _metricsController.stream;

  /// Records the time taken for an operation
  Future<T> measureOperation<T>(
    String operationName,
    Future<T> Function() operation,
  ) async {
    final stopwatch = Stopwatch()..start();

    try {
      final result = await operation();
      stopwatch.stop();

      _recordOperation(operationName, stopwatch.elapsed, false);
      return result;
    } catch (e) {
      stopwatch.stop();
      _recordOperation(operationName, stopwatch.elapsed, true);
      rethrow;
    }
  }

  /// Records a synchronous operation
  T measureSyncOperation<T>(String operationName, T Function() operation) {
    final stopwatch = Stopwatch()..start();

    try {
      final result = operation();
      stopwatch.stop();

      _recordOperation(operationName, stopwatch.elapsed, false);
      return result;
    } catch (e) {
      stopwatch.stop();
      _recordOperation(operationName, stopwatch.elapsed, true);
      rethrow;
    }
  }

  /// Records operation metrics
  void _recordOperation(String operationName, Duration duration, bool isError) {
    _operationTimes.putIfAbsent(operationName, () => []);
    _operationTimes[operationName]!.add(duration);

    _operationCounts[operationName] =
        (_operationCounts[operationName] ?? 0) + 1;

    if (isError) {
      _operationErrors[operationName] =
          (_operationErrors[operationName] ?? 0) + 1;
    }

    // Emit metric
    _metricsController.add(
      PerformanceMetric(
        operationName: operationName,
        duration: duration,
        isError: isError,
        timestamp: DateTime.now(),
      ),
    );

    // Keep only last 100 measurements per operation
    if (_operationTimes[operationName]!.length > 100) {
      _operationTimes[operationName]!.removeAt(0);
    }
  }

  /// Gets performance statistics for an operation
  PerformanceStats getStats(String operationName) {
    final times = _operationTimes[operationName] ?? [];
    final count = _operationCounts[operationName] ?? 0;
    final errors = _operationErrors[operationName] ?? 0;

    if (times.isEmpty) {
      return PerformanceStats(
        operationName: operationName,
        count: 0,
        errors: 0,
        averageTime: Duration.zero,
        minTime: Duration.zero,
        maxTime: Duration.zero,
        totalTime: Duration.zero,
        errorRate: 0.0,
      );
    }

    final totalTime = times.fold<Duration>(
      Duration.zero,
      (sum, duration) => sum + duration,
    );

    final averageTime = Duration(
      microseconds: totalTime.inMicroseconds ~/ times.length,
    );

    final minTime = times.reduce((a, b) => a < b ? a : b);
    final maxTime = times.reduce((a, b) => a > b ? a : b);
    final errorRate = count > 0 ? errors / count : 0.0;

    return PerformanceStats(
      operationName: operationName,
      count: count,
      errors: errors,
      averageTime: averageTime,
      minTime: minTime,
      maxTime: maxTime,
      totalTime: totalTime,
      errorRate: errorRate,
    );
  }

  /// Gets all performance statistics
  Map<String, PerformanceStats> getAllStats() {
    final stats = <String, PerformanceStats>{};

    for (final operationName in _operationTimes.keys) {
      stats[operationName] = getStats(operationName);
    }

    return stats;
  }

  /// Resets all performance data
  void reset() {
    _operationTimes.clear();
    _operationCounts.clear();
    _operationErrors.clear();
  }

  /// Disposes the performance monitor
  void dispose() {
    _metricsController.close();
  }
}

/// Represents a performance metric
@internal
class PerformanceMetric {
  final String operationName;
  final Duration duration;
  final bool isError;
  final DateTime timestamp;

  PerformanceMetric({
    required this.operationName,
    required this.duration,
    required this.isError,
    required this.timestamp,
  });

  @override
  String toString() {
    return 'PerformanceMetric(operation: $operationName, duration: $duration, error: $isError)';
  }
}

/// Performance statistics for an operation
@internal
class PerformanceStats {
  final String operationName;
  final int count;
  final int errors;
  final Duration averageTime;
  final Duration minTime;
  final Duration maxTime;
  final Duration totalTime;
  final double errorRate;

  PerformanceStats({
    required this.operationName,
    required this.count,
    required this.errors,
    required this.averageTime,
    required this.minTime,
    required this.maxTime,
    required this.totalTime,
    required this.errorRate,
  });

  @override
  String toString() {
    return '''PerformanceStats(
      operation: $operationName,
      count: $count,
      errors: $errors,
      averageTime: $averageTime,
      minTime: $minTime,
      maxTime: $maxTime,
      totalTime: $totalTime,
      errorRate: ${(errorRate * 100).toStringAsFixed(2)}%
    )''';
  }
}

/// Global performance monitor instance
@internal
final performanceMonitor = PerformanceMonitor();
