/// Provides a logging framework with built-in strategies for console, Firebase Analytics, 
/// and Firebase Crashlytics integration.
/// 
/// This library is designed to facilitate easy and structured logging across different platforms
/// and services, encapsulating complexity within pre-defined strategies. It's suitable for applications
/// that need straightforward logging capabilities with minimal setup.
library logger_usage;

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

