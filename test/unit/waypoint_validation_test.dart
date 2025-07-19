import 'package:flutter_mapbox_navigation/flutter_mapbox_navigation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Waypoint Validation Tests', () {
    group('validateWaypointCount', () {
      test('should return valid for minimum waypoints', () {
        // Arrange
        final waypoints = [
          WayPoint(name: 'Start', latitude: 51.5074, longitude: -0.1278),
          WayPoint(name: 'End', latitude: 51.5074, longitude: -0.1278),
        ];

        // Act
        final result = WayPoint.validateWaypointCount(waypoints);

        // Assert
        expect(result.isValid, isTrue);
        expect(result.warnings, isEmpty);
        expect(result.recommendations, isEmpty);
      });

      test('should return invalid for single waypoint', () {
        // Arrange
        final waypoints = [
          WayPoint(name: 'Start', latitude: 51.5074, longitude: -0.1278),
        ];

        // Act
        final result = WayPoint.validateWaypointCount(waypoints);

        // Assert
        expect(result.isValid, isFalse);
        expect(result.warnings, contains('Minimum 2 waypoints required for navigation'));
        expect(result.recommendations, contains('Add at least one more waypoint'));
      });

      test('should return invalid for empty waypoints', () {
        // Arrange
        final waypoints = <WayPoint>[];

        // Act
        final result = WayPoint.validateWaypointCount(waypoints);

        // Assert
        expect(result.isValid, isFalse);
        expect(result.warnings, contains('Minimum 2 waypoints required for navigation'));
      });

      test('should return warning for high waypoint count', () {
        // Arrange
        final waypoints = List.generate(20, (index) => 
          WayPoint(name: 'Stop $index', latitude: 51.5074, longitude: -0.1278)
        );

        // Act
        final result = WayPoint.validateWaypointCount(waypoints);

        // Assert
        expect(result.isValid, isTrue);
        expect(result.warnings, contains('High waypoint count (20) may impact route calculation performance'));
        expect(result.recommendations, contains('Consider optimizing route with fewer waypoints'));
      });

      test('should return warning for exceeding API limit', () {
        // Arrange
        final waypoints = List.generate(30, (index) => 
          WayPoint(name: 'Stop $index', latitude: 51.5074, longitude: -0.1278)
        );

        // Act
        final result = WayPoint.validateWaypointCount(waypoints);

        // Assert
        expect(result.isValid, isTrue);
        expect(result.warnings, contains('Waypoint count (30) exceeds recommended Mapbox API limit of 25'));
        expect(result.recommendations, contains('Consider reducing waypoint count for better performance'));
        expect(result.recommendations, contains('Use silent waypoints for route shaping instead of additional stops'));
      });

      test('should return valid for moderate waypoint count', () {
        // Arrange
        final waypoints = List.generate(10, (index) => 
          WayPoint(name: 'Stop $index', latitude: 51.5074, longitude: -0.1278)
        );

        // Act
        final result = WayPoint.validateWaypointCount(waypoints);

        // Assert
        expect(result.isValid, isTrue);
        expect(result.warnings, isEmpty);
        expect(result.recommendations, isEmpty);
      });
    });

    group('WaypointValidationResult', () {
      test('should create valid result correctly', () {
        // Act
        final result = WaypointValidationResult.valid();

        // Assert
        expect(result.isValid, isTrue);
        expect(result.warnings, isEmpty);
        expect(result.recommendations, isEmpty);
        expect(result.hasWarnings, isFalse);
        expect(result.hasRecommendations, isFalse);
      });

      test('should create invalid result correctly', () {
        // Arrange
        final warnings = ['Warning 1', 'Warning 2'];
        final recommendations = ['Recommendation 1'];

        // Act
        final result = WaypointValidationResult.invalid(
          warnings: warnings,
          recommendations: recommendations,
        );

        // Assert
        expect(result.isValid, isFalse);
        expect(result.warnings, equals(warnings));
        expect(result.recommendations, equals(recommendations));
        expect(result.hasWarnings, isTrue);
        expect(result.hasRecommendations, isTrue);
      });

      test('should format message correctly for valid result', () {
        // Act
        final result = WaypointValidationResult.valid();
        final message = result.formattedMessage;

        // Assert
        expect(message, contains('✅ Waypoint validation passed'));
        expect(message, isNot(contains('❌')));
        expect(message, isNot(contains('⚠️')));
      });

      test('should format message correctly for invalid result', () {
        // Arrange
        final result = WaypointValidationResult.invalid(
          warnings: ['Minimum 2 waypoints required'],
          recommendations: ['Add more waypoints'],
        );

        // Act
        final message = result.formattedMessage;

        // Assert
        expect(message, contains('❌ Waypoint validation failed:'));
        expect(message, contains('• Minimum 2 waypoints required'));
        expect(message, contains('💡 Recommendations:'));
        expect(message, contains('• Add more waypoints'));
      });

      test('should format message correctly for warnings only', () {
        // Arrange
        final result = WaypointValidationResult(
          isValid: true,
          warnings: ['High waypoint count'],
          recommendations: [],
        );

        // Act
        final message = result.formattedMessage;

        // Assert
        expect(message, contains('⚠️  Waypoint validation warnings:'));
        expect(message, contains('• High waypoint count'));
        expect(message, isNot(contains('💡 Recommendations:')));
      });

      test('should convert to string correctly', () {
        // Arrange
        final result = WaypointValidationResult(
          isValid: true,
          warnings: ['Warning'],
          recommendations: ['Recommendation'],
        );

        // Act
        final string = result.toString();

        // Assert
        expect(string, contains('WaypointValidationResult'));
        expect(string, contains('isValid: true'));
        expect(string, contains('warnings: [Warning]'));
        expect(string, contains('recommendations: [Recommendation]'));
      });
    });
  });
} 