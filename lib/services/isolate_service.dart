// Dart imports
import 'dart:async';
import 'dart:convert';
import 'dart:isolate';

// Flutter imports
import 'package:flutter/foundation.dart';

// Project imports
import 'app_logger.dart';

/// Service for managing isolate-based background processing
/// Handles JSON parsing, image processing, and heavy computations off the main thread
class IsolateService {
  static final IsolateService _instance = IsolateService._internal();
  factory IsolateService() => _instance;
  IsolateService._internal();

  // Isolate management
  Isolate? _backgroundIsolate;
  SendPort? _backgroundSendPort;
  ReceivePort? _backgroundReceivePort;
  final Map<String, Completer<dynamic>> _pendingOperations = {};
  int _operationId = 0;

  // Performance tracking
  // Performance monitoring available but not actively used

  /// Initialize the isolate service
  Future<void> initialize() async {
    try {
      await _startBackgroundIsolate();
      AppLogger.info('IsolateService initialized successfully');
    } catch (e) {
      AppLogger.error('Failed to initialize IsolateService: $e');
      rethrow;
    }
  }

  /// Start background isolate for heavy operations
  Future<void> _startBackgroundIsolate() async {
    _backgroundReceivePort = ReceivePort();
    _backgroundIsolate = await Isolate.spawn(
      _backgroundIsolateEntryPoint,
      _backgroundReceivePort!.sendPort,
    );

    // Listen for messages from background isolate
    _backgroundReceivePort!.listen(_handleBackgroundMessageInMain);
  }

  /// Background isolate entry point
  static void _backgroundIsolateEntryPoint(SendPort mainSendPort) {
    final backgroundReceivePort = ReceivePort();
    mainSendPort.send(backgroundReceivePort.sendPort);

    backgroundReceivePort.listen((message) {
      _handleBackgroundMessageInIsolate(message, mainSendPort);
    });
  }

  /// Handle messages in background isolate
  static void _handleBackgroundMessageInIsolate(dynamic message, SendPort mainSendPort) {
    if (message is Map<String, dynamic>) {
      final operation = message['operation'] as String;
      final operationId = message['operationId'] as String;
      final data = message['data'];

      try {
        dynamic result;
        switch (operation) {
          case 'parseJson':
            result = _parseJsonInIsolate(data);
            break;
          case 'encodeJson':
            result = _encodeJsonInIsolate(data);
            break;
          case 'processImage':
            result = _processImageInIsolate(data);
            break;
          case 'compressImage':
            result = _compressImageInIsolate(data);
            break;
          case 'calculateSRS':
            result = _calculateSRSInIsolate(data);
            break;
          case 'processDatabaseQuery':
            result = _processDatabaseQueryInIsolate(data);
            break;
          default:
            throw Exception('Unknown operation: $operation');
        }

        mainSendPort.send({
          'operationId': operationId,
          'success': true,
          'result': result,
        });
      } catch (e) {
        mainSendPort.send({
          'operationId': operationId,
          'success': false,
          'error': e.toString(),
        });
      }
    }
  }

  /// Handle messages from background isolate in main isolate
  void _handleBackgroundMessageInMain(dynamic message) {
    if (message is Map<String, dynamic>) {
      final operationId = message['operationId'] as String;
      final completer = _pendingOperations.remove(operationId);
        
        if (completer != null) {
        if (message['success'] == true) {
          completer.complete(message['result']);
          } else {
          completer.completeError(Exception(message['error']));
        }
      }
    }
  }

  /// Parse JSON in background isolate
  Future<Map<String, dynamic>> parseJson(String jsonString) async {
    return await _sendToBackgroundIsolate('parseJson', jsonString);
  }

  /// Encode JSON in background isolate
  Future<String> encodeJson(Map<String, dynamic> data) async {
    return await _sendToBackgroundIsolate('encodeJson', data);
  }

