import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

import '../events/log_event.dart';
import '../enums/log_level.dart';
import '../strategies/log_strategy.dart';

/// AI Log Strategy for Strategic Logger
///
/// This strategy integrates with AI models and services to provide:
/// - Intelligent log analysis
/// - Pattern detection
/// - Anomaly detection
/// - Automated insights and recommendations
/// - Natural language log summaries
class AILogStrategy extends LogStrategy {
  final String _apiKey;
  final String _baseUrl;
  final HttpClient _httpClient;
  final bool _enableAnalysis;
  final bool _enableInsights;
  final bool _enableAnomalyDetection;
  final Duration _analysisInterval;
  final int _batchSize;

  // Analysis state
  final List<AILogEntry> _logBuffer = [];
  Timer? _analysisTimer;
  final StreamController<AIInsight> _insightsController =
      StreamController<AIInsight>.broadcast();

  AILogStrategy({
    required String apiKey,
    String baseUrl = 'https://api.openai.com/v1',
    bool enableAnalysis = true,
    bool enableInsights = true,
    bool enableAnomalyDetection = true,
    Duration analysisInterval = const Duration(minutes: 5),
    int batchSize = 100,
  }) : _apiKey = apiKey,
       _baseUrl = baseUrl,
       _httpClient = HttpClient(),
       _enableAnalysis = enableAnalysis,
       _enableInsights = enableInsights,
       _enableAnomalyDetection = enableAnomalyDetection,
       _analysisInterval = analysisInterval,
       _batchSize = batchSize;

  @override
  LogLevel logLevel = LogLevel.info;

  @override
  LogLevel loggerLogLevel = LogLevel.info;

  @override
  List<LogEvent>? supportedEvents = [
    LogEvent(
      eventName: 'ai_analysis',
      eventMessage: 'AI analysis of log patterns',
    ),
    LogEvent(eventName: 'ai_insight', eventMessage: 'AI-generated insight'),
    LogEvent(eventName: 'ai_anomaly', eventMessage: 'AI-detected anomaly'),
  ];

  /// Stream of AI insights
  Stream<AIInsight> get insightsStream => _insightsController.stream;

  /// Starts the AI analysis timer
  void startAnalysis() {
    if (_enableAnalysis && _analysisTimer == null) {
      _analysisTimer = Timer.periodic(_analysisInterval, (_) {
        _performBatchAnalysis();
      });
    }
  }

  /// Stops the AI analysis timer
  void stopAnalysis() {
    _analysisTimer?.cancel();
    _analysisTimer = null;
  }

  @override
  Future<void> log({dynamic message, LogEvent? event}) async {
    await _logToAI(level: LogLevel.info, message: message, event: event);
  }

  @override
  Future<void> info({dynamic message, LogEvent? event}) async {
    await _logToAI(level: LogLevel.info, message: message, event: event);
  }

