// Dart imports
import 'dart:async';
import 'dart:io';

// Flutter imports
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

// Package imports
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

// Project imports
import '../models/flashcard.dart';
import '../models/deck.dart';
import '../models/card.dart';
import '../models/card_field.dart';
import '../models/user_progress.dart';
import 'app_logger.dart';
import 'isolate_service.dart';

/// Optimized database service with connection pooling and batch operations
class OptimizedDatabaseService {
  static final OptimizedDatabaseService _instance = OptimizedDatabaseService._internal();
  factory OptimizedDatabaseService() => _instance;
  OptimizedDatabaseService._internal();

  // Connection pooling
  static Database? _database;
  static bool _isInitializing = false;
  static final List<Database> _connectionPool = [];
  static const int _maxConnections = 5;
  static const int _minConnections = 2;
  
  // Prepared statements cache
  static final Map<String, String> _preparedStatements = {};
  
  // Batch operations
  static final List<Map<String, dynamic>> _batchOperations = [];
  static Timer? _batchTimer;
  static const Duration _batchTimeout = Duration(milliseconds: 100);

  /// Initialize the optimized database service
  Future<void> initialize() async {
    if (_database != null) return;

    try {
      
      // Initialize main database connection
      _database = await _createConnection();
      
      // Initialize connection pool
      await _initializeConnectionPool();
      
      // Initialize prepared statements
      await _initializePreparedStatements();
      
      // Start batch processing
      _startBatchProcessing();
      
    } catch (e) {
      AppLogger.error('Failed to initialize OptimizedDatabaseService: $e');
      rethrow;
    }
  }

  /// Initialize connection pool
  Future<void> _initializeConnectionPool() async {
    for (int i = 0; i < _minConnections; i++) {
      final connection = await _createConnection();
      _connectionPool.add(connection);
    }
  }

  /// Create a new database connection
  Future<Database> _createConnection() async {
    final dbPath = await _getDatabasePath();
    return await openDatabase(
      dbPath,
      readOnly: false,
      version: 1,
    );
  }

  /// Get database path
  Future<String> _getDatabasePath() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final dbPath = join(documentsDirectory.path, 'japanese.db');
    
    // Copy from assets if needed
    final dbFile = File(dbPath);
    if (!dbFile.existsSync()) {
      await _copyDatabaseFromAssets(dbFile);
    }
    
