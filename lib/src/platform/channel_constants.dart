/// Platform channel constants and contract documentation.
///
/// This file defines the communication contract between Dart and native
/// platform code. All method names, event types, and data formats must
/// match exactly between Dart, iOS (Swift), and Android (Kotlin).

// =============================================================================
// CHANNEL NAMES
// =============================================================================

/// Method channel for invoking native methods.
const String kMethodChannelName = 'flutter_mapbox_navigation';

/// Event channel for navigation events (route progress, arrival, etc.).
const String kEventChannelName = 'flutter_mapbox_navigation/events';

/// Event channel for static marker tap events.
const String kMarkerEventChannelName = 'flutter_mapbox_navigation/marker_events';

/// Event channel for offline download progress events.
const String kOfflineProgressChannelName = 'flutter_mapbox_navigation/offline_progress';

// =============================================================================
// METHOD NAMES
// =============================================================================

/// Method names for platform channel communication.
///
/// These must match exactly in native implementations.
abstract class Methods {
  Methods._(); // Prevent instantiation
  // ---------------------------------------------------------------------------
  // Core Navigation Methods
  // ---------------------------------------------------------------------------

  /// Gets the platform version string.
  ///
  /// **Returns:** `String` - Platform version (e.g., "Android 14", "iOS 17.0")
  static const String getPlatformVersion = 'getPlatformVersion';

  /// Starts turn-by-turn navigation.
  ///
  /// **Arguments:**
  /// ```json
  /// {
  ///   "wayPoints": [
  ///     {
  ///       "latitude": double,      // Required: -90 to 90
  ///       "longitude": double,     // Required: -180 to 180
  ///       "name": String?,         // Optional: Display name
  ///       "isSilent": bool?        // Optional: Silent waypoint (default: false)
  ///     }
  ///   ],
  ///   "options": {
  ///     "mode": String,            // "driving" | "drivingWithTraffic" | "walking" | "cycling"
  ///     "units": String,           // "imperial" | "metric"
  ///     "language": String,        // ISO language code (e.g., "en")
  ///     "simulateRoute": bool,     // Enable route simulation
  ///     "voiceInstructionsEnabled": bool,
  ///     "bannerInstructionsEnabled": bool,
  ///     "alternatives": bool,      // Show alternative routes
  ///     "zoom": double,            // Initial map zoom level
  ///     "tilt": double,            // Map tilt angle
  ///     "bearing": double          // Map bearing
  ///   }
  /// }
  /// ```
  ///
  /// **Returns:** `bool` - true if navigation started successfully
  ///
  /// **Errors:**
  /// - `PERMISSION_DENIED`: Location permission not granted
  /// - `ROUTE_NOT_FOUND`: No route between waypoints
  /// - `INVALID_ARGUMENTS`: Invalid waypoint data
  static const String startNavigation = 'startNavigation';

  /// Starts free-drive (passive navigation) mode.
  ///
  /// **Arguments:** Same as [startNavigation] but wayPoints may be empty
  ///
  /// **Returns:** `bool` - true if free drive started
  static const String startFreeDrive = 'startFreeDrive';

  /// Finishes the current navigation session.
  ///
  /// **Arguments:** None
  ///
  /// **Returns:** `bool` - true if navigation was stopped
  static const String finishNavigation = 'finishNavigation';

  /// Gets the remaining distance in meters.
  ///
  /// **Arguments:** None
  ///
  /// **Returns:** `double?` - Distance in meters, null if not navigating
  static const String getDistanceRemaining = 'getDistanceRemaining';

  /// Gets the remaining duration in seconds.
  ///
  /// **Arguments:** None
  ///
  /// **Returns:** `double?` - Duration in seconds, null if not navigating
  static const String getDurationRemaining = 'getDurationRemaining';

  /// Adds waypoints to an ongoing navigation.
  ///
  /// **Arguments:**
  /// ```json
  /// {
  ///   "wayPoints": [{ "latitude": double, "longitude": double, ... }]
  /// }
  /// ```
  ///
  /// **Returns:** `Map<String, Object?>`
  /// ```json
  /// {
  ///   "success": bool,
  ///   "waypointsAdded": int
  /// }
  /// ```
  static const String addWayPoints = 'addWayPoints';

  // ---------------------------------------------------------------------------
  // Offline Navigation Methods
  // ---------------------------------------------------------------------------

  /// Enables offline routing mode.
  ///
  /// **Arguments:** None
  ///
  /// **Returns:** `bool` - true if offline mode enabled
  static const String enableOfflineRouting = 'enableOfflineRouting';

  /// Downloads tiles for offline navigation.
  ///
  /// **Arguments:**
  /// ```json
  /// {
  ///   "southWestLat": double,
  ///   "southWestLng": double,
  ///   "northEastLat": double,
  ///   "northEastLng": double,
  ///   "minZoom": int,             // Default: 10
  ///   "maxZoom": int,             // Default: 16
  ///   "includeRoutingTiles": bool // Default: false
  /// }
  /// ```
  ///
  /// **Returns:** `Map<String, Object?>`
  /// ```json
  /// {
  ///   "success": bool,
  ///   "regionId": String
  /// }
  /// ```
  ///
  /// **Events:** Progress updates sent via [kOfflineProgressChannelName]
  static const String downloadOfflineRegion = 'downloadOfflineRegion';

