# Vehicle Movement Simulation for Test Application

This document outlines the approach for adding simulated vehicle movements to the flutter_mapbox_navigation test application to demonstrate marker functionality.

## Overview

The vehicle movement simulation will allow users to test and visualize the marker functionality by simulating multiple vehicles moving around the map in real-time. This provides a practical demonstration of how the marker system can be used for vehicle tracking applications.

## Current Test Application Structure

The existing test application (`example/lib/app.dart`) currently provides:

1. **Route Simulation** - `simulateRoute: true` simulates the user driving along a route
2. **Multiple Navigation Modes** - A to B, Multi-stop, Free drive
3. **Embedded Map View** - Shows the map with navigation
4. **Event Handling** - Tracks navigation progress and updates UI

## Proposed Multi-Vehicle Simulation Approach

### 1. Vehicle Simulation Manager

The core component that manages all simulated vehicles:

```dart
class VehicleSimulationManager {
  final Map<String, SimulatedVehicle> _vehicles = {};
  final MapBoxNavigation _navigation;
  Timer? _simulationTimer;
  bool _isRunning = false;
  
  VehicleSimulationManager(this._navigation);
  
  /// Start the vehicle simulation
  void startSimulation({int vehicleCount = 5, int updateFrequencySeconds = 2}) {
    if (_isRunning) return;
    
    _createVehicles(vehicleCount);
    _simulationTimer = Timer.periodic(
      Duration(seconds: updateFrequencySeconds), 
      (timer) => _updateAllVehicles()
    );
    _isRunning = true;
  }
  
  /// Stop the vehicle simulation
  void stopSimulation() {
    _simulationTimer?.cancel();
    _clearAllVehicles();
    _isRunning = false;
  }
  
  /// Update all vehicle positions
  void _updateAllVehicles() {
    for (final vehicle in _vehicles.values) {
      vehicle.updatePosition();
      _navigation.updateMarker(vehicle.createMarker());
    }
  }
  
  /// Create the specified number of vehicles
  void _createVehicles(int count) {
    for (int i = 0; i < count; i++) {
      final vehicle = SimulatedVehicle(
        id: 'vehicle-$i',
        name: 'Vehicle ${i + 1}',
        route: SimulationRoutes.getRandomRoute(),
        type: VehicleType.values[i % VehicleType.values.length],
      );
      _vehicles[vehicle.id] = vehicle;
      
      // Add initial marker
      _navigation.addMarker(vehicle.createMarker());
    }
  }
  
  /// Clear all vehicles from the map
  void _clearAllVehicles() {
    for (final vehicle in _vehicles.values) {
      _navigation.removeMarker(vehicle.id);
    }
    _vehicles.clear();
  }
  
  /// Get current simulation statistics
  SimulationStats getStats() {
    return SimulationStats(
      activeVehicles: _vehicles.length,
      isRunning: _isRunning,
      updateFrequency: _simulationTimer?.tick ?? 0,
    );
  }
}
```

### 2. Simulated Vehicle Class

Represents an individual vehicle with its movement logic:

```dart
class SimulatedVehicle {
  final String id;
  final String name;
  final List<LatLng> route;
  final VehicleType type;
  int currentRouteIndex = 0;
  double progress = 0.0; // 0.0 to 1.0 along current segment
  double speed = 1.0; // Speed multiplier
  
  SimulatedVehicle({
    required this.id,
    required this.name,
    required this.route,
    required this.type,
  });
  
  /// Get current position by interpolating between route points
  LatLng get currentPosition {
    if (route.length < 2) return route.first;
    
    final start = route[currentRouteIndex];
    final end = route[(currentRouteIndex + 1) % route.length];
    return LatLng.lerp(start, end, progress);
  }
  
  /// Get current heading in degrees
  double get currentHeading {
    if (route.length < 2) return 0.0;
    
    final start = route[currentRouteIndex];
    final end = route[(currentRouteIndex + 1) % route.length];
    return _calculateBearing(start, end);
  }
  
  /// Update vehicle position along the route
  void updatePosition() {
    progress += 0.02 * speed; // Move along current segment
    
    if (progress >= 1.0) {
      progress = 0.0;
      currentRouteIndex = (currentRouteIndex + 1) % route.length;
    }
  }
  
  /// Create a marker for this vehicle
  MapMarker createMarker() {
    final position = currentPosition;
    final markerType = VehicleMarker.types[type]!;
    
    return DirectionalMarker(
      id: id,
      latitude: position.latitude,
      longitude: position.longitude,
      heading: currentHeading,
      name: name,
      properties: {
        'icon': markerType.icon,
        'color': markerType.color.value,
        'vehicleType': type.toString(),
      },
    );
  }
  
  /// Calculate bearing between two points
  double _calculateBearing(LatLng start, LatLng end) {
    final lat1 = start.latitude * pi / 180;
    final lat2 = end.latitude * pi / 180;
    final dLon = (end.longitude - start.longitude) * pi / 180;
    
    final y = sin(dLon) * cos(lat2);
    final x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon);
    
    final bearing = atan2(y, x) * 180 / pi;
    return (bearing + 360) % 360;
  }
}
```

