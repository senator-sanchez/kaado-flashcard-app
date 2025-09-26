// Dart imports
import 'dart:async';
import 'dart:collection';

// Flutter imports
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Project imports
import 'app_logger.dart';
import 'performance_monitor_service.dart';
import 'ui_thread_service.dart';
import 'isolate_service.dart';
import 'async_database_service.dart';

/// Comprehensive performance optimization service
/// Coordinates all performance optimizations for 60fps target
class PerformanceOptimizationService {
  static final PerformanceOptimizationService _instance = PerformanceOptimizationService._internal();
  factory PerformanceOptimizationService() => _instance;
  PerformanceOptimizationService._internal();

  // Core services
  final PerformanceMonitorService _performanceMonitor = PerformanceMonitorService();
  final UIThreadService _uiThreadService = UIThreadService();
  final IsolateService _isolateService = IsolateService();
  final AsyncDatabaseService _asyncDatabaseService = AsyncDatabaseService();
  
  // Performance optimization state
  bool _isInitialized = false;
  bool _isOptimizationActive = false;
  
  // Performance targets
  static const double _targetFPS = 60.0;
  static const double _warningFPS = 55.0;
  static const double _criticalFPS = 45.0;
  static const double _targetFrameDropRate = 5.0;
  static const double _warningFrameDropRate = 10.0;
  
  // Optimization strategies
  final Map<String, bool> _optimizationStrategies = {
    'isolateProcessing': true,
    'asyncOperations': true,
    'uiThreadProtection': true,
    'caching': true,
    'debouncing': true,
    'parallelProcessing': true,
    'lazyLoading': true,
    'skeletonScreens': true,
  };
  
  // Performance metrics history
  final Queue<Map<String, dynamic>> _metricsHistory = Queue<Map<String, dynamic>>();
  static const int _maxHistorySize = 100;
  
  // Auto-optimization
  Timer? _autoOptimizationTimer;
  bool _autoOptimizationEnabled = true;

  /// Initialize the performance optimization service
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // Initialize core services
      await _isolateService.initialize();
      await _asyncDatabaseService.initialize();
      _uiThreadService.initialize();
      _performanceMonitor.startMonitoring();
      
      // Start auto-optimization
      if (_autoOptimizationEnabled) {
        _startAutoOptimization();
      }
      
      _isInitialized = true;
      _isOptimizationActive = true;
      
