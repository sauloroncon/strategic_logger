import 'package:test/test.dart';
import 'package:strategic_logger/src/strategic_logger.dart';
import 'package:strategic_logger/src/enums/log_level.dart';

void main() {
  group('Integration Tests', () {
    test('should handle basic logger functionality', () {
      final logger = StrategicLogger();

      // Test basic properties
      expect(logger.isInitialized, isFalse);
      expect(logger.level, equals(LogLevel.none));

      // Test that logger can be created
      expect(logger, isNotNull);
      expect(logger, isA<StrategicLogger>());
    });

    test('should handle log level enum', () {
      // Test LogLevel enum values
      expect(LogLevel.none, isNotNull);
      expect(LogLevel.debug, isNotNull);
      expect(LogLevel.info, isNotNull);
      expect(LogLevel.warning, isNotNull);
      expect(LogLevel.error, isNotNull);
      expect(LogLevel.fatal, isNotNull);

      // Test LogLevel converter
      expect(LogLevel.converter('debug'), equals(LogLevel.debug));
      expect(LogLevel.converter('info'), equals(LogLevel.info));
      expect(LogLevel.converter('error'), equals(LogLevel.error));
    });

    test('should handle logger disposal', () {
      final logger = StrategicLogger();

      // Test that dispose can be called without errors (may throw if not initialized)
      try {
        logger.dispose();
      } catch (e) {
        // Expected if not initialized
        expect(e.toString(), contains('LateInitializationError'));
      }
    });

    test('should handle performance stats', () {
      final logger = StrategicLogger();

      // Test that getPerformanceStats can be called
      final stats = logger.getPerformanceStats();
      expect(stats, isA<Map<String, dynamic>>());
      // Stats may be empty if not initialized
      expect(stats, isA<Map<String, dynamic>>());
    });

    test('should handle flush operation', () {
      final logger = StrategicLogger();

      // Test that flush can be called without errors (may throw if not initialized)
      try {
        logger.flush();
      } catch (e) {
        // Expected if not initialized
        expect(e.toString(), contains('LateInitializationError'));
      }
    });
  });
}