  /// Checks if offline routing is available for a location.
  ///
  /// **Arguments:**
  /// ```json
  /// {
  ///   "latitude": double,
  ///   "longitude": double
  /// }
  /// ```
  ///
  /// **Returns:** `bool` - true if offline routing available
  static const String isOfflineRoutingAvailable = 'isOfflineRoutingAvailable';

  /// Deletes a downloaded offline region.
  ///
  /// **Arguments:**
  /// ```json
  /// {
  ///   "southWestLat": double,
  ///   "southWestLng": double,
  ///   "northEastLat": double,
  ///   "northEastLng": double
  /// }
  /// ```
  ///
  /// **Returns:** `bool` - true if deleted
  static const String deleteOfflineRegion = 'deleteOfflineRegion';

  /// Gets the size of the offline cache in bytes.
  ///
  /// **Arguments:** None
  ///
  /// **Returns:** `int` - Cache size in bytes
  static const String getOfflineCacheSize = 'getOfflineCacheSize';

  /// Clears all offline cached data.
  ///
  /// **Arguments:** None
  ///
  /// **Returns:** `bool` - true if cleared
  static const String clearOfflineCache = 'clearOfflineCache';

  /// Gets the status of an offline region.
  ///
  /// **Arguments:**
  /// ```json
  /// {
  ///   "regionId": String
  /// }
  /// ```
  ///
  /// **Returns:** `Map<String, Object?>`
  /// ```json
  /// {
  ///   "status": String,           // "pending" | "downloading" | "complete" | "error"
  ///   "progress": double,         // 0.0 to 1.0
  ///   "completedSize": int,       // Bytes downloaded
  ///   "totalSize": int            // Total bytes
  /// }
  /// ```
  static const String getOfflineRegionStatus = 'getOfflineRegionStatus';

  /// Lists all downloaded offline regions.
  ///
  /// **Arguments:** None
  ///
  /// **Returns:** `Map<String, Object?>`
  /// ```json
  /// {
  ///   "regions": [
  ///     {
  ///       "id": String,
  ///       "bounds": { "sw": {...}, "ne": {...} },
  ///       "size": int
  ///     }
  ///   ],
  ///   "totalCount": int
  /// }
  /// ```
  static const String listOfflineRegions = 'listOfflineRegions';

  // ---------------------------------------------------------------------------
  // Static Marker Methods
  // ---------------------------------------------------------------------------

  /// Adds static markers to the map.
  ///
  /// **Arguments:**
  /// ```json
  /// {
  ///   "markers": [
  ///     {
  ///       "id": String,           // Required: Unique identifier
  ///       "latitude": double,     // Required
  ///       "longitude": double,    // Required
  ///       "title": String?,       // Optional: Marker title
  ///       "snippet": String?,     // Optional: Marker description
  ///       "iconId": String?,      // Optional: Icon identifier
  ///       "category": String?,    // Optional: Category for styling
  ///       "metadata": Map?        // Optional: Custom data
  ///     }
  ///   ],
  ///   "configuration": {
  ///     "clusteringEnabled": bool,
  ///     "clusterRadius": int,
  ///     "showCallouts": bool
  ///   }
  /// }
  /// ```
  ///
  /// **Returns:** `bool` - true if markers added
  static const String addStaticMarkers = 'addStaticMarkers';

  /// Removes static markers by ID.
  ///
  /// **Arguments:**
  /// ```json
  /// {
  ///   "markerIds": [String]
  /// }
  /// ```
  ///
  /// **Returns:** `bool` - true if markers removed
  static const String removeStaticMarkers = 'removeStaticMarkers';

  /// Removes all static markers from the map.
  ///
  /// **Arguments:** None
  ///
  /// **Returns:** `bool` - true if cleared
  static const String clearAllStaticMarkers = 'clearAllStaticMarkers';

  /// Updates marker display configuration.
  ///
  /// **Arguments:** Same as configuration in [addStaticMarkers]
  ///
  /// **Returns:** `bool` - true if updated
  static const String updateMarkerConfiguration = 'updateMarkerConfiguration';

  /// Gets all current static markers.
  ///
  /// **Arguments:** None
  ///
  /// **Returns:** `List<Map<String, Object?>>` - Array of marker data
  static const String getStaticMarkers = 'getStaticMarkers';

  /// Gets the screen position of a marker.
  ///
  /// **Arguments:**
  /// ```json
  /// {
  ///   "markerId": String
  /// }
  /// ```
  ///
  /// **Returns:** `Map<String, double>?`
  /// ```json
  /// {
  ///   "x": double,    // Screen X coordinate
  ///   "y": double     // Screen Y coordinate
  /// }
  /// ```
  /// Returns null if marker not visible.
  static const String getMarkerScreenPosition = 'getMarkerScreenPosition';

