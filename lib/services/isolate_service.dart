// Dart imports
import 'dart:async';
import 'dart:isolate';

// Project imports
import 'app_logger.dart';
import 'database_service.dart';
import 'optimized_database_service.dart';
import 'spaced_repetition_service.dart';
import '../models/deck.dart';
import '../models/card.dart';
import '../models/user_progress.dart';
import '../models/flashcard.dart';

/// Service for running heavy operations in background isolates
/// Prevents main thread blocking during database operations and computations
class IsolateService {
  static final IsolateService _instance = IsolateService._internal();
  factory IsolateService() => _instance;
  IsolateService._internal();

  // Isolate management
  Isolate? _isolate;
  SendPort? _sendPort;
  ReceivePort? _receivePort;
  int _requestId = 0;
  final Map<int, Completer<dynamic>> _pendingRequests = {};

  /// Initialize the isolate service
  Future<void> initialize() async {
    if (_isolate != null) {
      return; // Already initialized
    }

    try {
      
      _receivePort = ReceivePort();
      _isolate = await Isolate.spawn(
        _isolateEntryPoint,
        _receivePort!.sendPort,
        debugName: 'DatabaseIsolate',
      );

      // Listen for responses from isolate
      _receivePort!.listen(_handleIsolateResponse);

      // Wait for isolate to be ready
      await _waitForIsolateReady();
      
    } catch (e) {
      AppLogger.error('Failed to initialize IsolateService: $e');
      // Don't rethrow, just log the error and continue
    }
  }

  /// Wait for isolate to be ready
  Future<void> _waitForIsolateReady() async {
    final completer = Completer<void>();
    late StreamSubscription subscription;
    
    subscription = _receivePort!.listen((message) {
      if (message is Map<String, dynamic> && message['type'] == 'ready') {
        _sendPort = message['sendPort'] as SendPort;
        completer.complete();
        subscription.cancel();
      }
    });

    // Timeout after 5 seconds
    Timer(Duration(seconds: 5), () {
      if (!completer.isCompleted) {
        subscription.cancel();
        completer.completeError('Isolate initialization timeout');
      }
    });

    return completer.future;
  }

  /// Handle responses from isolate
  void _handleIsolateResponse(dynamic message) {
    if (message is Map<String, dynamic>) {
      final requestId = message['requestId'] as int?;
      if (requestId != null) {
        final completer = _pendingRequests.remove(requestId);
        
        if (completer != null) {
          if (message['error'] != null) {
            completer.completeError(message['error']);
          } else {
            completer.complete(message['result']);
          }
        }
      }
    }
  }

  /// Execute database operation in isolate
  Future<T> executeDatabaseOperation<T>(
    String operation,
    Map<String, dynamic> params,
  ) async {
    if (_sendPort == null) {
      // Fallback to main thread execution
      return await _executeOnMainThread<T>(operation, params);
    }

    final requestId = ++_requestId;
    final completer = Completer<T>();
    _pendingRequests[requestId] = completer;

    try {
      _sendPort!.send({
        'requestId': requestId,
        'operation': operation,
        'params': params,
      });

      // Timeout after 30 seconds
      Timer(Duration(seconds: 30), () {
        if (_pendingRequests.containsKey(requestId)) {
          _pendingRequests.remove(requestId);
          completer.completeError('Database operation timeout');
        }
      });

      return await completer.future;
    } catch (e) {
      _pendingRequests.remove(requestId);
      AppLogger.error('Error executing operation in isolate: $e');
      // Fallback to main thread execution
      return await _executeOnMainThread<T>(operation, params);
    }
  }

  /// Execute heavy computation in isolate
  Future<T> executeComputation<T>(
    String computation,
    Map<String, dynamic> params,
  ) async {
    if (_sendPort == null) {
      throw Exception('IsolateService not initialized');
    }

    final requestId = ++_requestId;
    final completer = Completer<T>();
    _pendingRequests[requestId] = completer;

    try {
      _sendPort!.send({
        'requestId': requestId,
        'computation': computation,
        'params': params,
      });

      // Timeout after 10 seconds for computations
      Timer(Duration(seconds: 10), () {
        if (_pendingRequests.containsKey(requestId)) {
          _pendingRequests.remove(requestId);
          completer.completeError('Computation timeout');
        }
      });

      return await completer.future;
    } catch (e) {
      _pendingRequests.remove(requestId);
      rethrow;
    }
  }

