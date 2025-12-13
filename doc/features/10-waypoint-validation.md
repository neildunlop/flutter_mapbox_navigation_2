# Feature Spec: Waypoint Validation

## Overview

Waypoint Validation provides comprehensive validation for navigation waypoints, ensuring data integrity before route calculation. This includes coordinate validation, name validation, API limit warnings, and silent waypoint rules.

**Priority:** P1 - Should Have
**Effort:** Low
**Dependencies:** None

## User Stories

1. **As a developer**, I receive validation errors for invalid coordinates before API calls fail.
2. **As a developer**, I receive warnings when exceeding recommended waypoint limits.
3. **As a developer**, I am warned about platform-specific limitations (iOS traffic mode).
4. **As a developer**, I can validate waypoint names to avoid empty stops.
5. **As a developer**, I understand why my waypoints might fail with clear error messages.

## Technical Approach

Validation is performed on the Flutter layer before sending waypoints to native code:

1. **Coordinate Validation**: Check lat/lng bounds
2. **Name Validation**: Check for empty or whitespace-only names
3. **Count Validation**: Warn about API limits
4. **Silent Waypoint Rules**: Validate first/last cannot be silent
5. **Duplicate Detection**: Check for duplicate coordinates

## API Reference

### WayPoint Class

```dart
class WayPoint {
  final String name;
  final double latitude;
  final double longitude;
  final bool isSilent;

  WayPoint({
    required this.name,
    required this.latitude,
    required this.longitude,
    this.isSilent = false,
  });
}
```

### Creating Valid Waypoints

```dart
// Valid waypoint
final waypoint = WayPoint(
  name: 'San Francisco',
  latitude: 37.7749,  // Valid: -90 to 90
  longitude: -122.4194, // Valid: -180 to 180
);

// Silent waypoint (for route shaping)
final viaPoint = WayPoint(
  name: 'Via Highway 101',
  latitude: 37.5000,
  longitude: -122.2000,
  isSilent: true,
);
```

### Validation Errors

The `WayPoint` constructor throws `FormatException` for:

```dart
// Empty name
WayPoint(name: '', latitude: 37.7749, longitude: -122.4194);
// Throws: FormatException('Waypoint name cannot be empty')

// Whitespace-only name
WayPoint(name: '   ', latitude: 37.7749, longitude: -122.4194);
// Throws: FormatException('Waypoint name cannot be whitespace only')

// Invalid latitude
WayPoint(name: 'Invalid', latitude: 91.0, longitude: -122.4194);
// Throws: FormatException('Latitude must be between -90 and 90')

// Invalid longitude
WayPoint(name: 'Invalid', latitude: 37.7749, longitude: 181.0);
// Throws: FormatException('Longitude must be between -180 and 180')
```

### WaypointValidationResult Class

```dart
class WaypointValidationResult {
  final bool isValid;
  final bool hasWarnings;
  final List<String> warnings;
  final List<String> recommendations;
  final String formattedMessage;
}
```

### Validating Waypoint Count

```dart
final waypoints = [
  WayPoint(name: 'A', latitude: 37.7749, longitude: -122.4194),
  WayPoint(name: 'B', latitude: 37.7849, longitude: -122.4094),
  // ... more waypoints
];

final validation = WayPoint.validateWaypointCount(waypoints);

if (!validation.isValid) {
  print('Validation failed:');
  for (final warning in validation.warnings) {
    print('  - $warning');
  }
} else if (validation.hasWarnings) {
  print('Warnings:');
  for (final warning in validation.warnings) {
    print('  - $warning');
  }
  print('Recommendations:');
  for (final rec in validation.recommendations) {
    print('  - $rec');
  }
} else {
  print('Waypoints are valid');
}

// Or use formatted message
print(validation.formattedMessage);
```

### Validation Rules

