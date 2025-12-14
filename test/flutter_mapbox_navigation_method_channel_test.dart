import 'package:flutter/services.dart';
import 'package:flutter_mapbox_navigation/src/flutter_mapbox_navigation_method_channel.dart';
import 'package:flutter_mapbox_navigation/src/models/models.dart';
import 'package:flutter_mapbox_navigation/src/platform/channel_constants.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MethodChannelFlutterMapboxNavigation platform;
  late List<MethodCall> methodCalls;

  setUp(() {
    platform = MethodChannelFlutterMapboxNavigation();
    methodCalls = [];

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel(kMethodChannelName),
      (MethodCall methodCall) async {
        methodCalls.add(methodCall);

        switch (methodCall.method) {
          case 'getPlatformVersion':
            return 'Android 12';
          case 'getDistanceRemaining':
            return 1500.5;
          case 'getDurationRemaining':
            return 900.0;
          case 'startFreeDrive':
            return true;
          case 'startNavigation':
            return true;
          case 'addWayPoints':
            return {
              'success': true,
              'waypointsAdded': 2,
              'errorMessage': null,
            };
          case 'finishNavigation':
            return true;
          case 'enableOfflineRouting':
            return true;
          case 'downloadOfflineRegion':
            return {'success': true, 'regionId': 'test-region'};
          case 'isOfflineRoutingAvailable':
            return true;
          case 'deleteOfflineRegion':
            return true;
          case 'getOfflineCacheSize':
            return 1024000;
          case 'clearOfflineCache':
            return true;
          case 'getOfflineRegionStatus':
            return {
              'regionId': 'test-region',
              'exists': true,
              'isComplete': true,
            };
          case 'listOfflineRegions':
            return {
              'regions': [],
              'totalCount': 0,
              'totalSizeBytes': 0,
            };
          case 'addStaticMarkers':
            return true;
          case 'removeStaticMarkers':
            return true;
          case 'clearAllStaticMarkers':
            return true;
          case 'updateMarkerConfiguration':
            return true;
          case 'getStaticMarkers':
            return [
              {
                'id': 'marker-1',
                'latitude': 51.5074,
                'longitude': -0.1278,
                'title': 'Test Marker',
                'category': 'test',
              },
            ];
          case 'getMarkerScreenPosition':
            return {'x': 100.0, 'y': 200.0};
          case 'getMapViewport':
            return {
              'centerLatitude': 51.5074,
              'centerLongitude': -0.1278,
              'zoom': 15.0,
            };
          case 'startFlutterNavigation':
            return true;
          default:
            return null;
        }
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel(kMethodChannelName),
      null,
    );
  });

  group('MethodChannelFlutterMapboxNavigation', () {
    group('getPlatformVersion', () {
      test('should return platform version', () async {
        final version = await platform.getPlatformVersion();

        expect(version, 'Android 12');
        expect(methodCalls.any((c) => c.method == 'getPlatformVersion'), isTrue);
      });
    });

    group('getDistanceRemaining', () {
      test('should return remaining distance', () async {
        final distance = await platform.getDistanceRemaining();

        expect(distance, 1500.5);
        expect(
          methodCalls.any((c) => c.method == 'getDistanceRemaining'),
          isTrue,
        );
      });
    });

    group('getDurationRemaining', () {
      test('should return remaining duration', () async {
        final duration = await platform.getDurationRemaining();

        expect(duration, 900.0);
        expect(
          methodCalls.any((c) => c.method == 'getDurationRemaining'),
          isTrue,
        );
      });
    });

    group('finishNavigation', () {
      test('should finish navigation successfully', () async {
        final result = await platform.finishNavigation();

        expect(result, isTrue);
        expect(
          methodCalls.any((c) => c.method == 'finishNavigation'),
          isTrue,
        );
      });
    });

    group('enableOfflineRouting', () {
      test('should enable offline routing', () async {
        // ignore: deprecated_member_use_from_same_package
        final result = await platform.enableOfflineRouting();

        expect(result, isTrue);
        expect(
          methodCalls.any((c) => c.method == 'enableOfflineRouting'),
          isTrue,
        );
      });
    });

    group('downloadOfflineRegion', () {
      test('should download offline region with bounds', () async {
        final result = await platform.downloadOfflineRegion(
          southWestLat: 51.0,
          southWestLng: -0.5,
          northEastLat: 52.0,
          northEastLng: 0.5,
        );

        expect(result, isNotNull);
        expect(result!['success'], isTrue);

        final call = methodCalls.firstWhere(
          (c) => c.method == 'downloadOfflineRegion',
        );
        expect(call.arguments['southWestLat'], 51.0);
        expect(call.arguments['southWestLng'], -0.5);
        expect(call.arguments['northEastLat'], 52.0);
        expect(call.arguments['northEastLng'], 0.5);
      });

      test('should download with custom zoom levels', () async {
        await platform.downloadOfflineRegion(
          southWestLat: 51.0,
          southWestLng: -0.5,
          northEastLat: 52.0,
          northEastLng: 0.5,
          minZoom: 8,
          maxZoom: 18,
        );

        final call = methodCalls.firstWhere(
          (c) => c.method == 'downloadOfflineRegion',
        );
        expect(call.arguments['minZoom'], 8);
        expect(call.arguments['maxZoom'], 18);
      });

      test('should download with routing tiles option', () async {
        await platform.downloadOfflineRegion(
          southWestLat: 51.0,
          southWestLng: -0.5,
          northEastLat: 52.0,
          northEastLng: 0.5,
          includeRoutingTiles: false,
        );

        final call = methodCalls.firstWhere(
          (c) => c.method == 'downloadOfflineRegion',
        );
        expect(call.arguments['includeRoutingTiles'], isFalse);
      });
    });

    group('isOfflineRoutingAvailable', () {
      test('should check offline routing availability', () async {
        final result = await platform.isOfflineRoutingAvailable(
          latitude: 51.5074,
          longitude: -0.1278,
        );

        expect(result, isTrue);

        final call = methodCalls.firstWhere(
          (c) => c.method == 'isOfflineRoutingAvailable',
        );
        expect(call.arguments['latitude'], 51.5074);
        expect(call.arguments['longitude'], -0.1278);
      });
    });

    group('deleteOfflineRegion', () {
      test('should delete offline region', () async {
        final result = await platform.deleteOfflineRegion(
          southWestLat: 51.0,
          southWestLng: -0.5,
          northEastLat: 52.0,
          northEastLng: 0.5,
        );

        expect(result, isTrue);
        expect(
          methodCalls.any((c) => c.method == 'deleteOfflineRegion'),
          isTrue,
        );
      });
    });

    group('getOfflineCacheSize', () {
      test('should return cache size', () async {
        final size = await platform.getOfflineCacheSize();

        expect(size, 1024000);
        expect(
          methodCalls.any((c) => c.method == 'getOfflineCacheSize'),
          isTrue,
        );
      });
    });

    group('clearOfflineCache', () {
      test('should clear offline cache', () async {
        final result = await platform.clearOfflineCache();

        expect(result, isTrue);
        expect(
          methodCalls.any((c) => c.method == 'clearOfflineCache'),
          isTrue,
        );
      });
    });

    group('getOfflineRegionStatus', () {
      test('should return region status', () async {
        final result = await platform.getOfflineRegionStatus(
          regionId: 'test-region',
        );

        expect(result, isNotNull);
        expect(result!['regionId'], 'test-region');
        expect(result['exists'], isTrue);
        expect(result['isComplete'], isTrue);
      });
    });

    group('listOfflineRegions', () {
      test('should list offline regions', () async {
        final result = await platform.listOfflineRegions();

        expect(result, isNotNull);
        expect(result!['totalCount'], 0);
        expect(result['regions'], isA<List>());
      });
    });

    group('registerRouteEventListener', () {
      test('should register route event listener', () async {
        RouteEvent? capturedEvent;
        await platform.registerRouteEventListener((event) {
          capturedEvent = event;
        });

        // The listener is registered (no method call, just stores callback)
        expect(capturedEvent, isNull);
      });
    });

    group('registerFullScreenEventListener', () {
      test('should register full screen event listener', () async {
        FullScreenEvent? capturedEvent;
        await platform.registerFullScreenEventListener((event) {
          capturedEvent = event;
        });

        // The listener is registered (no method call, just stores callback)
        expect(capturedEvent, isNull);
      });
    });

    group('addStaticMarkers', () {
      test('should add static markers', () async {
        final markers = [
          StaticMarker(
            id: 'marker-1',
            latitude: 51.5074,
            longitude: -0.1278,
            title: 'Marker 1',
            category: 'test',
          ),
          StaticMarker(
            id: 'marker-2',
            latitude: 48.8566,
            longitude: 2.3522,
            title: 'Marker 2',
            category: 'test',
          ),
        ];

        final result = await platform.addStaticMarkers(markers: markers);

        expect(result, isTrue);
        expect(
          methodCalls.any((c) => c.method == 'addStaticMarkers'),
          isTrue,
        );

        final call = methodCalls.firstWhere(
          (c) => c.method == 'addStaticMarkers',
        );
        expect((call.arguments['markers'] as List).length, 2);
      });

      test('should add markers with configuration', () async {
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

        await platform.addStaticMarkers(
          markers: markers,
          configuration: config,
        );

        final call = methodCalls.firstWhere(
          (c) => c.method == 'addStaticMarkers',
        );
        expect(call.arguments['configuration'], isNotNull);
      });
    });

    group('removeStaticMarkers', () {
      test('should remove static markers by ids', () async {
        final result = await platform.removeStaticMarkers(
          markerIds: ['marker-1', 'marker-2'],
        );

        expect(result, isTrue);

        final call = methodCalls.firstWhere(
          (c) => c.method == 'removeStaticMarkers',
        );
        expect(call.arguments['markerIds'], ['marker-1', 'marker-2']);
      });
    });

    group('clearAllStaticMarkers', () {
      test('should clear all markers', () async {
        final result = await platform.clearAllStaticMarkers();

        expect(result, isTrue);
        expect(
          methodCalls.any((c) => c.method == 'clearAllStaticMarkers'),
          isTrue,
        );
      });
    });

    group('updateMarkerConfiguration', () {
      test('should update marker configuration', () async {
        const config = MarkerConfiguration(
          enableClustering: false,
          minZoomLevel: 15.0,
        );

        final result = await platform.updateMarkerConfiguration(
          configuration: config,
        );

        expect(result, isTrue);

        final call = methodCalls.firstWhere(
          (c) => c.method == 'updateMarkerConfiguration',
        );
        expect(call.arguments['configuration'], isNotNull);
      });
    });

    group('getStaticMarkers', () {
      test('should return list of markers', () async {
        final markers = await platform.getStaticMarkers();

        expect(markers, isNotNull);
        expect(markers!.length, 1);
        expect(markers[0].id, 'marker-1');
        expect(markers[0].title, 'Test Marker');
      });
    });

    group('getMarkerScreenPosition', () {
      test('should return screen position for marker', () async {
        final position = await platform.getMarkerScreenPosition('marker-1');

        expect(position, isNotNull);
        expect(position!['x'], 100.0);
        expect(position['y'], 200.0);
      });
    });

    group('getMapViewport', () {
      test('should return map viewport', () async {
        final viewport = await platform.getMapViewport();

        expect(viewport, isNotNull);
        expect(viewport!['centerLatitude'], 51.5074);
        expect(viewport['centerLongitude'], -0.1278);
        expect(viewport['zoom'], 15.0);
      });
    });

    group('addWayPoints', () {
      test('should add waypoints successfully', () async {
        final wayPoints = [
          WayPoint(name: 'Stop 1', latitude: 51.5, longitude: -0.1),
          WayPoint(name: 'Stop 2', latitude: 51.6, longitude: -0.2),
        ];

        final result = await platform.addWayPoints(wayPoints: wayPoints);

        expect(result.success, isTrue);
        expect(result.waypointsAdded, 2);
        expect(result.errorMessage, isNull);
      });

      test('should handle failure response', () async {
        // Override mock for this test
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
          const MethodChannel(kMethodChannelName),
          (MethodCall methodCall) async {
            if (methodCall.method == 'addWayPoints') {
              return {
                'success': false,
                'waypointsAdded': 0,
                'errorMessage': 'Network error',
              };
            }
            return null;
          },
        );

        final wayPoints = [
          WayPoint(name: 'Stop 1', latitude: 51.5, longitude: -0.1),
        ];

        final result = await platform.addWayPoints(wayPoints: wayPoints);

        expect(result.success, isFalse);
        expect(result.errorMessage, 'Network error');
      });
    });
  });

  group('Error handling', () {
    test('addStaticMarkers should return false on error', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel(kMethodChannelName),
        (MethodCall methodCall) async {
          if (methodCall.method == 'addStaticMarkers') {
            throw PlatformException(code: 'ERROR');
          }
          return null;
        },
      );

      final result = await platform.addStaticMarkers(markers: []);

      expect(result, isFalse);
    });

    test('removeStaticMarkers should return false on error', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel(kMethodChannelName),
        (MethodCall methodCall) async {
          if (methodCall.method == 'removeStaticMarkers') {
            throw PlatformException(code: 'ERROR');
          }
          return null;
        },
      );

      final result = await platform.removeStaticMarkers(markerIds: []);

      expect(result, isFalse);
    });

    test('clearAllStaticMarkers should return false on error', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel(kMethodChannelName),
        (MethodCall methodCall) async {
          if (methodCall.method == 'clearAllStaticMarkers') {
            throw PlatformException(code: 'ERROR');
          }
          return null;
        },
      );

      final result = await platform.clearAllStaticMarkers();

      expect(result, isFalse);
    });

    test('getStaticMarkers should return null on error', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel(kMethodChannelName),
        (MethodCall methodCall) async {
          if (methodCall.method == 'getStaticMarkers') {
            throw PlatformException(code: 'ERROR');
          }
          return null;
        },
      );

      final result = await platform.getStaticMarkers();

      expect(result, isNull);
    });

    test('getMarkerScreenPosition should return null on error', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel(kMethodChannelName),
        (MethodCall methodCall) async {
          if (methodCall.method == 'getMarkerScreenPosition') {
            throw PlatformException(code: 'ERROR');
          }
          return null;
        },
      );

      final result = await platform.getMarkerScreenPosition('marker-1');

      expect(result, isNull);
    });

    test('getMapViewport should return null on error', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel(kMethodChannelName),
        (MethodCall methodCall) async {
          if (methodCall.method == 'getMapViewport') {
            throw PlatformException(code: 'ERROR');
          }
          return null;
        },
      );

      final result = await platform.getMapViewport();

      expect(result, isNull);
    });

    test('isOfflineRoutingAvailable should return false on error', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel(kMethodChannelName),
        (MethodCall methodCall) async {
          if (methodCall.method == 'isOfflineRoutingAvailable') {
            throw PlatformException(code: 'ERROR');
          }
          return null;
        },
      );

      final result = await platform.isOfflineRoutingAvailable(
        latitude: 51.5074,
        longitude: -0.1278,
      );

      expect(result, isFalse);
    });

    test('deleteOfflineRegion should return false on error', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel(kMethodChannelName),
        (MethodCall methodCall) async {
          if (methodCall.method == 'deleteOfflineRegion') {
            throw PlatformException(code: 'ERROR');
          }
          return null;
        },
      );

      final result = await platform.deleteOfflineRegion(
        southWestLat: 51.0,
        southWestLng: -0.5,
        northEastLat: 52.0,
        northEastLng: 0.5,
      );

      expect(result, isFalse);
    });

    test('getOfflineCacheSize should return 0 on error', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel(kMethodChannelName),
        (MethodCall methodCall) async {
          if (methodCall.method == 'getOfflineCacheSize') {
            throw PlatformException(code: 'ERROR');
          }
          return null;
        },
      );

      final result = await platform.getOfflineCacheSize();

      expect(result, 0);
    });

    test('clearOfflineCache should return false on error', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel(kMethodChannelName),
        (MethodCall methodCall) async {
          if (methodCall.method == 'clearOfflineCache') {
            throw PlatformException(code: 'ERROR');
          }
          return null;
        },
      );

      final result = await platform.clearOfflineCache();

      expect(result, isFalse);
    });

    test('getOfflineRegionStatus should return null on error', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel(kMethodChannelName),
        (MethodCall methodCall) async {
          if (methodCall.method == 'getOfflineRegionStatus') {
            throw PlatformException(code: 'ERROR');
          }
          return null;
        },
      );

      final result = await platform.getOfflineRegionStatus(regionId: 'test');

      expect(result, isNull);
    });

    test('listOfflineRegions should return null on error', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel(kMethodChannelName),
        (MethodCall methodCall) async {
          if (methodCall.method == 'listOfflineRegions') {
            throw PlatformException(code: 'ERROR');
          }
          return null;
        },
      );

      final result = await platform.listOfflineRegions();

      expect(result, isNull);
    });

    test('downloadOfflineRegion should return null on error', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel(kMethodChannelName),
        (MethodCall methodCall) async {
          if (methodCall.method == 'downloadOfflineRegion') {
            throw PlatformException(code: 'ERROR');
          }
          return null;
        },
      );

      final result = await platform.downloadOfflineRegion(
        southWestLat: 51.0,
        southWestLng: -0.5,
        northEastLat: 52.0,
        northEastLng: 0.5,
      );

      expect(result, isNull);
    });

    test('updateMarkerConfiguration should return false on error', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel(kMethodChannelName),
        (MethodCall methodCall) async {
          if (methodCall.method == 'updateMarkerConfiguration') {
            throw PlatformException(code: 'ERROR');
          }
          return null;
        },
      );

      final result = await platform.updateMarkerConfiguration(
        configuration: const MarkerConfiguration(),
      );

      expect(result, isFalse);
    });
  });

  group('Channel constants', () {
    test('should use correct method channel name', () {
      expect(platform.methodChannel.name, kMethodChannelName);
    });

    test('should use correct event channel name', () {
      expect(platform.eventChannel.name, kEventChannelName);
    });

    test('should use correct marker event channel name', () {
      expect(platform.markerEventChannel.name, kMarkerEventChannelName);
    });
  });
}
