// ignore_for_file: use_setters_to_change_properties

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_mapbox_navigation/src/flutter_mapbox_navigation_platform_interface.dart';
import 'package:flutter_mapbox_navigation/src/flutter_mapbox_navigation_method_channel.dart';
import 'package:flutter_mapbox_navigation/src/models/models.dart';
import 'package:flutter_mapbox_navigation/src/widgets/flutter_fullscreen_navigation.dart';
import 'package:flutter_mapbox_navigation/src/utilities/coordinate_converter.dart';

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

  /// Show a native Drop-in Navigation view
  ///
  /// This uses Mapbox's native Drop-in UI for navigation.
  /// **Note:** Flutter cannot render overlays on top of native navigation.
  /// For marker popups, use [startFlutterNavigation] instead.
  ///
  /// [wayPoints] must not be null and have at least 2 items
  /// [options] options used to generate the route and used while navigating
  /// [showDebugOverlay] whether to show debug information overlay
  ///
  /// **Usage Example:**
  /// ```dart
  /// await MapBoxNavigation.instance.startFlutterStyledNavigation(
  ///   wayPoints: [origin, destination],
  ///   options: MapBoxOptions(simulateRoute: true),
  /// );
  /// ```
  Future<bool?> startFlutterStyledNavigation({
    required List<WayPoint> wayPoints,
    MapBoxOptions? options,
    bool showDebugOverlay = false,
  }) async {
    options ??= _defaultOptions;

    return (FlutterMapboxNavigationPlatform.instance as MethodChannelFlutterMapboxNavigation)
        .startFlutterStyledNavigation(
      wayPoints,
      options,
      showDebugOverlay: showDebugOverlay,
    );
  }

  /// Show a Flutter-controlled navigation view with Flutter overlays (RECOMMENDED)
  ///
  /// This embeds the native map inside Flutter using platform views, allowing
  /// Flutter to render overlays (like marker popups) on top of the map.
  ///
  /// **Features:**
  /// - Native map performance via platform views
  /// - Cross-platform Flutter marker popups (works on Android & iOS)
  /// - Customizable popup UI via [markerPopupBuilder]
  /// - Default Material Design popup when no custom builder provided
  /// - Full control over navigation UI elements
  ///
  /// [context] Build context for navigation
  /// [wayPoints] must not be null and have at least 2 items
  /// [options] options used to generate the route and used while navigating
  /// [markerPopupBuilder] optional custom builder for marker popup UI
  /// [onMarkerTap] optional callback for marker tap events (called in addition to popup)
  /// [onMapTap] optional callback for map tap events
  /// [onRouteEvent] optional callback for route progress events
  /// [onNavigationFinished] optional callback when navigation ends
  /// [showDebugOverlay] whether to show debug information overlay
  ///
  /// **Usage Example:**
  /// ```dart
  /// await MapBoxNavigation.instance.startFlutterNavigation(
  ///   context: context,
  ///   wayPoints: [origin, destination],
  ///   options: MapBoxOptions(simulateRoute: true),
  ///   // Optional: Custom popup builder
  ///   markerPopupBuilder: (context, marker, onClose) {
  ///     return MyCustomPopup(marker: marker, onClose: onClose);
  ///   },
  ///   onMarkerTap: (marker) {
  ///     print('Marker tapped: ${marker.title}');
  ///   },
  /// );
  /// ```
  Future<void> startFlutterNavigation({
    required BuildContext context,
    required List<WayPoint> wayPoints,
    MapBoxOptions? options,
    MarkerPopupBuilder? markerPopupBuilder,
    Function(StaticMarker)? onMarkerTap,
    Function(double lat, double lng)? onMapTap,
    Function(RouteEvent)? onRouteEvent,
    Function()? onNavigationFinished,
    bool showDebugOverlay = false,
  }) async {
    options ??= _defaultOptions;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FlutterFullScreenNavigation(
          wayPoints: wayPoints,
          options: options!,
          markerPopupBuilder: markerPopupBuilder,
          onMarkerTap: onMarkerTap,
          onMapTap: onMapTap,
          onRouteEvent: onRouteEvent,
          onNavigationFinished: onNavigationFinished,
          showDebugOverlay: showDebugOverlay,
        ),
        fullscreenDialog: true,
      ),
    );
  }

  ///Ends Navigation and Closes the Navigation View
  Future<bool?> finishNavigation() async {
    return FlutterMapboxNavigationPlatform.instance.finishNavigation();
  }

  /// Will download the navigation engine and the user's region
  /// to allow offline routing
  @Deprecated('Use downloadOfflineRegion instead for more control')
  Future<bool?> enableOfflineRouting() async {
    return FlutterMapboxNavigationPlatform.instance.enableOfflineRouting();
  }

  // MARK: Offline Routing Methods

  /// Download map tiles and routing data for a specific region.
  ///
  /// Creates offline cache for navigation within the specified bounding box.
  /// Progress updates are sent via the optional [onProgress] callback.
  ///
  /// [southWestLat] Southwest corner latitude
  /// [southWestLng] Southwest corner longitude
  /// [northEastLat] Northeast corner latitude
  /// [northEastLng] Northeast corner longitude
  /// [minZoom] Minimum zoom level to download (default: 10)
  /// [maxZoom] Maximum zoom level to download (default: 16)
  /// [onProgress] Optional callback for download progress (0.0 to 1.0)
  ///
  /// Returns true if download succeeds, false otherwise.
  ///
  /// **Usage Example:**
  /// ```dart
  /// final success = await MapBoxNavigation.instance.downloadOfflineRegion(
  ///   southWestLat: 46.0,
  ///   southWestLng: 6.0,
  ///   northEastLat: 47.0,
  ///   northEastLng: 7.0,
  ///   minZoom: 10,
  ///   maxZoom: 16,
  ///   onProgress: (progress) {
  ///     print('Download: ${(progress * 100).toStringAsFixed(0)}%');
  ///   },
  /// );
  /// ```
  Future<bool?> downloadOfflineRegion({
    required double southWestLat,
    required double southWestLng,
    required double northEastLat,
    required double northEastLng,
    int minZoom = 10,
    int maxZoom = 16,
    void Function(double progress)? onProgress,
  }) async {
    return FlutterMapboxNavigationPlatform.instance.downloadOfflineRegion(
      southWestLat: southWestLat,
      southWestLng: southWestLng,
      northEastLat: northEastLat,
      northEastLng: northEastLng,
      minZoom: minZoom,
      maxZoom: maxZoom,
      onProgress: onProgress,
    );
  }

  /// Check if offline routing data is available for a location.
  ///
  /// Returns true if routing tiles are cached for the specified coordinates.
  ///
  /// **Usage Example:**
  /// ```dart
  /// final isAvailable = await MapBoxNavigation.instance.isOfflineRoutingAvailable(
  ///   latitude: 46.5,
  ///   longitude: 6.5,
  /// );
  /// if (isAvailable) {
  ///   print('Offline routing available for this location');
  /// }
  /// ```
  Future<bool> isOfflineRoutingAvailable({
    required double latitude,
    required double longitude,
  }) async {
    return FlutterMapboxNavigationPlatform.instance.isOfflineRoutingAvailable(
      latitude: latitude,
      longitude: longitude,
    );
  }

  /// Delete cached offline routing data for a region.
  ///
  /// Removes offline tiles and routing data for the specified bounding box.
  ///
  /// Returns true if deletion succeeds.
  ///
  /// **Usage Example:**
  /// ```dart
  /// await MapBoxNavigation.instance.deleteOfflineRegion(
  ///   southWestLat: 46.0,
  ///   southWestLng: 6.0,
  ///   northEastLat: 47.0,
  ///   northEastLng: 7.0,
  /// );
  /// ```
  Future<bool?> deleteOfflineRegion({
    required double southWestLat,
    required double southWestLng,
    required double northEastLat,
    required double northEastLng,
  }) async {
    return FlutterMapboxNavigationPlatform.instance.deleteOfflineRegion(
      southWestLat: southWestLat,
      southWestLng: southWestLng,
      northEastLat: northEastLat,
      northEastLng: northEastLng,
    );
  }

  /// Get the total size of cached offline data in bytes.
  ///
  /// **Usage Example:**
  /// ```dart
  /// final sizeBytes = await MapBoxNavigation.instance.getOfflineCacheSize();
  /// final sizeMB = sizeBytes / (1024 * 1024);
  /// print('Offline cache: ${sizeMB.toStringAsFixed(1)} MB');
  /// ```
  Future<int> getOfflineCacheSize() async {
    return FlutterMapboxNavigationPlatform.instance.getOfflineCacheSize();
  }

  /// Clear all cached offline routing data.
  ///
  /// Removes all offline tiles and routing data from the device.
  /// Use with caution - this operation cannot be undone.
  ///
  /// Returns true if clearing succeeds.
  ///
  /// **Usage Example:**
  /// ```dart
  /// final success = await MapBoxNavigation.instance.clearOfflineCache();
  /// if (success == true) {
  ///   print('Offline cache cleared');
  /// }
  /// ```
  Future<bool?> clearOfflineCache() async {
    return FlutterMapboxNavigationPlatform.instance.clearOfflineCache();
  }

  /// Event listener for RouteEvents
  Future<dynamic> registerRouteEventListener(
    ValueSetter<RouteEvent> listener,
  ) async {
    return FlutterMapboxNavigationPlatform.instance
        .registerRouteEventListener(listener);
  }

  /// Event listener for full-screen navigation events
  /// This handles marker taps and map taps in full-screen navigation mode
  Future<dynamic> registerFullScreenEventListener(
    ValueSetter<FullScreenEvent> listener,
  ) async {
    return FlutterMapboxNavigationPlatform.instance
        .registerFullScreenEventListener(listener);
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
  
  /// Get screen position for a marker by ID
  /// Returns screen coordinates as Offset, or null if marker not found/visible
  /// 
  /// **Usage Example:**
  /// ```dart
  /// final position = await MapBoxNavigation.instance.getMarkerScreenPosition('marker_id');
  /// if (position != null) {
  ///   print('Marker is at screen position: $position');
  /// }
  /// ```
  Future<Offset?> getMarkerScreenPosition(String markerId) async {
    final result = await FlutterMapboxNavigationPlatform.instance
        .getMarkerScreenPosition(markerId);
    
    if (result == null) return null;
    
    return Offset(result['x']!, result['y']!);
  }
  
  /// Get current map viewport information
  /// Returns viewport data including center coordinates, zoom level, and size
  /// 
  /// **Usage Example:**
  /// ```dart
  /// final viewport = await MapBoxNavigation.instance.getMapViewport();
  /// if (viewport != null) {
  ///   print('Map center: ${viewport['centerLat']}, ${viewport['centerLng']}');
  ///   print('Zoom level: ${viewport['zoom']}');
  /// }
  /// ```
  Future<MapViewport?> getMapViewport() async {
    final result = await FlutterMapboxNavigationPlatform.instance
        .getMapViewport();
    
    if (result == null) return null;
    
    return MapViewport(
      center: LatLng(
        result['centerLat'] as double,
        result['centerLng'] as double,
      ),
      zoomLevel: result['zoom'] as double,
      size: Size(
        result['width'] as double,
        result['height'] as double,
      ),
      bearing: result['bearing'] as double? ?? 0.0,
      tilt: result['tilt'] as double? ?? 0.0,
    );
  }
}
