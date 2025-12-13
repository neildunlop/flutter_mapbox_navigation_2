# Feature Spec: Embedded Navigation View

## Overview

Embedded Navigation View allows developers to integrate the navigation map directly into their Flutter widget tree rather than launching a full-screen native view. This provides more control over the UI and enables custom overlays.

**Priority:** P1 - Should Have
**Effort:** Medium
**Dependencies:** Turn-by-Turn Navigation (01)

## User Stories

1. **As a developer**, I can embed the navigation view in my app layout so I can show navigation alongside other UI elements.
2. **As a developer**, I can control the navigation view programmatically via a controller.
3. **As a user**, I can see navigation in a portion of the screen while other content is visible.
4. **As a developer**, I can receive navigation events from the embedded view.
5. **As a developer**, I can build routes and start navigation through the controller.

## Technical Approach

The embedded view uses Flutter's platform view system:
- **Android**: `PlatformViewLink` with hybrid composition
- **iOS**: `UiKitView`

A controller (`MapBoxNavigationViewController`) provides programmatic access to:
- Route building
- Navigation start/stop
- Free drive mode

## API Reference

### Adding Embedded View

```dart
import 'package:flutter_mapbox_navigation/flutter_mapbox_navigation.dart';

class EmbeddedNavigationScreen extends StatefulWidget {
  @override
  State<EmbeddedNavigationScreen> createState() => _EmbeddedNavigationScreenState();
}

class _EmbeddedNavigationScreenState extends State<EmbeddedNavigationScreen> {
  MapBoxNavigationViewController? _controller;
  bool _routeBuilt = false;

  final _options = MapBoxOptions(
    initialLatitude: 37.7749,
    initialLongitude: -122.4194,
    zoom: 13.0,
    voiceInstructionsEnabled: true,
    bannerInstructionsEnabled: true,
    mode: MapBoxNavigationMode.drivingWithTraffic,
    simulateRoute: true,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Embedded Navigation')),
      body: Column(
        children: [
          // Embedded navigation view
          Expanded(
            child: MapBoxNavigationView(
              options: _options,
              onRouteEvent: _onRouteEvent,
              onCreated: _onCreated,
            ),
          ),
          // Control buttons
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: _buildRoute,
                  child: const Text('Build Route'),
                ),
                ElevatedButton(
                  onPressed: _routeBuilt ? _startNavigation : null,
                  child: const Text('Start'),
                ),
                ElevatedButton(
                  onPressed: _finishNavigation,
                  child: const Text('Stop'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _onCreated(MapBoxNavigationViewController controller) async {
    _controller = controller;
    await controller.initialize();
  }

  Future<void> _onRouteEvent(RouteEvent event) async {
    if (event.eventType == MapBoxEvent.route_built) {
      setState(() => _routeBuilt = true);
    }
  }

  Future<void> _buildRoute() async {
    final waypoints = [
      WayPoint(name: 'Start', latitude: 37.7749, longitude: -122.4194),
      WayPoint(name: 'End', latitude: 37.7949, longitude: -122.3994),
    ];
    await _controller?.buildRoute(wayPoints: waypoints);
  }

  Future<void> _startNavigation() async {
    await _controller?.startNavigation();
  }

  Future<void> _finishNavigation() async {
    await _controller?.finishNavigation();
  }
}
```

### MapBoxNavigationView Widget

```dart
MapBoxNavigationView({
  required MapBoxOptions options,
  ValueSetter<RouteEvent>? onRouteEvent,
  void Function(MapBoxNavigationViewController)? onCreated,
})
```

### MapBoxNavigationViewController

```dart
class MapBoxNavigationViewController {
  /// Initialize the controller
  Future<void> initialize();

  /// Build a route through waypoints
  Future<bool?> buildRoute({required List<WayPoint> wayPoints});

  /// Start navigation on the built route
  Future<bool?> startNavigation();

  /// Start free drive mode
  Future<bool?> startFreeDrive();

  /// Clear the current route
  Future<bool?> clearRoute();

  /// Finish and exit navigation
  Future<bool?> finishNavigation();

  /// Recenter camera on user location
  Future<bool?> recenter();
}
```

