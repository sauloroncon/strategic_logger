import 'dart:typed_data';

import 'package:strategic_logger/logger.dart';
import 'package:test/test.dart';

/// Test suite for Log Compression functionality
void main() {
  group('Log Compression Tests', () {
    late LogCompression compression;

    setUp(() {
      compression = LogCompression.instance;
      compression.clearBuffer();
    });

    tearDown(() {
      compression.stopCompression();
      compression.clearBuffer();
    });

    test('Log Compression should be singleton', () {
      final compression1 = LogCompression.instance;
      final compression2 = LogCompression.instance;

      expect(compression1, equals(compression2));
    });

    test('Log Compression should start and stop correctly', () {
      expect(compression.getStats().isRunning, isFalse);

      compression.startCompression();
      expect(compression.getStats().isRunning, isTrue);

      compression.stopCompression();
      expect(compression.getStats().isRunning, isFalse);
    });

    test('Log Compression should not start twice', () {
      compression.startCompression();
      final firstTimer = compression.compressionTimer;

      compression.startCompression();
      expect(compression.compressionTimer, equals(firstTimer));
    });

    test('Log Compression should add log entries correctly', () {
      final logEntry = CompressibleLogEntry(
        id: 'test_1',
        timestamp: DateTime.now(),
        level: LogLevel.info,
        message: 'Test message',
        context: {'test': true},
        source: 'test',
      );

      compression.addLogEntry(logEntry);

      expect(compression.compressionBuffer.length, equals(1));
      expect(compression.compressionBuffer.first.id, equals('test_1'));
    });

    test('Log Compression should compress batch when buffer is full', () async {
      compression.startCompression();

      // Fill buffer to batch size (100)
      for (int i = 0; i < 100; i++) {
        final logEntry = CompressibleLogEntry(
          id: 'log_$i',
          timestamp: DateTime.now(),
          level: LogLevel.info,
          message: 'Test message $i',
          context: {'index': i},
          source: 'test',
        );
        compression.addLogEntry(logEntry);
      }

      // Buffer should be empty after compression
      expect(compression.compressionBuffer.length, equals(0));
    });

    test(
      'Log Compression should compress single log entry correctly',
      () async {
        final logEntry = CompressibleLogEntry(
          id: 'test_entry',
          timestamp: DateTime.now(),
          level: LogLevel.info,
          message: 'Test message for compression',
          context: {'test': true, 'compression': 'test'},
          source: 'test',
        );

        final compressedEntry = await compression.compressLogEntry(logEntry);

        expect(compressedEntry, isNotNull);
        expect(compressedEntry.id, equals('test_entry'));
        expect(compressedEntry.level, equals(LogLevel.info));
        expect(
          compressedEntry.compressedSize,
          lessThan(compressedEntry.uncompressedSize),
        );
        expect(compressedEntry.compressionRatio, lessThan(1.0));
      },
    );

    test('Log Compression should decompress log entry correctly', () async {
      final originalEntry = CompressibleLogEntry(
        id: 'test_entry',
        timestamp: DateTime.now(),
        level: LogLevel.info,
        message: 'Test message for compression',
        context: {'test': true, 'compression': 'test'},
        source: 'test',
      );

      final compressedEntry = await compression.compressLogEntry(originalEntry);
      final decompressedEntry = await compression.decompressLogEntry(
        compressedEntry,
      );

      expect(decompressedEntry.id, equals(originalEntry.id));
      expect(decompressedEntry.level, equals(originalEntry.level));
      expect(decompressedEntry.message, equals(originalEntry.message));
      expect(decompressedEntry.context, equals(originalEntry.context));
      expect(decompressedEntry.source, equals(originalEntry.source));
    });

    test(
      'Log Compression should compress and decompress batch correctly',
      () async {
        final originalEntries = <CompressibleLogEntry>[];

        for (int i = 0; i < 5; i++) {
          final entry = CompressibleLogEntry(
            id: 'batch_$i',
            timestamp: DateTime.now(),
            level: LogLevel.info,
            message: 'Batch message $i',
            context: {'batch': true, 'index': i},
            source: 'test',
          );
          originalEntries.add(entry);
        }

        // Compress batch
        final compressedBatch = await compression.compressLogBatch(
          originalEntries,
        );

        expect(compressedBatch, isNotNull);
        expect(compressedBatch.logCount, equals(5));
        expect(
          compressedBatch.compressedSize,
          lessThan(compressedBatch.uncompressedSize),
        );
        expect(compressedBatch.compressionRatio, lessThan(1.0));

        // Decompress batch
        final decompressedEntries = await compression.decompressLogBatch(
          compressedBatch,
        );

        expect(decompressedEntries.length, equals(5));
        for (int i = 0; i < 5; i++) {
          expect(decompressedEntries[i].id, equals('batch_$i'));
          expect(decompressedEntries[i].message, equals('Batch message $i'));
          expect(decompressedEntries[i].context['index'], equals(i));
        }
      },
    );

    test('Log Compression should calculate time range correctly', () {
      final entries = <CompressibleLogEntry>[];
      final baseTime = DateTime(2024, 1, 1, 12, 0, 0);

      for (int i = 0; i < 5; i++) {
        final entry = CompressibleLogEntry(
          id: 'time_$i',
          timestamp: baseTime.add(Duration(minutes: i)),
          level: LogLevel.info,
          message: 'Message $i',
          context: {},
          source: 'test',
        );
        entries.add(entry);
      }

      final timeRange = compression.calculateTimeRange(entries);

      expect(timeRange['start'], equals(baseTime));
      expect(timeRange['end'], equals(baseTime.add(Duration(minutes: 4))));
    });

    test('Log Compression should handle empty time range correctly', () {
      final timeRange = compression.calculateTimeRange([]);

      expect(timeRange['start'], isNotNull);
      expect(timeRange['end'], isNotNull);
      expect(timeRange['start'], equals(timeRange['end']));
    });

    test('Log Compression should update statistics correctly', () {
      final initialStats = compression.getStats();

      // Create a mock compressed batch
      final compressedBatch = CompressedLogBatch(
        id: 'test_batch',
        timestamp: DateTime.now(),
        logCount: 10,
        uncompressedSize: 1000,
        compressedSize: 300,
        compressionRatio: 0.3,
        compressedData: Uint8List.fromList([1, 2, 3, 4, 5]),
        logLevels: [LogLevel.info, LogLevel.error],
        timeRange: {
          'start': DateTime.now().subtract(Duration(hours: 1)),
          'end': DateTime.now(),
        },
      );

      compression.updateCompressionStats(compressedBatch);

      final updatedStats = compression.getStats();
      expect(
        updatedStats.totalLogsCompressed,
        equals(initialStats.totalLogsCompressed + 10),
      );
      expect(
        updatedStats.totalBytesCompressed,
        equals(initialStats.totalBytesCompressed + 300),
      );
      expect(
        updatedStats.totalBytesUncompressed,
        equals(initialStats.totalBytesUncompressed + 1000),
      );
      expect(updatedStats.compressionRatio, equals(0.3));
    });

    test('Log Compression should provide correct statistics', () {
      compression.startCompression();

      final stats = compression.getStats();

      expect(stats.totalLogsCompressed, isA<int>());
      expect(stats.totalBytesCompressed, isA<int>());
      expect(stats.totalBytesUncompressed, isA<int>());
      expect(stats.compressionRatio, isA<double>());
      expect(stats.compressionEfficiency, isA<double>());
      expect(stats.bufferSize, isA<int>());
      expect(stats.isRunning, isTrue);
      expect(stats.spaceSaved, isA<int>());
      expect(stats.spaceSavedPercentage, isA<double>());
    });

    test('Log Compression should clear buffer correctly', () {
      // Add some entries
      for (int i = 0; i < 5; i++) {
        final logEntry = CompressibleLogEntry(
          id: 'clear_$i',
          timestamp: DateTime.now(),
          level: LogLevel.info,
          message: 'Clear test $i',
          context: {},
          source: 'test',
        );
        compression.addLogEntry(logEntry);
      }

      expect(compression.compressionBuffer.length, equals(5));

      compression.clearBuffer();

      expect(compression.compressionBuffer.length, equals(0));
    });

    group('CompressibleLogEntry Tests', () {
      test('CompressibleLogEntry should serialize to JSON correctly', () {
        final logEntry = CompressibleLogEntry(
          id: 'test_id',
          timestamp: DateTime(2024, 1, 1, 12, 0, 0),
          level: LogLevel.info,
          message: 'Test message',
          context: {'key': 'value'},
          source: 'test_source',
        );

        final json = logEntry.toJson();

        expect(json['id'], equals('test_id'));
        expect(json['level'], equals('info'));
        expect(json['message'], equals('Test message'));
        expect(json['context'], equals({'key': 'value'}));
        expect(json['source'], equals('test_source'));
      });

      test('CompressibleLogEntry should deserialize from JSON correctly', () {
        final json = {
          'id': 'test_id',
          'timestamp': '2024-01-01T12:00:00.000Z',
          'level': 'info',
          'message': 'Test message',
          'context': {'key': 'value'},
          'source': 'test_source',
        };

        final logEntry = CompressibleLogEntry.fromJson(json);

        expect(logEntry.id, equals('test_id'));
        expect(logEntry.level, equals(LogLevel.info));
        expect(logEntry.message, equals('Test message'));
        expect(logEntry.context, equals({'key': 'value'}));
        expect(logEntry.source, equals('test_source'));
      });
    });

    group('CompressedLogEntry Tests', () {
      test('CompressedLogEntry should serialize to JSON correctly', () {
        final compressedEntry = CompressedLogEntry(
          id: 'compressed_id',
          timestamp: DateTime(2024, 1, 1, 12, 0, 0),
          level: LogLevel.info,
          uncompressedSize: 1000,
          compressedSize: 300,
          compressionRatio: 0.3,
          compressedData: Uint8List.fromList([1, 2, 3, 4, 5]),
        );

        final json = compressedEntry.toJson();

        expect(json['id'], equals('compressed_id'));
        expect(json['level'], equals('info'));
        expect(json['uncompressedSize'], equals(1000));
        expect(json['compressedSize'], equals(300));
        expect(json['compressionRatio'], equals(0.3));
        expect(json['compressedData'], isA<String>()); // Base64 encoded
      });

      test('CompressedLogEntry should deserialize from JSON correctly', () {
        final json = {
          'id': 'compressed_id',
          'timestamp': '2024-01-01T12:00:00.000Z',
          'level': 'info',
          'uncompressedSize': 1000,
          'compressedSize': 300,
          'compressionRatio': 0.3,
          'compressedData': 'AQIDBAU=', // Base64 for [1,2,3,4,5]
        };

        final compressedEntry = CompressedLogEntry.fromJson(json);

        expect(compressedEntry.id, equals('compressed_id'));
        expect(compressedEntry.level, equals(LogLevel.info));
        expect(compressedEntry.uncompressedSize, equals(1000));
        expect(compressedEntry.compressedSize, equals(300));
        expect(compressedEntry.compressionRatio, equals(0.3));
        expect(
          compressedEntry.compressedData,
          equals(Uint8List.fromList([1, 2, 3, 4, 5])),
        );
      });
    });

    group('CompressedLogBatch Tests', () {
      test('CompressedLogBatch should serialize to JSON correctly', () {
        final compressedBatch = CompressedLogBatch(
          id: 'batch_id',
          timestamp: DateTime(2024, 1, 1, 12, 0, 0),
          logCount: 10,
          uncompressedSize: 5000,
          compressedSize: 1500,
          compressionRatio: 0.3,
          compressedData: Uint8List.fromList([1, 2, 3, 4, 5]),
          logLevels: [LogLevel.info, LogLevel.error],
          timeRange: {
            'start': DateTime(2024, 1, 1, 11, 0, 0),
            'end': DateTime(2024, 1, 1, 12, 0, 0),
          },
        );

        final json = compressedBatch.toJson();

        expect(json['id'], equals('batch_id'));
        expect(json['logCount'], equals(10));
        expect(json['uncompressedSize'], equals(5000));
        expect(json['compressedSize'], equals(1500));
        expect(json['compressionRatio'], equals(0.3));
        expect(json['logLevels'], equals(['info', 'error']));
        expect(json['timeRange'], isA<Map<String, String>>());
      });

      test('CompressedLogBatch should deserialize from JSON correctly', () {
        final json = {
          'id': 'batch_id',
          'timestamp': '2024-01-01T12:00:00.000Z',
          'logCount': 10,
          'uncompressedSize': 5000,
          'compressedSize': 1500,
          'compressionRatio': 0.3,
          'compressedData': 'AQIDBAU=',
          'logLevels': ['info', 'error'],
          'timeRange': {
            'start': '2024-01-01T11:00:00.000Z',
            'end': '2024-01-01T12:00:00.000Z',
          },
        };

        final compressedBatch = CompressedLogBatch.fromJson(json);

        expect(compressedBatch.id, equals('batch_id'));
        expect(compressedBatch.logCount, equals(10));
        expect(compressedBatch.uncompressedSize, equals(5000));
        expect(compressedBatch.compressedSize, equals(1500));
        expect(compressedBatch.compressionRatio, equals(0.3));
        expect(
          compressedBatch.logLevels,
          equals([LogLevel.info, LogLevel.error]),
        );
        expect(
          compressedBatch.timeRange['start'],
          equals(DateTime(2024, 1, 1, 11, 0, 0)),
        );
        expect(
          compressedBatch.timeRange['end'],
          equals(DateTime(2024, 1, 1, 12, 0, 0)),
        );
      });
    });

    group('LogCompressionStats Tests', () {
      test('LogCompressionStats should calculate space saved correctly', () {
        final stats = LogCompressionStats(
          totalLogsCompressed: 100,
          totalBytesCompressed: 3000,
          totalBytesUncompressed: 10000,
          compressionRatio: 0.3,
          compressionEfficiency: 70.0,
          bufferSize: 5,
          isRunning: true,
        );

        expect(stats.spaceSaved, equals(7000)); // 10000 - 3000
        expect(
          stats.spaceSavedPercentage,
          equals(70.0),
        ); // (7000 / 10000) * 100
      });

      test('LogCompressionStats should serialize to JSON correctly', () {
        final stats = LogCompressionStats(
          totalLogsCompressed: 100,
          totalBytesCompressed: 3000,
          totalBytesUncompressed: 10000,
          compressionRatio: 0.3,
          compressionEfficiency: 70.0,
          bufferSize: 5,
          isRunning: true,
        );

        final json = stats.toJson();

        expect(json['totalLogsCompressed'], equals(100));
        expect(json['totalBytesCompressed'], equals(3000));
        expect(json['totalBytesUncompressed'], equals(10000));
        expect(json['compressionRatio'], equals(0.3));
        expect(json['compressionEfficiency'], equals(70.0));
        expect(json['bufferSize'], equals(5));
        expect(json['isRunning'], isTrue);
        expect(json['spaceSaved'], equals(7000));
        expect(json['spaceSavedPercentage'], equals(70.0));
      });

      test(
        'LogCompressionStats toString should return correct representation',
        () {
          final stats = LogCompressionStats(
            totalLogsCompressed: 100,
            totalBytesCompressed: 3000,
            totalBytesUncompressed: 10000,
            compressionRatio: 0.3,
            compressionEfficiency: 70.0,
            bufferSize: 5,
            isRunning: true,
          );

          final string = stats.toString();

          expect(string, contains('LogCompressionStats'));
          expect(string, contains('logs: 100'));
          expect(string, contains('efficiency: 70.0%'));
          expect(string, contains('space saved: 70.0%'));
        },
      );
    });
  });
}
