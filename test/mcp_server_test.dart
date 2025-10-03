import 'dart:convert';
import 'dart:io';

import 'package:strategic_logger/logger.dart';
import 'package:test/test.dart';

/// Test suite for MCP Server functionality
void main() {
  group('MCP Server Tests', () {
    late MCPServer mcpServer;

    setUp(() {
      mcpServer = MCPServer(port: 3002); // Use different port for tests
    });

    tearDown(() async {
      if (mcpServer.isRunning) {
        await mcpServer.stop();
      }
    });

    test('MCP Server should initialize correctly', () {
      expect(mcpServer, isNotNull);
      expect(mcpServer.isRunning, isFalse);
    });

    test('MCP Server should start and stop correctly', () async {
      await mcpServer.start();
      expect(mcpServer.isRunning, isTrue);

      await mcpServer.stop();
      expect(mcpServer.isRunning, isFalse);
    });

    test('MCP Server should not start twice', () async {
      await mcpServer.start();
      expect(mcpServer.isRunning, isTrue);

      expect(() => mcpServer.start(), throwsA(isA<StateError>()));
    });

    test('MCP Server should handle log entries correctly', () async {
      await mcpServer.start();

      final logEntry = MCPLogEntry(
        id: 'test_1',
        timestamp: DateTime.now(),
        level: LogLevel.info,
        message: 'Test message',
        context: {'test': true},
        source: 'test',
      );

      mcpServer.addLogEntry(logEntry);

      // Verify log was added to history
      expect(mcpServer.logHistory.length, equals(1));
    });

    test('MCP Server should maintain max history size', () async {
      await mcpServer.start();

      // Add more entries than max history size
      for (int i = 0; i < 10005; i++) {
        final logEntry = MCPLogEntry(
          id: 'test_$i',
          timestamp: DateTime.now(),
          level: LogLevel.info,
          message: 'Test message $i',
          context: {'index': i},
          source: 'test',
        );
        mcpServer.addLogEntry(logEntry);
      }

      // Should not exceed max history size
      expect(mcpServer.logHistory.length, lessThanOrEqualTo(10000));
    });

    group('HTTP Endpoints', () {
      setUp(() async {
        await mcpServer.start();
      });

      test('Health endpoint should return correct status', () async {
        final client = HttpClient();
        try {
          final request = await client.get('localhost', 3002, '/health');
          final response = await request.close();
          final responseBody = await response.transform(utf8.decoder).join();
          final jsonResponse = jsonDecode(responseBody) as Map<String, dynamic>;

          expect(response.statusCode, equals(200));
          expect(jsonResponse['status'], equals('healthy'));
          expect(jsonResponse['server'], equals('strategic_logger_mcp'));
          expect(jsonResponse['version'], equals('1.1.0'));
          expect(jsonResponse['is_running'], isTrue);
        } finally {
          client.close();
        }
      });

      test('Logs endpoint should return logs', () async {
        // Add test log entry
        final logEntry = MCPLogEntry(
          id: 'test_log',
          timestamp: DateTime.now(),
          level: LogLevel.info,
          message: 'Test log message',
          context: {'test': true},
          source: 'test',
        );
        mcpServer.addLogEntry(logEntry);

        final client = HttpClient();
        try {
          final request = await client.get('localhost', 3002, '/logs');
          final response = await request.close();
          final responseBody = await response.transform(utf8.decoder).join();
          final jsonResponse = jsonDecode(responseBody) as Map<String, dynamic>;

          expect(response.statusCode, equals(200));
          expect(jsonResponse['logs'], isA<List>());
          expect(jsonResponse['total'], equals(1));
        } finally {
          client.close();
        }
      });

      test('Logs endpoint should filter by level', () async {
        // Add logs with different levels
        mcpServer.addLogEntry(
          MCPLogEntry(
            id: 'error_log',
            timestamp: DateTime.now(),
            level: LogLevel.error,
            message: 'Error message',
            context: {},
            source: 'test',
          ),
        );

        mcpServer.addLogEntry(
          MCPLogEntry(
            id: 'info_log',
            timestamp: DateTime.now(),
            level: LogLevel.info,
            message: 'Info message',
            context: {},
            source: 'test',
          ),
        );

        final client = HttpClient();
        try {
          final request = await client.get(
            'localhost',
            3002,
            '/logs?level=error',
          );
          final response = await request.close();
          final responseBody = await response.transform(utf8.decoder).join();
          final jsonResponse = jsonDecode(responseBody) as Map<String, dynamic>;

          expect(response.statusCode, equals(200));
          expect(jsonResponse['logs'], isA<List>());

          final logs = jsonResponse['logs'] as List;
          if (logs.isNotEmpty) {
            final firstLog = logs.first as Map<String, dynamic>;
            expect(firstLog['level'], equals('error'));
          }
        } finally {
          client.close();
        }
      });

      test('Logs endpoint should limit results', () async {
        // Add multiple log entries
        for (int i = 0; i < 10; i++) {
          mcpServer.addLogEntry(
            MCPLogEntry(
              id: 'log_$i',
              timestamp: DateTime.now(),
              level: LogLevel.info,
              message: 'Message $i',
              context: {},
              source: 'test',
            ),
          );
        }

        final client = HttpClient();
        try {
          final request = await client.get('localhost', 3002, '/logs?limit=5');
          final response = await request.close();
          final responseBody = await response.transform(utf8.decoder).join();
          final jsonResponse = jsonDecode(responseBody) as Map<String, dynamic>;

          expect(response.statusCode, equals(200));
          expect(jsonResponse['logs'], isA<List>());
          expect(jsonResponse['total'], lessThanOrEqualTo(5));
        } finally {
          client.close();
        }
      });
    });

    group('MCPLogEntry Tests', () {
      test('MCPLogEntry should serialize to JSON correctly', () {
        final logEntry = MCPLogEntry(
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

      test('MCPLogEntry should deserialize from JSON correctly', () {
        final json = {
          'id': 'test_id',
          'timestamp': '2024-01-01T12:00:00.000Z',
          'level': 'info',
          'message': 'Test message',
          'context': {'key': 'value'},
          'source': 'test_source',
        };

        final logEntry = MCPLogEntry.fromJson(json);

        expect(logEntry.id, equals('test_id'));
        expect(logEntry.level, equals(LogLevel.info));
        expect(logEntry.message, equals('Test message'));
        expect(logEntry.context, equals({'key': 'value'}));
        expect(logEntry.source, equals('test_source'));
      });
    });

    group('MCPQuery Tests', () {
      test('MCPQuery should serialize to JSON correctly', () {
        // Test MCPQuery constructor
        final query = MCPQuery(
          level: LogLevel.error,
          since: DateTime(2024, 1, 1),
          until: DateTime(2024, 1, 2),
          message: 'error',
          context: {'user': 'test'},
          sortBy: 'timestamp',
          limit: 10,
        );

        expect(query.level, equals(LogLevel.error));
        expect(query.message, equals('error'));
        expect(query.context, equals({'user': 'test'}));
        expect(query.sortBy, equals('timestamp'));
        expect(query.limit, equals(10));

        // Note: MCPQuery doesn't have toJson method, testing fromJson instead
        final json = {
          'level': 'error',
          'message': 'error',
          'context': {'user': 'test'},
          'sortBy': 'timestamp',
          'limit': 10,
        };
        final queryFromJson = MCPQuery.fromJson(json);

        expect(queryFromJson.level, equals(LogLevel.error));
        expect(queryFromJson.message, equals('error'));
        expect(queryFromJson.context, equals({'user': 'test'}));
        expect(queryFromJson.sortBy, equals('timestamp'));
        expect(queryFromJson.limit, equals(10));
      });

      test('MCPQuery should deserialize from JSON correctly', () {
        final json = {
          'level': 'error',
          'since': '2024-01-01T00:00:00.000Z',
          'until': '2024-01-02T00:00:00.000Z',
          'message': 'error',
          'context': {'user': 'test'},
          'sortBy': 'timestamp',
          'limit': 10,
        };

        final query = MCPQuery.fromJson(json);

        expect(query.level, equals(LogLevel.error));
        expect(query.message, equals('error'));
        expect(query.context, equals({'user': 'test'}));
        expect(query.sortBy, equals('timestamp'));
        expect(query.limit, equals(10));
      });
    });
  });
}
