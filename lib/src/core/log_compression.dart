import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'dart:typed_data';

import '../events/log_event.dart';
import '../enums/log_level.dart';

/// Log Compression for Strategic Logger
///
/// Provides efficient log compression to reduce network bandwidth
/// and storage requirements for high-volume logging scenarios.
class LogCompression {
  static LogCompression? _instance;
  static LogCompression get instance => _instance ??= LogCompression._();

  LogCompression._();

  // Compression configuration
  final int _batchSize = 100; // Compress logs in batches
  final Duration _compressionInterval = const Duration(seconds: 30);

  // Compression state
  final List<CompressibleLogEntry> _compressionBuffer = [];
  Timer? _compressionTimer;
  final StreamController<CompressedLogBatch> _compressionStreamController =
      StreamController<CompressedLogBatch>.broadcast();

  // Statistics
  int _totalLogsCompressed = 0;
  int _totalBytesCompressed = 0;
  int _totalBytesUncompressed = 0;
  double _compressionRatio = 0.0;

  /// Stream of compressed log batches
  Stream<CompressedLogBatch> get compressionStream =>
      _compressionStreamController.stream;

  /// Compression timer for testing
  Timer? get compressionTimer => _compressionTimer;

  /// Compression buffer for testing
  List<CompressibleLogEntry> get compressionBuffer => _compressionBuffer;

  /// Compress log batch for testing
  Future<CompressedLogBatch> compressLogBatch(
    List<CompressibleLogEntry> entries,
  ) => _compressLogBatch(entries);

  /// Calculate time range for testing
  Map<String, DateTime> calculateTimeRange(
    List<CompressibleLogEntry> entries,
  ) => _calculateTimeRange(entries);

  /// Update compression stats for testing
  void updateCompressionStats(CompressedLogBatch batch) =>
      _updateCompressionStats(batch);

  /// Starts the compression timer
  void startCompression() {
    if (_compressionTimer == null) {
      _compressionTimer = Timer.periodic(_compressionInterval, (_) {
        _compressBatch();
      });

      developer.log(
        'LogCompression started with ${_compressionInterval.inSeconds}s interval',
        name: 'LogCompression',
      );
    }
  }

  /// Stops the compression timer
  void stopCompression() {
    _compressionTimer?.cancel();
    _compressionTimer = null;

    // Compress any remaining logs
    if (_compressionBuffer.isNotEmpty) {
      _compressBatch();
    }

    developer.log('LogCompression stopped', name: 'LogCompression');
  }

  /// Adds a log entry to the compression buffer
  void addLogEntry(CompressibleLogEntry entry) {
    _compressionBuffer.add(entry);

    // Compress if buffer is full
    if (_compressionBuffer.length >= _batchSize) {
      _compressBatch();
    }
  }

  /// Compresses a batch of log entries
  Future<void> _compressBatch() async {
    if (_compressionBuffer.isEmpty) return;

    try {
      final batch = List<CompressibleLogEntry>.from(_compressionBuffer);
      _compressionBuffer.clear();

      final compressedBatch = await _compressLogBatch(batch);

      // Update statistics
      _updateCompressionStats(compressedBatch);

      // Emit compressed batch
      _compressionStreamController.add(compressedBatch);
    } catch (e) {
      developer.log(
        'Failed to compress log batch: $e',
        name: 'LogCompression',
        error: e,
      );
    }
  }

  /// Compresses a batch of log entries
  Future<CompressedLogBatch> _compressLogBatch(
    List<CompressibleLogEntry> entries,
  ) async {
    try {
      // Serialize log entries to JSON
      final jsonData = entries.map((entry) => entry.toJson()).toList();
      final jsonString = jsonEncode(jsonData);
      final uncompressedBytes = utf8.encode(jsonString);

      // Compress using gzip
      final compressedBytes = await _compressBytes(
        Uint8List.fromList(uncompressedBytes),
      );

      return CompressedLogBatch(
        id: _generateBatchId(),
        timestamp: DateTime.now(),
        logCount: entries.length,
        uncompressedSize: uncompressedBytes.length,
        compressedSize: compressedBytes.length,
        compressionRatio: compressedBytes.length / uncompressedBytes.length,
        compressedData: compressedBytes,
        logLevels: entries.map((e) => e.level).toSet().toList(),
        timeRange: _calculateTimeRange(entries),
      );
    } catch (e) {
      throw Exception('Failed to compress log batch: $e');
    }
  }

  /// Compresses bytes using gzip
  Future<Uint8List> _compressBytes(Uint8List data) async {
    try {
      // Use zlib compression (gzip-compatible)
      final compressed = gzip.encode(data);
      return Uint8List.fromList(compressed);
    } catch (e) {
      throw Exception('Failed to compress bytes: $e');
    }
  }

