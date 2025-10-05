import '../enums/log_level.dart';
import '../events/log_event.dart';

/// Modern console formatter with colors, emojis, and structured output
class ModernConsoleFormatter {
  static final ModernConsoleFormatter _instance =
      ModernConsoleFormatter._internal();
  factory ModernConsoleFormatter() => _instance;
  ModernConsoleFormatter._internal();

  // ANSI color codes
  static const String _reset = '\x1B[0m';
  static const String _bold = '\x1B[1m';
  static const String _dim = '\x1B[2m';

  // Color definitions
  static const String _red = '\x1B[31m';
  static const String _green = '\x1B[32m';
  static const String _yellow = '\x1B[33m';
  static const String _blue = '\x1B[34m';
  static const String _magenta = '\x1B[35m';
  static const String _cyan = '\x1B[36m';
  static const String _white = '\x1B[37m';
  static const String _gray = '\x1B[90m';

  // Background colors
  static const String _bgRed = '\x1B[41m';
  static const String _bgGreen = '\x1B[42m';
  static const String _bgYellow = '\x1B[43m';
  static const String _bgCyan = '\x1B[46m';

  // Emojis for different log levels
  static const Map<LogLevel, String> _levelEmojis = {
    LogLevel.debug: '🐛',
    LogLevel.info: 'ℹ️',
    LogLevel.warning: '⚠️',
    LogLevel.error: '❌',
    LogLevel.fatal: '💀',
    LogLevel.none: '📝',
  };

  // Colors for different log levels
  static const Map<LogLevel, String> _levelColors = {
    LogLevel.debug: _cyan,
    LogLevel.info: _green,
    LogLevel.warning: _yellow,
    LogLevel.error: _red,
    LogLevel.fatal: _red + _bold,
    LogLevel.none: _gray,
  };

  // Background colors for different log levels
  static const Map<LogLevel, String> _levelBgColors = {
    LogLevel.debug: _bgCyan,
    LogLevel.info: _bgGreen,
    LogLevel.warning: _bgYellow,
    LogLevel.error: _bgRed,
    LogLevel.fatal: _bgRed,
    LogLevel.none: '',
  };

  /// Formats a log message with modern styling
  String formatLog({
    required LogLevel level,
    required String message,
    required DateTime timestamp,
    LogEvent? event,
    Map<String, dynamic>? context,
    StackTrace? stackTrace,
    bool useColors = true,
    bool useEmojis = true,
    bool showTimestamp = true,
    bool showContext = true,
  }) {
    final buffer = StringBuffer();

    // Add emoji if enabled
    if (useEmojis) {
      buffer.write('${_levelEmojis[level] ?? '📝'} ');
    }

    // Add timestamp if enabled
    if (showTimestamp) {
      final timeStr = _formatTimestamp(timestamp, useColors);
      buffer.write('$timeStr ');
    }

    // Add level badge
    final levelBadge = _formatLevelBadge(level, useColors);
    buffer.write('$levelBadge ');

    // Add message
    final formattedMessage = _formatMessage(message, level, useColors);
    buffer.write(formattedMessage);

    // Add event information if present
    if (event != null) {
      final eventInfo = _formatEvent(event, useColors);
      buffer.write('\n$eventInfo');
    }

    // Add context if present
    if (context != null && showContext) {
      final contextInfo = _formatContext(context, useColors);
      buffer.write('\n$contextInfo');
    }

    // Add stack trace if present
    if (stackTrace != null) {
      final stackInfo = _formatStackTrace(stackTrace, useColors);
      buffer.write('\n$stackInfo');
    }

    return buffer.toString();
  }

  /// Formats timestamp with color
  String _formatTimestamp(DateTime timestamp, bool useColors) {
    final timeStr =
        '${timestamp.hour.toString().padLeft(2, '0')}:'
        '${timestamp.minute.toString().padLeft(2, '0')}:'
        '${timestamp.second.toString().padLeft(2, '0')}.'
        '${timestamp.millisecond.toString().padLeft(3, '0')}';

    if (useColors) {
      return '$_gray$_dim$timeStr$_reset';
    }
    return timeStr;
  }

  /// Formats level badge with color and background
  String _formatLevelBadge(LogLevel level, bool useColors) {
    final levelName = level.name.toUpperCase().padRight(5);

    if (useColors) {
      final color = _levelColors[level] ?? _gray;
      final bgColor = _levelBgColors[level] ?? '';
      return '$color$_bold$bgColor $levelName $_reset';
    }

    return '[$levelName]';
  }

