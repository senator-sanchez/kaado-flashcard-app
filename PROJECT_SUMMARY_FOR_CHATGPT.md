# **Kaado App - Project Summary for ChatGPT**

## **App Overview**
**Kaado** is a Flutter-based Japanese language learning app that uses flashcards for vocabulary practice. The app features a comprehensive theme system, favorites functionality, and advanced navigation.

## **Current Version: v11.2 (Production Ready)**

### **Core Features**
- **Flashcard System**: Japanese vocabulary cards with kana, hiragana, English, and romaji
- **Favorites System**: Star icon to mark favorite cards, special "Favorites" category
- **Theme System**: Material Design 3 with light/dark mode support
- **Navigation**: Bottom navigation with Home and Library screens
- **Database**: SQLite with Japanese vocabulary and user progress tracking

### **Technical Stack**
- **Framework**: Flutter/Dart
- **Database**: SQLite with asset-based database
- **Theme**: Material Design 3 with custom extensions
- **State Management**: StatefulWidget with setState
- **Architecture**: Service-based with centralized logging

### **Key Components**

#### **1. Favorites System** ⭐
- Database column: `is_favorite INTEGER DEFAULT 0`
- Special category ID: -1 (Favorites)
- Star icon on card back with yellow color when favorited
- Database methods: `toggleFavorite()`, `getFavoriteCards()`, `getFavoriteCardsCount()`

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

### **Database Schema**
```sql
Card (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  kana TEXT NOT NULL,
  hiragana TEXT,
  english TEXT NOT NULL,
  romaji TEXT,
  script_type TEXT,
  notes TEXT,
  is_favorite INTEGER DEFAULT 0,  -- Favorites support
  category_id INTEGER NOT NULL,
  created_at INTEGER DEFAULT (strftime('%s', 'now')),
  updated_at INTEGER DEFAULT (strftime('%s', 'now'))
)
```

### **Theme Architecture**
- **AppThemeExtension**: Custom theme extension with 20+ properties
- **Light/Dark Themes**: Static theme data for both modes
- **Dynamic Colors**: Theme-aware colors that adapt to mode changes
- **Persistent Storage**: Theme selection saved across sessions

### **Key Services**
- **DatabaseService**: Card management, favorites, queries
- **ThemeService**: Material Design 3 theme management
- **AppLogger**: Centralized logging for debugging

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

### **Development Status**
- **Production Ready**: All major features implemented and tested
- **Favorites System**: Fully integrated with database and UI
- **Theme System**: Complete Material Design 3 migration
- **Navigation**: Bottom navigation and library screen functional
- **Code Quality**: Comprehensive cleanup and refactoring completed

### **Recent Updates (v11.2)**
- Added favorites system with database integration
- Implemented Material Design 3 theme overhaul
- Enhanced navigation with bottom navigation and library screen
- Improved card features with notes and edit functionality
- Comprehensive code cleanup and refactoring

### **Key Files Structure**
```
lib/
├── constants/
│   ├── app_colors.dart
│   ├── app_sizes.dart
│   └── app_strings.dart
├── models/
│   ├── flashcard.dart (with isFavorite field)
│   └── spaced_repetition.dart
├── screens/
│   ├── home_screen.dart (favorites integration)
│   ├── library_screen.dart (new)
│   └── main_navigation_screen.dart (bottom nav)
├── services/
│   ├── database_service.dart (favorites methods)
│   ├── app_logger.dart (new)
│   └── theme_service.dart (Material Design 3)
├── utils/
│   └── app_theme.dart (Material Design 3)
└── widgets/
    ├── flashcard_widget.dart (star icon, notes)
    ├── navigation_drawer.dart (favorites integration)
    └── quick_edit_card_dialog.dart (theme-aware)
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
