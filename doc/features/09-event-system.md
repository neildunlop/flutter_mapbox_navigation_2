# Feature Spec: Event System

## Overview

The Event System provides real-time updates about navigation state, route progress, user location, and map interactions. Events are streamed via Flutter event channels, enabling responsive UI updates.

**Priority:** P0 - Must Have
**Effort:** Medium
**Dependencies:** None (foundational system)

## User Stories

1. **As a developer**, I receive route building progress events to show loading states.
2. **As a developer**, I receive progress updates to display distance and time remaining.
3. **As a developer**, I receive arrival events when users reach waypoints.
4. **As a developer**, I receive off-route events to handle rerouting.
5. **As a developer**, I receive navigation state changes (started, cancelled, finished).
6. **As a developer**, I receive marker tap events for interactive POIs.

## Technical Approach

Events are delivered through Flutter event channels:

| Channel | Purpose |
|---------|---------|
| `flutter_mapbox_navigation/events` | Navigation and route events |
| `flutter_mapbox_navigation/marker_events` | Static marker interactions |

Events are encoded as JSON and decoded into typed Dart objects.

## API Reference

### MapBoxEvent Enum

```dart
enum MapBoxEvent {
  // Route building
  route_building,
  route_built,
  route_build_failed,
  route_build_cancelled,
  route_build_no_routes_found,

  // Navigation state
  navigation_running,
  navigation_cancelled,
  navigation_finished,

  // Progress
  progress_change,

  // Waypoints
  on_arrival,
  user_off_route,

  // Rerouting
  reroute_along,
  milestone_event,
  faster_route_found,

  // Speech
  speech_announcement,

  // Marker
  marker_tapped,
  marker_callout_tapped,

  // Map interactions
  on_map_tap,
  on_map_long_click,
  on_map_move_begin,

  // Other
  waypoint_arrival,
  next_route_leg_start,
}
```

### RouteEvent Class

```dart
class RouteEvent {
  final MapBoxEvent eventType;
  final dynamic data;

  // For progress events, data is RouteProgressEvent
  // For route built events, data contains route information
}
```

### RouteProgressEvent Class

```dart
class RouteProgressEvent {
  // Current location
  final double? currentLegIndex;
  final double? currentStepIndex;
  final String? currentStepInstruction;
  final String? currentModifier;
  final String? currentModifierType;

  // Route progress
  final double? distanceRemaining;
  final double? durationRemaining;
  final double? distanceTraveled;

  // Leg progress
  final double? legDistanceRemaining;
  final double? legDurationRemaining;
  final int? legIndex;

  // Step progress
  final double? stepDistanceRemaining;
  final double? stepDurationRemaining;

  // State
  final bool? arrived;
  final bool? isNavigating;

  // Current location coordinates
  final double? latitude;
  final double? longitude;

  // Current leg and step details
  final RouteLeg? currentLeg;
  final RouteStep? currentStep;
}
```

### RouteLeg Class

```dart
class RouteLeg {
  final double? distance;
  final double? duration;
  final String? summary;
  final List<RouteStep>? steps;
}
```

### RouteStep Class

```dart
class RouteStep {
  final double? distance;
  final double? duration;
  final String? instruction;
  final String? name;
  final String? mode;
  final String? maneuverType;
  final String? maneuverModifier;
  final double? maneuverBearingBefore;
  final double? maneuverBearingAfter;
  final String? drivingSide;
}
```

### Registering Event Listeners

```dart
// Register for navigation events
MapBoxNavigation.instance.registerRouteEventListener(_onRouteEvent);

Future<void> _onRouteEvent(RouteEvent event) async {
  switch (event.eventType) {
    case MapBoxEvent.route_building:
      setState(() => _isLoading = true);
      break;

    case MapBoxEvent.route_built:
      setState(() {
        _isLoading = false;
        _routeBuilt = true;
      });
      break;

    case MapBoxEvent.route_build_failed:
      setState(() {
        _isLoading = false;
        _error = 'Failed to build route';
      });
      break;

    case MapBoxEvent.navigation_running:
      setState(() => _isNavigating = true);
      break;

    case MapBoxEvent.progress_change:
      final progress = event.data as RouteProgressEvent;
      setState(() {
        _distanceRemaining = progress.distanceRemaining;
        _durationRemaining = progress.durationRemaining;
        _currentInstruction = progress.currentStepInstruction;
      });
      break;

    case MapBoxEvent.on_arrival:
      final progress = event.data as RouteProgressEvent;
      if (progress.arrived == true) {
        _handleArrival();
      }
      break;

    case MapBoxEvent.user_off_route:
      print('User went off route - rerouting...');
      break;

    case MapBoxEvent.navigation_finished:
    case MapBoxEvent.navigation_cancelled:
      setState(() => _isNavigating = false);
      break;

    default:
      break;
  }
}
```

### Marker Events

```dart
// Register for marker tap events
MapBoxNavigation.instance.registerStaticMarkerTapListener((marker) {
  print('Marker tapped: ${marker.title}');
  _showMarkerDetails(marker);
});
```

### Full-Screen Events

```dart
// Register for full-screen navigation events
MapBoxNavigation.instance.registerFullScreenEventListener((event) {
  if (event.type == FullScreenEventType.markerTapped) {
    final marker = event.data as StaticMarker;
    print('Marker tapped in full-screen: ${marker.title}');
  } else if (event.type == FullScreenEventType.mapTapped) {
    final location = event.data as Map<String, double>;
    print('Map tapped at: ${location['lat']}, ${location['lng']}');
  }
});
```

## Event Flow

