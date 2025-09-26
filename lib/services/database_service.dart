// Dart imports
import 'dart:async';
import 'dart:io';

// Flutter imports
import 'package:flutter/services.dart';

// Package imports
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

// Project imports - Models
import '../models/category.dart' as app_models;
import '../models/flashcard.dart';
import '../models/incorrect_card.dart';
import '../models/spaced_repetition.dart';
import '../models/spaced_repetition_settings.dart';
import '../models/deck.dart';
import '../models/card.dart';
import '../models/card_field.dart';
import '../models/user_progress.dart';
import 'app_logger.dart';

/// Service for managing database operations with the Japanese language database
/// Uses the new migrated schema with Deck, Card+CardField, and UserProgress
class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _database;
  static bool _isInitializing = false;
  
  /// Force re-initialization of the database (useful for debugging)
  static Future<void> resetDatabase() async {
    AppLogger.info('Resetting database...');
    _database?.close();
    _database = null;
    _isInitializing = false;
  }

  /// Ensure database is fully initialized before operations
  Future<void> ensureDatabaseInitialized() async {
    try {
      AppLogger.info('Ensuring database is initialized...');
      await database; // This will initialize if needed
      
      // Add a small delay for physical devices to ensure database is fully ready
      await Future.delayed(Duration(milliseconds: 100));
      
      // Test database connectivity
      final db = await database;
      await db.rawQuery('SELECT 1');
      
      AppLogger.info('Database initialization verified and tested');
    } catch (e) {
      AppLogger.error('Failed to ensure database initialization: $e');
      rethrow;
    }
  }

  /// Get the database instance, initializing if necessary
  Future<Database> get database async {
    if (_database != null) return _database!;
    
    // Prevent multiple simultaneous initializations
    if (_isInitializing) {
      // Wait for the current initialization to complete with timeout
      int attempts = 0;
      while (_isInitializing && attempts < 200) { // 2 second timeout for physical devices
        await Future.delayed(Duration(milliseconds: 10));
        attempts++;
      }
      if (_database != null) return _database!;
    }
    
    _isInitializing = true;
    try {
      AppLogger.info('Starting database initialization...');
    _database = await _initDatabase();
      AppLogger.info('Database initialization completed successfully');
    return _database!;
    } catch (e) {
      AppLogger.error('Database initialization failed: $e');
      _database = null; // Reset on error
      rethrow;
    } finally {
      _isInitializing = false;
    }
  }

  /// Initialize the database using the migrated database file
  Future<Database> _initDatabase() async {
    try {
      AppLogger.info('Starting database initialization...');
    final dbPath = await _getDatabasePath();
      AppLogger.info('Database path obtained: $dbPath');
      
      // Verify the database file exists and is readable
      final dbFile = File(dbPath);
      if (!dbFile.existsSync()) {
        throw Exception('Database file does not exist at: $dbPath');
      }
      
      // Check if database file is empty or corrupted
      final fileSize = dbFile.lengthSync();
      AppLogger.info('Database file size: $fileSize bytes');
      if (fileSize == 0) {
        throw Exception('Database file is empty (0 bytes)');
      }
      if (fileSize < 1000) {
        AppLogger.warning('Database file is very small ($fileSize bytes) - may be corrupted');
      }
      
      AppLogger.info('Opening database connection...');
    final db = await openDatabase(
      dbPath,
        readOnly: false,
      );
      AppLogger.info('Database connection opened successfully');
      
      // Create IncorrectCards table if it doesn't exist
      AppLogger.info('Creating IncorrectCards table...');
      await _createIncorrectCardsTable(db);
      AppLogger.info('IncorrectCards table created/verified');
    
    return db;
    } catch (e) {
      AppLogger.error('Error initializing database: $e');
      AppLogger.error('Error type: ${e.runtimeType}');
      rethrow;
    }
  }


  /// Get the database path - use the original database from assets
  Future<String> _getDatabasePath() async {
    try {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final dbPath = join(documentsDirectory.path, 'japanese.db');
    
      AppLogger.info('Database path: $dbPath');
      AppLogger.info('Documents directory: ${documentsDirectory.path}');
      AppLogger.info('Documents directory exists: ${documentsDirectory.existsSync()}');
      
      // Copy database from assets to app documents directory
    final dbFile = File(dbPath);
      if (!dbFile.existsSync()) {
        AppLogger.info('Database file does not exist, copying from assets...');
        await _copyDatabaseFromAssets(dbFile);
      } else {
        AppLogger.info('Database file already exists at: $dbPath');
        AppLogger.info('Database file size: ${dbFile.lengthSync()} bytes');
        AppLogger.info('Database file exists: ${dbFile.existsSync()}');
    }
    
    return dbPath;
    } catch (e) {
      AppLogger.error('Error in _getDatabasePath: $e');
      AppLogger.error('Error type: ${e.runtimeType}');
      rethrow;
    }
  }

  // ===== DECK OPERATIONS =====

  /// Get the complete deck tree with hierarchical structure
  Future<List<Deck>> getDeckTree() async {
    try {
      AppLogger.info('Getting deck tree...');
    final db = await database;
      AppLogger.info('Database connection established');
    
      // Test basic database connectivity
      final testQuery = await db.rawQuery('SELECT COUNT(*) as count FROM Deck');
      AppLogger.info('Database test query result: $testQuery');
      
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT 
        d.id,
        d.name,
        d.language,
        d.parent_id,
        d.sort_order,
        d.is_dirty,
        d.updated_at,
        CASE 
          WHEN EXISTS(SELECT 1 FROM Deck child WHERE child.parent_id = d.id) 
          THEN 1 
          ELSE 0 
        END as has_children,
        CASE 
          WHEN d.name = 'Favorites' THEN 
            (SELECT COUNT(*) FROM DeckMembership dm WHERE dm.deck_id = d.id)
          ELSE 
            (SELECT COUNT(*) FROM Card c WHERE c.deck_id = d.id)
        END as card_count,
        '' as full_path
      FROM Deck d
      ORDER BY 
        d.parent_id NULLS FIRST,
        d.sort_order,
        d.name
    ''');

      AppLogger.info('Found ${maps.length} decks in database');
      
      if (maps.isEmpty) {
        AppLogger.warning('No decks found in database - this may indicate a database issue');
        // Try to create a basic deck structure as fallback
        return _createFallbackDeckStructure();
      }
      
      final List<Deck> allDecks = List.generate(maps.length, (i) => Deck.fromMap(maps[i]));
      final result = _buildDeckHierarchy(allDecks);
      AppLogger.info('Built deck hierarchy with ${result.length} root decks');
      return result;
    } catch (e) {
      AppLogger.error('Error in getDeckTree: $e');
      AppLogger.error('Error type: ${e.runtimeType}');
      AppLogger.error('Stack trace: ${StackTrace.current}');
      
      // Return fallback deck structure
      AppLogger.info('Returning fallback deck structure due to error');
      return _createFallbackDeckStructure();
    }
  }

  /// Copy database from assets with retry mechanism
  Future<void> _copyDatabaseFromAssets(File dbFile) async {
    int attempts = 0;
    const maxAttempts = 3;
    
    while (attempts < maxAttempts) {
      try {
        AppLogger.info('Attempt ${attempts + 1} to copy database from assets...');
        
        // Try the original asset path first
        final ByteData data = await rootBundle.load('assets/database/japanese.db');
        AppLogger.info('Asset loaded successfully, size: ${data.lengthInBytes} bytes');
        
        // Ensure the directory exists
        final parentDir = dbFile.parent;
        if (!parentDir.existsSync()) {
          AppLogger.info('Creating parent directory: ${parentDir.path}');
          await parentDir.create(recursive: true);
        }
        
        // Delete existing file if it exists (in case of corruption)
        if (dbFile.existsSync()) {
          AppLogger.info('Deleting existing corrupted file...');
          await dbFile.delete();
        }
        
        // Write the database file
        final bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
        await dbFile.writeAsBytes(bytes);
        
        // Verify the file was written correctly
        if (!dbFile.existsSync()) {
          throw Exception('Database file was not created');
        }
        
        final writtenSize = dbFile.lengthSync();
        if (writtenSize != data.lengthInBytes) {
          throw Exception('Database file size mismatch: expected ${data.lengthInBytes}, got $writtenSize');
        }
        
        AppLogger.info('Database copied successfully to: ${dbFile.path}');
        AppLogger.info('Database file size: $writtenSize bytes');
        AppLogger.info('Database file exists: ${dbFile.existsSync()}');
        return; // Success
        
      } catch (e) {
        attempts++;
        AppLogger.error('Error copying database (attempt $attempts): $e');
        AppLogger.error('Error type: ${e.runtimeType}');
        
        if (attempts >= maxAttempts) {
          AppLogger.error('Failed to copy database after $maxAttempts attempts');
          rethrow;
        }
        
        // Wait before retry
        await Future.delayed(Duration(milliseconds: 500 * attempts));
      }
    }
  }


  /// Create a fallback deck structure when database fails
  List<Deck> _createFallbackDeckStructure() {
    AppLogger.info('Creating fallback deck structure - empty structure');
    return []; // Return empty list - no hardcoded data
  }

  /// Build the hierarchical deck structure from flat list
  List<Deck> _buildDeckHierarchy(List<Deck> allDecks) {
    final Map<int, List<Deck>> childrenMap = {};
    final List<Deck> rootDecks = [];
    
    // Group decks by parent ID
    for (final deck in allDecks) {
      if (deck.parentId == null) {
        rootDecks.add(deck);
      } else {
        childrenMap.putIfAbsent(deck.parentId!, () => []).add(deck);
      }
    }
    
    // Build the hierarchy by creating new Deck objects with children
    return _buildHierarchyRecursive(rootDecks, childrenMap);
  }
  
  /// Recursively build hierarchy with children
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

  // ===== CARD OPERATIONS =====

  /// Get cards with their fields for a specific deck
  Future<List<Card>> getCardsWithFieldsByDeck(int deckId) async {
    // Loading cards for deck ID: $deckId
    final db = await database;
    
    // OPTIMIZED: Single query instead of N+1 queries
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT 
        c.id,
        c.deck_id,
        c.notes,
        c.is_dirty,
        c.updated_at,
        d.name as deck_name,
        cf.id as field_id,
        cf.field_definition_id,
        cf.field_value,
        cf.is_dirty as field_is_dirty,
        cf.updated_at as field_updated_at,
        fd.field_type,
        fd.is_front,
        fd.is_back,
        fd.sort_order
      FROM Card c
      INNER JOIN Deck d ON c.deck_id = d.id
      LEFT JOIN CardField cf ON c.id = cf.card_id
      LEFT JOIN FieldDefinition fd ON cf.field_definition_id = fd.id
      WHERE c.deck_id = ?
      ORDER BY c.id, fd.sort_order
    ''', [deckId]);

    // Group results by card to avoid N+1 problem
    final Map<int, Map<String, dynamic>> cardMap = {};
    final Map<int, List<CardField>> cardFields = {};
    
    for (final map in maps) {
      final cardId = map['id'] as int;
      
      // Store card data (only once per card)
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
      
      // Add field data if it exists
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
    final List<Card> cards = [];
    for (final entry in cardMap.entries) {
      final cardId = entry.key;
      final cardData = entry.value;
      final fields = cardFields[cardId] ?? [];
      cards.add(Card.fromMap(cardData).copyWith(fields: fields));
    }
    
    return cards;
  }

  /// Get a single card with its fields by ID - OPTIMIZED with single query
  Future<Card?> getCardWithFieldsById(int cardId) async {
    final db = await database;
    
    // OPTIMIZED: Single query instead of two separate queries
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT 
        c.id,
        c.deck_id,
        c.notes,
        c.is_dirty,
        c.updated_at,
        d.name as deck_name,
        cf.id as field_id,
        cf.field_definition_id,
        cf.field_value,
        cf.is_dirty as field_is_dirty,
        cf.updated_at as field_updated_at,
        fd.field_type,
        fd.is_front,
        fd.is_back,
        fd.sort_order
      FROM Card c
      INNER JOIN Deck d ON c.deck_id = d.id
      LEFT JOIN CardField cf ON c.id = cf.card_id
      LEFT JOIN FieldDefinition fd ON cf.field_definition_id = fd.id
      WHERE c.id = ?
      ORDER BY fd.sort_order
    ''', [cardId]);
    
    if (maps.isEmpty) return null;
    
    // Group fields for this card
    final List<CardField> fields = [];
    final Map<String, dynamic> cardData = {
      'id': maps.first['id'],
      'deck_id': maps.first['deck_id'],
      'notes': maps.first['notes'],
      'is_dirty': maps.first['is_dirty'],
      'updated_at': maps.first['updated_at'],
      'deck_name': maps.first['deck_name'],
    };
    
    for (final map in maps) {
      if (map['field_id'] != null) {
        fields.add(CardField.fromMap({
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
    
    return Card.fromMap(cardData).copyWith(fields: fields);
  }

  /// Get card fields for a specific card
  Future<List<CardField>> getCardFields(int cardId) async {
    final db = await database;
    
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT 
        cf.id,
        cf.card_id,
        cf.field_definition_id,
        cf.field_value,
        cf.is_dirty,
        cf.updated_at,
        fd.field_type,
        fd.is_front,
        fd.is_back,
        fd.sort_order
      FROM CardField cf
      INNER JOIN FieldDefinition fd ON cf.field_definition_id = fd.id
      WHERE cf.card_id = ?
      ORDER BY fd.sort_order
    ''', [cardId]);
    
    return maps.map((map) => CardField.fromMap(map)).toList();
  }

  /// Helper method to create Flashcard from Card and CardFields
  Flashcard _createFlashcardFromCard(Card card, List<CardField> cardFields) {
    String getFieldValue(String fieldType) {
      final field = cardFields.firstWhere(
        (f) => f.fieldType == fieldType,
        orElse: () => CardField(id: 0, cardId: 0, fieldDefinitionId: 0, fieldValue: ''),
      );
      return field.fieldValue;
    }

    return Flashcard(
      id: card.id,
      kana: getFieldValue('kana'),
      hiragana: getFieldValue('hiragana').isEmpty ? null : getFieldValue('hiragana'),
      english: getFieldValue('english'),
      romaji: getFieldValue('romaji').isEmpty ? null : getFieldValue('romaji'),
      notes: card.notes,
      isFavorite: card.isFavorite,
      categoryId: card.deckId,
      categoryName: card.deckName,
      card: card,
      fields: cardFields,
    );
  }

  /// Add a new card with its fields
  Future<int> addCardWithFields(int deckId, Map<String, String> fieldValues, {String? notes, bool isFavorite = false}) async {
    final db = await database;
    
    return await db.transaction((txn) async {
      // Insert card
      final cardId = await txn.insert('Card', {
        'deck_id': deckId,
        'notes': notes,
        'is_dirty': 1,
        'updated_at': DateTime.now().toIso8601String(),
      });
      
      // Get field definitions for this deck
      final fieldDefs = await txn.rawQuery('''
        SELECT id, field_type FROM FieldDefinition 
        WHERE deck_id = ? 
        ORDER BY sort_order
      ''', [deckId]);
      
      // Insert card fields
      for (final fieldDef in fieldDefs) {
        final fieldType = fieldDef['field_type'] as String;
        final fieldValue = fieldValues[fieldType] ?? '';
        
        await txn.insert('CardField', {
          'card_id': cardId,
          'field_definition_id': fieldDef['id'],
          'field_value': fieldValue,
          'is_dirty': 1,
          'updated_at': DateTime.now().toIso8601String(),
        });
      }
      
      // Card count is now calculated dynamically, no need to update
      
      return cardId;
    });
  }

  /// Update a card with its fields
  Future<void> updateCardWithFields(int cardId, Map<String, String> fieldValues, {String? notes, bool? isFavorite}) async {
    final db = await database;
      
    await db.transaction((txn) async {
      // Update card metadata
      final cardUpdates = <String, dynamic>{
        'is_dirty': 1,
        'updated_at': DateTime.now().toIso8601String(),
      };
      
      if (notes != null) cardUpdates['notes'] = notes;
      
      await txn.update('Card', cardUpdates, where: 'id = ?', whereArgs: [cardId]);
      
      // Update card fields
      for (final entry in fieldValues.entries) {
        await txn.rawUpdate('''
          UPDATE CardField 
          SET field_value = ?, is_dirty = 1, updated_at = ?
          WHERE card_id = ? AND field_definition_id = (
            SELECT fd.id FROM FieldDefinition fd 
            INNER JOIN Card c ON fd.deck_id = c.deck_id 
            WHERE c.id = ? AND fd.field_type = ?
          )
        ''', [entry.value, DateTime.now().toIso8601String(), cardId, cardId, entry.key]);
      }
    });
  }

  /// Delete a card and its fields
  Future<void> deleteCardWithFields(int cardId) async {
    final db = await database;
    
    await db.transaction((txn) async {
      // Get deck ID before deletion
      final cardInfo = await txn.query('Card', columns: ['deck_id'], where: 'id = ?', whereArgs: [cardId]);
      if (cardInfo.isEmpty) return;
      
      // final deckId = cardInfo.first['deck_id'] as int; // Unused variable
      
      // Delete card fields
      await txn.delete('CardField', where: 'card_id = ?', whereArgs: [cardId]);
      
      // Delete user progress
      await txn.delete('UserProgress', where: 'card_id = ?', whereArgs: [cardId]);
      
      // Delete card
      await txn.delete('Card', where: 'id = ?', whereArgs: [cardId]);
      
      // Card count is now calculated dynamically, no need to update
    });
  }

  // ===== USER PROGRESS OPERATIONS =====

  /// Create or update user progress
  Future<void> upsertUserProgress(UserProgress progress) async {
      final db = await database;
      
      final existing = await db.query(
      'UserProgress',
      where: 'card_id = ? AND user_id = ?',
      whereArgs: [progress.cardId, progress.userId],
      );
      
      if (existing.isNotEmpty) {
        // For existing records, remove the id field to avoid UNIQUE constraint errors
        final map = progress.toMap();
        map.remove('id');
        await db.update(
        'UserProgress',
        map,
        where: 'card_id = ? AND user_id = ?',
        whereArgs: [progress.cardId, progress.userId],
        );
      } else {
        // For new records, remove the id field to let the database auto-increment
        final map = progress.toMap();
        map.remove('id');
        await db.insert('UserProgress', map);
    }
  }

  /// Mark a card as incorrect and update progress
  Future<void> markCardIncorrect(int cardId, int categoryId, String categoryName) async {
    // Marking card $cardId as incorrect for category $categoryId
    try {
      final db = await database;
      final now = DateTime.now();
      
      final existing = await db.query(
        'UserProgress',
        where: 'card_id = ?',
        whereArgs: [cardId],
      );
      
      if (existing.isNotEmpty) {
        final progress = UserProgress.fromMap(existing.first);
        final updated = progress.copyWith(
          timesSeen: progress.timesSeen + 1,
          totalReviews: progress.totalReviews + 1,
          lastReviewed: now.toIso8601String(),
          streak: 0,
          easeFactor: (progress.easeFactor - 0.2).clamp(1.3, 2.5),
          nextReview: now.add(Duration(minutes: 1)).toIso8601String(),
          isDirty: true,
          updatedAt: now.toIso8601String(),
        );
    
        await db.update(
          'UserProgress',
          updated.toMap(),
          where: 'card_id = ?',
          whereArgs: [cardId],
        );
        // Updated existing progress: times_seen=${updated.timesSeen}, times_correct=${updated.timesCorrect}
      } else {
        final newProgress = UserProgress(
          id: 0,
          cardId: cardId,
          userId: '1',
          timesSeen: 1,
          timesCorrect: 0,
          totalReviews: 1,
          lastReviewed: now.toIso8601String(),
          nextReview: now.add(Duration(minutes: 1)).toIso8601String(),
          difficultyLevel: 1,
          isMastered: false,
          createdAt: now.toIso8601String(),
          updatedAt: now.toIso8601String(),
          interval: 1,
          repetitions: 0,
          easeFactor: 2.5,
          streak: 0,
          isDirty: true,
        );
        
        await db.insert('UserProgress', newProgress.toMap());
        // Created new progress: times_seen=${newProgress.timesSeen}, times_correct=${newProgress.timesCorrect}
      }
    } catch (e) {
      // Error: $e
      AppLogger.error('Error marking card incorrect', e);
    }
  }

  /// Mark a card as correct and update progress
  Future<void> markCardCorrect(int cardId, int categoryId) async {
    try {
    final db = await database;
      final now = DateTime.now();
      
      final existing = await db.query(
        'UserProgress',
        where: 'card_id = ?',
        whereArgs: [cardId],
      );
      
      if (existing.isNotEmpty) {
        final progress = UserProgress.fromMap(existing.first);
        final newStreak = progress.streak + 1;
        final newRepetitions = progress.repetitions + 1;
        final newInterval = newRepetitions == 1 ? 1 : (progress.interval * progress.easeFactor).round();
        final isMastered = newRepetitions >= 5 && progress.easeFactor >= 2.5;
        
        final updated = progress.copyWith(
          timesSeen: progress.timesSeen + 1,
          timesCorrect: progress.timesCorrect + 1,
          totalReviews: progress.totalReviews + 1,
          lastReviewed: now.toIso8601String(),
          nextReview: now.add(Duration(days: newInterval)).toIso8601String(),
          interval: newInterval,
          repetitions: newRepetitions,
          easeFactor: (progress.easeFactor + 0.1).clamp(1.3, 2.5),
          streak: newStreak,
          isMastered: isMastered,
          isDirty: true,
          updatedAt: now.toIso8601String(),
        );
    
    await db.update(
          'UserProgress',
          updated.toMap(),
          where: 'card_id = ?',
          whereArgs: [cardId],
        );
      } else {
        final newProgress = UserProgress(
          id: 0,
          cardId: cardId,
          userId: '1',
          timesSeen: 1,
          timesCorrect: 1,
          totalReviews: 1,
          lastReviewed: now.toIso8601String(),
          nextReview: now.add(Duration(days: 1)).toIso8601String(),
          difficultyLevel: 1,
          isMastered: false,
          createdAt: now.toIso8601String(),
          updatedAt: now.toIso8601String(),
          interval: 1,
          repetitions: 1,
          easeFactor: 2.5,
          streak: 1,
          isDirty: true,
        );
        
        await db.insert('UserProgress', newProgress.toMap());
      }
    } catch (e) {
      AppLogger.error('Error marking card correct', e);
    }
  }

  // ===== BACKWARD COMPATIBILITY METHODS =====

  /// Get categories (wraps getDeckTree for compatibility)
  Future<List<app_models.Category>> getCategoryTree() async {
    try {
      final deckTree = await getDeckTree();
      return deckTree.map((deck) => app_models.Category.fromDeck(deck)).toList();
    } catch (e) {
      AppLogger.error('Error in getCategoryTree: $e');
      return [];
    }
  }

  /// Get cards by category (wraps getCardsWithFieldsByDeck for compatibility)
  Future<List<Flashcard>> getCardsByCategory(int categoryId) async {
      final cards = await getCardsWithFieldsByDeck(categoryId);
    
    // Get the Favorites deck ID and all favorite card IDs in one query
    final db = await database;
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
    
    return cards.map((card) {
      final isFavorite = favoriteCardIds.contains(card.id);
      return Flashcard.fromCard(card.copyWith(isFavorite: isFavorite));
    }).toList();
  }

  /// Get card by ID (wraps getCardWithFieldsById for compatibility)
  Future<Flashcard?> getCardById(int cardId) async {
      final card = await getCardWithFieldsById(cardId);
      if (card == null) return null;
    
    // Check if this card is in the Favorites deck
    final db = await database;
    final favoritesResult = await db.rawQuery('''
      SELECT 1 FROM DeckMembership dm
      INNER JOIN Deck d ON dm.deck_id = d.id
      WHERE d.name = 'Favorites' AND d.parent_id = (
        SELECT id FROM Deck WHERE parent_id IS NULL
      ) AND dm.card_id = ?
    ''', [cardId]);
    
    final isFavorite = favoritesResult.isNotEmpty;
    return Flashcard.fromCard(card.copyWith(isFavorite: isFavorite));
  }

  /// Get deck by ID
  Future<Deck?> getDeckById(int deckId) async {
      final db = await database;
      
      final List<Map<String, dynamic>> maps = await db.rawQuery('''
        SELECT 
        d.id,
        d.name,
        d.language,
        d.parent_id,
        d.sort_order,
        d.is_dirty,
        d.updated_at,
        CASE 
          WHEN EXISTS(SELECT 1 FROM Deck child WHERE child.parent_id = d.id) 
          THEN 1 
          ELSE 0 
        END as has_children,
        (SELECT COUNT(*) FROM Card c WHERE c.deck_id = d.id) as card_count,
        '' as full_path
      FROM Deck d
      WHERE d.id = ?
    ''', [deckId]);
    
    if (maps.isEmpty) return null;
    return Deck.fromMap(maps.first);
  }

  /// Get category by ID (wraps getDeckById for compatibility)
  Future<app_models.Category?> getCategoryById(int categoryId) async {
    final deck = await getDeckById(categoryId);
    return deck != null ? app_models.Category.fromDeck(deck) : null;
  }

  /// Add card with individual parameters (legacy compatibility)
  Future<int> addCard(int categoryId, String kana, String english, {String? hiragana, String? romaji, String? notes}) async {
    return await addCardWithFields(
      categoryId,
      {
        'kana': kana,
        'hiragana': hiragana ?? '',
        'english': english,
        'romaji': romaji ?? '',
      },
      notes: notes,
      isFavorite: false,
    );
  }

  /// Add card with Flashcard object
  Future<int> addCardFromFlashcard(Flashcard flashcard) async {
    return await addCardWithFields(
      flashcard.categoryId,
      {
        'kana': flashcard.kana,
        'hiragana': flashcard.hiragana ?? '',
        'english': flashcard.english,
        'romaji': flashcard.romaji ?? '',
      },
      notes: flashcard.notes,
      isFavorite: flashcard.isFavorite,
    );
  }

  /// Update card (wraps updateCardWithFields for compatibility)
  Future<void> updateCard(Flashcard flashcard) async {
    await updateCardWithFields(
      flashcard.id,
      {
        'kana': flashcard.kana,
        'hiragana': flashcard.hiragana ?? '',
        'english': flashcard.english,
        'romaji': flashcard.romaji ?? '',
      },
      notes: flashcard.notes,
      isFavorite: flashcard.isFavorite,
    );
  }

  /// Delete card (wraps deleteCardWithFields for compatibility)
  Future<void> deleteCard(int cardId) async {
    await deleteCardWithFields(cardId);
  }

  /// Toggle favorite status using DeckMembership
  Future<void> toggleFavorite(int cardId) async {
    final db = await database;
    
    // Get the Favorites deck ID (create if doesn't exist)
    int? favoritesDeckId = await _getFavoritesDeckId(db);
    
    if (favoritesDeckId == null) {
      // Create Favorites deck only when first card is favorited
      final japaneseDeckResult = await db.rawQuery('''
        SELECT id FROM Deck 
        WHERE language = 'Japanese' AND parent_id IS NULL
        ORDER BY id LIMIT 1
    ''');
    
      if (japaneseDeckResult.isEmpty) {
        throw Exception('Japanese deck not found - cannot create Favorites deck');
      }
      
      final japaneseDeckId = japaneseDeckResult.first['id'] as int;
      
      favoritesDeckId = await db.insert('Deck', {
        'name': 'Favorites',
        'language': 'Japanese',
        'parent_id': japaneseDeckId,
        'sort_order': -9999, // Special sort order to appear first
        'is_dirty': 0,
        'updated_at': DateTime.now().toIso8601String(),
      });
    }
    
    // Check if card is already in favorites
    final existingMembership = await db.rawQuery('''
      SELECT 1 FROM DeckMembership 
      WHERE deck_id = ? AND card_id = ?
    ''', [favoritesDeckId, cardId]);
    
    if (existingMembership.isNotEmpty) {
      // Remove from favorites
      await db.rawDelete('''
        DELETE FROM DeckMembership 
        WHERE deck_id = ? AND card_id = ?
      ''', [favoritesDeckId, cardId]);
    } else {
      // Add to favorites
      await db.rawInsert('''
        INSERT OR IGNORE INTO DeckMembership (deck_id, card_id)
        VALUES (?, ?)
      ''', [favoritesDeckId, cardId]);
    }
  }

  /// Get the Favorites deck ID (only if it exists)
  Future<int?> _getFavoritesDeckId(Database db) async {
    final favoritesResult = await db.rawQuery('''
      SELECT id FROM Deck 
      WHERE name = 'Favorites' AND parent_id = (
        SELECT id FROM Deck WHERE parent_id IS NULL
      )
    ''');
    
    if (favoritesResult.isNotEmpty) {
      return favoritesResult.first['id'] as int;
    }
    
    return null; // Favorites deck doesn't exist
  }

  /// Get favorite cards using DeckMembership
  Future<List<Flashcard>> getFavoriteCards() async {
    final db = await database;
    
    // Get the Favorites deck ID (only if it exists)
    final favoritesDeckId = await _getFavoritesDeckId(db);
    
    if (favoritesDeckId == null) {
      return []; // No Favorites deck exists
    }
    
    // Get cards that are in the Favorites deck via DeckMembership
    final cardMaps = await db.rawQuery('''
      SELECT 
        c.id,
        c.deck_id,
        c.notes,
        c.is_dirty,
        c.updated_at,
        d.name as deck_name
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
          cf.id,
          cf.card_id,
          cf.field_definition_id,
          cf.field_value,
          cf.is_dirty,
          cf.updated_at,
          fd.field_type,
          fd.is_front,
          fd.is_back
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
  }

  /// Get favorite cards count using DeckMembership
  Future<int> getFavoriteCardsCount() async {
    final db = await database;
    
    // Get the Favorites deck ID (only if it exists)
    final favoritesDeckId = await _getFavoritesDeckId(db);
    
    if (favoritesDeckId == null) {
      return 0; // No Favorites deck exists
    }
    
    final result = await db.rawQuery('''
      SELECT COUNT(*) as count 
      FROM DeckMembership 
      WHERE deck_id = ?
    ''', [favoritesDeckId]);
    
    return result.first['count'] as int? ?? 0;
  }

  /// Get incorrect cards for category (compatibility method)
  Future<List<IncorrectCard>> getIncorrectCards(int categoryId) async {
    final db = await database;
    
    final maps = await db.rawQuery('''
      SELECT 
        up.card_id,
        up.times_seen - up.times_correct as incorrect_count,
        up.last_reviewed as last_incorrect,
        0 as is_reviewed
      FROM UserProgress up
      INNER JOIN Card c ON up.card_id = c.id
      WHERE c.deck_id = ? 
        AND up.times_seen > 0 
        AND (up.times_correct * 1.0 / up.times_seen) < 0.7
      ORDER BY up.last_reviewed DESC
    ''', [categoryId]);

    return maps.map((map) {
      final lastIncorrectStr = map['last_incorrect'] as String?;
      int? lastIncorrectMillis;
      if (lastIncorrectStr != null) {
        try {
          final dateTime = DateTime.parse(lastIncorrectStr);
          lastIncorrectMillis = dateTime.millisecondsSinceEpoch;
        } catch (e) {
          lastIncorrectMillis = null;
        }
      }

      return IncorrectCard.fromMap({
        ...map,
        'last_incorrect': lastIncorrectMillis,
      });
    }).toList();
  }

  /// Get spaced repetition card (compatibility method)
  Future<SpacedRepetitionCard?> getSpacedRepetitionCard(int cardId, int categoryId) async {
    final db = await database;
    
    final maps = await db.query(
      'UserProgress',
      where: 'card_id = ?',
      whereArgs: [cardId],
    );

    if (maps.isNotEmpty) {
      final progress = UserProgress.fromMap(maps.first);
      
      // Convert ISO 8601 strings back to milliseconds
      int lastReviewedMillis = 0;
      int nextReviewMillis = 0;
      
      try {
        lastReviewedMillis = DateTime.parse(progress.lastReviewed ?? DateTime.now().toIso8601String()).millisecondsSinceEpoch;
    } catch (e) {
        lastReviewedMillis = DateTime.now().millisecondsSinceEpoch;
      }
      
      try {
        nextReviewMillis = DateTime.parse(progress.nextReview ?? DateTime.now().add(Duration(days: 1)).toIso8601String()).millisecondsSinceEpoch;
      } catch (e) {
        nextReviewMillis = DateTime.now().add(Duration(days: 1)).millisecondsSinceEpoch;
      }
      
      return SpacedRepetitionCard(
        cardId: progress.cardId,
        categoryId: categoryId,
        interval: progress.interval,
        repetitions: progress.repetitions,
        easeFactor: progress.easeFactor,
        lastReviewed: lastReviewedMillis,
        nextReview: nextReviewMillis,
        streak: progress.streak,
        totalReviews: progress.totalReviews,
      );
    }
    
    return null;
  }

  /// Create IncorrectCards table if it doesn't exist
  Future<void> _createIncorrectCardsTable([Database? db]) async {
    try {
      final database = db ?? await this.database;
      
      await database.execute('''
        CREATE TABLE IF NOT EXISTS IncorrectCards (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          card_id INTEGER NOT NULL,
          deck_id INTEGER NOT NULL,
          created_at TEXT NOT NULL,
          FOREIGN KEY (card_id) REFERENCES Card(id) ON DELETE CASCADE,
          FOREIGN KEY (deck_id) REFERENCES Deck(id) ON DELETE CASCADE
        )
      ''');
    } catch (e) {
      AppLogger.error('Error creating IncorrectCards table: $e');
    }
  }

  /// Mark a card as incorrect in the database (persistent storage)
  Future<void> markCardIncorrectInDatabase(int cardId, int deckId) async {
    try {
      final db = await database;
      
      // Check if card is already marked as incorrect
      final existing = await db.query(
        'IncorrectCards',
        where: 'card_id = ? AND deck_id = ?',
        whereArgs: [cardId, deckId],
      );
      
      if (existing.isEmpty) {
        // Insert new incorrect card record
        await db.insert('IncorrectCards', {
          'card_id': cardId,
          'deck_id': deckId,
          'created_at': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      AppLogger.error('Error marking card as incorrect: $e');
    }
  }

  /// Remove a card from incorrect status in the database
  Future<void> markCardCorrectInDatabase(int cardId) async {
    try {
    final db = await database;
    
      // Remove the card from IncorrectCards table
    await db.delete(
        'IncorrectCards',
        where: 'card_id = ?',
        whereArgs: [cardId],
      );
    } catch (e) {
      AppLogger.error('Error removing card from incorrect status: $e');
    }
  }

  /// Get incorrect cards from database (persistent storage)
  Future<List<int>> getIncorrectCardsFromDatabase(int deckId) async {
    try {
    final db = await database;
      
      // Get all cards in the deck that are marked as incorrect
      final result = await db.query(
        'IncorrectCards',
        columns: ['card_id'],
        where: 'deck_id = ?',
        whereArgs: [deckId],
      );
      
      return result.map((row) => row['card_id'] as int).toList();
    } catch (e) {
      AppLogger.error('Error getting incorrect cards: $e');
      return [];
    }
  }

  /// Upsert spaced repetition card (compatibility method)
  Future<void> upsertSpacedRepetitionCard(SpacedRepetitionCard card) async {
    final userProgress = UserProgress(
      id: 0,
      cardId: card.cardId,
      userId: '1',
      timesSeen: card.repetitions,
      timesCorrect: card.repetitions,
      totalReviews: card.repetitions,
      lastReviewed: DateTime.fromMillisecondsSinceEpoch(card.lastReviewed).toIso8601String(),
      nextReview: DateTime.fromMillisecondsSinceEpoch(card.nextReview).toIso8601String(),
      difficultyLevel: 1,
      isMastered: card.repetitions >= 5 && card.easeFactor >= 2.5,
      createdAt: DateTime.now().toIso8601String(),
      updatedAt: DateTime.now().toIso8601String(),
      interval: card.interval,
      repetitions: card.repetitions,
      easeFactor: card.easeFactor,
      streak: card.streak,
      isDirty: true,
    );
    
    await upsertUserProgress(userProgress);
  }

  /// Get incorrect cards for category (returns Flashcard objects)
  Future<List<Flashcard>> getIncorrectCardsForCategory(int categoryId) async {
    final incorrectCards = await getIncorrectCards(categoryId);
    final List<Flashcard> flashcards = [];
    
    for (final incorrectCard in incorrectCards) {
      final flashcard = await getCardById(incorrectCard.cardId);
      if (flashcard != null) {
        flashcards.add(flashcard);
      }
    }
    
    return flashcards;
  }

  /// Get recently incorrect cards for category (cards answered incorrectly in last session)
  Future<List<Flashcard>> getRecentlyIncorrectCardsForCategory(int categoryId) async {
    // Querying for category $categoryId
    final db = await database;
    final now = DateTime.now();
    final oneHourAgo = now.subtract(Duration(hours: 1)).toIso8601String();
    // One hour ago: $oneHourAgo
    
    
    final result = await db.rawQuery('''
      SELECT c.*, d.name as deck_name, d.language as deck_language
      FROM Card c
      INNER JOIN Deck d ON c.deck_id = d.id
      INNER JOIN UserProgress up ON c.id = up.card_id
      WHERE c.deck_id = ? 
        AND up.last_reviewed >= ?
        AND up.times_seen > up.times_correct
      ORDER BY up.last_reviewed DESC
    ''', [categoryId, oneHourAgo]);
    
    // Found ${result.length} cards in database
    
    final List<Flashcard> flashcards = [];
    
    for (final cardMap in result) {
      final cardFields = await getCardFields(cardMap['id'] as int);
      final card = Card.fromMap({
        'id': cardMap['id'],
        'deck_id': cardMap['deck_id'],
        'notes': cardMap['notes'],
        'is_dirty': cardMap['is_dirty'],
        'updated_at': cardMap['updated_at'],
        'deck_name': cardMap['deck_name'],
      });
      
      final flashcard = _createFlashcardFromCard(card, cardFields);
      flashcards.add(flashcard);
    }
    
    // Returning ${flashcards.length} flashcards
    return flashcards;
  }

  /// Get review stats for category (compatibility method)
  Future<Map<String, int>> getReviewStatsForCategory(int categoryId) async {
    final db = await database;
    
    // Get total cards
    final totalResult = await db.rawQuery('''
      SELECT COUNT(*) as count FROM Card WHERE deck_id = ?
    ''', [categoryId]);
    final totalCards = totalResult.first['count'] as int? ?? 0;
    
    // Get new cards (no progress)
    final newResult = await db.rawQuery('''
      SELECT COUNT(*) as count 
      FROM Card c
      LEFT JOIN UserProgress up ON c.id = up.card_id
      WHERE c.deck_id = ? AND up.card_id IS NULL
    ''', [categoryId]);
    final newCards = newResult.first['count'] as int? ?? 0;
    
    // Get due cards
    final now = DateTime.now().toIso8601String();
    final dueResult = await db.rawQuery('''
      SELECT COUNT(*) as count 
      FROM UserProgress up
      INNER JOIN Card c ON up.card_id = c.id
      WHERE c.deck_id = ? AND up.next_review <= ? AND up.repetitions > 0
    ''', [categoryId, now]);
    final dueCards = dueResult.first['count'] as int? ?? 0;
    
    // Get overdue cards
    final overdueResult = await db.rawQuery('''
      SELECT COUNT(*) as count 
      FROM UserProgress up
      INNER JOIN Card c ON up.card_id = c.id
      WHERE c.deck_id = ? AND up.next_review < ? AND up.repetitions > 0
    ''', [categoryId, now]);
    final overdueCards = overdueResult.first['count'] as int? ?? 0;
    
    return {
      'total_cards': totalCards,
      'new_cards': newCards,
      'due_cards': dueCards,
      'overdue_cards': overdueCards,
    };
  }


  /// Update category (deck) - compatibility method
  Future<void> updateCategory(app_models.Category category) async {
    final db = await database;
    
    await db.update('Deck', {
      'name': category.name,
      'language': category.description ?? 'Japanese',
      'parent_id': category.parentId,
      'is_dirty': 1,
      'updated_at': DateTime.now().toIso8601String(),
    }, where: 'id = ?', whereArgs: [category.id]);
  }

  /// Load spaced repetition settings (stub - returns default settings)
  Future<SpacedRepetitionSettings> loadSpacedRepetitionSettings() async {
    // Return default settings since we don't store these in the new schema
    return SpacedRepetitionPresets.standard;
  }

  /// Save spaced repetition settings (stub - no-op since we don't store these)
  Future<void> saveSpacedRepetitionSettings(SpacedRepetitionSettings settings) async {
    // No-op - settings are handled by SpacedRepetitionService
  }

  /// Add category with individual parameters (legacy compatibility)
  Future<int> addCategory(String name, String? description) async {
    final db = await database;
    
    // Special handling for Favorites deck
    if (name.toLowerCase() == 'favorites') {
      // Find the main Japanese deck
      final japaneseDeckResult = await db.rawQuery('''
        SELECT id FROM Deck 
        WHERE language = 'Japanese' AND parent_id IS NULL
        ORDER BY id LIMIT 1
      ''');
      
      if (japaneseDeckResult.isEmpty) {
        throw Exception('Japanese deck not found - cannot create Favorites deck');
      }
      
      final japaneseDeckId = japaneseDeckResult.first['id'] as int;
      
      return await db.insert('Deck', {
      'name': name,
        'language': 'Japanese',
        'parent_id': japaneseDeckId,
        'sort_order': -9999, // Special sort order to appear first
        'is_dirty': 1,
        'updated_at': DateTime.now().toIso8601String(),
      });
    }
    
    return await db.insert('Deck', {
      'name': name,
      'language': description ?? 'Japanese',
      'parent_id': null,
      'sort_order': 0,
      'is_dirty': 1,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  /// Add category with Category object
  Future<int> addCategoryFromObject(app_models.Category category) async {
    final db = await database;
    
    return await db.insert('Deck', {
        'name': category.name,
      'language': category.description ?? 'Japanese',
      'parent_id': category.parentId,
      'sort_order': 0,
      'is_dirty': 1,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  /// Cleanup orphaned cards
  Future<int> cleanupOrphanedCards() async {
    final db = await database;
    return await db.rawDelete('''
      DELETE FROM UserProgress
      WHERE card_id NOT IN (SELECT id FROM Card)
    ''');
  }

  /// Mark a card as reviewed (compatibility method)
  Future<void> markCardReviewed(int cardId, int categoryId) async {
    // This is a compatibility method - in the new schema, 
    // review tracking is handled through UserProgress
    // For now, we'll just log that it was called
    AppLogger.info('markCardReviewed called for card $cardId in category $categoryId');
  }

  /// Get user progress for a specific card
  Future<UserProgress?> getUserProgress(int cardId, {String userId = 'default'}) async {
    final db = await database;
    
    final result = await db.rawQuery('''
      SELECT * FROM UserProgress 
      WHERE card_id = ? AND user_id = ?
    ''', [cardId, userId]);
    
    if (result.isEmpty) return null;
    
    return UserProgress.fromMap(result.first);
  }

  /// Save or update user progress
  Future<void> saveUserProgress(UserProgress progress) async {
    final db = await database;
    
    if (progress.id == 0) {
      // Insert new progress
      await db.insert('UserProgress', progress.toMap());
    } else {
      // Update existing progress
      await db.update(
        'UserProgress', 
        progress.toMap(), 
        where: 'id = ?',
        whereArgs: [progress.id]
      );
    }
  }

  /// Get all user progress for a deck
  Future<List<UserProgress>> getUserProgressForDeck(int deckId, {String userId = 'default'}) async {
    final db = await database;
    
    final result = await db.rawQuery('''
      SELECT up.* FROM UserProgress up
      INNER JOIN Card c ON up.card_id = c.id
      WHERE c.deck_id = ? AND up.user_id = ?
      ORDER BY up.next_review ASC
    ''', [deckId, userId]);
    
    return result.map((map) => UserProgress.fromMap(map)).toList();
  }

  /// Get cards due for review in a deck
  Future<List<UserProgress>> getCardsDueForReview(int deckId, {String userId = 'default'}) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    
    final result = await db.rawQuery('''
      SELECT up.* FROM UserProgress up
      INNER JOIN Card c ON up.card_id = c.id
      WHERE c.deck_id = ? AND up.user_id = ? 
      AND (up.next_review IS NULL OR up.next_review <= ?)
      ORDER BY up.next_review ASC
    ''', [deckId, userId, now]);
    
    return result.map((map) => UserProgress.fromMap(map)).toList();
  }

  /// Get flashcards due for review in a deck
  Future<List<Flashcard>> getFlashcardsDueForReview(int deckId, {String userId = 'default'}) async {
    final db = await database;
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
      final cardFields = await getCardFields(cardMap['id'] as int);
      final card = Card.fromMap({
        'id': cardMap['id'],
        'deck_id': cardMap['deck_id'],
        'notes': cardMap['notes'],
        'is_dirty': cardMap['is_dirty'],
        'updated_at': cardMap['updated_at'],
        'deck_name': cardMap['deck_name'],
      });
      
      final flashcard = _createFlashcardFromCard(card, cardFields);
      flashcards.add(flashcard);
    }
    
    return flashcards;
  }

  /// Get SRS statistics for a deck
  Future<Map<String, dynamic>> getSRSStats(int deckId, {String userId = 'default'}) async {
    final db = await database;
    
    // Get total cards in deck
    final totalResult = await db.rawQuery('''
      SELECT COUNT(*) as count FROM Card WHERE deck_id = ?
    ''', [deckId]);
    final totalCards = totalResult.first['count'] as int;
    
    // Get cards with progress
    final progressResult = await db.rawQuery('''
      SELECT 
        COUNT(*) as total_progress,
        SUM(CASE WHEN up.is_mastered = 1 THEN 1 ELSE 0 END) as mastered,
        SUM(CASE WHEN up.next_review IS NULL OR up.next_review <= ? THEN 1 ELSE 0 END) as due,
        AVG(up.ease_factor) as avg_ease_factor
      FROM UserProgress up
      INNER JOIN Card c ON up.card_id = c.id
      WHERE c.deck_id = ? AND up.user_id = ?
    ''', [DateTime.now().toIso8601String(), deckId, userId]);
    
    final stats = progressResult.first;
    final totalProgress = stats['total_progress'] as int? ?? 0;
    final mastered = stats['mastered'] as int? ?? 0;
    final due = stats['due'] as int? ?? 0;
    final avgEaseFactor = stats['avg_ease_factor'] as double? ?? 0.0;
    
    return {
      'totalCards': totalCards,
      'cardsWithProgress': totalProgress,
      'masteredCards': mastered,
      'dueCards': due,
      'masteryPercentage': totalProgress > 0 ? (mastered / totalProgress) * 100 : 0.0,
      'averageEaseFactor': avgEaseFactor,
    };
  }
    
}
