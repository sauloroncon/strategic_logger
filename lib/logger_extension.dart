/// Provides the necessary components for extending the Strategic Logger with custom logging strategies.
///
/// This library exposes the core functionalities and base classes required for developers
/// to create and integrate new log strategies. It is ideal for developers looking to implement
/// customized logging behavior or to integrate with logging platforms not supported out of the box.
library logger_extension;

/// Core logger class that manages the logging operations.
/// This class can be utilized to understand the fundamental logging mechanism and to
/// ensure compatibility with custom log strategies.
export 'src/strategic_logger.dart';

/// Base class for all log strategies.
///
/// Extend this class to create custom log strategies. It defines the essential methods
/// that all log strategies must implement, such as `log()`, `error()`, and `fatal()`.
export 'src/strategies/log_strategy.dart';

/// Base class for log events.
///
/// This class can be extended to define custom log events that carry specific data
/// relevant to your custom log strategy. It includes properties like event name and
/// parameters that facilitate passing rich data in logs.
export 'src/events/log_event.dart';

/// Enumerates the different log levels used within the logger.
///
/// Understanding these levels is crucial when developing custom log strategies,
/// as it helps in deciding how to handle different severities of log messages.
export 'src/enums/log_level.dart';