  /// Formats message with appropriate styling
  String _formatMessage(String message, LogLevel level, bool useColors) {
    if (useColors) {
      final color = _levelColors[level] ?? _white;
      return '$color$message$_reset';
    }
    return message;
  }

  /// Formats event information
  String _formatEvent(LogEvent event, bool useColors) {
    final buffer = StringBuffer();

    if (useColors) {
      buffer.write('$_blue$_bold📋 Event: $_reset');
      buffer.write('$_cyan${event.eventName}$_reset');

      if (event.eventMessage != null) {
        buffer.write('\n$_gray   Message: $_reset${event.eventMessage}');
      }

      if (event.parameters != null && event.parameters!.isNotEmpty) {
        buffer.write('\n$_gray   Parameters:$_reset');
        for (final entry in event.parameters!.entries) {
          buffer.write('\n$_gray     ${entry.key}: $_reset${entry.value}');
        }
      }
    } else {
      buffer.write('Event: ${event.eventName}');
      if (event.eventMessage != null) {
        buffer.write('\n  Message: ${event.eventMessage}');
      }
      if (event.parameters != null && event.parameters!.isNotEmpty) {
        buffer.write('\n  Parameters: ${event.parameters}');
      }
    }

    return buffer.toString();
  }

  /// Formats context information
  String _formatContext(Map<String, dynamic> context, bool useColors) {
    final buffer = StringBuffer();

    if (useColors) {
      buffer.write('$_magenta$_bold🔍 Context:$_reset');
      for (final entry in context.entries) {
        buffer.write('\n$_gray   ${entry.key}: $_reset${entry.value}');
      }
    } else {
      buffer.write('Context:');
      for (final entry in context.entries) {
        buffer.write('\n  ${entry.key}: ${entry.value}');
      }
    }

    return buffer.toString();
  }

  /// Formats stack trace with color
  String _formatStackTrace(StackTrace stackTrace, bool useColors) {
    final buffer = StringBuffer();

    if (useColors) {
      buffer.write('$_red$_bold📚 Stack Trace:$_reset');
      final lines = stackTrace.toString().split('\n');
      for (final line in lines) {
        if (line.trim().isNotEmpty) {
          buffer.write('\n$_gray   $line$_reset');
        }
      }
    } else {
      buffer.write('Stack Trace:\n$stackTrace');
    }

    return buffer.toString();
  }

  /// Creates a separator line
  String createSeparator({bool useColors = true, int length = 80}) {
    final line = '═' * length;
    if (useColors) {
      return '$_gray$line$_reset';
    }
    return line;
  }

  /// Creates a header for log sections
  String createHeader(String title, {bool useColors = true}) {
    final buffer = StringBuffer();
    final separator = createSeparator(useColors: useColors);

    if (useColors) {
      buffer.write('$separator\n');
      buffer.write('$_bold$_blue🎯 $title$_reset\n');
      buffer.write(separator);
    } else {
      buffer.write('$separator\n');
      buffer.write('🎯 $title\n');
      buffer.write(separator);
    }

    return buffer.toString();
  }

  /// Creates a footer for log sections
  String createFooter({bool useColors = true}) {
    return createSeparator(useColors: useColors);
  }

  /// Formats a table of key-value pairs
  String formatTable(Map<String, dynamic> data, {bool useColors = true}) {
    final buffer = StringBuffer();

    if (data.isEmpty) return '';

    // Find the longest key for alignment
    final maxKeyLength = data.keys
        .map((k) => k.length)
        .reduce((a, b) => a > b ? a : b);

    for (final entry in data.entries) {
      final key = entry.key.padRight(maxKeyLength);
      final value = entry.value;

      if (useColors) {
        buffer.write('$_cyan$key$_reset: $_white$value$_reset\n');
      } else {
        buffer.write('$key: $value\n');
      }
    }

    return buffer.toString().trimRight();
  }

  /// Formats a list of items
  String formatList(List<dynamic> items, {bool useColors = true}) {
    final buffer = StringBuffer();

    for (int i = 0; i < items.length; i++) {
      final item = items[i];

      if (useColors) {
        buffer.write(
          '$_gray${(i + 1).toString().padLeft(2)}. $_reset$_white$item$_reset\n',
        );
      } else {
        buffer.write('${(i + 1).toString().padLeft(2)}. $item\n');
      }
    }

    return buffer.toString().trimRight();
  }
}

/// Global modern console formatter instance
final modernConsoleFormatter = ModernConsoleFormatter();
