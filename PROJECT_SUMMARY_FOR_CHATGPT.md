# **Kaado App - Project Summary for ChatGPT**

## **App Overview**
**Kaado** is a Flutter-based Japanese language learning app that uses flashcards for vocabulary practice. The app features a comprehensive theme system, favorites functionality, and advanced navigation.

## **Current Version: v12.0 (Production Ready - Database Migration Complete)**

### **Core Features**
- **Flashcard System**: Japanese vocabulary cards with kana, hiragana, English, and romaji
- **Favorites System**: Star icon to mark favorite cards, special "Favorites" deck using DeckMembership
- **Theme System**: Material Design 3 with light/dark mode support
- **Navigation**: Bottom navigation with Home and Library screens
- **Database**: Migrated SQLite schema with Deck/Card/CardField/UserProgress/DeckMembership
- **Spaced Repetition**: Advanced SRS system with UserProgress tracking

### **Technical Stack**
- **Framework**: Flutter/Dart
- **Database**: SQLite with asset-based database
- **Theme**: Material Design 3 with custom extensions
- **State Management**: StatefulWidget with setState
- **Architecture**: Service-based with centralized logging

### **Key Components**

#### **1. Favorites System** ⭐
- **DeckMembership Table**: Many-to-many relationship between cards and decks
- **Favorites Deck**: Special deck under Japanese with `sort_order = -9999` to appear first
- **No Data Duplication**: Cards stored once, linked to multiple decks via join table
- **Star Icon**: Visual favorite toggle on card back with yellow color when favorited
- **Database Methods**: `toggleFavorite()`, `getFavoriteCards()`, `getFavoriteCardsCount()` using DeckMembership

#### **2. Theme System** 🎨
- **AppThemeExtension**: 20+ theme properties for comprehensive theming
- **Material Design 3**: Complete migration from custom theme system
- **Light/Dark Modes**: Seamless switching with persistent preferences
- **Theme Properties**: Colors, backgrounds, text, buttons, shadows, etc.

#### **3. Navigation System** 🧭
- **Bottom Navigation**: Custom implementation with sharp corners
- **Library Screen**: Browse categories, view cards, edit/delete functionality
- **Navigation Drawer**: Category tree with favorites integration
- **Screen Management**: IndexedStack with proper state management

#### **4. Card Features** 🃏
- **Swipe Actions**: Left (incorrect), Right (correct)
- **Notes System**: Free text notes with icon display
- **Edit Dialog**: Theme-aware editing with proper styling
- **Star Icon**: Favorite toggle with visual feedback

### **Database Schema (v12.0 - Migrated)**
```sql
-- Core Tables
Deck (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  language TEXT,
  parent_id INTEGER,
  sort_order INTEGER DEFAULT 0,
  is_dirty INTEGER DEFAULT 0,
  updated_at TEXT,
  has_children INTEGER DEFAULT 0,
  FOREIGN KEY (parent_id) REFERENCES Deck(id)
)

Card (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  deck_id INTEGER NOT NULL,
  notes TEXT,
  is_dirty INTEGER DEFAULT 0,
  updated_at TEXT,
  FOREIGN KEY (deck_id) REFERENCES Deck(id)
)

CardField (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  card_id INTEGER NOT NULL,
  field_definition_id INTEGER NOT NULL,
  field_value TEXT,
  is_dirty INTEGER DEFAULT 0,
  updated_at TEXT,
  FOREIGN KEY (card_id) REFERENCES Card(id),
  FOREIGN KEY (field_definition_id) REFERENCES FieldDefinition(id)
)

FieldDefinition (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  deck_id INTEGER NOT NULL,
  field_type TEXT NOT NULL,
  is_front INTEGER DEFAULT 0,
  is_back INTEGER DEFAULT 0,
  sort_order INTEGER DEFAULT 0,
  is_dirty INTEGER DEFAULT 0,
  updated_at TEXT,
  FOREIGN KEY (deck_id) REFERENCES Deck(id)
)

UserProgress (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  card_id INTEGER NOT NULL,
  user_id TEXT DEFAULT 'default',
  times_seen INTEGER DEFAULT 0,
  times_correct INTEGER DEFAULT 0,
  last_reviewed TEXT,
  next_review TEXT,
  difficulty_level INTEGER DEFAULT 0,
  is_mastered INTEGER DEFAULT 0,
  created_at TEXT,
  updated_at TEXT,
  interval INTEGER DEFAULT 1,
  repetitions INTEGER DEFAULT 0,
  ease_factor REAL DEFAULT 2.5,
  streak INTEGER DEFAULT 0,
  total_reviews INTEGER DEFAULT 0,
  is_dirty INTEGER DEFAULT 0,
  FOREIGN KEY (card_id) REFERENCES Card(id)
)

-- Many-to-Many Relationship for Favorites
DeckMembership (
  deck_id INTEGER NOT NULL,
  card_id INTEGER NOT NULL,
  PRIMARY KEY (deck_id, card_id),
  FOREIGN KEY (deck_id) REFERENCES Deck(id) ON DELETE CASCADE,
  FOREIGN KEY (card_id) REFERENCES Card(id) ON DELETE CASCADE
)
```

