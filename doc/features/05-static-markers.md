# Feature Spec: Static Markers

## Overview

Static Markers allow developers to display custom points of interest (POIs) on the navigation map. Markers support categories, custom icons, clustering, distance filtering, and tap interactions.

**Priority:** P1 - Should Have
**Effort:** Medium
**Dependencies:** Turn-by-Turn Navigation (01), Embedded Navigation View (04)

## User Stories

1. **As a developer**, I can add custom markers to the navigation map to highlight points of interest.
2. **As a user**, I can see nearby gas stations, restaurants, and scenic viewpoints during navigation.
3. **As a user**, I can tap on markers to see more details.
4. **As a developer**, I can categorize markers and filter them by type.
5. **As a developer**, I can cluster markers in dense areas to avoid clutter.
6. **As a developer**, I can update or remove markers dynamically.

## Technical Approach

Static markers are implemented using native annotation APIs:
- **Android**: Mapbox Maps SDK `PointAnnotationManager`
- **iOS**: Mapbox Maps SDK `PointAnnotationManager`

Communication:
- Method Channel: Add/remove/update markers
- Event Channel: `flutter_mapbox_navigation/marker_events` for tap events

## API Reference

### StaticMarker Model

```dart
class StaticMarker {
  final String id;
  final double latitude;
  final double longitude;
  final String title;
  final String category;
  final String? description;
  final String? iconId;
  final Color? customColor;
  final int? priority;
  final bool isVisible;
  final Map<String, dynamic>? metadata;
}
```

### MarkerConfiguration

```dart
class MarkerConfiguration {
  final bool showDuringNavigation;    // Default: true
  final bool showInFreeDrive;         // Default: true
  final bool showOnEmbeddedMap;       // Default: true
  final double? maxDistanceFromRoute; // km, null = no limit
  final double minZoomLevel;          // Default: 10.0
  final bool enableClustering;        // Default: true
  final int? maxMarkersToShow;        // null = no limit
  final Function(StaticMarker)? onMarkerTap;
  final String? defaultIconId;
  final Color? defaultColor;
}
```

### Adding Markers

```dart
import 'package:flutter_mapbox_navigation/flutter_mapbox_navigation.dart';

final markers = [
  StaticMarker(
    id: 'scenic_1',
    latitude: 37.7749,
    longitude: -122.4194,
    title: 'Golden Gate Bridge',
    category: 'scenic',
    description: 'Iconic suspension bridge',
    iconId: MarkerIcons.scenic,
    customColor: Colors.orange,
    priority: 5,
    metadata: {'rating': 4.8},
  ),
  StaticMarker(
    id: 'petrol_1',
    latitude: 37.7849,
    longitude: -122.4094,
    title: 'Shell Gas Station',
    category: 'petrol_station',
    description: '24/7 fuel station',
    iconId: MarkerIcons.petrolStation,
    metadata: {'price': 1.85, 'brand': 'Shell'},
  ),
];

await MapBoxNavigation.instance.addStaticMarkers(
  markers: markers,
  configuration: MarkerConfiguration(
    maxDistanceFromRoute: 5.0,
    enableClustering: true,
  ),
);
```

### Handling Marker Taps

```dart
await MapBoxNavigation.instance.registerStaticMarkerTapListener(
  (marker) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(marker.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (marker.description != null)
              Text(marker.description!),
            if (marker.metadata != null)
              ...marker.metadata!.entries.map(
                (e) => Text('${e.key}: ${e.value}'),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  },
);
```

### Removing Markers

```dart
// Remove specific markers
await MapBoxNavigation.instance.removeStaticMarkers(
  markerIds: ['scenic_1', 'petrol_1'],
);

// Clear all markers
await MapBoxNavigation.instance.clearAllStaticMarkers();
```

### Updating Configuration

```dart
await MapBoxNavigation.instance.updateMarkerConfiguration(
  MarkerConfiguration(
    maxDistanceFromRoute: 10.0,
    enableClustering: false,
  ),
);
```

### Getting Current Markers

```dart
final markers = await MapBoxNavigation.instance.getStaticMarkers();
print('Current markers: ${markers?.length}');
```

## Available Icons

### MarkerIcons Class

```dart
class MarkerIcons {
  // Transportation
  static const petrolStation = 'petrol_station';
  static const chargingStation = 'charging_station';
  static const parking = 'parking';
  static const busStop = 'bus_stop';
  static const trainStation = 'train_station';
  static const airport = 'airport';
  static const port = 'port';

  // Food & Services
  static const restaurant = 'restaurant';
  static const cafe = 'cafe';
  static const hotel = 'hotel';
  static const shop = 'shop';
  static const pharmacy = 'pharmacy';
  static const hospital = 'hospital';
  static const police = 'police';
  static const fireStation = 'fire_station';

  // Scenic & Recreation
  static const scenic = 'scenic';
  static const park = 'park';
  static const beach = 'beach';
  static const mountain = 'mountain';
  static const lake = 'lake';
  static const waterfall = 'waterfall';
  static const viewpoint = 'viewpoint';
  static const hiking = 'hiking';

  // Safety & Traffic
  static const speedCamera = 'speed_camera';
  static const accident = 'accident';
  static const construction = 'construction';
  static const trafficLight = 'traffic_light';
  static const speedBump = 'speed_bump';
  static const schoolZone = 'school_zone';

  // General
  static const pin = 'pin';
  static const star = 'star';
  static const heart = 'heart';
  static const flag = 'flag';
  static const warning = 'warning';
  static const info = 'info';
  static const question = 'question';
}
```