  /// Dispose the isolate service
  Future<void> dispose() async {
    if (_isolate != null) {
      _sendPort?.send({'type': 'shutdown'});
      _isolate?.kill();
      _isolate = null;
      _sendPort = null;
    }
    
    if (_receivePort != null) {
      _receivePort!.close();
      _receivePort = null;
    }
    
    // Complete all pending requests with error
    for (final completer in _pendingRequests.values) {
      completer.completeError('IsolateService disposed');
    }
    _pendingRequests.clear();
  }

  /// Fallback method to execute operations on main thread
  Future<T> _executeOnMainThread<T>(
    String operation,
    Map<String, dynamic> params,
  ) async {
    
    // Import database service for fallback
    final databaseService = DatabaseService();
    
    switch (operation) {
      case 'getCardsByCategory':
        // Use the original method that doesn't use isolates
        final cards = await databaseService.getCardsWithFieldsByDeck(params['categoryId'] as int);
        // Get favorites and create flashcards
        final db = await databaseService.database;
        final favoritesResult = await db.rawQuery('''
          SELECT dm.card_id
          FROM DeckMembership dm
          INNER JOIN Deck d ON dm.deck_id = d.id
          WHERE d.name = 'Favorites' AND d.parent_id = (
            SELECT id FROM Deck WHERE language = 'Japanese' AND parent_id IS NULL
          )
        ''');
        
        final Set<int> favoriteCardIds = favoritesResult
            .map((row) => row['card_id'] as int)
            .toSet();
        
        final flashcards = cards.map((card) {
          final isFavorite = favoriteCardIds.contains(card.id);
          return Flashcard.fromCard(card.copyWith(isFavorite: isFavorite));
        }).toList();
        
        return flashcards as T;
      case 'getDeckTree':
        return await databaseService.getDeckTree() as T;
      case 'getFavoriteCards':
        return await databaseService.getFavoriteCards() as T;
      default:
        throw Exception('Operation $operation not supported in fallback mode');
    }
  }
}

/// Entry point for the isolate
void _isolateEntryPoint(SendPort sendPort) {
  final receivePort = ReceivePort();
  sendPort.send({
    'type': 'ready',
    'sendPort': receivePort.sendPort,
  });

  receivePort.listen((message) async {
    if (message is Map<String, dynamic>) {
      final requestId = message['requestId'] as int;
      
      try {
        dynamic result;
        
        if (message.containsKey('operation')) {
          result = await _handleDatabaseOperation(
            message['operation'] as String,
            message['params'] as Map<String, dynamic>,
          );
        } else if (message.containsKey('computation')) {
          result = await _handleComputation(
            message['computation'] as String,
            message['params'] as Map<String, dynamic>,
          );
        } else if (message['type'] == 'shutdown') {
          receivePort.close();
          return;
        }

        sendPort.send({
          'requestId': requestId,
          'result': result,
        });
      } catch (e) {
        sendPort.send({
          'requestId': requestId,
          'error': e.toString(),
        });
      }
    }
  });
}