### **Theme Architecture**
- **AppThemeExtension**: Custom theme extension with 20+ properties
- **Light/Dark Themes**: Static theme data for both modes
- **Dynamic Colors**: Theme-aware colors that adapt to mode changes
- **Persistent Storage**: Theme selection saved across sessions

### **Key Services**
- **DatabaseService**: Card management, favorites via DeckMembership, queries
- **ThemeService**: Material Design 3 theme management
- **AppLogger**: Centralized logging for debugging

### **Schema Design Principles**
- **No Data Duplication**: Cards stored once, linked to multiple decks via DeckMembership
- **Favorites as Real Deck**: Favorites is a proper deck with `sort_order = -9999` to appear first
- **Many-to-Many Relationships**: Cards can belong to multiple decks without copying data
- **Scalable Architecture**: Supports user-created custom decks and complex hierarchies
- **Industry Best Practice**: Matches Anki, Quizlet, Memrise design patterns

### **Current Functionality**
- **Card Interaction**: Swipe, tap, star, notes, edit
- **Favorites**: Add/remove favorites, view favorites collection
- **Navigation**: Bottom nav, library screen, category tree
- **Theming**: Light/dark modes, Material Design 3 compliance
- **Settings**: Card display, backgrounds, categories

### **Code Quality**
- **Theme System**: Eliminated old ThemeColors, migrated to Material Design 3
- **Constants Management**: Centralized colors, sizes, strings
- **Error Handling**: Comprehensive error handling with AppLogger
- **Code Cleanup**: Removed unused files, imports, dead code

### **Performance**
- **Theme Switching**: Minimal rebuilds on theme changes
- **Database Queries**: Optimized favorites and card queries
- **Navigation**: Efficient screen management with IndexedStack
- **State Management**: Proper state updates for UI responsiveness

### **Development Status (v12.0)**
- **Production Ready**: Complete database migration and all features functional
- **Database Migration**: Successfully migrated from legacy schema to normalized design
- **Favorites System**: Fully integrated using DeckMembership join table
- **Spaced Repetition**: Advanced SRS system with UserProgress model
- **Code Quality**: All compilation errors resolved, legacy code removed
- **Performance**: Optimized queries, removed multithreading complexity
- **Schema Compliance**: Industry-standard design matching Anki/Quizlet patterns

### **Recent Updates (v12.0)**
- **Database Migration**: Complete migration to new normalized schema (Deck/Card/CardField/UserProgress/DeckMembership)
- **Favorites System**: Implemented using DeckMembership join table for many-to-many relationships
- **Spaced Repetition**: Advanced SRS system with UserProgress model and algorithm
- **Code Cleanup**: Removed all legacy code, unused imports, and debug prints
- **Performance**: Optimized database queries and removed multithreading complexity
- **Error Resolution**: Fixed all compilation errors and import conflicts
- **Schema Design**: Industry-standard design matching Anki/Quizlet patterns

### **Key Files Structure (v12.0)**
```
lib/
├── constants/
│   ├── app_colors.dart
│   ├── app_sizes.dart
│   └── app_strings.dart
├── models/
│   ├── flashcard.dart (wrapper for Card/CardField)
│   ├── category.dart (wrapper for Deck)
│   ├── deck.dart (new schema)
│   ├── card.dart (new schema)
│   ├── card_field.dart (new schema)
│   ├── field_definition.dart (new schema)
│   ├── user_progress.dart (new SRS model)
│   └── spaced_repetition.dart (legacy compatibility)
├── screens/
│   ├── home_screen.dart (migrated to new schema)
│   ├── library_screen.dart
│   ├── category_detail_screen.dart
│   └── main_navigation_screen.dart
├── services/
│   ├── database_service.dart (migrated to new schema)
│   ├── spaced_repetition_service.dart (UserProgress integration)
│   ├── app_logger.dart
│   └── theme_service.dart
├── utils/
│   └── app_theme.dart (Material Design 3)
└── widgets/
    ├── flashcard_widget.dart (DeckMembership favorites)
    ├── navigation_drawer.dart (deck treeview)
    └── category_management_dialogs.dart
```

### **Flutter/Dart Specifics**
- **Material Design 3**: Complete implementation with custom extensions
- **SQLite**: Local database with asset-based database
- **State Management**: StatefulWidget with setState for UI updates
- **Theme System**: Custom AppThemeExtension with 20+ properties
- **Navigation**: Bottom navigation with IndexedStack
- **Database**: SQLite with favorites and review tracking

### **Common Development Patterns**
- **Theme Access**: `context.appTheme` for theme properties
- **Database Operations**: Service-based with error handling
- **State Updates**: setState for UI refresh after database changes
- **Navigation**: IndexedStack for screen management
- **Favorites**: Special category ID (-1) for favorites collection

This summary provides a complete overview of the Kaado app for asking ChatGPT questions about Flutter development, Material Design 3, database management, theme systems, or any other technical aspects of the project.
