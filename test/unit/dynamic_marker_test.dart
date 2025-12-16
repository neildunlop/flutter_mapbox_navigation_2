import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_mapbox_navigation/src/models/dynamic_marker.dart';

void main() {
  group('DynamicMarkerState Tests', () {
    test('should have all required states', () {
      expect(DynamicMarkerState.values, contains(DynamicMarkerState.tracking));
      expect(DynamicMarkerState.values, contains(DynamicMarkerState.animating));
      expect(DynamicMarkerState.values, contains(DynamicMarkerState.stationary));
      expect(DynamicMarkerState.values, contains(DynamicMarkerState.stale));
      expect(DynamicMarkerState.values, contains(DynamicMarkerState.offline));
      expect(DynamicMarkerState.values, contains(DynamicMarkerState.expired));
    });

    test('should have exactly 6 states', () {
      expect(DynamicMarkerState.values.length, 6);
    });
  });

  group('DynamicMarker Tests', () {
    test('should create DynamicMarker with required fields', () {
      final marker = DynamicMarker(
        id: 'vehicle_1',
        latitude: 37.7749,
        longitude: -122.4194,
        title: 'Vehicle 1',
        category: 'vehicle',
      );

      expect(marker.id, 'vehicle_1');
      expect(marker.latitude, 37.7749);
      expect(marker.longitude, -122.4194);
      expect(marker.title, 'Vehicle 1');
      expect(marker.category, 'vehicle');
      expect(marker.state, DynamicMarkerState.tracking);
      expect(marker.showTrail, false);
      expect(marker.trailLength, 50);
    });

    test('should create DynamicMarker with all optional fields', () {
      final lastUpdated = DateTime(2024, 1, 15, 10, 30);
      final marker = DynamicMarker(
        id: 'drone_1',
        latitude: 37.7849,
        longitude: -122.4094,
        title: 'Drone Alpha',
        category: 'drone',
        previousLatitude: 37.7800,
        previousLongitude: -122.4100,
        heading: 45.0,
        speed: 15.5,
        lastUpdated: lastUpdated,
        iconId: 'drone',
        customColor: Colors.purple,
        metadata: {'batteryLevel': 85, 'altitude': 120.5},
        state: DynamicMarkerState.animating,
        showTrail: true,
        trailLength: 30,
        positionHistory: [
          const LatLng(37.7800, -122.4100),
          const LatLng(37.7820, -122.4090),
        ],
      );

      expect(marker.previousLatitude, 37.7800);
      expect(marker.previousLongitude, -122.4100);
      expect(marker.heading, 45.0);
      expect(marker.speed, 15.5);
      expect(marker.lastUpdated, lastUpdated);
      expect(marker.iconId, 'drone');
      expect(marker.customColor, Colors.purple);
      expect(marker.metadata?['batteryLevel'], 85);
      expect(marker.metadata?['altitude'], 120.5);
      expect(marker.state, DynamicMarkerState.animating);
      expect(marker.showTrail, true);
      expect(marker.trailLength, 30);
      expect(marker.positionHistory?.length, 2);
    });

    test('should use current time as default lastUpdated', () {
      final before = DateTime.now();
      final marker = DynamicMarker(
        id: 'test_1',
        latitude: 37.7749,
        longitude: -122.4194,
        title: 'Test',
        category: 'test',
      );
      final after = DateTime.now();

      expect(marker.lastUpdated.isAfter(before.subtract(const Duration(seconds: 1))), true);
      expect(marker.lastUpdated.isBefore(after.add(const Duration(seconds: 1))), true);
    });

    test('should convert to and from JSON', () {
      final originalMarker = DynamicMarker(
        id: 'vehicle_2',
        latitude: 37.7949,
        longitude: -122.3994,
        title: 'Vehicle 2',
        category: 'vehicle',
        previousLatitude: 37.7900,
        previousLongitude: -122.4000,
        heading: 90.0,
        speed: 25.0,
        lastUpdated: DateTime(2024, 1, 15, 12, 0),
        iconId: 'vehicle',
        customColor: Colors.blue,
        metadata: {'vehicleType': 'truck', 'licensePlate': 'ABC123'},
        state: DynamicMarkerState.tracking,
        showTrail: true,
        trailLength: 40,
      );

      final json = originalMarker.toJson();
      final restoredMarker = DynamicMarker.fromJson(json);

      expect(restoredMarker.id, originalMarker.id);
      expect(restoredMarker.latitude, originalMarker.latitude);
      expect(restoredMarker.longitude, originalMarker.longitude);
      expect(restoredMarker.title, originalMarker.title);
      expect(restoredMarker.category, originalMarker.category);
      expect(restoredMarker.previousLatitude, originalMarker.previousLatitude);
      expect(restoredMarker.previousLongitude, originalMarker.previousLongitude);
      expect(restoredMarker.heading, originalMarker.heading);
      expect(restoredMarker.speed, originalMarker.speed);
      expect(restoredMarker.lastUpdated, originalMarker.lastUpdated);
      expect(restoredMarker.iconId, originalMarker.iconId);
      expect(restoredMarker.customColor?.value, originalMarker.customColor?.value);
      expect(restoredMarker.metadata?['vehicleType'], originalMarker.metadata?['vehicleType']);
      expect(restoredMarker.state, originalMarker.state);
      expect(restoredMarker.showTrail, originalMarker.showTrail);
      expect(restoredMarker.trailLength, originalMarker.trailLength);
    });

    test('should convert to JSON with correct state string', () {
      final marker = DynamicMarker(
        id: 'test_state',
        latitude: 37.7749,
        longitude: -122.4194,
        title: 'Test State',
        category: 'test',
        state: DynamicMarkerState.stale,
      );

      final json = marker.toJson();
      expect(json['state'], 'stale');
    });

    test('should restore state from JSON string', () {
      final json = {
        'id': 'test_state',
        'latitude': 37.7749,
        'longitude': -122.4194,
        'title': 'Test State',
        'category': 'test',
        'state': 'offline',
      };

      final marker = DynamicMarker.fromJson(json);
      expect(marker.state, DynamicMarkerState.offline);
    });

    test('should handle position history in JSON serialization', () {
      final marker = DynamicMarker(
        id: 'test_history',
        latitude: 37.7749,
        longitude: -122.4194,
        title: 'Test History',
        category: 'test',
        positionHistory: [
          const LatLng(37.7700, -122.4200),
          const LatLng(37.7720, -122.4190),
          const LatLng(37.7740, -122.4195),
        ],
      );

      final json = marker.toJson();
      final restored = DynamicMarker.fromJson(json);

      expect(restored.positionHistory?.length, 3);
      expect(restored.positionHistory?[0].latitude, 37.7700);
      expect(restored.positionHistory?[0].longitude, -122.4200);
    });

    test('should create copy with updated fields', () {
      final originalMarker = DynamicMarker(
        id: 'original',
        latitude: 37.7749,
        longitude: -122.4194,
        title: 'Original Title',
        category: 'vehicle',
        heading: 0.0,
        speed: 10.0,
        state: DynamicMarkerState.tracking,
      );

      final updatedMarker = originalMarker.copyWith(
        latitude: 37.7800,
        longitude: -122.4100,
        heading: 45.0,
        speed: 20.0,
        state: DynamicMarkerState.animating,
      );

      expect(updatedMarker.id, originalMarker.id);
      expect(updatedMarker.latitude, 37.7800);
      expect(updatedMarker.longitude, -122.4100);
      expect(updatedMarker.title, originalMarker.title);
      expect(updatedMarker.heading, 45.0);
      expect(updatedMarker.speed, 20.0);
      expect(updatedMarker.state, DynamicMarkerState.animating);
    });

    test('should implement equality based on id', () {
      final marker1 = DynamicMarker(
        id: 'same_id',
        latitude: 37.7749,
        longitude: -122.4194,
        title: 'Marker 1',
        category: 'vehicle',
      );

      final marker2 = DynamicMarker(
        id: 'same_id',
        latitude: 37.8000,
        longitude: -122.4000,
        title: 'Marker 2',
        category: 'drone',
      );

      final marker3 = DynamicMarker(
        id: 'different_id',
        latitude: 37.7749,
        longitude: -122.4194,
        title: 'Marker 1',
        category: 'vehicle',
      );

      expect(marker1, equals(marker2));
      expect(marker1, isNot(equals(marker3)));
    });

    test('should have consistent hashCode based on id', () {
      final marker1 = DynamicMarker(
        id: 'same_id',
        latitude: 37.7749,
        longitude: -122.4194,
        title: 'Marker 1',
        category: 'vehicle',
      );

      final marker2 = DynamicMarker(
        id: 'same_id',
        latitude: 37.8000,
        longitude: -122.4000,
        title: 'Marker 2',
        category: 'drone',
      );

      expect(marker1.hashCode, equals(marker2.hashCode));
    });

    test('should have correct string representation', () {
      final marker = DynamicMarker(
        id: 'test_id',
        latitude: 37.7749,
        longitude: -122.4194,
        title: 'Test Marker',
        category: 'vehicle',
        state: DynamicMarkerState.tracking,
      );

      final stringRep = marker.toString();
      expect(stringRep, contains('test_id'));
      expect(stringRep, contains('Test Marker'));
      expect(stringRep, contains('vehicle'));
      expect(stringRep, contains('37.7749'));
      expect(stringRep, contains('-122.4194'));
      expect(stringRep, contains('tracking'));
    });

    test('should provide position as LatLng', () {
      final marker = DynamicMarker(
        id: 'test_pos',
        latitude: 37.7749,
        longitude: -122.4194,
        title: 'Test',
        category: 'test',
      );

      expect(marker.position.latitude, 37.7749);
      expect(marker.position.longitude, -122.4194);
    });

    test('should provide previousPosition as LatLng when available', () {
      final marker = DynamicMarker(
        id: 'test_prev',
        latitude: 37.7749,
        longitude: -122.4194,
        title: 'Test',
        category: 'test',
        previousLatitude: 37.7700,
        previousLongitude: -122.4200,
      );

      expect(marker.previousPosition?.latitude, 37.7700);
      expect(marker.previousPosition?.longitude, -122.4200);
    });

    test('should return null previousPosition when not set', () {
      final marker = DynamicMarker(
        id: 'test_no_prev',
        latitude: 37.7749,
        longitude: -122.4194,
        title: 'Test',
        category: 'test',
      );

      expect(marker.previousPosition, isNull);
    });
  });

  group('LatLng Tests', () {
    test('should create LatLng with coordinates', () {
      const latLng = LatLng(37.7749, -122.4194);
      expect(latLng.latitude, 37.7749);
      expect(latLng.longitude, -122.4194);
    });

    test('should convert to and from JSON', () {
      const original = LatLng(37.7749, -122.4194);
      final json = original.toJson();
      final restored = LatLng.fromJson(json);

      expect(restored.latitude, original.latitude);
      expect(restored.longitude, original.longitude);
    });

    test('should implement equality', () {
      const latLng1 = LatLng(37.7749, -122.4194);
      const latLng2 = LatLng(37.7749, -122.4194);
      const latLng3 = LatLng(37.8000, -122.4194);

      expect(latLng1, equals(latLng2));
      expect(latLng1, isNot(equals(latLng3)));
    });

    test('should have correct string representation', () {
      const latLng = LatLng(37.7749, -122.4194);
      final stringRep = latLng.toString();
      expect(stringRep, contains('37.7749'));
      expect(stringRep, contains('-122.4194'));
    });
  });
}
