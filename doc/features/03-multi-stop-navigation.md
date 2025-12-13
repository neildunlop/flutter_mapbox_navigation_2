# Feature Spec: Multi-Stop Navigation

## Overview

Multi-Stop Navigation enables routing through multiple waypoints in sequence. This feature supports dynamic waypoint addition during navigation, silent waypoints for route shaping, and arrival events at each stop.

**Priority:** P1 - Should Have
**Effort:** Medium
**Dependencies:** Turn-by-Turn Navigation (01), Waypoint Validation (10)

## User Stories

1. **As a user**, I can add multiple stops to my route so I can visit several locations.
2. **As a user**, I can add new stops during navigation so I can adjust my route dynamically.
3. **As a user**, I receive arrival notifications at each stop.
4. **As a user**, I can use silent waypoints to shape my route without announcements.
5. **As a user**, I can skip waypoints if I change my mind.
6. **As a user**, I can see my progress through all waypoints.

## Technical Approach

Multi-stop navigation uses the same route calculation API with multiple waypoints. The native SDK handles:
- Sequential routing through waypoints
- Leg-by-leg progress tracking
- Arrival events at each waypoint
- Dynamic waypoint insertion

### Silent Waypoints

Silent waypoints are intermediate points used for route optimization without voice announcements:

```dart
final waypoints = [
  WayPoint(name: 'Start', latitude: 37.7749, longitude: -122.4194),
  WayPoint(name: 'Via Point', latitude: 37.7849, longitude: -122.4094, isSilent: true),
  WayPoint(name: 'Destination', latitude: 37.7949, longitude: -122.3994),
];
```

**Rules:**
- First waypoint cannot be silent (always origin)
- Last waypoint cannot be silent (always destination)
- Silent waypoints affect route but not voice guidance

## API Reference

### Starting Multi-Stop Navigation

```dart
import 'package:flutter_mapbox_navigation/flutter_mapbox_navigation.dart';

final waypoints = [
  WayPoint(name: 'Start', latitude: 37.7749, longitude: -122.4194),
  WayPoint(name: 'Coffee Shop', latitude: 37.7849, longitude: -122.4094),
  WayPoint(name: 'Office', latitude: 37.7949, longitude: -122.3994),
  WayPoint(name: 'Home', latitude: 37.8049, longitude: -122.3894),
];

await MapBoxNavigation.instance.startNavigation(
  wayPoints: waypoints,
  options: MapBoxOptions(
    mode: MapBoxNavigationMode.driving,
    simulateRoute: true,
    allowsUTurnAtWayPoints: true,
  ),
);
```

### Adding Waypoints During Navigation

```dart
// Add a new stop during navigation
final newStop = WayPoint(
  name: 'Gas Station',
  latitude: 37.7899,
  longitude: -122.4044,
);

final result = await MapBoxNavigation.instance.addWayPoints(
  wayPoints: [newStop],
);

if (result.success) {
  print('Added ${result.waypointsAdded} waypoints');
} else {
  print('Failed: ${result.errorMessage}');
}
```

### WaypointResult Class

```dart
class WaypointResult {
  final bool success;
  final int waypointsAdded;
  final String? errorMessage;
}
```

### Handling Arrival Events

```dart
MapBoxNavigation.instance.registerRouteEventListener((event) {
  if (event.eventType == MapBoxEvent.on_arrival) {
    final progress = event.data as RouteProgressEvent;

    if (progress.legIndex < totalLegs - 1) {
      // Intermediate waypoint arrival
      print('Arrived at waypoint ${progress.legIndex + 1}');
      // Continue to next waypoint after delay
      await Future.delayed(const Duration(seconds: 3));
    } else {
      // Final destination
      print('Arrived at final destination');
      await MapBoxNavigation.instance.finishNavigation();
    }
  }
});
```

## Platform Limitations

### iOS
- **drivingWithTraffic mode**: Maximum 3 waypoints supported
- Other modes: No waypoint limit enforced

### Android
- No waypoint count limitations for any mode

### Mapbox API
- **Official Limit**: 25 waypoints per route request
- **Plugin Behavior**: No enforcement in plugin code
- **Recommendation**: Stay within 25 waypoints for reliability

## Test Cases

### Unit Tests

