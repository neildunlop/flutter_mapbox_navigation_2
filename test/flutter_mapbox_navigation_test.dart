import 'package:flutter/widgets.dart';
import 'package:flutter_mapbox_navigation/flutter_mapbox_navigation.dart';
import 'package:flutter_mapbox_navigation/src/flutter_mapbox_navigation_method_channel.dart';
import 'package:flutter_mapbox_navigation/src/flutter_mapbox_navigation_platform_interface.dart';
import 'package:flutter_mapbox_navigation/src/models/waypoint_result.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockFlutterMapboxNavigationPlatform
    with MockPlatformInterfaceMixin
    implements FlutterMapboxNavigationPlatform {
  @override
  Future<String?> getPlatformVersion() => Future.value('42');

  @override
  Future<WaypointResult> addWayPoints({required List<WayPoint> wayPoints}) =>
      Future.value(WaypointResult(success: true, waypointsAdded: 0));

  @override
  Future<bool?> enableOfflineRouting() => Future.value(true);

  @override
  Future<bool?> finishNavigation() => Future.value(true);

  @override
  Future<double?> getDistanceRemaining() => Future.value(3.5);

  @override
  Future<double?> getDurationRemaining() => Future.value(50);

  @override
  Future<bool?> startFreeDrive(MapBoxOptions options) => Future.value(true);

  @override
  Future<bool?> startNavigation(
    List<WayPoint> wayPoints,
    MapBoxOptions options,
  ) =>
      Future.value();

  @override
  Future<dynamic> registerRouteEventListener(
    ValueSetter<RouteEvent> listener,
  ) =>
      Future.value();

  @override
  Future<bool> addStaticMarkers({
    required List<StaticMarker> markers,
    MarkerConfiguration? configuration,
  }) =>
      Future.value(true);

  @override
  Future<bool> removeStaticMarkers({required List<String> markerIds}) =>
      Future.value(true);

  @override
  Future<bool> clearAllStaticMarkers() => Future.value(true);

  @override
  Future<bool> updateMarkerConfiguration({required MarkerConfiguration configuration}) =>
      Future.value(true);

  @override
  Future<List<StaticMarker>?> getStaticMarkers() =>
      Future.value([]);

  @override
  Future<dynamic> registerStaticMarkerTapListener(
    ValueSetter<StaticMarker> listener,
  ) =>
      Future.value();
      
  @override
  Future<dynamic> registerFullScreenEventListener(
    ValueSetter<FullScreenEvent> listener,
  ) =>
      Future.value();
}

void main() {
  final initialPlatform = FlutterMapboxNavigationPlatform.instance;

  test('$MethodChannelFlutterMapboxNavigation is the default instance', () {
    expect(
      initialPlatform,
      isInstanceOf<MethodChannelFlutterMapboxNavigation>(),
    );
  });

  test('getPlatformVersion', () async {
    final flutterMapboxNavigationPlugin = MapBoxNavigation();
    final fakePlatform = MockFlutterMapboxNavigationPlatform();
    FlutterMapboxNavigationPlatform.instance = fakePlatform;

    expect(await flutterMapboxNavigationPlugin.getPlatformVersion(), '42');
  });
}