### 3. Vehicle Types and Markers

Define different vehicle types with distinct visual representations:

```dart
enum VehicleType { car, truck, bus, motorcycle }

class VehicleMarker {
  final VehicleType type;
  final Color color;
  final String icon;
  
  const VehicleMarker({
    required this.type,
    required this.color,
    required this.icon,
  });
  
  static const Map<VehicleType, VehicleMarker> types = {
    VehicleType.car: VehicleMarker(
      type: VehicleType.car,
      color: Colors.blue,
      icon: 'car-marker',
    ),
    VehicleType.truck: VehicleMarker(
      type: VehicleType.truck,
      color: Colors.red,
      icon: 'truck-marker',
    ),
    VehicleType.bus: VehicleMarker(
      type: VehicleType.bus,
      color: Colors.green,
      icon: 'bus-marker',
    ),
    VehicleType.motorcycle: VehicleMarker(
      type: VehicleType.motorcycle,
      color: Colors.orange,
      icon: 'motorcycle-marker',
    ),
  };
}
```

### 4. Predefined Routes for Simulation

Create various route patterns for realistic vehicle movement:

```dart
class SimulationRoutes {
  static final List<List<LatLng>> predefinedRoutes = [
    // Route 1: Downtown loop (San Francisco)
    [
      LatLng(37.774406, -122.435397), // Home
      LatLng(37.765569, -122.424098), // Store
      LatLng(37.784406, -122.445397), // Office
      LatLng(37.774406, -122.435397), // Back to home
    ],
    
    // Route 2: Highway simulation
    [
      LatLng(37.774406, -122.435397),
      LatLng(37.784406, -122.445397),
      LatLng(37.794406, -122.455397),
      LatLng(37.804406, -122.465397),
    ],
    
    // Route 3: Residential area
    [
      LatLng(37.764406, -122.425397),
      LatLng(37.764406, -122.415397),
      LatLng(37.754406, -122.415397),
      LatLng(37.754406, -122.425397),
    ],
    
    // Route 4: Business district
    [
      LatLng(37.784406, -122.445397),
      LatLng(37.784406, -122.435397),
      LatLng(37.784406, -122.425397),
      LatLng(37.784406, -122.415397),
    ],
    
    // Route 5: Circular route
    [
      LatLng(37.774406, -122.435397),
      LatLng(37.784406, -122.435397),
      LatLng(37.784406, -122.425397),
      LatLng(37.774406, -122.425397),
      LatLng(37.774406, -122.435397),
    ],
  ];
  
  /// Get a random route for vehicle assignment
  static List<LatLng> getRandomRoute() {
    final random = Random();
    return predefinedRoutes[random.nextInt(predefinedRoutes.length)];
  }
  
  /// Get a specific route by index
  static List<LatLng> getRoute(int index) {
    return predefinedRoutes[index % predefinedRoutes.length];
  }
}
```

### 5. Performance-Optimized Updates

Implement batch updates for efficient handling of multiple vehicles:

