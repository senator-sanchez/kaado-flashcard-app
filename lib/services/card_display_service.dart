import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/card_display_settings.dart';

/// Service to manage card display settings
class CardDisplayService {
  static const String _settingsKey = 'card_display_settings';
  static CardDisplayService? _instance;
  
  static CardDisplayService get instance => _instance ??= CardDisplayService._();
  CardDisplayService._();

  CardDisplaySettings _currentSettings = CardDisplaySettings.defaultSettings;

  /// Get current display settings
  CardDisplaySettings get currentSettings => _currentSettings;

  /// Load settings from shared preferences
  Future<void> loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = prefs.getString(_settingsKey);
      
      if (settingsJson != null) {
        final settingsMap = jsonDecode(settingsJson) as Map<String, dynamic>;
        _currentSettings = CardDisplaySettings.fromJson(settingsMap);
      }
    } catch (e) {
      // If loading fails, use default settings
      _currentSettings = CardDisplaySettings.defaultSettings;
    }
  }

  /// Save settings to shared preferences
  Future<void> saveSettings(CardDisplaySettings settings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = jsonEncode(settings.toJson());
      await prefs.setString(_settingsKey, settingsJson);
      _currentSettings = settings;
    } catch (e) {
      // Handle error silently or log it
      // Failed to save card display settings
    }
  }

  /// Update front display type
  Future<void> updateFrontDisplay(CardDisplayType frontDisplay) async {
    // Remove the front display from back displays if it's there
    final newBackDisplays = Set<CardDisplayType>.from(_currentSettings.backDisplays);
    newBackDisplays.remove(frontDisplay);
    
    // If no back displays left, add all others except the front
    if (newBackDisplays.isEmpty) {
      newBackDisplays.addAll(CardDisplayType.values.where((type) => type != frontDisplay));
    }

    final newSettings = _currentSettings.copyWith(
      frontDisplay: frontDisplay,
      backDisplays: newBackDisplays.toList(),
    );
    
    await saveSettings(newSettings);
  }

  /// Update back display types
  Future<void> updateBackDisplays(Set<CardDisplayType> backDisplays) async {
    // Ensure front display is not in back displays
    final filteredBackDisplays = backDisplays.where(
      (type) => type != _currentSettings.frontDisplay,
    ).toSet();

    final newSettings = _currentSettings.copyWith(
      backDisplays: filteredBackDisplays.toList(),
    );
    
    await saveSettings(newSettings);
  }

  /// Toggle a back display type
  Future<void> toggleBackDisplay(CardDisplayType displayType) async {
    if (displayType == _currentSettings.frontDisplay) return;

    final newBackDisplays = Set<CardDisplayType>.from(_currentSettings.backDisplays);
    
    if (newBackDisplays.contains(displayType)) {
      newBackDisplays.remove(displayType);
    } else {
      newBackDisplays.add(displayType);
    }

    await updateBackDisplays(newBackDisplays);
  }

  /// Update settings (for Riverpod integration)
  Future<void> updateSettings(CardDisplaySettings settings) async {
    await saveSettings(settings);
  }
}
