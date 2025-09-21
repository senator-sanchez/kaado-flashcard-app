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
import '../models/category.dart';
import '../models/flashcard.dart';
import '../models/incorrect_card.dart';
import '../models/spaced_repetition.dart';
import '../models/spaced_repetition_settings.dart';

// Project imports - Services
import 'database_migration.dart';

/// Service for managing database operations with the Japanese language database
/// Uses a pre-built SQLite database packaged with the app
class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _database;

  /// Get the database instance, initializing if necessary
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Initialize the database by opening it directly from assets
  Future<Database> _initDatabase() async {
    // Get the database path from assets
    final dbPath = await _getDatabasePath();
    
    // Open the database file with migration support
    final db = await openDatabase(
      dbPath,
      version: DatabaseMigration.currentVersion,
      onUpgrade: DatabaseMigration.migrate,
      onCreate: (db, version) async {
        // This won't be called since we're copying from assets, but good to have
        await DatabaseMigration.migrate(db, 0, version);
      },
      readOnly: false, // Allow writes for incorrect cards tracking
    );
    
    return db;
  }

  /// Get the database path from assets (always copy fresh from assets)
  Future<String> _getDatabasePath() async {
    // Get the app's documents directory
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final dbPath = join(documentsDirectory.path, 'japanese.db');
    
    // Database path set
    
    // Always copy fresh database from assets to ensure clean data
    // Copying fresh database from assets
    final ByteData data = await rootBundle.load('database/japanese.db');
    final dbFile = File(dbPath);
    await dbFile.writeAsBytes(data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes));
    // Fresh database copied from assets
    
    return dbPath;
  }

  // ===== CATEGORY OPERATIONS =====

  /// Get the complete category tree with hierarchical structure
  /// Computes has_children, is_card_category, and card_count dynamically
  Future<List<Category>> getCategoryTree() async {
    final db = await database;
    
    // Get all categories with computed has_children and card_count
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT 
        c.id as category_id,
        c.name,
        c.parent_id,
        c.sort_order,
        CASE 
          WHEN EXISTS(SELECT 1 FROM Category child WHERE child.parent_id = c.id) 
          THEN 1 
          ELSE 0 
        END as has_children,
        CASE 
          WHEN NOT EXISTS(SELECT 1 FROM Category child WHERE child.parent_id = c.id)
              AND EXISTS(SELECT 1 FROM Card WHERE category_id = c.id)
        THEN 1 
          ELSE 0 
        END as is_card_category,
        CASE 
          WHEN NOT EXISTS(SELECT 1 FROM Category child WHERE child.parent_id = c.id)
          THEN (SELECT COUNT(*) FROM Card WHERE category_id = c.id)
          ELSE 0
        END as card_count
      FROM Category c
      ORDER BY 
        COALESCE(c.parent_id, 0) ASC,
        c.sort_order ASC,
        c.name ASC
    ''');

    final List<Category> allCategories = List.generate(maps.length, (i) => Category.fromMap(maps[i]));
    
    // Build hierarchical structure
    return _buildCategoryHierarchy(allCategories);
  }

  /// Build the hierarchical category structure from flat list
  List<Category> _buildCategoryHierarchy(List<Category> allCategories) {
    final Map<int, Category> categoryMap = {};
    final List<Category> rootCategories = [];
    
    // Create a map of all categories by ID
    for (final category in allCategories) {
      categoryMap[category.id] = category;
    }
    
    // Build parent-child relationships recursively
    for (final category in allCategories) {
      if (category.parentId == null) {
        // This is a root category
        rootCategories.add(category);
        _buildChildrenRecursively(category, categoryMap);
      }
    }
    
    return rootCategories;
  }

  /// Recursively build children for a parent category
  void _buildChildrenRecursively(Category parent, Map<int, Category> categoryMap) {
    final List<Category> children = [];
    
    // Find all direct children of this parent
    for (final category in categoryMap.values) {
      if (category.parentId == parent.id) {
        children.add(category);
        // Recursively build children for this child
        _buildChildrenRecursively(category, categoryMap);
      }
    }
    
    // Sort children by sort_order
    children.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    
    // Assign children to parent
    if (children.isNotEmpty) {
      parent.children = children;
    }
  }

  /// Get all categories
  Future<List<Category>> getCategories() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'Category',
      orderBy: 'name ASC',
    );

    return List.generate(maps.length, (i) {
      return Category.fromMap(maps[i]);
    });
  }

  /// Get categories by parent ID
  Future<List<Category>> getCategoriesByParent(int? parentId) async {
    final db = await database;
    
    final List<Map<String, dynamic>> maps = await db.query(
      'Category',
      where: 'parent_id = ?',
      whereArgs: [parentId],
      orderBy: 'sort_order ASC',
    );

    return List.generate(maps.length, (i) => Category.fromMap(maps[i]));
  }

  /// Get a category by its ID
  Future<Category?> getCategoryById(int id) async {
    final db = await database;
    
    final List<Map<String, dynamic>> maps = await db.query(
      'Category',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return Category.fromMap(maps.first);
    }
    return null;
  }

  // ===== FLASHCARD OPERATIONS =====

  /// Get all flashcards for a specific category
  Future<List<Flashcard>> getCardsByCategory(int categoryId) async {
    final db = await database;
    
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT 
        c.id as card_id,
        c.kana,
        c.hiragana,
        c.english,
        c.romaji,
        c.script_type,
        c.notes,
        c.category_id,
        cat.name as category_name
      FROM Card c
      INNER JOIN Category cat ON c.category_id = cat.id
      WHERE c.category_id = ?
      ORDER BY c.id
    ''', [categoryId]);

    final cards = List.generate(maps.length, (i) => Flashcard.fromMap(maps[i]));
    
    // Debug: Print card count and IDs to help identify duplication
    // Loaded ${cards.length} cards for category $categoryId
    
    return cards;
  }

  /// Get a specific flashcard by ID
  Future<Flashcard?> getCardById(int id) async {
    final db = await database;
    
    final List<Map<String, dynamic>> maps = await db.query(
      'Card',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return Flashcard.fromMap(maps.first);
    }
    return null;
  }

  /// Get the count of cards in a category
  Future<int> getCardCount(int categoryId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM Card WHERE category_id = ?',
      [categoryId]
    );
    return result.first['count'] as int;
  }

  /// Close the database connection
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }

  /// Force a fresh initialization of the database
  /// This can help resolve database connection issues
  Future<void> resetDatabase() async {
    // Close existing database connection
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
    
    // Force reinitialization (will always copy fresh from assets)
    _database = await _initDatabase();
  }

  // ===== INCORRECT CARDS TRACKING =====

  /// Mark a card as incorrect and add it to the review list
  Future<void> markCardIncorrect(int cardId, int categoryId, String categoryName) async {
    try {
      final db = await database;
      
      // Check if card is already in incorrect list
      final existing = await db.query(
        'IncorrectCards',
        where: 'card_id = ? AND category_id = ?',
        whereArgs: [cardId, categoryId],
      );
      
      if (existing.isNotEmpty) {
        // Update existing record - increment count and update timestamp
        await db.update(
          'IncorrectCards',
          {
            'incorrect_count': (existing.first['incorrect_count'] as int) + 1,
            'last_incorrect': DateTime.now().millisecondsSinceEpoch,
            'is_reviewed': 0, // Reset reviewed status
          },
          where: 'card_id = ? AND category_id = ?',
          whereArgs: [cardId, categoryId],
        );
      } else {
        // Insert new record
        await db.insert('IncorrectCards', {
          'card_id': cardId,
          'category_id': categoryId,
          'category_name': categoryName,
          'last_incorrect': DateTime.now().millisecondsSinceEpoch,
          'incorrect_count': 1,
          'is_reviewed': 0,
        });
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Mark a card as correct and remove it from the review list
  Future<void> markCardCorrect(int cardId, int categoryId) async {
    final db = await database;
    
    await db.delete(
      'IncorrectCards',
      where: 'card_id = ? AND category_id = ?',
      whereArgs: [cardId, categoryId],
    );
  }

  /// Mark a card as reviewed (but keep it in the list for tracking)
  Future<void> markCardReviewed(int cardId, int categoryId) async {
    final db = await database;
    
    await db.update(
      'IncorrectCards',
      {
        'is_reviewed': 1,
        'last_reviewed': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'card_id = ? AND category_id = ?',
      whereArgs: [cardId, categoryId],
    );
  }

  /// Get all incorrect cards for a specific category
  Future<List<IncorrectCard>> getIncorrectCards(int categoryId) async {
    final db = await database;
    
    final List<Map<String, dynamic>> maps = await db.query(
      'IncorrectCards',
      where: 'category_id = ?',
      whereArgs: [categoryId],
      orderBy: 'last_incorrect DESC',
    );

    return List.generate(maps.length, (i) => IncorrectCard.fromMap(maps[i]));
  }

  /// Get flashcard objects for incorrect cards in a category
  Future<List<Flashcard>> getIncorrectCardsForCategory(int categoryId) async {
    final db = await database;
    
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT c.* FROM Card c
      INNER JOIN IncorrectCards ic ON c.id = ic.card_id
      WHERE c.category_id = ?
      ORDER BY ic.last_incorrect DESC
    ''', [categoryId]);

    return List.generate(maps.length, (i) => Flashcard.fromMap(maps[i]));
  }

  /// Get all decks that have incorrect cards available for review
  Future<List<ReviewDeck>> getReviewDecks() async {
    try {
      final db = await database;
      
      final List<Map<String, dynamic>> maps = await db.rawQuery('''
        SELECT 
          ic.category_id,
          c.name as category_name,
          (SELECT COUNT(*) FROM Card WHERE category_id = ic.category_id) as total_cards,
          COUNT(ic.card_id) as incorrect_cards,
          SUM(CASE WHEN ic.is_reviewed = 1 THEN 1 ELSE 0 END) as reviewed_cards,
          MAX(ic.last_reviewed) as last_reviewed
        FROM IncorrectCards ic
        INNER JOIN Category c ON ic.category_id = c.id
        GROUP BY ic.category_id, c.name
        HAVING incorrect_cards > 0
        ORDER BY incorrect_cards DESC, last_reviewed ASC
      ''');

      return List.generate(maps.length, (i) => ReviewDeck.fromMap(maps[i]));
    } catch (e) {
      return [];
    }
  }

  /// Get the total count of incorrect cards across all categories
  Future<int> getTotalIncorrectCards() async {
    final db = await database;
    
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM IncorrectCards WHERE is_reviewed = 0'
    );
    
    return result.first['count'] as int;
  }

  /// Clear all incorrect card records (for testing or reset purposes)
  Future<void> clearIncorrectCards() async {
    final db = await database;
    await db.delete('IncorrectCards');
  }

  /// Clean up orphaned cards that no longer exist in the main Card table
  Future<int> cleanupOrphanedCards() async {
    final db = await database;
    
    // Delete cards from IncorrectCards that don't exist in the main Card table
    final result = await db.rawDelete('''
      DELETE FROM IncorrectCards 
      WHERE card_id NOT IN (SELECT id FROM Card)
    ''');
    
    return result; // Returns number of deleted records
  }

  // ===== SPACED REPETITION METHODS =====

  /// Create or update a spaced repetition card
  Future<void> upsertSpacedRepetitionCard(SpacedRepetitionCard card) async {
    final db = await database;
    
    await db.insert(
      'SpacedRepetition',
      card.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get spaced repetition data for a specific card
  Future<SpacedRepetitionCard?> getSpacedRepetitionCard(int cardId, int categoryId) async {
    final db = await database;
    
    final List<Map<String, dynamic>> maps = await db.query(
      'SpacedRepetition',
      where: 'card_id = ? AND category_id = ?',
      whereArgs: [cardId, categoryId],
    );

    if (maps.isNotEmpty) {
      return SpacedRepetitionCard.fromMap(maps.first);
    }
    return null;
  }

  /// Get all spaced repetition cards for a category
  Future<List<SpacedRepetitionCard>> getSpacedRepetitionCardsForCategory(int categoryId) async {
    final db = await database;
    
    final List<Map<String, dynamic>> maps = await db.query(
      'SpacedRepetition',
      where: 'category_id = ?',
      whereArgs: [categoryId],
      orderBy: 'next_review ASC',
    );

    return List.generate(maps.length, (i) => SpacedRepetitionCard.fromMap(maps[i]));
  }

  /// Get cards due for review today
  Future<List<SpacedRepetitionCard>> getCardsDueForReview() async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;
    
    final List<Map<String, dynamic>> maps = await db.query(
      'SpacedRepetition',
      where: 'next_review <= ?',
      whereArgs: [now],
      orderBy: 'next_review ASC',
    );

    return List.generate(maps.length, (i) => SpacedRepetitionCard.fromMap(maps[i]));
  }

  /// Get cards due for review in a specific category
  Future<List<SpacedRepetitionCard>> getCardsDueForReviewInCategory(int categoryId) async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;
    
    final List<Map<String, dynamic>> maps = await db.query(
      'SpacedRepetition',
      where: 'category_id = ? AND next_review <= ?',
      whereArgs: [categoryId, now],
      orderBy: 'next_review ASC',
    );

    return List.generate(maps.length, (i) => SpacedRepetitionCard.fromMap(maps[i]));
  }

  /// Get new cards (never reviewed) for a category
  Future<List<SpacedRepetitionCard>> getNewCardsForCategory(int categoryId, {int limit = 20}) async {
    final db = await database;
    
    final List<Map<String, dynamic>> maps = await db.query(
      'SpacedRepetition',
      where: 'category_id = ? AND repetitions = 0',
      whereArgs: [categoryId],
      orderBy: 'created_at ASC',
      limit: limit,
    );

    return List.generate(maps.length, (i) => SpacedRepetitionCard.fromMap(maps[i]));
  }

  /// Get review statistics for a category
  Future<Map<String, int>> getReviewStatsForCategory(int categoryId) async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;
    
    // Get total cards in category
    final totalResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM Card WHERE category_id = ?',
      [categoryId]
    );
    final totalCards = totalResult.first['count'] as int;

    // Get new cards (never reviewed)
    final newResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM SpacedRepetition WHERE category_id = ? AND repetitions = 0',
      [categoryId]
    );
    final newCards = newResult.first['count'] as int;

    // Get cards due for review
    final reviewResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM SpacedRepetition WHERE category_id = ? AND next_review <= ? AND repetitions > 0',
      [categoryId, now]
    );
    final reviewCards = reviewResult.first['count'] as int;

    // Get overdue cards
    final overdueResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM SpacedRepetition WHERE category_id = ? AND next_review < ? AND repetitions > 0',
      [categoryId, now]
    );
    final overdueCards = overdueResult.first['count'] as int;

    return {
      'total': totalCards,
      'new': newCards,
      'review': reviewCards,
      'overdue': overdueCards,
    };
  }

  /// Get overall review statistics
  Future<Map<String, int>> getOverallReviewStats() async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;
    
    // Get total cards
    final totalResult = await db.rawQuery('SELECT COUNT(*) as count FROM Card');
    final totalCards = totalResult.first['count'] as int;

    // Get new cards
    final newResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM SpacedRepetition WHERE repetitions = 0'
    );
    final newCards = newResult.first['count'] as int;

    // Get cards due for review
    final reviewResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM SpacedRepetition WHERE next_review <= ? AND repetitions > 0',
      [now]
    );
    final reviewCards = reviewResult.first['count'] as int;

    // Get overdue cards
    final overdueResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM SpacedRepetition WHERE next_review < ? AND repetitions > 0',
      [now]
    );
    final overdueCards = overdueResult.first['count'] as int;

    return {
      'total': totalCards,
      'new': newCards,
      'review': reviewCards,
      'overdue': overdueCards,
    };
  }

  /// Delete spaced repetition data for a card
  Future<void> deleteSpacedRepetitionCard(int cardId, int categoryId) async {
    final db = await database;
    
    await db.delete(
      'SpacedRepetition',
      where: 'card_id = ? AND category_id = ?',
      whereArgs: [cardId, categoryId],
    );
  }

  /// Clear all spaced repetition data (for testing or reset purposes)
  Future<void> clearSpacedRepetitionData() async {
    final db = await database;
    await db.delete('SpacedRepetition');
  }

  /// Clean up orphaned spaced repetition cards
  Future<int> cleanupOrphanedSpacedRepetitionCards() async {
    final db = await database;
    
    final result = await db.rawDelete('''
      DELETE FROM SpacedRepetition 
      WHERE card_id NOT IN (SELECT id FROM Card)
    ''');
    
    return result;
  }

  // ===== SPACED REPETITION SETTINGS METHODS =====

  /// Save spaced repetition settings to database
  Future<void> saveSpacedRepetitionSettings(SpacedRepetitionSettings settings) async {
    final db = await database;
    
    // Use a simple key-value approach for settings
    final settingsMap = settings.toMap();
    
    // Clear existing settings
    await db.delete('Settings', where: 'key LIKE ?', whereArgs: ['spaced_repetition_%']);
    
    // Insert new settings
    for (final entry in settingsMap.entries) {
      await db.insert('Settings', {
        'key': 'spaced_repetition_${entry.key}',
        'value': entry.value.toString(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  /// Load spaced repetition settings from database
  Future<SpacedRepetitionSettings> loadSpacedRepetitionSettings() async {
    final db = await database;
    
    final results = await db.query(
      'Settings',
      where: 'key LIKE ?',
      whereArgs: ['spaced_repetition_%'],
    );
    
    if (results.isEmpty) {
      return SpacedRepetitionPresets.standard;
    }
    
    final settingsMap = <String, dynamic>{};
    for (final row in results) {
      final key = row['key'] as String;
      final value = row['value'] as String;
      final cleanKey = key.replaceFirst('spaced_repetition_', '');
      
      // Convert string values back to appropriate types
      if (cleanKey.contains('ease_factor') || cleanKey.contains('decrease') || cleanKey.contains('increase')) {
        settingsMap[cleanKey] = double.parse(value);
      } else if (cleanKey == 'review_order') {
        settingsMap[cleanKey] = int.parse(value);
      } else if (cleanKey == 'mix_new_and_review' || cleanKey.contains('enable_')) {
        settingsMap[cleanKey] = value == '1';
      } else {
        settingsMap[cleanKey] = int.parse(value);
      }
    }
    
    return SpacedRepetitionSettings.fromMap(settingsMap);
  }

  // ===== CATEGORY MANAGEMENT METHODS =====

  /// Get all categories
  Future<List<Category>> getAllCategories() async {
    final db = await database;
    
    final results = await db.query(
      'Category',
      orderBy: 'name ASC',
    );
    
    return results.map((map) => Category.fromMap(map)).toList();
  }

  /// Add a new category
  Future<int> addCategory(String name, String? description) async {
    final db = await database;
    
    final categoryMap = {
      'name': name,
      'description': description,
    };
    
    return await db.insert('Category', categoryMap);
  }

  /// Update an existing category
  Future<void> updateCategory(Category category) async {
    final db = await database;
    
    await db.update(
      'Category',
      {
        'name': category.name,
        'description': category.description,
      },
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  /// Delete a category and all its cards
  Future<void> deleteCategory(int categoryId) async {
    final db = await database;
    
    // Delete all cards in this category first
    await db.delete('Card', where: 'category_id = ?', whereArgs: [categoryId]);
    
    // Delete the category
    await db.delete('Category', where: 'id = ?', whereArgs: [categoryId]);
  }

  // ===== CARD MANAGEMENT METHODS =====

  /// Add a new card
  Future<int> addCard(
    int categoryId,
    String kana,
    String english, {
    String? hiragana,
    String? romaji,
    String? notes,
  }) async {
    final db = await database;
    
    final cardMap = {
      'kana': kana,
      'hiragana': hiragana,
      'english': english,
      'romaji': romaji,
      'notes': notes,
      'category_id': categoryId,
    };
    
    return await db.insert('Card', cardMap);
  }

  /// Update an existing card
  Future<void> updateCard(Flashcard card) async {
    final db = await database;
    
    try {
      await db.update(
        'Card',
        {
          'kana': card.kana,
          'hiragana': card.hiragana,
          'english': card.english,
          'romaji': card.romaji,
          'notes': card.notes,
        },
        where: 'id = ?',
        whereArgs: [card.id],
      );
    } catch (e) {
      // If notes column doesn't exist, try to add it and retry
      if (e.toString().contains('no such column: notes')) {
        try {
          await db.execute('ALTER TABLE Card ADD COLUMN notes TEXT');
          // Retry the update with notes
          await db.update(
            'Card',
            {
              'kana': card.kana,
              'hiragana': card.hiragana,
              'english': card.english,
              'romaji': card.romaji,
              'notes': card.notes,
            },
            where: 'id = ?',
            whereArgs: [card.id],
          );
        } catch (addColumnError) {
          // If adding the column fails, update without notes
          await db.update(
            'Card',
            {
              'kana': card.kana,
              'hiragana': card.hiragana,
              'english': card.english,
              'romaji': card.romaji,
            },
            where: 'id = ?',
            whereArgs: [card.id],
          );
        }
      } else {
        rethrow;
      }
    }
  }

  /// Delete a card
  Future<void> deleteCard(int cardId) async {
    final db = await database;
    
    // Delete from Card table
    await db.delete('Card', where: 'id = ?', whereArgs: [cardId]);
    
    // Also delete from IncorrectCards if it exists
    await db.delete('IncorrectCards', where: 'card_id = ?', whereArgs: [cardId]);
  }

  // ===== FAVORITES MANAGEMENT METHODS =====

  /// Toggle favorite status of a card
  Future<void> toggleFavorite(int cardId) async {
    final db = await database;
    
    // Get current favorite status
    final result = await db.query(
      'Card',
      columns: ['is_favorite'],
      where: 'id = ?',
      whereArgs: [cardId],
    );
    
    if (result.isNotEmpty) {
      final currentStatus = result.first['is_favorite'] as int? ?? 0;
      final newStatus = currentStatus == 1 ? 0 : 1;
      
      await db.update(
        'Card',
        {'is_favorite': newStatus},
        where: 'id = ?',
        whereArgs: [cardId],
      );
    }
  }

  /// Get all favorite cards
  Future<List<Flashcard>> getFavoriteCards() async {
    final db = await database;
    
    final results = await db.rawQuery('''
      SELECT c.*, cat.name as category_name
      FROM Card c
      LEFT JOIN Category cat ON c.category_id = cat.id
      WHERE c.is_favorite = 1
      ORDER BY c.id
    ''');
    
    return results.map((map) => Flashcard.fromMap(map)).toList();
  }

  /// Get favorite cards count
  Future<int> getFavoriteCardsCount() async {
    final db = await database;
    
    final result = await db.rawQuery('''
      SELECT COUNT(*) as count
      FROM Card
      WHERE is_favorite = 1
    ''');
    
    return result.first['count'] as int? ?? 0;
  }
}
