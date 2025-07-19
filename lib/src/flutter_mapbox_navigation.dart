// ignore_for_file: use_setters_to_change_properties

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_mapbox_navigation/src/flutter_mapbox_navigation_platform_interface.dart';
import 'package:flutter_mapbox_navigation/src/models/models.dart';

/// Turn-By-Turn Navigation Provider
class MapBoxNavigation {
  static final MapBoxNavigation _instance = MapBoxNavigation();

  /// get current instance of this class
  static MapBoxNavigation get instance => _instance;

  MapBoxOptions _defaultOptions = MapBoxOptions(
    zoom: 15,
    tilt: 0,
    bearing: 0,
    enableRefresh: false,
    alternatives: true,
    voiceInstructionsEnabled: true,
    bannerInstructionsEnabled: true,
    allowsUTurnAtWayPoints: true,
    mode: MapBoxNavigationMode.drivingWithTraffic,
    units: VoiceUnits.imperial,
    simulateRoute: false,
    animateBuildRoute: true,
    longPressDestinationEnabled: true,
    language: 'en',
  );

  /// setter to set default options
  void setDefaultOptions(MapBoxOptions options) {
    _defaultOptions = options;
  }

  /// Getter to retriev default options
  MapBoxOptions getDefaultOptions() {
    return _defaultOptions;
  }

  ///Current Device OS Version
  Future<String?> getPlatformVersion() {
    return FlutterMapboxNavigationPlatform.instance.getPlatformVersion();
  }

  ///Total distance remaining in meters along route.
  Future<double?> getDistanceRemaining() {
    return FlutterMapboxNavigationPlatform.instance.getDistanceRemaining();
  }

  ///Total seconds remaining on all legs.
  Future<double?> getDurationRemaining() {
    return FlutterMapboxNavigationPlatform.instance.getDurationRemaining();
  }

  ///Adds waypoints or stops to an on-going navigation
  ///
  /// [wayPoints] must not be null and have at least 1 item. The way points will
  /// be inserted after the currently navigating waypoint
  /// in the existing navigation
  Future<dynamic> addWayPoints({required List<WayPoint> wayPoints}) async {
    return FlutterMapboxNavigationPlatform.instance
        .addWayPoints(wayPoints: wayPoints);
  }

  /// Free-drive mode is a unique Mapbox Navigation SDK feature that allows
  /// drivers to navigate without a set destination.
  /// This mode is sometimes referred to as passive navigation.
  /// Begins to generate Route Progress
  ///
  Future<bool?> startFreeDrive({MapBoxOptions? options}) async {
    options ??= _defaultOptions;
    return FlutterMapboxNavigationPlatform.instance.startFreeDrive(options);
  }

  ///Show the Navigation View and Begins Direction Routing
  ///
  /// [wayPoints] must not be null and have at least 2 items. A collection of
  /// [WayPoint](longitude, latitude and name). 
  /// 
  /// **Waypoint Limits:**
  /// - **Minimum**: 2 waypoints (enforced)
  /// - **Recommended Maximum**: 25 waypoints (Mapbox API limit)
  /// - **Plugin Behavior**: No maximum enforcement in plugin code
  /// - **iOS Traffic Mode**: Maximum 3 waypoints when using drivingWithTraffic
  /// 
  /// **API Considerations:**
  /// - Each navigation start counts as one Mapbox API request
  /// - Route calculation time increases with more waypoints
  /// - Exceeding 25 waypoints may result in API errors
  /// 
  /// [options] options used to generate the route and used while navigating
  /// Begins to generate Route Progress
  ///
  Future<bool?> startNavigation({
    required List<WayPoint> wayPoints,
    MapBoxOptions? options,
  }) async {
    options ??= _defaultOptions;
    return FlutterMapboxNavigationPlatform.instance
        .startNavigation(wayPoints, options);
  }

  ///Ends Navigation and Closes the Navigation View
  Future<bool?> finishNavigation() async {
    return FlutterMapboxNavigationPlatform.instance.finishNavigation();
  }

  /// Will download the navigation engine and the user's region
  /// to allow offline routing
  Future<bool?> enableOfflineRouting() async {
    return FlutterMapboxNavigationPlatform.instance.enableOfflineRouting();
  }

  /// Event listener for RouteEvents
  Future<dynamic> registerRouteEventListener(
    ValueSetter<RouteEvent> listener,
  ) async {
    return FlutterMapboxNavigationPlatform.instance
        .registerRouteEventListener(listener);
  }

  // MARK: Static Marker Methods

