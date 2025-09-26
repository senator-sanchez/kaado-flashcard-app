# **Kaado App - Unified Project Summary**

## **App Overview**
**Kaado** is a Flutter-based Japanese language learning app that uses flashcards for vocabulary practice. The app features a comprehensive theme system, favorites functionality, advanced navigation, spaced repetition system, and persistent incorrect card tracking for enhanced learning.

## **Current Version: v12.3 (Production Ready - Favorites Deck Review System Complete)**

### **Core Features**
- **Flashcard System**: Japanese vocabulary cards with kana, hiragana, English, and romaji
- **Favorites System**: Star icon to mark favorite cards, special "Favorites" deck using DeckMembership
- **Incorrect Cards Tracking**: Per-deck tracking of incorrect cards with immediate review prompts
- **Review System**: Persistent database-backed incorrect card tracking with manual exit
- **Theme System**: Material Design 3 with light/dark mode support
- **Navigation**: Bottom navigation with Home and Library screens
- **Database**: Migrated SQLite schema with Deck/Card/CardField/UserProgress/DeckMembership/IncorrectCards
- **Spaced Repetition**: Advanced SRS system with UserProgress tracking

### **Technical Stack**
- **Framework**: Flutter/Dart
- **Database**: SQLite with asset-based database
- **Theme**: Material Design 3 with custom extensions
- **State Management**: StatefulWidget with setState
- **Architecture**: Service-based with centralized logging

## **User Interface & Experience**

### **Main Navigation Structure**
- **Bottom Navigation Bar**: Two-tab system with Home and Library icons (no text labels)
- **Navigation Drawer**: Left-side drawer with deck treeview, settings, and review options
- **App Bar**: Dynamic title, back button in review mode, three-dot menu for settings

### **Home Screen (Main Study Interface)**
- **Flashcard Display**: Large, responsive card with front/back content
- **Swipe Gestures**: 
  - **Right Swipe**: Mark as correct, advance to next card
  - **Left Swipe**: Mark as incorrect, advance to next card
  - **Up Swipe**: Skip card (no scoring)
  - **Down Swipe**: Skip card (no scoring)
- **Progress Bar**: Shows current position (e.g., "3 of 48") and percentage score
- **Favorites Star**: Top-center of card, toggles favorite status
- **Notes Icon**: Appears on back of card when notes field has content
- **Review Prompt**: Appears after incorrect swipes, shows count of incorrect cards

### **Card Display System**
- **Responsive Text**: Dynamic font sizing based on content length
- **Overflow Handling**: Text wraps and shrinks to fit card boundaries
- **Field Customization**: Front/back field display can be customized via settings
- **Background Support**: Custom background photos with adaptive text backgrounds
- **Consistent Sizing**: All card states (placeholder, main, loading) use same dimensions

### **Review Mode Interface**
- **Independent Scoring**: Separate progress tracking from main deck
- **Manual Exit**: Back button to return to main deck
- **Persistent State**: Review mode remains active until manually exited
- **Card Removal**: Correctly answered cards are immediately removed from review
- **Progress Reset**: Review-specific counters reset when entering review mode

### **Navigation Drawer Features**
- **Deck Treeview**: Hierarchical display of all decks with card counts
- **Favorites Deck**: Special deck showing all favorited cards
- **Settings Access**: Card display settings, spaced repetition settings
- **Review Options**: Incorrect cards review, spaced repetition review
- **Theme Controls**: Light/dark mode toggle
- **Background Settings**: Custom background photo selection

### **Theme System**
- **Material Design 3**: Modern design with dynamic color support
- **Light/Dark Mode**: Automatic system theme detection with manual override
- **Custom Colors**: App-specific color palette with primary blue, amber accents
- **Consistent Styling**: All UI elements follow the same theme principles
- **Adaptive Text**: Text colors adjust based on background for readability

## **Database Architecture & Data Flow**

### **Core Database Schema**
```sql
-- Main Tables
Deck (id, name, language, parent_id, sort_order, is_dirty, updated_at)
Card (id, deck_id, created_at, updated_at)
CardField (id, card_id, field_name, field_value, created_at, updated_at)
UserProgress (id, card_id, user_id, times_seen, times_correct, last_reviewed, next_review, difficulty_level, is_mastered, created_at, updated_at, interval, repetitions, ease_factor, streak, total_reviews, is_dirty)
DeckMembership (id, deck_id, card_id, created_at, updated_at)
IncorrectCards (id, card_id, deck_id, created_at)
```

### **Data Relationships**
- **Deck → Card**: One-to-many (deck contains multiple cards)
- **Card → CardField**: One-to-many (card has multiple fields like kana, hiragana, English)
- **Card → UserProgress**: One-to-one (each card has progress tracking)
- **Deck → DeckMembership**: One-to-many (deck membership for favorites)
- **Card → IncorrectCards**: One-to-many (card can be marked incorrect multiple times)

### **Key Data Flow Patterns**
1. **Card Loading**: `getCardsByCategory()` → `getCardsWithFieldsByDeck()` → `_createFlashcardFromCard()`
2. **Favorites System**: `toggleFavorite()` → `DeckMembership` table → `getFavoriteCards()`
3. **Incorrect Tracking**: `markCardIncorrectInDatabase()` → `IncorrectCards` table → `getIncorrectCardsFromDatabase()`
4. **SRS Updates**: `_recordAnswer()` → `upsertSpacedRepetitionCard()` → `UserProgress` table
5. **Review Mode**: `getIncorrectCardsFromDatabase()` → filter cards → display in review mode

### **Database Service Architecture**
- **Singleton Pattern**: `DatabaseService()` ensures single instance
- **Connection Management**: Static `_database` with initialization guards
- **Error Handling**: Consistent `AppLogger.error()` throughout
- **Performance**: Caching and debouncing to prevent excessive database calls
- **Thread Safety**: Static flags prevent concurrent operations

## **State Management & Performance**

### **Home Screen State Variables**
```dart
// Core State
List<Flashcard> _currentCards = [];
int _currentCardIndex = 0;
bool _showAnswer = false;
bool _isLoading = false;

// Scoring State
int _correctAnswers = 0;
int _totalAttempts = 0;
int _reviewCorrectAnswers = 0;
int _reviewTotalAttempts = 0;

// Review Mode State
bool _isReviewMode = false;
int _currentCategoryId = 0;

// Animation State
bool _isAnimationBlocked = false;
```

### **Performance Optimizations**
- **Static Caching**: `_staticCategories` with 5-minute timeout
- **Debouncing**: Prevents rapid successive database calls
- **Global Loading Flags**: `_isLoadingGlobally` prevents concurrent operations
- **Swipe Operation Flags**: `_isSwipeOperation` blocks database calls during gestures
- **Connection Pooling**: Single database connection with proper lifecycle management

### **Memory Management**
- **Widget Disposal**: Proper cleanup of timers and controllers
- **State Persistence**: Critical state maintained across widget rebuilds
- **Resource Cleanup**: Database connections properly closed
- **Cache Management**: Automatic cache invalidation and refresh

## **File Structure & Key Components**

