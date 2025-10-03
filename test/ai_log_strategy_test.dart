import 'package:strategic_logger/logger.dart';
import 'package:test/test.dart';

/// Test suite for AI Log Strategy functionality
void main() {
  group('AI Log Strategy Tests', () {
    late AILogStrategy aiStrategy;

    setUp(() {
      aiStrategy = AILogStrategy(
        apiKey: 'test-api-key',
        enableAnalysis: true,
        enableInsights: true,
        enableAnomalyDetection: true,
        analysisInterval: const Duration(seconds: 1),
        batchSize: 5,
      );
    });

    tearDown(() {
      aiStrategy.stopAnalysis();
      aiStrategy.dispose();
    });

    test('AI Log Strategy should initialize correctly', () {
      expect(aiStrategy, isNotNull);
      expect(aiStrategy.logLevel, equals(LogLevel.info));
      expect(aiStrategy.loggerLogLevel, equals(LogLevel.info));
      expect(aiStrategy.supportedEvents, isNotNull);
      expect(aiStrategy.supportedEvents!.length, equals(3));
    });

    test('AI Log Strategy should start and stop analysis correctly', () {
      expect(aiStrategy.analysisTimer, isNull);

      aiStrategy.startAnalysis();
      expect(aiStrategy.analysisTimer, isNotNull);

      aiStrategy.stopAnalysis();
      expect(aiStrategy.analysisTimer, isNull);
    });

    test('AI Log Strategy should not start analysis twice', () {
      aiStrategy.startAnalysis();
      final firstTimer = aiStrategy.analysisTimer;

      aiStrategy.startAnalysis();
      expect(aiStrategy.analysisTimer, equals(firstTimer));
    });

    test('AI Log Strategy should log info messages correctly', () async {
      aiStrategy.startAnalysis();

      await aiStrategy.info(message: 'Test info message');

      // Verify log was added to buffer
      expect(aiStrategy.logBuffer.length, equals(1));

      final logEntry = aiStrategy.logBuffer.first;
      expect(logEntry.level, equals(LogLevel.info));
      expect(logEntry.message, equals('Test info message'));
    });

    test('AI Log Strategy should log error messages correctly', () async {
      aiStrategy.startAnalysis();

      await aiStrategy.error(error: 'Test error message');

      // Verify log was added to buffer
      expect(aiStrategy.logBuffer.length, equals(1));

      final logEntry = aiStrategy.logBuffer.first;
      expect(logEntry.level, equals(LogLevel.error));
      expect(logEntry.message, equals('Test error message'));
    });

    test('AI Log Strategy should log fatal messages correctly', () async {
      aiStrategy.startAnalysis();

      await aiStrategy.fatal(error: 'Test fatal message');

      // Verify log was added to buffer
      expect(aiStrategy.logBuffer.length, equals(1));

      final logEntry = aiStrategy.logBuffer.first;
      expect(logEntry.level, equals(LogLevel.fatal));
      expect(logEntry.message, equals('Test fatal message'));
    });

    test('AI Log Strategy should log with events correctly', () async {
      aiStrategy.startAnalysis();

      final event = LogEvent(
        eventName: 'TEST_EVENT',
        eventMessage: 'Test event message',
      );

      await aiStrategy.log(message: 'Test message with event', event: event);

      // Verify log was added to buffer
      expect(aiStrategy.logBuffer.length, equals(1));

      final logEntry = aiStrategy.logBuffer.first;
      expect(logEntry.event, isNotNull);
      expect(logEntry.event!.eventName, equals('TEST_EVENT'));
    });

    test('AI Log Strategy should process batch when buffer is full', () async {
      aiStrategy.startAnalysis();

      // Fill buffer to batch size
      for (int i = 0; i < 5; i++) {
        await aiStrategy.info(message: 'Test message $i');
      }

      // Buffer should be empty after batch processing
      expect(aiStrategy.logBuffer.length, equals(0));
    });

    test('AI Log Strategy should analyze critical logs immediately', () async {
      aiStrategy.startAnalysis();

      await aiStrategy.error(error: 'Critical error');

      // Critical logs should trigger immediate analysis
      // Note: In a real test, you'd mock the AI analysis
      expect(aiStrategy.logBuffer.length, equals(1));
    });

    test('AI Log Strategy should format messages correctly', () {
      // Test string message
      expect(aiStrategy.formatMessage('Test string'), equals('Test string'));

      // Test null message
      expect(aiStrategy.formatMessage(null), equals('null'));

      // Test Map message
      final mapMessage = {'key': 'value'};
      final formatted = aiStrategy.formatMessage(mapMessage);
      expect(formatted, contains('key'));
      expect(formatted, contains('value'));

      // Test List message
      final listMessage = [1, 2, 3];
      final formattedList = aiStrategy.formatMessage(listMessage);
      expect(formattedList, contains('1'));
      expect(formattedList, contains('2'));
      expect(formattedList, contains('3'));
    });

    test('AI Log Strategy should generate unique log IDs', () {
      final id1 = aiStrategy.generateLogId();
      final id2 = aiStrategy.generateLogId();

      expect(id1, isNot(equals(id2)));
      expect(id1, isNotEmpty);
      expect(id2, isNotEmpty);
    });

    test('AI Log Strategy should build context correctly', () {
      final additionalContext = {'extra': 'data'};
      final stackTrace = StackTrace.current;

      final context = aiStrategy.buildContext(additionalContext, stackTrace);

      // Should include additional context
      expect(context['extra'], equals('data'));

      // Should include stack trace
      expect(context['stackTrace'], isNotNull);

      // Should include AI-specific context
      expect(context['ai_timestamp'], isNotNull);
      expect(context['ai_source'], equals('strategic_logger'));
      expect(context['ai_version'], equals('1.1.0'));
    });

    test('AI Log Strategy should generate log summary correctly', () async {
      aiStrategy.startAnalysis();

      // Add some test logs
      await aiStrategy.info(message: 'Test message 1');
      await aiStrategy.error(error: 'Test error 1');
      await aiStrategy.info(message: 'Test message 2');

      final summary = await aiStrategy.generateLogSummary(
        timeRange: const Duration(minutes: 5),
        maxLogs: 10,
      );

      expect(summary, isA<String>());
      expect(summary, isNotEmpty);
    });

    test('AI Log Strategy should extract recommendations correctly', () {
      final contentWithError = 'This is an error message';
      final recommendations = aiStrategy.extractRecommendations(
        contentWithError,
      );

      expect(recommendations, isA<List<String>>());
      expect(recommendations.length, greaterThan(0));
      expect(recommendations.any((r) => r.contains('error')), isTrue);
    });

    test('AI Log Strategy should determine insight type correctly', () {
      final errorResult = AIAnalysisResult(
        title: 'Error Analysis',
        summary: 'Found errors',
        confidence: 0.8,
        recommendations: ['Fix errors'],
      );

      final warningResult = AIAnalysisResult(
        title: 'Performance Warning',
        summary: 'Performance issues',
        confidence: 0.7,
        recommendations: ['Optimize performance'],
      );

      final infoResult = AIAnalysisResult(
        title: 'General Info',
        summary: 'General information',
        confidence: 0.6,
        recommendations: ['Review info'],
      );

      expect(
        aiStrategy.determineInsightType(errorResult),
        equals(AIInsightType.critical),
      );
      expect(
        aiStrategy.determineInsightType(warningResult),
        equals(AIInsightType.warning),
      );
      expect(
        aiStrategy.determineInsightType(infoResult),
        equals(AIInsightType.info),
      );
    });

    test('AI Log Strategy should build system prompt correctly', () {
      final prompt = aiStrategy.buildSystemPrompt();

      expect(prompt, isA<String>());
      expect(prompt, isNotEmpty);
      expect(prompt, contains('expert log analyst'));
      expect(prompt, contains('patterns'));
      expect(prompt, contains('anomalies'));
    });

    test('AI Log Strategy should build analysis prompt correctly', () {
      final entries = [
        AILogEntry(
          id: '1',
          timestamp: DateTime.now(),
          level: LogLevel.info,
          message: 'Test message',
          context: {},
          source: 'test',
        ),
      ];

      final prompt = aiStrategy.buildAnalysisPrompt(entries);

      expect(prompt, isA<String>());
      expect(prompt, isNotEmpty);
      expect(prompt, contains('Test message'));
    });

    test('AI Log Strategy toString should return correct representation', () {
      final strategy = AILogStrategy(
        apiKey: 'test-key',
        enableAnalysis: false,
        enableInsights: false,
        enableAnomalyDetection: false,
      );

      final string = strategy.toString();

      expect(string, contains('AILogStrategy'));
      expect(string, contains('analysis: false'));
      expect(string, contains('insights: false'));
      expect(string, contains('anomaly: false'));
    });

    group('AILogEntry Tests', () {
      test('AILogEntry should serialize to JSON correctly', () {
        final logEntry = AILogEntry(
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
    });

    group('AIInsight Tests', () {
      test('AIInsight should serialize to JSON correctly', () {
        final insight = AIInsight(
          id: 'insight_1',
          timestamp: DateTime(2024, 1, 1, 12, 0, 0),
          type: AIInsightType.critical,
          title: 'Critical Issue',
          description: 'Found critical issue',
          confidence: 0.9,
          recommendations: ['Fix immediately'],
          relatedLogs: ['log_1', 'log_2'],
        );

        final json = insight.toJson();

        expect(json['id'], equals('insight_1'));
        expect(json['type'], equals('critical'));
        expect(json['title'], equals('Critical Issue'));
        expect(json['description'], equals('Found critical issue'));
        expect(json['confidence'], equals(0.9));
        expect(json['recommendations'], equals(['Fix immediately']));
        expect(json['relatedLogs'], equals(['log_1', 'log_2']));
      });
    });

    group('AIAnalysisResult Tests', () {
      test('AIAnalysisResult should initialize correctly', () {
        final result = AIAnalysisResult(
          title: 'Test Analysis',
          summary: 'Test summary',
          confidence: 0.8,
          recommendations: ['Test recommendation'],
        );

        expect(result.title, equals('Test Analysis'));
        expect(result.summary, equals('Test summary'));
        expect(result.confidence, equals(0.8));
        expect(result.recommendations, equals(['Test recommendation']));
      });
    });
  });
}