    return dbPath;
  }

  /// Copy database from assets
  Future<void> _copyDatabaseFromAssets(File dbFile) async {
    final ByteData data = await rootBundle.load('assets/database/japanese.db');
    final bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    await dbFile.writeAsBytes(bytes);
  }

  /// Initialize prepared statements
  Future<void> _initializePreparedStatements() async {
    _preparedStatements['getDeckTree'] = '''
      SELECT 
        d.id, d.name, d.language, d.parent_id, d.sort_order, d.is_dirty, d.updated_at,
        CASE WHEN EXISTS(SELECT 1 FROM Deck child WHERE child.parent_id = d.id) THEN 1 ELSE 0 END as has_children,
        CASE 
          WHEN d.name = 'Favorites' THEN 
            (SELECT COUNT(*) FROM DeckMembership dm WHERE dm.deck_id = d.id)
          ELSE 
            (SELECT COUNT(*) FROM Card c WHERE c.deck_id = d.id)
        END as card_count,
        '' as full_path
      FROM Deck d
      ORDER BY d.parent_id NULLS FIRST, d.sort_order, d.name
    ''';

    _preparedStatements['getCardsByDeck'] = '''
      SELECT 
        c.id, c.deck_id, c.notes, c.is_dirty, c.updated_at, d.name as deck_name,
        cf.id as field_id, cf.field_definition_id, cf.field_value, cf.is_dirty as field_is_dirty, cf.updated_at as field_updated_at,
        fd.field_type, fd.is_front, fd.is_back, fd.sort_order
      FROM Card c
      INNER JOIN Deck d ON c.deck_id = d.id
      LEFT JOIN CardField cf ON c.id = cf.card_id
      LEFT JOIN FieldDefinition fd ON cf.field_definition_id = fd.id
      WHERE c.deck_id = ?
      ORDER BY c.id, fd.sort_order
    ''';

    _preparedStatements['getUserProgress'] = '''
      SELECT * FROM UserProgress WHERE card_id = ? AND user_id = ?
    ''';

    _preparedStatements['upsertUserProgress'] = '''
      INSERT OR REPLACE INTO UserProgress 
      (card_id, user_id, times_seen, times_correct, total_reviews, last_reviewed, next_review, 
       difficulty_level, is_mastered, created_at, updated_at, interval, repetitions, ease_factor, streak, is_dirty)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ''';

    _preparedStatements['markCardIncorrect'] = '''
      INSERT OR IGNORE INTO IncorrectCards (card_id, deck_id, created_at)
      VALUES (?, ?, ?)
    ''';

    _preparedStatements['markCardCorrect'] = '''
      DELETE FROM IncorrectCards WHERE card_id = ?
    ''';

    _preparedStatements['getIncorrectCards'] = '''
      SELECT card_id FROM IncorrectCards WHERE deck_id = ?
    ''';

    _preparedStatements['toggleFavorite'] = '''
      INSERT OR IGNORE INTO DeckMembership (deck_id, card_id)
      VALUES (?, ?)
    ''';

    _preparedStatements['removeFavorite'] = '''
      DELETE FROM DeckMembership WHERE deck_id = ? AND card_id = ?
    ''';

  }

  /// Start batch processing
  void _startBatchProcessing() {
    _batchTimer = Timer.periodic(_batchTimeout, (_) {
      if (_batchOperations.isNotEmpty) {
        _processBatchOperations();
      }
    });
  }

  /// Process batch operations
  Future<void> _processBatchOperations() async {
    if (_batchOperations.isEmpty) return;

    final operations = List<Map<String, dynamic>>.from(_batchOperations);
    _batchOperations.clear();

    try {
      final db = await _getConnection();
      await db.transaction((txn) async {
        for (final operation in operations) {
          await _executeOperation(txn, operation);
        }
      });
    } catch (e) {
      AppLogger.error('Error processing batch operations: $e');
      // Re-add operations to queue for retry
      _batchOperations.addAll(operations);
    }
  }

  /// Execute a single operation
  Future<void> _executeOperation(Transaction txn, Map<String, dynamic> operation) async {
    final type = operation['type'] as String;
    final params = operation['params'] as List<dynamic>;

    switch (type) {
      case 'upsertUserProgress':
        await txn.rawInsert(_preparedStatements['upsertUserProgress']!, params);
        break;
      case 'markCardIncorrect':
        await txn.rawInsert(_preparedStatements['markCardIncorrect']!, params);
        break;
      case 'markCardCorrect':
        await txn.rawDelete(_preparedStatements['markCardCorrect']!, params);
        break;
      case 'toggleFavorite':
        await txn.rawInsert(_preparedStatements['toggleFavorite']!, params);
        break;
      case 'removeFavorite':
        await txn.rawDelete(_preparedStatements['removeFavorite']!, params);
        break;
    }
  }

  /// Get a database connection from the pool
  Future<Database> _getConnection() async {
    if (_connectionPool.isNotEmpty) {
      return _connectionPool.removeLast();
    }
    
    // Create new connection if pool is empty and under limit
    if (_connectionPool.length < _maxConnections) {
      return await _createConnection();
    }
    
    // Wait for connection to become available
    while (_connectionPool.isEmpty) {
      await Future.delayed(Duration(milliseconds: 10));
    }
    
    return _connectionPool.removeLast();
  }

  /// Return connection to pool
  void _returnConnection(Database connection) {
    if (_connectionPool.length < _maxConnections) {
      _connectionPool.add(connection);
    } else {
      connection.close();
    }
  }

  /// Get deck tree with optimized query
  Future<List<Deck>> getDeckTree() async {
    try {
      // Use isolate for heavy operations
      if (kIsWeb) {
        return await _getDeckTreeDirect();
      } else {
        return await IsolateService().executeDatabaseOperation<List<Deck>>(
          'getDeckTree',
          {},
        );
      }
    } catch (e) {
      AppLogger.error('Error getting deck tree: $e');
      return [];
    }
  }

  /// Get deck tree directly (fallback)
  Future<List<Deck>> _getDeckTreeDirect() async {
    final db = await _getConnection();
    try {
      final List<Map<String, dynamic>> maps = await db.rawQuery(_preparedStatements['getDeckTree']!);
      final List<Deck> allDecks = maps.map((map) => Deck.fromMap(map)).toList();
      return _buildDeckHierarchy(allDecks);
    } finally {
      _returnConnection(db);
    }
  }

  /// Get cards by category with optimized query
  Future<List<Flashcard>> getCardsByCategory(int categoryId) async {
    try {
      if (kIsWeb) {
        return await _getCardsByCategoryDirect(categoryId);
      } else {
        return await IsolateService().executeDatabaseOperation<List<Flashcard>>(
          'getCardsByCategory',
          {'categoryId': categoryId},
        );
      }
    } catch (e) {
      AppLogger.error('Error getting cards by category: $e');
      return [];
    }
  }

  /// Get cards by category directly (fallback)
  Future<List<Flashcard>> _getCardsByCategoryDirect(int categoryId) async {
    final db = await _getConnection();
    try {
      final List<Map<String, dynamic>> maps = await db.rawQuery(
        _preparedStatements['getCardsByDeck']!,
        [categoryId],
      );

      // Group results by card to avoid N+1 problem
      final Map<int, Map<String, dynamic>> cardMap = {};
      final Map<int, List<CardField>> cardFields = {};
      
      for (final map in maps) {
        final cardId = map['id'] as int;
        
        if (!cardMap.containsKey(cardId)) {
          cardMap[cardId] = {
            'id': map['id'],
            'deck_id': map['deck_id'],
            'notes': map['notes'],
            'is_dirty': map['is_dirty'],
            'updated_at': map['updated_at'],
            'deck_name': map['deck_name'],
          };
          cardFields[cardId] = [];
        }
        
        if (map['field_id'] != null) {
          cardFields[cardId]!.add(CardField.fromMap({
            'id': map['field_id'],
            'card_id': map['id'],
            'field_definition_id': map['field_definition_id'],
            'field_value': map['field_value'],
            'is_dirty': map['field_is_dirty'],
            'updated_at': map['field_updated_at'],
            'field_type': map['field_type'],
            'is_front': map['is_front'],
            'is_back': map['is_back'],
          }));
        }
      }
      
      // Build final card list
      final List<Flashcard> flashcards = [];
      for (final entry in cardMap.entries) {
        final cardId = entry.key;
        final cardData = entry.value;
        final fields = cardFields[cardId] ?? [];
        final card = Card.fromMap(cardData).copyWith(fields: fields);
        flashcards.add(Flashcard.fromCard(card));
      }
      
      return flashcards;
    } finally {
      _returnConnection(db);
    }
  }

  /// Get user progress with prepared statement
  Future<UserProgress?> getUserProgress(int cardId, {String userId = 'default'}) async {
    final db = await _getConnection();
    try {
      final result = await db.rawQuery(
        _preparedStatements['getUserProgress']!,
        [cardId, userId],
      );
      
      if (result.isEmpty) return null;
      return UserProgress.fromMap(result.first);
    } finally {
      _returnConnection(db);
    }
  }

  /// Upsert user progress with batch operation
  Future<void> upsertUserProgress(UserProgress progress) async {
    // Add to batch operations for better performance
    _batchOperations.add({
      'type': 'upsertUserProgress',
      'params': [
        progress.cardId,
        progress.userId,
        progress.timesSeen,
        progress.timesCorrect,
        progress.totalReviews,
        progress.lastReviewed,
        progress.nextReview,
        progress.difficultyLevel,
        progress.isMastered ? 1 : 0,
        progress.createdAt,
        progress.updatedAt,
        progress.interval,
        progress.repetitions,
        progress.easeFactor,
        progress.streak,
        progress.isDirty ? 1 : 0,
      ],
    });
  }

  /// Mark card as incorrect with batch operation
  Future<void> markCardIncorrectInDatabase(int cardId, int deckId) async {
    _batchOperations.add({
      'type': 'markCardIncorrect',
      'params': [cardId, deckId, DateTime.now().toIso8601String()],
    });
  }

  /// Mark card as correct with batch operation
  Future<void> markCardCorrectInDatabase(int cardId) async {
    _batchOperations.add({
      'type': 'markCardCorrect',
      'params': [cardId],
    });
  }

  /// Get incorrect cards with prepared statement
  Future<List<int>> getIncorrectCardsFromDatabase(int deckId) async {
    final db = await _getConnection();
    try {
      final result = await db.rawQuery(
        _preparedStatements['getIncorrectCards']!,
        [deckId],
      );
      return result.map((row) => row['card_id'] as int).toList();
    } finally {
      _returnConnection(db);
    }
  }

  /// Toggle favorite with batch operation
  Future<void> toggleFavorite(int cardId) async {
    // Get favorites deck ID first
    final db = await _getConnection();
    try {
      final favoritesResult = await db.rawQuery('''
        SELECT id FROM Deck 
        WHERE name = 'Favorites' AND parent_id = (
          SELECT id FROM Deck WHERE parent_id IS NULL
        )
      ''');
      
      if (favoritesResult.isNotEmpty) {
        final favoritesDeckId = favoritesResult.first['id'] as int;
        
        // Check if already favorited
        final existing = await db.rawQuery('''
          SELECT 1 FROM DeckMembership 
          WHERE deck_id = ? AND card_id = ?
        ''', [favoritesDeckId, cardId]);
        
        if (existing.isNotEmpty) {
          _batchOperations.add({
            'type': 'removeFavorite',
            'params': [favoritesDeckId, cardId],
          });
        } else {
          _batchOperations.add({
            'type': 'toggleFavorite',
            'params': [favoritesDeckId, cardId],
          });
        }
      }
    } finally {
      _returnConnection(db);
    }
  }

  /// Get favorite cards
  Future<List<Flashcard>> getFavoriteCards() async {
    final db = await _getConnection();
    try {
      final favoritesResult = await db.rawQuery('''
        SELECT id FROM Deck 
        WHERE name = 'Favorites' AND parent_id = (
          SELECT id FROM Deck WHERE parent_id IS NULL
        )
      ''');
      
      if (favoritesResult.isEmpty) return [];
      
      final favoritesDeckId = favoritesResult.first['id'] as int;
      
      final cardMaps = await db.rawQuery('''
        SELECT 
          c.id, c.deck_id, c.notes, c.is_dirty, c.updated_at, d.name as deck_name
        FROM Card c
        INNER JOIN Deck d ON c.deck_id = d.id
        INNER JOIN DeckMembership dm ON c.id = dm.card_id
        WHERE dm.deck_id = ?
        ORDER BY c.id
      ''', [favoritesDeckId]);
      
      final List<Flashcard> favoriteCards = [];
      
      for (final cardMap in cardMaps) {
        final cardId = cardMap['id'] as int;
        final fieldMaps = await db.rawQuery('''
          SELECT 
            cf.id, cf.card_id, cf.field_definition_id, cf.field_value, cf.is_dirty, cf.updated_at,
            fd.field_type, fd.is_front, fd.is_back
          FROM CardField cf
          INNER JOIN FieldDefinition fd ON cf.field_definition_id = fd.id
          WHERE cf.card_id = ?
          ORDER BY fd.sort_order
        ''', [cardId]);
        
        final fields = fieldMaps.map((fieldMap) => CardField.fromMap(fieldMap)).toList();
        final card = Card.fromMap(cardMap).copyWith(fields: fields, isFavorite: true);
        favoriteCards.add(Flashcard.fromCard(card));
      }
      
      return favoriteCards;
    } finally {
      _returnConnection(db);
    }
  }

  /// Get review stats for category
  Future<Map<String, int>> getReviewStatsForCategory(int categoryId) async {
    final db = await _getConnection();
    try {
      final now = DateTime.now().toIso8601String();
      
      final result = await db.rawQuery('''
        SELECT 
          COUNT(*) as total_cards,
          SUM(CASE WHEN up.card_id IS NULL THEN 1 ELSE 0 END) as new_cards,
          SUM(CASE WHEN up.next_review IS NULL OR up.next_review <= ? THEN 1 ELSE 0 END) as due_cards,
          SUM(CASE WHEN up.next_review < ? THEN 1 ELSE 0 END) as overdue_cards
        FROM Card c
        LEFT JOIN UserProgress up ON c.id = up.card_id
        WHERE c.deck_id = ?
      ''', [now, now, categoryId]);
      
      final stats = result.first;
      return {
        'total': stats['total_cards'] as int? ?? 0,
        'new': stats['new_cards'] as int? ?? 0,
        'due': stats['due_cards'] as int? ?? 0,
        'overdue': stats['overdue_cards'] as int? ?? 0,
      };
    } finally {
      _returnConnection(db);
    }
  }

  /// Get flashcards due for review
  Future<List<Flashcard>> getFlashcardsDueForReview(int deckId, {String userId = 'default'}) async {
    final db = await _getConnection();
    try {
      final now = DateTime.now().toIso8601String();
      
      final result = await db.rawQuery('''
        SELECT c.*, d.name as deck_name, d.language as deck_language
        FROM Card c
        INNER JOIN Deck d ON c.deck_id = d.id
        INNER JOIN UserProgress up ON c.id = up.card_id
        WHERE c.deck_id = ? AND up.user_id = ? 
        AND (up.next_review IS NULL OR up.next_review <= ?)
        ORDER BY up.next_review ASC
      ''', [deckId, userId, now]);
      
      final List<Flashcard> flashcards = [];
      
      for (final cardMap in result) {
        final cardFields = await db.rawQuery('''
          SELECT 
            cf.id, cf.card_id, cf.field_definition_id, cf.field_value, cf.is_dirty, cf.updated_at,
            fd.field_type, fd.is_front, fd.is_back, fd.sort_order
          FROM CardField cf
          INNER JOIN FieldDefinition fd ON cf.field_definition_id = fd.id
          WHERE cf.card_id = ?
          ORDER BY fd.sort_order
        ''', [cardMap['id'] as int]);
        
        final fields = cardFields.map((fieldMap) => CardField.fromMap(fieldMap)).toList();
        final card = Card.fromMap({
          'id': cardMap['id'],
          'deck_id': cardMap['deck_id'],
          'notes': cardMap['notes'],
          'is_dirty': cardMap['is_dirty'],
          'updated_at': cardMap['updated_at'],
          'deck_name': cardMap['deck_name'],
        }).copyWith(fields: fields);
        
        flashcards.add(Flashcard.fromCard(card));
      }
      
      return flashcards;
    } finally {
      _returnConnection(db);
    }
  }

  /// Build deck hierarchy
  List<Deck> _buildDeckHierarchy(List<Deck> allDecks) {
    final Map<int, List<Deck>> childrenMap = {};
    final List<Deck> rootDecks = [];
    
    for (final deck in allDecks) {
      if (deck.parentId == null) {
        rootDecks.add(deck);
      } else {
        childrenMap.putIfAbsent(deck.parentId!, () => []).add(deck);
      }
    }
    
    return _buildHierarchyRecursive(rootDecks, childrenMap);
  }
  
  /// Recursively build hierarchy
  List<Deck> _buildHierarchyRecursive(List<Deck> decks, Map<int, List<Deck>> childrenMap) {
    final List<Deck> result = [];
    
    for (final deck in decks) {
      final children = childrenMap[deck.id] ?? [];
      final childrenWithHierarchy = _buildHierarchyRecursive(children, childrenMap);
      
      final deckWithChildren = deck.copyWith(children: childrenWithHierarchy);
      result.add(deckWithChildren);
    }
    
    return result;
  }

  /// Dispose the service
  Future<void> dispose() async {
    _batchTimer?.cancel();
    _batchTimer = null;
    
    // Process remaining batch operations
    if (_batchOperations.isNotEmpty) {
      await _processBatchOperations();
    }
    
    // Close all connections
    for (final connection in _connectionPool) {
      connection.close();
    }
    _connectionPool.clear();
    
    if (_database != null) {
      _database!.close();
      _database = null;
    }
  }
}
