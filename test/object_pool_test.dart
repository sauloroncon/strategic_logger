import 'package:strategic_logger/logger.dart';
import 'package:test/test.dart';

/// Test suite for Object Pool functionality
void main() {
  group('Object Pool Tests', () {
    late ObjectPool objectPool;

    setUp(() {
      objectPool = ObjectPool.instance;
      objectPool.clear();
    });

    tearDown(() {
      objectPool.clear();
    });

    test('Object Pool should be singleton', () {
      final pool1 = ObjectPool.instance;
      final pool2 = ObjectPool.instance;

      expect(pool1, equals(pool2));
    });

    test('Object Pool should initialize correctly', () {
      objectPool.initialize();

      final stats = objectPool.getStats();
      expect(stats.logEntryPoolSize, equals(100));
      expect(stats.logEventPoolSize, equals(100));
      expect(stats.stringBufferPoolSize, equals(100));
      expect(stats.contextMapPoolSize, equals(100));
    });

    test('Object Pool should get and return LogEntry correctly', () {
      objectPool.initialize();

      final initialStats = objectPool.getStats();

      // Get LogEntry from pool
      final logEntry = objectPool.getLogEntry(
        level: LogLevel.info,
        message: 'Test message',
        timestamp: DateTime.now(),
        context: {'test': true},
      );

      expect(logEntry, isNotNull);
      expect(logEntry.level, equals(LogLevel.info));
      expect(logEntry.message, equals('Test message'));
      expect(logEntry.context, equals({'test': true}));

      // Verify pool size decreased
      final afterGetStats = objectPool.getStats();
      expect(
        afterGetStats.logEntryPoolSize,
        equals(initialStats.logEntryPoolSize - 1),
      );
      expect(afterGetStats.logEntryReuses, equals(1));

      // Return LogEntry to pool
      objectPool.returnLogEntry(logEntry);

      // Verify pool size increased
      final afterReturnStats = objectPool.getStats();
      expect(
        afterReturnStats.logEntryPoolSize,
        equals(initialStats.logEntryPoolSize),
      );
    });

    test('Object Pool should get and return LogEvent correctly', () {
      objectPool.initialize();

      final initialStats = objectPool.getStats();

      // Get LogEvent from pool
      final logEvent = objectPool.getLogEvent(
        eventName: 'TEST_EVENT',
        eventMessage: 'Test event message',
        timestamp: DateTime.now(),
        context: {'test': true},
      );

      expect(logEvent, isNotNull);
      expect(logEvent.eventName, equals('TEST_EVENT'));
      expect(logEvent.eventMessage, equals('Test event message'));
      expect(logEvent.context, equals({'test': true}));

      // Verify pool size decreased
      final afterGetStats = objectPool.getStats();
      expect(
        afterGetStats.logEventPoolSize,
        equals(initialStats.logEventPoolSize - 1),
      );
      expect(afterGetStats.logEventReuses, equals(1));

      // Return LogEvent to pool
      objectPool.returnLogEvent(logEvent);

      // Verify pool size increased
      final afterReturnStats = objectPool.getStats();
      expect(
        afterReturnStats.logEventPoolSize,
        equals(initialStats.logEventPoolSize),
      );
    });

    test('Object Pool should get and return StringBuffer correctly', () {
      objectPool.initialize();

      final initialStats = objectPool.getStats();

      // Get StringBuffer from pool
      final stringBuffer = objectPool.getStringBuffer();

      expect(stringBuffer, isNotNull);
      expect(stringBuffer.length, equals(0)); // Should be cleared

      // Use the buffer
      stringBuffer.write('Test content');
      expect(stringBuffer.toString(), equals('Test content'));

      // Verify pool size decreased
      final afterGetStats = objectPool.getStats();
      expect(
        afterGetStats.stringBufferPoolSize,
        equals(initialStats.stringBufferPoolSize - 1),
      );
      expect(afterGetStats.stringBufferReuses, equals(1));

      // Return StringBuffer to pool
      objectPool.returnStringBuffer(stringBuffer);

      // Verify pool size increased and buffer is cleared
      final afterReturnStats = objectPool.getStats();
      expect(
        afterReturnStats.stringBufferPoolSize,
        equals(initialStats.stringBufferPoolSize),
      );
      expect(stringBuffer.length, equals(0)); // Should be cleared
    });

    test('Object Pool should get and return context Map correctly', () {
      objectPool.initialize();

      final initialStats = objectPool.getStats();

      // Get context Map from pool
      final contextMap = objectPool.getContextMap();

      expect(contextMap, isNotNull);
      expect(contextMap.length, equals(0)); // Should be cleared

      // Use the map
      contextMap['key'] = 'value';
      expect(contextMap['key'], equals('value'));

      // Verify pool size decreased
      final afterGetStats = objectPool.getStats();
      expect(
        afterGetStats.contextMapPoolSize,
        equals(initialStats.contextMapPoolSize - 1),
      );
      expect(afterGetStats.contextMapReuses, equals(1));

      // Return context Map to pool
      objectPool.returnContextMap(contextMap);

      // Verify pool size increased and map is cleared
      final afterReturnStats = objectPool.getStats();
      expect(
        afterReturnStats.contextMapPoolSize,
        equals(initialStats.contextMapPoolSize),
      );
      expect(contextMap.length, equals(0)); // Should be cleared
    });

    test('Object Pool should create new objects when pool is empty', () {
      // Don't initialize pool
      final initialStats = objectPool.getStats();
      expect(initialStats.logEntryPoolSize, equals(0));

      // Get LogEntry when pool is empty
      final logEntry = objectPool.getLogEntry(
        level: LogLevel.info,
        message: 'Test message',
        timestamp: DateTime.now(),
      );

      expect(logEntry, isNotNull);

      // Verify allocation count increased
      final afterGetStats = objectPool.getStats();
      expect(
        afterGetStats.logEntryAllocations,
        equals(initialStats.logEntryAllocations + 1),
      );
    });

    test('Object Pool should respect max pool size', () {
      objectPool.initialize();

      // Fill pool beyond max size
      final logEntries = <LogEntry>[];
      for (int i = 0; i < 100; i++) {
        final entry = objectPool.getLogEntry(
          level: LogLevel.info,
          message: 'Test $i',
          timestamp: DateTime.now(),
        );
        logEntries.add(entry);
      }

      // Return all entries
      for (final entry in logEntries) {
        objectPool.returnLogEntry(entry);
      }

      // Pool should not exceed max size
      final stats = objectPool.getStats();
      expect(stats.logEntryPoolSize, lessThanOrEqualTo(1000));
    });

    test('Object Pool should provide correct statistics', () {
      objectPool.initialize();

      // Get some objects
      final logEntry = objectPool.getLogEntry(
        level: LogLevel.info,
        message: 'Test',
        timestamp: DateTime.now(),
      );
      final logEvent = objectPool.getLogEvent(
        eventName: 'TEST',
        eventMessage: 'Test',
        timestamp: DateTime.now(),
      );

      final stats = objectPool.getStats();

      expect(stats.totalAllocations, greaterThan(0));
      expect(stats.totalReuses, greaterThan(0));
      expect(stats.reuseRate, greaterThan(0));
      expect(stats.efficiencyScore, greaterThan(0));
      expect(stats.efficiencyScore, lessThanOrEqualTo(1.0));

      // Return objects
      objectPool.returnLogEntry(logEntry);
      objectPool.returnLogEvent(logEvent);
    });

    test('Object Pool should clear correctly', () {
      objectPool.initialize();

      expect(objectPool.getStats().logEntryPoolSize, greaterThan(0));

      objectPool.clear();

      expect(objectPool.getStats().logEntryPoolSize, equals(0));
      expect(objectPool.getStats().logEventPoolSize, equals(0));
      expect(objectPool.getStats().stringBufferPoolSize, equals(0));
      expect(objectPool.getStats().contextMapPoolSize, equals(0));
    });

    group('Pooled LogEntry Tests', () {
      test('Pooled LogEntry should reset correctly', () {
        objectPool.initialize();

        final logEntry = objectPool.getLogEntry(
          level: LogLevel.info,
          message: 'Original message',
          timestamp: DateTime.now(),
          context: {'original': true},
        );

        // Return to pool
        objectPool.returnLogEntry(logEntry);

        // Get again and verify reset
        final newLogEntry = objectPool.getLogEntry(
          level: LogLevel.error,
          message: 'New message',
          timestamp: DateTime.now(),
          context: {'new': true},
        );

        expect(newLogEntry.level, equals(LogLevel.error));
        expect(newLogEntry.message, equals('New message'));
        expect(newLogEntry.context, equals({'new': true}));
      });

      test('Pooled LogEntry should serialize to JSON correctly', () {
        objectPool.initialize();

        final logEntry = objectPool.getLogEntry(
          level: LogLevel.info,
          message: 'Test message',
          timestamp: DateTime(2024, 1, 1, 12, 0, 0),
          context: {'test': true},
        );

        final json = logEntry.toJson();

        expect(json['level'], equals('info'));
        expect(json['message'], equals('Test message'));
        expect(json['context'], equals({'test': true}));
      });

      test('Pooled LogEntry should return to pool correctly', () {
        objectPool.initialize();

        final logEntry = objectPool.getLogEntry(
          level: LogLevel.info,
          message: 'Test',
          timestamp: DateTime.now(),
        );

        final initialPoolSize = objectPool.getStats().logEntryPoolSize;

        logEntry.returnToPool();

        expect(
          objectPool.getStats().logEntryPoolSize,
          equals(initialPoolSize + 1),
        );
      });
    });

    group('Pooled LogEvent Tests', () {
      test('Pooled LogEvent should reset correctly', () {
        objectPool.initialize();

        final logEvent = objectPool.getLogEvent(
          eventName: 'ORIGINAL_EVENT',
          eventMessage: 'Original message',
          timestamp: DateTime.now(),
          context: {'original': true},
        );

        // Return to pool
        objectPool.returnLogEvent(logEvent);

        // Get again and verify reset
        final newLogEvent = objectPool.getLogEvent(
          eventName: 'NEW_EVENT',
          eventMessage: 'New message',
          timestamp: DateTime.now(),
          context: {'new': true},
        );

        expect(newLogEvent.eventName, equals('NEW_EVENT'));
        expect(newLogEvent.eventMessage, equals('New message'));
        expect(newLogEvent.context, equals({'new': true}));
      });

      test('Pooled LogEvent should serialize to Map correctly', () {
        objectPool.initialize();

        final logEvent = objectPool.getLogEvent(
          eventName: 'TEST_EVENT',
          eventMessage: 'Test message',
          timestamp: DateTime(2024, 1, 1, 12, 0, 0),
          context: {'test': true},
        );

        final map = logEvent.toMap();

        expect(map['eventName'], equals('TEST_EVENT'));
        expect(map['eventMessage'], equals('Test message'));
        expect(map['context'], equals({'test': true}));
      });

      test('Pooled LogEvent should return to pool correctly', () {
        objectPool.initialize();

        final logEvent = objectPool.getLogEvent(
          eventName: 'TEST',
          eventMessage: 'Test',
          timestamp: DateTime.now(),
        );

        final initialPoolSize = objectPool.getStats().logEventPoolSize;

        logEvent.returnToPool();

        expect(
          objectPool.getStats().logEventPoolSize,
          equals(initialPoolSize + 1),
        );
      });
    });

    group('ObjectPoolStats Tests', () {
      test('ObjectPoolStats should calculate totals correctly', () {
        final stats = ObjectPoolStats(
          logEntryPoolSize: 10,
          logEntryAllocations: 5,
          logEntryReuses: 15,
          logEventPoolSize: 8,
          logEventAllocations: 3,
          logEventReuses: 12,
          stringBufferPoolSize: 6,
          stringBufferAllocations: 2,
          stringBufferReuses: 8,
          contextMapPoolSize: 4,
          contextMapAllocations: 1,
          contextMapReuses: 6,
        );

        expect(stats.totalAllocations, equals(11)); // 5+3+2+1
        expect(stats.totalReuses, equals(41)); // 15+12+8+6
        expect(stats.reuseRate, equals(41 / (11 + 41)));
        expect(stats.efficiencyScore, equals(41 / (11 + 41)));
      });

      test('ObjectPoolStats should serialize to JSON correctly', () {
        final stats = ObjectPoolStats(
          logEntryPoolSize: 10,
          logEntryAllocations: 5,
          logEntryReuses: 15,
          logEventPoolSize: 8,
          logEventAllocations: 3,
          logEventReuses: 12,
          stringBufferPoolSize: 6,
          stringBufferAllocations: 2,
          stringBufferReuses: 8,
          contextMapPoolSize: 4,
          contextMapAllocations: 1,
          contextMapReuses: 6,
        );

        final json = stats.toJson();

        expect(json['logEntryPoolSize'], equals(10));
        expect(json['totalAllocations'], equals(11));
        expect(json['totalReuses'], equals(41));
        expect(json['reuseRate'], isA<double>());
        expect(json['efficiencyScore'], isA<double>());
      });

      test('ObjectPoolStats toString should return correct representation', () {
        final stats = ObjectPoolStats(
          logEntryPoolSize: 10,
          logEntryAllocations: 5,
          logEntryReuses: 15,
          logEventPoolSize: 8,
          logEventAllocations: 3,
          logEventReuses: 12,
          stringBufferPoolSize: 6,
          stringBufferAllocations: 2,
          stringBufferReuses: 8,
          contextMapPoolSize: 4,
          contextMapAllocations: 1,
          contextMapReuses: 6,
        );

        final string = stats.toString();

        expect(string, contains('ObjectPoolStats'));
        expect(string, contains('allocations: 11'));
        expect(string, contains('reuses: 41'));
        expect(string, contains('efficiency:'));
      });
    });
  });
}
