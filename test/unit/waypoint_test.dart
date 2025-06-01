import 'package:flutter_mapbox_navigation/flutter_mapbox_navigation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WayPoint Tests', () {
    test('should create WayPoint with required parameters', () {
      // Arrange
      const name = 'Test Location';
      const latitude = 51.5074;
      const longitude = -0.1278;
      const isSilent = false;

      // Act
      final wayPoint = WayPoint(
        name: name,
        latitude: latitude,
        longitude: longitude,
        isSilent: isSilent,
      );

      // Assert
      expect(wayPoint.name, equals(name));
      expect(wayPoint.latitude, equals(latitude));
      expect(wayPoint.longitude, equals(longitude));
      expect(wayPoint.isSilent, equals(isSilent));
    });

    test('should create WayPoint with default isSilent value', () {
      // Arrange
      const name = 'Test Location';
      const latitude = 51.5074;
      const longitude = -0.1278;

      // Act
      final wayPoint = WayPoint(
        name: name,
        latitude: latitude,
        longitude: longitude,
      );

      // Assert
      expect(wayPoint.name, equals(name));
      expect(wayPoint.latitude, equals(latitude));
      expect(wayPoint.longitude, equals(longitude));
      expect(wayPoint.isSilent, equals(false)); // Default value
    });

    test('should create WayPoint from JSON', () {
      // Arrange
      final json = {
        'name': 'Test Location',
        'latitude': 51.5074,
        'longitude': -0.1278,
        'isSilent': true,
      };

      // Act
      final wayPoint = WayPoint.fromJson(json);

      // Assert
      expect(wayPoint.name, equals('Test Location'));
      expect(wayPoint.latitude, equals(51.5074));
      expect(wayPoint.longitude, equals(-0.1278));
      expect(wayPoint.isSilent, equals(true));
    });

    test('should handle string latitude/longitude in JSON', () {
      // Arrange
      final json = {
        'name': 'Test Location',
        'latitude': '51.5074',
        'longitude': '-0.1278',
        'isSilent': true,
      };

      // Act
      final wayPoint = WayPoint.fromJson(json);

      // Assert
      expect(wayPoint.name, equals('Test Location'));
      expect(wayPoint.latitude, equals(51.5074));
      expect(wayPoint.longitude, equals(-0.1278));
      expect(wayPoint.isSilent, equals(true));
    });

    test('should handle missing isSilent in JSON', () {
      // Arrange
      final json = {
        'name': 'Test Location',
        'latitude': 51.5074,
        'longitude': -0.1278,
      };

      // Act
      final wayPoint = WayPoint.fromJson(json);

      // Assert
      expect(wayPoint.name, equals('Test Location'));
      expect(wayPoint.latitude, equals(51.5074));
      expect(wayPoint.longitude, equals(-0.1278));
      expect(wayPoint.isSilent, equals(false)); // Default value
    });

    test('should convert to string correctly', () {
      // Arrange
      const name = 'Test Location';
      const latitude = 51.5074;
      const longitude = -0.1278;

      // Act
      final wayPoint = WayPoint(
        name: name,
        latitude: latitude,
        longitude: longitude,
      );

      // Assert
      expect(wayPoint.toString(), equals('WayPoint{latitude: 51.5074, longitude: -0.1278}'));
    });
  });
} 