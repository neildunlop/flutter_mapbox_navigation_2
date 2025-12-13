/// Application Constants
///
/// Central location for all app-wide constants including default coordinates,
/// configuration values, and route names.

import 'package:flutter/material.dart';

/// Default map coordinates for testing
class MapDefaults {
  MapDefaults._();

  // San Francisco Bay Area (default location)
  static const double defaultLatitude = 37.7749;
  static const double defaultLongitude = -122.4194;
  static const double defaultZoom = 13.0;
  static const double defaultBearing = 0.0;
  static const double defaultTilt = 0.0;

  // Map bounds for offline download testing
  static const double sfBayAreaSouthWestLat = 37.0;
  static const double sfBayAreaSouthWestLng = -122.5;
  static const double sfBayAreaNorthEastLat = 38.0;
  static const double sfBayAreaNorthEastLng = -121.5;
}

/// Route names for navigation
class AppRoutes {
  AppRoutes._();

  static const String home = '/';
  static const String basicNavigation = '/basic-navigation';
  static const String freeDrive = '/free-drive';
  static const String multiStop = '/multi-stop';
  static const String embeddedMap = '/embedded-map';
  static const String staticMarkers = '/static-markers';
  static const String markerGallery = '/marker-gallery';
  static const String markerPopups = '/marker-popups';
  static const String offline = '/offline';
  static const String tripProgress = '/trip-progress';
  static const String eventsDemo = '/events-demo';
  static const String validation = '/validation';
  static const String accessibility = '/accessibility';
}

/// UI Constants
class UIConstants {
  UIConstants._();

  static const double cardElevation = 2.0;
  static const double borderRadius = 12.0;
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;

  // Navigation view heights
  static const double embeddedMapHeight = 350.0;
  static const double fullScreenMapHeight = double.infinity;

  // Touch targets (accessibility)
  static const double minTouchTargetSize = 48.0;
}

/// Feature categories for home screen organization
enum FeatureCategory {
  core('Core Navigation', Colors.blue),
  mapFeatures('Map & Markers', Colors.green),
  advanced('Advanced Features', Colors.orange);

  final String label;
  final Color color;

  const FeatureCategory(this.label, this.color);
}
