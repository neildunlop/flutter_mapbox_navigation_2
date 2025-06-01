# Map Marker Implementation

This document outlines the implementation plan for adding marker support to the flutter_mapbox_navigation package.

## Overview

The implementation provides a generic way to add, update, and remove markers on the map. This functionality can be used for various purposes such as:
- Vehicle tracking
- Points of interest
- Waypoints
- Custom location markers

## Implementation Details

### 1. Marker Model

```dart
class MapMarker {
  final String id;
  final double latitude;
  final double longitude;
  final String? name;
  final Map<String, dynamic>? properties;  // For additional data like icon, color, etc.

  MapMarker({
    required this.id,
    required this.latitude,
    required this.longitude,
    this.name,
    this.properties,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'latitude': latitude,
      'longitude': longitude,
      'name': name,
      'properties': properties,
    };
  }
}
```

### 2. Flutter Layer Implementation

Add these methods to the MapBoxNavigation class:

```dart
class MapBoxNavigation {
  // ... existing code ...

  /// Add a marker to the map
  Future<bool> addMarker(MapMarker marker) async {
    return await _channel.invokeMethod('addMarker', marker.toMap());
  }

  /// Update a marker's position
  Future<bool> updateMarker(MapMarker marker) async {
    return await _channel.invokeMethod('updateMarker', marker.toMap());
  }

  /// Remove a marker
  Future<bool> removeMarker(String markerId) async {
    return await _channel.invokeMethod('removeMarker', {'id': markerId});
  }

  /// Remove all markers
  Future<bool> clearMarkers() async {
    return await _channel.invokeMethod('clearMarkers');
  }
}
```

### 3. Platform-Specific Implementations

#### Android (Kotlin)

```kotlin
// In EmbeddedNavigationMapView.kt
private val markers = mutableMapOf<String, PointAnnotation>()

fun addMarker(marker: MapMarker) {
    val point = Point.fromLngLat(marker.longitude, marker.latitude)
    val annotation = PointAnnotation(point)
    // Use default marker or custom marker from properties
    val iconName = marker.properties?.get("icon") as? String ?: "default-marker"
    annotation.setIconImage(iconName)
    annotation.setIconSize(1.0)
    markers[marker.id] = annotation
    binding.navigationView.mapView.annotations.addAnnotation(annotation)
}

fun updateMarker(marker: MapMarker) {
    markers[marker.id]?.let { annotation ->
        annotation.point = Point.fromLngLat(marker.longitude, marker.latitude)
        binding.navigationView.mapView.annotations.updateAnnotation(annotation)
    }
}
```

#### iOS (Swift)

```swift
// In EmbeddedNavigationView.swift
private var markers: [String: PointAnnotation] = [:]

func addMarker(marker: MapMarker) {
    let point = Point(CLLocationCoordinate2D(latitude: marker.latitude, longitude: marker.longitude))
    let annotation = PointAnnotation(coordinate: point)
    // Use default marker or custom marker from properties
    let iconName = marker.properties?["icon"] as? String ?? "default-marker"
    annotation.image = .init(image: UIImage(named: iconName)!, scale: 1.0)
    markers[marker.id] = annotation
    navigationMapView.mapView.annotations.addAnnotation(annotation)
}

func updateMarker(marker: MapMarker) {
    if let annotation = markers[marker.id] {
        annotation.coordinate = CLLocationCoordinate2D(latitude: marker.latitude, longitude: marker.longitude)
        navigationMapView.mapView.annotations.updateAnnotation(annotation)
    }
}
```

### 4. Usage Example

```dart
class MapMarkerManager {
  final MapBoxNavigation _navigation = MapBoxNavigation.instance;
  final Map<String, MapMarker> _markers = {};

  // Add or update a marker
  void updateMarker(String id, double lat, double lng, {String? name, Map<String, dynamic>? properties}) {
    final marker = MapMarker(
      id: id,
      latitude: lat,
      longitude: lng,
      name: name,
      properties: properties,
    );

    if (_markers.containsKey(id)) {
      _navigation.updateMarker(marker);
    } else {
      _navigation.addMarker(marker);
    }
    _markers[id] = marker;
  }

  // Remove a marker
  void removeMarker(String id) {
    _navigation.removeMarker(id);
    _markers.remove(id);
  }

  // Clear all markers
  void clearMarkers() {
    _navigation.clearMarkers();
    _markers.clear();
  }
}
```