### **Core Application Files**
```
lib/
├── main.dart                          # App entry point
├── firebase_options.dart              # Firebase configuration
├── constants/                         # App constants and configuration
│   ├── app_colors.dart               # Color definitions
│   ├── app_constants.dart            # General constants
│   ├── app_durations.dart            # Animation durations
│   ├── app_sizes.dart                # Size definitions
│   ├── app_strings.dart              # String constants
│   └── app_text_styles.dart          # Text style definitions
├── models/                           # Data models
│   ├── card.dart                     # Card model
│   ├── card_display_settings.dart    # Display settings model
│   ├── card_field.dart               # Card field model
│   ├── category.dart                 # Category model
│   ├── deck.dart                     # Deck model
│   ├── flashcard.dart                # Flashcard model
│   ├── incorrect_card.dart           # Incorrect card model
│   ├── spaced_repetition.dart        # SRS model
│   ├── spaced_repetition_settings.dart # SRS settings
│   └── user_progress.dart            # User progress model
├── screens/                          # Main screens
│   ├── home_screen.dart              # Main study interface
│   ├── library_screen.dart           # Library/deck selection
│   ├── main_navigation_screen.dart   # Bottom navigation wrapper
│   ├── category_detail_screen.dart   # Category details
│   ├── review_screen.dart            # Review interface
│   ├── spaced_repetition_settings_screen.dart # SRS settings
│   └── card_display_settings_screen.dart # Display settings
├── services/                         # Business logic services
│   ├── app_logger.dart               # Centralized logging
│   ├── background_photo_service.dart # Background management
│   ├── card_display_service.dart     # Display settings
│   ├── database_service.dart         # Database operations
│   ├── service_locator.dart          # Dependency injection
│   ├── spaced_repetition_service.dart # SRS logic
│   ├── swipe_animation_service.dart  # Animation handling
│   └── theme_service.dart            # Theme management
├── utils/                           # Utility functions
│   ├── animation_constants.dart      # Animation values
│   ├── app_theme.dart               # Theme definitions
│   ├── constants.dart                # General utilities
│   ├── decoration_utils.dart         # UI decorations
│   ├── logger.dart                   # Logging utilities
│   └── system_ui_utils.dart         # System UI helpers
└── widgets/                         # Reusable UI components
    ├── action_buttons.dart           # Action button components
    ├── background_photo_settings_traditional.dart # Background settings
    ├── background_selector_dialog.dart # Background picker
    ├── background_widget.dart        # Background display
    ├── card_display_settings_dialog.dart # Display settings dialog
    ├── card_edit_dialog.dart         # Card editing
    ├── card_item.dart                # Card list item
    ├── category_card.dart            # Category display
    ├── category_management_dialogs.dart # Category management
    ├── fab_menu.dart                 # Floating action menu
    ├── flashcard_widget.dart         # Main flashcard component
    ├── navigation_drawer.dart        # Navigation drawer
    ├── progress_bar.dart             # Progress indicator
    ├── quick_edit_card_dialog.dart   # Quick card editing
    ├── text_with_background.dart     # Text with background
    ├── common/                       # Common widgets
    └── shared/                       # Shared components
```

### **Key Service Components**

#### **DatabaseService** (`lib/services/database_service.dart`)
- **Purpose**: Centralized database operations and data management
- **Key Methods**:
  - `getDeckTree()`: Retrieves hierarchical deck structure
  - `getCardsByCategory()`: Loads cards for specific category
  - `getFavoriteCards()`: Retrieves favorited cards
  - `markCardIncorrectInDatabase()`: Marks card as incorrect
  - `markCardCorrectInDatabase()`: Removes card from incorrect status
  - `getIncorrectCardsFromDatabase()`: Gets incorrect cards for deck
  - `toggleFavorite()`: Toggles favorite status
  - `upsertSpacedRepetitionCard()`: Updates SRS data
- **Architecture**: Singleton pattern with static database connection
- **Performance**: Caching, debouncing, and connection pooling

#### **HomeScreen** (`lib/screens/home_screen.dart`)
- **Purpose**: Main study interface with flashcard display and interaction
- **Key Features**:
  - Swipe gesture handling (left/right/up/down)
  - Review mode management
  - Progress tracking and scoring
  - Favorites functionality
  - Card display and animation
- **State Management**: StatefulWidget with comprehensive state variables
- **Performance**: Animation blocking, gesture debouncing, state persistence

#### **NavigationDrawer** (`lib/widgets/navigation_drawer.dart`)
- **Purpose**: Left-side navigation with deck treeview and settings
- **Key Features**:
  - Hierarchical deck display
  - Favorites deck integration
  - Settings access
  - Review mode triggers
  - Theme controls
- **Performance**: Static caching, debounced loading, global loading flags

#### **FlashcardWidget** (`lib/widgets/flashcard_widget.dart`)
- **Purpose**: Main flashcard display component
- **Key Features**:
  - Responsive text sizing
  - Overflow handling
  - Favorites star integration
  - Notes icon display
  - Background support
- **Responsive Design**: Dynamic font sizing based on content length

### **Database Schema Details**

#### **IncorrectCards Table**
```sql
CREATE TABLE IF NOT EXISTS IncorrectCards (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  card_id INTEGER NOT NULL,
  deck_id INTEGER NOT NULL,
  created_at TEXT NOT NULL,
  FOREIGN KEY (card_id) REFERENCES Card(id) ON DELETE CASCADE,
  FOREIGN KEY (deck_id) REFERENCES Deck(id) ON DELETE CASCADE
)
```

#### **UserProgress Table**
```sql
CREATE TABLE IF NOT EXISTS UserProgress (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  card_id INTEGER NOT NULL,
  user_id INTEGER NOT NULL,
  times_seen INTEGER DEFAULT 0,
  times_correct INTEGER DEFAULT 0,
  last_reviewed TEXT,
  next_review TEXT,
  difficulty_level INTEGER DEFAULT 1,
  is_mastered INTEGER DEFAULT 0,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  interval INTEGER DEFAULT 1,
  repetitions INTEGER DEFAULT 0,
  ease_factor REAL DEFAULT 2.5,
  streak INTEGER DEFAULT 0,
  total_reviews INTEGER DEFAULT 0,
  is_dirty INTEGER DEFAULT 0,
  FOREIGN KEY (card_id) REFERENCES Card(id) ON DELETE CASCADE
)
```

## **Troubleshooting & Common Issues**

### **Performance Issues**
- **Skipped Frames**: Usually caused by excessive database calls during swipe gestures
  - **Solution**: Ensure `_isSwipeOperation` flag is properly set during gestures
  - **Prevention**: Use debouncing and caching in navigation drawer
- **Memory Leaks**: Caused by improper widget disposal or timer cleanup
  - **Solution**: Implement proper `dispose()` methods and cleanup timers
  - **Prevention**: Use static caching and connection pooling

### **Database Issues**
- **Connection Timeouts**: Multiple simultaneous database operations
  - **Solution**: Use global loading flags (`_isLoadingGlobally`)
  - **Prevention**: Implement proper connection management
- **Data Inconsistency**: Race conditions in database operations
  - **Solution**: Use static flags to prevent concurrent operations
  - **Prevention**: Implement proper state management

### **UI Issues**
- **Card Size Inconsistency**: Different card states using different sizing
  - **Solution**: Standardize all card states to use `MediaQuery.of(context).size.height * 0.3`
  - **Prevention**: Use consistent sizing constants
