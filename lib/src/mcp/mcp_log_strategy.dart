import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import '../events/log_event.dart';
import '../enums/log_level.dart';
import '../strategies/log_strategy.dart';
import 'mcp_server.dart';

/// MCP Log Strategy for Strategic Logger
///
/// This strategy integrates with the Model Context Protocol (MCP) server
/// to provide AI agents with structured logging capabilities.
///
/// Features:
/// - Structured logging for AI consumption
/// - Real-time log streaming
/// - Query capabilities for log analysis
/// - Health monitoring through logs
class MCPLogStrategy extends LogStrategy {
  final MCPServer _mcpServer;
  final bool _enableRealTimeStreaming;
  final bool _enableHealthMonitoring;
  final Map<String, dynamic> _defaultContext;

  MCPLogStrategy({
    MCPServer? mcpServer,
    bool enableRealTimeStreaming = true,
    bool enableHealthMonitoring = true,
    Map<String, dynamic>? defaultContext,
  }) : _mcpServer = mcpServer ?? MCPServer.instance,
       _enableRealTimeStreaming = enableRealTimeStreaming,
       _enableHealthMonitoring = enableHealthMonitoring,
       _defaultContext = defaultContext ?? {};

  @override
  LogLevel logLevel = LogLevel.info;

  @override
  LogLevel loggerLogLevel = LogLevel.info;

  @override
  List<LogEvent>? supportedEvents = [
    LogEvent(eventName: 'mcp_log', eventMessage: 'MCP structured log entry'),
  ];

  /// Starts the MCP server if not already running
  Future<void> startServer() async {
    if (!_mcpServer.isRunning) {
      await _mcpServer.start();
    }
  }

  /// Stops the MCP server
  Future<void> stopServer() async {
    if (_mcpServer.isRunning) {
      await _mcpServer.stop();
    }
  }

  @override
  Future<void> log({dynamic message, LogEvent? event}) async {
    await _logToMCP(level: LogLevel.info, message: message, event: event);
  }

  @override
  Future<void> info({dynamic message, LogEvent? event}) async {
    await _logToMCP(level: LogLevel.info, message: message, event: event);
  }

  @override
  Future<void> error({
    dynamic error,
    StackTrace? stackTrace,
    LogEvent? event,
  }) async {
    await _logToMCP(
      level: LogLevel.error,
      message: error,
      event: event,
      stackTrace: stackTrace,
    );
  }

  @override
  Future<void> fatal({
    dynamic error,
    StackTrace? stackTrace,
    LogEvent? event,
  }) async {
    await _logToMCP(
      level: LogLevel.fatal,
      message: error,
      event: event,
      stackTrace: stackTrace,
    );
  }

  /// Logs a message to the MCP server
  Future<void> _logToMCP({
    required LogLevel level,
    dynamic message,
    LogEvent? event,
    StackTrace? stackTrace,
    Map<String, dynamic>? additionalContext,
  }) async {
    try {
      // Ensure server is running
      if (!_mcpServer.isRunning) {
        await startServer();
      }

      // Create structured log entry
      final mcpLogEntry = MCPLogEntry(
        id: _generateLogId(),
        timestamp: DateTime.now(),
        level: level,
        message: _formatMessage(message),
        context: _buildContext(additionalContext, stackTrace),
        event: event,
        source: 'strategic_logger_mcp',
      );

      // Add to MCP server
      _mcpServer.addLogEntry(mcpLogEntry);

      // Enable real-time streaming if configured
      if (_enableRealTimeStreaming) {
        await _streamLogEntry(mcpLogEntry);
      }

      // Health monitoring
      if (_enableHealthMonitoring) {
        await _updateHealthMetrics(mcpLogEntry);
      }
    } catch (e) {
      // Fallback to developer log if MCP fails
      developer.log(
        'Failed to log to MCP: $e',
        name: 'MCPLogStrategy',
        error: e,
      );
    }
  }

  /// Generates a unique log ID
  String _generateLogId() {
    return '${DateTime.now().millisecondsSinceEpoch}_${Uri.encodeComponent('mcp_log')}';
  }

