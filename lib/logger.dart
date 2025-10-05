/// Strategic Logger - Modern, high-performance logging framework for Flutter & Dart applications
/// 
/// This package provides a comprehensive logging solution with multi-strategy support,
/// isolate-based processing, and beautiful console output.
library logger;

/// and other analytics integration.
///
/// This library is designed to facilitate easy and structured logging across different platforms
/// and services, encapsulating complexity within pre-defined strategies. It's suitable for applications
/// that need robust logging capabilities with minimal setup, including error tracking and performance monitoring.
///
/// Features:
/// - Isolate-based processing for heavy operations
/// - Performance monitoring and metrics
/// - Modern console formatting with colors and emojis
/// - Compatibility with popular logger packages
/// - Async queue with backpressure control

/// Initializes the logger with default settings. Example usage:
///
/// ```dart
/// logger.initialize(level: LogLevel.info);
/// ```
export 'src/strategic_logger.dart';

/// Enum defining various levels of logging.
///
/// This enum is used throughout the logging system to set the minimum level of messages
/// that should be logged, providing control over what is logged based on severity.
export 'src/enums/log_level.dart';

/// Base class for log events.
///
/// This class can be extended to define custom log events. It includes basic properties
/// like event name and parameters that can be used to pass additional data with each log.
export 'src/events/log_event.dart';

// Built-in strategies
/// Strategy for logging messages to the console using Dart's `developer` library.
///
/// This strategy is useful for development and debugging purposes where logs should be
/// visible in the console of the development tools or the terminal.
export 'src/strategies/console/console_log_strategy.dart';

/// Represents a log event specifically formatted for console output.
export 'src/strategies/console/console_log_event.dart';

/// A logging strategy that integrates with Sentry.
///
/// This strategy sends logging information to Sentry, allowing for detailed
/// error tracking and performance monitoring within the Sentry platform. It's ideal for applications that
/// require robust error handling and insights into issues occurring in production environments.
export 'src/strategies/sentry/sentry_log_strategy.dart';

/// Log event specifically tailored for Sentry.
///
/// This class is an extension of the generic LogEvent tailored to meet the requirements
/// of Sentry, providing a structured way to send error data and performance metrics to Sentry.
/// It should be used when detailed error analysis and monitoring are needed.
export 'src/strategies/sentry/sentry_log_event.dart';

/// Log event specifically tailored for Firebase Analytics.
///
/// This class is an extension of the generic LogEvent tailored to meet the requirements
/// of Firebase Analytics, providing a structured way to send event data to Firebase.
/// It should be used when detailed analytics about application behavior are needed.
export 'src/strategies/analytics/firebase_analytics_log_event.dart';

/// A logging strategy that integrates with Firebase Analytics.
///
/// This strategy sends logging information to Firebase Analytics, allowing for detailed
/// analysis and tracking within the Firebase platform. It's ideal for applications that
/// require insights into user interactions and app functionality via Firebase's analytics tools.
export 'src/strategies/analytics/firebase_analytics_log_strategy.dart';

/// Log event specifically tailored for Firebase Crashlytics.
///
/// Extends LogEvent to suit the specific needs of Firebase Crashlytics logging, such as
/// reporting errors and crashes. It provides a convenient way to structure error-related
/// data and send it to Firebase Crashlytics for detailed crash analysis and monitoring.
export 'src/strategies/crashlytics/firebase_crashlytics_log_event.dart';

/// A logging strategy that integrates with Firebase Crashlytics.
///
/// This strategy is designed to log critical issues to Firebase Crashlytics, enhancing
/// the ability to track and analyze application crashes and significant errors.
/// It's particularly useful for maintaining high reliability and quick debugging in production environments.
export 'src/strategies/crashlytics/firebase_crashlytics_log_strategy.dart';

/// Error thrown when an attempt is made to re-initialize an already initialized logger.
///
/// This exception helps prevent accidental reconfiguration of the logger which might
/// lead to inconsistent logging behavior.
export 'src/errors/alread_initialized_error.dart';

/// Error thrown when operations are attempted on an uninitialized logger.
///
/// This exception ensures that the logger is properly set up before use, guarding
/// against runtime errors due to misconfiguration or sequence errors in initialization.
export 'src/errors/not_initialized_error.dart';

// Modern features
/// Compatibility wrapper for popular logger packages
export 'src/compatibility/logger_sync_compatibility.dart';

/// Modern console formatter with colors and emojis
export 'src/console/modern_console_formatter.dart';

// New strategies
/// Strategy for logging messages to Datadog
export 'src/strategies/datadog/datadog_log_strategy.dart';

/// Log event specifically tailored for Datadog
export 'src/strategies/datadog/datadog_log_event.dart';

/// Strategy for logging messages to New Relic
export 'src/strategies/newrelic/newrelic_log_strategy.dart';

/// Log event specifically tailored for New Relic
export 'src/strategies/newrelic/newrelic_log_event.dart';

// MCP & AI Integration (v1.1.0)
/// Model Context Protocol (MCP) Server for Strategic Logger
export 'src/mcp/mcp_server.dart';

/// MCP Log Strategy for AI agent integration
export 'src/mcp/mcp_log_strategy.dart';

/// AI Log Strategy for intelligent log analysis
export 'src/ai/ai_log_strategy.dart';

// Performance & Optimization (v1.1.0)
/// Object Pool for efficient memory management
export 'src/core/object_pool.dart' hide LogEvent;

/// Log Compression for bandwidth optimization
export 'src/core/log_compression.dart';
