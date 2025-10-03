import 'dart:io';
import 'dart:math';
import 'package:test/test.dart';
import 'package:strategic_logger/src/strategic_logger.dart';
import 'package:strategic_logger/src/strategies/console/console_log_strategy.dart';
import 'package:strategic_logger/src/core/object_pool.dart';
import 'package:strategic_logger/src/core/log_compression.dart';
import 'package:strategic_logger/src/mcp/mcp_log_strategy.dart';
import 'package:strategic_logger/src/ai/ai_log_strategy.dart';

void main() {
  group('Integration Tests', () {
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

    group('Object Pool Integration', () {
      test('should integrate object pool with logging operations', () async {
        await logger.initialize(
          strategies: [consoleStrategy],
          useIsolates: true,
          enablePerformanceMonitoring: true,
          enableModernConsole: true,
        );

        final objectPool = ObjectPool();
        await objectPool.initialize();

        // Generate logs that will use the object pool
        for (int i = 0; i < 200; i++) {
          await logger.info(
            'Object pool integration test $i',
            context: <String, Object>{
              'iteration': i,
              'poolTest': true,
            },
          );
        }

        final poolStats = objectPool.getStats();
        final loggerStats = logger.getPerformanceStats();

        expect(loggerStats['totalLogs'], equals(200));
        expect(poolStats['logEntryPool']['reused'], greaterThan(0));
        expect(poolStats['logEntryPool']['created'], lessThan(200));
      });

      test('should handle object pool exhaustion gracefully', () async {
        await logger.initialize(
          strategies: [consoleStrategy],
          useIsolates: true,
          enablePerformanceMonitoring: true,
          enableModernConsole: true,
        );

        final objectPool = ObjectPool();
        await objectPool.initialize();

        // Overwhelm the object pool
        final futures = <Future>[];
        for (int i = 0; i < 1000; i++) {
          futures.add(Future(() async {
            await logger.info(
              'Object pool stress test $i',
              context: <String, Object>{
                'iteration': i,
                'stressTest': true,
                'data': List.generate(100, (index) => 'stress_data_$index'),
              },
            );
          }));
        }

        await Future.wait(futures);

        final poolStats = objectPool.getStats();
        final loggerStats = logger.getPerformanceStats();

        expect(loggerStats['totalLogs'], equals(1000));
        expect(poolStats['logEntryPool']['reused'], greaterThan(0));
        expect(poolStats['logEntryPool']['created'], greaterThan(0));
      });
    });

    group('Log Compression Integration', () {
      test('should integrate log compression with logging operations', () async {
        await logger.initialize(
          strategies: [consoleStrategy],
          useIsolates: true,
          enablePerformanceMonitoring: true,
          enableModernConsole: true,
        );

        final compression = LogCompression();
        await compression.startCompression();

        // Generate logs for compression
        for (int i = 0; i < 100; i++) {
          final logEntry = CompressibleLogEntry(
            level: LogLevel.info,
            message: 'Compression integration test $i',
            timestamp: DateTime.now(),
            context: <String, Object>{
              'iteration': i,
              'compressionTest': true,
              'data': List.generate(50, (index) => 'compressible_data_$index'),
            },
          );

          await compression.addLogEntry(logEntry);
        }

        await compression.stopCompression();

        final compressionStats = compression.getStats();
        final loggerStats = logger.getPerformanceStats();

        expect(compressionStats['totalEntries'], equals(100));
        expect(compressionStats['compressionRatio'], greaterThan(0));
        expect(compressionStats['batchCount'], greaterThan(0));
      });

      test('should handle compression failures gracefully', () async {
        await logger.initialize(
          strategies: [consoleStrategy],
          useIsolates: true,
          enablePerformanceMonitoring: true,
          enableModernConsole: true,
        );

        final compression = LogCompression();
        await compression.startCompression();

        // Generate logs that might cause compression issues
        for (int i = 0; i < 50; i++) {
          final logEntry = CompressibleLogEntry(
            level: LogLevel.error,
            message: 'Compression failure test $i',
            timestamp: DateTime.now(),
            context: <String, Object>{
              'iteration': i,
              'failureTest': true,
              'problematicData': List.generate(10000, (index) => 'problematic_data_$index'),
            },
          );

          await compression.addLogEntry(logEntry);
        }

        await compression.stopCompression();

        final compressionStats = compression.getStats();
        expect(compressionStats['totalEntries'], equals(50));
        expect(compressionStats['errorCount'], equals(0)); // Should handle gracefully
      });
    });

    group('MCP Integration', () {
      test('should integrate MCP server with logging operations', () async {
        await logger.initialize(
          strategies: [consoleStrategy],
          useIsolates: true,
          enablePerformanceMonitoring: true,
          enableModernConsole: true,
        );

        final mcpStrategy = MCPLogStrategy(
          port: 8080,
          host: 'localhost',
        );

        // Start MCP server
        await mcpStrategy.startServer();

        // Generate logs for MCP
        for (int i = 0; i < 50; i++) {
          await logger.info(
            'MCP integration test $i',
            context: <String, Object>{
              'iteration': i,
              'mcpTest': true,
            },
          );
        }

        final healthStatus = mcpStrategy.getHealthStatus();
        final loggerStats = logger.getPerformanceStats();

        expect(loggerStats['totalLogs'], equals(50));
        expect(healthStatus['status'], equals('healthy'));
        expect(healthStatus['totalLogs'], equals(50));

        // Stop MCP server
        await mcpStrategy.stopServer();
      });

      test('should handle MCP server failures gracefully', () async {
        await logger.initialize(
          strategies: [consoleStrategy],
          useIsolates: true,
          enablePerformanceMonitoring: true,
          enableModernConsole: true,
        );

        final mcpStrategy = MCPLogStrategy(
          port: 9999, // Invalid port
          host: 'invalid-host',
        );

        // Try to start MCP server (should fail gracefully)
        try {
          await mcpStrategy.startServer();
        } catch (e) {
          // Expected to fail
        }

        // Generate logs anyway
        for (int i = 0; i < 25; i++) {
          await logger.info(
            'MCP failure test $i',
            context: <String, Object>{
              'iteration': i,
              'failureTest': true,
            },
          );
        }

        final loggerStats = logger.getPerformanceStats();
        expect(loggerStats['totalLogs'], equals(25));
        expect(loggerStats['errorCount'], equals(0)); // Should handle gracefully
      });
    });

    group('AI Integration', () {
      test('should integrate AI strategy with logging operations', () async {
        await logger.initialize(
          strategies: [consoleStrategy],
          useIsolates: true,
          enablePerformanceMonitoring: true,
          enableModernConsole: true,
        );

        final aiStrategy = AILogStrategy(
          apiKey: 'test-key',
          model: 'gpt-3.5-turbo',
          analysisInterval: Duration(seconds: 1),
        );

        // Start AI analysis
        await aiStrategy.startAnalysis();

        // Generate logs for AI analysis
        for (int i = 0; i < 30; i++) {
          await logger.info(
            'AI integration test $i',
            context: <String, Object>{
              'iteration': i,
              'aiTest': true,
              'category': i % 3 == 0 ? 'error' : 'info',
            },
          );
        }

        // Wait for AI analysis
        await Future.delayed(Duration(seconds: 2));

        final loggerStats = logger.getPerformanceStats();
        expect(loggerStats['totalLogs'], equals(30));

        // Stop AI analysis
        await aiStrategy.stopAnalysis();
      });

      test('should handle AI strategy failures gracefully', () async {
        await logger.initialize(
          strategies: [consoleStrategy],
          useIsolates: true,
          enablePerformanceMonitoring: true,
          enableModernConsole: true,
        );

        final aiStrategy = AILogStrategy(
          apiKey: 'invalid-key',
          model: 'invalid-model',
          analysisInterval: Duration(milliseconds: 100),
        );

        // Try to start AI analysis (should fail gracefully)
        try {
          await aiStrategy.startAnalysis();
        } catch (e) {
          // Expected to fail
        }

        // Generate logs anyway
        for (int i = 0; i < 20; i++) {
          await logger.info(
            'AI failure test $i',
            context: <String, Object>{
              'iteration': i,
              'failureTest': true,
            },
          );
        }

        final loggerStats = logger.getPerformanceStats();
        expect(loggerStats['totalLogs'], equals(20));
        expect(loggerStats['errorCount'], equals(0)); // Should handle gracefully
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

        // Initialize all components
        final objectPool = ObjectPool();
        await objectPool.initialize();

        final compression = LogCompression();
        await compression.startCompression();

        final mcpStrategy = MCPLogStrategy(port: 8081, host: 'localhost');
        await mcpStrategy.startServer();

        final aiStrategy = AILogStrategy(
          apiKey: 'test-key',
          model: 'gpt-3.5-turbo',
          analysisInterval: Duration(seconds: 1),
        );
        await aiStrategy.startAnalysis();

        // Perform comprehensive logging
        final futures = <Future>[];
        for (int i = 0; i < 100; i++) {
          futures.add(Future(() async {
            // Log to main logger
            await logger.info(
              'E2E integration test $i',
              context: <String, Object>{
                'iteration': i,
                'e2eTest': true,
                'data': List.generate(50, (index) => 'e2e_data_$index'),
              },
            );

            // Add to compression
            final logEntry = CompressibleLogEntry(
              level: LogLevel.info,
              message: 'E2E compression test $i',
              timestamp: DateTime.now(),
              context: <String, Object>{
                'iteration': i,
                'compressionE2E': true,
              },
            );
            await compression.addLogEntry(logEntry);
          }));
        }

        await Future.wait(futures);

        // Wait for AI analysis
        await Future.delayed(Duration(seconds: 2));

        // Collect statistics
        final loggerStats = logger.getPerformanceStats();
        final poolStats = objectPool.getStats();
        final compressionStats = compression.getStats();
        final mcpHealth = mcpStrategy.getHealthStatus();

        // Verify integration
        expect(loggerStats['totalLogs'], equals(100));
        expect(poolStats['logEntryPool']['reused'], greaterThan(0));
        expect(compressionStats['totalEntries'], equals(100));
        expect(mcpHealth['status'], equals('healthy'));
        expect(mcpHealth['totalLogs'], equals(100));

        // Cleanup
        await compression.stopCompression();
        await mcpStrategy.stopServer();
        await aiStrategy.stopAnalysis();
      });

      test('should handle stress testing across all components', () async {
        await logger.initialize(
          strategies: [consoleStrategy],
          useIsolates: true,
          enablePerformanceMonitoring: true,
          enableModernConsole: true,
        );

        final objectPool = ObjectPool();
        await objectPool.initialize();

        final compression = LogCompression();
        await compression.startCompression();

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

            final logEntry = CompressibleLogEntry(
              level: LogLevel.info,
              message: 'Stress compression test $i',
              timestamp: DateTime.now(),
              context: <String, Object>{
                'iteration': i,
                'stressCompression': true,
              },
            );
            await compression.addLogEntry(logEntry);
          }));
        }

        await Future.wait(futures);
        await compression.stopCompression();

        final loggerStats = logger.getPerformanceStats();
        final poolStats = objectPool.getStats();
        final compressionStats = compression.getStats();

        expect(loggerStats['totalLogs'], equals(500));
        expect(poolStats['logEntryPool']['reused'], greaterThan(0));
        expect(compressionStats['totalEntries'], equals(500));
        expect(loggerStats['errorCount'], equals(0)); // Should handle stress gracefully
      });
    });
  });
}
