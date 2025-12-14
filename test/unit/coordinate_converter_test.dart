import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_mapbox_navigation/src/utilities/coordinate_converter.dart';

void main() {
  group('LatLng', () {
    test('should create LatLng with valid coordinates', () {
      const latLng = LatLng(51.5074, -0.1278);

      expect(latLng.latitude, 51.5074);
      expect(latLng.longitude, -0.1278);
    });

    test('should convert to string correctly', () {
      const latLng = LatLng(51.5074, -0.1278);

      expect(latLng.toString(), 'LatLng(51.5074, -0.1278)');
    });

    test('should be equal when coordinates match', () {
      const latLng1 = LatLng(51.5074, -0.1278);
      const latLng2 = LatLng(51.5074, -0.1278);

      expect(latLng1, equals(latLng2));
      expect(latLng1.hashCode, equals(latLng2.hashCode));
    });

    test('should not be equal when coordinates differ', () {
      const latLng1 = LatLng(51.5074, -0.1278);
      const latLng2 = LatLng(48.8566, 2.3522);

      expect(latLng1, isNot(equals(latLng2)));
    });

    test('should handle edge case coordinates', () {
      // North pole
      const northPole = LatLng(90.0, 0.0);
      expect(northPole.latitude, 90.0);

      // South pole
      const southPole = LatLng(-90.0, 0.0);
      expect(southPole.latitude, -90.0);

      // Date line
      const dateLineEast = LatLng(0.0, 180.0);
      expect(dateLineEast.longitude, 180.0);

      const dateLineWest = LatLng(0.0, -180.0);
      expect(dateLineWest.longitude, -180.0);
    });

    test('should handle zero coordinates (null island)', () {
      const nullIsland = LatLng(0.0, 0.0);

      expect(nullIsland.latitude, 0.0);
      expect(nullIsland.longitude, 0.0);
    });
  });

  group('MapViewport', () {
    test('should create MapViewport with required parameters', () {
      const viewport = MapViewport(
        center: LatLng(51.5074, -0.1278),
        zoomLevel: 15.0,
        size: Size(400, 800),
      );

      expect(viewport.center, const LatLng(51.5074, -0.1278));
      expect(viewport.zoomLevel, 15.0);
      expect(viewport.size, const Size(400, 800));
      expect(viewport.bearing, 0.0);
      expect(viewport.tilt, 0.0);
    });

    test('should create MapViewport with optional parameters', () {
      const viewport = MapViewport(
        center: LatLng(51.5074, -0.1278),
        zoomLevel: 15.0,
        size: Size(400, 800),
        bearing: 45.0,
        tilt: 30.0,
      );

      expect(viewport.bearing, 45.0);
      expect(viewport.tilt, 30.0);
    });

    test('coordinateToScreen should return position for visible coordinate', () {
      const viewport = MapViewport(
        center: LatLng(51.5074, -0.1278),
        zoomLevel: 15.0,
        size: Size(400, 800),
      );

      // Center should map to center of screen
      final centerPosition = viewport.coordinateToScreen(51.5074, -0.1278);

      expect(centerPosition, isNotNull);
      expect(centerPosition!.dx, closeTo(200, 1)); // Half of width
      expect(centerPosition.dy, closeTo(400, 1)); // Half of height
    });

    test('isCoordinateVisible should return true for visible coordinates', () {
      const viewport = MapViewport(
        center: LatLng(51.5074, -0.1278),
        zoomLevel: 15.0,
        size: Size(400, 800),
      );

      // Center should be visible
      expect(viewport.isCoordinateVisible(51.5074, -0.1278), isTrue);
    });

    test('isCoordinateVisible should return false for far coordinates', () {
      const viewport = MapViewport(
        center: LatLng(51.5074, -0.1278),
        zoomLevel: 15.0,
        size: Size(400, 800),
      );

      // Paris from London at high zoom should not be visible
      expect(viewport.isCoordinateVisible(48.8566, 2.3522), isFalse);
    });

    test('isCoordinateVisible should respect buffer parameter', () {
      const viewport = MapViewport(
        center: LatLng(51.5074, -0.1278),
        zoomLevel: 10.0,
        size: Size(400, 800),
      );

      // Test with larger buffer
      final visibleWithBuffer = viewport.isCoordinateVisible(
        51.5074,
        -0.1278,
        buffer: 0.5,
      );
      expect(visibleWithBuffer, isTrue);
    });
  });

  group('CoordinateConverter', () {
    group('coordinateToScreen', () {
      test('should return center position for center coordinate', () {
        final position = CoordinateConverter.coordinateToScreen(
          latitude: 51.5074,
          longitude: -0.1278,
          mapCenter: const LatLng(51.5074, -0.1278),
          mapSize: const Size(400, 800),
          zoomLevel: 15.0,
        );

        expect(position, isNotNull);
        expect(position!.dx, closeTo(200, 1));
        expect(position.dy, closeTo(400, 1));
      });

      test('should return null for coordinates far outside viewport', () {
        final position = CoordinateConverter.coordinateToScreen(
          latitude: 48.8566, // Paris
          longitude: 2.3522,
          mapCenter: const LatLng(51.5074, -0.1278), // London
          mapSize: const Size(400, 800),
          zoomLevel: 15.0, // High zoom = small visible area
        );

        expect(position, isNull);
      });

      test('should handle different zoom levels', () {
        const london = LatLng(51.5074, -0.1278);
        const mapSize = Size(400, 800);

        // Center point should always be visible at any zoom
        final highZoomPosition = CoordinateConverter.coordinateToScreen(
          latitude: london.latitude,
          longitude: london.longitude,
          mapCenter: london,
          mapSize: mapSize,
          zoomLevel: 18.0,
        );
        expect(highZoomPosition, isNotNull);
        expect(highZoomPosition!.dx, closeTo(200, 1));

        // At low zoom, center should also be visible
        final lowZoomPosition = CoordinateConverter.coordinateToScreen(
          latitude: london.latitude,
          longitude: london.longitude,
          mapCenter: london,
          mapSize: mapSize,
          zoomLevel: 5.0,
        );
        expect(lowZoomPosition, isNotNull);
        expect(lowZoomPosition!.dx, closeTo(200, 1));
      });

      test('should handle coordinates at equator', () {
        final position = CoordinateConverter.coordinateToScreen(
          latitude: 0.0,
          longitude: 0.0,
          mapCenter: const LatLng(0.0, 0.0),
          mapSize: const Size(400, 800),
          zoomLevel: 10.0,
        );

        expect(position, isNotNull);
        expect(position!.dx, closeTo(200, 1));
        expect(position.dy, closeTo(400, 1));
      });

      test('should handle negative longitudes', () {
        final position = CoordinateConverter.coordinateToScreen(
          latitude: 40.7128,
          longitude: -74.0060, // New York
          mapCenter: const LatLng(40.7128, -74.0060),
          mapSize: const Size(400, 800),
          zoomLevel: 12.0,
        );

        expect(position, isNotNull);
        expect(position!.dx, closeTo(200, 1));
        expect(position.dy, closeTo(400, 1));
      });

      test('should return position offset from center for offset coordinate', () {
        // Use estimateScreenPosition which doesn't clip to viewport
        // to verify the offset calculation logic
        final position = CoordinateConverter.estimateScreenPosition(
          latitude: 51.5080, // Slightly north
          longitude: -0.1278, // Same longitude
          mapCenter: const LatLng(51.5074, -0.1278),
          mapSize: const Size(400, 800),
          zoomLevel: 10.0,
        );

        // Y should be less than center (north is up, but screen Y increases down)
        expect(position.dy, lessThan(400));
        // X should be roughly center since longitude is the same
        expect(position.dx, closeTo(200, 10));
      });
    });

    group('estimateScreenPosition', () {
      test('should return center position for center coordinate', () {
        final position = CoordinateConverter.estimateScreenPosition(
          latitude: 51.5074,
          longitude: -0.1278,
          mapCenter: const LatLng(51.5074, -0.1278),
          mapSize: const Size(400, 800),
          zoomLevel: 15.0,
        );

        expect(position.dx, closeTo(200, 1));
        expect(position.dy, closeTo(400, 1));
      });

      test('should always return a position (never null)', () {
        // Even for far away coordinates, estimate should return a value
        final position = CoordinateConverter.estimateScreenPosition(
          latitude: -33.8688, // Sydney
          longitude: 151.2093,
          mapCenter: const LatLng(51.5074, -0.1278), // London
          mapSize: const Size(400, 800),
          zoomLevel: 15.0,
        );

        // Should return some position (not null)
        expect(position, isA<Offset>());
      });

      test('should handle zoom level edge cases', () {
        // Very low zoom
        final lowZoom = CoordinateConverter.estimateScreenPosition(
          latitude: 51.5080,
          longitude: -0.1280,
          mapCenter: const LatLng(51.5074, -0.1278),
          mapSize: const Size(400, 800),
          zoomLevel: 1.0,
        );
        expect(lowZoom, isA<Offset>());

        // Very high zoom
        final highZoom = CoordinateConverter.estimateScreenPosition(
          latitude: 51.5080,
          longitude: -0.1280,
          mapCenter: const LatLng(51.5074, -0.1278),
          mapSize: const Size(400, 800),
          zoomLevel: 22.0,
        );
        expect(highZoom, isA<Offset>());
      });
    });
  });
}
