import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_mapbox_navigation/src/models/fullscreen_event.dart';
import 'package:flutter_mapbox_navigation/src/models/waypoint_result.dart';
import 'package:flutter_mapbox_navigation/src/models/static_marker.dart';

void main() {
  group('WaypointResult', () {
    group('Constructor', () {
      test('should create with success and waypointsAdded', () {
        const result = WaypointResult(
          success: true,
          waypointsAdded: 3,
        );

        expect(result.success, isTrue);
        expect(result.waypointsAdded, 3);
        expect(result.errorMessage, isNull);
      });

      test('should create with failure and errorMessage', () {
        const result = WaypointResult(
          success: false,
          waypointsAdded: 0,
          errorMessage: 'Invalid waypoint data',
        );

        expect(result.success, isFalse);
        expect(result.waypointsAdded, 0);
        expect(result.errorMessage, 'Invalid waypoint data');
      });
    });

    group('Factory constructors', () {
      test('success should create successful result', () {
        final result = WaypointResult.success(waypointsAdded: 5);

        expect(result.success, isTrue);
        expect(result.waypointsAdded, 5);
        expect(result.errorMessage, isNull);
      });

      test('failure should create failed result with message', () {
        final result = WaypointResult.failure(
          errorMessage: 'Network error',
        );

        expect(result.success, isFalse);
        expect(result.waypointsAdded, 0);
        expect(result.errorMessage, 'Network error');
      });

      test('failure should create failed result with partial waypoints', () {
        final result = WaypointResult.failure(
          errorMessage: 'Partial failure',
          waypointsAdded: 2,
        );

        expect(result.success, isFalse);
        expect(result.waypointsAdded, 2);
        expect(result.errorMessage, 'Partial failure');
      });
    });

    group('toString', () {
      test('should format successful result correctly', () {
        const result = WaypointResult(
          success: true,
          waypointsAdded: 3,
        );

        expect(
          result.toString(),
          'WaypointResult(success: true, waypointsAdded: 3)',
        );
      });

      test('should format failed result correctly', () {
        const result = WaypointResult(
          success: false,
          waypointsAdded: 0,
          errorMessage: 'Error occurred',
        );

        expect(
          result.toString(),
          'WaypointResult(success: false, waypointsAdded: 0, errorMessage: Error occurred)',
        );
      });
    });
  });

  group('FullScreenEvent', () {
    group('Constructor', () {
      test('should create with required parameters', () {
        const event = FullScreenEvent(
          type: 'marker_tap',
          mode: 'navigation',
        );

        expect(event.type, 'marker_tap');
        expect(event.mode, 'navigation');
        expect(event.marker, isNull);
        expect(event.latitude, isNull);
        expect(event.longitude, isNull);
        expect(event.metadata, isNull);
      });

      test('should create with all parameters', () {
        final marker = StaticMarker(
          id: 'test-marker',
          latitude: 51.5074,
          longitude: -0.1278,
          title: 'Test Marker',
          category: 'test',
        );

        final event = FullScreenEvent(
          type: 'marker_tap',
          mode: 'free_drive',
          marker: marker,
          latitude: 51.5074,
          longitude: -0.1278,
          metadata: {'key': 'value'},
        );

        expect(event.type, 'marker_tap');
        expect(event.mode, 'free_drive');
        expect(event.marker, equals(marker));
        expect(event.latitude, 51.5074);
        expect(event.longitude, -0.1278);
        expect(event.metadata, {'key': 'value'});
      });
    });

    group('fromJson', () {
      test('should parse basic JSON', () {
        final json = jsonEncode({
          'type': 'map_tap',
          'mode': 'navigation',
        });

        final event = FullScreenEvent.fromJson(json);

        expect(event.type, 'map_tap');
        expect(event.mode, 'navigation');
      });

      test('should parse JSON with coordinates', () {
        final json = jsonEncode({
          'type': 'map_tap',
          'mode': 'navigation',
          'latitude': 51.5074,
          'longitude': -0.1278,
        });

        final event = FullScreenEvent.fromJson(json);

        expect(event.latitude, 51.5074);
        expect(event.longitude, -0.1278);
      });

      test('should parse JSON with nested marker', () {
        final json = jsonEncode({
          'type': 'marker_tap',
          'mode': 'navigation',
          'marker': {
            'id': 'test-id',
            'latitude': 51.5074,
            'longitude': -0.1278,
            'title': 'Test Marker',
            'category': 'test',
          },
        });

        final event = FullScreenEvent.fromJson(json);

        expect(event.marker, isNotNull);
        expect(event.marker!.id, 'test-id');
        expect(event.marker!.title, 'Test Marker');
      });

      test('should parse JSON with flattened marker data', () {
        final json = jsonEncode({
          'type': 'marker_tap',
          'mode': 'navigation',
          'marker_id': 'flat-marker-id',
          'marker_latitude': 48.8566,
          'marker_longitude': 2.3522,
          'marker_title': 'Flattened Marker',
          'marker_category': 'flat-test',
        });

        final event = FullScreenEvent.fromJson(json);

        expect(event.marker, isNotNull);
        expect(event.marker!.id, 'flat-marker-id');
        expect(event.marker!.title, 'Flattened Marker');
        expect(event.marker!.latitude, 48.8566);
        expect(event.marker!.longitude, 2.3522);
      });

      test('should parse JSON with marker as string', () {
        final markerJson = jsonEncode({
          'id': 'string-marker-id',
          'latitude': 40.7128,
          'longitude': -74.0060,
          'title': 'String Marker',
          'category': 'string-test',
        });

        final json = jsonEncode({
          'type': 'marker_tap',
          'mode': 'navigation',
          'marker': markerJson,
        });

        final event = FullScreenEvent.fromJson(json);

        expect(event.marker, isNotNull);
        expect(event.marker!.id, 'string-marker-id');
        expect(event.marker!.title, 'String Marker');
      });

      test('should parse JSON with metadata', () {
        final json = jsonEncode({
          'type': 'map_tap',
          'mode': 'navigation',
          'metadata': {
            'custom_field': 'custom_value',
            'another_field': 123,
          },
        });

        final event = FullScreenEvent.fromJson(json);

        expect(event.metadata, isNotNull);
        expect(event.metadata!['custom_field'], 'custom_value');
        expect(event.metadata!['another_field'], 123);
      });

      test('should throw FormatException for invalid JSON', () {
        expect(
          () => FullScreenEvent.fromJson('invalid json'),
          throwsFormatException,
        );
      });

      test('should throw FormatException for missing required fields', () {
        final json = jsonEncode({
          'type': 'map_tap',
          // missing 'mode'
        });

        expect(
          () => FullScreenEvent.fromJson(json),
          throwsFormatException,
        );
      });
    });

    group('toJson', () {
      test('should convert basic event to JSON', () {
        const event = FullScreenEvent(
          type: 'map_tap',
          mode: 'navigation',
        );

        final jsonString = event.toJson();
        final decoded = jsonDecode(jsonString) as Map<String, dynamic>;

        expect(decoded['type'], 'map_tap');
        expect(decoded['mode'], 'navigation');
      });

      test('should include coordinates in JSON', () {
        const event = FullScreenEvent(
          type: 'map_tap',
          mode: 'navigation',
          latitude: 51.5074,
          longitude: -0.1278,
        );

        final jsonString = event.toJson();
        final decoded = jsonDecode(jsonString) as Map<String, dynamic>;

        expect(decoded['latitude'], 51.5074);
        expect(decoded['longitude'], -0.1278);
      });

      test('should include marker in JSON', () {
        final marker = StaticMarker(
          id: 'test-marker',
          latitude: 51.5074,
          longitude: -0.1278,
          title: 'Test',
          category: 'test',
        );

        final event = FullScreenEvent(
          type: 'marker_tap',
          mode: 'navigation',
          marker: marker,
        );

        final jsonString = event.toJson();
        final decoded = jsonDecode(jsonString) as Map<String, dynamic>;

        expect(decoded['marker'], isNotNull);
      });

      test('should include metadata in JSON', () {
        final event = FullScreenEvent(
          type: 'map_tap',
          mode: 'navigation',
          metadata: {'key': 'value'},
        );

        final jsonString = event.toJson();
        final decoded = jsonDecode(jsonString) as Map<String, dynamic>;

        expect(decoded['metadata'], {'key': 'value'});
      });
    });

    group('toMap', () {
      test('should convert to map correctly', () {
        const event = FullScreenEvent(
          type: 'map_tap',
          mode: 'navigation',
          latitude: 51.5074,
          longitude: -0.1278,
        );

        final map = event.toMap();

        expect(map['type'], 'map_tap');
        expect(map['mode'], 'navigation');
        expect(map['latitude'], 51.5074);
        expect(map['longitude'], -0.1278);
      });

      test('should not include null values in map', () {
        const event = FullScreenEvent(
          type: 'map_tap',
          mode: 'navigation',
        );

        final map = event.toMap();

        expect(map.containsKey('latitude'), isFalse);
        expect(map.containsKey('longitude'), isFalse);
        expect(map.containsKey('marker'), isFalse);
        expect(map.containsKey('metadata'), isFalse);
      });
    });

    group('toString', () {
      test('should format correctly', () {
        const event = FullScreenEvent(
          type: 'marker_tap',
          mode: 'navigation',
          latitude: 51.5074,
          longitude: -0.1278,
        );

        final str = event.toString();

        expect(str.contains('marker_tap'), isTrue);
        expect(str.contains('navigation'), isTrue);
        expect(str.contains('51.5074'), isTrue);
        expect(str.contains('-0.1278'), isTrue);
      });

      test('should show marker id when present', () {
        final marker = StaticMarker(
          id: 'marker-123',
          latitude: 51.5074,
          longitude: -0.1278,
          title: 'Test',
          category: 'test',
        );

        final event = FullScreenEvent(
          type: 'marker_tap',
          mode: 'navigation',
          marker: marker,
        );

        final str = event.toString();

        expect(str.contains('marker-123'), isTrue);
      });
    });

    group('equality', () {
      test('should be equal for same values', () {
        const event1 = FullScreenEvent(
          type: 'map_tap',
          mode: 'navigation',
          latitude: 51.5074,
          longitude: -0.1278,
        );

        const event2 = FullScreenEvent(
          type: 'map_tap',
          mode: 'navigation',
          latitude: 51.5074,
          longitude: -0.1278,
        );

        expect(event1, equals(event2));
        expect(event1.hashCode, equals(event2.hashCode));
      });

      test('should not be equal for different types', () {
        const event1 = FullScreenEvent(
          type: 'map_tap',
          mode: 'navigation',
        );

        const event2 = FullScreenEvent(
          type: 'marker_tap',
          mode: 'navigation',
        );

        expect(event1, isNot(equals(event2)));
      });

      test('should not be equal for different modes', () {
        const event1 = FullScreenEvent(
          type: 'map_tap',
          mode: 'navigation',
        );

        const event2 = FullScreenEvent(
          type: 'map_tap',
          mode: 'free_drive',
        );

        expect(event1, isNot(equals(event2)));
      });
    });
  });
}