  /// Process image in background isolate
  Future<Uint8List> processImage(Uint8List imageData, {
    int? width,
    int? height,
    double? quality,
  }) async {
    return await _sendToBackgroundIsolate('processImage', {
      'imageData': imageData,
      'width': width,
      'height': height,
      'quality': quality,
    });
  }

  /// Compress image in background isolate
  Future<Uint8List> compressImage(Uint8List imageData, {double quality = 0.8}) async {
    return await _sendToBackgroundIsolate('compressImage', {
      'imageData': imageData,
      'quality': quality,
    });
  }

  /// Calculate SRS algorithm in background isolate
  Future<Map<String, dynamic>> calculateSRS(Map<String, dynamic> srsData) async {
    return await _sendToBackgroundIsolate('calculateSRS', srsData);
  }

  /// Process database query results in background isolate
  Future<List<Map<String, dynamic>>> processDatabaseQuery(
    List<Map<String, dynamic>> queryResults,
    String operation,
  ) async {
    return await _sendToBackgroundIsolate('processDatabaseQuery', {
      'queryResults': queryResults,
      'operation': operation,
    });
  }

  /// Send operation to background isolate
  Future<T> _sendToBackgroundIsolate<T>(String operation, dynamic data) async {
    if (_backgroundSendPort == null) {
      throw Exception('Background isolate not initialized');
    }

    final operationId = '${++_operationId}';
    final completer = Completer<T>();
    _pendingOperations[operationId] = completer;

    _backgroundSendPort!.send({
        'operation': operation,
      'operationId': operationId,
      'data': data,
    });

    return completer.future;
  }

  /// Parse JSON in isolate
  static Map<String, dynamic> _parseJsonInIsolate(dynamic data) {
    final jsonString = data as String;
    return jsonDecode(jsonString) as Map<String, dynamic>;
  }

  /// Encode JSON in isolate
  static String _encodeJsonInIsolate(dynamic data) {
    final map = data as Map<String, dynamic>;
    return jsonEncode(map);
  }

  /// Process image in isolate
  static Uint8List _processImageInIsolate(dynamic data) {
    final map = data as Map<String, dynamic>;
    final imageData = map['imageData'] as Uint8List;
    // Note: width, height, quality parameters available for future implementation
    // For now, return original data - implement actual image processing
    // This would typically involve image resizing, format conversion, etc.
    return imageData;
  }

  /// Compress image in isolate
  static Uint8List _compressImageInIsolate(dynamic data) {
    final map = data as Map<String, dynamic>;
    final imageData = map['imageData'] as Uint8List;
    // Note: quality parameter available for future implementation
    // For now, return original data - implement actual compression
    // This would typically involve JPEG compression, quality reduction, etc.
    return imageData;
  }

  /// Calculate SRS algorithm in isolate
  static Map<String, dynamic> _calculateSRSInIsolate(dynamic data) {
    final map = data as Map<String, dynamic>;
    
    // Extract SRS parameters
    final interval = map['interval'] as int;
    final repetitions = map['repetitions'] as int;
    final easeFactor = map['easeFactor'] as double;
    final quality = map['quality'] as int;
    
    // SuperMemo 2 algorithm implementation
    double newEaseFactor = easeFactor;
    int newInterval = interval;
    int newRepetitions = repetitions;
    
    if (quality >= 3) {
      // Correct answer
      if (repetitions == 0) {
        newInterval = 1;
      } else if (repetitions == 1) {
        newInterval = 6;
      } else {
        newInterval = (interval * easeFactor).round();
      }
      newRepetitions = repetitions + 1;
      newEaseFactor = easeFactor + (0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02));
    } else {
      // Incorrect answer
      newRepetitions = 0;
      newInterval = 1;
      newEaseFactor = easeFactor - 0.2;
    }
    
    // Clamp ease factor
    newEaseFactor = newEaseFactor.clamp(1.3, 2.5);
    
