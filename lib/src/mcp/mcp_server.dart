import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../core/log_queue.dart';
import '../events/log_event.dart';
import '../enums/log_level.dart';

/// Model Context Protocol (MCP) Server for Strategic Logger
///
/// Provides a native MCP server that allows AI agents to:
/// - Register structured logging events
/// - Query recent logs with filtering
/// - Access logging context for debugging
/// - Monitor application health through logs
class MCPServer {
  static MCPServer? _instance;
  static MCPServer get instance => _instance ??= MCPServer._();

  MCPServer._() : _port = 3001, _host = 'localhost';

  bool _isRunning = false;
  HttpServer? _server;
  final int _port;
  final String _host;

  // Log storage for MCP queries
  final List<MCPLogEntry> _logHistory = [];
  final int _maxHistorySize = 10000;

  // Stream controllers for real-time updates
  final StreamController<MCPLogEntry> _logStreamController =
      StreamController<MCPLogEntry>.broadcast();

  MCPServer({int port = 3001, String host = 'localhost'})
    : _port = port,
      _host = host;

  /// Whether the MCP server is currently running
  bool get isRunning => _isRunning;

  /// Stream of log entries for real-time monitoring
  Stream<MCPLogEntry> get logStream => _logStreamController.stream;

  /// Current log history for testing
  List<MCPLogEntry> get logHistory => _logHistory;

  /// Starts the MCP server
  Future<void> start() async {
    if (_isRunning) {
      throw StateError('MCP Server is already running');
    }

    try {
      _server = await HttpServer.bind(_host, _port);
      _isRunning = true;

      print('🚀 MCP Server started on $_host:$_port');

      // Handle incoming requests
      _server!.listen(_handleRequest);

      // Set up log queue listener
      _setupLogQueueListener();
    } catch (e) {
      print('❌ Failed to start MCP Server: $e');
      rethrow;
    }
  }

  /// Stops the MCP server
  Future<void> stop() async {
    if (!_isRunning) return;

    await _server?.close();
    _server = null;
    _isRunning = false;

    print('🛑 MCP Server stopped');
  }

  /// Handles incoming HTTP requests
  void _handleRequest(HttpRequest request) async {
    try {
      final response = request.response;
      response.headers.add('Content-Type', 'application/json');
      response.headers.add('Access-Control-Allow-Origin', '*');
      response.headers.add(
        'Access-Control-Allow-Methods',
        'GET, POST, OPTIONS',
      );
      response.headers.add('Access-Control-Allow-Headers', 'Content-Type');

      if (request.method == 'OPTIONS') {
        response.statusCode = 200;
        await response.close();
        return;
      }

      final uri = request.uri;
      final path = uri.path;

      switch (path) {
        case '/logs':
          await _handleLogsRequest(request, response);
          break;
        case '/logs/query':
          await _handleQueryRequest(request, response);
          break;
        case '/logs/stream':
          await _handleStreamRequest(request, response);
          break;
        case '/health':
          await _handleHealthRequest(request, response);
          break;
        default:
          response.statusCode = 404;
          response.write(jsonEncode({'error': 'Not found'}));
      }

      await response.close();
    } catch (e) {
      print('❌ Error handling MCP request: $e');
      request.response.statusCode = 500;
      request.response.write(jsonEncode({'error': e.toString()}));
      await request.response.close();
    }
  }

  /// Handles requests to get recent logs
  Future<void> _handleLogsRequest(
    HttpRequest request,
    HttpResponse response,
  ) async {
    final queryParams = request.uri.queryParameters;
    final limit = int.tryParse(queryParams['limit'] ?? '100') ?? 100;
    final level = queryParams['level'];
    final since = queryParams['since'];

    var filteredLogs = _logHistory.take(limit).toList();

    // Filter by log level
    if (level != null) {
      final logLevel = LogLevel.values.firstWhere(
        (l) => l.name.toLowerCase() == level.toLowerCase(),
        orElse: () => LogLevel.info,
      );
      filteredLogs = filteredLogs
          .where((log) => _compareLogLevels(log.level, logLevel))
          .toList();
    }

    // Filter by timestamp
    if (since != null) {
      final sinceTime = DateTime.tryParse(since);
      if (sinceTime != null) {
        filteredLogs = filteredLogs
            .where((log) => log.timestamp.isAfter(sinceTime))
            .toList();
      }
    }

    response.statusCode = 200;
    response.write(
      jsonEncode({
        'logs': filteredLogs.map((log) => log.toJson()).toList(),
        'total': filteredLogs.length,
        'timestamp': DateTime.now().toIso8601String(),
      }),
    );
  }

