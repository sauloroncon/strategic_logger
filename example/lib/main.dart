import 'package:flutter/material.dart';
import 'package:strategic_logger/logger.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize Strategic Logger with console strategy only for demo
    // useIsolates is now auto-detected based on platform
    await logger.initialize(
      strategies: [
        ConsoleLogStrategy(
          useModernFormatting: true,
          useColors: true,
          useEmojis: true,
          showTimestamp: true,
          showContext: true,
        ),
      ],
      enablePerformanceMonitoring: true,
      enableModernConsole: true,
    );

    logger.info('Strategic Logger initialized successfully');
  } catch (e) {
    print('Error initializing logger: $e');
  }

  runApp(const StrategicLoggerExampleApp());
}

class StrategicLoggerExampleApp extends StatelessWidget {
  const StrategicLoggerExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Strategic Logger Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const LoggingDemoScreen(),
    );
  }
}

class LoggingDemoScreen extends StatefulWidget {
  const LoggingDemoScreen({super.key});

  @override
  State<LoggingDemoScreen> createState() => _LoggingDemoScreenState();
}

class _LoggingDemoScreenState extends State<LoggingDemoScreen> {
  int _logCount = 0;
  bool _isPerformanceMode = false;

  @override
  void initState() {
    super.initState();
    // Log app initialization
    try {
      logger.info('Strategic Logger Example App initialized');
    } catch (e) {
      print('Error logging: $e');
    }
  }

  void _logMessage(
    LogLevel level,
    String message, {
    Map<String, Object>? context,
  }) {
    setState(() {
      _logCount++;
    });

    try {
      switch (level) {
        case LogLevel.debug:
          logger.debug(message, context: context);
          break;
        case LogLevel.info:
          logger.info(message, context: context);
          break;
        case LogLevel.warning:
          logger.warning(message, context: context);
          break;
        case LogLevel.error:
          logger.error(message, context: context);
          break;
        case LogLevel.fatal:
          logger.fatal(message, context: context);
          break;
        case LogLevel.none:
          break;
      }
    } catch (e) {
      print('Error logging message: $e');
    }
  }

  void _logStructuredEvent() {
    try {
      final event = LogEvent(
        eventName: 'user_action',
        eventMessage: 'User performed structured logging test',
        parameters: {
          'action_type': 'structured_log',
          'timestamp': DateTime.now().toIso8601String(),
          'user_id': 'demo_user_123',
          'session_id': 'session_${DateTime.now().millisecondsSinceEpoch}',
        },
      );

      logger.logStructured(LogLevel.info, event);
      setState(() {
        _logCount++;
      });
    } catch (e) {
      print('Error logging structured event: $e');
    }
  }

  void _testPerformanceLogging() async {
    setState(() {
      _isPerformanceMode = true;
    });

    try {
      // Simulate high-volume logging
      for (int i = 0; i < 50; i++) {
        // Reduced for web
        logger.info(
          'Performance test log $i',
          context: {
            'iteration': i,
            'test_type': 'performance',
            'timestamp': DateTime.now().toIso8601String(),
          },
        );
        setState(() {
          _logCount++;
        });

        // Small delay to simulate real-world usage
        await Future.delayed(Duration(milliseconds: 50));
      }
    } catch (e) {
      print('Error in performance test: $e');
    }

    setState(() {
      _isPerformanceMode = false;
    });
  }

  void _testErrorScenario() {
    try {
      // Simulate an error
      throw Exception('This is a test error for logging demonstration');
    } catch (e, stackTrace) {
      try {
        logger.error(
          'Test error occurred',
          context: {
            'error_type': 'test_exception',
            'user_action': 'error_test_button',
          },
          stackTrace: stackTrace,
        );
        setState(() {
          _logCount++;
        });
      } catch (logError) {
        print('Error logging error: $logError');
      }
    }
  }

