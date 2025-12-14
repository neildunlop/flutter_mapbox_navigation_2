import 'package:flutter/widgets.dart';
import 'package:flutter_mapbox_navigation/src/flutter_mapbox_navigation_method_channel.dart';
import 'package:flutter_mapbox_navigation/src/flutter_mapbox_navigation_platform_interface.dart';
import 'package:flutter_mapbox_navigation/src/models/models.dart';
import 'package:flutter_mapbox_navigation/src/models/options.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

// Test implementation that extends FlutterMapboxNavigationPlatform
class TestFlutterMapboxNavigationPlatform extends FlutterMapboxNavigationPlatform
    with MockPlatformInterfaceMixin {
  @override
  Future<String?> getPlatformVersion() => Future.value('Test 1.0');
}

// Invalid implementation that doesn't use the token
class InvalidPlatform extends FlutterMapboxNavigationPlatform
    with MockPlatformInterfaceMixin {
  // This class is valid because it uses MockPlatformInterfaceMixin
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final initialPlatform = FlutterMapboxNavigationPlatform.instance;

  tearDown(() {
    // Reset to initial platform after each test
    FlutterMapboxNavigationPlatform.instance = initialPlatform;
  });

  group('FlutterMapboxNavigationPlatform', () {
    group('instance', () {
      test('default instance is MethodChannelFlutterMapboxNavigation', () {
        expect(
          FlutterMapboxNavigationPlatform.instance,
          isA<MethodChannelFlutterMapboxNavigation>(),
        );
      });

      test('can set valid instance', () {
        final testPlatform = TestFlutterMapboxNavigationPlatform();
        FlutterMapboxNavigationPlatform.instance = testPlatform;

        expect(FlutterMapboxNavigationPlatform.instance, testPlatform);
      });
    });

    group('Unimplemented methods', () {
      late FlutterMapboxNavigationPlatform platform;

      setUp(() {
        platform = TestFlutterMapboxNavigationPlatform();
      });

      test('getPlatformVersion can be overridden', () async {
        final version = await platform.getPlatformVersion();
        expect(version, 'Test 1.0');
      });

      test('getDistanceRemaining throws UnimplementedError', () {
        expect(
          () => platform.getDistanceRemaining(),
          throwsA(isA<UnimplementedError>()),
        );
      });

      test('getDurationRemaining throws UnimplementedError', () {
        expect(
          () => platform.getDurationRemaining(),
          throwsA(isA<UnimplementedError>()),
        );
      });

      test('startFreeDrive throws UnimplementedError', () {
        final options = MapBoxOptions(units: VoiceUnits.metric);
        expect(
          () => platform.startFreeDrive(options),
          throwsA(isA<UnimplementedError>()),
        );
      });

      test('startNavigation throws UnimplementedError', () {
        final wayPoints = [
          WayPoint(name: 'A', latitude: 0, longitude: 0),
          WayPoint(name: 'B', latitude: 1, longitude: 1),
        ];
        final options = MapBoxOptions(units: VoiceUnits.metric);
        expect(
          () => platform.startNavigation(wayPoints, options),
          throwsA(isA<UnimplementedError>()),
        );
      });

      test('addWayPoints throws UnimplementedError', () {
        expect(
          () => platform.addWayPoints(wayPoints: []),
          throwsA(isA<UnimplementedError>()),
        );
      });

      test('finishNavigation throws UnimplementedError', () {
        expect(
          () => platform.finishNavigation(),
          throwsA(isA<UnimplementedError>()),
        );
      });

      test('enableOfflineRouting throws UnimplementedError', () {
        expect(
          // ignore: deprecated_member_use_from_same_package
          () => platform.enableOfflineRouting(),
          throwsA(isA<UnimplementedError>()),
        );
      });

      test('downloadOfflineRegion throws UnimplementedError', () {
        expect(
          () => platform.downloadOfflineRegion(
            southWestLat: 0,
            southWestLng: 0,
            northEastLat: 1,
            northEastLng: 1,
          ),
          throwsA(isA<UnimplementedError>()),
        );
      });

      test('isOfflineRoutingAvailable throws UnimplementedError', () {
        expect(
          () => platform.isOfflineRoutingAvailable(
            latitude: 0,
            longitude: 0,
          ),
          throwsA(isA<UnimplementedError>()),
        );
      });

      test('deleteOfflineRegion throws UnimplementedError', () {
        expect(
          () => platform.deleteOfflineRegion(
            southWestLat: 0,
            southWestLng: 0,
            northEastLat: 1,
            northEastLng: 1,
          ),
          throwsA(isA<UnimplementedError>()),
        );
      });

      test('getOfflineCacheSize throws UnimplementedError', () {
        expect(
          () => platform.getOfflineCacheSize(),
          throwsA(isA<UnimplementedError>()),
        );
      });

      test('clearOfflineCache throws UnimplementedError', () {
        expect(
          () => platform.clearOfflineCache(),
          throwsA(isA<UnimplementedError>()),
        );
      });

      test('getOfflineRegionStatus throws UnimplementedError', () {
        expect(
          () => platform.getOfflineRegionStatus(regionId: 'test'),
          throwsA(isA<UnimplementedError>()),
        );
      });

      test('listOfflineRegions throws UnimplementedError', () {
        expect(
          () => platform.listOfflineRegions(),
          throwsA(isA<UnimplementedError>()),
        );
      });

      test('registerRouteEventListener throws UnimplementedError', () {
        expect(
          () => platform.registerRouteEventListener((event) {}),
          throwsA(isA<UnimplementedError>()),
        );
      });

      test('registerFullScreenEventListener throws UnimplementedError', () {
        expect(
          () => platform.registerFullScreenEventListener((event) {}),
          throwsA(isA<UnimplementedError>()),
        );
      });

      test('addStaticMarkers throws UnimplementedError', () {
        expect(
          () => platform.addStaticMarkers(markers: []),
          throwsA(isA<UnimplementedError>()),
        );
      });

      test('removeStaticMarkers throws UnimplementedError', () {
        expect(
          () => platform.removeStaticMarkers(markerIds: []),
          throwsA(isA<UnimplementedError>()),
        );
      });

      test('clearAllStaticMarkers throws UnimplementedError', () {
        expect(
          () => platform.clearAllStaticMarkers(),
          throwsA(isA<UnimplementedError>()),
        );
      });

      test('updateMarkerConfiguration throws UnimplementedError', () {
        expect(
          () => platform.updateMarkerConfiguration(
            configuration: const MarkerConfiguration(),
          ),
          throwsA(isA<UnimplementedError>()),
        );
      });

      test('getStaticMarkers throws UnimplementedError', () {
        expect(
          () => platform.getStaticMarkers(),
          throwsA(isA<UnimplementedError>()),
        );
      });

      test('registerStaticMarkerTapListener throws UnimplementedError', () {
        expect(
          () => platform.registerStaticMarkerTapListener((marker) {}),
          throwsA(isA<UnimplementedError>()),
        );
      });

      test('getMarkerScreenPosition throws UnimplementedError', () {
        expect(
          () => platform.getMarkerScreenPosition('marker-1'),
          throwsA(isA<UnimplementedError>()),
        );
      });

      test('getMapViewport throws UnimplementedError', () {
        expect(
          () => platform.getMapViewport(),
          throwsA(isA<UnimplementedError>()),
        );
      });
    });
  });
}