```
Navigation Started
       │
       ▼
route_building ──► route_built OR route_build_failed
       │
       ▼
navigation_running
       │
       ▼
progress_change (continuous) ───► user_off_route (if applicable)
       │                                   │
       │                                   ▼
       │                             reroute_along
       │                                   │
       ▼                                   ▼
on_arrival ────────────────────────► Continue or Finish
       │
       ▼
navigation_finished OR navigation_cancelled
```

## Test Cases

### Unit Tests

```dart
// test/unit/event_system_test.dart

void main() {
  group('RouteEvent', () {
    test('should parse route_building event', () {
      final event = RouteEvent(
        eventType: MapBoxEvent.route_building,
        data: null,
      );

      expect(event.eventType, equals(MapBoxEvent.route_building));
    });

    test('should parse progress_change event with data', () {
      final progressData = {
        'distanceRemaining': 5000.0,
        'durationRemaining': 600.0,
        'currentStepInstruction': 'Turn right',
      };

      final progress = RouteProgressEvent.fromJson(progressData);

      expect(progress.distanceRemaining, equals(5000.0));
      expect(progress.durationRemaining, equals(600.0));
      expect(progress.currentStepInstruction, equals('Turn right'));
    });
  });

  group('RouteProgressEvent', () {
    test('should parse all fields', () {
      final json = {
        'distanceRemaining': 10000.0,
        'durationRemaining': 1200.0,
        'distanceTraveled': 5000.0,
        'legIndex': 1,
        'arrived': false,
        'isNavigating': true,
        'latitude': 37.7749,
        'longitude': -122.4194,
      };

      final progress = RouteProgressEvent.fromJson(json);

      expect(progress.distanceRemaining, equals(10000.0));
      expect(progress.legIndex, equals(1));
      expect(progress.arrived, isFalse);
      expect(progress.latitude, equals(37.7749));
    });

    test('should handle missing optional fields', () {
      final json = <String, dynamic>{};

      final progress = RouteProgressEvent.fromJson(json);

      expect(progress.distanceRemaining, isNull);
      expect(progress.currentStepInstruction, isNull);
    });
  });

  group('MapBoxEvent', () {
    test('should have all expected events', () {
      expect(MapBoxEvent.values, contains(MapBoxEvent.route_building));
      expect(MapBoxEvent.values, contains(MapBoxEvent.progress_change));
      expect(MapBoxEvent.values, contains(MapBoxEvent.on_arrival));
      expect(MapBoxEvent.values, contains(MapBoxEvent.navigation_finished));
    });
  });
}
```

### Integration Tests

```dart
// test/integration/event_system_test.dart

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('should receive route events', (tester) async {
    final events = <MapBoxEvent>[];

    MapBoxNavigation.instance.registerRouteEventListener((event) {
      events.add(event.eventType);
    });

    await MapBoxNavigation.instance.startNavigation(
      wayPoints: [
        WayPoint(name: 'A', latitude: 37.7749, longitude: -122.4194),
        WayPoint(name: 'B', latitude: 37.7949, longitude: -122.3994),
      ],
      options: MapBoxOptions(simulateRoute: true),
    );

    await tester.pumpAndSettle(const Duration(seconds: 5));

    expect(events, contains(MapBoxEvent.route_building));
    expect(events, contains(MapBoxEvent.route_built));
    expect(events, contains(MapBoxEvent.navigation_running));

    await MapBoxNavigation.instance.finishNavigation();
  });

  testWidgets('should receive progress events', (tester) async {
    RouteProgressEvent? lastProgress;

    MapBoxNavigation.instance.registerRouteEventListener((event) {
      if (event.eventType == MapBoxEvent.progress_change) {
        lastProgress = event.data as RouteProgressEvent;
      }
    });

    await MapBoxNavigation.instance.startNavigation(
      wayPoints: [
        WayPoint(name: 'A', latitude: 37.7749, longitude: -122.4194),
        WayPoint(name: 'B', latitude: 37.7949, longitude: -122.3994),
      ],
      options: MapBoxOptions(simulateRoute: true),
    );

    await tester.pump(const Duration(seconds: 10));

    expect(lastProgress, isNotNull);
    expect(lastProgress!.distanceRemaining, isNotNull);

    await MapBoxNavigation.instance.finishNavigation();
  });
}
```

### E2E Tests

```dart
// test/e2e/event_system_test.dart

void main() {
  group('Event System E2E', () {
    testWidgets('complete navigation event flow', (tester) async {
      // 1. Register event listener
      // 2. Start navigation
      // 3. Verify route_building received
      // 4. Verify route_built received
      // 5. Verify navigation_running received
      // 6. Wait for progress_change events
      // 7. Verify on_arrival at destination
      // 8. Verify navigation_finished
    });

    testWidgets('handle reroute events', (tester) async {
      // 1. Start navigation with simulation
      // 2. Simulate going off route
      // 3. Verify user_off_route event
      // 4. Verify reroute_along event
    });

    testWidgets('marker tap events', (tester) async {
      // 1. Add static markers
      // 2. Start navigation
      // 3. Tap on a marker
      // 4. Verify marker tap event received
      // 5. Verify marker data is correct
    });
  });
}
```

## Acceptance Criteria

- [ ] route_building event fires when route calculation starts
- [ ] route_built event fires when route is ready
- [ ] route_build_failed event fires on error
- [ ] navigation_running event fires when navigation starts
- [ ] progress_change events fire continuously during navigation
- [ ] Progress events contain distance and duration remaining
- [ ] Progress events contain current step instruction
- [ ] on_arrival event fires at each waypoint
- [ ] user_off_route event fires when user leaves route
- [ ] navigation_finished event fires at end
- [ ] navigation_cancelled event fires on user cancel
- [ ] Marker tap events contain complete marker data
- [ ] Events work on both iOS and Android
- [ ] Multiple listeners can be registered