  void _getPerformanceStats() {
    try {
      final stats = logger.getPerformanceStats();
      logger.info(
        'Performance Statistics',
        context: {'stats': stats.toString(), 'total_logs': _logCount},
      );
    } catch (e) {
      print('Error getting performance stats: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Strategic Logger Demo'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: _getPerformanceStats,
            tooltip: 'Get Performance Stats',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Card
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Icon(
                      Icons.bug_report,
                      size: 48,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Strategic Logger Example',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Test logging strategies and features',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStatCard('Total Logs', _logCount.toString()),
                        _buildStatCard('Strategies', '1'),
                        _buildStatCard(
                          'Status',
                          _isPerformanceMode ? 'Testing' : 'Ready',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Log Level Buttons
            Text(
              'Log Levels',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildLogButton(
                  'Debug',
                  LogLevel.debug,
                  Colors.blue,
                  Icons.bug_report,
                ),
                _buildLogButton(
                  'Info',
                  LogLevel.info,
                  Colors.green,
                  Icons.info,
                ),
                _buildLogButton(
                  'Warning',
                  LogLevel.warning,
                  Colors.orange,
                  Icons.warning,
                ),
                _buildLogButton(
                  'Error',
                  LogLevel.error,
                  Colors.red,
                  Icons.error,
                ),
                _buildLogButton(
                  'Fatal',
                  LogLevel.fatal,
                  Colors.purple,
                  Icons.dangerous,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Special Features
            Text(
              'Special Features',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildFeatureButton(
                  'Structured Log',
                  Colors.indigo,
                  Icons.data_object,
                  _logStructuredEvent,
                ),
                _buildFeatureButton(
                  'Performance Test',
                  Colors.teal,
                  Icons.speed,
                  _testPerformanceLogging,
                ),
                _buildFeatureButton(
                  'Error Test',
                  Colors.red,
                  Icons.error_outline,
                  _testErrorScenario,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Context Examples
            Text(
              'Context Examples',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildContextButton(
                  'User Action',
                  Colors.cyan,
                  Icons.person,
                  () => _logMessage(
                    LogLevel.info,
                    'User performed action',
                    context: {
                      'user_id': 'user_123',
                      'action': 'button_click',
                      'screen': 'demo_screen',
                    },
                  ),
                ),
                _buildContextButton(
                  'API Call',
                  Colors.amber,
                  Icons.api,
                  () => _logMessage(
                    LogLevel.info,
                    'API call completed',
                    context: {
                      'endpoint': '/api/users',
                      'method': 'GET',
                      'status_code': 200,
                      'response_time': '150ms',
                    },
                  ),
                ),
                _buildContextButton(
                  'Database',
                  Colors.deepOrange,
                  Icons.storage,
                  () => _logMessage(
                    LogLevel.debug,
                    'Database query executed',
                    context: {
                      'table': 'users',
                      'operation': 'SELECT',
                      'rows_affected': 5,
                      'query_time': '25ms',
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Performance Stats Card
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.analytics,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Performance Monitoring',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Strategic Logger includes built-in performance monitoring with isolate-based processing, object pooling, and log compression.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _getPerformanceStats,
                      icon: const Icon(Icons.show_chart),
                      label: const Text('View Stats'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          try {
            logger.info(
              'Floating action button pressed',
              context: {
                'button_type': 'fab',
                'timestamp': DateTime.now().toIso8601String(),
              },
            );
            setState(() {
              _logCount++;
            });
          } catch (e) {
            print('Error logging FAB press: $e');
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Quick Log'),
      ),
    );
  }

  Widget _buildStatCard(String label, String value) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }

  Widget _buildLogButton(
    String label,
    LogLevel level,
    Color color,
    IconData icon,
  ) {
    return ElevatedButton.icon(
      onPressed: _isPerformanceMode
          ? null
          : () => _logMessage(level, '$label message sent'),
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  Widget _buildFeatureButton(
    String label,
    Color color,
    IconData icon,
    VoidCallback onPressed,
  ) {
    return ElevatedButton.icon(
      onPressed: _isPerformanceMode ? null : onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  Widget _buildContextButton(
    String label,
    Color color,
    IconData icon,
    VoidCallback onPressed,
  ) {
    return ElevatedButton.icon(
      onPressed: _isPerformanceMode ? null : onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }
}
