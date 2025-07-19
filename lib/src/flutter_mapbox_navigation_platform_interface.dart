import 'package:flutter/foundation.dart';
import 'package:flutter_mapbox_navigation/src/flutter_mapbox_navigation_method_channel.dart';
import 'package:flutter_mapbox_navigation/src/models/models.dart';
import 'package:flutter_mapbox_navigation/src/models/options.dart';
import 'package:flutter_mapbox_navigation/src/models/route_event.dart';
import 'package:flutter_mapbox_navigation/src/models/waypoint_result.dart';
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
  Future<bool?> enableOfflineRouting() async {
    throw UnimplementedError(
      'enableOfflineRouting() has not been implemented.',
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
}