    return {
      'interval': newInterval,
      'repetitions': newRepetitions,
      'easeFactor': newEaseFactor,
      'nextReview': DateTime.now().add(Duration(days: newInterval)).millisecondsSinceEpoch,
    };
  }

  /// Process database query results in isolate
  static List<Map<String, dynamic>> _processDatabaseQueryInIsolate(dynamic data) {
    final map = data as Map<String, dynamic>;
    final queryResults = map['queryResults'] as List<Map<String, dynamic>>;
    final operation = map['operation'] as String;
    
    // Process query results based on operation type
    switch (operation) {
      case 'getDeckTree':
        return _processDeckTreeResults(queryResults);
      case 'getCardsWithFields':
        return _processCardsWithFieldsResults(queryResults);
      case 'getUserProgress':
        return _processUserProgressResults(queryResults);
      default:
        return queryResults;
    }
  }

  /// Process deck tree results
  static List<Map<String, dynamic>> _processDeckTreeResults(
    List<Map<String, dynamic>> results,
  ) {
    // Build hierarchy in isolate
    final Map<int, List<Map<String, dynamic>>> childrenMap = {};
    final List<Map<String, dynamic>> rootDecks = [];
    
    for (final deck in results) {
      final parentId = deck['parent_id'];
      if (parentId == null) {
        rootDecks.add(deck);
      } else {
        childrenMap.putIfAbsent(parentId, () => []).add(deck);
      }
    }
    
    return _buildHierarchyRecursive(rootDecks, childrenMap);
  }

  /// Process cards with fields results
  static List<Map<String, dynamic>> _processCardsWithFieldsResults(
    List<Map<String, dynamic>> results,
  ) {
    // Group fields by card ID
    final Map<int, List<Map<String, dynamic>>> cardFieldsMap = {};
    
    for (final row in results) {
      final cardId = row['card_id'] as int;
      cardFieldsMap.putIfAbsent(cardId, () => []).add(row);
    }
    
    // Build card objects with fields
    final List<Map<String, dynamic>> cards = [];
    for (final entry in cardFieldsMap.entries) {
      final cardId = entry.key;
      final fields = entry.value;
      
      // Get card data from first field
      final firstField = fields.first;
      final card = {
        'id': cardId,
        'deck_id': firstField['deck_id'],
        'notes': firstField['notes'],
        'is_dirty': firstField['is_dirty'],
        'updated_at': firstField['updated_at'],
        'fields': fields.map((field) => {
          'id': field['field_id'],
          'card_id': cardId,
          'field_definition_id': field['field_definition_id'],
          'field_value': field['field_value'],
          'field_type': field['field_type'],
          'is_front': field['is_front'],
          'is_back': field['is_back'],
        }).toList(),
      };
      
      cards.add(card);
    }
    
    return cards;
  }

  /// Process user progress results
  static List<Map<String, dynamic>> _processUserProgressResults(
    List<Map<String, dynamic>> results,
  ) {
    // Calculate SRS statistics
    int totalCards = results.length;
    int masteredCards = 0;
    int dueCards = 0;
    double totalEaseFactor = 0.0;
    
    final now = DateTime.now();
    
    for (final progress in results) {
      if (progress['is_mastered'] == 1) {
        masteredCards++;
      }
      
      final nextReview = progress['next_review'] as String?;
      if (nextReview != null) {
        try {
          final nextReviewDate = DateTime.parse(nextReview);
          if (nextReviewDate.isBefore(now)) {
            dueCards++;
          }
      } catch (e) {
          // Invalid date format
        }
      }
      
      totalEaseFactor += progress['ease_factor'] as double? ?? 2.5;
    }
    
    return [{
      'totalCards': totalCards,
      'masteredCards': masteredCards,
      'dueCards': dueCards,
      'averageEaseFactor': totalCards > 0 ? totalEaseFactor / totalCards : 2.5,
      'masteryPercentage': totalCards > 0 ? (masteredCards / totalCards) * 100 : 0.0,
    }];
  }

  /// Build hierarchy recursively
  static List<Map<String, dynamic>> _buildHierarchyRecursive(
    List<Map<String, dynamic>> decks,
    Map<int, List<Map<String, dynamic>>> childrenMap,
  ) {
    final List<Map<String, dynamic>> result = [];
    
    for (final deck in decks) {
      final children = childrenMap[deck['id']] ?? [];
      final childrenWithHierarchy = _buildHierarchyRecursive(children, childrenMap);
      
      final deckWithChildren = Map<String, dynamic>.from(deck);
      deckWithChildren['children'] = childrenWithHierarchy;
      result.add(deckWithChildren);
    }
    
    return result;
  }

  /// Execute database operation in isolate
  Future<T> executeDatabaseOperation<T>(String operation, Map<String, dynamic> data) async {
    final operationId = DateTime.now().millisecondsSinceEpoch.toString();
    final completer = Completer<T>();
    _pendingOperations[operationId] = completer;

    _backgroundSendPort?.send({
      'operation': operation,
      'operationId': operationId,
      'data': data,
    });

    return completer.future;
  }

  /// Dispose the service
  void dispose() {
    _backgroundIsolate?.kill();
    _backgroundReceivePort?.close();
    _pendingOperations.clear();
  }
}

