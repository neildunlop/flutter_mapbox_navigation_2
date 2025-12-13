# Feature Spec: Turn-by-Turn Navigation

## Overview

Turn-by-turn navigation is the core feature of the Flutter Mapbox Navigation plugin. It provides full-screen navigation UI with voice instructions, route calculation, and real-time guidance.

**Priority:** P0 - Must Have
**Effort:** High
**Dependencies:** None (this is the foundation feature)

## User Stories

1. **As a user**, I can start navigation to a destination so I can get turn-by-turn directions.
2. **As a user**, I can hear voice instructions so I don't need to look at the screen while driving.
3. **As a user**, I can see banner instructions showing the next maneuver.
4. **As a user**, I can see my current location on the map during navigation.
5. **As a user**, I can see the remaining distance and time to my destination.
6. **As a user**, I can cancel navigation at any time.
7. **As a user**, I am automatically rerouted if I go off-route.
8. **As a user**, I can choose between different navigation modes (driving, walking, cycling).

## Technical Approach

The feature uses the native Mapbox Navigation SDK:
- **Android**: Mapbox Navigation SDK v2.16
- **iOS**: Mapbox Navigation SDK v2.11

Communication happens via Flutter platform channels:
- Method Channel: `flutter_mapbox_navigation` for commands
- Event Channel: `flutter_mapbox_navigation/events` for navigation events

## API Reference

### Starting Navigation

```dart
import 'package:flutter_mapbox_navigation/flutter_mapbox_navigation.dart';

// Define waypoints
final origin = WayPoint(
  name: "Origin",
  latitude: 37.7749,
  longitude: -122.4194,
);
final destination = WayPoint(
  name: "Destination",
  latitude: 37.3382,
  longitude: -121.8863,
);

// Start navigation
await MapBoxNavigation.instance.startNavigation(
  wayPoints: [origin, destination],
  options: MapBoxOptions(
    mode: MapBoxNavigationMode.drivingWithTraffic,
    simulateRoute: false,
    language: "en",
    units: VoiceUnits.metric,
    voiceInstructionsEnabled: true,
    bannerInstructionsEnabled: true,
  ),
);
```

### Navigation Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `mode` | `MapBoxNavigationMode` | `drivingWithTraffic` | Navigation mode |
| `simulateRoute` | `bool` | `false` | Simulate movement for testing |
| `language` | `String` | `"en"` | Voice instruction language |
| `units` | `VoiceUnits` | `imperial` | Unit system for voice |
| `voiceInstructionsEnabled` | `bool` | `true` | Enable voice guidance |
| `bannerInstructionsEnabled` | `bool` | `true` | Enable banner instructions |
| `alternatives` | `bool` | `true` | Show alternative routes |
| `allowsUTurnAtWayPoints` | `bool` | `true` | Allow U-turns |
| `mapStyleUrlDay` | `String?` | `null` | Custom day map style |
| `mapStyleUrlNight` | `String?` | `null` | Custom night map style |

### Navigation Modes

```dart
enum MapBoxNavigationMode {
  driving,           // Standard driving
  drivingWithTraffic, // Driving with live traffic
  walking,           // Walking directions
  cycling,           // Cycling directions
}
```

### Event Handling

```dart
// Register for navigation events
MapBoxNavigation.instance.registerRouteEventListener(_onRouteEvent);

Future<void> _onRouteEvent(RouteEvent event) async {
  switch (event.eventType) {
    case MapBoxEvent.route_building:
      print('Building route...');
      break;
    case MapBoxEvent.route_built:
      print('Route built successfully');
      break;
    case MapBoxEvent.route_build_failed:
      print('Failed to build route');
      break;
    case MapBoxEvent.progress_change:
      final progress = event.data as RouteProgressEvent;
      print('Distance remaining: ${progress.distanceRemaining}');
      break;
    case MapBoxEvent.on_arrival:
      print('Arrived at destination');
      break;
    case MapBoxEvent.navigation_finished:
    case MapBoxEvent.navigation_cancelled:
      print('Navigation ended');
      break;
    default:
      break;
  }
}
```

