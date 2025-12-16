import 'package:flutter/foundation.dart';
import 'package:flutter_mapbox_navigation/src/flutter_mapbox_navigation_method_channel.dart';
import 'package:flutter_mapbox_navigation/src/models/models.dart';
import 'package:flutter_mapbox_navigation/src/models/options.dart';
import 'package:flutter_mapbox_navigation/src/models/route_event.dart';
import 'package:flutter_mapbox_navigation/src/models/waypoint_result.dart';
import 'package:flutter_mapbox_navigation/src/models/dynamic_marker.dart';
import 'package:flutter_mapbox_navigation/src/models/dynamic_marker_configuration.dart';
import 'package:flutter_mapbox_navigation/src/models/dynamic_marker_position_update.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

/// The interface that implementations of flutter_mapbox_navigation must implement.
///
/// Platform implementations should extend this class rather than implement it as `flutter_mapbox_navigation`
/// does not consider newly added methods to be breaking changes. Extending this class
/// (using `extends`) ensures that the subclass will get the default implementation, while
/// platform implementations that `implements` this interface will be broken by newly added
/// [FlutterMapboxNavigationPlatform] methods.
abstract class FlutterMapboxNavigationPlatform extends PlatformInterface {
  /// Constructs a FlutterMapboxNavigationPlatform.
  FlutterMapboxNavigationPlatform() : super(token: _token);

  static final Object _token = Object();

  static FlutterMapboxNavigationPlatform _instance =
      MethodChannelFlutterMapboxNavigation();

  /// The default instance of [FlutterMapboxNavigationPlatform] to use.
  ///
  /// Defaults to [MethodChannelFlutterMapboxNavigation].
  static FlutterMapboxNavigationPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [FlutterMapboxNavigationPlatform]
  /// when they register themselves.
  static set instance(FlutterMapboxNavigationPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  ///Current Device OS Version
  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }

  ///Total distance remaining in meters along route.
  Future<double?> getDistanceRemaining() {
    throw UnimplementedError(
      'getDistanceRemaining() has not been implemented.',
    );
  }

  ///Total seconds remaining on all legs.
  Future<double?> getDurationRemaining() {
    throw UnimplementedError(
      'getDurationRemaining() has not been implemented.',
    );
  }

