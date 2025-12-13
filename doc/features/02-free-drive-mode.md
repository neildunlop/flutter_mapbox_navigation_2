# Feature Spec: Free Drive Mode

## Overview

Free Drive Mode enables passive navigation without a set destination. This mode is useful for displaying the user's location on the map while generating location updates and speed data without following a specific route.

**Priority:** P1 - Should Have
**Effort:** Low
**Dependencies:** Turn-by-Turn Navigation (01)

## User Stories

1. **As a user**, I can explore an area without setting a destination so I can see my location and surroundings.
2. **As a user**, I can see my current speed while in free drive mode.
3. **As a user**, I can see nearby roads and points of interest while driving.
4. **As a user**, I can transition from free drive to navigation when I decide on a destination.
5. **As a user**, I can exit free drive mode at any time.

## Technical Approach

Free Drive Mode uses the same native Mapbox Navigation SDK as turn-by-turn navigation but operates in "passive" mode without route calculation.

Key differences from active navigation:
- No route is calculated or displayed
- No turn-by-turn instructions
- Location tracking is still active
- Map follows user location
- Progress events still fire with location data

## API Reference

### Starting Free Drive

```dart
import 'package:flutter_mapbox_navigation/flutter_mapbox_navigation.dart';

// Start free drive mode
await MapBoxNavigation.instance.startFreeDrive(
  options: MapBoxOptions(
    initialLatitude: 37.7749,
    initialLongitude: -122.4194,
    zoom: 15.0,
    mode: MapBoxNavigationMode.drivingWithTraffic,
    units: VoiceUnits.metric,
    language: "en",
  ),
);
```

### Free Drive Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `initialLatitude` | `double?` | `null` | Initial map center latitude |
| `initialLongitude` | `double?` | `null` | Initial map center longitude |
| `zoom` | `double` | `15.0` | Initial zoom level |
| `mode` | `MapBoxNavigationMode` | `drivingWithTraffic` | Navigation mode |
| `units` | `VoiceUnits` | `imperial` | Unit system |
| `mapStyleUrlDay` | `String?` | `null` | Custom day map style |
| `mapStyleUrlNight` | `String?` | `null` | Custom night map style |

### Ending Free Drive

```dart
// End free drive mode
await MapBoxNavigation.instance.finishNavigation();
```

### Event Handling in Free Drive

```dart
MapBoxNavigation.instance.registerRouteEventListener(_onFreeDriveEvent);

Future<void> _onFreeDriveEvent(RouteEvent event) async {
  switch (event.eventType) {
    case MapBoxEvent.navigation_running:
      print('Free drive mode active');
      break;
    case MapBoxEvent.progress_change:
      final progress = event.data as RouteProgressEvent;
      // Location updates still available
      print('Current location: ${progress.currentLocation}');
      break;
    case MapBoxEvent.navigation_finished:
    case MapBoxEvent.navigation_cancelled:
      print('Free drive ended');
      break;
    default:
      break;
  }
}
```

## Implementation Notes

### Flutter Layer

Free drive is initiated through the same platform interface as navigation:

```dart
// lib/src/flutter_mapbox_navigation.dart
Future<bool?> startFreeDrive({MapBoxOptions? options}) async {
  options ??= _defaultOptions;
  return FlutterMapboxNavigationPlatform.instance.startFreeDrive(options);
}
```

### Platform Implementation

**Android** (`TurnByTurn.kt`):
- Starts navigation session without route
- Location puck follows user
- Map camera follows location

**iOS** (`NavigationFactory.swift`):
- Initializes navigation view in passive mode
- No route request made
- Continuous location tracking

## Test Cases

### Unit Tests

```dart
// test/unit/free_drive_mode_test.dart

void main() {
  group('Free Drive Mode', () {
    test('should accept options without waypoints', () {
      final options = MapBoxOptions(
        initialLatitude: 37.7749,
        initialLongitude: -122.4194,
        zoom: 15.0,
      );

      expect(options.initialLatitude, equals(37.7749));
      expect(options.initialLongitude, equals(-122.4194));
      expect(options.zoom, equals(15.0));
    });

    test('should use default options when none provided', () {
      final defaultOptions = MapBoxNavigation.instance.getDefaultOptions();
      expect(defaultOptions, isNotNull);
    });
  });
}
```

### Integration Tests

```dart
// test/integration/free_drive_mode_test.dart

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('should start and stop free drive mode', (tester) async {
    // Start free drive
    final result = await MapBoxNavigation.instance.startFreeDrive(
      options: MapBoxOptions(
        initialLatitude: 37.7749,
        initialLongitude: -122.4194,
        zoom: 15.0,
      ),
    );

    expect(result, isTrue);

    // Wait for mode to initialize
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // End free drive
    final finished = await MapBoxNavigation.instance.finishNavigation();
    expect(finished, isTrue);
  });
}
```

### E2E Tests

```dart
// test/e2e/free_drive_test.dart

void main() {
  group('Free Drive E2E', () {
    testWidgets('free drive displays user location', (tester) async {
      // 1. Start free drive mode
      // 2. Verify map is displayed
      // 3. Verify user location puck is visible
      // 4. Verify location updates are received
      // 5. End free drive mode
    });

    testWidgets('transition from free drive to navigation', (tester) async {
      // 1. Start free drive mode
      // 2. User selects destination
      // 3. Transition to navigation mode
      // 4. Verify route is displayed
    });
  });
}
```

## Acceptance Criteria

- [ ] User can start free drive mode without specifying destination
- [ ] Map displays and follows user location
- [ ] Location updates are received in progress events
- [ ] Free drive works on both iOS and Android
- [ ] User can exit free drive mode at any time
- [ ] Map styling (day/night) works in free drive mode
- [ ] Zoom level is configurable
- [ ] Initial position can be specified