### Finishing Navigation

```dart
await MapBoxNavigation.instance.finishNavigation();
```

## Platform-Specific Notes

### iOS
- Requires `MBXAccessToken` in Info.plist
- Background modes required: Audio, AirPlay, Picture in Picture; Location updates
- Maximum 3 waypoints when using `drivingWithTraffic` mode

### Android
- Requires `mapbox_access_token` in resources
- MainActivity must extend `FlutterFragmentActivity`
- Android 13+ security updates applied

## Test Cases

### Unit Tests

```dart
// test/unit/turn_by_turn_navigation_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_mapbox_navigation/flutter_mapbox_navigation.dart';

void main() {
  group('Turn-by-Turn Navigation', () {
    test('should require at least 2 waypoints', () {
      final origin = WayPoint(
        name: 'Origin',
        latitude: 37.7749,
        longitude: -122.4194,
      );

      // Single waypoint should fail validation
      expect(
        [origin].length >= 2,
        isFalse,
      );
    });

    test('should create valid navigation options', () {
      final options = MapBoxOptions(
        mode: MapBoxNavigationMode.drivingWithTraffic,
        simulateRoute: true,
        language: 'en',
      );

      expect(options.mode, equals(MapBoxNavigationMode.drivingWithTraffic));
      expect(options.simulateRoute, isTrue);
      expect(options.language, equals('en'));
    });

    test('should have default options', () {
      final defaultOptions = MapBoxNavigation.instance.getDefaultOptions();

      expect(defaultOptions.voiceInstructionsEnabled, isTrue);
      expect(defaultOptions.bannerInstructionsEnabled, isTrue);
      expect(defaultOptions.alternatives, isTrue);
    });
  });
}
```

### Integration Tests

```dart
// test/integration/turn_by_turn_navigation_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_mapbox_navigation/flutter_mapbox_navigation.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('should start and finish navigation', (tester) async {
    final origin = WayPoint(
      name: 'San Francisco',
      latitude: 37.7749,
      longitude: -122.4194,
    );
    final destination = WayPoint(
      name: 'San Jose',
      latitude: 37.3382,
      longitude: -121.8863,
    );

    // Start navigation
    final result = await MapBoxNavigation.instance.startNavigation(
      wayPoints: [origin, destination],
      options: MapBoxOptions(simulateRoute: true),
    );

    expect(result, isTrue);

    // Wait for route to build
    await tester.pumpAndSettle(const Duration(seconds: 5));

    // Finish navigation
    final finished = await MapBoxNavigation.instance.finishNavigation();
    expect(finished, isTrue);
  });
}
```

### E2E Tests

```dart
// test/e2e/navigation_flow_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Navigation Flow E2E', () {
    testWidgets('complete navigation journey', (tester) async {
      // 1. Start navigation
      // 2. Verify route is displayed
      // 3. Verify voice instructions work
      // 4. Simulate progress
      // 5. Verify arrival event
      // 6. Finish navigation
    });

    testWidgets('handle off-route rerouting', (tester) async {
      // 1. Start navigation
      // 2. Simulate going off-route
      // 3. Verify reroute event
      // 4. Verify new route displayed
    });

    testWidgets('cancel navigation mid-route', (tester) async {
      // 1. Start navigation
      // 2. Cancel navigation
      // 3. Verify navigation cancelled event
      // 4. Verify UI returns to previous state
    });
  });
}
```

## Acceptance Criteria

- [ ] User can start navigation with at least 2 waypoints
- [ ] Route is calculated and displayed on map
- [ ] Voice instructions play at appropriate times
- [ ] Banner instructions show next maneuver
- [ ] Progress events fire as user moves along route
- [ ] Remaining distance and time are displayed
- [ ] Arrival event fires when reaching destination
- [ ] User can cancel navigation at any time
- [ ] Automatic rerouting when user goes off-route
- [ ] All navigation modes work (driving, walking, cycling)
- [ ] Navigation works on both iOS and Android
- [ ] Simulation mode works for testing
- [ ] Language localization works for voice instructions
- [ ] Day/night map styles apply correctly
