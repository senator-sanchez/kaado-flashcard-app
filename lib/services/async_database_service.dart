// Dart imports
import 'dart:async';
import 'dart:io';

// Flutter imports
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Project imports
import 'app_logger.dart';
import 'performance_monitor_service.dart';

/// Async-optimized database service with parallel operations and debouncing
class AsyncDatabaseService {
  static final AsyncDatabaseService _instance = AsyncDatabaseService._internal();
  factory AsyncDatabaseService() => _instance;
  AsyncDatabaseService._internal();

  // Database management
  static Database? _database;
  static bool _isInitializing = false;
  
  // Performance monitoring
  final PerformanceMonitorService _performanceMonitor = PerformanceMonitorService();
  
  // Caching and debouncing
  final Map<String, dynamic> _cache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheTimeout = Duration(minutes: 5);
  
  // Debouncing
  final Map<String, Timer> _debounceTimers = {};
  
  // Parallel operation management
  final Set<String> _activeOperations = {};

  /// Initialize the async database service
  Future<void> initialize() async {
    try {
      await _ensureDatabaseInitialized();
      AppLogger.info('AsyncDatabaseService initialized successfully');
    } catch (e) {
      AppLogger.error('Failed to initialize AsyncDatabaseService: $e');
      rethrow;
    }
  }

  /// Ensure database is fully initialized
  Future<void> _ensureDatabaseInitialized() async {
    if (_database != null) return;
    
    if (_isInitializing) {
      while (_isInitializing) {
        await Future.delayed(Duration(milliseconds: 10));
      }
      return;
    }
    
    _isInitializing = true;
    try {
      _database = await _initDatabase();
    } finally {
      _isInitializing = false;
    }
  }

  /// Get database instance
  Future<Database> get database async {
    await _ensureDatabaseInitialized();
    return _database!;
  }

  /// Initialize database with optimized settings
  Future<Database> _initDatabase() async {
    return await _performanceMonitor.trackOperation(
      'database_initialization',
      () async {
        final dbPath = await _getDatabasePath();
        
        final dbFile = File(dbPath);
        if (!dbFile.existsSync()) {
          await _copyDatabaseFromAssets(dbFile);
        }
        
        final db = await openDatabase(
          dbPath,
          readOnly: false,
          onConfigure: (db) async {
            await db.execute('PRAGMA journal_mode=WAL');
            await db.execute('PRAGMA synchronous=NORMAL');
            await db.execute('PRAGMA cache_size=10000');
            await db.execute('PRAGMA temp_store=MEMORY');
          },
        );
        
        return db;
      },
    );
  }

  /// Get database path
  Future<String> _getDatabasePath() async {
    try {
      final documentsDirectory = await getApplicationDocumentsDirectory();
      return join(documentsDirectory.path, 'japanese.db');
    } catch (e) {
      AppLogger.error('Error getting database path: $e');
      rethrow;
    }
  }

  /// Copy database from assets
  Future<void> _copyDatabaseFromAssets(File dbFile) async {
    int attempts = 0;
    const maxAttempts = 3;
    
    while (attempts < maxAttempts) {
      try {
        final ByteData data = await rootBundle.load('assets/database/japanese.db');
        
        final parentDir = dbFile.parent;
        if (!parentDir.existsSync()) {
          await parentDir.create(recursive: true);
        }
        
        if (dbFile.existsSync()) {
          await dbFile.delete();
        }
        
        final bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
        await dbFile.writeAsBytes(bytes);
        
        return;
      } catch (e) {
        attempts++;
        AppLogger.error('Error copying database (attempt $attempts): $e');
        
        if (attempts >= maxAttempts) {
          rethrow;
        }
        
        await Future.delayed(Duration(milliseconds: 500 * attempts));
      }
    }
  }

  /// Execute database operation with performance tracking
  Future<T> executeOperation<T>(
    String operationName,
    Future<T> Function() operation,
  ) async {
    return await _performanceMonitor.trackOperation(operationName, operation);
  }

  /// Execute multiple database operations in parallel
  Future<List<T>> executeParallelOperations<T>(
    String operationName,
    List<Future<T> Function()> operations,
  ) async {
    return await _performanceMonitor.trackOperation(
      operationName,
      () async => Future.wait(operations.map((op) => op())),
    );
  }

