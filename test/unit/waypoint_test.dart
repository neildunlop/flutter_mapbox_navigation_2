import 'package:flutter_mapbox_navigation/flutter_mapbox_navigation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WayPoint Tests', () {
    group('Basic WayPoint Creation', () {
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
    });

    group('Name Validation', () {
      test('should throw FormatException for empty name', () {
        // Arrange & Act & Assert
        expect(
          () => WayPoint(
            name: '',
            latitude: 51.5074,
            longitude: -0.1278,
          ),
          throwsFormatException,
        );
      });

      test('should throw FormatException for whitespace-only name', () {
        // Arrange & Act & Assert
        expect(
          () => WayPoint(
            name: '   ',
            latitude: 51.5074,
            longitude: -0.1278,
          ),
          throwsFormatException,
        );
      });

      test('should accept valid name with whitespace', () {
        // Arrange
        const name = '  Test Location  ';

        // Act
        final wayPoint = WayPoint(
          name: name,
          latitude: 51.5074,
          longitude: -0.1278,
        );

        // Assert
        expect(wayPoint.name, equals(name));
      });
    });

    group('JSON Handling', () {
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

      test('should throw FormatException for missing name in JSON', () {
        // Arrange
        final json = {
          'latitude': 51.5074,
          'longitude': -0.1278,
        };

        // Act & Assert
        expect(
          () => WayPoint.fromJson(json),
          throwsFormatException,
        );
      });

      test('should throw FormatException for null name in JSON', () {
        // Arrange
        final json = {
          'name': null,
          'latitude': 51.5074,
          'longitude': -0.1278,
        };

        // Act & Assert
        expect(
          () => WayPoint.fromJson(json),
          throwsFormatException,
        );
      });

      test('should throw FormatException for empty name in JSON', () {
        // Arrange
        final json = {
          'name': '',
          'latitude': 51.5074,
          'longitude': -0.1278,
        };

        // Act & Assert
        expect(
          () => WayPoint.fromJson(json),
          throwsFormatException,
        );
      });

      test('should throw FormatException for whitespace-only name in JSON', () {
        // Arrange
        final json = {
          'name': '   ',
          'latitude': 51.5074,
          'longitude': -0.1278,
        };

        // Act & Assert
        expect(
          () => WayPoint.fromJson(json),
          throwsFormatException,
        );
      });
    });

    group('String Representation', () {
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
        expect(
          wayPoint.toString(),
          equals('WayPoint{name: Test Location, latitude: 51.5074, longitude: -0.1278}'),
        );
      });
    });

    group('Error Handling', () {
      test('should handle null coordinates', () {
        // Arrange & Act & Assert
        expect(
          () => WayPoint(
            name: 'Test',
            latitude: null,
            longitude: -0.1278,
          ),
          throwsFormatException,
        );

        expect(
          () => WayPoint(
            name: 'Test',
            latitude: 51.5074,
            longitude: null,
          ),
          throwsFormatException,
        );
      });

      test('should handle invalid coordinates', () {
        // Arrange & Act & Assert
        expect(
          () => WayPoint(
            name: 'Test',
            latitude: 91.0, // Invalid latitude > 90
            longitude: -0.1278,
          ),
          throwsFormatException,
        );

        expect(
          () => WayPoint(
            name: 'Test',
            latitude: 51.5074,
            longitude: 181.0, // Invalid longitude > 180
          ),
          throwsFormatException,
        );

        expect(
          () => WayPoint(
            name: 'Test',
            latitude: -91.0, // Invalid latitude < -90
            longitude: -0.1278,
          ),
          throwsFormatException,
        );

        expect(
          () => WayPoint(
            name: 'Test',
            latitude: 51.5074,
            longitude: -181.0, // Invalid longitude < -180
          ),
          throwsFormatException,
        );
      });

      test('should handle invalid JSON data', () {
        // Arrange
        final invalidJson = {
          'name': 'Test Location',
          'latitude': 'invalid', // Invalid latitude format
          'longitude': -0.1278,
        };

        // Act & Assert
        expect(
          () => WayPoint.fromJson(invalidJson),
          throwsFormatException,
        );
      });

      test('should handle missing required fields in JSON', () {
        // Arrange
        final missingFieldsJson = {
          'name': 'Test Location',
          // Missing latitude and longitude
        };

        // Act & Assert
        expect(
          () => WayPoint.fromJson(missingFieldsJson),
          throwsFormatException,
        );
      });

      test('should handle duplicate waypoints in route', () {
        // Arrange
        final wayPoints = [
          WayPoint(
            name: 'Start',
            latitude: 51.5074,
            longitude: -0.1278,
          ),
          WayPoint(
            name: 'End',
            latitude: 51.5074, // Same coordinates
            longitude: -0.1278,
          ),
        ];

        // Act & Assert
        expect(
          () => WayPoint.validateWaypoints(wayPoints),
          throwsFormatException,
        );
      });
    });
  });
} 