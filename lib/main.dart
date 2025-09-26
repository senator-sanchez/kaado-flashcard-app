// Dart imports

// Flutter imports
import 'package:flutter/material.dart';

// Package imports
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Project imports
import 'constants/app_strings.dart';
import 'firebase_options.dart';
import 'screens/main_navigation_screen.dart';
import 'services/theme_service.dart';
import 'services/performance_optimization_service.dart';
import 'services/async_database_service.dart';
import 'services/isolate_service.dart';
import 'services/ui_thread_service.dart';

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
  
  // Initialize optimized services for better performance
  await _initializeOptimizedServices();
  
  runApp(
    const ProviderScope(
      child: KaadoApp(),
    ),
  );
}

/// Initialize optimized services for better performance
Future<void> _initializeOptimizedServices() async {
  try {
    // Initialize theme service
    await ThemeService().initialize();
    
    // Initialize comprehensive performance optimization service
    final performanceOptimization = PerformanceOptimizationService();
    await performanceOptimization.initialize();
    
    // Initialize async database service
    final asyncDatabaseService = AsyncDatabaseService();
    await asyncDatabaseService.initialize();
    
    // Initialize UI thread service
    final uiThreadService = UIThreadService();
    uiThreadService.initialize();
    
    // Initialize isolate service for background processing
    final isolateService = IsolateService();
    await isolateService.initialize();
    
  } catch (e) {
    // Continue with fallback initialization
    await ThemeService().initialize();
  }
}

/// Root application widget
class KaadoApp extends ConsumerWidget {
  const KaadoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