- **Text Overflow**: Long text content exceeding card boundaries
  - **Solution**: Implement responsive text sizing with `FittedBox` and `LayoutBuilder`
  - **Prevention**: Use dynamic font sizing based on content length

### **Review System Issues**
- **Cards Not Removing**: Incorrect cards not being removed from review
  - **Solution**: Ensure `markCardCorrectInDatabase()` is called for correct answers
  - **Prevention**: Implement proper database transaction handling
- **Review Mode Persistence**: Review mode not persisting across sessions
  - **Solution**: Use database-backed storage instead of memory
  - **Prevention**: Implement proper state persistence

### **Debugging Tips**
- **Enable AppLogger**: Use `AppLogger.error()` for consistent error handling
- **Check Database State**: Verify database connections and table creation
- **Monitor Performance**: Use Flutter DevTools for performance analysis
- **Test Edge Cases**: Ensure proper handling of empty states and error conditions

## **GitHub Workflow & Version Management**

### **Repository Information**
- **GitHub Repository**: `https://github.com/senator-sanchez/kaado-flashcard-app`
- **Current Working Directory**: `C:\Users\Clayt\Flutter_Apps\Kaado\kaadoapp_v12`
- **Latest Version**: v12.1 (Complete code cleanup and knowledge base documentation)

### **Version Incrementing Process**
The preferred workflow for version management follows this pattern:

#### **1. Version Numbering Convention**
- **Major Version**: v12.x (significant feature additions or architectural changes)
- **Minor Version**: v12.1, v12.2, v12.3 (feature improvements, bug fixes, documentation)
- **Current Pattern**: Increment minor version for each significant update

#### **2. Git Workflow Process**
```bash
# 1. Check current status and version
git status
git tag --sort=-version:refname

# 2. Add all changes
git add .

# 3. Commit with descriptive message
git commit -m "v12.x: [Brief description]

- [Feature 1]: Description
- [Feature 2]: Description
- [Technical improvement]: Description
- [Documentation update]: Description"

# 4. Create new branch for version
git checkout -b v12.x-branch

# 5. Push branch to GitHub
git push -u origin v12.x-branch

# 6. Create annotated tag with detailed release notes
git tag -a v12.x -m "v12.x: [Comprehensive title]

Features:
- [Feature 1]: Detailed description
- [Feature 2]: Detailed description

Technical Improvements:
- [Technical improvement 1]: Description
- [Technical improvement 2]: Description

Bug Fixes:
- [Bug fix 1]: Description
- [Bug fix 2]: Description"

# 7. Push tag to GitHub
git push origin v12.x

# 8. Verify everything is pushed
git status
git tag --sort=-version:refname
```

#### **3. Commit Message Format**
```
v12.x: [Brief descriptive title]

- [Category]: [Description]
- [Category]: [Description]
- [Category]: [Description]
```

**Categories used:**
- **Features**: New functionality added
- **Fixes**: Bug fixes and issue resolutions
- **Improvements**: Performance and code quality enhancements
- **Documentation**: Updates to documentation and knowledge base
- **Refactoring**: Code restructuring and optimization
- **Dependencies**: Package and dependency updates

#### **4. Tag Message Format**
```
v12.x: [Comprehensive title]

Features:
- [Feature 1]: Detailed description with impact
- [Feature 2]: Detailed description with impact

Technical Improvements:
- [Improvement 1]: Technical details and benefits
- [Improvement 2]: Technical details and benefits

Bug Fixes:
- [Fix 1]: Issue description and resolution
- [Fix 2]: Issue description and resolution

Breaking Changes:
- [If any]: Description of breaking changes and migration steps
```

#### **5. Branch Naming Convention**
- **Version Branches**: `v12.x-branch`
- **Feature Branches**: `feature/[feature-name]`
- **Hotfix Branches**: `hotfix/[issue-description]`

#### **6. Current Repository Structure**
```
Branches:
- master (main branch)
- v11.1-branch
- v11.2-branch  
- v11.3-branch
- v12.0-branch
- v12.1-branch (current)

Tags:
- v12.1 (latest)
- v12.0
- v11.3
- v11.2
- v11.1
```

#### **7. Release Process Checklist**
- [ ] All changes committed and tested
- [ ] Version number incremented appropriately
- [ ] Comprehensive commit message written
- [ ] New branch created for version
- [ ] Branch pushed to GitHub
- [ ] Annotated tag created with detailed release notes
- [ ] Tag pushed to GitHub
- [ ] Status verified (clean working tree)
- [ ] Tags confirmed on GitHub

### **Version History**
- **v12.3** (2025-01-25): Favorites deck review system complete with full functionality
- **v12.2** (2025-01-25): GitHub workflow documentation and version management
- **v12.1** (2025-01-25): Complete code cleanup and knowledge base documentation
- **v12.0**: Previous stable version
- **v11.3**: Previous version
- **v11.2**: Previous version
- **v11.1**: Previous version

## **Firebase Deployment Process**

