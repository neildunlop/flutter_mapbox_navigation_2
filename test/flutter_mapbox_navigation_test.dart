import 'package:flutter/widgets.dart';
import 'package:flutter_mapbox_navigation/flutter_mapbox_navigation.dart';
import 'package:flutter_mapbox_navigation/src/flutter_mapbox_navigation_method_channel.dart';
import 'package:flutter_mapbox_navigation/src/flutter_mapbox_navigation_platform_interface.dart';
import 'package:flutter_mapbox_navigation/src/models/dynamic_marker.dart';
import 'package:flutter_mapbox_navigation/src/models/dynamic_marker_configuration.dart';
import 'package:flutter_mapbox_navigation/src/models/dynamic_marker_position_update.dart';
import 'package:flutter_mapbox_navigation/src/models/waypoint_result.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockFlutterMapboxNavigationPlatform
    with MockPlatformInterfaceMixin
    implements FlutterMapboxNavigationPlatform {
  List<String> methodCalls = [];

  void reset() {
    methodCalls.clear();
  }

  @override
  Future<String?> getPlatformVersion() {
    methodCalls.add('getPlatformVersion');
    return Future.value('42');
  }

  @override
  Future<WaypointResult> addWayPoints({required List<WayPoint> wayPoints}) {
    methodCalls.add('addWayPoints');
    return Future.value(WaypointResult(success: true, waypointsAdded: wayPoints.length));
  }

  @override
  Future<bool?> enableOfflineRouting() {
    methodCalls.add('enableOfflineRouting');
    return Future.value(true);
  }

  @override
  Future<bool?> finishNavigation() {
    methodCalls.add('finishNavigation');
    return Future.value(true);
  }

  @override
  Future<double?> getDistanceRemaining() {
    methodCalls.add('getDistanceRemaining');
    return Future.value(1500.5);
  }

  @override
  Future<double?> getDurationRemaining() {
    methodCalls.add('getDurationRemaining');
    return Future.value(300.0);
  }

  @override
  Future<bool?> startFreeDrive(MapBoxOptions options) {
    methodCalls.add('startFreeDrive');
    return Future.value(true);
  }

  @override
  Future<bool?> startNavigation(
    List<WayPoint> wayPoints,
    MapBoxOptions options,
  ) {
    methodCalls.add('startNavigation');
    return Future.value(true);
  }

  @override
  Future<dynamic> registerRouteEventListener(
    ValueSetter<RouteEvent> listener,
  ) {
    methodCalls.add('registerRouteEventListener');
    return Future.value();
  }

  @override
  Future<bool> addStaticMarkers({
    required List<StaticMarker> markers,
    MarkerConfiguration? configuration,
  }) {
    methodCalls.add('addStaticMarkers');
    return Future.value(true);
  }

  @override
  Future<bool> removeStaticMarkers({required List<String> markerIds}) {
    methodCalls.add('removeStaticMarkers');
    return Future.value(true);
  }

  @override
  Future<bool> clearAllStaticMarkers() {
    methodCalls.add('clearAllStaticMarkers');
    return Future.value(true);
  }

  @override
  Future<bool> updateMarkerConfiguration({required MarkerConfiguration configuration}) {
    methodCalls.add('updateMarkerConfiguration');
    return Future.value(true);
  }

  @override
  Future<List<StaticMarker>?> getStaticMarkers() {
    methodCalls.add('getStaticMarkers');
    return Future.value([
      StaticMarker(
        id: 'test-marker',
        latitude: 51.5074,
        longitude: -0.1278,
        title: 'Test Marker',
        category: 'test',
      ),
    ]);
  }

  @override
  Future<dynamic> registerStaticMarkerTapListener(
    ValueSetter<StaticMarker> listener,
  ) {
    methodCalls.add('registerStaticMarkerTapListener');
    return Future.value();
  }

  @override
  Future<dynamic> registerFullScreenEventListener(
    ValueSetter<FullScreenEvent> listener,
  ) {
    methodCalls.add('registerFullScreenEventListener');
    return Future.value();
  }

  // Offline navigation methods
  @override
  Future<Map<String, dynamic>?> downloadOfflineRegion({
    required double southWestLat,
    required double southWestLng,
    required double northEastLat,
    required double northEastLng,
    int minZoom = 10,
    int maxZoom = 16,
    bool includeRoutingTiles = false,
    void Function(double)? onProgress,
  }) {
    methodCalls.add('downloadOfflineRegion');
    return Future.value({
      'success': true,
      'regionId': 'test_region',
      'resourceCount': 100,
    });
  }

  @override
  Future<bool> isOfflineRoutingAvailable({
    required double latitude,
    required double longitude,
  }) {
    methodCalls.add('isOfflineRoutingAvailable');
    return Future.value(true);
  }

  @override
  Future<bool?> deleteOfflineRegion({
    required double southWestLat,
    required double southWestLng,
    required double northEastLat,
    required double northEastLng,
  }) {
    methodCalls.add('deleteOfflineRegion');
    return Future.value(true);
  }

  @override
  Future<int> getOfflineCacheSize() {
    methodCalls.add('getOfflineCacheSize');
    return Future.value(1024000);
  }

  @override
  Future<bool?> clearOfflineCache() {
    methodCalls.add('clearOfflineCache');
    return Future.value(true);
  }

  @override
  Future<Map<String, dynamic>?> getOfflineRegionStatus({
    required String regionId,
  }) {
    methodCalls.add('getOfflineRegionStatus');
    return Future.value({
      'regionId': regionId,
      'exists': true,
      'isComplete': true,
    });
  }

  @override
  Future<Map<String, dynamic>?> listOfflineRegions() {
    methodCalls.add('listOfflineRegions');
    return Future.value({
      'regions': [],
      'totalCount': 0,
      'totalSizeBytes': 0,
    });
  }

  @override
  Future<Map<String, double>?> getMarkerScreenPosition(String markerId) {
    methodCalls.add('getMarkerScreenPosition');
    return Future.value({'x': 100.0, 'y': 200.0});
  }

  @override
  Future<Map<String, dynamic>?> getMapViewport() {
    methodCalls.add('getMapViewport');
    return Future.value({
      'centerLat': 51.5074,
      'centerLng': -0.1278,
      'zoom': 15.0,
      'width': 400.0,
      'height': 800.0,
      'bearing': 45.0,
      'tilt': 30.0,
    });
  }

  // MARK: - Dynamic Marker Methods

  @override
  Future<bool?> addDynamicMarker({required DynamicMarker marker}) {
    methodCalls.add('addDynamicMarker');
    return Future.value(true);
  }

  @override
  Future<bool?> addDynamicMarkers({required List<DynamicMarker> markers}) {
    methodCalls.add('addDynamicMarkers');
    return Future.value(true);
  }

  @override
  Future<bool?> updateDynamicMarkerPosition({
    required DynamicMarkerPositionUpdate update,
  }) {
    methodCalls.add('updateDynamicMarkerPosition');
    return Future.value(true);
  }

  @override
  Future<bool?> batchUpdateDynamicMarkerPositions({
    required List<DynamicMarkerPositionUpdate> updates,
  }) {
    methodCalls.add('batchUpdateDynamicMarkerPositions');
    return Future.value(true);
  }

  @override
  Future<bool?> updateDynamicMarker({
    required String markerId,
    String? title,
    String? snippet,
    String? iconId,
    bool? showTrail,
    Map<String, dynamic>? metadata,
  }) {
    methodCalls.add('updateDynamicMarker');
    return Future.value(true);
  }

  @override
  Future<bool?> removeDynamicMarker({required String markerId}) {
    methodCalls.add('removeDynamicMarker');
    return Future.value(true);
  }

  @override
  Future<bool?> removeDynamicMarkers({required List<String> markerIds}) {
    methodCalls.add('removeDynamicMarkers');
    return Future.value(true);
  }

  @override
  Future<bool?> clearAllDynamicMarkers() {
    methodCalls.add('clearAllDynamicMarkers');
    return Future.value(true);
  }

  @override
  Future<DynamicMarker?> getDynamicMarker({required String markerId}) {
    methodCalls.add('getDynamicMarker');
    return Future.value(DynamicMarker(
      id: markerId,
      latitude: 51.5074,
      longitude: -0.1278,
      title: 'Test Dynamic Marker',
      category: 'vehicle',
    ));
  }

  @override
  Future<List<DynamicMarker>?> getDynamicMarkers() {
    methodCalls.add('getDynamicMarkers');
    return Future.value([
      DynamicMarker(
        id: 'test-dynamic-marker',
        latitude: 51.5074,
        longitude: -0.1278,
        title: 'Test Dynamic Marker',
        category: 'vehicle',
      ),
    ]);
  }

  @override
  Future<bool?> updateDynamicMarkerConfiguration({
    required DynamicMarkerConfiguration configuration,
  }) {
    methodCalls.add('updateDynamicMarkerConfiguration');
    return Future.value(true);
  }

  @override
  Future<bool?> clearDynamicMarkerTrail({required String markerId}) {
    methodCalls.add('clearDynamicMarkerTrail');
    return Future.value(true);
  }

  @override
  Future<bool?> clearAllDynamicMarkerTrails() {
    methodCalls.add('clearAllDynamicMarkerTrails');
    return Future.value(true);
  }

  @override
  Future<dynamic> registerDynamicMarkerEventListener(
    ValueSetter<DynamicMarker> listener,
  ) {
    methodCalls.add('registerDynamicMarkerEventListener');
    return Future.value();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final initialPlatform = FlutterMapboxNavigationPlatform.instance;
  late MockFlutterMapboxNavigationPlatform mockPlatform;
  late MapBoxNavigation navigation;

  setUp(() {
    mockPlatform = MockFlutterMapboxNavigationPlatform();
    FlutterMapboxNavigationPlatform.instance = mockPlatform;
    navigation = MapBoxNavigation.instance;
  });

  tearDown(() {
    FlutterMapboxNavigationPlatform.instance = initialPlatform;
  });

  group('MapBoxNavigation', () {
    test('$MethodChannelFlutterMapboxNavigation is the default instance', () {
      expect(
        initialPlatform,
        isInstanceOf<MethodChannelFlutterMapboxNavigation>(),
      );
    });

    test('instance returns singleton', () {
      final instance1 = MapBoxNavigation.instance;
      final instance2 = MapBoxNavigation.instance;

      expect(identical(instance1, instance2), isTrue);
    });
  });

  group('Default Options', () {
    test('getDefaultOptions returns default options', () {
      final options = navigation.getDefaultOptions();

      expect(options, isNotNull);
      expect(options.zoom, 15);
      expect(options.mode, MapBoxNavigationMode.drivingWithTraffic);
    });

    test('setDefaultOptions updates default options', () {
      final customOptions = MapBoxOptions(
        zoom: 18,
        mode: MapBoxNavigationMode.walking,
        units: VoiceUnits.metric,
      );

      navigation.setDefaultOptions(customOptions);
      final options = navigation.getDefaultOptions();

      expect(options.zoom, 18);
      expect(options.mode, MapBoxNavigationMode.walking);
    });
  });

  group('Platform Information', () {
    test('getPlatformVersion calls platform', () async {
      final version = await navigation.getPlatformVersion();

      expect(version, '42');
      expect(mockPlatform.methodCalls.contains('getPlatformVersion'), isTrue);
    });
  });

  group('Navigation Metrics', () {
    test('getDistanceRemaining returns distance', () async {
      final distance = await navigation.getDistanceRemaining();

      expect(distance, 1500.5);
      expect(mockPlatform.methodCalls.contains('getDistanceRemaining'), isTrue);
    });

    test('getDurationRemaining returns duration', () async {
      final duration = await navigation.getDurationRemaining();

      expect(duration, 300.0);
      expect(mockPlatform.methodCalls.contains('getDurationRemaining'), isTrue);
    });
  });

  group('Waypoint Management', () {
    test('addWayPoints calls platform with waypoints', () async {
      final wayPoints = [
        WayPoint(name: 'Stop 1', latitude: 51.5, longitude: -0.1),
        WayPoint(name: 'Stop 2', latitude: 51.6, longitude: -0.2),
      ];

      final result = await navigation.addWayPoints(wayPoints: wayPoints);

      expect(result.success, isTrue);
      expect(result.waypointsAdded, 2);
      expect(mockPlatform.methodCalls.contains('addWayPoints'), isTrue);
    });
  });

  group('Navigation Control', () {
    test('startFreeDrive calls platform with options', () async {
      final result = await navigation.startFreeDrive();

      expect(result, isTrue);
      expect(mockPlatform.methodCalls.contains('startFreeDrive'), isTrue);
    });

    test('startFreeDrive uses custom options', () async {
      final customOptions = MapBoxOptions(zoom: 18, units: VoiceUnits.metric);

      final result = await navigation.startFreeDrive(options: customOptions);

      expect(result, isTrue);
      expect(mockPlatform.methodCalls.contains('startFreeDrive'), isTrue);
    });

    test('startNavigation calls platform with waypoints and options', () async {
      final wayPoints = [
        WayPoint(name: 'Origin', latitude: 51.5, longitude: -0.1),
        WayPoint(name: 'Destination', latitude: 51.6, longitude: -0.2),
      ];

      final result = await navigation.startNavigation(wayPoints: wayPoints);

      expect(result, isTrue);
      expect(mockPlatform.methodCalls.contains('startNavigation'), isTrue);
    });

    test('startNavigation uses custom options', () async {
      final wayPoints = [
        WayPoint(name: 'Origin', latitude: 51.5, longitude: -0.1),
        WayPoint(name: 'Destination', latitude: 51.6, longitude: -0.2),
      ];
      final customOptions = MapBoxOptions(simulateRoute: true, units: VoiceUnits.metric);

      final result = await navigation.startNavigation(
        wayPoints: wayPoints,
        options: customOptions,
      );

      expect(result, isTrue);
    });

    test('finishNavigation calls platform', () async {
      final result = await navigation.finishNavigation();

      expect(result, isTrue);
      expect(mockPlatform.methodCalls.contains('finishNavigation'), isTrue);
    });
  });

  group('Offline Routing', () {
    test('enableOfflineRouting calls platform', () async {
      // ignore: deprecated_member_use_from_same_package
      final result = await navigation.enableOfflineRouting();

      expect(result, isTrue);
      expect(mockPlatform.methodCalls.contains('enableOfflineRouting'), isTrue);
    });

    test('downloadOfflineRegion calls platform with bounds', () async {
      final result = await navigation.downloadOfflineRegion(
        southWestLat: 51.0,
        southWestLng: -0.5,
        northEastLat: 52.0,
        northEastLng: 0.5,
      );

      expect(result, isNotNull);
      expect(result!['success'], isTrue);
      expect(result['regionId'], 'test_region');
      expect(mockPlatform.methodCalls.contains('downloadOfflineRegion'), isTrue);
    });

    test('downloadOfflineRegion with custom zoom levels', () async {
      final result = await navigation.downloadOfflineRegion(
        southWestLat: 51.0,
        southWestLng: -0.5,
        northEastLat: 52.0,
        northEastLng: 0.5,
        minZoom: 8,
        maxZoom: 18,
        includeRoutingTiles: true,
      );

      expect(result, isNotNull);
      expect(result!['success'], isTrue);
    });

    test('isOfflineRoutingAvailable checks location', () async {
      final result = await navigation.isOfflineRoutingAvailable(
        latitude: 51.5074,
        longitude: -0.1278,
      );

      expect(result, isTrue);
      expect(mockPlatform.methodCalls.contains('isOfflineRoutingAvailable'), isTrue);
    });

    test('deleteOfflineRegion calls platform', () async {
      final result = await navigation.deleteOfflineRegion(
        southWestLat: 51.0,
        southWestLng: -0.5,
        northEastLat: 52.0,
        northEastLng: 0.5,
      );

      expect(result, isTrue);
      expect(mockPlatform.methodCalls.contains('deleteOfflineRegion'), isTrue);
    });

    test('getOfflineCacheSize returns size', () async {
      final size = await navigation.getOfflineCacheSize();

      expect(size, 1024000);
      expect(mockPlatform.methodCalls.contains('getOfflineCacheSize'), isTrue);
    });

    test('clearOfflineCache calls platform', () async {
      final result = await navigation.clearOfflineCache();

      expect(result, isTrue);
      expect(mockPlatform.methodCalls.contains('clearOfflineCache'), isTrue);
    });

    test('getOfflineRegionStatus returns status', () async {
      final status = await navigation.getOfflineRegionStatus(
        regionId: 'test-region',
      );

      expect(status, isNotNull);
      expect(status!['regionId'], 'test-region');
      expect(status['exists'], isTrue);
      expect(status['isComplete'], isTrue);
      expect(mockPlatform.methodCalls.contains('getOfflineRegionStatus'), isTrue);
    });

    test('listOfflineRegions returns regions', () async {
      final result = await navigation.listOfflineRegions();

      expect(result, isNotNull);
      expect(result!['totalCount'], 0);
      expect(result['regions'], isA<List>());
      expect(mockPlatform.methodCalls.contains('listOfflineRegions'), isTrue);
    });
  });

  group('Event Listeners', () {
    test('registerRouteEventListener registers callback', () async {
      RouteEvent? capturedEvent;

      await navigation.registerRouteEventListener((event) {
        capturedEvent = event;
      });

      expect(mockPlatform.methodCalls.contains('registerRouteEventListener'), isTrue);
    });

    test('registerFullScreenEventListener registers callback', () async {
      FullScreenEvent? capturedEvent;

      await navigation.registerFullScreenEventListener((event) {
        capturedEvent = event;
      });

      expect(mockPlatform.methodCalls.contains('registerFullScreenEventListener'), isTrue);
    });
  });

  group('Static Markers', () {
    test('addStaticMarkers calls platform with markers', () async {
      final markers = [
        StaticMarker(
          id: 'marker-1',
          latitude: 51.5074,
          longitude: -0.1278,
          title: 'Marker 1',
          category: 'test',
        ),
      ];

      final result = await navigation.addStaticMarkers(markers: markers);

      expect(result, isTrue);
      expect(mockPlatform.methodCalls.contains('addStaticMarkers'), isTrue);
    });

    test('addStaticMarkers with configuration', () async {
      final markers = [
        StaticMarker(
          id: 'marker-1',
          latitude: 51.5074,
          longitude: -0.1278,
          title: 'Marker 1',
          category: 'test',
        ),
      ];
      const config = MarkerConfiguration(
        enableClustering: true,
        minZoomLevel: 12.0,
      );

      final result = await navigation.addStaticMarkers(
        markers: markers,
        configuration: config,
      );

      expect(result, isTrue);
    });

    test('removeStaticMarkers calls platform with ids', () async {
      final result = await navigation.removeStaticMarkers(
        markerIds: ['marker-1', 'marker-2'],
      );

      expect(result, isTrue);
      expect(mockPlatform.methodCalls.contains('removeStaticMarkers'), isTrue);
    });

    test('clearAllStaticMarkers calls platform', () async {
      final result = await navigation.clearAllStaticMarkers();

      expect(result, isTrue);
      expect(mockPlatform.methodCalls.contains('clearAllStaticMarkers'), isTrue);
    });

    test('updateMarkerConfiguration calls platform', () async {
      const config = MarkerConfiguration(
        enableClustering: false,
        minZoomLevel: 15.0,
      );

      final result = await navigation.updateMarkerConfiguration(
        configuration: config,
      );

      expect(result, isTrue);
      expect(mockPlatform.methodCalls.contains('updateMarkerConfiguration'), isTrue);
    });

    test('getStaticMarkers returns markers', () async {
      final markers = await navigation.getStaticMarkers();

      expect(markers, isNotNull);
      expect(markers!.length, 1);
      expect(markers[0].id, 'test-marker');
      expect(mockPlatform.methodCalls.contains('getStaticMarkers'), isTrue);
    });

    test('registerStaticMarkerTapListener registers callback', () async {
      StaticMarker? capturedMarker;

      await navigation.registerStaticMarkerTapListener((marker) {
        capturedMarker = marker;
      });

      expect(mockPlatform.methodCalls.contains('registerStaticMarkerTapListener'), isTrue);
    });
  });

  group('Map Viewport', () {
    test('getMarkerScreenPosition returns offset', () async {
      final position = await navigation.getMarkerScreenPosition('marker-1');

      expect(position, isNotNull);
      expect(position!.dx, 100.0);
      expect(position.dy, 200.0);
      expect(mockPlatform.methodCalls.contains('getMarkerScreenPosition'), isTrue);
    });

    test('getMarkerScreenPosition returns null for null result', () async {
      // Create a mock that returns null
      final nullMock = _NullMarkerPositionMock();
      FlutterMapboxNavigationPlatform.instance = nullMock;

      final position = await navigation.getMarkerScreenPosition('non-existent');

      expect(position, isNull);
    });

    test('getMapViewport returns viewport data', () async {
      final viewport = await navigation.getMapViewport();

      expect(viewport, isNotNull);
      expect(viewport!.center.latitude, 51.5074);
      expect(viewport.center.longitude, -0.1278);
      expect(viewport.zoomLevel, 15.0);
      expect(viewport.size.width, 400.0);
      expect(viewport.size.height, 800.0);
      expect(viewport.bearing, 45.0);
      expect(viewport.tilt, 30.0);
      expect(mockPlatform.methodCalls.contains('getMapViewport'), isTrue);
    });

    test('getMapViewport returns null for null result', () async {
      // Create a mock that returns null
      final nullMock = _NullViewportMock();
      FlutterMapboxNavigationPlatform.instance = nullMock;

      final viewport = await navigation.getMapViewport();

      expect(viewport, isNull);
    });
  });
}

// Helper mocks for null return testing
class _NullMarkerPositionMock extends MockFlutterMapboxNavigationPlatform {
  @override
  Future<Map<String, double>?> getMarkerScreenPosition(String markerId) {
    return Future.value(null);
  }
}

class _NullViewportMock extends MockFlutterMapboxNavigationPlatform {
  @override
  Future<Map<String, dynamic>?> getMapViewport() {
    return Future.value(null);
  }
}