## Platform Icon Coverage

| Platform | Status | Notes |
|----------|--------|-------|
| iOS | Complete | 40+ SF Symbols |
| Android | Partial | 12 essential icons, 35 fallback to default pin |

## Test Cases

### Unit Tests

```dart
// test/unit/static_markers_test.dart

void main() {
  group('StaticMarker', () {
    test('should create marker with required fields', () {
      final marker = StaticMarker(
        id: 'test_1',
        latitude: 37.7749,
        longitude: -122.4194,
        title: 'Test Marker',
        category: 'test',
      );

      expect(marker.id, equals('test_1'));
      expect(marker.latitude, equals(37.7749));
      expect(marker.longitude, equals(-122.4194));
      expect(marker.title, equals('Test Marker'));
      expect(marker.category, equals('test'));
    });

    test('should serialize to JSON', () {
      final marker = StaticMarker(
        id: 'test_1',
        latitude: 37.7749,
        longitude: -122.4194,
        title: 'Test Marker',
        category: 'test',
        metadata: {'key': 'value'},
      );

      final json = marker.toJson();
      expect(json['id'], equals('test_1'));
      expect(json['metadata'], equals({'key': 'value'}));
    });

    test('should deserialize from JSON', () {
      final json = {
        'id': 'test_1',
        'latitude': 37.7749,
        'longitude': -122.4194,
        'title': 'Test Marker',
        'category': 'test',
      };

      final marker = StaticMarker.fromJson(json);
      expect(marker.id, equals('test_1'));
    });

    test('should create copy with updated fields', () {
      final original = StaticMarker(
        id: 'test_1',
        latitude: 37.7749,
        longitude: -122.4194,
        title: 'Original',
        category: 'test',
      );

      final copy = original.copyWith(title: 'Updated');
      expect(copy.title, equals('Updated'));
      expect(copy.id, equals(original.id));
    });
  });

  group('MarkerIcons', () {
    test('should list all icons', () {
      final icons = MarkerIcons.getAllIcons();
      expect(icons.length, greaterThan(30));
    });

    test('should validate icon IDs', () {
      expect(MarkerIcons.isValidIcon('petrol_station'), isTrue);
      expect(MarkerIcons.isValidIcon('invalid_icon'), isFalse);
    });
  });
}
```

### Integration Tests

```dart
// test/integration/static_markers_test.dart

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('should add and remove static markers', (tester) async {
    final markers = [
      StaticMarker(
        id: 'test_1',
        latitude: 37.7749,
        longitude: -122.4194,
        title: 'Test Marker',
        category: 'test',
      ),
    ];

    // Add markers
    final added = await MapBoxNavigation.instance.addStaticMarkers(
      markers: markers,
    );
    expect(added, isTrue);

    // Get markers
    final current = await MapBoxNavigation.instance.getStaticMarkers();
    expect(current?.length, equals(1));

    // Remove markers
    final removed = await MapBoxNavigation.instance.removeStaticMarkers(
      markerIds: ['test_1'],
    );
    expect(removed, isTrue);
  });
}
```

### E2E Tests

```dart
// test/e2e/static_markers_test.dart

void main() {
  group('Static Markers E2E', () {
    testWidgets('markers appear during navigation', (tester) async {
      // 1. Add static markers
      // 2. Start navigation
      // 3. Verify markers are visible on map
      // 4. Tap a marker
      // 5. Verify tap event is received
    });

    testWidgets('marker clustering works', (tester) async {
      // 1. Add many markers in close proximity
      // 2. Verify clustering at low zoom
      // 3. Zoom in
      // 4. Verify individual markers appear
    });

    testWidgets('distance filtering works', (tester) async {
      // 1. Configure max distance from route
      // 2. Add markers at various distances
      // 3. Build route
      // 4. Verify only nearby markers are visible
    });
  });
}
```

## Acceptance Criteria

- [ ] Developer can add static markers to map
- [ ] Markers display with correct icons and colors
- [ ] Markers can be categorized
- [ ] Marker metadata is preserved
- [ ] Tap events are received when markers are tapped
- [ ] Developer can remove specific markers
- [ ] Developer can clear all markers
- [ ] Clustering works for dense marker areas
- [ ] Distance filtering shows only nearby markers
- [ ] Markers work during navigation, free drive, and embedded modes
- [ ] Works on both iOS and Android
- [ ] Performance is acceptable with 100+ markers
