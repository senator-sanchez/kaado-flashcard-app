// Dart imports
import 'dart:async';
import 'dart:collection';

// Flutter imports
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

// Project imports
import 'app_logger.dart';
import 'performance_monitor_service.dart';

/// Service for protecting UI thread and ensuring smooth 60fps performance
/// Implements proper concurrency patterns to prevent UI blocking
class UIThreadService {
  static final UIThreadService _instance = UIThreadService._internal();
  factory UIThreadService() => _instance;
  UIThreadService._internal();

  // Performance monitoring
  final PerformanceMonitorService _performanceMonitor = PerformanceMonitorService();
  
  // UI thread protection
  bool _isUIThreadBlocked = false;
  final Queue<Future<void>> _pendingUIOperations = Queue<Future<void>>();
  Timer? _uiThreadMonitor;
  
  // Frame rate monitoring
  final Queue<Duration> _frameTimes = Queue<Duration>();
  static const int _maxFrameTimeHistory = 60; // 1 second at 60fps
  // Target frame time: 16ms for 60fps
  static const Duration _warningFrameTime = Duration(milliseconds: 33); // 30fps
  
  // Loading states
  final Map<String, bool> _loadingStates = {};
  final Map<String, StreamController<bool>> _loadingControllers = {};
  
  // Skeleton screen management
  final Map<String, bool> _skeletonStates = {};
  final Map<String, StreamController<bool>> _skeletonControllers = {};

  /// Initialize the UI thread service
  void initialize() {
    _startFrameRateMonitoring();
    _startUIThreadProtection();
    AppLogger.info('UIThreadService initialized successfully');
  }

  /// Start frame rate monitoring
  void _startFrameRateMonitoring() {
    SchedulerBinding.instance.addPersistentFrameCallback(_onFrame);
  }

  /// Handle frame callback for performance monitoring
  void _onFrame(Duration frameTime) {
    _frameTimes.add(frameTime);
    
    // Keep only recent frame times
    if (_frameTimes.length > _maxFrameTimeHistory) {
      _frameTimes.removeFirst();
    }
    
    // Check for frame drops
    if (frameTime > _warningFrameTime) {
      AppLogger.warning('Frame drop detected: ${frameTime.inMilliseconds}ms');
    }
  }

  /// Start UI thread protection
  void _startUIThreadProtection() {
    _uiThreadMonitor = Timer.periodic(Duration(milliseconds: 100), (_) {
      _checkUIThreadHealth();
    });
  }

  /// Check UI thread health
  void _checkUIThreadHealth() {
    if (_frameTimes.isEmpty) return;
    
    final totalTime = _frameTimes.fold<Duration>(
      Duration.zero,
      (sum, time) => sum + time,
    );
    final averageFrameTime = Duration(microseconds: totalTime.inMicroseconds ~/ _frameTimes.length);
    
    if (averageFrameTime > _warningFrameTime) {
      AppLogger.warning('UI thread performance degraded: ${averageFrameTime.inMilliseconds}ms average');
    }
  }

  /// Execute operation on UI thread with protection
  Future<T> executeOnUIThread<T>(
    String operationName,
    Future<T> Function() operation,
  ) async {
    if (_isUIThreadBlocked) {
      AppLogger.warning('UI thread blocked, queuing operation: $operationName');
      return await _queueUIOperation(operationName, operation);
    }
    
    return await _executeUIOperation(operationName, operation);
  }

  /// Execute UI operation with monitoring
  Future<T> _executeUIOperation<T>(
    String operationName,
    Future<T> Function() operation,
  ) async {
    _isUIThreadBlocked = true;
    
    try {
      return await _performanceMonitor.trackOperation(operationName, operation);
    } finally {
      _isUIThreadBlocked = false;
      _processQueuedOperations();
    }
  }

  /// Queue UI operation for later execution
  Future<T> _queueUIOperation<T>(
    String operationName,
    Future<T> Function() operation,
  ) async {
    final completer = Completer<T>();
    
    _pendingUIOperations.add(
      _executeUIOperation(operationName, operation).then((result) {
        completer.complete(result);
      }).catchError((error) {
        completer.completeError(error);
      }),
    );
    
    return completer.future;
  }

  /// Process queued UI operations
  void _processQueuedOperations() {
    if (_pendingUIOperations.isNotEmpty && !_isUIThreadBlocked) {
      final operation = _pendingUIOperations.removeFirst();
      operation.then((_) {
        _processQueuedOperations();
      });
    }
  }

  /// Execute operation in background isolate
  Future<T> executeInBackground<T>(
    String operationName,
    T Function() operation,
  ) async {
    return await _performanceMonitor.trackOperation(
      operationName,
      () async => compute(_executeInBackground, operation),
    );
  }

  /// Execute operation in background (top-level function)
  static T _executeInBackground<T>(T Function() operation) {
    return operation();
  }