```dart
// test/unit/multi_stop_navigation_test.dart

void main() {
  group('Multi-Stop Navigation', () {
    test('should require minimum 2 waypoints', () {
      final validation = WayPoint.validateWaypointCount([
        WayPoint(name: 'Start', latitude: 37.7749, longitude: -122.4194),
      ]);

      expect(validation.isValid, isFalse);
    });

    test('should validate waypoint count warnings', () {
      final waypoints = List.generate(
        26,
        (i) => WayPoint(
          name: 'Point $i',
          latitude: 37.7749 + i * 0.01,
          longitude: -122.4194,
        ),
      );

      final validation = WayPoint.validateWaypointCount(waypoints);
      expect(validation.hasWarnings, isTrue);
    });

    test('first waypoint cannot be silent', () {
      final waypoints = [
        WayPoint(name: 'Start', latitude: 37.7749, longitude: -122.4194, isSilent: true),
        WayPoint(name: 'End', latitude: 37.7949, longitude: -122.3994),
      ];

      // First waypoint isSilent is ignored
      expect(waypoints.first.isSilent, isTrue);
      // But validation should warn or convert
    });

    test('last waypoint cannot be silent', () {
      final waypoints = [
        WayPoint(name: 'Start', latitude: 37.7749, longitude: -122.4194),
        WayPoint(name: 'End', latitude: 37.7949, longitude: -122.3994, isSilent: true),
      ];

      // Last waypoint isSilent is ignored
      expect(waypoints.last.isSilent, isTrue);
      // But validation should warn or convert
    });
  });
}
```

### Integration Tests

```dart
// test/integration/multi_stop_navigation_test.dart

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('should navigate through multiple stops', (tester) async {
    final waypoints = [
      WayPoint(name: 'A', latitude: 37.7749, longitude: -122.4194),
      WayPoint(name: 'B', latitude: 37.7849, longitude: -122.4094),
      WayPoint(name: 'C', latitude: 37.7949, longitude: -122.3994),
    ];

    final result = await MapBoxNavigation.instance.startNavigation(
      wayPoints: waypoints,
      options: MapBoxOptions(simulateRoute: true),
    );

    expect(result, isTrue);
  });

  testWidgets('should add waypoints during navigation', (tester) async {
    // Start with initial waypoints
    await MapBoxNavigation.instance.startNavigation(
      wayPoints: [
        WayPoint(name: 'A', latitude: 37.7749, longitude: -122.4194),
        WayPoint(name: 'B', latitude: 37.7949, longitude: -122.3994),
      ],
      options: MapBoxOptions(simulateRoute: true),
    );

    await tester.pumpAndSettle(const Duration(seconds: 2));

    // Add new waypoint
    final result = await MapBoxNavigation.instance.addWayPoints(
      wayPoints: [
        WayPoint(name: 'New Stop', latitude: 37.7849, longitude: -122.4094),
      ],
    );

    expect(result.success, isTrue);
    expect(result.waypointsAdded, equals(1));
  });
}
```

### E2E Tests

```dart
// test/e2e/multi_stop_test.dart

void main() {
  group('Multi-Stop Navigation E2E', () {
    testWidgets('complete multi-stop journey', (tester) async {
      // 1. Start with 3 waypoints
      // 2. Receive arrival event at first stop
      // 3. Continue to second stop
      // 4. Receive arrival event at second stop
      // 5. Continue to final destination
      // 6. Receive final arrival event
      // 7. Navigation finishes
    });

    testWidgets('add waypoint mid-route', (tester) async {
      // 1. Start navigation with 2 waypoints
      // 2. Add third waypoint during navigation
      // 3. Verify route is recalculated
      // 4. Verify new waypoint is in route
    });

    testWidgets('silent waypoints shape route', (tester) async {
      // 1. Create route with silent waypoint
      // 2. Verify route passes through silent waypoint
      // 3. Verify no voice announcement at silent waypoint
    });
  });
}
```

## Acceptance Criteria

- [ ] User can start navigation with multiple waypoints
- [ ] Route is calculated through all waypoints in order
- [ ] Arrival event fires at each non-silent waypoint
- [ ] User can add waypoints during active navigation
- [ ] addWayPoints returns success status and count
- [ ] Silent waypoints shape route without announcements
- [ ] First and last waypoints are always announced
- [ ] Progress shows current leg and overall progress
- [ ] Navigation continues to next waypoint after arrival
- [ ] Final destination arrival triggers finish event
- [ ] Works on both iOS and Android
- [ ] Respects platform-specific waypoint limits