  /// Handles query requests with advanced filtering
  Future<void> _handleQueryRequest(
    HttpRequest request,
    HttpResponse response,
  ) async {
    if (request.method != 'POST') {
      response.statusCode = 405;
      response.write(jsonEncode({'error': 'Method not allowed'}));
      return;
    }

    try {
      final body = await utf8.decoder.bind(request).join();
      final query = jsonDecode(body) as Map<String, dynamic>;

      final mcpQuery = MCPQuery.fromJson(query);
      final results = await _executeQuery(mcpQuery);

      response.statusCode = 200;
      response.write(
        jsonEncode({
          'results': results.map((log) => log.toJson()).toList(),
          'query': query,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );
    } catch (e) {
      response.statusCode = 400;
      response.write(jsonEncode({'error': 'Invalid query: $e'}));
    }
  }

  /// Handles streaming requests for real-time log updates
  Future<void> _handleStreamRequest(
    HttpRequest request,
    HttpResponse response,
  ) async {
    response.statusCode = 200;
    response.headers.add('Content-Type', 'text/event-stream');
    response.headers.add('Cache-Control', 'no-cache');
    response.headers.add('Connection', 'keep-alive');

    final subscription = _logStreamController.stream.listen(
      (logEntry) {
        response.write('data: ${jsonEncode(logEntry.toJson())}\n\n');
      },
      onError: (error) {
        response.write(
          'event: error\ndata: ${jsonEncode({'error': error.toString()})}\n\n',
        );
      },
    );

    // Clean up when client disconnects
    request.response.done.then((_) {
      subscription.cancel();
    });
  }

  /// Handles health check requests
  Future<void> _handleHealthRequest(
    HttpRequest request,
    HttpResponse response,
  ) async {
    response.statusCode = 200;
    response.write(
      jsonEncode({
        'status': 'healthy',
        'server': 'strategic_logger_mcp',
        'version': '1.1.0',
        'uptime': DateTime.now().toIso8601String(),
        'logs_count': _logHistory.length,
        'is_running': _isRunning,
      }),
    );
  }

  /// Sets up listener for log queue
  void _setupLogQueueListener() {
    // This would integrate with the existing LogQueue
    // For now, we'll simulate log entries
    Timer.periodic(Duration(seconds: 1), (timer) {
      if (!_isRunning) {
        timer.cancel();
        return;
      }

      // In a real implementation, this would listen to the actual log queue
      // and convert LogEntry to MCPLogEntry
    });
  }

  /// Executes a query against the log history
  Future<List<MCPLogEntry>> _executeQuery(MCPQuery query) async {
    var results = List<MCPLogEntry>.from(_logHistory);

    // Apply filters
    if (query.level != null) {
      results = results
          .where((log) => _compareLogLevels(log.level, query.level!))
          .toList();
    }

    if (query.since != null) {
      results = results
          .where((log) => log.timestamp.isAfter(query.since!))
          .toList();
    }

    if (query.until != null) {
      results = results
          .where((log) => log.timestamp.isBefore(query.until!))
          .toList();
    }

    if (query.message != null) {
      results = results
          .where(
            (log) => log.message.toLowerCase().contains(
              query.message!.toLowerCase(),
            ),
          )
          .toList();
    }

    if (query.context != null) {
      results = results.where((log) {
        return query.context!.entries.every((entry) {
          return log.context[entry.key]?.toString() == entry.value;
        });
      }).toList();
    }

    // Apply sorting
    if (query.sortBy != null) {
      switch (query.sortBy) {
        case 'timestamp':
          results.sort((a, b) => a.timestamp.compareTo(b.timestamp));
          break;
        case 'level':
          results.sort((a, b) => a.level.index.compareTo(b.level.index));
          break;
        case 'message':
          results.sort((a, b) => a.message.compareTo(b.message));
          break;
      }
    }

    // Apply limit
    if (query.limit != null) {
      results = results.take(query.limit!).toList();
    }

    return results;
  }

  /// Compares log levels for filtering
  bool _compareLogLevels(LogLevel logLevel, LogLevel filterLevel) {
    return logLevel.index >= filterLevel.index;
  }

  /// Adds a log entry to the history
  void addLogEntry(MCPLogEntry entry) {
    _logHistory.insert(0, entry);

    // Maintain max history size
    if (_logHistory.length > _maxHistorySize) {
      _logHistory.removeLast();
    }

    // Emit to stream
    _logStreamController.add(entry);
  }

  /// Converts a LogEntry to MCPLogEntry
  MCPLogEntry fromLogEntry(LogEntry logEntry) {
    return MCPLogEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      timestamp: logEntry.timestamp,
      level: logEntry.level,
      message: logEntry.message,
      context: logEntry.context ?? {},
      event: logEntry.event,
      source: 'strategic_logger',
    );
  }
}

/// MCP Log Entry for structured logging
class MCPLogEntry {
  final String id;
  final DateTime timestamp;
  final LogLevel level;
  final String message;
  final Map<String, dynamic> context;
  final LogEvent? event;
  final String source;

  MCPLogEntry({
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

  factory MCPLogEntry.fromJson(Map<String, dynamic> json) {
    return MCPLogEntry(
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

/// MCP Query for advanced log filtering
class MCPQuery {
  final LogLevel? level;
  final DateTime? since;
  final DateTime? until;
  final String? message;
  final Map<String, String>? context;
  final String? sortBy;
  final int? limit;

  MCPQuery({
    this.level,
    this.since,
    this.until,
    this.message,
    this.context,
    this.sortBy,
    this.limit,
  });

  factory MCPQuery.fromJson(Map<String, dynamic> json) {
    return MCPQuery(
      level: json['level'] != null
          ? LogLevel.values.firstWhere(
              (l) => l.name == json['level'],
              orElse: () => LogLevel.info,
            )
          : null,
      since: json['since'] != null ? DateTime.parse(json['since']) : null,
      until: json['until'] != null ? DateTime.parse(json['until']) : null,
      message: json['message'] as String?,
      context: json['context'] != null
          ? Map<String, String>.from(json['context'] as Map)
          : null,
      sortBy: json['sortBy'] as String?,
      limit: json['limit'] as int?,
    );
  }
}
