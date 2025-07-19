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

## Performance Analysis and Recommendations

### Multi-Vehicle Tracking Efficiency

This section provides guidance on using the marker implementation for tracking multiple vehicles in real-time, including performance considerations and optimization strategies.

#### Current Implementation Limitations

The proposed marker implementation has several limitations when tracking multiple vehicles:

1. **Individual Marker Updates**
   - Each vehicle update requires a separate method channel call
   - No batch processing for multiple marker updates
   - High overhead for frequent updates (e.g., every 1-2 seconds)

2. **Missing Critical Optimizations**
   - Batch marker updates not implemented
   - No viewport-based culling for off-screen markers
   - No update throttling or rate limiting

#### Performance Impact Analysis

##### Method Channel Overhead
- **50 vehicles × 1 update/second = 50 method channel calls/second**
- Each call involves: Flutter → Platform → Mapbox SDK → UI update
- **Significant battery drain** and potential frame drops

##### Memory Usage
- **50 PointAnnotation objects** in memory
- **50 marker tracking objects** in Flutter
- **Platform-specific marker storage** (Android/iOS)

##### Update Frequency Considerations
- **1-2 second updates**: 25-50 method calls/second (problematic)
- **5 second updates**: 10 method calls/second (manageable)
- **10+ second updates**: 5 or fewer calls/second (acceptable)

#### Recommended Approaches by Vehicle Count

##### For 1-10 Vehicles
**Current implementation is suitable**
```dart
// Direct approach works well
void updateVehicle(String id, double lat, double lng) {
  _navigation.updateMarker(MapMarker(
    id: id,
    latitude: lat,
    longitude: lng,
  ));
}
```

##### For 10-50 Vehicles
**Requires optimizations for best performance**

1. **Implement Batch Updates (Critical)**
```dart
class VehicleFleetManager {
  final List<MapMarker> _pendingUpdates = [];
  Timer? _batchTimer;
  
  void updateVehicle(String id, double lat, double lng) {
    _pendingUpdates.add(MapMarker(id: id, latitude: lat, longitude: lng));
    
    _batchTimer?.cancel();
    _batchTimer = Timer(Duration(milliseconds: 200), _flushBatch);
  }
  
  void _flushBatch() {
    if (_pendingUpdates.isNotEmpty) {
      _navigation.updateMarkersBatch(_pendingUpdates);
      _pendingUpdates.clear();
    }
  }
}
```

2. **Reduce Update Frequency**
```dart
// Update every 3-5 seconds instead of every 1-2 seconds
Timer.periodic(Duration(seconds: 3), (timer) {
  _updateAllVehicles();
});
```

3. **Viewport Optimization**
```dart
// Only update vehicles within current map view
void updateVisibleVehicles() {
  final bounds = _navigation.getCurrentViewport();
  final visibleVehicles = _vehicles.where((v) => 
    bounds.contains(v.latitude, v.longitude)
  );
  
  _navigation.updateMarkersBatch(visibleVehicles.map((v) => v.marker).toList());
}
```

##### For 50+ Vehicles
**Requires advanced optimizations**

1. **Implement Clustering**
```dart
// Enable clustering for better performance
await _navigation.enableMarkerClustering(
  maxZoom: 15.0,
  minZoom: 10.0,
  clusterProperties: {
    'clusterMaxZoom': 15.0,
    'clusterRadius': 50.0,
  },
);
```

2. **Level-of-Detail Rendering**
```dart
class VehicleTracker {
  void updateVehicleDetail(String id, double lat, double lng, double zoom) {
    final marker = zoom > 12.0 
      ? _createDetailedMarker(id, lat, lng)  // Full detail
      : _createSimpleMarker(id, lat, lng);   // Simplified
    
    _navigation.updateMarker(marker);
  }
}
```