## Future Enhancements

The following features could be added in future updates:

1. Marker Clustering
   - Support for grouping markers when zoomed out
   - Custom cluster styling
   - Cluster click handling

2. Marker Interaction
   - Click/tap handling
   - Long press handling
   - Custom info windows

3. Advanced Styling
   - Custom marker colors
   - Variable marker sizes
   - Marker rotation for directional markers
   - Custom marker images

4. Performance Optimizations
   - Batch marker updates
   - Marker culling for off-screen markers
   - Efficient marker removal

## Implementation Notes

1. Default Marker
   - A default marker image should be included in the package assets
   - Custom markers can be provided through the properties map

2. Marker Properties
   - The properties map allows for flexible marker customization
   - Common properties include:
     - icon: Custom marker image name
     - color: Marker color
     - size: Marker size
     - rotation: Marker rotation angle

3. Platform Considerations
   - Android and iOS implementations should be kept in sync
   - Platform-specific optimizations may be needed
   - Consider platform limitations for marker count and update frequency 

## Next Steps

The following features can be implemented to enhance the marker functionality:

### 1. Marker Clustering
```dart
class MapBoxNavigation {
  // ... existing code ...

  /// Enable marker clustering with custom options
  Future<bool> enableMarkerClustering({
    required double maxZoom,  // Maximum zoom level for clustering
    required double minZoom,  // Minimum zoom level for clustering
    Map<String, dynamic>? clusterProperties,  // Custom cluster styling
  }) async {
    return await _channel.invokeMethod('enableMarkerClustering', {
      'maxZoom': maxZoom,
      'minZoom': minZoom,
      'properties': clusterProperties,
    });
  }
}
```

### 2. Marker Click Handling
```dart
class MapBoxNavigation {
  // ... existing code ...

  /// Register a callback for marker clicks
  void onMarkerClick(Function(MapMarker marker) callback) {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onMarkerClick') {
        final marker = MapMarker.fromMap(call.arguments);
        callback(marker);
      }
    });
  }
}
```

### 3. Custom Marker Styles
```dart
class MapMarkerStyle {
  final String? icon;
  final Color? color;
  final double? size;
  final double? rotation;
  final Map<String, dynamic>? customProperties;

  MapMarkerStyle({
    this.icon,
    this.color,
    this.size,
    this.rotation,
    this.customProperties,
  });

  Map<String, dynamic> toMap() {
    return {
      'icon': icon,
      'color': color?.value,
      'size': size,
      'rotation': rotation,
      'customProperties': customProperties,
    };
  }
}

class MapMarker {
  // ... existing code ...
  final MapMarkerStyle? style;

  MapMarker({
    required this.id,
    required this.latitude,
    required this.longitude,
    this.name,
    this.properties,
    this.style,
  });
}
```

### 4. Directional Markers
```dart
class DirectionalMarker extends MapMarker {
  final double heading;  // Heading in degrees (0-360)
  final bool autoRotate;  // Whether to automatically rotate based on movement

  DirectionalMarker({
    required super.id,
    required super.latitude,
    required super.longitude,
    required this.heading,
    this.autoRotate = true,
    super.name,
    super.properties,
  });

  @override
  Map<String, dynamic> toMap() {
    return {
      ...super.toMap(),
      'heading': heading,
      'autoRotate': autoRotate,
    };
  }
}

// Usage example:
void updateVehiclePosition(String id, double lat, double lng, double heading) {
  final marker = DirectionalMarker(
    id: id,
    latitude: lat,
    longitude: lng,
    heading: heading,
    style: MapMarkerStyle(
      icon: 'car-marker',
      rotation: heading,
    ),
  );
  _navigation.updateMarker(marker);
}
```

### Implementation Priority

1. **High Priority**
   - Marker click handling (essential for user interaction)
   - Basic custom marker styles (colors and sizes)

2. **Medium Priority**
   - Directional markers (important for vehicle tracking)
   - Advanced custom marker styles (rotation, custom images)

3. **Lower Priority**
   - Marker clustering (useful for large numbers of markers)
   - Performance optimizations

### Platform-Specific Considerations

#### Android
- Use Mapbox's `PointAnnotationManager` for efficient marker management
- Implement marker clustering using `ClusterManager`
- Handle marker rotation using `PointAnnotation.setIconRotate()`