## Implementation Notes

### Platform Views

The embedded view is created using platform-specific implementations:

**Android** (`EmbeddedNavigationMapView.kt`):
- Extends `PlatformView`
- Creates `MapView` with navigation session
- Handles lifecycle through `FlutterFragmentActivity`

**iOS** (`EmbeddedNavigationView.swift`):
- Implements `FlutterPlatformView`
- Creates `NavigationMapView`
- Manages navigation session lifecycle

### Communication

- Same method channel as full-screen navigation
- Same event channel for route events
- Controller wraps platform channel calls

## Test Cases

### Unit Tests

```dart
// test/unit/embedded_navigation_view_test.dart

void main() {
  group('Embedded Navigation View', () {
    test('should create MapBoxOptions for embedded view', () {
      final options = MapBoxOptions(
        initialLatitude: 37.7749,
        initialLongitude: -122.4194,
        zoom: 13.0,
      );

      expect(options.initialLatitude, equals(37.7749));
      expect(options.initialLongitude, equals(-122.4194));
      expect(options.zoom, equals(13.0));
    });
  });
}
```

### Widget Tests

```dart
// test/widget/embedded_navigation_view_test.dart

void main() {
  testWidgets('should create MapBoxNavigationView', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MapBoxNavigationView(
            options: MapBoxOptions(
              initialLatitude: 37.7749,
              initialLongitude: -122.4194,
            ),
            onCreated: (controller) {},
          ),
        ),
      ),
    );

    expect(find.byType(MapBoxNavigationView), findsOneWidget);
  });
}
```

### Integration Tests

```dart
// test/integration/embedded_navigation_test.dart

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('should build and start navigation in embedded view', (tester) async {
    MapBoxNavigationViewController? controller;
    bool routeBuilt = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MapBoxNavigationView(
            options: MapBoxOptions(
              initialLatitude: 37.7749,
              initialLongitude: -122.4194,
              simulateRoute: true,
            ),
            onCreated: (c) async {
              controller = c;
              await c.initialize();
            },
            onRouteEvent: (event) {
              if (event.eventType == MapBoxEvent.route_built) {
                routeBuilt = true;
              }
            },
          ),
        ),
      ),
    );

    await tester.pumpAndSettle(const Duration(seconds: 2));

    // Build route
    await controller?.buildRoute(wayPoints: [
      WayPoint(name: 'A', latitude: 37.7749, longitude: -122.4194),
      WayPoint(name: 'B', latitude: 37.7949, longitude: -122.3994),
    ]);

    await tester.pumpAndSettle(const Duration(seconds: 3));
    expect(routeBuilt, isTrue);

    // Start navigation
    await controller?.startNavigation();
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // Finish navigation
    await controller?.finishNavigation();
  });
}
```

### E2E Tests

```dart
// test/e2e/embedded_navigation_test.dart

void main() {
  group('Embedded Navigation E2E', () {
    testWidgets('full embedded navigation flow', (tester) async {
      // 1. Display embedded view in widget tree
      // 2. Build route via controller
      // 3. Start navigation
      // 4. Receive progress events
      // 5. Complete navigation
      // 6. Clear route
    });

    testWidgets('embedded free drive mode', (tester) async {
      // 1. Display embedded view
      // 2. Start free drive via controller
      // 3. Verify location tracking
      // 4. Exit free drive
    });

    testWidgets('resize embedded view', (tester) async {
      // 1. Display embedded view at one size
      // 2. Resize container
      // 3. Verify view adapts
    });
  });
}
```

## Acceptance Criteria

- [ ] MapBoxNavigationView displays map in widget tree
- [ ] Controller is provided via onCreated callback
- [ ] Controller can build routes with waypoints
- [ ] Controller can start navigation
- [ ] Controller can start free drive mode
- [ ] Controller can clear and finish navigation
- [ ] Route events are received via onRouteEvent
- [ ] View properly resizes with container
- [ ] View works in Column, Row, Stack layouts
- [ ] Memory is properly released when view is disposed
- [ ] Works on both iOS and Android
