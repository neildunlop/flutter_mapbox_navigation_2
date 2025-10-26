import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mapbox_navigation/src/flutter_mapbox_navigation_platform_interface.dart';
import 'package:flutter_mapbox_navigation/src/models/models.dart';
import 'package:flutter_mapbox_navigation/src/models/waypoint_result.dart';

/// An implementation of [FlutterMapboxNavigationPlatform]
/// that uses method channels.
class MethodChannelFlutterMapboxNavigation
    extends FlutterMapboxNavigationPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('flutter_mapbox_navigation');

  /// The event channel used to interact with the native platform.
  @visibleForTesting
  final eventChannel = const EventChannel('flutter_mapbox_navigation/events');

  /// The event channel used for static marker events.
  @visibleForTesting
  final markerEventChannel = const EventChannel('flutter_mapbox_navigation/marker_events');

  late StreamSubscription<RouteEvent> _routeEventSubscription;
  late StreamSubscription<StaticMarker> _markerEventSubscription;
  late ValueSetter<RouteEvent>? _onRouteEvent;
  late ValueSetter<StaticMarker>? _onMarkerTap;

  @override
  Future<String?> getPlatformVersion() async {
    final version =
        await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }

  @override
  Future<double?> getDistanceRemaining() async {
    final distance =
        await methodChannel.invokeMethod<double?>('getDistanceRemaining');
    return distance;
  }

  @override
  Future<double?> getDurationRemaining() async {
    final duration =
        await methodChannel.invokeMethod<double?>('getDurationRemaining');
    return duration;
  }

  @override
  Future<bool?> startFreeDrive(MapBoxOptions options) async {
    _routeEventSubscription = routeEventsListener!.listen(_onProgressData);
    final args = options.toMap();
    final result = await methodChannel.invokeMethod('startFreeDrive', args);
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
    final result = await methodChannel.invokeMethod('startNavigation', args);
    if (result is bool) return result;
    log(result.toString());
    return false;
  }

  @override
  Future<WaypointResult> addWayPoints({
    required List<WayPoint> wayPoints,
  }) async {
    assert(wayPoints.isNotEmpty, 'Error: WayPoints must be at least 1');
    try {
      final pointList = _getPointListFromWayPoints(wayPoints);
      var i = 0;
      final wayPointMap = {for (var e in pointList) i++: e};
      final args = <String, dynamic>{};
      args['wayPoints'] = wayPointMap;
      
      final result = await methodChannel.invokeMethod('addWayPoints', args);
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
    final success = await methodChannel.invokeMethod<bool?>('finishNavigation');
    return success;
  }

  /// Will download the navigation engine and the user's region
  /// to allow offline routing
  @override
  Future<bool?> enableOfflineRouting() async {
    final success =
        await methodChannel.invokeMethod<bool?>('enableOfflineRouting');
    return success;
  }

  @override
  Future<dynamic> registerRouteEventListener(
    ValueSetter<RouteEvent> listener,
  ) async {
    _onRouteEvent = listener;
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
      
      final result = await methodChannel.invokeMethod('addStaticMarkers', args);
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
      
      final result = await methodChannel.invokeMethod(
        'removeStaticMarkers',
        args,
      );
      return result as bool?;
    } catch (e) {
      log('Error removing static markers: $e');
      return false;
    }
  }

  @override
  Future<bool?> clearAllStaticMarkers() async {
    try {
      final result = await methodChannel.invokeMethod('clearAllStaticMarkers');
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
      
      final result = await methodChannel.invokeMethod(
        'updateMarkerConfiguration',
        args,
      );
      return result as bool?;
    } catch (e) {
      log('Error updating marker configuration: $e');
      return false;
    }
  }

  @override
  Future<List<StaticMarker>?> getStaticMarkers() async {
    try {
      final result = await methodChannel.invokeMethod('getStaticMarkers');
      if (result is List) {
        return result
            .map((markerJson) => StaticMarker.fromJson(markerJson as Map<String, dynamic>))
            .toList();
      }
      return null;
    } catch (e) {
      log('Error getting static markers: $e');
      return null;
    }
  }

  @override
  Future<dynamic> registerStaticMarkerTapListener(
    ValueSetter<StaticMarker> listener,
  ) async {
    _onMarkerTap = listener;
    _markerEventSubscription = markerEventsListener!.listen(_onMarkerTapData);
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
    return event;
  }

  StaticMarker _parseMarkerEvent(Map<String, dynamic> markerData) {
    return StaticMarker.fromJson(markerData);
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
}