  // ---------------------------------------------------------------------------
  // Map Viewport Methods
  // ---------------------------------------------------------------------------

  /// Gets the current map viewport information.
  ///
  /// **Arguments:** None
  ///
  /// **Returns:** `Map<String, Object?>`
  /// ```json
  /// {
  ///   "center": { "latitude": double, "longitude": double },
  ///   "zoom": double,
  ///   "bearing": double,
  ///   "tilt": double,
  ///   "bounds": {
  ///     "southwest": { "latitude": double, "longitude": double },
  ///     "northeast": { "latitude": double, "longitude": double }
  ///   }
  /// }
  /// ```
  static const String getMapViewport = 'getMapViewport';
}

// =============================================================================
// EVENT TYPES
// =============================================================================

/// Event types received from native code via event channels.
///
/// These must match exactly in native implementations.
abstract class EventTypes {
  EventTypes._(); // Prevent instantiation
  // ---------------------------------------------------------------------------
  // Route Events (via kEventChannelName)
  // ---------------------------------------------------------------------------

  /// Navigation has started.
  static const String navigationStarted = 'navigation_started';

  /// Route is being built/calculated.
  static const String routeBuilding = 'route_building';

  /// Route has been successfully built.
  static const String routeBuilt = 'route_built';

  /// Route building failed.
  static const String routeBuildFailed = 'route_build_failed';

  /// Progress update during navigation.
  ///
  /// **Data:**
  /// ```json
  /// {
  ///   "distanceRemaining": double,    // Meters
  ///   "durationRemaining": double,    // Seconds
  ///   "distanceTraveled": double,     // Meters
  ///   "currentLegIndex": int,
  ///   "currentStepIndex": int,
  ///   "currentLegProgress": double,   // 0.0 to 1.0
  ///   "location": {
  ///     "latitude": double,
  ///     "longitude": double,
  ///     "bearing": double,
  ///     "speed": double               // Meters per second
  ///   },
  ///   "currentInstruction": String?,
  ///   "nextInstruction": String?
  /// }
  /// ```
  static const String progressChange = 'progress_change';

  /// User has gone off the planned route.
  static const String userOffRoute = 'user_off_route';

  /// Milestone reached (waypoint or destination).
  static const String milestoneEvent = 'milestone_event';

  /// Route has been rerouted.
  static const String routeRerouted = 'route_rerouted';

  /// Arrived at a waypoint.
  ///
  /// **Data:**
  /// ```json
  /// {
  ///   "waypointIndex": int,
  ///   "waypointName": String?,
  ///   "isFinalDestination": bool
  /// }
  /// ```
  static const String onArrival = 'on_arrival';

  /// Navigation was cancelled.
  static const String navigationCancelled = 'navigation_cancelled';

  /// Navigation finished (arrived at final destination).
  static const String navigationFinished = 'navigation_finished';

  // ---------------------------------------------------------------------------
  // Marker Events (via kMarkerEventChannelName)
  // ---------------------------------------------------------------------------

  /// A static marker was tapped.
  ///
  /// **Data:** Full marker object as Map<String, Object?>
  static const String markerTapped = 'marker_tapped';

  /// A marker callout action was triggered.
  static const String markerCalloutTapped = 'marker_callout_tapped';

  // ---------------------------------------------------------------------------
  // Offline Events (via kOfflineProgressChannelName)
  // ---------------------------------------------------------------------------

  /// Download progress update.
  ///
  /// **Data:**
  /// ```json
  /// {
  ///   "regionId": String,
  ///   "progress": double,     // 0.0 to 1.0
  ///   "completedBytes": int,
  ///   "totalBytes": int
  /// }
  /// ```
  static const String downloadProgress = 'download_progress';

  /// Download completed.
  static const String downloadComplete = 'download_complete';

  /// Download failed.
  static const String downloadFailed = 'download_failed';
}

// =============================================================================
// ERROR CODES
// =============================================================================

/// Error codes returned from native platform.
///
/// These must match exactly in native implementations.
abstract class ErrorCodes {
  ErrorCodes._(); // Prevent instantiation
  /// Location permission was denied.
  static const String permissionDenied = 'PERMISSION_DENIED';

  /// Location services unavailable.
  static const String locationUnavailable = 'LOCATION_UNAVAILABLE';

  /// No route found between points.
  static const String routeNotFound = 'ROUTE_NOT_FOUND';

  /// Network error occurred.
  static const String networkError = 'NETWORK_ERROR';

  /// Invalid arguments provided.
  static const String invalidArguments = 'INVALID_ARGUMENTS';

  /// Mapbox token is invalid.
  static const String invalidToken = 'INVALID_TOKEN';

  /// Operation not implemented.
  static const String notImplemented = 'NOT_IMPLEMENTED';

  /// Operation timed out.
  static const String timeout = 'TIMEOUT';

  /// Operation was cancelled.
  static const String cancelled = 'CANCELLED';
}