  /// Execute database operation with debouncing
  Future<T> executeDebouncedOperation<T>(
    String operationName,
    String debounceKey,
    Duration debounceDelay,
    Future<T> Function() operation,
  ) async {
    // Cancel existing timer
    _debounceTimers[debounceKey]?.cancel();
    
    final completer = Completer<T>();
    
    _debounceTimers[debounceKey] = Timer(debounceDelay, () async {
      try {
        final result = await _performanceMonitor.trackOperation(operationName, operation);
        completer.complete(result);
      } catch (e) {
        completer.completeError(e);
      }
    });
    
    return completer.future;
  }

  /// Execute database operation with caching
  Future<T> executeCachedOperation<T>(
    String operationName,
    String cacheKey,
    Duration cacheTimeout,
    Future<T> Function() operation,
  ) async {
    // Check cache first
    if (_isCacheValid(cacheKey)) {
      return _cache[cacheKey] as T;
    }
    
    // Execute operation
    final result = await _performanceMonitor.trackOperation(operationName, operation);
    
    // Cache result
    _cache[cacheKey] = result;
    _cacheTimestamps[cacheKey] = DateTime.now();
    
    return result;
  }

  /// Execute database operation with retry logic
  Future<T> executeWithRetry<T>(
    String operationName,
    Future<T> Function() operation, {
    int maxRetries = 3,
    Duration retryDelay = const Duration(milliseconds: 500),
  }) async {
    int attempts = 0;
    
    while (attempts < maxRetries) {
      try {
        return await _performanceMonitor.trackOperation(operationName, operation);
      } catch (e) {
        attempts++;
        AppLogger.error('Operation failed (attempt $attempts): $e');
        
        if (attempts >= maxRetries) {
          rethrow;
        }
        
        await Future.delayed(retryDelay * attempts);
      }
    }
    
    throw Exception('Operation failed after $maxRetries attempts');
  }

  /// Execute database operation in isolate
  Future<T> executeInIsolate<T>(
    String operationName,
    T Function() operation,
  ) async {
    return await _performanceMonitor.trackOperation(
      operationName,
      () async => compute(_executeInIsolate, operation),
    );
  }

  /// Execute operation in isolate (top-level function)
  static T _executeInIsolate<T>(T Function() operation) {
    return operation();
  }

  /// Check if cache is valid
  bool _isCacheValid(String key) {
    if (!_cache.containsKey(key)) return false;
    
    final timestamp = _cacheTimestamps[key];
    if (timestamp == null) return false;
    
    return DateTime.now().difference(timestamp) < _cacheTimeout;
  }

  /// Clear cache
  void clearCache() {
    _cache.clear();
    _cacheTimestamps.clear();
  }

  /// Clear cache for specific pattern
  void clearCacheForPattern(String pattern) {
    final keysToRemove = _cache.keys.where((key) => key.startsWith(pattern)).toList();
    for (final key in keysToRemove) {
      _cache.remove(key);
      _cacheTimestamps.remove(key);
    }
  }

  /// Get cache statistics
  Map<String, dynamic> getCacheStatistics() {
    return {
      'cacheSize': _cache.length,
      'cacheKeys': _cache.keys.toList(),
      'oldestEntry': _cacheTimestamps.values.isNotEmpty 
          ? _cacheTimestamps.values.reduce((a, b) => a.isBefore(b) ? a : b)
          : null,
      'newestEntry': _cacheTimestamps.values.isNotEmpty
          ? _cacheTimestamps.values.reduce((a, b) => a.isAfter(b) ? a : b)
          : null,
    };
  }

  /// Dispose the service
  void dispose() {
    for (final timer in _debounceTimers.values) {
      timer.cancel();
    }
    _debounceTimers.clear();
    _cache.clear();
    _cacheTimestamps.clear();
    _activeOperations.clear();
  }
}

/// Riverpod provider for AsyncDatabaseService
final asyncDatabaseServiceProvider = Provider<AsyncDatabaseService>((ref) {
  return AsyncDatabaseService();
});
