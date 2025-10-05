# Strategic Logger Example App

This example app demonstrates all the features and capabilities of the Strategic Logger package.

## Features Demonstrated

### 🎯 Log Levels
- **Debug**: Detailed information for debugging
- **Info**: General information messages
- **Warning**: Warning messages for potential issues
- **Error**: Error messages for recoverable errors
- **Fatal**: Critical errors that may cause app termination

### 🚀 Special Features
- **Structured Logging**: Log structured events with custom parameters
- **Performance Testing**: High-volume logging simulation
- **Error Testing**: Exception handling and stack trace logging

### 📊 Context Examples
- **User Actions**: Log user interactions with context
- **API Calls**: Log API requests and responses
- **Database Operations**: Log database queries and results

### ⚡ Performance Monitoring
- Built-in performance metrics
- Isolate-based processing
- Object pooling
- Log compression

## How to Run

1. Navigate to the example directory:
   ```bash
   cd example
   ```

2. Get dependencies:
   ```bash
   flutter pub get
   ```

3. Run the app:
   ```bash
   flutter run
   ```

## Configuration

The example app initializes Strategic Logger with all available strategies:

- **Console Logging**: Beautiful console output with colors and emojis
- **Sentry**: Error tracking and monitoring
- **Firebase Crashlytics**: Crash reporting
- **Firebase Analytics**: User analytics
- **Datadog**: Application monitoring
- **New Relic**: Performance monitoring
- **MCP**: Model Context Protocol integration
- **AI**: AI-powered log analysis

## Usage

1. **Log Levels**: Tap the colored buttons to send logs at different levels
2. **Special Features**: Test structured logging, performance, and error scenarios
3. **Context Examples**: See how to log with rich context data
4. **Performance Stats**: View real-time performance metrics

## Customization

You can modify the example to:
- Add your own API keys for external services
- Customize log messages and context
- Test different logging strategies
- Experiment with performance settings

## Learn More

Visit the [Strategic Logger documentation](https://github.com/sauloroncon/strategic_logger) for more information about:
- Advanced configuration options
- Custom strategy implementation
- Performance optimization
- Integration patterns