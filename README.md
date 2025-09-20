Strategic Logger - One Call Logs All!
================

Easy to use and extensible logger designed to support multiple logging strategies, like Firebase Crashlytics, Sentry, Firebase Analytics, and other that you want. 

Show some ❤️ and star the repo to support the project


Features
--------

*   **Multiple & Built-in Log Strategies**: Firebase Crashlytics, Sentry, Firebase Analytics, ConsoleLog already implemented. (See examples tab) 
    
*   **Customizable**: Extendable to include custom logging strategies depending on your application needs.
    
*   **Easy to Use**: Simple API for logging messages, errors, and fatal incidents across all integrated services.
    
*   **Robust Error Handling**: Includes predefined error types for handling common logging errors effectively.
    

Getting Started
---------------

To get started with Strategic Logger, add it to your project as a dependency:

dependencies:strategic\_logger: ^0.2.0

### Initialization

Initialize the logger once during the startup of your application:

```dart
import 'package:strategic\_logger/strategic\_logger.dart';

void main() {
    logger.initialize(
        level: LogLevel.info,
        strategies: [
            ConsoleLogStrategy(),
            FirebaseAnalyticsLogStrategy(),
            FirebaseCrashlyticsLogStrategy(),
        ],
    );
}
```
### Usage

Logging messages is straightforward: (Easy and clean-code)

```dart
logger.log('This is an info log');
logger.info('This is an info log too');
logger.error('This is an error message');
logger.fatal('This is a fatal error');
```

You can also log detailed events:

```dart

logger.log('User logged in', event: LogEvent(eventName: 'user\_login'));

```

Documentation
-------------

For full documentation, including all configuration options and advanced usage examples, see examples tab.

Extending the Logger (Your Custom Strategy)
--------------------

To add a custom log strategy, extend the LogStrategy class:

```dart

class MyCustomLogStrategy extends LogStrategy {
    @override
    Future log({dynamic message, LogEvent? event}) async {
    // Implement custom logging logic here
    }
}
```

Register your custom strategy during logger initialization.

Contributing
------------

Contributions are welcome! Please read the contributing guide on our GitHub repository to get started.
<a href="https://www.buymeacoffee.com/sauloroncon" target="_blank"><img src="https://cdn.buymeacoffee.com/buttons/v2/default-yellow.png" alt="Buy Me A Coffee" style="width: 150px; height: auto;"></a>

License
-------

Strategic Logger is released under the MIT License.