  /// Decompresses bytes using gzip
  Future<Uint8List> _decompressBytes(Uint8List compressedData) async {
    try {
      // Use zlib decompression (gzip-compatible)
      final decompressed = gzip.decode(compressedData);
      return Uint8List.fromList(decompressed);
    } catch (e) {
      throw Exception('Failed to decompress bytes: $e');
    }
  }

  /// Updates compression statistics
  void _updateCompressionStats(CompressedLogBatch batch) {
    _totalLogsCompressed += batch.logCount;
    _totalBytesCompressed += batch.compressedSize;
    _totalBytesUncompressed += batch.uncompressedSize;

    if (_totalBytesUncompressed > 0) {
      _compressionRatio = _totalBytesCompressed / _totalBytesUncompressed;
    }
  }

  /// Generates a unique batch ID
  String _generateBatchId() {
    return 'batch_${DateTime.now().millisecondsSinceEpoch}';
  }

  /// Calculates the time range for a batch of log entries
  Map<String, DateTime> _calculateTimeRange(
    List<CompressibleLogEntry> entries,
  ) {
    if (entries.isEmpty) {
      final now = DateTime.now();
      return {'start': now, 'end': now};
    }

    final timestamps = entries.map((e) => e.timestamp).toList();
    timestamps.sort();

    return {'start': timestamps.first, 'end': timestamps.last};
  }

  /// Compresses a single log entry
  Future<CompressedLogEntry> compressLogEntry(
    CompressibleLogEntry entry,
  ) async {
    try {
      final jsonString = jsonEncode(entry.toJson());
      final uncompressedBytes = utf8.encode(jsonString);
      final compressedBytes = await _compressBytes(
        Uint8List.fromList(uncompressedBytes),
      );

      return CompressedLogEntry(
        id: entry.id,
        timestamp: entry.timestamp,
        level: entry.level,
        uncompressedSize: uncompressedBytes.length,
        compressedSize: compressedBytes.length,
        compressionRatio: compressedBytes.length / uncompressedBytes.length,
        compressedData: compressedBytes,
      );
    } catch (e) {
      throw Exception('Failed to compress log entry: $e');
    }
  }

  /// Decompresses a compressed log entry
  Future<CompressibleLogEntry> decompressLogEntry(
    CompressedLogEntry entry,
  ) async {
    try {
      final decompressedBytes = await _decompressBytes(entry.compressedData);
      final jsonString = utf8.decode(decompressedBytes);
      final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;

      return CompressibleLogEntry.fromJson(jsonData);
    } catch (e) {
      throw Exception('Failed to decompress log entry: $e');
    }
  }

