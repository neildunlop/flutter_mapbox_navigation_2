/// Flutter Mapbox Navigation - Example App
///
/// This example app demonstrates all major features of the flutter_mapbox_navigation
/// plugin. Each screen showcases a specific feature with easy-to-understand,
/// copyable code examples.
///
/// Features demonstrated:
/// - Turn-by-turn navigation
/// - Free drive mode
/// - Multi-stop navigation with silent waypoints
/// - Embedded navigation views
/// - Static markers with clustering
/// - Custom marker popups
/// - Trip progress panel customization
/// - Event system and logging
/// - Offline navigation
/// - Waypoint validation
/// - Accessibility support

import 'package:flutter/material.dart';
import 'core/app_theme.dart';
import 'core/app_router.dart';
import 'core/constants.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MapboxNavigationExampleApp());
}

class MapboxNavigationExampleApp extends StatelessWidget {
  const MapboxNavigationExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mapbox Navigation Demo',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: AppRoutes.home,
      onGenerateRoute: AppRouter.generateRoute,
    );
  }
}
