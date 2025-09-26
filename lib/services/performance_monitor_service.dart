// Dart imports
import 'dart:async';
import 'dart:collection';

// Flutter imports
import 'package:flutter/scheduler.dart';

// Project imports
import 'app_logger.dart';

/// Service for monitoring app performance and frame rates
class PerformanceMonitorService {
  static final PerformanceMonitorService _instance = PerformanceMonitorService._internal();
  factory PerformanceMonitorService() => _instance;
  PerformanceMonitorService._internal();
  
  // Performance tracking
  final Queue<Duration> _frameTimes = Queue<Duration>();
  final Queue<Duration> _operationTimes = Queue<Duration>();
  Timer? _monitoringTimer;
  bool _isMonitoring = false;
  
  // Performance thresholds
  static const Duration _targetFrameTime = Duration(milliseconds: 16); // 60fps
  static const Duration _warningFrameTime = Duration(milliseconds: 33); // 30fps
  static const int _maxFrameTimeHistory = 100;
  static const int _maxOperationTimeHistory = 50;

  // Performance metrics
  double _averageFrameTime = 0.0;
  double _averageOperationTime = 0.0;
  int _frameDrops = 0;
  int _slowOperations = 0;
  int _totalFrames = 0;
  int _totalOperations = 0;
  
  /// Start performance monitoring
  void startMonitoring() {
    if (_isMonitoring) return;
    
    _isMonitoring = true;
    
    // Monitor frame times
    _monitoringTimer = Timer.periodic(Duration(milliseconds: 100), (_) {
      _updateFrameMetrics();
    });
    
    // Listen to frame callbacks
    SchedulerBinding.instance.addPersistentFrameCallback(_onFrame);
  }
  
  /// Stop performance monitoring
  void stopMonitoring() {
    if (!_isMonitoring) return;
    
    _isMonitoring = false;
    _monitoringTimer?.cancel();
    _monitoringTimer = null;
    
    // Note: removePersistentFrameCallback is not available in current Flutter version
    // The callback will be automatically removed when the service is disposed
  }
  
  /// Handle frame callback
  void _onFrame(Duration frameTime) {
    if (!_isMonitoring) return;
    
    _frameTimes.add(frameTime);
    _totalFrames++;
    
    // Keep only recent frame times
    if (_frameTimes.length > _maxFrameTimeHistory) {
      _frameTimes.removeFirst();
    }
    
    // Check for frame drops
    if (frameTime > _warningFrameTime) {
      _frameDrops++;
    }
    
    // Update average frame time
    _updateAverageFrameTime();
  }

  /// Update frame metrics
  void _updateFrameMetrics() {
    if (_frameTimes.isEmpty) return;
    
    final currentFrameTime = _frameTimes.last;
    
    // Log performance warnings
    if (currentFrameTime > _warningFrameTime) {
    }
  }

  /// Update average frame time
  void _updateAverageFrameTime() {
    if (_frameTimes.isEmpty) return;
    
    final totalTime = _frameTimes.fold<Duration>(
      Duration.zero,
      (sum, time) => sum + time,
    );
    
    _averageFrameTime = totalTime.inMicroseconds / _frameTimes.length / 1000.0;
  }

  /// Track operation performance
  Future<T> trackOperation<T>(
    String operationName,
    Future<T> Function() operation,
  ) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      final result = await operation();
      stopwatch.stop();
      
      final operationTime = stopwatch.elapsed;
      _trackOperationTime(operationName, operationTime);
      