| Rule | Condition | Result |
|------|-----------|--------|
| Minimum count | < 2 waypoints | Invalid |
| API limit | > 25 waypoints | Warning |
| iOS traffic mode | > 3 waypoints + drivingWithTraffic | Warning |
| Silent first | First waypoint is silent | Warning (ignored at runtime) |
| Silent last | Last waypoint is silent | Warning (ignored at runtime) |
| Duplicate coordinates | Same lat/lng twice | Warning |

### Validation with Mode

```dart
final validation = WayPoint.validateWaypointCount(
  waypoints,
  mode: MapBoxNavigationMode.drivingWithTraffic,
  platform: TargetPlatform.iOS,
);

if (validation.hasWarnings) {
  // May contain iOS-specific warning about 3 waypoint limit
}
```

## Implementation

### Coordinate Validation

```dart
// In WayPoint constructor
if (latitude < -90 || latitude > 90) {
  throw FormatException('Latitude must be between -90 and 90');
}
if (longitude < -180 || longitude > 180) {
  throw FormatException('Longitude must be between -180 and 180');
}
```

### Name Validation

```dart
// In WayPoint constructor
if (name.isEmpty) {
  throw FormatException('Waypoint name cannot be empty');
}
if (name.trim().isEmpty) {
  throw FormatException('Waypoint name cannot be whitespace only');
}
```

### Count Validation

```dart
static WaypointValidationResult validateWaypointCount(
  List<WayPoint> waypoints, {
  MapBoxNavigationMode? mode,
  TargetPlatform? platform,
}) {
  final warnings = <String>[];
  final recommendations = <String>[];
  var isValid = true;

  // Minimum check
  if (waypoints.length < 2) {
    warnings.add('At least 2 waypoints required');
    isValid = false;
  }

  // API limit warning
  if (waypoints.length > 25) {
    warnings.add('Exceeds Mapbox API limit of 25 waypoints');
    recommendations.add('Consider splitting into multiple routes');
  }

  // iOS traffic mode limit
  if (platform == TargetPlatform.iOS &&
      mode == MapBoxNavigationMode.drivingWithTraffic &&
      waypoints.length > 3) {
    warnings.add('iOS drivingWithTraffic mode limited to 3 waypoints');
    recommendations.add('Use driving mode for more waypoints on iOS');
  }

  // Silent waypoint checks
  if (waypoints.isNotEmpty && waypoints.first.isSilent) {
    warnings.add('First waypoint cannot be silent (will be announced)');
  }
  if (waypoints.length > 1 && waypoints.last.isSilent) {
    warnings.add('Last waypoint cannot be silent (will be announced)');
  }

  return WaypointValidationResult(
    isValid: isValid,
    hasWarnings: warnings.isNotEmpty,
    warnings: warnings,
    recommendations: recommendations,
  );
}
```

## Test Cases

### Unit Tests