```dart
class VehicleSimulationManager {
  final List<MapMarker> _pendingUpdates = [];
  Timer? _batchTimer;
  
  /// Update vehicle with batching for performance
  void updateVehicle(String id, double lat, double lng, double heading) {
    _pendingUpdates.add(DirectionalMarker(
      id: id,
      latitude: lat,
      longitude: lng,
      heading: heading,
    ));
    
    // Batch updates every 200ms for efficiency
    _batchTimer?.cancel();
    _batchTimer = Timer(Duration(milliseconds: 200), _flushBatch);
  }
  
  /// Flush pending marker updates
  void _flushBatch() {
    if (_pendingUpdates.isNotEmpty) {
      _navigation.updateMarkersBatch(_pendingUpdates);
      _pendingUpdates.clear();
    }
  }
  
  /// Update all vehicles with viewport optimization
  void _updateAllVehicles() {
    final bounds = _navigation.getCurrentViewport();
    final visibleVehicles = _vehicles.values.where((v) => 
      _isInViewport(v.currentPosition, bounds)
    );
    
    for (final vehicle in visibleVehicles) {
      vehicle.updatePosition();
      _pendingUpdates.add(vehicle.createMarker());
    }
    
    // Flush updates immediately for visible vehicles
    if (_pendingUpdates.isNotEmpty) {
      _navigation.updateMarkersBatch(_pendingUpdates);
      _pendingUpdates.clear();
    }
  }
  
  /// Check if position is within viewport
  bool _isInViewport(LatLng position, LatLngBounds bounds) {
    return position.latitude >= bounds.southwest.latitude &&
           position.latitude <= bounds.northeast.latitude &&
           position.longitude >= bounds.southwest.longitude &&
           position.longitude <= bounds.northeast.longitude;
  }
}
```

### 6. Integration with Test Application

Add new UI controls to the existing test application:

```dart
// Add this section to the existing app.dart after the existing buttons
Container(
  color: Colors.blue,
  width: double.infinity,
  child: const Padding(
    padding: EdgeInsets.all(10),
    child: Text(
      "Multi-Vehicle Simulation",
      style: TextStyle(color: Colors.white),
      textAlign: TextAlign.center,
    ),
  ),
),
Padding(
  padding: const EdgeInsets.all(8.0),
  child: Wrap(
    spacing: 8.0,
    runSpacing: 8.0,
    alignment: WrapAlignment.center,
    children: [
      ElevatedButton(
        child: const Text("Start 5 Vehicle Simulation"),
        onPressed: () => _startVehicleSimulation(5),
      ),
      ElevatedButton(
        child: const Text("Start 10 Vehicle Simulation"),
        onPressed: () => _startVehicleSimulation(10),
      ),
      ElevatedButton(
        child: const Text("Start 20 Vehicle Simulation"),
        onPressed: () => _startVehicleSimulation(20),
      ),
      ElevatedButton(
        child: const Text("Stop Simulation"),
        onPressed: () => _stopVehicleSimulation(),
      ),
    ],
  ),
),
// Add simulation controls
if (_vehicleSimulationManager != null) ...[
  Container(
    padding: EdgeInsets.all(10),
    child: Column(
      children: [
        Row(
          children: [
            Text("Vehicle Count: ${_vehicleCount}"),
            Expanded(
              child: Slider(
                value: _vehicleCount.toDouble(),
                min: 1,
                max: 50,
                divisions: 49,
                onChanged: (value) => setState(() {
                  _vehicleCount = value.toInt();
                }),
              ),
            ),
          ],
        ),
        Row(
          children: [
            Text("Update Frequency: ${_updateFrequency}s"),
            Expanded(
              child: Slider(
                value: _updateFrequency.toDouble(),
                min: 1,
                max: 10,
                divisions: 9,
                onChanged: (value) => setState(() {
                  _updateFrequency = value.toInt();
                  _updateSimulationTimer();
                }),
              ),
            ),
          ],
        ),
      ],
    ),
  ),
  // Simulation statistics
  Container(
    padding: EdgeInsets.all(10),
    child: Column(
      children: [
        Text("Active Vehicles: ${_stats.activeVehicles}"),
        Text("Update Rate: ${_stats.updateFrequency}/sec"),
        Text("Simulation Running: ${_stats.isRunning ? 'Yes' : 'No'}"),
      ],
    ),
  ),
],
```

### 7. Simulation Statistics and Monitoring