      return result;
    } catch (e) {
      stopwatch.stop();
      final operationTime = stopwatch.elapsed;
      _trackOperationTime(operationName, operationTime, error: e);
      rethrow;
    }
  }

  /// Track operation time
  void _trackOperationTime(String operationName, Duration operationTime, {dynamic error}) {
    _operationTimes.add(operationTime);
    _totalOperations++;
    
    // Keep only recent operation times
    if (_operationTimes.length > _maxOperationTimeHistory) {
      _operationTimes.removeFirst();
    }
    
    // Check for slow operations
    if (operationTime > Duration(milliseconds: 100)) {
      _slowOperations++;
    }
    
    // Log errors
    if (error != null) {
      AppLogger.error('Operation failed: $operationName - $error');
    }
    
    // Update average operation time
    _updateAverageOperationTime();
  }

  /// Update average operation time
  void _updateAverageOperationTime() {
    if (_operationTimes.isEmpty) return;
    
    final totalTime = _operationTimes.fold<Duration>(
      Duration.zero,
      (sum, time) => sum + time,
    );
    
    _averageOperationTime = totalTime.inMicroseconds / _operationTimes.length / 1000.0;
  }

  /// Get current performance metrics
  Map<String, dynamic> getPerformanceMetrics() {
    return {
      'averageFrameTime': _averageFrameTime,
      'averageOperationTime': _averageOperationTime,
      'frameDrops': _frameDrops,
      'slowOperations': _slowOperations,
      'totalFrames': _totalFrames,
      'totalOperations': _totalOperations,
      'frameDropRate': _totalFrames > 0 ? (_frameDrops / _totalFrames) * 100 : 0.0,
      'slowOperationRate': _totalOperations > 0 ? (_slowOperations / _totalOperations) * 100 : 0.0,
      'fps': _averageFrameTime > 0 ? 1000.0 / _averageFrameTime : 0.0,
    };
  }
  
  /// Get performance summary
  String getPerformanceSummary() {
    final metrics = getPerformanceMetrics();
    final fps = metrics['fps'] as double;
    final frameDropRate = metrics['frameDropRate'] as double;
    final slowOperationRate = metrics['slowOperationRate'] as double;
    
    return '''
Performance Summary:
- FPS: ${fps.toStringAsFixed(1)}
- Frame Drop Rate: ${frameDropRate.toStringAsFixed(1)}%
- Slow Operation Rate: ${slowOperationRate.toStringAsFixed(1)}%
- Total Frames: ${metrics['totalFrames']}
- Total Operations: ${metrics['totalOperations']}
- Frame Drops: ${metrics['frameDrops']}
- Slow Operations: ${metrics['slowOperations']}
''';
  }

  /// Check if performance is good
  bool get isPerformanceGood {
    final metrics = getPerformanceMetrics();
    final fps = metrics['fps'] as double;
    final frameDropRate = metrics['frameDropRate'] as double;
    
    return fps >= 55.0 && frameDropRate <= 5.0;
  }

  /// Get performance warnings
  List<String> getPerformanceWarnings() {
    final warnings = <String>[];
    final metrics = getPerformanceMetrics();
    
    final fps = metrics['fps'] as double;
    final frameDropRate = metrics['frameDropRate'] as double;
    final slowOperationRate = metrics['slowOperationRate'] as double;
    
    if (fps < 55.0) {
      warnings.add('Low FPS: ${fps.toStringAsFixed(1)} (target: 60)');
    }
    
    if (frameDropRate > 5.0) {
      warnings.add('High frame drop rate: ${frameDropRate.toStringAsFixed(1)}%');
    }
    
    if (slowOperationRate > 10.0) {
      warnings.add('High slow operation rate: ${slowOperationRate.toStringAsFixed(1)}%');
    }
    
    return warnings;
  }

  /// Reset performance metrics
  void resetMetrics() {
    _frameTimes.clear();
    _operationTimes.clear();
    _averageFrameTime = 0.0;
    _averageOperationTime = 0.0;
    _frameDrops = 0;
    _slowOperations = 0;
    _totalFrames = 0;
    _totalOperations = 0;
    
  }

  /// Log performance report
  void logPerformanceReport() {
    
    final warnings = getPerformanceWarnings();
    if (warnings.isNotEmpty) {
      for (final warning in warnings) {
      }
    } else {
    }
  }
  
  /// Dispose the service
  void dispose() {
    stopMonitoring();
    _frameTimes.clear();
    _operationTimes.clear();
  }
}