/// Top-level function for JSON parsing in compute
Future<Map<String, dynamic>> parseJsonInCompute(String jsonString) async {
  return await compute(_parseJsonInCompute, jsonString);
}

/// Top-level function for JSON encoding in compute
Future<String> encodeJsonInCompute(Map<String, dynamic> data) async {
  return await compute(_encodeJsonInCompute, data);
}

/// Top-level function for image processing in compute
Future<Uint8List> processImageInCompute(Uint8List imageData, {
  int? width,
  int? height,
  double? quality,
}) async {
  return await compute(_processImageInCompute, {
    'imageData': imageData,
    'width': width,
    'height': height,
    'quality': quality,
  });
}

/// Top-level function for SRS calculation in compute
Future<Map<String, dynamic>> calculateSRSInCompute(Map<String, dynamic> srsData) async {
  return await compute(_calculateSRSInCompute, srsData);
}

/// Parse JSON in compute function
Map<String, dynamic> _parseJsonInCompute(String jsonString) {
  return jsonDecode(jsonString) as Map<String, dynamic>;
}

/// Encode JSON in compute function
String _encodeJsonInCompute(Map<String, dynamic> data) {
  return jsonEncode(data);
}

/// Process image in compute function
Uint8List _processImageInCompute(Map<String, dynamic> data) {
  final imageData = data['imageData'] as Uint8List;
  // Note: width, height, quality parameters available for future implementation
  // For now, return original data - implement actual image processing
  return imageData;
}

/// Calculate SRS in compute function
Map<String, dynamic> _calculateSRSInCompute(Map<String, dynamic> data) {
  final interval = data['interval'] as int;
  final repetitions = data['repetitions'] as int;
  final easeFactor = data['easeFactor'] as double;
  final quality = data['quality'] as int;
  
  // SuperMemo 2 algorithm implementation
  double newEaseFactor = easeFactor;
  int newInterval = interval;
  int newRepetitions = repetitions;
  
  if (quality >= 3) {
    // Correct answer
    if (repetitions == 0) {
      newInterval = 1;
    } else if (repetitions == 1) {
      newInterval = 6;
    } else {
      newInterval = (interval * easeFactor).round();
    }
    newRepetitions = repetitions + 1;
    newEaseFactor = easeFactor + (0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02));
  } else {
    // Incorrect answer
    newRepetitions = 0;
    newInterval = 1;
    newEaseFactor = easeFactor - 0.2;
  }
  
  // Clamp ease factor
  newEaseFactor = newEaseFactor.clamp(1.3, 2.5);
  
  return {
    'interval': newInterval,
    'repetitions': newRepetitions,
    'easeFactor': newEaseFactor,
    'nextReview': DateTime.now().add(Duration(days: newInterval)).millisecondsSinceEpoch,
  };
}