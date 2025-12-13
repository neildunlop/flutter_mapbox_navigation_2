/// Application Router
///
/// Centralized route configuration for the example app.
/// All screen routes are defined here for easy navigation.

import 'package:flutter/material.dart';
import 'constants.dart';
import '../screens/home_screen.dart';
import '../screens/basic_navigation/basic_navigation_screen.dart';
import '../screens/free_drive/free_drive_screen.dart';
import '../screens/multi_stop/multi_stop_screen.dart';
import '../screens/embedded_map/embedded_map_screen.dart';
import '../screens/static_markers/static_markers_screen.dart';
import '../screens/static_markers/marker_gallery_screen.dart';
import '../screens/marker_popups/marker_popups_screen.dart';
import '../screens/offline/offline_screen.dart';
import '../screens/trip_progress/trip_progress_screen.dart';
import '../screens/events_demo/events_demo_screen.dart';
import '../screens/validation/validation_screen.dart';
import '../screens/accessibility/accessibility_screen.dart';

class AppRouter {
  AppRouter._();

  /// Generate routes for the app
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.home:
        return _buildRoute(const HomeScreen());

      case AppRoutes.basicNavigation:
        return _buildRoute(const BasicNavigationScreen());

      case AppRoutes.freeDrive:
        return _buildRoute(const FreeDriveScreen());

      case AppRoutes.multiStop:
        return _buildRoute(const MultiStopScreen());

      case AppRoutes.embeddedMap:
        return _buildRoute(const EmbeddedMapScreen());

      case AppRoutes.staticMarkers:
        return _buildRoute(const StaticMarkersScreen());

      case AppRoutes.markerGallery:
        return _buildRoute(const MarkerGalleryScreen());

      case AppRoutes.markerPopups:
        return _buildRoute(const MarkerPopupsScreen());

      case AppRoutes.offline:
        return _buildRoute(const OfflineScreen());

      case AppRoutes.tripProgress:
        return _buildRoute(const TripProgressScreen());

      case AppRoutes.eventsDemo:
        return _buildRoute(const EventsDemoScreen());

      case AppRoutes.validation:
        return _buildRoute(const ValidationScreen());

      case AppRoutes.accessibility:
        return _buildRoute(const AccessibilityScreen());

      default:
        return _buildRoute(
          Scaffold(
            appBar: AppBar(title: const Text('Not Found')),
            body: Center(
              child: Text('Route ${settings.name} not found'),
            ),
          ),
        );
    }
  }

  /// Build a material page route
  static MaterialPageRoute<dynamic> _buildRoute(Widget page) {
    return MaterialPageRoute(builder: (_) => page);
  }
}