Track performance and simulation metrics:

```dart
class SimulationStats {
  final int activeVehicles;
  final bool isRunning;
  final int updateFrequency;
  final double memoryUsage;
  final double currentFPS;
  
  SimulationStats({
    required this.activeVehicles,
    required this.isRunning,
    required this.updateFrequency,
    this.memoryUsage = 0.0,
    this.currentFPS = 0.0,
  });
}

class PerformanceMonitor {
  final Stopwatch _frameTimer = Stopwatch();
  final List<double> _frameTimes = [];
  
  void startFrame() {
    _frameTimer.start();
  }
  
  void endFrame() {
    _frameTimer.stop();
    _frameTimes.add(_frameTimer.elapsedMicroseconds / 1000.0);
    
    // Keep only last 60 frames
    if (_frameTimes.length > 60) {
      _frameTimes.removeAt(0);
    }
    
    _frameTimer.reset();
  }
  
  double get averageFPS {
    if (_frameTimes.isEmpty) return 0.0;
    final avgFrameTime = _frameTimes.reduce((a, b) => a + b) / _frameTimes.length;
    return 1000.0 / avgFrameTime;
  }
}
```

### 8. Implementation Phases

#### Phase 1: Basic Vehicle Simulation
- [ ] Create `SimulatedVehicle` class
- [ ] Create `VehicleSimulationManager`
- [ ] Add basic UI controls to test app
- [ ] Implement simple circular routes
- [ ] Add basic marker updates

#### Phase 2: Enhanced Features
- [ ] Add different vehicle types (car, truck, bus, motorcycle)
- [ ] Implement batch updates for performance
- [ ] Add performance monitoring
- [ ] Create more complex route patterns
- [ ] Add vehicle interaction (click to follow)

#### Phase 3: Advanced Features
- [ ] Add clustering for large numbers of vehicles
- [ ] Implement viewport culling for off-screen vehicles
- [ ] Add traffic simulation (speed variations, traffic lights)
- [ ] Add vehicle collision detection
- [ ] Add realistic vehicle movement patterns

#### Phase 4: Performance Optimization
- [ ] Implement level-of-detail rendering
- [ ] Add memory usage optimization
- [ ] Implement efficient marker pooling
- [ ] Add WebSocket integration for real-time updates
- [ ] Add performance benchmarking tools

### 9. Usage Examples

#### Basic Usage
```dart
// Initialize simulation manager
final simulationManager = VehicleSimulationManager(MapBoxNavigation.instance);

// Start simulation with 10 vehicles
simulationManager.startSimulation(vehicleCount: 10);

// Stop simulation
simulationManager.stopSimulation();
```

#### Advanced Usage with Custom Routes
```dart
// Create custom vehicle with specific route
final customVehicle = SimulatedVehicle(
  id: 'custom-vehicle',
  name: 'Delivery Truck',
  route: [
    LatLng(37.774406, -122.435397),
    LatLng(37.784406, -122.445397),
    LatLng(37.794406, -122.455397),
  ],
  type: VehicleType.truck,
);

// Add to simulation
simulationManager.addVehicle(customVehicle);
```

### 10. Benefits

1. **Demonstrates Marker Functionality** - Shows real-time marker updates in action
2. **Performance Testing** - Tests marker system with different vehicle counts
3. **User Experience** - Provides visual demonstration of capabilities
4. **Development Tool** - Helps debug marker implementation issues
5. **Documentation** - Live example of how to use the marker API
6. **Performance Validation** - Validates the performance recommendations from marker_implementation.md

### 11. Testing Scenarios

#### Performance Testing
- Test with 1-10 vehicles (should work smoothly)
- Test with 10-50 vehicles (requires optimizations)
- Test with 50+ vehicles (requires advanced optimizations)

#### Feature Testing
- Test different vehicle types and markers
- Test batch updates vs individual updates
- Test viewport culling effectiveness
- Test marker clustering functionality

#### User Experience Testing
- Test vehicle interaction (click to follow)
- Test simulation controls (start/stop, count adjustment)
- Test performance monitoring display
- Test different update frequencies

This simulation system will provide a comprehensive demonstration of the marker functionality while also serving as a testing and validation tool for the implementation. 