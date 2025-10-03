# Strategic Logger 🚀

[![Pub Version](https://img.shields.io/pub/v/strategic_logger?style=for-the-badge)](https://pub.dev/packages/strategic_logger)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge)](https://opensource.org/licenses/MIT)
[![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev/)
[![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev/)

> **Modern, high-performance logging framework for Flutter & Dart applications**

Strategic Logger is a cutting-edge logging solution that combines **multi-strategy logging**, **isolate-based processing**, and **beautiful console output** to provide developers with the most powerful and flexible logging experience.

---

## ✨ Why Strategic Logger?

### 🎯 **One Call, All Strategies**
Log once and send to multiple destinations simultaneously - Console, Firebase, Sentry, Datadog, New Relic, and more.

### ⚡ **Performance First**
- **Isolate-based processing** - Never block the main thread
- **Async queue with backpressure** - Handle high log volumes efficiently
- **Automatic batching** - Reduce network overhead
- **Performance monitoring** - Built-in metrics and insights

### 🎨 **Beautiful Console Output**
- **Modern formatting** with colors, emojis, and structured layout
- **Rich context display** with metadata and stack traces
- **Timestamp precision** with millisecond accuracy

### 🔄 **Drop-in Replacement**
100% compatible with popular logger packages - no code changes required!

---

## 🚀 Quick Start

### Installation

Add Strategic Logger to your `pubspec.yaml`:

```yaml
dependencies:
  strategic_logger: ^0.2.0
```

Then run:
```bash
flutter pub get
```

### Basic Usage

```dart
import 'package:strategic_logger/strategic_logger.dart';

void main() async {
  // Initialize once at app startup
  await logger.initialize(
    level: LogLevel.debug,
    strategies: [
      ConsoleLogStrategy(
        useModernFormatting: true,
        useColors: true,
        useEmojis: true,
      ),
      FirebaseAnalyticsLogStrategy(),
      FirebaseCrashlyticsLogStrategy(),
    ],
    useIsolates: true,
    enablePerformanceMonitoring: true,
  );

  // Start logging!
  await logger.info('App started successfully');
  await logger.error('Something went wrong', stackTrace: StackTrace.current);
}
```

---

## 🎯 Features

### 🔧 **Core Features**
- **Multiple Log Strategies** - Console, Firebase, Sentry, Datadog, New Relic
- **Custom Strategies** - Extend with your own logging destinations
- **Log Levels** - Debug, Info, Warning, Error, Fatal
- **Structured Logging** - Rich metadata and context support
- **Error Handling** - Robust error management with predefined types

### 🚀 **Modern Features**
- **Isolate Processing** - Heavy operations run in background isolates
- **Performance Monitoring** - Built-in metrics and performance tracking
- **Modern Console** - Beautiful, colorful, emoji-rich output
- **Compatibility Layer** - Drop-in replacement for popular logger packages
- **Async Queue** - Efficient log processing with backpressure control
- **Batch Processing** - Automatic batching for network strategies
- **Retry Logic** - Exponential backoff for failed operations

---

## 📖 Usage Examples

### Async Logging (Recommended)

```dart
// Basic logging
await logger.debug('Debug message');
await logger.info('Info message');
await logger.warning('Warning message');
await logger.error('Error message');
await logger.fatal('Fatal error');

// Structured logging with context
await logger.info('User action', context: {
  'userId': '123',
  'action': 'login',
  'timestamp': DateTime.now().toIso8601String(),
});

// Log with events
await logger.log('User logged in', event: LogEvent(
  eventName: 'user_login',
  eventMessage: 'User successfully logged in',
  parameters: {'userId': '123'},
));
```

### Sync Logging (Compatibility)

```dart
// Drop-in replacement for popular logger packages
logger.debugSync('Debug message');
logger.infoSync('Info message');
logger.errorSync('Error message');

// Or use the compatibility extension
loggerCompatibility.debug('Debug message');
loggerCompatibility.info('Info message');
loggerCompatibility.error('Error message');
```

### Performance Monitoring

```dart
// Get performance statistics
final stats = logger.getPerformanceStats();
print('Performance Stats: $stats');

// Force flush all queued logs
await logger.flush();
```

---

## 🎨 Modern Console Output

Experience beautiful, structured console output:

```
🐛 14:30:25.123 DEBUG  User action completed
📋 Event: USER_ACTION
   Message: User completed purchase
   Parameters:
     userId: 123
     amount: 99.99
🔍 Context:
   timestamp: 2024-01-15T14:30:25.123Z
   source: mobile_app
```

---

## 🔧 Configuration

### Advanced Initialization

```dart
await logger.initialize(
  level: LogLevel.info,
  strategies: [
    // Console with modern formatting
    ConsoleLogStrategy(
      useModernFormatting: true,
      useColors: true,
      useEmojis: true,
      showTimestamp: true,
      showContext: true,
    ),
    
    // Firebase Analytics
    FirebaseAnalyticsLogStrategy(),
    
    // Firebase Crashlytics
    FirebaseCrashlyticsLogStrategy(),
    
    // Datadog
    DatadogLogStrategy(
      apiKey: 'your-datadog-api-key',
      service: 'my-app',
      env: 'production',
      tags: 'team:mobile,version:1.0.0',
    ),
    
    // New Relic
    NewRelicLogStrategy(
      licenseKey: 'your-newrelic-license-key',
      appName: 'my-app',
      environment: 'production',
    ),
  ],
  
  // Modern features
  useIsolates: true,
  enablePerformanceMonitoring: true,
  enableModernConsole: true,
);
```

### Custom Strategies

Create your own logging strategy:

```dart
class MyCustomLogStrategy extends LogStrategy {
  @override
  Future<void> log({dynamic message, LogEvent? event}) async {
    // Use isolates for heavy processing
    final result = await isolateManager.executeInIsolate(
      'customTask',
      {'message': message, 'event': event?.toMap()},
    );
    
    // Send to your custom service
    await _sendToCustomService(result);
  }
  
  @override
  Future<void> info({dynamic message, LogEvent? event}) async {
    await log(message: message, event: event);
  }
  
  @override
  Future<void> error({dynamic error, StackTrace? stackTrace, LogEvent? event}) async {
    await log(message: error, event: event);
  }
  
  @override
  Future<void> fatal({dynamic error, StackTrace? stackTrace, LogEvent? event}) async {
    await log(message: error, event: event);
  }
}
```

---

## 📊 Performance

Strategic Logger is designed for high performance:

- **Isolate-based processing** prevents blocking the main thread
- **Automatic batching** reduces network overhead
- **Async queue with backpressure** handles high log volumes
- **Performance monitoring** tracks operation metrics
- **Efficient serialization** minimizes memory usage

### Performance Metrics

```dart
final stats = logger.getPerformanceStats();
print('Total operations: ${stats['processLogEntry']?.totalOperations}');
print('Average duration: ${stats['processLogEntry']?.averageDuration}ms');
print('Error rate: ${stats['processLogEntry']?.errorRate}%');
```

---

## 🆕 Migration Guide

### From v0.1.x to v0.2.x

The new version introduces breaking changes for better performance and modern features:

```dart
// Old way (v0.1.x)
logger.initialize(
  level: LogLevel.info,
  strategies: [ConsoleLogStrategy()],
);

// New way (v0.2.x)
await logger.initialize(
  level: LogLevel.info,
  strategies: [
    ConsoleLogStrategy(
      useModernFormatting: true,
      useColors: true,
      useEmojis: true,
    ),
  ],
  useIsolates: true,
  enablePerformanceMonitoring: true,
  enableModernConsole: true,
);
```

---

## 🌐 Supported Platforms

- ✅ **Flutter** (iOS, Android, Web, Desktop)
- ✅ **Dart CLI** applications
- ✅ **Dart VM** applications
- ✅ **Flutter Web**
- ✅ **Flutter Desktop** (Windows, macOS, Linux)

---

## 🗺️ Roadmap

- [ ] **Elasticsearch** strategy
- [ ] **Splunk** strategy
- [ ] **CloudWatch** strategy
- [ ] **File-based** logging strategy
- [ ] **SQLite** logging strategy
- [ ] **WebSocket** logging strategy
- [ ] **Compression** support
- [ ] **Encryption** support

---

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md) for details.

### Development Setup

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

---

## 💖 Support

If you find Strategic Logger helpful, please consider:

- ⭐ **Starring** the repository
- 🐛 **Reporting** bugs
- 💡 **Suggesting** new features
- 🤝 **Contributing** code
- ☕ [Buy me a coffee](https://www.buymeacoffee.com/sauloroncon)

---

## 🏢 Sponsored by

<div align="center">

**[Hypn Tech](https://hypn.com.br)** - *Maintainer & Sponsor*

*Building the future of mobile applications with cutting-edge technology*

</div>

---

## 📄 License

Strategic Logger is released under the **MIT License**. See [LICENSE](LICENSE) for details.

---

## 📚 Documentation

- [API Documentation](https://pub.dev/documentation/strategic_logger/latest/)
- [Examples](example/)
- [Changelog](CHANGELOG.md)
- [Contributing Guide](CONTRIBUTING.md)

---

<div align="center">

**Made with ❤️ by the Strategic Logger team**

[![GitHub](https://img.shields.io/badge/GitHub-100000?style=for-the-badge&logo=github&logoColor=white)](https://github.com/sauloroncon/strategic_logger)
[![Pub](https://img.shields.io/badge/Pub-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://pub.dev/packages/strategic_logger)

</div>