      AppLogger.info('PerformanceOptimizationService initialized successfully');
    } catch (e) {
      AppLogger.error('Failed to initialize PerformanceOptimizationService: $e');
      rethrow;
    }
  }

  /// Start auto-optimization monitoring
  void _startAutoOptimization() {
    _autoOptimizationTimer = Timer.periodic(Duration(seconds: 5), (_) {
      _performAutoOptimization();
    });
  }

  /// Perform automatic optimization based on current performance
  void _performAutoOptimization() {
    final metrics = _getCurrentMetrics();
    final fps = metrics['fps'] as double? ?? 0.0;
    final frameDropRate = metrics['frameDropRate'] as double? ?? 0.0;
    
    // Store metrics in history
    _metricsHistory.add(metrics);
    if (_metricsHistory.length > _maxHistorySize) {
      _metricsHistory.removeFirst();
    }
    
    // Apply optimization strategies based on performance
    if (fps < _criticalFPS || frameDropRate > _warningFrameDropRate) {
      _applyCriticalOptimizations();
    } else if (fps < _warningFPS || frameDropRate > _targetFrameDropRate) {
      _applyWarningOptimizations();
    } else {
      _applyMaintenanceOptimizations();
    }
  }

  /// Apply critical optimizations for poor performance
  void _applyCriticalOptimizations() {
    AppLogger.warning('Applying critical performance optimizations');
    
    // Enable all optimization strategies
    _optimizationStrategies.updateAll((key, value) => true);
    
    // Increase cache timeout to reduce database calls
    // This would be implemented in the actual service
    
    // Reduce animation complexity
    // This would be implemented in the actual service
    
    // Force garbage collection
    _forceGarbageCollection();
  }

  /// Apply warning optimizations for moderate performance
  void _applyWarningOptimizations() {
    AppLogger.info('Applying warning performance optimizations');
    
    // Enable most optimization strategies
    _optimizationStrategies.updateAll((key, value) => key != 'skeletonScreens');
    
    // Moderate cache timeout
    // This would be implemented in the actual service
  }

  /// Apply maintenance optimizations for good performance
  void _applyMaintenanceOptimizations() {
    // Keep current optimization strategies
    // Perform maintenance tasks
    
    // Clear old cache entries
    _clearOldCacheEntries();
    
    // Optimize memory usage
    _optimizeMemoryUsage();
  }

  /// Force garbage collection
  void _forceGarbageCollection() {
    // This would trigger garbage collection
    // Implementation depends on the specific platform
  }

  /// Clear old cache entries
  void _clearOldCacheEntries() {
    // This would clear old cache entries
    // Implementation would be in the actual service
  }

  /// Optimize memory usage
  void _optimizeMemoryUsage() {
    // This would optimize memory usage
    // Implementation would be in the actual service
  }

  /// Get current performance metrics
  Map<String, dynamic> _getCurrentMetrics() {
    return {
      ..._performanceMonitor.getPerformanceMetrics(),
      ..._uiThreadService.getPerformanceMetrics(),
    };
  }

  /// Execute operation with performance optimization
  Future<T> executeOptimizedOperation<T>(
    String operationName,
    Future<T> Function() operation, {
    bool useIsolate = false,
    bool useCaching = false,
    bool useDebouncing = false,
    Duration? debounceDelay,
    String? cacheKey,
    Duration? cacheTimeout,
  }) async {
    if (!_isOptimizationActive) {
      return await operation();
    }
    
    // Apply optimization strategies
    if (useIsolate && _optimizationStrategies['isolateProcessing'] == true) {
      // For async operations, we need to handle them differently
      return await _uiThreadService.executeWithLoading(
        operationName,
        'isolate_processing',
        () async => await operation(),
      );
    }
    
    if (useCaching && _optimizationStrategies['caching'] == true && cacheKey != null) {
      return await _asyncDatabaseService.executeCachedOperation(
        operationName,
        cacheKey,
        cacheTimeout ?? Duration(minutes: 5),
        operation,
      );
    }
    
    if (useDebouncing && _optimizationStrategies['debouncing'] == true && debounceDelay != null) {
      return await _uiThreadService.executeDebounced(
        operationName,
        cacheKey ?? operationName,
        debounceDelay,
        operation,
      );
    }
    
    // Default execution with UI thread protection
    return await _uiThreadService.executeOnUIThread(operationName, operation);
  }

  /// Execute multiple operations in parallel
  Future<List<T>> executeParallelOperations<T>(
    String operationName,
    List<Future<T> Function()> operations,
  ) async {
    if (!_isOptimizationActive || _optimizationStrategies['parallelProcessing'] != true) {
      // Execute sequentially if parallel processing is disabled
      final results = <T>[];
      for (final operation in operations) {
        results.add(await operation());
      }
      return results;
    }
    
    return await _asyncDatabaseService.executeParallelOperations(
      operationName,
      operations,
    );
  }

  /// Execute operation with loading state
  Future<T> executeWithLoading<T>(
    String operationName,
    String loadingKey,
    Future<T> Function() operation,
  ) async {
    return await _uiThreadService.executeWithLoading(operationName, loadingKey, operation);
  }

  /// Execute operation with skeleton screen
  Future<T> executeWithSkeleton<T>(
    String operationName,
    String skeletonKey,
    Future<T> Function() operation,
  ) async {
    return await _uiThreadService.executeWithSkeleton(operationName, skeletonKey, operation);
  }

  /// Get performance optimization status
  Map<String, dynamic> getOptimizationStatus() {
    return {
      'isInitialized': _isInitialized,
      'isOptimizationActive': _isOptimizationActive,
      'autoOptimizationEnabled': _autoOptimizationEnabled,
      'optimizationStrategies': Map.from(_optimizationStrategies),
      'currentMetrics': _getCurrentMetrics(),
      'metricsHistorySize': _metricsHistory.length,
    };
  }

  /// Enable/disable optimization strategy
  void setOptimizationStrategy(String strategy, bool enabled) {
    if (_optimizationStrategies.containsKey(strategy)) {
      _optimizationStrategies[strategy] = enabled;
      AppLogger.info('Optimization strategy $strategy ${enabled ? 'enabled' : 'disabled'}');
    }
  }

  /// Enable/disable auto-optimization
  void setAutoOptimization(bool enabled) {
    _autoOptimizationEnabled = enabled;
    
    if (enabled && _autoOptimizationTimer == null) {
      _startAutoOptimization();
    } else if (!enabled && _autoOptimizationTimer != null) {
      _autoOptimizationTimer?.cancel();
      _autoOptimizationTimer = null;
    }
    
    AppLogger.info('Auto-optimization ${enabled ? 'enabled' : 'disabled'}');
  }

  /// Get performance recommendations
  List<String> getPerformanceRecommendations() {
    final recommendations = <String>[];
    final metrics = _getCurrentMetrics();
    
    final fps = metrics['fps'] as double? ?? 0.0;
    final frameDropRate = metrics['frameDropRate'] as double? ?? 0.0;
    final slowOperationRate = metrics['slowOperationRate'] as double? ?? 0.0;
    
    if (fps < _targetFPS) {
      recommendations.add('Consider enabling isolate processing for heavy operations');
    }
    
    if (frameDropRate > _targetFrameDropRate) {
      recommendations.add('Enable UI thread protection to prevent blocking');
    }
    
    if (slowOperationRate > 10.0) {
      recommendations.add('Consider using caching and debouncing for database operations');
    }
    
    if (!_optimizationStrategies['parallelProcessing']!) {
      recommendations.add('Enable parallel processing for better performance');
    }
    
    if (!_optimizationStrategies['lazyLoading']!) {
      recommendations.add('Enable lazy loading for large datasets');
    }
    
    return recommendations;
  }

  /// Get performance history
  List<Map<String, dynamic>> getPerformanceHistory() {
    return List.from(_metricsHistory);
  }

  /// Clear performance history
  void clearPerformanceHistory() {
    _metricsHistory.clear();
  }

  /// Get performance summary
  String getPerformanceSummary() {
    final metrics = _getCurrentMetrics();
    final fps = metrics['fps'] as double? ?? 0.0;
    final frameDropRate = metrics['frameDropRate'] as double? ?? 0.0;
    final isHealthy = metrics['isUIThreadHealthy'] as bool? ?? false;
    
    return '''
Performance Summary:
- FPS: ${fps.toStringAsFixed(1)} (target: $_targetFPS)
- Frame Drop Rate: ${frameDropRate.toStringAsFixed(1)}% (target: $_targetFrameDropRate%)
- UI Thread Healthy: $isHealthy
- Optimization Active: $_isOptimizationActive
- Auto-Optimization: $_autoOptimizationEnabled
- Strategies Enabled: ${_optimizationStrategies.values.where((v) => v).length}/${_optimizationStrategies.length}
''';
  }

  /// Dispose the service
  void dispose() {
    _autoOptimizationTimer?.cancel();
    _performanceMonitor.stopMonitoring();
    _uiThreadService.dispose();
    _isolateService.dispose();
    _asyncDatabaseService.dispose();
    _metricsHistory.clear();
    _isInitialized = false;
    _isOptimizationActive = false;
  }
}

/// Riverpod provider for PerformanceOptimizationService
final performanceOptimizationServiceProvider = Provider<PerformanceOptimizationService>((ref) {
  return PerformanceOptimizationService();
});