  /// Execute operation with loading state
  Future<T> executeWithLoading<T>(
    String operationName,
    String loadingKey,
    Future<T> Function() operation,
  ) async {
    _setLoadingState(loadingKey, true);
    
    try {
      return await _performanceMonitor.trackOperation(operationName, operation);
    } finally {
      _setLoadingState(loadingKey, false);
    }
  }

  /// Execute operation with skeleton screen
  Future<T> executeWithSkeleton<T>(
    String operationName,
    String skeletonKey,
    Future<T> Function() operation,
  ) async {
    _setSkeletonState(skeletonKey, true);
    
    try {
      return await _performanceMonitor.trackOperation(operationName, operation);
    } finally {
      _setSkeletonState(skeletonKey, false);
    }
  }

  /// Execute operation with debouncing
  Future<T> executeDebounced<T>(
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

  // Debouncing
  final Map<String, Timer> _debounceTimers = {};

  /// Set loading state
  void _setLoadingState(String key, bool isLoading) {
    _loadingStates[key] = isLoading;
    _loadingControllers[key]?.add(isLoading);
  }

  /// Set skeleton state
  void _setSkeletonState(String key, bool showSkeleton) {
    _skeletonStates[key] = showSkeleton;
    _skeletonControllers[key]?.add(showSkeleton);
  }

  /// Get loading state
  bool isLoading(String key) {
    return _loadingStates[key] ?? false;
  }

  /// Get skeleton state
  bool isShowingSkeleton(String key) {
    return _skeletonStates[key] ?? false;
  }

  /// Get loading state stream
  Stream<bool> getLoadingStateStream(String key) {
    _loadingControllers[key] ??= StreamController<bool>.broadcast();
    return _loadingControllers[key]!.stream;
  }

  /// Get skeleton state stream
  Stream<bool> getSkeletonStateStream(String key) {
    _skeletonControllers[key] ??= StreamController<bool>.broadcast();
    return _skeletonControllers[key]!.stream;
  }

  /// Get current frame rate
  double getCurrentFrameRate() {
    if (_frameTimes.isEmpty) return 0.0;
    
    final totalTime = _frameTimes.fold<Duration>(
      Duration.zero,
      (sum, time) => sum + time,
    );
    final averageFrameTime = Duration(microseconds: totalTime.inMicroseconds ~/ _frameTimes.length);
    
    return 1000.0 / averageFrameTime.inMilliseconds;
  }

  /// Get frame drop rate
  double getFrameDropRate() {
    if (_frameTimes.isEmpty) return 0.0;
    
    final frameDrops = _frameTimes.where((time) => time > _warningFrameTime).length;
    return (frameDrops / _frameTimes.length) * 100.0;
  }

  /// Check if UI thread is healthy
  bool get isUIThreadHealthy {
    final frameRate = getCurrentFrameRate();
    final frameDropRate = getFrameDropRate();
    
    return frameRate >= 55.0 && frameDropRate <= 5.0;
  }

  /// Get performance metrics
  Map<String, dynamic> getPerformanceMetrics() {
    return {
      'currentFrameRate': getCurrentFrameRate(),
      'frameDropRate': getFrameDropRate(),
      'isUIThreadHealthy': isUIThreadHealthy,
      'isUIThreadBlocked': _isUIThreadBlocked,
      'pendingOperations': _pendingUIOperations.length,
      'loadingStates': Map.from(_loadingStates),
      'skeletonStates': Map.from(_skeletonStates),
    };
  }

  /// Get performance warnings
  List<String> getPerformanceWarnings() {
    final warnings = <String>[];
    
    final frameRate = getCurrentFrameRate();
    final frameDropRate = getFrameDropRate();
    
    if (frameRate < 55.0) {
      warnings.add('Low frame rate: ${frameRate.toStringAsFixed(1)}fps (target: 60fps)');
    }
    
    if (frameDropRate > 5.0) {
      warnings.add('High frame drop rate: ${frameDropRate.toStringAsFixed(1)}%');
    }
    
    if (_isUIThreadBlocked) {
      warnings.add('UI thread is blocked');
    }
    
    if (_pendingUIOperations.length > 5) {
      warnings.add('High number of pending UI operations: ${_pendingUIOperations.length}');
    }
    
    return warnings;
  }

  /// Reset performance metrics
  void resetPerformanceMetrics() {
    _frameTimes.clear();
    _isUIThreadBlocked = false;
    _pendingUIOperations.clear();
  }

  /// Dispose the service
  void dispose() {
    _uiThreadMonitor?.cancel();
    _frameTimes.clear();
    _pendingUIOperations.clear();
    
    for (final timer in _debounceTimers.values) {
      timer.cancel();
    }
    _debounceTimers.clear();
    
    for (final controller in _loadingControllers.values) {
      controller.close();
    }
    _loadingControllers.clear();
    
    for (final controller in _skeletonControllers.values) {
      controller.close();
    }
    _skeletonControllers.clear();
    
    _loadingStates.clear();
    _skeletonStates.clear();
  }
}
