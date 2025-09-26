import 'package:flutter/foundation.dart';

/// Centralized logging utility for the application
/// Provides consistent logging across the app with different log levels
class AppLogger {
  static const String _tag = 'KaadoApp';
  
  /// Log debug information (only in debug mode)
  static void debug(String message, [Object? error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      _log('DEBUG', message, error, stackTrace);
    }
  }
  
  /// Log informational messages
  static void info(String message, [Object? error, StackTrace? stackTrace]) {
    _log('INFO', message, error, stackTrace);
  }
  
  /// Log warning messages
  static void warning(String message, [Object? error, StackTrace? stackTrace]) {
    _log('WARNING', message, error, stackTrace);
  }
  
  /// Log error messages
  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    _log('ERROR', message, error, stackTrace);
  }
  
  /// Internal logging method
  static void _log(String level, String message, [Object? error, StackTrace? stackTrace]) {
    final timestamp = DateTime.now().toIso8601String();
    final logMessage = '[$timestamp] [$level] [$_tag] $message';
    
    if (kDebugMode) {
      print(logMessage);
      if (error != null) {
        print('Error: $error');
      }
      if (stackTrace != null) {
        print('StackTrace: $stackTrace');
      }
    }
  }
}
