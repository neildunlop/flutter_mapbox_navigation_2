# Feature Spec: Marker Popups

## Overview

Marker Popups provide a Flutter-based overlay system for displaying rich information when users interact with static markers. Unlike native tooltips, these popups are rendered entirely in Flutter, enabling custom UI designs and cross-platform consistency.

**Priority:** P2 - Nice to Have
**Effort:** Medium
**Dependencies:** Static Markers (05)

## User Stories

1. **As a user**, I can tap on a marker to see detailed information in a popup.
2. **As a user**, I can close the popup by tapping a close button or outside the popup.
3. **As a developer**, I can customize the popup appearance and content.
4. **As a developer**, I can add action buttons to popups (e.g., "Add to Route").
5. **As a user**, I can see popups positioned correctly relative to the marker.

## Technical Approach

Marker popups use Flutter's overlay system combined with coordinate conversion utilities:

1. **Coordinate Conversion**: Convert marker lat/lng to screen position
2. **Overlay Positioning**: Position popup relative to marker
3. **Custom Builder**: Allow developers to provide custom popup UI
4. **Default Popup**: Material Design popup when no custom builder provided

### Architecture

```
StaticMarker Tap Event
       │
       ▼
MarkerPopupManager
       │
       ├─► Get marker screen position
       │
       ├─► Create popup overlay entry
       │
       └─► Position and display popup
```

## API Reference

### Starting Flutter Navigation with Popups

```dart
await MapBoxNavigation.instance.startFlutterNavigation(
  context: context,
  wayPoints: [origin, destination],
  options: MapBoxOptions(simulateRoute: true),
  // Optional: Custom popup builder
  markerPopupBuilder: (context, marker, onClose) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(child: Text(marker.title, style: TextStyle(fontWeight: FontWeight.bold))),
              IconButton(icon: Icon(Icons.close), onPressed: onClose),
            ],
          ),
          if (marker.description != null)
            Text(marker.description!),
          ElevatedButton(
            onPressed: () {
              // Add to route logic
              onClose();
            },
            child: Text('Add to Route'),
          ),
        ],
      ),
    );
  },
  onMarkerTap: (marker) {
    // Additional handler (called alongside popup)
    print('Marker tapped: ${marker.title}');
  },
);
```

### MarkerPopupBuilder Type

```dart
typedef MarkerPopupBuilder = Widget Function(
  BuildContext context,
  StaticMarker marker,
  VoidCallback onClose,
);
```

### Default Popup

When no custom builder is provided, a default Material Design popup is shown:

```dart
// Default popup includes:
// - Marker title (bold)
// - Category label
// - Description (if available)
// - Metadata display (if available)
// - Close button
// - "Add to Route" button
```

### MarkerPopupManager

Internal manager for popup lifecycle:

```dart
class MarkerPopupManager {
  /// Show popup for a marker
  void showPopup(StaticMarker marker, Offset position);

  /// Hide the current popup
  void hidePopup();

  /// Check if a popup is currently visible
  bool get isPopupVisible;

  /// Get the currently displayed marker
  StaticMarker? get currentMarker;
}
```

### Coordinate Conversion

```dart
// Get marker screen position
final position = await MapBoxNavigation.instance.getMarkerScreenPosition(marker.id);
if (position != null) {
  print('Marker at screen position: ${position.dx}, ${position.dy}');
}

// Get map viewport info
final viewport = await MapBoxNavigation.instance.getMapViewport();
if (viewport != null) {
  print('Map center: ${viewport.center}');
  print('Zoom level: ${viewport.zoomLevel}');
}
```

### MapViewport Class

```dart
class MapViewport {
  final LatLng center;
  final double zoomLevel;
  final Size size;
  final double bearing;
  final double tilt;
}
```

## Implementation Notes

### Flutter Navigation Mode

Popups only work in Flutter navigation mode (`startFlutterNavigation`), not in native full-screen mode (`startNavigation`). This is because:
- Native views cannot render Flutter overlays
- Platform views allow Flutter to overlay content

### Popup Positioning