  /// Free-drive mode is a unique Mapbox Navigation SDK feature that allows
  /// drivers to navigate without a set destination. This mode is sometimes
  /// referred to as passive navigation.
  /// [options] options used to generate the route and used while navigating
  /// Begins to generate Route Progress
  ///
  Future<bool?> startFreeDrive(MapBoxOptions options) async {
    throw UnimplementedError('startFreeDrive() has not been implemented.');
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
  Future<bool?> startNavigation(
    List<WayPoint> wayPoints,
    MapBoxOptions options,
  ) async {
    throw UnimplementedError('startNavigation() has not been implemented.');
  }

  ///Adds waypoints or stops to an on-going navigation
  ///
  /// [wayPoints] must not be null and have at least 1 item. The way points will
  /// be inserted after the currently navigating \
  /// waypoint in the existing navigation
  Future<WaypointResult> addWayPoints({required List<WayPoint> wayPoints}) {
    throw UnimplementedError(
      'addWayPoints({required wayPoints }) has not been implemented.',
    );
  }

  ///Ends Navigation and Closes the Navigation View
  Future<bool?> finishNavigation() async {
    throw UnimplementedError('finishNavigation() has not been implemented.');
  }

  /// Will download the navigation engine and the user's region
  /// to allow offline routing
  @Deprecated('Use downloadOfflineRegion instead for more control')
  Future<bool?> enableOfflineRouting() async {
    throw UnimplementedError(
      'enableOfflineRouting() has not been implemented.',
    );
  }

  /// Download map tiles and routing data for a specific region.
  ///
  /// [southWestLat] Southwest corner latitude
  /// [southWestLng] Southwest corner longitude
  /// [northEastLat] Northeast corner latitude
  /// [northEastLng] Northeast corner longitude
  /// [minZoom] Minimum zoom level to download (default: 10)
  /// [maxZoom] Maximum zoom level to download (default: 16)
  /// [includeRoutingTiles] Whether to include routing tiles for offline navigation (default: true)
  /// [onProgress] Optional callback for download progress (0.0 to 1.0)
  ///
  /// Returns a map with download result details, or null on error.
  /// The map includes: success, regionId, resourceCount, includesRoutingTiles
  Future<Map<String, dynamic>?> downloadOfflineRegion({
    required double southWestLat,
    required double southWestLng,
    required double northEastLat,
    required double northEastLng,
    int minZoom = 10,
    int maxZoom = 16,
    bool includeRoutingTiles = true,
    void Function(double progress)? onProgress,
  }) async {
    throw UnimplementedError(
      'downloadOfflineRegion() has not been implemented.',
    );
  }

  /// Check if offline routing data is available for a region.
  ///
  /// Returns true if routing tiles are cached for the specified bounds.
  Future<bool> isOfflineRoutingAvailable({
    required double latitude,
    required double longitude,
  }) async {
    throw UnimplementedError(
      'isOfflineRoutingAvailable() has not been implemented.',
    );
  }

  /// Delete cached offline routing data for a region.
  ///
  /// Returns true if deletion succeeds.
  Future<bool?> deleteOfflineRegion({
    required double southWestLat,
    required double southWestLng,
    required double northEastLat,
    required double northEastLng,
  }) async {
    throw UnimplementedError(
      'deleteOfflineRegion() has not been implemented.',
    );
  }

  /// Get the total size of cached offline data in bytes.
  Future<int> getOfflineCacheSize() async {
    throw UnimplementedError(
      'getOfflineCacheSize() has not been implemented.',
    );
  }

  /// Clear all cached offline routing data.
  Future<bool?> clearOfflineCache() async {
    throw UnimplementedError(
      'clearOfflineCache() has not been implemented.',
    );
  }

  /// Get the status of a specific offline region.
  ///
  /// [regionId] The unique identifier for the region
  ///
  /// Returns a map with:
  /// - `regionId`: The region identifier
  /// - `exists`: Whether the region exists
  /// - `mapTilesReady`: Whether map tiles are downloaded
  /// - `routingTilesReady`: Whether routing tiles are downloaded
  /// - `estimatedSizeBytes`: Estimated size in bytes
  /// - `isComplete`: Whether download is complete
  Future<Map<String, dynamic>?> getOfflineRegionStatus({
    required String regionId,
  }) async {
    throw UnimplementedError(
      'getOfflineRegionStatus() has not been implemented.',
    );
  }

  /// List all offline regions with their status.
  ///
  /// Returns a map with:
  /// - `regions`: List of region status maps
  /// - `totalCount`: Total number of regions
  /// - `totalSizeBytes`: Total size of all regions in bytes
  Future<Map<String, dynamic>?> listOfflineRegions() async {
    throw UnimplementedError(
      'listOfflineRegions() has not been implemented.',
    );
  }

  /// Event listener
  Future<dynamic> registerRouteEventListener(
    ValueSetter<RouteEvent> listener,
  ) async {
    throw UnimplementedError(
      'registerRouteEventListener() has not been implemented.',
    );
  }

  /// Register a callback for full-screen navigation events
  Future<dynamic> registerFullScreenEventListener(
    ValueSetter<FullScreenEvent> listener,
  ) async {
    throw UnimplementedError(
      'registerFullScreenEventListener() has not been implemented.',
    );
  }

  // MARK: Static Marker Methods

  /// Adds static markers to the map
  Future<bool?> addStaticMarkers({
    required List<StaticMarker> markers,
    MarkerConfiguration? configuration,
  }) async {
    throw UnimplementedError('addStaticMarkers() has not been implemented.');
  }

  /// Removes specific static markers from the map
  Future<bool?> removeStaticMarkers({
    required List<String> markerIds,
  }) async {
    throw UnimplementedError('removeStaticMarkers() has not been implemented.');
  }

  /// Removes all static markers from the map
  Future<bool?> clearAllStaticMarkers() async {
    throw UnimplementedError('clearAllStaticMarkers() has not been implemented.');
  }

  /// Updates the configuration for static markers
  Future<bool?> updateMarkerConfiguration({
    required MarkerConfiguration configuration,
  }) async {
    throw UnimplementedError('updateMarkerConfiguration() has not been implemented.');
  }

  /// Gets the current list of static markers on the map
  Future<List<StaticMarker>?> getStaticMarkers() async {
    throw UnimplementedError('getStaticMarkers() has not been implemented.');
  }

  /// Event listener for static marker tap events
  Future<dynamic> registerStaticMarkerTapListener(
    ValueSetter<StaticMarker> listener,
  ) async {
    throw UnimplementedError('registerStaticMarkerTapListener() has not been implemented.');
  }
  
  /// Get screen position for a marker coordinate
  /// Returns a Map with 'x' and 'y' screen coordinates, or null if not visible
  Future<Map<String, double>?> getMarkerScreenPosition(
    String markerId,
  ) async {
    throw UnimplementedError('getMarkerScreenPosition() has not been implemented.');
  }
  
  /// Get current map viewport information
  /// Returns a Map with center coordinates, zoom level, and view size
  Future<Map<String, dynamic>?> getMapViewport() async {
    throw UnimplementedError('getMapViewport() has not been implemented.');
  }

  // MARK: Dynamic Marker Methods

  /// Adds a single dynamic marker to the map.
  Future<bool?> addDynamicMarker({
    required DynamicMarker marker,
  }) async {
    throw UnimplementedError('addDynamicMarker() has not been implemented.');
  }

  /// Adds multiple dynamic markers to the map.
  Future<bool?> addDynamicMarkers({
    required List<DynamicMarker> markers,
  }) async {
    throw UnimplementedError('addDynamicMarkers() has not been implemented.');
  }

  /// Updates the position of a dynamic marker with animation.
  Future<bool?> updateDynamicMarkerPosition({
    required DynamicMarkerPositionUpdate update,
  }) async {
    throw UnimplementedError(
      'updateDynamicMarkerPosition() has not been implemented.',
    );
  }

  /// Applies multiple position updates in batch.
  Future<bool?> batchUpdateDynamicMarkerPositions({
    required List<DynamicMarkerPositionUpdate> updates,
  }) async {
    throw UnimplementedError(
      'batchUpdateDynamicMarkerPositions() has not been implemented.',
    );
  }

  /// Updates properties of a dynamic marker.
  Future<bool?> updateDynamicMarker({
    required String markerId,
    String? title,
    String? snippet,
    String? iconId,
    bool? showTrail,
    Map<String, dynamic>? metadata,
  }) async {
    throw UnimplementedError('updateDynamicMarker() has not been implemented.');
  }

  /// Removes a dynamic marker by ID.
  Future<bool?> removeDynamicMarker({
    required String markerId,
  }) async {
    throw UnimplementedError('removeDynamicMarker() has not been implemented.');
  }

  /// Removes multiple dynamic markers by ID.
  Future<bool?> removeDynamicMarkers({
    required List<String> markerIds,
  }) async {
    throw UnimplementedError(
      'removeDynamicMarkers() has not been implemented.',
    );
  }

  /// Removes all dynamic markers from the map.
  Future<bool?> clearAllDynamicMarkers() async {
    throw UnimplementedError(
      'clearAllDynamicMarkers() has not been implemented.',
    );
  }

  /// Gets a dynamic marker by ID.
  Future<DynamicMarker?> getDynamicMarker({
    required String markerId,
  }) async {
    throw UnimplementedError('getDynamicMarker() has not been implemented.');
  }

  /// Gets all current dynamic markers.
  Future<List<DynamicMarker>?> getDynamicMarkers() async {
    throw UnimplementedError('getDynamicMarkers() has not been implemented.');
  }

  /// Updates the global dynamic marker configuration.
  Future<bool?> updateDynamicMarkerConfiguration({
    required DynamicMarkerConfiguration configuration,
  }) async {
    throw UnimplementedError(
      'updateDynamicMarkerConfiguration() has not been implemented.',
    );
  }

  /// Clears the trail for a specific marker.
  Future<bool?> clearDynamicMarkerTrail({
    required String markerId,
  }) async {
    throw UnimplementedError(
      'clearDynamicMarkerTrail() has not been implemented.',
    );
  }

  /// Clears trails for all dynamic markers.
  Future<bool?> clearAllDynamicMarkerTrails() async {
    throw UnimplementedError(
      'clearAllDynamicMarkerTrails() has not been implemented.',
    );
  }

  /// Registers a listener for dynamic marker events.
  Future<dynamic> registerDynamicMarkerEventListener(
    ValueSetter<DynamicMarker> listener,
  ) async {
    throw UnimplementedError(
      'registerDynamicMarkerEventListener() has not been implemented.',
    );
  }
}
