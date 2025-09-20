import 'package:get_it/get_it.dart';
import 'database_service.dart';
import 'card_display_service.dart';
import 'theme_service.dart';

/// Service Locator for dependency injection
/// This follows the Service Locator pattern for managing dependencies
final GetIt serviceLocator = GetIt.instance;

/// Initialize all services
Future<void> initializeServices() async {
  // Register services as singletons
  serviceLocator.registerLazySingleton<DatabaseService>(
    () => DatabaseService(),
  );
  
  serviceLocator.registerLazySingleton<CardDisplayService>(
    () => CardDisplayService.instance,
  );
  
  serviceLocator.registerLazySingleton<ThemeService>(
    () => ThemeService(),
  );
}

/// Get service instances
DatabaseService get databaseService => serviceLocator<DatabaseService>();
CardDisplayService get cardDisplayService => serviceLocator<CardDisplayService>();
ThemeService get themeService => serviceLocator<ThemeService>();
