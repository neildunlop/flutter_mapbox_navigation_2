import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_mapbox_navigation/src/flutter_mapbox_navigation_method_channel.dart';
import 'package:flutter_mapbox_navigation/src/models/dynamic_marker.dart';
import 'package:flutter_mapbox_navigation/src/models/dynamic_marker_configuration.dart';
import 'package:flutter_mapbox_navigation/src/models/dynamic_marker_position_update.dart';
import 'package:flutter_mapbox_navigation/src/platform/channel_constants.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MethodChannelFlutterMapboxNavigation platform;
  late List<MethodCall> calls;

  setUp(() {
    platform = MethodChannelFlutterMapboxNavigation();
    calls = [];

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel(kMethodChannelName),
      (MethodCall call) async {
        calls.add(call);
        switch (call.method) {
          case 'addDynamicMarker':
            return true;
          case 'addDynamicMarkers':
            return true;
          case 'updateDynamicMarkerPosition':
            return true;
          case 'batchUpdateDynamicMarkerPositions':
            return true;
          case 'updateDynamicMarker':
            return true;
          case 'removeDynamicMarker':
            return true;
          case 'removeDynamicMarkers':
            return true;
          case 'clearAllDynamicMarkers':
            return true;
          case 'getDynamicMarker':
            return {
              'id': 'vehicle_1',
              'latitude': 37.7749,
              'longitude': -122.4194,
              'title': 'Vehicle 1',
              'category': 'vehicle',
              'heading': 90.0,
              'speed': 15.0,
              'state': 'tracking',
              'showTrail': false,
              'trailLength': 50,
              'lastUpdated': DateTime.now().toIso8601String(),
            };
          case 'getDynamicMarkers':
            return [
              {
                'id': 'vehicle_1',
                'latitude': 37.7749,
                'longitude': -122.4194,
                'title': 'Vehicle 1',
                'category': 'vehicle',
                'state': 'tracking',
                'showTrail': false,
                'trailLength': 50,
                'lastUpdated': DateTime.now().toIso8601String(),
              },
              {
                'id': 'vehicle_2',
                'latitude': 37.7849,
                'longitude': -122.4094,
                'title': 'Vehicle 2',
                'category': 'vehicle',
                'state': 'tracking',
                'showTrail': true,
                'trailLength': 50,
                'lastUpdated': DateTime.now().toIso8601String(),
              },
            ];
          case 'updateDynamicMarkerConfiguration':
            return true;
          case 'clearDynamicMarkerTrail':
            return true;
          case 'clearAllDynamicMarkerTrails':
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

  group('Dynamic Marker Platform Methods', () {
    group('addDynamicMarker', () {
      test('should invoke addDynamicMarker method with correct arguments', () async {
        final marker = DynamicMarker(
          id: 'vehicle_1',
          latitude: 37.7749,
          longitude: -122.4194,
          title: 'Vehicle 1',
          category: 'vehicle',
          heading: 90.0,
          speed: 15.0,
        );

        final result = await platform.addDynamicMarker(marker: marker);

        expect(result, true);
        expect(calls.length, 1);
        expect(calls.first.method, Methods.addDynamicMarker);
        final args = calls.first.arguments as Map<dynamic, dynamic>;
        expect(args['marker']['id'], 'vehicle_1');
        expect(args['marker']['latitude'], 37.7749);
        expect(args['marker']['longitude'], -122.4194);
      });
    });

    group('addDynamicMarkers', () {
      test('should invoke addDynamicMarkers method with multiple markers', () async {
        final markers = [
          DynamicMarker(
            id: 'vehicle_1',
            latitude: 37.7749,
            longitude: -122.4194,
            title: 'Vehicle 1',
            category: 'vehicle',
          ),
          DynamicMarker(
            id: 'vehicle_2',
            latitude: 37.7849,
            longitude: -122.4094,
            title: 'Vehicle 2',
            category: 'vehicle',
          ),
        ];

        final result = await platform.addDynamicMarkers(markers: markers);

        expect(result, true);
        expect(calls.length, 1);
        expect(calls.first.method, Methods.addDynamicMarkers);
        final args = calls.first.arguments as Map<dynamic, dynamic>;
        expect((args['markers'] as List).length, 2);
      });
    });

    group('updateDynamicMarkerPosition', () {
      test('should invoke updateDynamicMarkerPosition with correct arguments', () async {
        final update = DynamicMarkerPositionUpdate(
          markerId: 'vehicle_1',
          latitude: 37.7750,
          longitude: -122.4195,
          timestamp: DateTime(2024, 1, 15, 10, 30, 45),
          heading: 95.0,
          speed: 18.0,
        );

        final result = await platform.updateDynamicMarkerPosition(update: update);

        expect(result, true);
        expect(calls.length, 1);
        expect(calls.first.method, Methods.updateDynamicMarkerPosition);
        final args = calls.first.arguments as Map<dynamic, dynamic>;
        expect(args['markerId'], 'vehicle_1');
        expect(args['latitude'], 37.7750);
        expect(args['longitude'], -122.4195);
      });
    });

    group('batchUpdateDynamicMarkerPositions', () {
      test('should invoke batchUpdateDynamicMarkerPositions with multiple updates', () async {
        final timestamp = DateTime.now();
        final updates = [
          DynamicMarkerPositionUpdate(
            markerId: 'vehicle_1',
            latitude: 37.7750,
            longitude: -122.4195,
            timestamp: timestamp,
          ),
          DynamicMarkerPositionUpdate(
            markerId: 'vehicle_2',
            latitude: 37.7850,
            longitude: -122.4095,
            timestamp: timestamp,
          ),
        ];

        final result = await platform.batchUpdateDynamicMarkerPositions(updates: updates);

        expect(result, true);
        expect(calls.length, 1);
        expect(calls.first.method, Methods.batchUpdateDynamicMarkerPositions);
        final args = calls.first.arguments as Map<dynamic, dynamic>;
        expect((args['updates'] as List).length, 2);
      });
    });

    group('updateDynamicMarker', () {
      test('should invoke updateDynamicMarker with updated properties', () async {
        final result = await platform.updateDynamicMarker(
          markerId: 'vehicle_1',
          title: 'Updated Vehicle 1',
          showTrail: true,
        );

        expect(result, true);
        expect(calls.length, 1);
        expect(calls.first.method, Methods.updateDynamicMarker);
        final args = calls.first.arguments as Map<dynamic, dynamic>;
        expect(args['markerId'], 'vehicle_1');
        expect(args['title'], 'Updated Vehicle 1');
        expect(args['showTrail'], true);
      });
    });

    group('removeDynamicMarker', () {
      test('should invoke removeDynamicMarker with marker ID', () async {
        final result = await platform.removeDynamicMarker(markerId: 'vehicle_1');

        expect(result, true);
        expect(calls.length, 1);
        expect(calls.first.method, Methods.removeDynamicMarker);
        final args = calls.first.arguments as Map<dynamic, dynamic>;
        expect(args['markerId'], 'vehicle_1');
      });
    });

    group('removeDynamicMarkers', () {
      test('should invoke removeDynamicMarkers with list of IDs', () async {
        final result = await platform.removeDynamicMarkers(
          markerIds: ['vehicle_1', 'vehicle_2'],
        );

        expect(result, true);
        expect(calls.length, 1);
        expect(calls.first.method, Methods.removeDynamicMarkers);
        final args = calls.first.arguments as Map<dynamic, dynamic>;
        expect(args['markerIds'], ['vehicle_1', 'vehicle_2']);
      });
    });

    group('clearAllDynamicMarkers', () {
      test('should invoke clearAllDynamicMarkers', () async {
        final result = await platform.clearAllDynamicMarkers();

        expect(result, true);
        expect(calls.length, 1);
        expect(calls.first.method, Methods.clearAllDynamicMarkers);
      });
    });

    group('getDynamicMarker', () {
      test('should invoke getDynamicMarker and return marker', () async {
        final result = await platform.getDynamicMarker(markerId: 'vehicle_1');

        expect(result, isNotNull);
        expect(result?.id, 'vehicle_1');
        expect(result?.latitude, 37.7749);
        expect(result?.longitude, -122.4194);
        expect(calls.length, 1);
        expect(calls.first.method, Methods.getDynamicMarker);
      });
    });

    group('getDynamicMarkers', () {
      test('should invoke getDynamicMarkers and return list', () async {
        final result = await platform.getDynamicMarkers();

        expect(result, isNotNull);
        expect(result?.length, 2);
        expect(result?[0].id, 'vehicle_1');
        expect(result?[1].id, 'vehicle_2');
        expect(calls.length, 1);
        expect(calls.first.method, Methods.getDynamicMarkers);
      });
    });

    group('updateDynamicMarkerConfiguration', () {
      test('should invoke updateDynamicMarkerConfiguration with config', () async {
        final config = DynamicMarkerConfiguration(
          animationDurationMs: 500,
          enableAnimation: true,
          enableTrail: true,
          maxTrailPoints: 100,
        );

        final result = await platform.updateDynamicMarkerConfiguration(
          configuration: config,
        );

        expect(result, true);
        expect(calls.length, 1);
        expect(calls.first.method, Methods.updateDynamicMarkerConfiguration);
        final args = calls.first.arguments as Map<dynamic, dynamic>;
        expect(args['animationDurationMs'], 500);
        expect(args['enableAnimation'], true);
        expect(args['enableTrail'], true);
        expect(args['maxTrailPoints'], 100);
      });
    });

    group('clearDynamicMarkerTrail', () {
      test('should invoke clearDynamicMarkerTrail with marker ID', () async {
        final result = await platform.clearDynamicMarkerTrail(markerId: 'vehicle_1');

        expect(result, true);
        expect(calls.length, 1);
        expect(calls.first.method, Methods.clearDynamicMarkerTrail);
        final args = calls.first.arguments as Map<dynamic, dynamic>;
        expect(args['markerId'], 'vehicle_1');
      });
    });

    group('clearAllDynamicMarkerTrails', () {
      test('should invoke clearAllDynamicMarkerTrails', () async {
        final result = await platform.clearAllDynamicMarkerTrails();

        expect(result, true);
        expect(calls.length, 1);
        expect(calls.first.method, Methods.clearAllDynamicMarkerTrails);
      });
    });
  });
}