### **Firebase App Distribution Setup**
- **Project ID**: kaado-b7fdb
- **App ID**: 1:134812932196:android:e108d67afbc61f545d2771
- **Test Group**: Test
- **Firebase Console**: [Project Console](https://console.firebase.google.com/project/kaado-b7fdb)

### **Deployment Workflow**
The complete process for deploying to Firebase App Distribution:

#### **1. Build Release APK**
```bash
# Build the Flutter app in release mode
flutter build apk --release
```
**Output**: `build/app/outputs/flutter-apk/app-release.apk` (typically 50MB)

#### **2. Deploy to Firebase App Distribution**
```bash
# Distribute APK to test group
firebase appdistribution:distribute build/app/outputs/flutter-apk/app-release.apk \
  --app 1:134812932196:android:e108d67afbc61f545d2771 \
  --groups Test
```

#### **3. Deployment Results**
- **Release Version**: Auto-incremented (e.g., 11.0.0 (12))
- **Status**: Successfully distributed to testers
- **Download Link**: Provided with 1-hour expiration
- **Firebase Console**: Direct link to view release details

### **Firebase Configuration**
- **Project**: kaado-b7fdb
- **App Distribution**: Enabled for Android
- **Test Groups**: Test (primary testing group)
- **Release Notes**: Optional (can be added with `--release-notes` flag)

### **Build Optimization**
- **Font Tree-shaking**: MaterialIcons reduced by 99.7% (1.6MB → 5.4KB)
- **Build Time**: ~110 seconds for release APK
- **APK Size**: ~50MB (optimized)

### **Deployment Checklist**
- [ ] Code changes committed and tested
- [ ] Version incremented appropriately
- [ ] Flutter dependencies resolved
- [ ] Release APK built successfully
- [ ] Firebase CLI authenticated
- [ ] APK distributed to test group
- [ ] Download links shared with testers
- [ ] Firebase console updated with new release

### **Troubleshooting**
- **Missing APK**: Run `flutter build apk --release` first
- **Authentication**: Ensure `firebase login` is completed
- **Project Access**: Verify Firebase project permissions
- **Test Group**: Confirm test group exists in Firebase console

## **Future Architecture Considerations**

### **Planned Improvements**
- **ElectricSQL Integration**: Cloud synchronization for multi-device support
- **Advanced SRS**: SuperMemo 2 algorithm implementation
- **Offline Support**: Enhanced offline capabilities with sync
- **Performance Optimization**: Multithreading for database operations
- **Analytics**: User progress tracking and insights

### **Scalability Considerations**
- **Database Optimization**: Indexing and query optimization
- **Memory Management**: Efficient caching and resource cleanup
- **State Management**: Consider Provider or Riverpod for complex state
- **Architecture**: Move to clean architecture with proper separation of concerns

## **Development History**

### **v12.3 Complete Knowledge Base** 🚀

#### **1. Code Quality & Best Practices**
- ✅ **Debug Print Cleanup** - Removed all debug prints, replaced with AppLogger
- ✅ **Warning Resolution** - Fixed unused imports and variables
- ✅ **Error Handling** - Consistent AppLogger.error() throughout codebase
- ✅ **Code Organization** - Clean imports, proper separation of concerns
- ✅ **Performance Optimization** - Eliminated excessive database calls

#### **2. User Experience Enhancements**
- ✅ **Responsive Design** - Dynamic text sizing and overflow handling
- ✅ **Gesture Optimization** - Smooth swipe gestures with proper blocking
- ✅ **State Persistence** - Review mode and incorrect cards persist across sessions
- ✅ **Visual Feedback** - Immediate UI updates for all user actions
- ✅ **Error Recovery** - Graceful handling of database and network errors

## **Key Methods & Interactions**

### **Critical Method Flow**

#### **Swipe Gesture Flow**
```dart
_onPanEnd() → _completeSwipeAction() → _handleSwipeGesture() → _recordAnswer() → _advanceToNextCard()
```

#### **Review System Flow**
```dart
_leftSwipe() → markCardIncorrectInDatabase() → _showReviewPrompt() → _startIncorrectCardsReview() → _exitReviewMode()
```

#### **Favorites System Flow**
```dart
_toggleFavorite() → toggleFavorite() → _refreshCurrentCards() → _loadCategories()
```

#### **Database Initialization Flow**
```dart
DatabaseService() → database getter → _initDatabase() → _getDatabasePath() → _createIncorrectCardsTable()
```

### **State Management Patterns**

#### **Home Screen State Updates**
- **Card Loading**: `_loadCardsForCategory()` → `setState()` → UI rebuild
- **Swipe Actions**: `_completeSwipeAction()` → `_recordAnswer()` → `setState()` → UI update
- **Review Mode**: `_startIncorrectCardsReview()` → `setState()` → UI transition
- **Favorites**: `_toggleFavorite()` → `_refreshCurrentCards()` → `setState()` → UI refresh

#### **Navigation Drawer State Updates**
- **Category Loading**: `_loadCategories()` → `setState()` → Treeview update
- **Cache Management**: `_staticCategories` → 5-minute timeout → Refresh
- **Global Loading**: `_isLoadingGlobally` → Prevents concurrent operations

### **Performance Critical Methods**

#### **Database Operations**
- **`getDeckTree()`**: Called frequently, uses caching
- **`getCardsByCategory()`**: Core method, optimized with connection pooling
- **`markCardIncorrectInDatabase()`**: Critical for review system
- **`getIncorrectCardsFromDatabase()`**: Used for review prompts

#### **UI Operations**
- **`_completeSwipeAction()`**: Must be fast, uses animation blocking
- **`_loadCategories()`**: Debounced to prevent excessive calls
- **`_refreshCurrentCards()`**: Optimized to prevent unnecessary database calls

### **Error Handling Patterns**

#### **Database Errors**
- **Connection Issues**: `AppLogger.error()` → Graceful degradation
- **Query Failures**: Try-catch blocks → Return empty results
- **Transaction Errors**: Rollback → User notification

#### **UI Errors**
- **Animation Issues**: `_isAnimationBlocked` → Prevent multiple gestures
- **State Inconsistency**: `setState()` → Force UI rebuild
- **Memory Issues**: Proper disposal → Resource cleanup

### **Integration Points**

#### **Home Screen ↔ Database Service**
- **Card Loading**: `getCardsByCategory()` → `_currentCards`
- **Favorites**: `toggleFavorite()` → `_refreshCurrentCards()`
- **Review System**: `markCardIncorrectInDatabase()` → Review prompts

#### **Navigation Drawer ↔ Database Service**
- **Deck Tree**: `getDeckTree()` → `_categories`
- **Card Counts**: `getCategoryTree()` → Card count updates
- **Favorites**: `getFavoriteCards()` → Favorites deck

#### **Review System ↔ Database Service**
- **Incorrect Tracking**: `IncorrectCards` table → Review mode
- **Card Removal**: `markCardCorrectInDatabase()` → Review updates
- **Persistence**: Database storage → Cross-session persistence

### **v12.2 Review System Optimization** 🚀

#### **1. Incorrect Cards Tracking System**
- ✅ **Database Schema** - New `IncorrectCards` table with `id`, `card_id`, `deck_id`, `created_at`
- ✅ **Persistent Storage** - Cards marked incorrect are stored in database, not memory
- ✅ **Per-Deck Tracking** - Each deck maintains its own incorrect cards collection
- ✅ **Foreign Key Constraints** - Proper cascade deletion when cards/decks are removed
- ✅ **Database Service Methods** - `markCardIncorrectInDatabase()`, `markCardCorrectInDatabase()`, `getIncorrectCardsFromDatabase()`

#### **2. Review Mode Implementation**
- ✅ **Manual Exit Only** - Review mode persists until user manually exits with back button
- ✅ **Independent Scoring** - Review mode has separate score tracking from main deck
- ✅ **Card Removal Logic** - Correctly answered cards are immediately removed from review
- ✅ **UI State Management** - Review mode properly resets progress counters and card index
- ✅ **Error Handling** - Graceful error handling with user-friendly messages

#### **3. User Experience Flow**
- ✅ **Immediate Feedback** - Review prompt appears immediately after incorrect swipe
- ✅ **Persistent Prompts** - Review prompts remain visible until user manually exits
- ✅ **Cross-Deck Persistence** - Incorrect cards persist when switching between decks
- ✅ **Manual Control** - Users can review cards multiple times until satisfied
- ✅ **Progress Tracking** - Independent progress tracking for review sessions

#### **4. Code Optimization**
- ✅ **Debug Print Cleanup** - Removed excessive debug logging for cleaner console output
- ✅ **Database Call Optimization** - Reduced redundant database queries
- ✅ **Error Message Standardization** - Consistent error handling across all methods
- ✅ **Method Simplification** - Streamlined review logic for better maintainability

#### **5. Review System Logic Flow**
```
1. User swipes left (incorrect) on a card
   ↓
2. Card is marked as incorrect in IncorrectCards table
   ↓
3. Review prompt appears immediately showing count
   ↓
4. User taps "Review" button
   ↓
5. Review mode activates with incorrect cards only
   ↓
6. User studies cards in review mode
   ↓
7. When user swipes right (correct) in review mode:
   - Card is removed from IncorrectCards table
   - Card is removed from current review session
   - Progress is tracked independently
   ↓
8. User manually exits review mode with back button
   ↓
9. Returns to main deck with updated incorrect card count
```

#### **6. Database Schema for Review System**
```sql
CREATE TABLE IncorrectCards (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  card_id INTEGER NOT NULL,
  deck_id INTEGER NOT NULL,
  created_at TEXT NOT NULL,
  FOREIGN KEY (card_id) REFERENCES Card(id) ON DELETE CASCADE,
  FOREIGN KEY (deck_id) REFERENCES Deck(id) ON DELETE CASCADE
);
```

#### **7. Key Methods and Their Functions**
- **`markCardIncorrectInDatabase(cardId, deckId)`** - Adds card to IncorrectCards table
- **`markCardCorrectInDatabase(cardId)`** - Removes card from IncorrectCards table
- **`getIncorrectCardsFromDatabase(deckId)`** - Retrieves incorrect card IDs for a deck
- **`_startIncorrectCardsReview()`** - Loads incorrect cards and enters review mode
- **`_checkForRemainingIncorrectCards()`** - Checks if review should continue
- **`_exitReviewMode()`** - Manually exits review mode and returns to main deck

#### **8. User Experience Requirements**
- **Immediate Feedback** - Review prompt must appear instantly after incorrect swipe
- **Persistent State** - Review prompts must remain visible until user manually exits
- **Cross-Deck Persistence** - Incorrect cards must persist when switching between decks
- **Manual Control** - Users must be able to review cards multiple times until satisfied
- **Independent Scoring** - Review mode must have separate progress tracking from main deck
- **Database Persistence** - Incorrect cards must be stored in database, not memory
- **Error Handling** - System must gracefully handle database errors and edge cases
- **Performance** - System must not block UI during database operations
- **Consistency** - Review mode behavior must be consistent across all decks

### **v11.0 Major Features Implemented** 🎨

#### **1. Comprehensive Theme System Overhaul**
- ✅ **Material Design 3 Integration** - Complete migration to Material Design 3
- ✅ **Dynamic Theme Extension** - Custom `AppThemeExtension` with 20+ theme properties
- ✅ **Light/Dark Mode Support** - Seamless theme switching with persistent preferences
- ✅ **Consistent Color System** - Centralized color management across all components
- ✅ **Theme-Aware Components** - All widgets now properly respect theme settings
- ✅ **Navigation Drawer Redesign** - Flat design with proper Material Design patterns

#### **2. Favorites System Implementation (v11.0)**
- ✅ **Database Schema** - Added `is_favorite` column to Card table
- ✅ **Favorites Collection** - Special category under Japanese for favorite cards
- ✅ **Star Icon Integration** - Visual favorite toggle on card back with yellow star
- ✅ **Database Service Methods** - `toggleFavorite()`, `getFavoriteCards()`, `getFavoriteCardsCount()`
- ✅ **Navigation Integration** - Favorites appears as first child under Japanese
- ✅ **Special ID Handling** - Category ID -1 triggers favorites loading logic

#### **3. Enhanced Navigation System**
- ✅ **Bottom Navigation Bar** - Custom implementation with Home and Library screens
- ✅ **Library Screen** - Browse categories, view cards, edit/delete functionality
- ✅ **Navigation Drawer Persistence** - Properly closes when switching screens
- ✅ **Category Tree View** - Hierarchical category display with proper nesting
- ✅ **Favorites Integration** - Star icon and special handling in navigation

#### **4. Advanced Card Features**
- ✅ **Notes System** - Free text notes with icon display on card back
- ✅ **Edit Card Dialog** - Comprehensive editing with theme-aware styling
- ✅ **Favorite Toggle** - Star icon for adding/removing favorites
- ✅ **Card Swipe Improvements** - Proper z-index and animation handling
- ✅ **Action Button Redesign** - Removed circles, positioned above navigation

### **v12.0 Major Database Migration & Enhancements** 🗄️

#### **1. Database Schema Migration**
- ✅ **Normalized Schema** - Migrated from flat structure to normalized design
- ✅ **Deck/Card/CardField Structure** - Industry-standard design matching Anki/Quizlet patterns
- ✅ **DeckMembership Table** - Many-to-many relationships for favorites and custom decks
- ✅ **UserProgress Table** - SRS tracking with comprehensive progress data
- ✅ **Single Database Implementation** - Consolidated to single master database

#### **2. Enhanced Favorites System**
- ✅ **DeckMembership Integration** - Many-to-many relationship between cards and decks
- ✅ **Favorites Deck** - Special deck under Japanese with `sort_order = -9999` to appear first
- ✅ **No Data Duplication** - Cards stored once, linked to multiple decks via join table
- ✅ **Scalable Architecture** - Supports user-created custom decks and complex hierarchies

#### **3. Spaced Repetition System (SRS)**
- ✅ **SuperMemo 2 Algorithm** - Advanced SRS system with UserProgress tracking
- ✅ **Quality Scale Integration** - 0-5 scale based on swipe gestures
- ✅ **Progress Tracking** - Comprehensive learning progress and mastery tracking
- ✅ **Review Scheduling** - Cards scheduled for review based on SRS algorithm

#### **4. Card Display Settings**
- ✅ **Front/Back Customization** - User can choose what appears on front and back
- ✅ **Field Visibility** - Show/hide individual fields for customized study experience
- ✅ **Study Modes** - Recognition mode, Production mode, Mixed mode
- ✅ **Personalization** - Adapts to individual learning patterns and preferences

### **v12.1 Incorrect Cards Tracking System** ❌📚

#### **1. Per-Deck Incorrect Cards Collection**
- ✅ **In-Memory Tracking** - `Map<int, Set<int>> _incorrectCardsByDeck` tracks incorrect card IDs per deck
- ✅ **Deck-Specific Collections** - Each deck maintains independent incorrect cards collection
- ✅ **Session Persistence** - Collections persist during app session until cards are answered correctly
- ✅ **Immediate Feedback** - Review prompt appears instantly after left swipe

#### **2. Smart Review System**
- ✅ **Instant Review Prompt** - Shows "X card(s) wrong" immediately after marking cards incorrect
- ✅ **Deck Navigation Persistence** - Review prompt appears when returning to decks with incorrect cards
- ✅ **Review Mode Integration** - Only incorrect cards are shown during review sessions
- ✅ **Auto-Exit Logic** - Review mode exits when all incorrect cards are answered correctly

#### **3. User Experience Enhancements**
- ✅ **Immediate Visual Feedback** - No database queries needed for prompt display
- ✅ **Cross-Deck Tracking** - Each deck remembers its incorrect cards independently
- ✅ **Progress Tracking** - Cards are removed from collection when answered correctly in review
- ✅ **Seamless Integration** - Works with existing SRS system and swipe gestures

#### **4. Technical Implementation**
- ✅ **Helper Methods** - `_hasIncorrectCardsForCurrentDeck()`, `_getIncorrectCardsCountForCurrentDeck()`
- ✅ **State Management** - `_showReviewPrompt` for immediate display, `_incorrectCardsByDeck` for persistence
- ✅ **Performance Optimization** - Lightweight in-memory tracking, no database queries for UI
- ✅ **Error Handling** - Graceful fallbacks for invalid card IDs or empty collections

### **Recent Development Work (v12.1 - Current Session)** 🔧

#### **UI/UX Improvements Completed** ✅
1. **Card Size Consistency**: Fixed inconsistent card sizing between placeholder, main, and loading states
   - All cards now use `MediaQuery.of(context).size.height * 0.3` for consistent sizing
   - Eliminated card size switching when loading decks

2. **Responsive Text System**: Implemented dynamic text sizing with overflow handling
   - `_buildResponsiveText()` method handles text overflow with `maxLines`, `TextOverflow.ellipsis`, and `softWrap`
   - Text automatically adjusts size based on content length
   - Prevents text overflow issues on cards

3. **Bottom Navigation Bar Optimization**: Streamlined navigation interface
   - Removed text labels ("Home" and "Library"), keeping only icons
   - Increased icon size to 28 for better visibility
   - Reduced total height to 60.0 for more compact design

4. **Favorites Icon Positioning**: Fixed star icon placement and visibility
   - Moved favorites star to top center of card (`top: 8, left: 0, right: 0`)
   - Added white background with `BoxDecoration` for better visibility
   - Set icon size to 20 for optimal appearance

5. **Theme Consistency Review**: Comprehensive theme alignment
   - Changed deck completion color from teal to gold (`Colors.amber`)
   - Updated progress bar colors to match app theme
   - Fixed hardcoded colors in `background_photo_settings_traditional.dart`
   - Ensured all UI elements follow application theme

#### **Performance Optimizations Implemented** ⚡
1. **Swipe Operation Flag System**: Prevented database calls during swipe gestures
   - Static flag `_isSwipeOperation` blocks database calls during active swipes
   - Set to `true` at start of swipe, `false` after animation completes
   - Eliminates UI freezing during swipe operations

2. **Navigation Drawer Caching**: Implemented aggressive caching system
   - Static caching with `_staticCategories` and `_staticLastLoadTime`
   - 5-second interval checks before fetching from database
   - Global loading flag prevents simultaneous database operations
   - Disabled `onDrawerOpened()` to prevent excessive database calls

3. **Card Count Display Fix**: Corrected progress bar accuracy
   - Used `math.min()` to prevent displaying counts beyond total cards
   - Fixed "6 of 5" display issues
   - Ensured progress bar shows accurate card counts

#### **Bug Fixes Resolved** 🐛
1. **Swipe Up Freezing Issue**: Fixed screen freezing on swipe up gestures
   - Root cause: Inconsistent animation handling between swipe right and swipe up
   - Solution: Made swipe up use same animation system as swipe right
   - Result: Consistent deck completion display across all swipe directions

2. **Card Editing Issues**: Resolved multiple editing problems
   - Fixed type conversion errors in `CardField.fromMap` and `Card.fromMap`
   - Corrected `_refreshCurrentCards()` to handle Favorites deck properly
   - Ensured cards can be edited multiple times without issues

3. **Favorites System Issues**: Fixed star button and count updates
   - Corrected `getCardById` query to use `parent_id IS NULL` instead of `language = 'Japanese'`
   - Implemented proper database refresh after favorite actions
   - Fixed Favorites deck count updates in navigation drawer

4. **Compilation Errors**: Resolved all build issues
   - Fixed import conflicts between Flutter's `Category` and custom `Category` model
   - Added missing imports and method definitions
   - Corrected type mismatches in SRS algorithm implementation

## **Database Schema (v12.0 - Current)**

### **Core Tables**
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

### **Schema Design Principles**
- **No Data Duplication**: Cards stored once, linked to multiple decks via DeckMembership
- **Favorites as Real Deck**: Favorites is a proper deck with `sort_order = -9999` to appear first
- **Many-to-Many Relationships**: Cards can belong to multiple decks without copying data
- **Scalable Architecture**: Supports user-created custom decks and complex hierarchies
- **Industry Best Practice**: Matches Anki, Quizlet, Memrise design patterns

## **Key Components**

### **1. Favorites System** ⭐
- **DeckMembership Table**: Many-to-many relationship between cards and decks
- **Favorites Deck**: Special deck under Japanese with `sort_order = -9999` to appear first
- **No Data Duplication**: Cards stored once, linked to multiple decks via join table
- **Star Icon**: Visual favorite toggle on card back with yellow color when favorited
- **Database Methods**: `toggleFavorite()`, `getFavoriteCards()`, `getFavoriteCardsCount()` using DeckMembership

### **2. Theme System** 🎨
- **AppThemeExtension**: 20+ theme properties for comprehensive theming
- **Material Design 3**: Complete migration from custom theme system
- **Light/Dark Modes**: Seamless switching with persistent preferences
- **Theme Properties**: Colors, backgrounds, text, buttons, shadows, etc.

### **3. Navigation System** 🧭
- **Bottom Navigation**: Custom implementation with sharp corners
- **Library Screen**: Browse categories, view cards, edit/delete functionality
- **Navigation Drawer**: Category tree with favorites integration
- **Screen Management**: IndexedStack with proper state management

### **4. Card Features** 🃏
- **Swipe Actions**: Left (incorrect), Right (correct), Up (skip), Down (go back)
- **Notes System**: Free text notes with icon display
- **Edit Dialog**: Theme-aware editing with proper styling
- **Star Icon**: Favorite toggle with visual feedback

### **Card Interaction System** 🎯

#### **Card Interaction Analysis**

**1. Card Flip Interaction**
- **Trigger**: Tap anywhere on the card
- **Behavior**: Toggles between front and back of the card
- **Implementation**: `widget.onTap()` in `FlashcardWidget`
- **Gesture**: `GestureDetector` with `HitTestBehavior.deferToChild`

**2. Edit Button Interaction**
- **Trigger**: Tap the edit icon (pencil) on the back of the card
- **Visibility**: Only shows when `widget.showAnswer` is true (card is flipped)
- **Behavior**: Opens `QuickEditCardDialog` for editing card fields
- **Implementation**: `widget.onEdit?.call()` in `FlashcardWidget`
- **Position**: Top-left corner of the card

**3. Favorite Star Button Interaction**
- **Trigger**: Tap the star icon on the back of the card
- **Visibility**: Only shows when `widget.showAnswer` is true AND `widget.onToggleFavorite` is not null
- **Behavior**: Toggles favorite status (adds/removes from Favorites deck)
- **Visual State**: 
  - Filled gold star when favorited (`Icons.star`)
  - Empty star when not favorited (`Icons.star_border`)
- **Implementation**: `widget.onToggleFavorite?.call()` in `FlashcardWidget`
- **Position**: Centered at the top of the card

**4. Notes Icon Interaction**
- **Trigger**: Tap the notes icon on the back of the card
- **Visibility**: Only shows when:
  - `widget.showAnswer` is true (card is flipped)
  - Card has notes (`widget.flashcard.notes != null && widget.flashcard.notes!.isNotEmpty`)
  - Not currently showing notes (`!_showNotes`)
- **Behavior**: Toggles between showing notes content and hiding it
- **Implementation**: Sets `_showNotes = true` in `FlashcardWidget`
- **Position**: Top-right corner of the card

**5. Notes Content Display**
- **Trigger**: When notes icon is tapped
- **Behavior**: Shows notes content in place of card content
- **Exit**: Tap anywhere on the card to return to normal view
- **Implementation**: `_showNotes` state variable in `FlashcardWidget`

### **Swipe Gesture System** 👆
- **Left Swipe**: Incorrect (quality 0-2) - updates SRS, decreases correct %
- **Right Swipe**: Correct (quality 3-5) - updates SRS, increases correct %
- **Up Swipe**: Skip - no quality change, moves to next card
- **Down Swipe**: Go back one card - returns to previous card
- **Visual Feedback**: Correct percentage updates in real-time
- **SRS Integration**: Swipe quality feeds into spaced repetition algorithm

### **Incorrect Cards Tracking System** ❌📚

#### **Per-Deck Incorrect Cards Collection**
- **Data Structure**: `Map<int, Set<int>> _incorrectCardsByDeck` - tracks incorrect card IDs per deck
- **Scope**: Each deck maintains its own collection of incorrect cards
- **Persistence**: In-memory tracking during app session (resets on app restart)
- **Purpose**: Immediate feedback and review functionality for incorrectly answered cards

#### **Left Swipe Behavior (Mark as Incorrect)**
- **Trigger**: User swipes left on any card
- **Action**: Card ID is added to the incorrect collection for the current deck
- **Code**: `_incorrectCardsByDeck.putIfAbsent(_currentCategoryId, () => <int>{}); _incorrectCardsByDeck[_currentCategoryId]!.add(currentCard.id);`
- **Immediate Feedback**: Review prompt appears instantly below the main card
- **Database Integration**: Still calls `markCardIncorrect()` for SRS tracking

#### **Review Cards Prompt Display**
- **Visibility Logic**: Shows when `(_showReviewPrompt || _hasIncorrectCardsForCurrentDeck()) && !_isReviewMode`
- **Text Display**: "X card(s) wrong" with actual count from `_getIncorrectCardsCountForCurrentDeck()`
- **Position**: Below main card area, above spaced repetition section
- **Styling**: Consistent with app theme, rounded container with error icon

#### **Review Mode Functionality**
- **Trigger**: User clicks "Review" button in the prompt
- **Card Loading**: Only loads cards that are in the incorrect collection for current deck
- **Implementation**: `_startIncorrectCardsReview()` filters all deck cards by incorrect card IDs
- **Exit Condition**: When all incorrect cards are answered correctly, review mode automatically exits

#### **Correct Answer Handling in Review Mode**
- **Trigger**: User answers correctly (swipe right) while in review mode
- **Action**: Card is removed from the incorrect collection for that deck
- **Code**: `_incorrectCardsByDeck[_currentCategoryId]?.remove(currentCard.id);`
- **Auto-Exit**: If no more incorrect cards remain, review mode exits automatically
- **State Update**: `_isReviewMode = false; _showReviewPrompt = false;`

#### **Deck Navigation Persistence**
- **Entering Deck**: When loading a deck, checks if it has incorrect cards using `_hasIncorrectCardsForCurrentDeck()`
- **Prompt Display**: If incorrect cards exist, review prompt appears automatically
- **Cross-Deck Tracking**: Each deck maintains its own incorrect cards collection independently
- **Memory Management**: Collections persist until cards are answered correctly or app restarts

#### **Helper Methods**
- **`_hasIncorrectCardsForCurrentDeck()`**: Checks if current deck has any incorrect cards
- **`_getIncorrectCardsCountForCurrentDeck()`**: Returns count of incorrect cards for current deck
- **`_startIncorrectCardsReview()`**: Loads and displays only incorrect cards for review
- **Collection Management**: Automatic cleanup when cards are answered correctly

#### **User Experience Flow**
1. **Study Phase**: User studies cards normally, swiping left on difficult cards
2. **Immediate Feedback**: Review prompt appears instantly after each left swipe
3. **Deck Persistence**: Leaving and returning to a deck shows prompt if incorrect cards remain
4. **Review Phase**: User clicks "Review" to study only the cards they got wrong
5. **Progress Tracking**: As cards are answered correctly in review, they're removed from collection
6. **Completion**: When all incorrect cards are mastered, review mode exits automatically

#### **Technical Implementation Details**
- **State Variables**: `_showReviewPrompt` (immediate display), `_incorrectCardsByDeck` (persistent tracking)
- **UI Integration**: Conditional rendering based on collection state and review mode
- **Performance**: Lightweight in-memory tracking, no database queries for prompt display
- **Error Handling**: Graceful fallbacks if card IDs are invalid or collections are empty

#### **Swipe Operation Flag System** 🚦
**Purpose**: Prevents database calls during active swipe gestures to avoid UI freezing and performance issues.

**Implementation**:
- **Static Flag**: `_isSwipeOperation` in `KaadoNavigationDrawer` class
- **Set Flag**: `KaadoNavigationDrawer.setSwipeOperation(true)` at start of swipe
- **Clear Flag**: `KaadoNavigationDrawer.setSwipeOperation(false)` after animation completes
- **Database Protection**: `_loadCategories()` checks flag and returns early if swipe in progress

**Code Flow**:
```dart
// In _completeSwipeAction()
KaadoNavigationDrawer.setSwipeOperation(true);  // Block database calls

// After animation completes in _animateCardExit()
KaadoNavigationDrawer.setSwipeOperation(false); // Allow database calls

// In _loadCategories() - navigation_drawer.dart
if (_isSwipeOperation) {
  print('DEBUG: _loadCategories - Swipe operation in progress, skipping');
  return; // Prevent database calls during swipe
}
```

**Deck Completion Handling**:
- **Swipe Right**: Goes through `_animateCardExit(true)` → Animation → Deck completion card appears after animation
- **Swipe Up**: Now uses `_animateCardExit(null)` → Animation → Deck completion card appears after animation (consistent with swipe right)
- **Consistent Experience**: Both swipe directions now show deck completion card after animation completes
- **No Freezing**: Swipe operation flag prevents database calls during deck completion display

**Performance Benefits**:
- Eliminates UI freezing during swipe gestures
- Prevents excessive database calls during animations
- Ensures smooth user experience during deck completion
- Maintains consistent deck completion display across all swipe directions

### **Background Photo System** 🖼️
- **Custom Backgrounds**: Users can set custom background photos for main card screen
- **Adaptive Text**: Text automatically gets background for visibility
- **Smart Contrast**: Dark backgrounds get light text backgrounds, light backgrounds get dark text backgrounds
- **Text Visibility**: All text and icons remain readable regardless of background

### **Card Display Settings** ⚙️
- **Front Card Options**: User can choose what appears on front (Kana, Hiragana, Kanji, Romaji)
- **Back Card Options**: User can choose what appears on back (English, Notes, Pronunciation)
- **Field Visibility**: Show/hide individual fields for customized study experience
- **Study Modes**: Recognition mode, Production mode, Mixed mode
- **Personalization**: Adapts to individual learning patterns and preferences

### **Navigation Drawer Logic** 🌳
- **Hierarchical Navigation**: Click on language deck (Japanese, Spanish, etc.) to see sub-decks
- **Deck Traversal**: Navigate through category levels and sub-decks
- **Card Count Indicators**: Decks with cards show count, clicking loads cards into main screen
- **Tree Structure**: Parent-child relationships with proper deck hierarchy
- **Favorites Integration**: Favorites deck appears at top with special sorting

### **Spaced Repetition System (SRS)** 🔄
- **Algorithm**: SuperMemo 2 (SM-2) algorithm for optimal learning intervals
- **Quality Scale**: 0-5 scale (0=blackout, 5=perfect) based on swipe gestures
- **Interval Calculation**: Dynamic intervals based on performance and ease factor
- **Review Scheduling**: Cards scheduled for review based on SRS algorithm
- **Progress Tracking**: UserProgress table tracks learning progress and mastery

### **Performance & Multithreading** ⚡
- **Compute Isolates**: Heavy database operations run in background isolates
- **Smart Caching**: 5-minute cache for frequently accessed data
- **Background Processing**: Non-blocking UI for database operations
- **Memory Management**: Efficient data structures and cleanup
- **Future Cloud Sync**: Designed for ElectricSQL integration with local-first architecture

## **Key Services**
- **DatabaseService**: Card management, favorites via DeckMembership, queries
- **ThemeService**: Material Design 3 theme management
- **AppLogger**: Centralized logging for debugging
- **SpacedRepetitionService**: SRS algorithm implementation
- **CardDisplayService**: Card display settings management

## **Current Development Status (v12.0 - Latest)** 📊
- **All Major Issues Resolved**: Swipe freezing, card editing, favorites system
- **Performance Optimized**: Caching, swipe operation flags, database optimization
- **UI/UX Enhanced**: Consistent sizing, responsive text, theme alignment
- **Code Quality Improved**: Clean imports, proper error handling, organized structure
- **User Experience Polished**: Smooth interactions, consistent design, intuitive navigation

## **Next Development Priorities** 🎯
1. **Background Photo System**: Implement adaptive text backgrounds for custom photos
2. **Performance Optimizations**: Add caching and multithreading for better performance
3. **Error Handling Enhancement**: Improve AppLogger and error handling throughout app
4. **Cloud Sync Preparation**: Prepare for ElectricSQL integration
5. **Advanced Features**: Analytics, social interactions, drawing practice, audio pronunciation

## **Development Environment & Setup** 🛠️

### **System Requirements**
- **Flutter Version**: Latest stable (3.x)
- **Dart Version**: Latest stable (3.x)
- **Target Platforms**: Android (primary), iOS (configured), Web (configured)
- **Database**: SQLite with asset-based database
- **Build System**: Gradle (Android), Xcode (iOS)

### **Key Dependencies**
```yaml
dependencies:
  flutter:
    sdk: flutter
  sqflite: ^2.3.0
  path: ^1.8.3
  shared_preferences: ^2.2.2
  firebase_core: ^2.24.2
  image_picker: ^1.0.4
  path_provider: ^2.1.1
```

### **Database Location**
- **Development**: `C:\Users\Clayt\Flutter_Apps\Kaado\kaadoapp_v12\database\japanese.db`
- **Production**: App documents directory with asset fallback
- **Backup**: Single master database, no duplication

## **Troubleshooting Guide** 🔧

### **Common Issues & Solutions**

#### **Build Errors**
- **Import Conflicts**: Use import aliases for Category model conflicts
- **Type Mismatches**: Ensure proper type conversion in CardField.fromMap
- **Missing Dependencies**: Run `flutter pub get` after adding new packages

#### **Database Issues**
- **Path Problems**: Check database path in DatabaseService._getDatabasePath()
- **Schema Mismatches**: Ensure database migration is complete
- **Favorites Not Working**: Verify DeckMembership table relationships

#### **Performance Issues**
- **UI Freezing**: Check swipe operation flag implementation
- **Slow Loading**: Verify caching system is working
- **Memory Issues**: Check for proper widget disposal

#### **Theme Issues**
- **Colors Not Updating**: Ensure AppThemeExtension is properly configured
- **Dark Mode Problems**: Check theme switching logic in ThemeService
- **Inconsistent Styling**: Verify all components use context.appTheme

### **Debug Commands**
```bash
# Clean and rebuild
flutter clean
flutter pub get
flutter run

# Check for issues
flutter analyze
flutter doctor

# Database debugging
# Check terminal logs for DEBUG: _getDatabasePath messages
```

## **Testing Strategy** 🧪

### **Manual Testing Checklist**
- [ ] Card swiping (all directions)
- [ ] Favorites toggle functionality
- [ ] Card editing and saving
- [ ] Theme switching (light/dark)
- [ ] Navigation between screens
- [ ] Database operations
- [ ] SRS algorithm calculations
- [ ] Performance under load

### **Key Test Scenarios**
1. **Swipe Operations**: Test all swipe directions for proper behavior
2. **Favorites System**: Add/remove favorites, verify database updates
3. **Card Editing**: Edit cards multiple times, verify persistence
4. **Theme Switching**: Switch themes, verify all components update
5. **Navigation**: Test all navigation paths and state management
6. **Database Operations**: Verify all database operations work correctly

## **Deployment Information** 🚀

### **Build Configuration**
- **Android**: Gradle build with proper signing configuration
- **iOS**: Xcode project with proper provisioning
- **Version**: v12.0 (Production Ready)
- **Database**: Single SQLite database with asset fallback

### **Release Notes (v12.0)**
- ✅ Complete database migration to normalized schema
- ✅ Advanced SRS system with UserProgress tracking
- ✅ Performance optimizations and caching
- ✅ UI/UX improvements and bug fixes
- ✅ Swipe operation flag system for smooth interactions
- ✅ Theme consistency and responsive design
- ✅ Comprehensive error handling and logging

## **Contributing Guidelines** 👥

### **Code Standards**
- Follow Flutter/Dart best practices
- Use proper error handling with AppLogger
- Maintain theme consistency with context.appTheme
- Write comprehensive comments for complex logic
- Test all changes thoroughly

### **File Organization**
- Keep related functionality in appropriate directories
- Use descriptive file and class names
- Maintain proper import organization
- Follow existing code patterns and architecture

### **Database Changes**
- Always test database migrations thoroughly
- Maintain backward compatibility when possible
- Update schema documentation
- Test with production data when possible

## **Key Files Structure (v12.0)**
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
│   ├── card_display_settings_screen.dart
│   ├── spaced_repetition_settings_screen.dart
│   └── main_navigation_screen.dart
├── services/
│   ├── database_service.dart (migrated to new schema)
│   ├── spaced_repetition_service.dart (UserProgress integration)
│   ├── card_display_service.dart
│   ├── app_logger.dart
│   └── theme_service.dart
├── utils/
│   └── app_theme.dart (Material Design 3)
└── widgets/
    ├── flashcard_widget.dart (DeckMembership favorites)
    ├── navigation_drawer.dart (deck treeview)
    └── category_management_dialogs.dart
```

## **Flutter/Dart Specifics**
- **Material Design 3**: Complete implementation with custom extensions
- **SQLite**: Local database with asset-based database
- **State Management**: StatefulWidget with setState for UI updates
- **Theme System**: Custom AppThemeExtension with 20+ properties
- **Navigation**: Bottom navigation with IndexedStack
- **Database**: SQLite with favorites and review tracking

## **Common Development Patterns**
- **Theme Access**: `context.appTheme` for theme properties
- **Database Operations**: Service-based with error handling
- **State Updates**: setState for UI refresh after database changes
- **Navigation**: IndexedStack for screen management
- **Favorites**: Special category ID (-1) for favorites collection

---

**Last Updated**: End of v12.0 development session
**Status**: Production ready with comprehensive features and optimizations
**Version**: v12.0
**Key Achievement**: Complete database migration, SRS system, and performance optimizations

This unified summary provides a complete overview of the Kaado app for asking ChatGPT questions about Flutter development, Material Design 3, database management, theme systems, or any other technical aspects of the project.