  /// Adds static markers to the map
  /// 
  /// [markers] List of static markers to add to the map
  /// [configuration] Optional configuration for marker display and behavior
  /// 
  /// **Features:**
  /// - Markers are displayed on the map with custom icons and colors
  /// - Clustering is enabled by default for dense areas
  /// - Markers can be filtered by distance from route
  /// - Tap callbacks provide interaction capabilities
  /// 
  /// **Usage Example:**
  /// ```dart
  /// final markers = [
  ///   StaticMarker(
  ///     id: 'scenic_1',
  ///     latitude: 37.7749,
  ///     longitude: -122.4194,
  ///     title: 'Golden Gate Bridge',
  ///     category: 'scenic',
  ///     description: 'Iconic suspension bridge',
  ///     iconId: MarkerIcons.scenic,
  ///   ),
  ///   StaticMarker(
  ///     id: 'petrol_1',
  ///     latitude: 37.7849,
  ///     longitude: -122.4094,
  ///     title: 'Shell Station',
  ///     category: 'petrol_station',
  ///     description: '24/7 fuel station',
  ///     iconId: MarkerIcons.petrolStation,
  ///   ),
  /// ];
  /// 
  /// await MapBoxNavigation.instance.addStaticMarkers(
  ///   markers: markers,
  ///   configuration: MarkerConfiguration(
  ///     maxDistanceFromRoute: 5.0, // 5km from route
  ///     onMarkerTap: (marker) {
  ///       print('Tapped: ${marker.title}');
  ///     },
  ///   ),
  /// );
  /// ```
  Future<bool?> addStaticMarkers({
    required List<StaticMarker> markers,
    MarkerConfiguration? configuration,
  }) async {
    return FlutterMapboxNavigationPlatform.instance.addStaticMarkers(
      markers: markers,
      configuration: configuration,
    );
  }

  /// Removes specific static markers from the map
  /// 
  /// [markerIds] List of marker IDs to remove
  /// 
  /// **Usage Example:**
  /// ```dart
  /// await MapBoxNavigation.instance.removeStaticMarkers(
  ///   markerIds: ['scenic_1', 'petrol_1'],
  /// );
  /// ```
  Future<bool?> removeStaticMarkers({
    required List<String> markerIds,
  }) async {
    return FlutterMapboxNavigationPlatform.instance.removeStaticMarkers(
      markerIds: markerIds,
    );
  }

  /// Removes all static markers from the map
  /// 
  /// **Usage Example:**
  /// ```dart
  /// await MapBoxNavigation.instance.clearAllStaticMarkers();
  /// ```
  Future<bool?> clearAllStaticMarkers() async {
    return FlutterMapboxNavigationPlatform.instance.clearAllStaticMarkers();
  }

  /// Updates the configuration for static markers
  /// 
  /// [configuration] New configuration settings
  /// 
  /// **Usage Example:**
  /// ```dart
  /// await MapBoxNavigation.instance.updateMarkerConfiguration(
  ///   MarkerConfiguration(
  ///     maxDistanceFromRoute: 10.0, // Increase to 10km
  ///     enableClustering: false, // Disable clustering
  ///   ),
  /// );
  /// ```
  Future<bool?> updateMarkerConfiguration({
    required MarkerConfiguration configuration,
  }) async {
    return FlutterMapboxNavigationPlatform.instance.updateMarkerConfiguration(
      configuration: configuration,
    );
  }

  /// Gets the current list of static markers on the map
  /// 
  /// Returns a list of currently displayed static markers
  /// 
  /// **Usage Example:**
  /// ```dart
  /// final currentMarkers = await MapBoxNavigation.instance.getStaticMarkers();
  /// print('Current markers: ${currentMarkers.length}');
  /// ```
  Future<List<StaticMarker>?> getStaticMarkers() async {
    return FlutterMapboxNavigationPlatform.instance.getStaticMarkers();
  }

  /// Event listener for static marker tap events
  /// 
  /// [listener] Callback function that receives the tapped marker
  /// 
  /// **Usage Example:**
  /// ```dart
  /// await MapBoxNavigation.instance.registerStaticMarkerTapListener(
  ///   (marker) {
  ///     print('Marker tapped: ${marker.title}');
  ///     // Show custom UI or perform actions
  ///   },
  /// );
  /// ```
  Future<dynamic> registerStaticMarkerTapListener(
    ValueSetter<StaticMarker> listener,
  ) async {
    return FlutterMapboxNavigationPlatform.instance
        .registerStaticMarkerTapListener(listener);
  }
}