#### iOS
- Use Mapbox's `PointAnnotationManager` for marker management
- Implement clustering using `PointAnnotationClusterManager`
- Handle marker rotation using `PointAnnotation.imageRotation`

### Testing Strategy

1. Unit Tests
   - Test marker creation and property mapping
   - Test style application
   - Test rotation calculations

2. Integration Tests
   - Test marker addition/removal
   - Test marker updates
   - Test click handling

3. Performance Tests
   - Test with large numbers of markers
   - Test update frequency
   - Test memory usage 

### Testing with Android Studio

#### Setup

1. **Project Configuration**
   ```yaml
   # pubspec.yaml
   dev_dependencies:
     flutter_test:
       sdk: flutter
     integration_test:
       sdk: flutter
   ```

2. **Test Directory Structure**
   ```
   your_project/
   ├── test/
   │   ├── unit/
   │   │   └── marker_test.dart
   │   └── integration/
   │       └── marker_integration_test.dart
   └── integration_test/
       └── marker_test.dart
   ```

#### Running Tests

1. **Unit Tests**
   ```bash
   # Run all unit tests
   flutter test

   # Run specific test file
   flutter test test/unit/marker_test.dart
   ```

2. **Integration Tests**
   ```bash
   # Run on connected device/emulator
   flutter test integration_test/marker_test.dart
   ```

#### Example Test Cases

1. **Unit Test Example**
   ```dart
   // test/unit/marker_test.dart
   import 'package:flutter_test/flutter_test.dart';
   import 'package:your_package/map_marker.dart';

   void main() {
     group('MapMarker Tests', () {
       test('creates marker with required properties', () {
         final marker = MapMarker(
           id: 'test-1',
           latitude: 51.5074,
           longitude: -0.1278,
         );
         
         expect(marker.id, equals('test-1'));
         expect(marker.latitude, equals(51.5074));
         expect(marker.longitude, equals(-0.1278));
       });

       test('converts to map correctly', () {
         final marker = MapMarker(
           id: 'test-1',
           latitude: 51.5074,
           longitude: -0.1278,
           name: 'Test Marker',
         );
         
         final map = marker.toMap();
         expect(map['id'], equals('test-1'));
         expect(map['name'], equals('Test Marker'));
       });
     });
   });
   ```

2. **Integration Test Example**
   ```dart
   // integration_test/marker_test.dart
   import 'package:flutter_test/flutter_test.dart';
   import 'package:integration_test/integration_test.dart';
   import 'package:your_package/map_marker.dart';
   import 'package:your_package/map_box_navigation.dart';

   void main() {
     IntegrationTestWidgetsFlutterBinding.ensureInitialized();

     group('Marker Integration Tests', () {
       testWidgets('adds and updates marker', (WidgetTester tester) async {
         final navigation = MapBoxNavigation.instance;
         
         // Add marker
         final marker = MapMarker(
           id: 'test-1',
           latitude: 51.5074,
           longitude: -0.1278,
         );
         
         await navigation.addMarker(marker);
         
         // Update marker
         final updatedMarker = MapMarker(
           id: 'test-1',
           latitude: 51.5075,
           longitude: -0.1279,
         );
         
         await navigation.updateMarker(updatedMarker);
       });
     });
   });
   ```

#### Debugging Tips

1. **Using Android Studio's Debug Tools**
   - Set breakpoints in your Flutter code
   - Use the Flutter Inspector to examine widget tree
   - Monitor performance using the Flutter Performance view

2. **Common Issues**
   - Map not loading: Check Mapbox token and internet connection
   - Markers not appearing: Verify coordinates and zoom level
   - Performance issues: Monitor marker count and update frequency

3. **Testing Different Scenarios**
   - Test with different map styles
   - Test with various marker configurations
   - Test on different device sizes and orientations

#### Device Emulator Setup

1. **Android Emulator**
   - Open Android Studio
   - Go to Tools > Device Manager
   - Create a new virtual device
   - Recommended settings:
     - API Level: 30 or higher
     - RAM: 2GB or more
     - Internal Storage: 2GB or more

2. **iOS Simulator** (if on macOS)
   - Open Xcode
   - Go to Xcode > Open Developer Tool > Simulator
   - Choose device type and iOS version

3. **Physical Device Testing**
   - Enable Developer Options on Android device
   - Enable USB debugging
   - Trust computer on iOS device
   - Connect device and run `flutter devices` to verify connection 