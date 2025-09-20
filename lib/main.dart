// Dart imports

// Flutter imports
import 'package:flutter/material.dart';

// Package imports
import 'package:firebase_core/firebase_core.dart';

// Project imports
import 'constants/app_strings.dart';
import 'firebase_options.dart';
import 'screens/main_navigation_screen.dart';
import 'services/background_photo_service.dart';
import 'services/theme_service.dart';

/// Main entry point for the Kaado Japanese Language Learning App
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase with error handling
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    // Firebase initialized successfully
  } catch (e) {
    // Firebase initialization failed, continuing with local database
    // Continue without Firebase - the app should still work for local database
  }
  
  // Initialize background photo service
  await BackgroundPhotoService.instance.initialize();
  
  // Initialize theme service to ensure theme is loaded before app starts
  await ThemeService().initialize();
  
  runApp(const KaadoApp());
}

/// Root application widget
class KaadoApp extends StatelessWidget {
  const KaadoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeService(),
      builder: (context, child) {
        return MaterialApp(
          title: AppStrings.appName,
          theme: ThemeService().themeData,
          home: const MainNavigationScreen(),
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}
