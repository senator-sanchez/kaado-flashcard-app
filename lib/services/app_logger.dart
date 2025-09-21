/// App Logger Service
/// 
/// This service provides centralized logging functionality for the app.
/// It helps with debugging and monitoring app behavior.

import 'dart:developer' as developer;

/// Centralized logging service for the app
class AppLogger {
  /// Log an info message
  static void info(String message) {
    developer.log(message, name: 'AppLogger', level: 800);
  }

  /// Log an error message with optional exception
  static void error(String message, [dynamic error, StackTrace? stackTrace]) {
    developer.log(
      message,
      name: 'AppLogger',
      level: 1000,
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Log a warning message
  static void warning(String message) {
    developer.log(message, name: 'AppLogger', level: 900);
  }

  /// Log a debug message
  static void debug(String message) {
    developer.log(message, name: 'AppLogger', level: 700);
  }
}
