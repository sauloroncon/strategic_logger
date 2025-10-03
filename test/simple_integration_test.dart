import 'dart:io';
import 'dart:math';
import 'package:test/test.dart';
import 'package:strategic_logger/src/strategic_logger.dart';
import 'package:strategic_logger/src/strategies/console/console_log_strategy.dart';

void main() {
  group('Simple Integration Tests', () {
    late StrategicLogger logger;
    late ConsoleLogStrategy consoleStrategy;

    setUp(() {
      logger = StrategicLogger();
      consoleStrategy = ConsoleLogStrategy(
        useModernFormatting: true,
        useColors: true,
        useEmojis: true,
        showTimestamp: true,
        showContext: true,
      );
    });

    tearDown(() {
      logger.dispose();
    });

    group('Multi-Strategy Integration', () {
      test('should integrate multiple strategies seamlessly', () async {
        // Initialize with multiple strategies
        await logger.initialize(
          strategies: [consoleStrategy],
          useIsolates: true,
          enablePerformanceMonitoring: true,
          enableModernConsole: true,
        );

        // Test logging with different levels
        await logger.debug('Debug message for integration test');
        await logger.info('Info message for integration test');
        await logger.warning('Warning message for integration test');
        await logger.error('Error message for integration test');
        await logger.fatal('Fatal message for integration test');

        // Verify all strategies received the logs
        final stats = logger.getPerformanceStats();
        expect(stats['totalLogs'], equals(5));
        expect(stats['debugCount'], equals(1));
        expect(stats['infoCount'], equals(1));
        expect(stats['warningCount'], equals(1));
        expect(stats['errorCount'], equals(1));
        expect(stats['fatalCount'], equals(1));
      });

      test('should handle strategy failures gracefully', () async {
        await logger.initialize(
          strategies: [consoleStrategy],
          useIsolates: true,
          enablePerformanceMonitoring: true,
          enableModernConsole: true,
        );

        // Log messages that might cause strategy failures
        for (int i = 0; i < 10; i++) {
          await logger.info(
            'Integration test message $i',
            context: <String, Object>{
              'iteration': i,
              'complexData': List.generate(100, (index) => 'data_$index'),
            },
          );
        }

        final stats = logger.getPerformanceStats();
        expect(stats['totalLogs'], equals(10));
        expect(stats['errorCount'], equals(0)); // Should not have errors
      });
    });

    group('Isolate Integration', () {
      test('should integrate isolates with logging strategies', () async {
        await logger.initialize(
          strategies: [consoleStrategy],
          useIsolates: true,
          enablePerformanceMonitoring: true,
          enableModernConsole: true,
        );

        // Generate logs that will use isolates for processing
        final futures = <Future>[];
        for (int i = 0; i < 50; i++) {
          futures.add(Future(() async {
            await logger.info(
              'Isolate integration test $i',
              context: <String, Object>{
                'iteration': i,
                'heavyData': List.generate(1000, (index) => 'heavy_data_$index'),
              },
            );
          }));
        }

        await Future.wait(futures);
        logger.flush();

        final stats = logger.getPerformanceStats();
        expect(stats['totalLogs'], equals(50));
        expect(stats['isolateOperations'], greaterThan(0));
      });

      test('should fallback gracefully when isolates fail', () async {
        await logger.initialize(
          strategies: [consoleStrategy],
          useIsolates: true,
          enablePerformanceMonitoring: true,
          enableModernConsole: true,
        );

        // Generate logs that might overwhelm isolates
        for (int i = 0; i < 100; i++) {
          await logger.info(
            'Isolate fallback test $i',
            context: <String, Object>{
              'iteration': i,
              'massiveData': List.generate(10000, (index) => 'massive_data_$index'),
            },
          );
        }

        final stats = logger.getPerformanceStats();
        expect(stats['totalLogs'], equals(100));
        expect(stats['fallbackOperations'], greaterThan(0));
      });
    });

    group('Performance Monitoring Integration', () {
      test('should integrate performance monitoring with all operations', () async {
        await logger.initialize(
          strategies: [consoleStrategy],
          useIsolates: true,
          enablePerformanceMonitoring: true,
          enableModernConsole: true,
        );

        // Perform various operations
        for (int i = 0; i < 100; i++) {
          await logger.info(
            'Performance monitoring test $i',
            context: <String, Object>{
              'iteration': i,
              'performance': 'test',
            },
          );
        }

        final stats = logger.getPerformanceStats();
        expect(stats['totalLogs'], equals(100));
        expect(stats['averageProcessingTime'], greaterThan(0));
        expect(stats['maxProcessingTime'], greaterThan(0));
        expect(stats['memoryUsage'], greaterThan(0));
      });

      test('should track memory usage across operations', () async {
        await logger.initialize(
          strategies: [consoleStrategy],
          useIsolates: true,
          enablePerformanceMonitoring: true,
          enableModernConsole: true,
        );

        final initialMemory = ProcessInfo.currentRss;

        // Generate logs with varying memory usage
        for (int i = 0; i < 50; i++) {
          await logger.info(
            'Memory tracking test $i',
            context: <String, Object>{
              'iteration': i,
              'data': List.generate(i * 100, (index) => 'memory_data_$index'),
            },
          );
        }

        final finalMemory = ProcessInfo.currentRss;
        final memoryIncrease = finalMemory - initialMemory;

        final stats = logger.getPerformanceStats();
        expect(stats['totalLogs'], equals(50));
        expect(stats['memoryUsage'], greaterThan(0));
        expect(memoryIncrease, lessThan(100 * 1024 * 1024)); // Should not increase by more than 100MB
      });
    });

    group('Context Integration', () {
      test('should handle complex context structures', () async {
        await logger.initialize(
          strategies: [consoleStrategy],
          useIsolates: true,
          enablePerformanceMonitoring: true,
          enableModernConsole: true,
        );

        // Test with complex nested context
        for (int i = 0; i < 20; i++) {
          final complexContext = <String, Object>{
            'user': <String, Object>{
              'id': 'user_$i',
              'profile': <String, Object>{
                'name': 'User $i',
                'settings': <String, Object>{
                  'theme': 'dark',
                  'notifications': true,
                  'preferences': <String, Object>{
                    'language': 'en',
                    'timezone': 'UTC',
                  },
                },
              },
            },
            'session': <String, Object>{
              'id': 'session_$i',
              'startTime': DateTime.now().millisecondsSinceEpoch,
              'metadata': <String, Object>{
                'device': 'mobile',
                'version': '1.0.0',
                'features': ['feature1', 'feature2', 'feature3'],
              },
            },
            'operation': <String, Object>{
              'type': 'user_action',
              'category': 'navigation',
              'details': <String, Object>{
                'from': 'home',
                'to': 'profile',
                'duration': Random().nextInt(1000),
              },
            },
          };

          await logger.info(
            'Complex context test $i',
            context: complexContext,
          );
        }

        final stats = logger.getPerformanceStats();
        expect(stats['totalLogs'], equals(20));
        expect(stats['complexContextOperations'], greaterThan(0));
      });

      test('should handle context serialization efficiently', () async {
        await logger.initialize(
          strategies: [consoleStrategy],
          useIsolates: true,
          enablePerformanceMonitoring: true,
          enableModernConsole: true,
        );

        // Test with various data types in context
        for (int i = 0; i < 30; i++) {
          final mixedContext = <String, Object>{
            'stringValue': 'test_string_$i',
            'intValue': i,
            'doubleValue': i * 1.5,
            'boolValue': i % 2 == 0,
            'listValue': List.generate(10, (index) => 'item_$index'),
            'mapValue': <String, Object>{
              'nested': 'value_$i',
              'number': i,
            },
            'nullValue': 'null',
            'dateValue': DateTime.now(),
          };

          await logger.info(
            'Mixed context test $i',
            context: mixedContext,
          );
        }

        final stats = logger.getPerformanceStats();
        expect(stats['totalLogs'], equals(30));
        expect(stats['serializationOperations'], greaterThan(0));
      });
    });

    group('Error Handling Integration', () {
      test('should handle logging errors gracefully', () async {
        await logger.initialize(
          strategies: [consoleStrategy],
          useIsolates: true,
          enablePerformanceMonitoring: true,
          enableModernConsole: true,
        );

        // Test with potentially problematic data
        for (int i = 0; i < 15; i++) {
          try {
            await logger.info(
              'Error handling test $i',
              context: <String, Object>{
                'iteration': i,
                'problematicData': i % 3 == 0 ? 'normal' : 'problematic_${i * 1000}',
              },
            );
          } catch (e) {
            // Should handle errors gracefully
          }
        }

        final stats = logger.getPerformanceStats();
        expect(stats['totalLogs'], equals(15));
        expect(stats['errorCount'], equals(0)); // Should not have errors
      });

      test('should handle concurrent errors gracefully', () async {
        await logger.initialize(
          strategies: [consoleStrategy],
          useIsolates: true,
          enablePerformanceMonitoring: true,
          enableModernConsole: true,
        );

        // Test concurrent operations that might cause errors
        final futures = <Future>[];
        for (int i = 0; i < 25; i++) {
          futures.add(Future(() async {
            try {
              await logger.info(
                'Concurrent error test $i',
                context: <String, Object>{
                  'iteration': i,
                  'concurrentData': List.generate(500, (index) => 'concurrent_$index'),
                },
              );
            } catch (e) {
              // Should handle errors gracefully
            }
          }));
        }

        await Future.wait(futures);

        final stats = logger.getPerformanceStats();
        expect(stats['totalLogs'], equals(25));
        expect(stats['errorCount'], equals(0)); // Should not have errors
      });
    });

    group('Configuration Integration', () {
      test('should handle different configuration combinations', () async {
        // Test with different configuration combinations
        final configs = [
          {
            'useIsolates': true,
            'enablePerformanceMonitoring': true,
            'enableModernConsole': true,
          },
          {
            'useIsolates': false,
            'enablePerformanceMonitoring': true,
            'enableModernConsole': false,
          },
          {
            'useIsolates': true,
            'enablePerformanceMonitoring': false,
            'enableModernConsole': true,
          },
          {
            'useIsolates': false,
            'enablePerformanceMonitoring': false,
            'enableModernConsole': false,
          },
        ];

        for (int configIndex = 0; configIndex < configs.length; configIndex++) {
          final config = configs[configIndex];
          
          await logger.initialize(
            strategies: [consoleStrategy],
            useIsolates: config['useIsolates'] as bool,
            enablePerformanceMonitoring: config['enablePerformanceMonitoring'] as bool,
            enableModernConsole: config['enableModernConsole'] as bool,
          );

          // Test logging with this configuration
          for (int i = 0; i < 10; i++) {
            await logger.info(
              'Config test $configIndex-$i',
              context: <String, Object>{
                'configIndex': configIndex,
                'iteration': i,
              },
            );
          }

          final stats = logger.getPerformanceStats();
          expect(stats['totalLogs'], equals(10));
        }
      });

      test('should handle reconfiguration gracefully', () async {
        // Initial configuration
        await logger.initialize(
          strategies: [consoleStrategy],
          useIsolates: true,
          enablePerformanceMonitoring: true,
          enableModernConsole: true,
        );

        // Log some messages
        for (int i = 0; i < 5; i++) {
          await logger.info('Initial config test $i');
        }

        // Reconfigure
        await logger.reconfigure(
          strategies: [consoleStrategy],
          useIsolates: false,
          enablePerformanceMonitoring: false,
          enableModernConsole: false,
        );

        // Log more messages
        for (int i = 0; i < 5; i++) {
          await logger.info('Reconfigured test $i');
        }

        final stats = logger.getPerformanceStats();
        expect(stats['totalLogs'], equals(10));
      });
    });

    group('End-to-End Integration', () {
      test('should handle complete workflow integration', () async {
        await logger.initialize(
          strategies: [consoleStrategy],
          useIsolates: true,
          enablePerformanceMonitoring: true,
          enableModernConsole: true,
        );

        // Perform comprehensive logging workflow
        final futures = <Future>[];
        for (int i = 0; i < 100; i++) {
          futures.add(Future(() async {
            // Log with different levels
            switch (i % 5) {
              case 0:
                await logger.debug('E2E debug test $i');
                break;
              case 1:
                await logger.info('E2E info test $i');
                break;
              case 2:
                await logger.warning('E2E warning test $i');
                break;
              case 3:
                await logger.error('E2E error test $i');
                break;
              case 4:
                await logger.fatal('E2E fatal test $i');
                break;
            }

            // Log with context
            await logger.info(
              'E2E context test $i',
              context: <String, Object>{
                'iteration': i,
                'e2eTest': true,
                'data': List.generate(50, (index) => 'e2e_data_$index'),
              },
            );
          }));
        }

        await Future.wait(futures);

        // Collect statistics
        final stats = logger.getPerformanceStats();

        // Verify integration
        expect(stats['totalLogs'], equals(200)); // 100 * 2 (level + context)
        expect(stats['debugCount'], equals(20));
        expect(stats['infoCount'], equals(40)); // 20 from level + 20 from context
        expect(stats['warningCount'], equals(20));
        expect(stats['errorCount'], equals(20));
        expect(stats['fatalCount'], equals(20));
      });

      test('should handle stress testing across all components', () async {
        await logger.initialize(
          strategies: [consoleStrategy],
          useIsolates: true,
          enablePerformanceMonitoring: true,
          enableModernConsole: true,
        );

        // Stress test with high volume
        final futures = <Future>[];
        for (int i = 0; i < 500; i++) {
          futures.add(Future(() async {
            await logger.info(
              'Stress test $i',
              context: <String, Object>{
                'iteration': i,
                'stressTest': true,
                'heavyData': List.generate(1000, (index) => 'stress_data_$index'),
              },
            );
          }));
        }

        await Future.wait(futures);

        final stats = logger.getPerformanceStats();
        expect(stats['totalLogs'], equals(500));
        expect(stats['errorCount'], equals(0)); // Should handle stress gracefully
        expect(stats['averageProcessingTime'], lessThan(50.0)); // Should still be efficient
      });
    });
  });
}
