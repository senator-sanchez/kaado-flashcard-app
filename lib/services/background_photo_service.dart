import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';
import '../utils/logger.dart';

/// Service for managing background photos
class BackgroundPhotoService extends ChangeNotifier {
  static BackgroundPhotoService? _instance;
  static BackgroundPhotoService get instance => _instance ??= BackgroundPhotoService._();
  BackgroundPhotoService._();

  final ImagePicker _imagePicker = ImagePicker();
  String? _backgroundPhotoPath;
  bool _isLoading = false;
  
  // Default background options - will be populated dynamically
  static List<String> _defaultBackgrounds = [];

  // Getters
  String? get backgroundPhotoPath => _backgroundPhotoPath;
  bool get isLoading => _isLoading;
  bool get hasBackgroundPhoto => _backgroundPhotoPath != null && _backgroundPhotoPath!.isNotEmpty;

  /// Initialize the service and load saved background photo
  Future<void> initialize() async {
    await _loadBackgroundPhotoPath();
    await _loadDefaultBackgrounds();
  }

  /// Load all available default backgrounds from assets/backgrounds/
  Future<void> _loadDefaultBackgrounds() async {
    try {
      // Use rootBundle to load the AssetManifest.json
      final manifestContent = await rootBundle.loadString('AssetManifest.json');
      final Map<String, dynamic> manifestMap = json.decode(manifestContent);
      
      // Filter assets that are in the backgrounds folder
      _defaultBackgrounds = manifestMap.keys
          .where((String key) => key.startsWith(AppConstants.backgroundsPath))
          .where((String key) => _isImageFile(key))
          .toList();
      
      // Sort alphabetically for consistent ordering
      _defaultBackgrounds.sort();
      
      AppLogger.info('Found ${_defaultBackgrounds.length} default backgrounds: $_defaultBackgrounds');
      notifyListeners();
    } catch (e) {
      AppLogger.error('Error loading default backgrounds', e);
      // Fallback to empty list if there's an error
      _defaultBackgrounds = [];
      notifyListeners();
    }
  }

  /// Check if a file is an image based on its extension
  bool _isImageFile(String path) {
    final extension = path.toLowerCase().split('.').last;
    return AppConstants.supportedImageExtensions.any((ext) => ext.substring(1) == extension);
  }

  /// Load background photo path from shared preferences
  Future<void> _loadBackgroundPhotoPath() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _backgroundPhotoPath = prefs.getString('background_photo_path');
      notifyListeners();
    } catch (e) {
      AppLogger.error('Error loading background photo path', e);
    }
  }

  /// Save background photo path to shared preferences
  Future<void> _saveBackgroundPhotoPath(String? path) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (path != null) {
        await prefs.setString('background_photo_path', path);
      } else {
        await prefs.remove('background_photo_path');
      }
    } catch (e) {
      AppLogger.error('Error saving background photo path', e);
    }
  }

  /// Pick a background photo from gallery
  Future<bool> pickBackgroundPhoto() async {
    if (_isLoading) return false;
    
    _setLoading(true);
    
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        // Copy the image to app directory
        final String savedPath = await _saveImageToAppDirectory(image.path);
        _backgroundPhotoPath = savedPath;
        await _saveBackgroundPhotoPath(savedPath);
        notifyListeners();
        return true;
      }
    } catch (e) {
      AppLogger.error('Error picking background photo', e);
    } finally {
      _setLoading(false);
    }
    
    return false;
  }


  /// Save image to app directory
  Future<String> _saveImageToAppDirectory(String imagePath) async {
    try {
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String backgroundDir = '${appDir.path}/backgrounds';
      
      // Create backgrounds directory if it doesn't exist
      final Directory backgroundDirectory = Directory(backgroundDir);
      if (!await backgroundDirectory.exists()) {
        await backgroundDirectory.create(recursive: true);
      }
      
      // Generate unique filename
      final String fileName = '${AppConstants.backgroundFileNamePrefix}${DateTime.now().millisecondsSinceEpoch}${AppConstants.backgroundFileExtension}';
      final String newPath = '$backgroundDir/$fileName';
      
      // Copy the image
      final File originalFile = File(imagePath);
      final File newFile = await originalFile.copy(newPath);
      
      return newFile.path;
    } catch (e) {
      AppLogger.error('Error saving image to app directory', e);
      rethrow;
    }
  }

  /// Remove current background photo
  Future<void> removeBackgroundPhoto() async {
    if (_backgroundPhotoPath != null) {
      try {
        // Delete the file
        final File file = File(_backgroundPhotoPath!);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        AppLogger.error('Error deleting background photo file', e);
      }
    }
    
    _backgroundPhotoPath = null;
    await _saveBackgroundPhotoPath(null);
    notifyListeners();
  }

  /// Reset to default background (no photo)
  Future<void> resetToDefault() async {
    await removeBackgroundPhoto();
  }

  /// Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Get background photo as File (for local display)
  File? get backgroundPhotoFile {
    if (_backgroundPhotoPath != null) {
      final File file = File(_backgroundPhotoPath!);
      return file.existsSync() ? file : null;
    }
    return null;
  }

  /// Get list of available default backgrounds
  List<String> get defaultBackgrounds => List.from(_defaultBackgrounds);

  /// Set a default background
  Future<void> setDefaultBackground(String assetPath) async {
    if (_defaultBackgrounds.contains(assetPath)) {
      _backgroundPhotoPath = assetPath;
      await _saveBackgroundPhotoPath(assetPath);
      notifyListeners();
    }
  }

  /// Check if current background is a default asset
  bool get isUsingDefaultBackground {
    return _backgroundPhotoPath != null && _defaultBackgrounds.contains(_backgroundPhotoPath);
  }

  /// Refresh the list of default backgrounds (call this after adding new images)
  Future<void> refreshDefaultBackgrounds() async {
    await _loadDefaultBackgrounds();
  }
}
