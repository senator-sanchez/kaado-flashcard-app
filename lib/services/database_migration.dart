import 'package:sqflite/sqflite.dart';

/// Database migration service to handle schema updates
class DatabaseMigration {
  static const int currentVersion = 5;
  static const int initialVersion = 1;

  /// Apply database migrations
  static Future<void> migrate(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createIncorrectCardsTable(db);
    }
    if (oldVersion < 3) {
      await _createSpacedRepetitionTable(db);
    }
    if (oldVersion < 4) {
      await _createSettingsTable(db);
    }
    if (oldVersion < 5) {
      await _addNotesColumn(db);
    }
  }

  /// Create the IncorrectCards table for tracking incorrect answers
  static Future<void> _createIncorrectCardsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS IncorrectCards (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        card_id INTEGER NOT NULL,
        category_id INTEGER NOT NULL,
        category_name TEXT NOT NULL,
        last_incorrect INTEGER NOT NULL,
        incorrect_count INTEGER DEFAULT 1,
        is_reviewed INTEGER DEFAULT 0,
        last_reviewed INTEGER,
        created_at INTEGER DEFAULT (strftime('%s', 'now')),
        UNIQUE(card_id, category_id)
      )
    ''');

    // Create indexes for better performance
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_incorrect_cards_category 
      ON IncorrectCards(category_id)
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_incorrect_cards_reviewed 
      ON IncorrectCards(is_reviewed)
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_incorrect_cards_last_incorrect 
      ON IncorrectCards(last_incorrect)
    ''');
  }

  /// Create the SpacedRepetition table for tracking spaced repetition data
  static Future<void> _createSpacedRepetitionTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS SpacedRepetition (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        card_id INTEGER NOT NULL,
        category_id INTEGER NOT NULL,
        interval INTEGER NOT NULL DEFAULT 1,
        repetitions INTEGER NOT NULL DEFAULT 0,
        ease_factor REAL NOT NULL DEFAULT 2.5,
        last_reviewed INTEGER NOT NULL DEFAULT 0,
        next_review INTEGER NOT NULL,
        streak INTEGER NOT NULL DEFAULT 0,
        total_reviews INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER DEFAULT (strftime('%s', 'now')),
        UNIQUE(card_id, category_id)
      )
    ''');

    // Create indexes for better performance
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_spaced_repetition_category 
      ON SpacedRepetition(category_id)
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_spaced_repetition_next_review 
      ON SpacedRepetition(next_review)
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_spaced_repetition_due 
      ON SpacedRepetition(next_review, category_id)
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_spaced_repetition_streak 
      ON SpacedRepetition(streak)
    ''');
  }

  /// Create the Settings table for storing app settings
  static Future<void> _createSettingsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS Settings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        key TEXT UNIQUE NOT NULL,
        value TEXT NOT NULL,
        created_at INTEGER DEFAULT (strftime('%s', 'now')),
        updated_at INTEGER DEFAULT (strftime('%s', 'now'))
      )
    ''');

    // Create index for better performance
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_settings_key 
      ON Settings(key)
    ''');
  }

  /// Add notes column to Card table
  static Future<void> _addNotesColumn(Database db) async {
    // Add notes column to Card table if it doesn't exist
    await db.execute('''
      ALTER TABLE Card ADD COLUMN notes TEXT
    ''');
  }
}
