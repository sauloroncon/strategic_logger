import 'dart:async';
import 'dart:collection';
import 'dart:isolate';

import 'package:meta/meta.dart';

/// Manages isolates for heavy logging operations to prevent blocking the main thread.
///
/// This class provides a pool of isolates that can be used for:
/// - Log formatting and serialization
/// - Heavy data processing
/// - Network operations preparation
/// - File I/O operations
@internal
class IsolateManager {
  static final IsolateManager _instance = IsolateManager._internal();
  factory IsolateManager() => _instance;
  IsolateManager._internal();

  final List<Isolate> _isolates = [];
  final List<ReceivePort> _ports = [];
  final Queue<Completer> _availableIsolates = Queue<Completer>();
  final int _maxIsolates = 4;
  bool _isInitialized = false;

  /// Initializes the isolate pool
  Future<void> initialize() async {
    if (_isInitialized) return;

    for (int i = 0; i < _maxIsolates; i++) {
      await _createIsolate();
    }
    _isInitialized = true;
  }

  /// Creates a new isolate for the pool
  Future<void> _createIsolate() async {
    final receivePort = ReceivePort();
    final isolate = await Isolate.spawn(
      _isolateEntryPoint,
      receivePort.sendPort,
    );

    _isolates.add(isolate);
    _ports.add(receivePort);

    // Listen for isolate availability
    receivePort.listen((message) {
      if (message is SendPort) {
        _availableIsolates.add(Completer<SendPort>()..complete(message));
      }
    });
  }

  /// Entry point for isolates
  static void _isolateEntryPoint(SendPort sendPort) {
    final receivePort = ReceivePort();
    sendPort.send(receivePort.sendPort);

    receivePort.listen((message) async {
      if (message is Map<String, dynamic>) {
        final task = message['task'] as String;
        final data = message['data'];
        final replyPort = message['replyPort'] as SendPort;

        try {
          dynamic result;
          switch (task) {
            case 'formatLog':
              result = await _formatLog(data);
              break;
            case 'serializeData':
              result = await _serializeData(data);
              break;
            case 'compressLog':
              result = await _compressLog(data);
              break;
            default:
              result = {'error': 'Unknown task: $task'};
          }

          replyPort.send({'success': true, 'result': result});
        } catch (e, stackTrace) {
          replyPort.send({
            'success': false,
            'error': e.toString(),
            'stackTrace': stackTrace.toString(),
          });
        }
      }
    });
  }

  /// Formats a log message in isolate
  static Future<Map<String, dynamic>> _formatLog(dynamic data) async {
    final logData = data as Map<String, dynamic>;
    final message = logData['message'] as String;
    final level = logData['level'] as String;
    final timestamp = logData['timestamp'] as DateTime;
    final context = logData['context'] as Map<String, dynamic>?;

    // Simulate heavy formatting work
    await Future.delayed(const Duration(milliseconds: 10));

    return {
      'formatted': '[$timestamp] [$level] $message',
      'structured': {
        'timestamp': timestamp.toIso8601String(),
        'level': level,
        'message': message,
        'context': context,
      },
    };
  }

  /// Serializes data in isolate
  static Future<String> _serializeData(dynamic data) async {
    // Simulate heavy serialization work
    await Future.delayed(const Duration(milliseconds: 5));

    // Simple JSON-like serialization
    if (data is Map) {
      return data.entries.map((e) => '${e.key}: ${e.value}').join(', ');
    }
    return data.toString();
  }

  /// Compresses log data in isolate
  static Future<Map<String, dynamic>> _compressLog(dynamic data) async {
    // Simulate compression work
    await Future.delayed(const Duration(milliseconds: 15));

    final logData = data as Map<String, dynamic>;
    return {
      'compressed': true,
      'originalSize': logData.toString().length,
      'compressedSize': (logData.toString().length * 0.7).round(),
      'data': logData,
    };
  }

  /// Executes a task in an available isolate
  Future<T> executeInIsolate<T>(String task, dynamic data) async {
    if (!_isInitialized) {
      await initialize();
    }

    final completer = Completer<SendPort>();

    // Wait for an available isolate
    if (_availableIsolates.isNotEmpty) {
      final availableCompleter = _availableIsolates.removeFirst();
      final sendPort = await availableCompleter.future;
      completer.complete(sendPort);
    } else {
      // Create a new isolate if none available
      await _createIsolate();
      final receivePort = _ports.last;
      final sendPort = await receivePort.first as SendPort;
      completer.complete(sendPort);
    }

    final sendPort = await completer.future;
    final replyPort = ReceivePort();

    sendPort.send({
      'task': task,
      'data': data,
      'replyPort': replyPort.sendPort,
    });

    final result = await replyPort.first as Map<String, dynamic>;
    replyPort.close();

    if (result['success'] == true) {
      return result['result'] as T;
    } else {
      throw Exception('Isolate task failed: ${result['error']}');
    }
  }

  /// Formats a log message using isolate
  Future<Map<String, dynamic>> formatLog({
    required String message,
    required String level,
    required DateTime timestamp,
    Map<String, dynamic>? context,
  }) async {
    return executeInIsolate('formatLog', {
      'message': message,
      'level': level,
      'timestamp': timestamp,
      'context': context,
    });
  }

  /// Serializes data using isolate
  Future<String> serializeData(dynamic data) async {
    return executeInIsolate('serializeData', data);
  }

  /// Compresses log data using isolate
  Future<Map<String, dynamic>> compressLog(Map<String, dynamic> data) async {
    return executeInIsolate('compressLog', data);
  }

  /// Disposes all isolates and cleans up resources
  void dispose() {
    for (final isolate in _isolates) {
      isolate.kill();
    }
    for (final port in _ports) {
      port.close();
    }
    _isolates.clear();
    _ports.clear();
    _availableIsolates.clear();
    _isInitialized = false;
  }
}

/// Global isolate manager instance
@internal
final isolateManager = IsolateManager();