  /// Decompresses a compressed log batch
  Future<List<CompressibleLogEntry>> decompressLogBatch(
    CompressedLogBatch batch,
  ) async {
    try {
      final decompressedBytes = await _decompressBytes(batch.compressedData);
      final jsonString = utf8.decode(decompressedBytes);
      final jsonData = jsonDecode(jsonString) as List;

      return jsonData
          .map(
            (data) =>
                CompressibleLogEntry.fromJson(data as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      throw Exception('Failed to decompress log batch: $e');
    }
  }

  /// Gets compression statistics
  LogCompressionStats getStats() {
    return LogCompressionStats(
      totalLogsCompressed: _totalLogsCompressed,
      totalBytesCompressed: _totalBytesCompressed,
      totalBytesUncompressed: _totalBytesUncompressed,
      compressionRatio: _compressionRatio,
      compressionEfficiency: _compressionRatio > 0
          ? (1.0 - _compressionRatio) * 100
          : 0.0,
      bufferSize: _compressionBuffer.length,
      isRunning: _compressionTimer != null,
    );
  }

  /// Clears the compression buffer
  void clearBuffer() {
    _compressionBuffer.clear();

    developer.log('LogCompression buffer cleared', name: 'LogCompression');
  }

  /// Disposes the log compression
  void dispose() {
    stopCompression();
    _compressionStreamController.close();
    _instance = null;
  }
}

/// Compressible Log Entry
class CompressibleLogEntry {
  final String id;
  final DateTime timestamp;
  final LogLevel level;
  final String message;
  final Map<String, dynamic> context;
  final LogEvent? event;
  final String source;

  CompressibleLogEntry({
    required this.id,
    required this.timestamp,
    required this.level,
    required this.message,
    required this.context,
    this.event,
    required this.source,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'level': level.name,
      'message': message,
      'context': context,
      'event': event?.toMap(),
      'source': source,
    };
  }

  factory CompressibleLogEntry.fromJson(Map<String, dynamic> json) {
    return CompressibleLogEntry(
      id: json['id'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      level: LogLevel.values.firstWhere(
        (l) => l.name == json['level'],
        orElse: () => LogLevel.info,
      ),
      message: json['message'] as String,
      context: Map<String, dynamic>.from(json['context'] as Map),
      event: json['event'] != null
          ? LogEvent(
              eventName: json['event']['eventName'] as String? ?? '',
              eventMessage: json['event']['eventMessage'] as String? ?? '',
            )
          : null,
      source: json['source'] as String,
    );
  }
}

/// Compressed Log Entry
class CompressedLogEntry {
  final String id;
  final DateTime timestamp;
  final LogLevel level;
  final int uncompressedSize;
  final int compressedSize;
  final double compressionRatio;
  final Uint8List compressedData;

  CompressedLogEntry({
    required this.id,
    required this.timestamp,
    required this.level,
    required this.uncompressedSize,
    required this.compressedSize,
    required this.compressionRatio,
    required this.compressedData,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'level': level.name,
      'uncompressedSize': uncompressedSize,
      'compressedSize': compressedSize,
      'compressionRatio': compressionRatio,
      'compressedData': base64Encode(compressedData),
    };
  }

  factory CompressedLogEntry.fromJson(Map<String, dynamic> json) {
    return CompressedLogEntry(
      id: json['id'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      level: LogLevel.values.firstWhere(
        (l) => l.name == json['level'],
        orElse: () => LogLevel.info,
      ),
      uncompressedSize: json['uncompressedSize'] as int,
      compressedSize: json['compressedSize'] as int,
      compressionRatio: (json['compressionRatio'] as num).toDouble(),
      compressedData: base64Decode(json['compressedData'] as String),
    );
  }
}

/// Compressed Log Batch
class CompressedLogBatch {
  final String id;
  final DateTime timestamp;
  final int logCount;
  final int uncompressedSize;
  final int compressedSize;
  final double compressionRatio;
  final Uint8List compressedData;
  final List<LogLevel> logLevels;
  final Map<String, DateTime> timeRange;

  CompressedLogBatch({
    required this.id,
    required this.timestamp,
    required this.logCount,
    required this.uncompressedSize,
    required this.compressedSize,
    required this.compressionRatio,
    required this.compressedData,
    required this.logLevels,
    required this.timeRange,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'logCount': logCount,
      'uncompressedSize': uncompressedSize,
      'compressedSize': compressedSize,
      'compressionRatio': compressionRatio,
      'compressedData': base64Encode(compressedData),
      'logLevels': logLevels.map((l) => l.name).toList(),
      'timeRange': {
        'start': timeRange['start']!.toIso8601String(),
        'end': timeRange['end']!.toIso8601String(),
      },
    };
  }

  factory CompressedLogBatch.fromJson(Map<String, dynamic> json) {
    return CompressedLogBatch(
      id: json['id'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      logCount: json['logCount'] as int,
      uncompressedSize: json['uncompressedSize'] as int,
      compressedSize: json['compressedSize'] as int,
      compressionRatio: (json['compressionRatio'] as num).toDouble(),
      compressedData: base64Decode(json['compressedData'] as String),
      logLevels: (json['logLevels'] as List)
          .map(
            (l) => LogLevel.values.firstWhere(
              (level) => level.name == l,
              orElse: () => LogLevel.info,
            ),
          )
          .toList(),
      timeRange: {
        'start': DateTime.parse(json['timeRange']['start'] as String),
        'end': DateTime.parse(json['timeRange']['end'] as String),
      },
    );
  }
}

/// Log Compression Statistics
class LogCompressionStats {
  final int totalLogsCompressed;
  final int totalBytesCompressed;
  final int totalBytesUncompressed;
  final double compressionRatio;
  final double compressionEfficiency;
  final int bufferSize;
  final bool isRunning;

  LogCompressionStats({
    required this.totalLogsCompressed,
    required this.totalBytesCompressed,
    required this.totalBytesUncompressed,
    required this.compressionRatio,
    required this.compressionEfficiency,
    required this.bufferSize,
    required this.isRunning,
  });

  /// Space saved in bytes
  int get spaceSaved => totalBytesUncompressed - totalBytesCompressed;

  /// Space saved as percentage
  double get spaceSavedPercentage => totalBytesUncompressed > 0
      ? (spaceSaved / totalBytesUncompressed) * 100
      : 0.0;

  Map<String, dynamic> toJson() {
    return {
      'totalLogsCompressed': totalLogsCompressed,
      'totalBytesCompressed': totalBytesCompressed,
      'totalBytesUncompressed': totalBytesUncompressed,
      'compressionRatio': compressionRatio,
      'compressionEfficiency': compressionEfficiency,
      'bufferSize': bufferSize,
      'isRunning': isRunning,
      'spaceSaved': spaceSaved,
      'spaceSavedPercentage': spaceSavedPercentage,
    };
  }

  @override
  String toString() {
    return 'LogCompressionStats(logs: $totalLogsCompressed, efficiency: ${compressionEfficiency.toStringAsFixed(1)}%, space saved: ${spaceSavedPercentage.toStringAsFixed(1)}%)';
  }
}
