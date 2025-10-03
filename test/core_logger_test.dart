import 'package:test/test.dart';

// Mock classes to avoid Flutter dependencies
class LogLevel {
  static const debug = LogLevel._('debug');
  static const info = LogLevel._('info');
  static const warning = LogLevel._('warning');
  static const error = LogLevel._('error');
  static const fatal = LogLevel._('fatal');

  const LogLevel._(this.name);
  final String name;
}

class LogEntry {
  final LogLevel level;
  final String message;
  final DateTime timestamp;
  final Map<String, dynamic>? context;
  final StackTrace? stackTrace;

  LogEntry({
    required this.level,
    required this.message,
    required this.timestamp,
    this.context,
    this.stackTrace,
  });

  Map<String, dynamic> toJson() => {
    'level': level.name,
    'message': message,
    'timestamp': timestamp.toIso8601String(),
    'context': context,
    'stackTrace': stackTrace?.toString(),
  };
}

class MockLogStrategy {
  final List<LogEntry> entries = [];

  void log(LogEntry entry) {
    entries.add(entry);
  }

  void clear() {
    entries.clear();
  }
}

class CoreLogger {
  final List<MockLogStrategy> _strategies = [];
  bool _isInitialized = false;

  void initialize() {
    _isInitialized = true;
  }

  void addStrategy(MockLogStrategy strategy) {
    _strategies.add(strategy);
  }

  void log(
    LogLevel level,
    String message, {
    Map<String, dynamic>? context,
    StackTrace? stackTrace,
  }) {
    if (!_isInitialized) {
      throw StateError('Logger not initialized');
    }

    final entry = LogEntry(
      level: level,
      message: message,
      timestamp: DateTime.now(),
      context: context,
      stackTrace: stackTrace,
    );

    for (final strategy in _strategies) {
      strategy.log(entry);
    }
  }

  void debug(String message, {Map<String, dynamic>? context}) {
    log(LogLevel.debug, message, context: context);
  }

  void info(String message, {Map<String, dynamic>? context}) {
    log(LogLevel.info, message, context: context);
  }

  void warning(String message, {Map<String, dynamic>? context}) {
    log(LogLevel.warning, message, context: context);
  }

  void error(
    String message, {
    Map<String, dynamic>? context,
    StackTrace? stackTrace,
  }) {
    log(LogLevel.error, message, context: context, stackTrace: stackTrace);
  }

  void fatal(
    String message, {
    Map<String, dynamic>? context,
    StackTrace? stackTrace,
  }) {
    log(LogLevel.fatal, message, context: context, stackTrace: stackTrace);
  }

  bool get isInitialized => _isInitialized;
}

void main() {
  group('Core Logger Tests', () {
    late CoreLogger logger;
    late MockLogStrategy strategy;

    setUp(() {
      logger = CoreLogger();
      strategy = MockLogStrategy();
      logger.addStrategy(strategy);
      logger.initialize();
    });

    test('should initialize successfully', () {
      expect(logger.isInitialized, isTrue);
    });

    test('should throw error when logging before initialization', () {
      final uninitializedLogger = CoreLogger();
      expect(() => uninitializedLogger.info('test'), throwsStateError);
    });

    test('should log debug message', () {
      logger.debug('Debug message');
      expect(strategy.entries.length, equals(1));
      expect(strategy.entries.first.level, equals(LogLevel.debug));
      expect(strategy.entries.first.message, equals('Debug message'));
    });

    test('should log info message', () {
      logger.info('Info message');
      expect(strategy.entries.length, equals(1));
      expect(strategy.entries.first.level, equals(LogLevel.info));
      expect(strategy.entries.first.message, equals('Info message'));
    });

    test('should log warning message', () {
      logger.warning('Warning message');
      expect(strategy.entries.length, equals(1));
      expect(strategy.entries.first.level, equals(LogLevel.warning));
      expect(strategy.entries.first.message, equals('Warning message'));
    });

    test('should log error message', () {
      logger.error('Error message');
      expect(strategy.entries.length, equals(1));
      expect(strategy.entries.first.level, equals(LogLevel.error));
      expect(strategy.entries.first.message, equals('Error message'));
    });

    test('should log fatal message', () {
      logger.fatal('Fatal message');
      expect(strategy.entries.length, equals(1));
      expect(strategy.entries.first.level, equals(LogLevel.fatal));
      expect(strategy.entries.first.message, equals('Fatal message'));
    });

    test('should log with context', () {
      final context = {'userId': '123', 'action': 'login'};
      logger.info('User action', context: context);

      expect(strategy.entries.length, equals(1));
      expect(strategy.entries.first.context, equals(context));
    });

    test('should log with stack trace', () {
      final stackTrace = StackTrace.current;
      logger.error('Error with stack trace', stackTrace: stackTrace);

      expect(strategy.entries.length, equals(1));
      expect(strategy.entries.first.stackTrace, equals(stackTrace));
    });

    test('should log to multiple strategies', () {
      final strategy2 = MockLogStrategy();
      logger.addStrategy(strategy2);

      logger.info('Message to both strategies');

      expect(strategy.entries.length, equals(1));
      expect(strategy2.entries.length, equals(1));
      expect(
        strategy.entries.first.message,
        equals('Message to both strategies'),
      );
      expect(
        strategy2.entries.first.message,
        equals('Message to both strategies'),
      );
    });

    test('should create proper log entry structure', () {
      final context = {'key': 'value'};
      final stackTrace = StackTrace.current;

      logger.error('Test error', context: context, stackTrace: stackTrace);

      final entry = strategy.entries.first;
      final json = entry.toJson();

      expect(json['level'], equals('error'));
      expect(json['message'], equals('Test error'));
      expect(json['context'], equals(context));
      expect(json['timestamp'], isA<String>());
      expect(json['stackTrace'], isA<String>());
    });

    test('should handle multiple log entries', () {
      logger.debug('Debug 1');
      logger.info('Info 1');
      logger.warning('Warning 1');
      logger.error('Error 1');
      logger.fatal('Fatal 1');

      expect(strategy.entries.length, equals(5));
      expect(strategy.entries[0].level, equals(LogLevel.debug));
      expect(strategy.entries[1].level, equals(LogLevel.info));
      expect(strategy.entries[2].level, equals(LogLevel.warning));
      expect(strategy.entries[3].level, equals(LogLevel.error));
      expect(strategy.entries[4].level, equals(LogLevel.fatal));
    });
  });
}