/// Handle database operations in isolate
Future<dynamic> _handleDatabaseOperation(
  String operation,
  Map<String, dynamic> params,
) async {
  // Import database service dynamically to avoid isolate issues
  final databaseService = await _getDatabaseService();
  
  switch (operation) {
    case 'getDeckTree':
      return await databaseService.getDeckTree();
    case 'getCardsByCategory':
      return await databaseService.getCardsByCategory(params['categoryId'] as int);
    case 'getFavoriteCards':
      return await databaseService.getFavoriteCards();
    case 'getIncorrectCardsFromDatabase':
      return await databaseService.getIncorrectCardsFromDatabase(params['deckId'] as int);
    case 'getSpacedRepetitionStats':
      return await databaseService.getReviewStatsForCategory(params['categoryId'] as int);
    case 'markCardIncorrectInDatabase':
      return await databaseService.markCardIncorrectInDatabase(
        params['cardId'] as int,
        params['deckId'] as int,
      );
    case 'markCardCorrectInDatabase':
      return await databaseService.markCardCorrectInDatabase(params['cardId'] as int);
    case 'toggleFavorite':
      return await databaseService.toggleFavorite(params['cardId'] as int);
    case 'upsertUserProgress':
      return await databaseService.upsertUserProgress(params['progress']);
    case 'getUserProgress':
      return await databaseService.getUserProgress(params['cardId'] as int);
    case 'getFlashcardsDueForReview':
      return await databaseService.getFlashcardsDueForReview(params['deckId'] as int);
    default:
      throw Exception('Unknown database operation: $operation');
  }
}

/// Handle computations in isolate
Future<dynamic> _handleComputation(
  String computation,
  Map<String, dynamic> params,
) async {
  switch (computation) {
    case 'calculateSRS':
      return await _calculateSRSInIsolate(params);
    case 'buildDeckHierarchy':
      return await _buildDeckHierarchyInIsolate(params);
    case 'processCardData':
      return await _processCardDataInIsolate(params);
    default:
      throw Exception('Unknown computation: $computation');
  }
}

/// Get database service instance in isolate
Future<dynamic> _getDatabaseService() async {
  // Import and initialize database service in isolate
  // This avoids sharing database connections across isolates
  final databaseService = OptimizedDatabaseService();
  await databaseService.initialize();
  return databaseService;
}

/// Calculate SRS in isolate
Future<Map<String, dynamic>> _calculateSRSInIsolate(Map<String, dynamic> params) async {
  // Import SRS service
  final spacedRepetitionService = SpacedRepetitionService();
  
  final progress = params['progress'] as UserProgress;
  final isCorrect = params['isCorrect'] as bool;
  
  final updatedProgress = spacedRepetitionService.calculateNextReviewFromProgress(
    progress,
    isCorrect,
  );
  
  return updatedProgress.toMap();
}

/// Build deck hierarchy in isolate
Future<List<Map<String, dynamic>>> _buildDeckHierarchyInIsolate(Map<String, dynamic> params) async {
  final allDecks = params['decks'] as List<Map<String, dynamic>>;
  
  // Convert to Deck objects
  final decks = allDecks.map((map) => Deck.fromMap(map)).toList();
  
  // Build hierarchy
  final Map<int, List<Deck>> childrenMap = {};
  final List<Deck> rootDecks = [];
  
  for (final deck in decks) {
    if (deck.parentId == null) {
      rootDecks.add(deck);
    } else {
      childrenMap.putIfAbsent(deck.parentId!, () => []).add(deck);
    }
  }
  
  final result = _buildHierarchyRecursiveInIsolate(rootDecks, childrenMap);
  return result.map((deck) => deck.toMap()).toList();
}

/// Process card data in isolate
Future<List<Map<String, dynamic>>> _processCardDataInIsolate(Map<String, dynamic> params) async {
  final cards = params['cards'] as List<Map<String, dynamic>>;
  final favoriteCardIds = params['favoriteCardIds'] as Set<int>;
  
  return cards.map((cardMap) {
    final card = Card.fromMap(cardMap);
    final isFavorite = favoriteCardIds.contains(card.id);
    return card.copyWith(isFavorite: isFavorite).toMap();
  }).toList();
}

/// Recursively build hierarchy in isolate
List<Deck> _buildHierarchyRecursiveInIsolate(List<Deck> decks, Map<int, List<Deck>> childrenMap) {
  final List<Deck> result = [];
  
  for (final deck in decks) {
    final children = childrenMap[deck.id] ?? [];
    final childrenWithHierarchy = _buildHierarchyRecursiveInIsolate(children, childrenMap);
    
    final deckWithChildren = deck.copyWith(children: childrenWithHierarchy);
    result.add(deckWithChildren);
  }
  
  return result;
}