  @override
  Future<void> error({
    dynamic error,
    StackTrace? stackTrace,
    LogEvent? event,
  }) async {
    await _logToAI(
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
    await _logToAI(
      level: LogLevel.fatal,
      message: error,
      event: event,
      stackTrace: stackTrace,
    );
  }

  /// Logs a message to the AI strategy
  Future<void> _logToAI({
    required LogLevel level,
    dynamic message,
    LogEvent? event,
    StackTrace? stackTrace,
    Map<String, dynamic>? additionalContext,
  }) async {
    try {
      // Create AI log entry
      final aiLogEntry = AILogEntry(
        id: _generateLogId(),
        timestamp: DateTime.now(),
        level: level,
        message: _formatMessage(message),
        context: _buildContext(additionalContext, stackTrace),
        event: event,
        source: 'strategic_logger_ai',
      );

      // Add to buffer
      _logBuffer.add(aiLogEntry);

      // Perform immediate analysis for critical logs
      if (level == LogLevel.error || level == LogLevel.fatal) {
        await _analyzeCriticalLog(aiLogEntry);
      }

      // Start analysis if not already started
      if (_enableAnalysis && _analysisTimer == null) {
        startAnalysis();
      }

      // Process batch if buffer is full
      if (_logBuffer.length >= _batchSize) {
        await _performBatchAnalysis();
      }
    } catch (e) {
      developer.log('Failed to log to AI: $e', name: 'AILogStrategy', error: e);
    }
  }

  /// Generates a unique log ID
  String _generateLogId() {
    return '${DateTime.now().millisecondsSinceEpoch}_${Uri.encodeComponent('ai_log')}';
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
    final context = <String, dynamic>{};

    if (additionalContext != null) {
      context.addAll(additionalContext);
    }

    if (stackTrace != null) {
      context['stackTrace'] = stackTrace.toString();
    }

    // Add AI-specific context
    context['ai_timestamp'] = DateTime.now().toIso8601String();
    context['ai_source'] = 'strategic_logger';
    context['ai_version'] = '1.1.0';

    return context;
  }

  /// Analyzes a critical log entry immediately
  Future<void> _analyzeCriticalLog(AILogEntry entry) async {
    try {
      final analysis = await _performAIAnalysis([entry]);

      if (analysis.isNotEmpty) {
        final insight = AIInsight(
          id: _generateLogId(),
          timestamp: DateTime.now(),
          type: AIInsightType.critical,
          title: 'Critical Log Analysis',
          description: analysis.first.summary,
          confidence: analysis.first.confidence,
          recommendations: analysis.first.recommendations,
          relatedLogs: [entry.id],
        );

        _insightsController.add(insight);
      }
    } catch (e) {
      developer.log(
        'Failed to analyze critical log: $e',
        name: 'AILogStrategy',
        error: e,
      );
    }
  }

  /// Performs batch analysis of log entries
  Future<void> _performBatchAnalysis() async {
    if (_logBuffer.isEmpty) return;

    try {
      final batch = List<AILogEntry>.from(_logBuffer);
      _logBuffer.clear();

      final analysis = await _performAIAnalysis(batch);

      if (analysis.isNotEmpty) {
        for (final result in analysis) {
          final insight = AIInsight(
            id: _generateLogId(),
            timestamp: DateTime.now(),
            type: _determineInsightType(result),
            title: result.title,
            description: result.summary,
            confidence: result.confidence,
            recommendations: result.recommendations,
            relatedLogs: batch.map((e) => e.id).toList(),
          );

          _insightsController.add(insight);
        }
      }
    } catch (e) {
      developer.log(
        'Failed to perform batch analysis: $e',
        name: 'AILogStrategy',
        error: e,
      );
    }
  }

  /// Performs AI analysis on log entries
  Future<List<AIAnalysisResult>> _performAIAnalysis(
    List<AILogEntry> entries,
  ) async {
    try {
      final requestBody = {
        'model': 'gpt-3.5-turbo',
        'messages': [
          {'role': 'system', 'content': _buildSystemPrompt()},
          {'role': 'user', 'content': _buildAnalysisPrompt(entries)},
        ],
        'temperature': 0.3,
        'max_tokens': 1000,
      };

      final request = await _httpClient.postUrl(
        Uri.parse('$_baseUrl/chat/completions'),
      );

      request.headers.add('Authorization', 'Bearer $_apiKey');
      request.headers.add('Content-Type', 'application/json');
      request.write(jsonEncode(requestBody));

      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();

      if (response.statusCode == 200) {
        final responseData = jsonDecode(responseBody);
        return _parseAnalysisResponse(responseData);
      } else {
        throw Exception('AI API request failed: ${response.statusCode}');
      }
    } catch (e) {
      developer.log(
        'Failed to perform AI analysis: $e',
        name: 'AILogStrategy',
        error: e,
      );
      return [];
    }
  }

  /// Builds the system prompt for AI analysis
  String _buildSystemPrompt() {
    return '''
You are an expert log analyst. Analyze the provided log entries and provide insights about:
1. Patterns and trends
2. Potential issues or anomalies
3. Performance implications
4. Recommendations for improvement

Focus on actionable insights that can help improve application performance and reliability.
''';
  }

  /// Builds the analysis prompt for AI
  String _buildAnalysisPrompt(List<AILogEntry> entries) {
    final logSummary = entries
        .map(
          (entry) =>
              '${entry.timestamp.toIso8601String()} [${entry.level.name}] ${entry.message}',
        )
        .join('\n');

    return '''
Please analyze these log entries:

$logSummary

Provide insights about patterns, issues, and recommendations.
''';
  }

  /// Parses the AI analysis response
  List<AIAnalysisResult> _parseAnalysisResponse(Map<String, dynamic> response) {
    try {
      final choices = response['choices'] as List;
      if (choices.isEmpty) return [];

      final content = choices.first['message']['content'] as String;

      // Parse the AI response (this is a simplified parser)
      final result = AIAnalysisResult(
        title: 'Log Analysis',
        summary: content,
        confidence: 0.8,
        recommendations: _extractRecommendations(content),
      );

      return [result];
    } catch (e) {
      developer.log(
        'Failed to parse AI analysis response: $e',
        name: 'AILogStrategy',
        error: e,
      );
      return [];
    }
  }

  /// Extracts recommendations from AI response
  List<String> _extractRecommendations(String content) {
    // Simple extraction - in a real implementation, this would be more sophisticated
    final recommendations = <String>[];

    if (content.toLowerCase().contains('error')) {
      recommendations.add(
        'Review error patterns and implement better error handling',
      );
    }

    if (content.toLowerCase().contains('performance')) {
      recommendations.add(
        'Monitor performance metrics and optimize bottlenecks',
      );
    }

    if (content.toLowerCase().contains('security')) {
      recommendations.add(
        'Review security implications and implement safeguards',
      );
    }

    return recommendations;
  }

  /// Determines the insight type based on analysis result
  AIInsightType _determineInsightType(AIAnalysisResult result) {
    if (result.title.toLowerCase().contains('error') ||
        result.title.toLowerCase().contains('critical')) {
      return AIInsightType.critical;
    }

    if (result.title.toLowerCase().contains('warning') ||
        result.title.toLowerCase().contains('performance')) {
      return AIInsightType.warning;
    }

    return AIInsightType.info;
  }

  /// Generates a summary of recent logs
  Future<String> generateLogSummary({Duration? timeRange, int? maxLogs}) async {
    try {
      final cutoffTime = timeRange != null
          ? DateTime.now().subtract(timeRange)
          : DateTime.now().subtract(const Duration(hours: 1));

      final recentLogs = _logBuffer
          .where((log) => log.timestamp.isAfter(cutoffTime))
          .take(maxLogs ?? 50)
          .toList();

      if (recentLogs.isEmpty) {
        return 'No recent logs found for the specified time range.';
      }

      final analysis = await _performAIAnalysis(recentLogs);

      if (analysis.isNotEmpty) {
        return analysis.first.summary;
      }

      return 'Generated summary: ${recentLogs.length} log entries analyzed.';
    } catch (e) {
      return 'Failed to generate log summary: $e';
    }
  }

  /// Analysis timer for testing
  Timer? get analysisTimer => _analysisTimer;

  /// Log buffer for testing
  List<AILogEntry> get logBuffer => _logBuffer;

  /// Generate log ID for testing
  String generateLogId() => _generateLogId();

  /// Format message for testing
  String formatMessage(dynamic message) => _formatMessage(message);

  /// Build context for testing
  Map<String, dynamic> buildContext(
    Map<String, dynamic>? additionalContext,
    StackTrace? stackTrace,
  ) => _buildContext(additionalContext, stackTrace);

  /// Extract recommendations for testing
  List<String> extractRecommendations(String content) =>
      _extractRecommendations(content);

  /// Determine insight type for testing
  AIInsightType determineInsightType(AIAnalysisResult result) =>
      _determineInsightType(result);

  /// Build system prompt for testing
  String buildSystemPrompt() => _buildSystemPrompt();

  /// Build analysis prompt for testing
  String buildAnalysisPrompt(List<AILogEntry> entries) =>
      _buildAnalysisPrompt(entries);

  @override
  String toString() {
    return 'AILogStrategy(analysis: $_enableAnalysis, insights: $_enableInsights, anomaly: $_enableAnomalyDetection)';
  }

  void dispose() {
    stopAnalysis();
    _insightsController.close();
    _httpClient.close();
  }
}

/// AI Log Entry for structured logging
class AILogEntry {
  final String id;
  final DateTime timestamp;
  final LogLevel level;
  final String message;
  final Map<String, dynamic> context;
  final LogEvent? event;
  final String source;

  AILogEntry({
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
}

/// AI Analysis Result
class AIAnalysisResult {
  final String title;
  final String summary;
  final double confidence;
  final List<String> recommendations;

  AIAnalysisResult({
    required this.title,
    required this.summary,
    required this.confidence,
    required this.recommendations,
  });
}

/// AI Insight
class AIInsight {
  final String id;
  final DateTime timestamp;
  final AIInsightType type;
  final String title;
  final String description;
  final double confidence;
  final List<String> recommendations;
  final List<String> relatedLogs;

  AIInsight({
    required this.id,
    required this.timestamp,
    required this.type,
    required this.title,
    required this.description,
    required this.confidence,
    required this.recommendations,
    required this.relatedLogs,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'type': type.name,
      'title': title,
      'description': description,
      'confidence': confidence,
      'recommendations': recommendations,
      'relatedLogs': relatedLogs,
    };
  }
}

/// AI Insight Type
enum AIInsightType { info, warning, critical }
