import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_mapbox_navigation/src/models/dynamic_marker_position_update.dart';

void main() {
  group('DynamicMarkerPositionUpdate Tests', () {
    test('should create update with required fields', () {
      final timestamp = DateTime(2024, 1, 15, 10, 30, 45);
      final update = DynamicMarkerPositionUpdate(
        markerId: 'vehicle_1',
        latitude: 37.7749,
        longitude: -122.4194,
        timestamp: timestamp,
      );

      expect(update.markerId, 'vehicle_1');
      expect(update.latitude, 37.7749);
      expect(update.longitude, -122.4194);
      expect(update.timestamp, timestamp);
      expect(update.heading, isNull);
      expect(update.speed, isNull);
      expect(update.altitude, isNull);
      expect(update.accuracy, isNull);
      expect(update.additionalData, isNull);
    });

    test('should create update with all optional fields', () {
      final timestamp = DateTime(2024, 1, 15, 10, 30, 45);
      final update = DynamicMarkerPositionUpdate(
        markerId: 'drone_1',
        latitude: 37.7849,
        longitude: -122.4094,
        timestamp: timestamp,
        heading: 45.0,
        speed: 15.5,
        altitude: 120.5,
        accuracy: 5.0,
        additionalData: {'batteryLevel': 85, 'status': 'active'},
      );

      expect(update.heading, 45.0);
      expect(update.speed, 15.5);
      expect(update.altitude, 120.5);
      expect(update.accuracy, 5.0);
      expect(update.additionalData?['batteryLevel'], 85);
      expect(update.additionalData?['status'], 'active');
    });

    test('should convert to and from JSON', () {
      final timestamp = DateTime(2024, 1, 15, 10, 30, 45);
      final original = DynamicMarkerPositionUpdate(
        markerId: 'vehicle_2',
        latitude: 37.7949,
        longitude: -122.3994,
        timestamp: timestamp,
        heading: 90.0,
        speed: 25.0,
        altitude: 50.0,
        accuracy: 3.0,
        additionalData: {'vehicleType': 'truck'},
      );

      final json = original.toJson();
      final restored = DynamicMarkerPositionUpdate.fromJson(json);

      expect(restored.markerId, original.markerId);
      expect(restored.latitude, original.latitude);
      expect(restored.longitude, original.longitude);
      expect(restored.timestamp, original.timestamp);
      expect(restored.heading, original.heading);
      expect(restored.speed, original.speed);
      expect(restored.altitude, original.altitude);
      expect(restored.accuracy, original.accuracy);
      expect(restored.additionalData?['vehicleType'], 'truck');
    });

    test('should create from generic map with id field', () {
      final map = {
        'id': 'entity_1',
        'latitude': 37.7749,
        'longitude': -122.4194,
        'timestamp': '2024-01-15T10:30:45.000',
        'heading': 45.0,
        'speed': 10.0,
      };

      final update = DynamicMarkerPositionUpdate.fromMap(map);

      expect(update.markerId, 'entity_1');
      expect(update.latitude, 37.7749);
      expect(update.longitude, -122.4194);
      expect(update.heading, 45.0);
      expect(update.speed, 10.0);
    });

    test('should create from map with alternate coordinate keys (lat/lng)', () {
      final map = {
        'id': 'entity_2',
        'lat': 37.7849,
        'lng': -122.4094,
      };

      final update = DynamicMarkerPositionUpdate.fromMap(map);

      expect(update.latitude, 37.7849);
      expect(update.longitude, -122.4094);
    });

    test('should create from map with alternate coordinate keys (lat/lon)', () {
      final map = {
        'id': 'entity_3',
        'lat': 37.7949,
        'lon': -122.3994,
      };

      final update = DynamicMarkerPositionUpdate.fromMap(map);

      expect(update.latitude, 37.7949);
      expect(update.longitude, -122.3994);
    });

    test('should use current time when timestamp not in map', () {
      final before = DateTime.now();
      final map = {
        'id': 'entity_4',
        'latitude': 37.7749,
        'longitude': -122.4194,
      };

      final update = DynamicMarkerPositionUpdate.fromMap(map);
      final after = DateTime.now();

      expect(update.timestamp.isAfter(before.subtract(const Duration(seconds: 1))), true);
      expect(update.timestamp.isBefore(after.add(const Duration(seconds: 1))), true);
    });

    test('should parse additionalData from map with data key', () {
      final map = {
        'id': 'entity_5',
        'latitude': 37.7749,
        'longitude': -122.4194,
        'data': {'customField': 'customValue', 'count': 42},
      };

      final update = DynamicMarkerPositionUpdate.fromMap(map);

      expect(update.additionalData?['customField'], 'customValue');
      expect(update.additionalData?['count'], 42);
    });

    test('should handle integer coordinate values', () {
      final map = {
        'id': 'entity_6',
        'latitude': 37,
        'longitude': -122,
      };

      final update = DynamicMarkerPositionUpdate.fromMap(map);

      expect(update.latitude, 37.0);
      expect(update.longitude, -122.0);
    });

    test('should create copy with updated fields', () {
      final original = DynamicMarkerPositionUpdate(
        markerId: 'vehicle_1',
        latitude: 37.7749,
        longitude: -122.4194,
        timestamp: DateTime(2024, 1, 15, 10, 30),
        heading: 0.0,
        speed: 10.0,
      );

      final updated = original.copyWith(
        latitude: 37.7800,
        longitude: -122.4100,
        heading: 45.0,
        speed: 20.0,
      );

      expect(updated.markerId, original.markerId);
      expect(updated.latitude, 37.7800);
      expect(updated.longitude, -122.4100);
      expect(updated.timestamp, original.timestamp);
      expect(updated.heading, 45.0);
      expect(updated.speed, 20.0);
    });

    test('should have correct string representation', () {
      final update = DynamicMarkerPositionUpdate(
        markerId: 'test_marker',
        latitude: 37.7749,
        longitude: -122.4194,
        timestamp: DateTime(2024, 1, 15, 10, 30),
        heading: 90.0,
        speed: 15.0,
      );

      final stringRep = update.toString();
      expect(stringRep, contains('test_marker'));
      expect(stringRep, contains('37.7749'));
      expect(stringRep, contains('-122.4194'));
    });

    test('should implement equality based on markerId and timestamp', () {
      final timestamp = DateTime(2024, 1, 15, 10, 30);

      final update1 = DynamicMarkerPositionUpdate(
        markerId: 'same_id',
        latitude: 37.7749,
        longitude: -122.4194,
        timestamp: timestamp,
      );

      final update2 = DynamicMarkerPositionUpdate(
        markerId: 'same_id',
        latitude: 37.8000,
        longitude: -122.4000,
        timestamp: timestamp,
      );

      final update3 = DynamicMarkerPositionUpdate(
        markerId: 'different_id',
        latitude: 37.7749,
        longitude: -122.4194,
        timestamp: timestamp,
      );

      final update4 = DynamicMarkerPositionUpdate(
        markerId: 'same_id',
        latitude: 37.7749,
        longitude: -122.4194,
        timestamp: DateTime(2024, 1, 15, 10, 31),
      );

      expect(update1, equals(update2));
      expect(update1, isNot(equals(update3)));
      expect(update1, isNot(equals(update4)));
    });
  });
}
