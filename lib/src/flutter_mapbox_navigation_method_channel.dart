import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mapbox_navigation/src/flutter_mapbox_navigation_platform_interface.dart';
import 'package:flutter_mapbox_navigation/src/models/models.dart';
import 'package:flutter_mapbox_navigation/src/models/waypoint_result.dart';
import 'package:flutter_mapbox_navigation/src/platform/channel_constants.dart';

/// An implementation of [FlutterMapboxNavigationPlatform]
/// that uses method channels.
class MethodChannelFlutterMapboxNavigation
    extends FlutterMapboxNavigationPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel(kMethodChannelName);

  /// The event channel used to interact with the native platform.
  @visibleForTesting
  final eventChannel = const EventChannel(kEventChannelName);

  /// The event channel used for static marker events.
  @visibleForTesting
  final markerEventChannel = const EventChannel(kMarkerEventChannelName);

  /// The event channel used for dynamic marker events.
  @visibleForTesting
  final dynamicMarkerEventChannel = const EventChannel(kDynamicMarkerEventChannelName);

  late StreamSubscription<RouteEvent> _routeEventSubscription;
  late StreamSubscription<StaticMarker> _markerEventSubscription;
  StreamSubscription<DynamicMarker>? _dynamicMarkerEventSubscription;
  ValueSetter<RouteEvent>? _onRouteEvent;
  ValueSetter<StaticMarker>? _onMarkerTap;
  ValueSetter<FullScreenEvent>? _onFullScreenEvent;
  ValueSetter<DynamicMarker>? _onDynamicMarkerEvent;

  @override
  Future<String?> getPlatformVersion() async {
    final version =
        await methodChannel.invokeMethod<String>(Methods.getPlatformVersion);
    return version;
  }

  @override
  Future<double?> getDistanceRemaining() async {
    final distance =
        await methodChannel.invokeMethod<double?>(Methods.getDistanceRemaining);
    return distance;
  }

  @override
  Future<double?> getDurationRemaining() async {
    final duration =
        await methodChannel.invokeMethod<double?>(Methods.getDurationRemaining);
    return duration;
  }

  @override
  Future<bool?> startFreeDrive(MapBoxOptions options) async {
    _routeEventSubscription = routeEventsListener!.listen(_onProgressData);
    final args = options.toMap();
    final result = await methodChannel.invokeMethod(Methods.startFreeDrive, args);
    if (result is bool) return result;
    log(result.toString());
    return false;
  }

  @override
  Future<bool?> startNavigation(
    List<WayPoint> wayPoints,
    MapBoxOptions options,
  ) async {
    assert(wayPoints.length > 1, 'Error: WayPoints must be at least 2');
    if (Platform.isIOS && wayPoints.length > 3) {
      assert(options.mode != MapBoxNavigationMode.drivingWithTraffic, '''
            Error: Cannot use drivingWithTraffic Mode when you have more than 3 Stops
          ''');
    }

    final pointList = _getPointListFromWayPoints(wayPoints);
    var i = 0;
    final wayPointMap = {for (var e in pointList) i++: e};

    final args = options.toMap();
    args['wayPoints'] = wayPointMap;

    _routeEventSubscription = routeEventsListener!.listen(_onProgressData);
    final result = await methodChannel.invokeMethod(Methods.startNavigation, args);
    if (result is bool) return result;
    log(result.toString());
    return false;
  }

  @override
  Future<WaypointResult> addWayPoints({required List<WayPoint> wayPoints}) async {
    assert(wayPoints.isNotEmpty, 'Error: WayPoints must be at least 1');
    try {
      final pointList = _getPointListFromWayPoints(wayPoints);
      var i = 0;
      final wayPointMap = {for (var e in pointList) i++: e};
      final args = <String, dynamic>{};
      args['wayPoints'] = wayPointMap;
      
      final result = await methodChannel.invokeMethod(Methods.addWayPoints, args);
      if (result is Map) {
        return WaypointResult(
          success: result['success'] as bool,
          waypointsAdded: result['waypointsAdded'] as int,
          errorMessage: result['errorMessage'] as String?,
        );
      }
      return WaypointResult.failure(
        errorMessage: 'Invalid response from platform',
        waypointsAdded: 0,
      );
    } catch (e) {
      return WaypointResult.failure(
        errorMessage: e.toString(),
        waypointsAdded: 0,
      );
    }
  }

  @override
  Future<bool?> finishNavigation() async {
    final success = await methodChannel.invokeMethod<bool?>(Methods.finishNavigation);
    return success;
  }

  /// Will download the navigation engine and the user's region
  /// to allow offline routing
  @override
  @Deprecated('Use downloadOfflineRegion instead for more control')
  Future<bool?> enableOfflineRouting() async {
    final success =
        await methodChannel.invokeMethod<bool?>(Methods.enableOfflineRouting);
    return success;
  }

  /// Download map tiles and routing data for a specific region.
  ///
  /// [includeRoutingTiles] - When true (default), downloads routing tiles for offline
  /// turn-by-turn navigation. Set to false to only download map display tiles.
  @override
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
    StreamSubscription<dynamic>? progressSubscription;

    try {
      // Set up progress listener if callback provided
      if (onProgress != null) {
        progressSubscription = eventChannel.receiveBroadcastStream().listen(
          (dynamic event) {
            try {
              Map<String, dynamic>? eventData;

              if (event is Map) {
                // Recursively convert nested maps
                eventData = _convertMap(event);
              } else if (event is String) {
                // Some platforms send JSON strings
                eventData = jsonDecode(event) as Map<String, dynamic>?;
              }

              if (eventData != null &&
                  eventData['eventType'] == 'download_progress') {
                final data = eventData['data'];
                if (data is Map) {
                  final dataMap = _convertMap(data);
                  final progress = (dataMap['progress'] as num?)?.toDouble();
                  if (progress != null) {
                    onProgress(progress);
                  }
                }
              }
            } catch (e) {
              log('Error parsing download progress event: $e');
            }
          },
          onError: (dynamic error) {
            log('Download progress stream error: $error');
          },
        );
      }

      final args = <String, dynamic>{
        'southWestLat': southWestLat,
        'southWestLng': southWestLng,
        'northEastLat': northEastLat,
        'northEastLng': northEastLng,
        'minZoom': minZoom,
        'maxZoom': maxZoom,
        'includeRoutingTiles': includeRoutingTiles,
      };

      final result = await methodChannel.invokeMethod<Object?>(
        Methods.downloadOfflineRegion,
        args,
      );

      // Handle different response formats
      if (result is Map) {
        return Map<String, dynamic>.from(result);
      } else if (result is bool) {
        // Legacy response format
        return {
          'success': result,
          'includesRoutingTiles': includeRoutingTiles,
        };
      }

      return null;
    } catch (e) {
      log('Error downloading offline region: $e');
      return null;
    } finally {
      // Clean up progress listener
      await progressSubscription?.cancel();
    }
  }

  /// Check if offline routing data is available for a location.
  @override
  Future<bool> isOfflineRoutingAvailable({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final args = <String, dynamic>{
        'latitude': latitude,
        'longitude': longitude,
      };

      final result = await methodChannel.invokeMethod<bool?>(
        Methods.isOfflineRoutingAvailable,
        args,
      );

      return result ?? false;
    } catch (e) {
      log('Error checking offline routing availability: $e');
      return false;
    }
  }

  /// Delete cached offline routing data for a region.
  @override
  Future<bool?> deleteOfflineRegion({
    required double southWestLat,
    required double southWestLng,
    required double northEastLat,
    required double northEastLng,
  }) async {
    try {
      final args = <String, dynamic>{
        'southWestLat': southWestLat,
        'southWestLng': southWestLng,
        'northEastLat': northEastLat,
        'northEastLng': northEastLng,
      };

      final result = await methodChannel.invokeMethod<bool?>(
        Methods.deleteOfflineRegion,
        args,
      );

      return result;
    } catch (e) {
      log('Error deleting offline region: $e');
      return false;
    }
  }

  /// Get the total size of cached offline data in bytes.
  @override
  Future<int> getOfflineCacheSize() async {
    try {
      final result = await methodChannel.invokeMethod<int?>(
        Methods.getOfflineCacheSize,
      );
      return result ?? 0;
    } catch (e) {
      log('Error getting offline cache size: $e');
      return 0;
    }
  }

  /// Clear all cached offline routing data.
  @override
  Future<bool?> clearOfflineCache() async {
    try {
      final result = await methodChannel.invokeMethod<bool?>(
        Methods.clearOfflineCache,
      );
      return result;
    } catch (e) {
      log('Error clearing offline cache: $e');
      return false;
    }
  }

  /// Get the status of a specific offline region.
  ///
  /// Returns a map with:
  /// - `regionId`: The region identifier
  /// - `exists`: Whether the region exists
  /// - `mapTilesReady`: Whether map tiles are downloaded
  /// - `routingTilesReady`: Whether routing tiles are downloaded
  /// - `estimatedSizeBytes`: Estimated size in bytes
  /// - `isComplete`: Whether download is complete
  @override
  Future<Map<String, dynamic>?> getOfflineRegionStatus({
    required String regionId,
  }) async {
    try {
      final args = <String, dynamic>{
        'regionId': regionId,
      };

      final result = await methodChannel.invokeMethod<Object?>(
        Methods.getOfflineRegionStatus,
        args,
      );

      if (result is Map) {
        return Map<String, dynamic>.from(result);
      }

      return null;
    } catch (e) {
      log('Error getting offline region status: $e');
      return null;
    }
  }

  /// List all offline regions with their status.
  ///
  /// Returns a map with:
  /// - `regions`: List of region status maps
  /// - `totalCount`: Total number of regions
  /// - `totalSizeBytes`: Total size of all regions in bytes
  @override
  Future<Map<String, dynamic>?> listOfflineRegions() async {
    try {
      final result = await methodChannel.invokeMethod<Object?>(
        Methods.listOfflineRegions,
      );

      if (result is Map) {
        return Map<String, dynamic>.from(result);
      }

      return null;
    } catch (e) {
      log('Error listing offline regions: $e');
      return null;
    }
  }

  @override
  Future<dynamic> registerRouteEventListener(
    ValueSetter<RouteEvent> listener,
  ) async {
    _onRouteEvent = listener;
  }

  /// Register a callback for full-screen navigation events
  @override
  Future<dynamic> registerFullScreenEventListener(
    ValueSetter<FullScreenEvent> listener,
  ) async {
    _onFullScreenEvent = listener;
  }

  // MARK: Static Marker Methods

  @override
  Future<bool?> addStaticMarkers({
    required List<StaticMarker> markers,
    MarkerConfiguration? configuration,
  }) async {
    try {
      final args = <String, dynamic>{
        'markers': markers.map((marker) => marker.toJson()).toList(),
      };
      
      if (configuration != null) {
        args['configuration'] = configuration.toJson();
      }
      
      final result = await methodChannel.invokeMethod(Methods.addStaticMarkers, args);
      return result as bool?;
    } catch (e) {
      log('Error adding static markers: $e');
      return false;
    }
  }

  @override
  Future<bool?> removeStaticMarkers({
    required List<String> markerIds,
  }) async {
    try {
      final args = <String, dynamic>{
        'markerIds': markerIds,
      };
      
      final result = await methodChannel.invokeMethod(Methods.removeStaticMarkers, args);
      return result as bool?;
    } catch (e) {
      log('Error removing static markers: $e');
      return false;
    }
  }

  @override
  Future<bool?> clearAllStaticMarkers() async {
    try {
      final result = await methodChannel.invokeMethod(Methods.clearAllStaticMarkers);
      return result as bool?;
    } catch (e) {
      log('Error clearing static markers: $e');
      return false;
    }
  }

  @override
  Future<bool?> updateMarkerConfiguration({
    required MarkerConfiguration configuration,
  }) async {
    try {
      final args = <String, dynamic>{
        'configuration': configuration.toJson(),
      };
      
      final result = await methodChannel.invokeMethod(Methods.updateMarkerConfiguration, args);
      return result as bool?;
    } catch (e) {
      log('Error updating marker configuration: $e');
      return false;
    }
  }

  @override
  Future<List<StaticMarker>?> getStaticMarkers() async {
    try {
      final result = await methodChannel.invokeMethod(Methods.getStaticMarkers);
      if (result is List) {
        return result
            .map((markerJson) => StaticMarker.fromJson(
                Map<String, dynamic>.from(markerJson as Map)))
            .toList();
      }
      return null;
    } catch (e) {
      log('Error getting static markers: $e');
      return null;
    }
  }

  @override
  Future<void> registerStaticMarkerTapListener(
    ValueSetter<StaticMarker> listener,
  ) async {
    _onMarkerTap = listener;
    _markerEventSubscription = markerEventsListener!.listen(_onMarkerTapData);
  }

  /// Unregisters the static marker tap listener and cancels the subscription.
  Future<void> unregisterStaticMarkerTapListener() async {
    await _markerEventSubscription.cancel();
    _onMarkerTap = null;
  }
  
  @override
  Future<Map<String, double>?> getMarkerScreenPosition(String markerId) async {
    try {
      final result = await methodChannel.invokeMethod(Methods.getMarkerScreenPosition, {
        'markerId': markerId,
      });
      
      if (result == null) return null;
      
      return {
        'x': (result['x'] as num).toDouble(),
        'y': (result['y'] as num).toDouble(),
      };
    } catch (e) {
      log('Error getting marker screen position: $e');
      return null;
    }
  }
  
  @override
  Future<Map<String, dynamic>?> getMapViewport() async {
    try {
      final result = await methodChannel.invokeMethod(Methods.getMapViewport);
      return result != null ? Map<String, dynamic>.from(result as Map) : null;
    } catch (e) {
      log('Error getting map viewport: $e');
      return null;
    }
  }

  /// Start Flutter-styled Drop-in Navigation (new approach)
  Future<bool?> startFlutterStyledNavigation(
    List<WayPoint> wayPoints,
    MapBoxOptions options, {
    bool showDebugOverlay = false,
  }) async {
    assert(wayPoints.length > 1, 'Error: WayPoints must be at least 2');

    final pointList = _getPointListFromWayPoints(wayPoints);
    var i = 0;
    final wayPointMap = {for (var e in pointList) i++: e};

    final args = options.toMap();
    args['wayPoints'] = wayPointMap;
    args['showDebugOverlay'] = showDebugOverlay;

    _routeEventSubscription = routeEventsListener!.listen(_onProgressData);
    final result = await methodChannel.invokeMethod('startFlutterNavigation', args);
    if (result is bool) return result;
    log(result.toString());
    return false;
  }

  /// Events Handling
  Stream<RouteEvent>? get routeEventsListener {
    return eventChannel
        .receiveBroadcastStream()
        .map((dynamic event) => _parseRouteEvent(event as String));
  }

  /// Static Marker Events Handling
  Stream<StaticMarker>? get markerEventsListener {
    return markerEventChannel
        .receiveBroadcastStream()
        .map((dynamic event) => _parseMarkerEvent(Map<String, dynamic>.from(event as Map)));
  }

  void _onProgressData(RouteEvent event) {
    if (_onRouteEvent != null) _onRouteEvent?.call(event);
    switch (event.eventType) {
      case MapBoxEvent.navigation_finished:
        _routeEventSubscription.cancel();
        break;
      // ignore: no_default_cases
      default:
        break;
    }
  }

  void _onMarkerTapData(StaticMarker marker) {
    if (_onMarkerTap != null) _onMarkerTap?.call(marker);
  }

  RouteEvent _parseRouteEvent(String jsonString) {
    RouteEvent event;
    final map = json.decode(jsonString);
    
    // Check if this is a full-screen event by looking at eventType
    if (map is Map<String, dynamic> && 
        (map['eventType'] == 'marker_tap_fullscreen' || map['eventType'] == 'map_tap_fullscreen')) {
      // The data field is now a JSON object, not a string
      final Map<String, dynamic> dataMap = Map<String, dynamic>.from(map['data'] as Map);
      final String dataString = json.encode(dataMap);
      _handleFullScreenEvent(dataString);
      
      // Create RouteEvent for backward compatibility
      final eventType = map['eventType'] == 'marker_tap_fullscreen' 
          ? MapBoxEvent.marker_tap_fullscreen 
          : MapBoxEvent.map_tap_fullscreen;
      
      event = RouteEvent(
        eventType: eventType,
        data: dataString,
      );
    } else {
      // Handle regular route events
      final progressEvent =
          RouteProgressEvent.fromJson(map as Map<String, dynamic>);
      if (progressEvent.isProgressEvent!) {
        event = RouteEvent(
          eventType: MapBoxEvent.progress_change,
          data: progressEvent,
        );
      } else {
        event = RouteEvent.fromJson(map);
      }
    }
    return event;
  }
  
  void _handleFullScreenEvent(String jsonString) {
    try {
      final fullScreenEvent = FullScreenEvent.fromJson(jsonString);
      if (_onFullScreenEvent != null) {
        _onFullScreenEvent!(fullScreenEvent);
      } else {
        log('Full-screen event listener not registered, ignoring event');
      }
    } catch (e) {
      log('Failed to parse full-screen event: $e');
    }
  }

  StaticMarker _parseMarkerEvent(Map<String, dynamic> markerData) {
    return StaticMarker.fromJson(markerData);
  }

  /// Dynamic Marker Events Handling
  Stream<DynamicMarker>? get dynamicMarkerEventsListener {
    return dynamicMarkerEventChannel
        .receiveBroadcastStream()
        .map((dynamic event) => _parseDynamicMarkerEvent(Map<String, dynamic>.from(event as Map)));
  }

  void _onDynamicMarkerEventData(DynamicMarker marker) {
    if (_onDynamicMarkerEvent != null) _onDynamicMarkerEvent?.call(marker);
  }

  DynamicMarker _parseDynamicMarkerEvent(Map<String, dynamic> eventData) {
    // The event data contains 'eventType' and 'marker' fields
    // Extract the marker data from the event
    final markerData = eventData['marker'] != null
        ? Map<String, dynamic>.from(eventData['marker'] as Map)
        : eventData;
    return DynamicMarker.fromJson(markerData);
  }

  @override
  Future<dynamic> registerDynamicMarkerEventListener(
    ValueSetter<DynamicMarker> listener,
  ) async {
    _onDynamicMarkerEvent = listener;
    _dynamicMarkerEventSubscription?.cancel();
    _dynamicMarkerEventSubscription = dynamicMarkerEventsListener?.listen(_onDynamicMarkerEventData);
    return true;
  }

  List<Map<String, Object?>> _getPointListFromWayPoints(
    List<WayPoint> wayPoints,
  ) {
    final pointList = <Map<String, Object?>>[];

    for (var i = 0; i < wayPoints.length; i++) {
      final wayPoint = wayPoints[i];
      assert(wayPoint.latitude != null, 'Error: waypoints need latitude');
      assert(wayPoint.longitude != null, 'Error: waypoints need longitude');

      final pointMap = <String, dynamic>{
        'Order': i,
        'Name': wayPoint.name,
        'Latitude': wayPoint.latitude,
        'Longitude': wayPoint.longitude,
        'IsSilent': wayPoint.isSilent,
      };
      pointList.add(pointMap);
    }
    return pointList;
  }

  /// Converts a platform Map (which may have Object? keys/values) to Map<String, dynamic>
  Map<String, dynamic> _convertMap(Map<dynamic, dynamic> map) {
    return map.map((key, value) {
      final stringKey = key?.toString() ?? '';
      if (value is Map) {
        return MapEntry(stringKey, _convertMap(value));
      } else if (value is List) {
        return MapEntry(stringKey, _convertList(value));
      } else {
        return MapEntry(stringKey, value);
      }
    });
  }

  /// Converts a platform List to List<dynamic> with proper map conversion
  List<dynamic> _convertList(List<dynamic> list) {
    return list.map((item) {
      if (item is Map) {
        return _convertMap(item);
      } else if (item is List) {
        return _convertList(item);
      } else {
        return item;
      }
    }).toList();
  }

  // MARK: Dynamic Marker Methods

  @override
  Future<bool?> addDynamicMarker({
    required DynamicMarker marker,
  }) async {
    try {
      final args = <String, dynamic>{
        'marker': marker.toJson(),
      };
      final result = await methodChannel.invokeMethod(
        Methods.addDynamicMarker,
        args,
      );
      return result as bool?;
    } catch (e) {
      log('Error adding dynamic marker: $e');
      return false;
    }
  }

  @override
  Future<bool?> addDynamicMarkers({
    required List<DynamicMarker> markers,
  }) async {
    try {
      final args = <String, dynamic>{
        'markers': markers.map((m) => m.toJson()).toList(),
      };
      final result = await methodChannel.invokeMethod(
        Methods.addDynamicMarkers,
        args,
      );
      return result as bool?;
    } catch (e) {
      log('Error adding dynamic markers: $e');
      return false;
    }
  }

  @override
  Future<bool?> updateDynamicMarkerPosition({
    required DynamicMarkerPositionUpdate update,
  }) async {
    try {
      final args = update.toJson();
      final result = await methodChannel.invokeMethod(
        Methods.updateDynamicMarkerPosition,
        args,
      );
      return result as bool?;
    } catch (e) {
      log('Error updating dynamic marker position: $e');
      return false;
    }
  }

  @override
  Future<bool?> batchUpdateDynamicMarkerPositions({
    required List<DynamicMarkerPositionUpdate> updates,
  }) async {
    try {
      final args = <String, dynamic>{
        'updates': updates.map((u) => u.toJson()).toList(),
      };
      final result = await methodChannel.invokeMethod(
        Methods.batchUpdateDynamicMarkerPositions,
        args,
      );
      return result as bool?;
    } catch (e) {
      log('Error batch updating dynamic marker positions: $e');
      return false;
    }
  }

  @override
  Future<bool?> updateDynamicMarker({
    required String markerId,
    String? title,
    String? snippet,
    String? iconId,
    bool? showTrail,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final args = <String, dynamic>{
        'markerId': markerId,
        if (title != null) 'title': title,
        if (snippet != null) 'snippet': snippet,
        if (iconId != null) 'iconId': iconId,
        if (showTrail != null) 'showTrail': showTrail,
        if (metadata != null) 'metadata': metadata,
      };
      final result = await methodChannel.invokeMethod(
        Methods.updateDynamicMarker,
        args,
      );
      return result as bool?;
    } catch (e) {
      log('Error updating dynamic marker: $e');
      return false;
    }
  }

  @override
  Future<bool?> removeDynamicMarker({
    required String markerId,
  }) async {
    try {
      final args = <String, dynamic>{
        'markerId': markerId,
      };
      final result = await methodChannel.invokeMethod(
        Methods.removeDynamicMarker,
        args,
      );
      return result as bool?;
    } catch (e) {
      log('Error removing dynamic marker: $e');
      return false;
    }
  }

  @override
  Future<bool?> removeDynamicMarkers({
    required List<String> markerIds,
  }) async {
    try {
      final args = <String, dynamic>{
        'markerIds': markerIds,
      };
      final result = await methodChannel.invokeMethod(
        Methods.removeDynamicMarkers,
        args,
      );
      return result as bool?;
    } catch (e) {
      log('Error removing dynamic markers: $e');
      return false;
    }
  }

  @override
  Future<bool?> clearAllDynamicMarkers() async {
    try {
      final result = await methodChannel.invokeMethod(
        Methods.clearAllDynamicMarkers,
      );
      return result as bool?;
    } catch (e) {
      log('Error clearing all dynamic markers: $e');
      return false;
    }
  }

  @override
  Future<DynamicMarker?> getDynamicMarker({
    required String markerId,
  }) async {
    try {
      final args = <String, dynamic>{
        'markerId': markerId,
      };
      final result = await methodChannel.invokeMethod(
        Methods.getDynamicMarker,
        args,
      );
      if (result == null) return null;
      return DynamicMarker.fromJson(Map<String, dynamic>.from(result as Map));
    } catch (e) {
      log('Error getting dynamic marker: $e');
      return null;
    }
  }

  @override
  Future<List<DynamicMarker>?> getDynamicMarkers() async {
    try {
      final result = await methodChannel.invokeMethod(
        Methods.getDynamicMarkers,
      );
      if (result == null) return null;
      return (result as List)
          .map((m) => DynamicMarker.fromJson(Map<String, dynamic>.from(m as Map)))
          .toList();
    } catch (e) {
      log('Error getting dynamic markers: $e');
      return null;
    }
  }

  @override
  Future<bool?> updateDynamicMarkerConfiguration({
    required DynamicMarkerConfiguration configuration,
  }) async {
    try {
      final args = configuration.toJson();
      final result = await methodChannel.invokeMethod(
        Methods.updateDynamicMarkerConfiguration,
        args,
      );
      return result as bool?;
    } catch (e) {
      log('Error updating dynamic marker configuration: $e');
      return false;
    }
  }

  @override
  Future<bool?> clearDynamicMarkerTrail({
    required String markerId,
  }) async {
    try {
      final args = <String, dynamic>{
        'markerId': markerId,
      };
      final result = await methodChannel.invokeMethod(
        Methods.clearDynamicMarkerTrail,
        args,
      );
      return result as bool?;
    } catch (e) {
      log('Error clearing dynamic marker trail: $e');
      return false;
    }
  }

  @override
  Future<bool?> clearAllDynamicMarkerTrails() async {
    try {
      final result = await methodChannel.invokeMethod(
        Methods.clearAllDynamicMarkerTrails,
      );
      return result as bool?;
    } catch (e) {
      log('Error clearing all dynamic marker trails: $e');
      return false;
    }
  }
}