  /// Formats a message for logging
  String _formatMessage(dynamic message) {
    if (message == null) return 'null';
    if (message is String) return message;
    if (message is Map || message is List) {
      return jsonEncode(message);
    }
    return message.toString();
  }

  /// Builds context for the log entry
  Map<String, dynamic> _buildContext(
    Map<String, dynamic>? additionalContext,
    StackTrace? stackTrace,
  ) {
    final context = Map<String, dynamic>.from(_defaultContext);

    if (additionalContext != null) {
      context.addAll(additionalContext);
    }

    if (stackTrace != null) {
      context['stackTrace'] = stackTrace.toString();
    }

    // Add MCP-specific context
    context['mcp_timestamp'] = DateTime.now().toIso8601String();
    context['mcp_source'] = 'strategic_logger';
    context['mcp_version'] = '1.1.0';

    return context;
  }

  /// Streams a log entry for real-time monitoring
  Future<void> _streamLogEntry(MCPLogEntry entry) async {
    try {
      // In a real implementation, this would send to a streaming endpoint
      // For now, we'll just log to developer console
      developer.log(
        'MCP Stream: ${entry.level.name} - ${entry.message}',
        name: 'MCPLogStrategy',
      );
    } catch (e) {
      developer.log(
        'Failed to stream log entry: $e',
        name: 'MCPLogStrategy',
        error: e,
      );
    }
  }

  /// Updates health metrics based on log entry
  Future<void> _updateHealthMetrics(MCPLogEntry entry) async {
    try {
      // Update health metrics based on log level
      switch (entry.level) {
        case LogLevel.error:
        case LogLevel.fatal:
          // Increment error count
          _incrementErrorCount();
          break;
        case LogLevel.warning:
          // Increment warning count
          _incrementWarningCount();
          break;
        default:
          // Increment info count
          _incrementInfoCount();
          break;
      }
    } catch (e) {
      developer.log(
        'Failed to update health metrics: $e',
        name: 'MCPLogStrategy',
        error: e,
      );
    }
  }

  /// Increments error count for health monitoring
  void _incrementErrorCount() {
    // In a real implementation, this would update health metrics
    developer.log('Health: Error count incremented', name: 'MCPLogStrategy');
  }

  /// Increments warning count for health monitoring
  void _incrementWarningCount() {
    // In a real implementation, this would update health metrics
    developer.log('Health: Warning count incremented', name: 'MCPLogStrategy');
  }

  /// Increments info count for health monitoring
  void _incrementInfoCount() {
    // In a real implementation, this would update health metrics
    developer.log('Health: Info count incremented', name: 'MCPLogStrategy');
  }

  /// Queries logs from the MCP server
  Future<List<MCPLogEntry>> queryLogs({
    LogLevel? level,
    DateTime? since,
    DateTime? until,
    String? message,
    Map<String, String>? context,
    String? sortBy,
    int? limit,
  }) async {
    try {
      // In a real implementation, this would query the MCP server
      // For now, we'll return an empty list
      return [];
    } catch (e) {
      developer.log(
        'Failed to query logs: $e',
        name: 'MCPLogStrategy',
        error: e,
      );
      return [];
    }
  }

  /// Gets health status from the MCP server
  Future<Map<String, dynamic>> getHealthStatus() async {
    try {
      // In a real implementation, this would query the MCP server health endpoint
      return {
        'status': 'healthy',
        'mcp_server': _mcpServer.isRunning,
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      return {
        'status': 'unhealthy',
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  /// MCP Server instance for testing
  MCPServer get mcpServer => _mcpServer;

  /// Generate log ID for testing
  String generateLogId() => _generateLogId();

  /// Format message for testing
  String formatMessage(dynamic message) => _formatMessage(message);

  /// Build context for testing
  Map<String, dynamic> buildContext(
    Map<String, dynamic>? additionalContext,
    StackTrace? stackTrace,
  ) => _buildContext(additionalContext, stackTrace);

  @override
  String toString() {
    return 'MCPLogStrategy(server: ${_mcpServer.isRunning}, streaming: $_enableRealTimeStreaming, health: $_enableHealthMonitoring)';
  }

  void dispose() {
    // Clean up resources
    stopServer();
  }
}
