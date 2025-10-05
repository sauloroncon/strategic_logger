import 'dart:io';
import 'dart:math';
import 'package:test/test.dart';
import 'package:strategic_logger/src/strategic_logger.dart';
import 'package:strategic_logger/src/strategies/console/console_log_strategy.dart';

void main() {
  group('Core Performance Tests', () {
    late StrategicLogger logger;

    setUp(() {
      logger = StrategicLogger();
    });

    tearDown(() {
      logger.dispose();
    });

    group('Basic Logging Performance', () {
      test('should handle 1000 logs efficiently', () async {
        await logger.initialize(
          strategies: [ConsoleLogStrategy()],
          useIsolates: true,
          enablePerformanceMonitoring: true,
          enableModernConsole: true,
        );

        final stopwatch = Stopwatch()..start();

        // Generate 1000 logs
        for (int i = 0; i < 1000; i++) {
          await logger.info(
            'Performance test log $i',
            context: <String, Object>{
              'iteration': i,
              'timestamp': DateTime.now().millisecondsSinceEpoch,
            },
          );
        }

        // Wait for all logs to be processed
        logger.flush();

        stopwatch.stop();

        final stats = logger.getPerformanceStats();

        expect(stats['totalLogs'], equals(1000));
        expect(
          stats['averageProcessingTime'],
          lessThan(10.0),
        ); // Should be under 10ms per log
        expect(
          stats['maxProcessingTime'],
          lessThan(50.0),
        ); // Max should be under 50ms
        expect(
          stopwatch.elapsedMilliseconds,
          lessThan(5000),
        ); // Total time under 5 seconds

        print('1000 logs processed in ${stopwatch.elapsedMilliseconds}ms');
        print('Average processing time: ${stats['averageProcessingTime']}ms');
      });

      test('should handle concurrent logging efficiently', () async {
        await logger.initialize(
          strategies: [ConsoleLogStrategy()],
          useIsolates: true,
          enablePerformanceMonitoring: true,
          enableModernConsole: true,
        );

        final stopwatch = Stopwatch()..start();

        // Create 10 concurrent streams of 100 logs each
        final futures = <Future>[];
        for (int stream = 0; stream < 10; stream++) {
          futures.add(
            Future(() async {
              for (int i = 0; i < 100; i++) {
                await logger.info(
                  'Concurrent log from stream $stream, iteration $i',
                  context: <String, Object>{'stream': stream, 'iteration': i},
                );
              }
            }),
          );
        }

        await Future.wait(futures);
        logger.flush();

        stopwatch.stop();

        final stats = logger.getPerformanceStats();

        expect(stats['totalLogs'], equals(1000));
        expect(stats['concurrentOperations'], greaterThan(0));
        expect(
          stopwatch.elapsedMilliseconds,
          lessThan(3000),
        ); // Should handle concurrency efficiently

        print(
          '1000 concurrent logs processed in ${stopwatch.elapsedMilliseconds}ms',
        );
        print('Concurrent operations: ${stats['concurrentOperations']}');
      });

      test('should maintain performance under memory pressure', () async {
        await logger.initialize(
          strategies: [ConsoleLogStrategy()],
          useIsolates: true,
          enablePerformanceMonitoring: true,
          enableModernConsole: true,
        );

        final stopwatch = Stopwatch()..start();

        // Create memory pressure by generating large context data
        for (int i = 0; i < 500; i++) {
          final largeContext = <String, Object>{
            'largeData': List.generate(1000, (index) => 'data_$index'),
            'timestamp': DateTime.now().millisecondsSinceEpoch,
            'iteration': i,
            'nested': <String, Object>{
              'level1': <String, Object>{
                'level2': <String, Object>{
                  'level3': List.generate(100, (index) => 'nested_$index'),
                },
              },
            },
          };

          await logger.info(
            'Memory pressure test log $i',
            context: largeContext,
          );
        }

        logger.flush();

        stopwatch.stop();

        final stats = logger.getPerformanceStats();

        expect(stats['totalLogs'], equals(500));
        expect(
          stats['memoryUsage'],
          lessThan(100 * 1024 * 1024),
        ); // Should use less than 100MB
        expect(
          stats['averageProcessingTime'],
          lessThan(20.0),
        ); // Should still be efficient

        print(
          '500 large-context logs processed in ${stopwatch.elapsedMilliseconds}ms',
        );
        print(
          'Memory usage: ${(stats['memoryUsage'] / 1024 / 1024).toStringAsFixed(2)}MB',
        );
      });
    });

    group('Isolate Performance', () {
      test('should demonstrate isolate performance benefits', () async {
        // Test with isolates enabled
        await logger.initialize(
          strategies: [ConsoleLogStrategy()],
          useIsolates: true,
          enablePerformanceMonitoring: true,
          enableModernConsole: true,
        );

        final isolateStopwatch = Stopwatch()..start();

        for (int i = 0; i < 500; i++) {
          await logger.info(
            'Isolate test log $i',
            context: <String, Object>{
              'iteration': i,
              'complexData': List.generate(100, (index) => 'item_$index'),
            },
          );
        }

        logger.flush();
        isolateStopwatch.stop();

        logger.dispose();

        // Test without isolates for comparison
        final noIsolateLogger = StrategicLogger();
        await noIsolateLogger.initialize(
          strategies: [ConsoleLogStrategy()],
          useIsolates: false,
          enablePerformanceMonitoring: true,
          enableModernConsole: false,
        );

        final noIsolateStopwatch = Stopwatch()..start();

        for (int i = 0; i < 500; i++) {
          await noIsolateLogger.info(
            'No isolate test log $i',
            context: <String, Object>{
              'iteration': i,
              'complexData': List.generate(100, (index) => 'item_$index'),
            },
          );
        }

        noIsolateLogger.flush();
        noIsolateStopwatch.stop();

        noIsolateLogger.dispose();

        // Isolates should provide performance benefits for complex operations
        expect(
          isolateStopwatch.elapsedMilliseconds,
          lessThanOrEqualTo(noIsolateStopwatch.elapsedMilliseconds * 1.5),
        );

        print('With isolates: ${isolateStopwatch.elapsedMilliseconds}ms');
        print('Without isolates: ${noIsolateStopwatch.elapsedMilliseconds}ms');
        print(
          'Isolate performance ratio: ${(isolateStopwatch.elapsedMilliseconds / noIsolateStopwatch.elapsedMilliseconds).toStringAsFixed(2)}',
        );
      });
    });

    group('Memory Management Performance', () {
      test('should handle memory cleanup efficiently', () async {
        await logger.initialize(
          strategies: [ConsoleLogStrategy()],
          useIsolates: true,
          enablePerformanceMonitoring: true,
          enableModernConsole: true,
        );

        final initialMemory = ProcessInfo.currentRss;

        // Generate logs with large context data
        for (int i = 0; i < 1000; i++) {
          await logger.info(
            'Memory cleanup test log $i',
            context: <String, Object>{
              'iteration': i,
              'largeData': List.generate(1000, (index) => 'data_$index'),
            },
          );
        }

        logger.flush();

        // Force garbage collection simulation
        await Future.delayed(Duration(milliseconds: 100));

        final finalMemory = ProcessInfo.currentRss;
        final memoryIncrease = finalMemory - initialMemory;

        final stats = logger.getPerformanceStats();

        expect(
          memoryIncrease,
          lessThan(50 * 1024 * 1024),
        ); // Should not increase by more than 50MB
        expect(stats['memoryCleanupOperations'], greaterThan(0));

        print(
          'Memory increase: ${(memoryIncrease / 1024 / 1024).toStringAsFixed(2)}MB',
        );
        print('Cleanup operations: ${stats['memoryCleanupOperations']}');
      });
    });

    group('Performance Regression Tests', () {
      test('should maintain consistent performance across runs', () async {
        final runTimes = <int>[];

        for (int run = 0; run < 5; run++) {
          final runLogger = StrategicLogger();
          await runLogger.initialize(
            strategies: [ConsoleLogStrategy()],
            useIsolates: true,
            enablePerformanceMonitoring: true,
            enableModernConsole: true,
          );

          final stopwatch = Stopwatch()..start();

          for (int i = 0; i < 500; i++) {
            await runLogger.info(
              'Regression test log run $run, iteration $i',
              context: <String, Object>{'run': run, 'iteration': i},
            );
          }

          runLogger.flush();
          stopwatch.stop();

          runTimes.add(stopwatch.elapsedMilliseconds);
          runLogger.dispose();
        }

        // Calculate statistics
        final averageTime = runTimes.reduce((a, b) => a + b) / runTimes.length;
        final maxTime = runTimes.reduce((a, b) => a > b ? a : b);
        final variance =
            runTimes
                .map((time) => (time - averageTime) * (time - averageTime))
                .reduce((a, b) => a + b) /
            runTimes.length;
        final standardDeviation = sqrt(variance);
        final coefficientOfVariation = standardDeviation / averageTime;

        expect(averageTime, lessThan(2000)); // Should be consistently fast
        expect(
          coefficientOfVariation,
          lessThan(0.3),
        ); // Should have low variance
        expect(
          maxTime,
          lessThan(averageTime * 1.5),
        ); // Max should not be too far from average

        print('Performance regression test results:');
        print('Run times: $runTimes');
        print('Average: ${averageTime.toStringAsFixed(2)}ms');
        print('Standard deviation: ${standardDeviation.toStringAsFixed(2)}ms');
        print(
          'Coefficient of variation: ${coefficientOfVariation.toStringAsFixed(3)}',
        );
      });
    });

    group('Log Level Performance', () {
      test('should handle different log levels efficiently', () async {
        await logger.initialize(
          strategies: [ConsoleLogStrategy()],
          useIsolates: true,
          enablePerformanceMonitoring: true,
          enableModernConsole: true,
        );

        final stopwatch = Stopwatch()..start();

        // Test different log levels
        for (int i = 0; i < 200; i++) {
          switch (i % 5) {
            case 0:
              await logger.debug(
                'Debug log $i',
                context: <String, Object>{'level': 'debug', 'iteration': i},
              );
              break;
            case 1:
              await logger.info(
                'Info log $i',
                context: <String, Object>{'level': 'info', 'iteration': i},
              );
              break;
            case 2:
              await logger.warning(
                'Warning log $i',
                context: <String, Object>{'level': 'warning', 'iteration': i},
              );
              break;
            case 3:
              await logger.error(
                'Error log $i',
                context: <String, Object>{'level': 'error', 'iteration': i},
              );
              break;
            case 4:
              await logger.fatal(
                'Fatal log $i',
                context: <String, Object>{'level': 'fatal', 'iteration': i},
              );
              break;
          }
        }

        logger.flush();
        stopwatch.stop();

        final stats = logger.getPerformanceStats();

        expect(stats['totalLogs'], equals(200));
        expect(stats['debugCount'], equals(40));
        expect(stats['infoCount'], equals(40));
        expect(stats['warningCount'], equals(40));
        expect(stats['errorCount'], equals(40));
        expect(stats['fatalCount'], equals(40));
        expect(stopwatch.elapsedMilliseconds, lessThan(2000)); // Should be fast

        print(
          'Log level performance test completed in ${stopwatch.elapsedMilliseconds}ms',
        );
        print(
          'Debug: ${stats['debugCount']}, Info: ${stats['infoCount']}, Warning: ${stats['warningCount']}',
        );
        print('Error: ${stats['errorCount']}, Fatal: ${stats['fatalCount']}');
      });
    });
  });
}
