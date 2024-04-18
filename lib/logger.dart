/// Provides a logging framework with built-in strategies for console, Sentry,
/// and other analytics integration.
///
/// This library is designed to facilitate easy and structured logging across different platforms
/// and services, encapsulating complexity within pre-defined strategies. It's suitable for applications
/// that need robust logging capabilities with minimal setup, including error tracking and performance monitoring.
library logger;

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