3. **WebSocket/Real-time Updates**
```dart
// Use WebSocket for efficient real-time updates
class RealTimeVehicleTracker {
  WebSocket? _socket;
  
  void connectToVehicleStream() {
    _socket = WebSocket.connect('ws://your-server/vehicles');
    _socket!.listen((data) {
      final vehicleData = jsonDecode(data);
      _updateVehicleFromStream(vehicleData);
    });
  }
}
```

#### Performance Optimization Strategies

##### 1. Batch Updates (High Priority)
```dart
// Enhanced MapBoxNavigation class
class MapBoxNavigation {
  /// Update multiple markers in a single call
  Future<bool> updateMarkersBatch(List<MapMarker> markers) async {
    return await _channel.invokeMethod('updateMarkersBatch', {
      'markers': markers.map((m) => m.toMap()).toList()
    });
  }
}
```

##### 2. Update Throttling
```dart
class VehicleTracker {
  final Map<String, Timer> _updateTimers = {};
  
  void updateVehicle(String id, double lat, double lng) {
    _updateTimers[id]?.cancel();
    _updateTimers[id] = Timer(Duration(milliseconds: 500), () {
      _navigation.updateMarker(createMarker(id, lat, lng));
    });
  }
}
```

##### 3. Viewport-Based Updates
```dart
class ViewportOptimizedTracker {
  void updateVisibleVehicles() {
    final bounds = _navigation.getCurrentViewport();
    final visibleVehicles = _vehicles.where((v) => 
      _isInViewport(v.latitude, v.longitude, bounds)
    );
    
    _navigation.updateMarkersBatch(visibleVehicles.map((v) => v.marker).toList());
  }
}
```

#### Platform-Specific Performance Considerations

##### Android
- Use Mapbox's `PointAnnotationManager` for efficient marker management
- Implement marker clustering using `ClusterManager`
- Consider using `PointAnnotationOptions` for batch operations
- Monitor memory usage with large numbers of annotations

##### iOS
- Use Mapbox's `PointAnnotationManager` for marker management
- Implement clustering using `PointAnnotationClusterManager`
- Consider using `PointAnnotationOptions` for batch operations
- Monitor memory usage with large numbers of annotations

#### Testing Performance

##### Performance Test Example
```dart
// test/performance/multi_vehicle_test.dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Multi-Vehicle Performance Tests', () {
    test('handles 50 vehicles with batch updates', () async {
      final tracker = VehicleFleetManager();
      final stopwatch = Stopwatch()..start();
      
      // Simulate 50 vehicles updating every 3 seconds
      for (int i = 0; i < 50; i++) {
        tracker.updateVehicle('vehicle-$i', 51.5074 + i * 0.001, -0.1278 + i * 0.001);
      }
      
      await Future.delayed(Duration(seconds: 1));
      stopwatch.stop();
      
      // Should complete within reasonable time
      expect(stopwatch.elapsedMilliseconds, lessThan(5000));
    });
  });
}
```

#### Summary of Recommendations

| Vehicle Count | Update Frequency | Required Optimizations | Performance Rating |
|---------------|------------------|----------------------|-------------------|
| 1-10 | 1-2 seconds | None | Excellent |
| 10-25 | 3-5 seconds | Batch updates | Good |
| 25-50 | 5-10 seconds | Batch updates + Viewport culling | Fair |
| 50+ | 10+ seconds | Clustering + LOD + Real-time streaming | Poor (needs redesign) |

#### Implementation Priority for Multi-Vehicle Support

1. **High Priority**
   - Implement batch marker updates
   - Add update frequency controls
   - Implement viewport-based culling

2. **Medium Priority**
   - Add marker clustering support
   - Implement level-of-detail rendering
   - Add performance monitoring

3. **Lower Priority**
   - Real-time streaming integration
   - Advanced clustering algorithms
   - Custom marker optimization

#### Conclusion

The proposed marker implementation can handle multiple vehicles but requires significant optimizations for 25+ vehicles. The most critical improvement is implementing batch updates to reduce method channel overhead. For 50+ vehicles, consider implementing clustering and reducing update frequency, or explore alternative approaches like custom map layers or WebGL rendering for better performance. 