The popup is positioned above the marker with arrow pointing down:
- Default offset: 10 pixels above marker
- Popup constrained to screen bounds
- Repositions if marker moves during navigation

## Test Cases

### Unit Tests

```dart
// test/unit/marker_popup_test.dart

void main() {
  group('MarkerPopupBuilder', () {
    test('should accept marker and callback', () {
      MarkerPopupBuilder builder = (context, marker, onClose) {
        return Container();
      };

      expect(builder, isNotNull);
    });
  });

  group('MapViewport', () {
    test('should create viewport from map data', () {
      final viewport = MapViewport(
        center: LatLng(37.7749, -122.4194),
        zoomLevel: 15.0,
        size: Size(375, 667),
        bearing: 0.0,
        tilt: 0.0,
      );

      expect(viewport.center.latitude, equals(37.7749));
      expect(viewport.zoomLevel, equals(15.0));
    });
  });
}
```

### Widget Tests

```dart
// test/widget/marker_popup_test.dart

void main() {
  testWidgets('should display default popup content', (tester) async {
    final marker = StaticMarker(
      id: 'test_1',
      latitude: 37.7749,
      longitude: -122.4194,
      title: 'Test Marker',
      category: 'test',
      description: 'A test description',
    );

    // Build default popup widget
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DefaultMarkerPopup(
            marker: marker,
            onClose: () {},
          ),
        ),
      ),
    );

    expect(find.text('Test Marker'), findsOneWidget);
    expect(find.text('A test description'), findsOneWidget);
  });

  testWidgets('should call onClose when close button tapped', (tester) async {
    bool closed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DefaultMarkerPopup(
            marker: StaticMarker(
              id: 'test_1',
              latitude: 37.7749,
              longitude: -122.4194,
              title: 'Test',
              category: 'test',
            ),
            onClose: () => closed = true,
          ),
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.close));
    expect(closed, isTrue);
  });
}
```

### Integration Tests

```dart
// test/integration/marker_popup_test.dart

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('popup appears on marker tap', (tester) async {
    // Start Flutter navigation with markers
    // Tap on a marker
    // Verify popup appears
    // Close popup
    // Verify popup disappears
  });

  testWidgets('custom popup builder is used', (tester) async {
    bool customBuilderCalled = false;

    await MapBoxNavigation.instance.startFlutterNavigation(
      context: context,
      wayPoints: waypoints,
      markerPopupBuilder: (context, marker, onClose) {
        customBuilderCalled = true;
        return Text('Custom Popup');
      },
    );

    // Trigger marker tap
    // Verify custom builder was called
    expect(customBuilderCalled, isTrue);
  });
}
```

### E2E Tests

```dart
// test/e2e/marker_popup_test.dart

void main() {
  group('Marker Popup E2E', () {
    testWidgets('full popup interaction flow', (tester) async {
      // 1. Start Flutter navigation with markers
      // 2. Tap on a marker
      // 3. Verify popup displays with correct content
      // 4. Tap "Add to Route" button
      // 5. Verify marker added to route
      // 6. Close popup
      // 7. Verify popup dismissed
    });

    testWidgets('popup repositions with map pan', (tester) async {
      // 1. Show popup for a marker
      // 2. Pan the map
      // 3. Verify popup moves with marker
    });

    testWidgets('only one popup visible at a time', (tester) async {
      // 1. Tap marker A, verify popup A
      // 2. Tap marker B (without closing A)
      // 3. Verify popup A closed, popup B visible
    });
  });
}
```

## Acceptance Criteria

- [ ] Popup appears when marker is tapped
- [ ] Default popup shows title, category, description
- [ ] Custom popup builder is used when provided
- [ ] Close button dismisses popup
- [ ] Tapping outside popup dismisses it
- [ ] Popup is positioned correctly above marker
- [ ] Popup stays within screen bounds
- [ ] Only one popup visible at a time
- [ ] Popup works during active navigation
- [ ] Popup works in Flutter navigation mode
- [ ] "Add to Route" button adds waypoint
- [ ] Works on both iOS and Android