```dart
// test/unit/waypoint_validation_test.dart

void main() {
  group('WayPoint Validation', () {
    group('Coordinate validation', () {
      test('should accept valid coordinates', () {
        expect(
          () => WayPoint(name: 'Valid', latitude: 37.7749, longitude: -122.4194),
          returnsNormally,
        );
      });

      test('should accept boundary coordinates', () {
        expect(
          () => WayPoint(name: 'North Pole', latitude: 90.0, longitude: 0.0),
          returnsNormally,
        );
        expect(
          () => WayPoint(name: 'Date Line', latitude: 0.0, longitude: 180.0),
          returnsNormally,
        );
        expect(
          () => WayPoint(name: 'Date Line', latitude: 0.0, longitude: -180.0),
          returnsNormally,
        );
      });

      test('should reject invalid latitude', () {
        expect(
          () => WayPoint(name: 'Invalid', latitude: 91.0, longitude: 0.0),
          throwsFormatException,
        );
        expect(
          () => WayPoint(name: 'Invalid', latitude: -91.0, longitude: 0.0),
          throwsFormatException,
        );
      });

      test('should reject invalid longitude', () {
        expect(
          () => WayPoint(name: 'Invalid', latitude: 0.0, longitude: 181.0),
          throwsFormatException,
        );
        expect(
          () => WayPoint(name: 'Invalid', latitude: 0.0, longitude: -181.0),
          throwsFormatException,
        );
      });
    });

    group('Name validation', () {
      test('should accept valid names', () {
        expect(
          () => WayPoint(name: 'Valid Name', latitude: 0.0, longitude: 0.0),
          returnsNormally,
        );
      });

      test('should reject empty name', () {
        expect(
          () => WayPoint(name: '', latitude: 0.0, longitude: 0.0),
          throwsFormatException,
        );
      });

      test('should reject whitespace-only name', () {
        expect(
          () => WayPoint(name: '   ', latitude: 0.0, longitude: 0.0),
          throwsFormatException,
        );
      });
    });

    group('Count validation', () {
      test('should require minimum 2 waypoints', () {
        final result = WayPoint.validateWaypointCount([
          WayPoint(name: 'Only', latitude: 0.0, longitude: 0.0),
        ]);

        expect(result.isValid, isFalse);
      });

      test('should pass with 2 waypoints', () {
        final result = WayPoint.validateWaypointCount([
          WayPoint(name: 'A', latitude: 0.0, longitude: 0.0),
          WayPoint(name: 'B', latitude: 1.0, longitude: 1.0),
        ]);

        expect(result.isValid, isTrue);
      });

      test('should warn above 25 waypoints', () {
        final waypoints = List.generate(
          26,
          (i) => WayPoint(name: 'WP$i', latitude: i.toDouble(), longitude: 0.0),
        );

        final result = WayPoint.validateWaypointCount(waypoints);

        expect(result.isValid, isTrue);
        expect(result.hasWarnings, isTrue);
      });
    });

    group('Silent waypoint validation', () {
      test('should warn if first waypoint is silent', () {
        final result = WayPoint.validateWaypointCount([
          WayPoint(name: 'A', latitude: 0.0, longitude: 0.0, isSilent: true),
          WayPoint(name: 'B', latitude: 1.0, longitude: 1.0),
        ]);

        expect(result.hasWarnings, isTrue);
      });

      test('should warn if last waypoint is silent', () {
        final result = WayPoint.validateWaypointCount([
          WayPoint(name: 'A', latitude: 0.0, longitude: 0.0),
          WayPoint(name: 'B', latitude: 1.0, longitude: 1.0, isSilent: true),
        ]);

        expect(result.hasWarnings, isTrue);
      });

      test('should accept silent middle waypoints', () {
        final result = WayPoint.validateWaypointCount([
          WayPoint(name: 'A', latitude: 0.0, longitude: 0.0),
          WayPoint(name: 'B', latitude: 0.5, longitude: 0.5, isSilent: true),
          WayPoint(name: 'C', latitude: 1.0, longitude: 1.0),
        ]);

        expect(result.isValid, isTrue);
        expect(result.hasWarnings, isFalse);
      });
    });
  });
}
```

### Integration Tests

```dart
// test/integration/waypoint_validation_test.dart

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('should reject invalid waypoints in navigation', (tester) async {
    // Navigation with < 2 waypoints should fail
    final result = await MapBoxNavigation.instance.startNavigation(
      wayPoints: [
        WayPoint(name: 'Only', latitude: 37.7749, longitude: -122.4194),
      ],
      options: MapBoxOptions(simulateRoute: true),
    );

    expect(result, isFalse);
  });
}
```

## Acceptance Criteria

- [ ] WayPoint constructor validates coordinates
- [ ] WayPoint constructor validates name is not empty
- [ ] WayPoint constructor validates name is not whitespace-only
- [ ] validateWaypointCount requires minimum 2 waypoints
- [ ] validateWaypointCount warns above 25 waypoints
- [ ] validateWaypointCount warns about iOS traffic mode limit
- [ ] validateWaypointCount warns about silent first waypoint
- [ ] validateWaypointCount warns about silent last waypoint
- [ ] Validation result provides clear messages
- [ ] Validation result provides recommendations
- [ ] formattedMessage is suitable for display to users
- [ ] Validation works on both platforms
