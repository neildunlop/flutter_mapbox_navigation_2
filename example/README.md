# Flutter Mapbox Navigation Example App

This example app demonstrates the full capabilities of the `flutter_mapbox_navigation` plugin, showcasing both embedded and full-screen navigation modes with comprehensive features including static markers, multi-stop routing, and various navigation modes.

## 🎯 What This Example Demonstrates

### Core Navigation Features
- **Full-Screen Navigation**: Native Mapbox navigation UI with complete turn-by-turn guidance
- **Embedded Navigation**: In-app navigation view that can be integrated with your Flutter UI
- **Free Drive Mode**: Passive navigation without a specific destination
- **Multi-Stop Navigation**: Routes with multiple waypoints and silent waypoints for route shaping
- **Voice Instructions**: Configurable voice guidance with metric/imperial units
- **Route Alternatives**: Display multiple route options to users

### Interactive Map Features
- **Static Markers**: 35+ different marker types for POIs (restaurants, gas stations, hotels, etc.)
- **Marker Clustering**: Automatic grouping of nearby markers for better performance
- **Interactive Markers**: Tap markers to show popups with detailed information
- **Custom Marker Colors**: Personalized marker appearance
- **Map Gestures**: Long-press to set destinations, tap callbacks for custom interactions

### Advanced Capabilities
- **Route Optimization**: Automatic waypoint ordering for efficient routes
- **Simulation Mode**: Test navigation without actually moving
- **Multiple Transportation Modes**: Driving, walking, and cycling navigation
- **Real-time Updates**: Live traffic information and rerouting
- **Background Navigation**: Continue navigation when app is backgrounded

## 🚀 Quick Start

### Prerequisites

Before running the example, ensure you have:

1. **Mapbox Account**: Get free API tokens at [mapbox.com](https://mapbox.com)
2. **Development Environment**: Flutter SDK and platform-specific tools

### Setup Steps

1. **Configure Mapbox Tokens** (See [CLAUDE.md](../CLAUDE.md) for detailed instructions):
   ```bash
   # Android: Add tokens to gradle.properties
   echo "MAPBOX_DOWNLOADS_TOKEN=sk.your_secret_token" >> android/gradle.properties
   
   # iOS: Create .netrc file
   echo "machine api.mapbox.com\nlogin mapbox\npassword sk.your_secret_token" > ~/.netrc
   chmod 600 ~/.netrc
   ```

2. **Install Dependencies**:
   ```bash
   flutter pub get
   
   # iOS only
   cd ios && pod install --repo-update
   ```

3. **Run the Example**:
   ```bash
   flutter run
   ```

## 📱 Using the Example App

### Main Features Overview

The example app provides several screens demonstrating different aspects of the plugin:

#### 1. **Basic Navigation Screen** (`lib/main.dart`)
- Simple route planning between two points
- Toggle between embedded and full-screen modes
- Basic navigation controls (start, stop, simulate)

#### 2. **Marker Examples** (`lib/marker_example.dart`)
- Demonstrates all 35 marker types available
- Shows marker clustering in action
- Interactive marker popups with custom content
- Dynamic marker addition/removal

#### 3. **Multi-Stop Navigation** (`lib/multi_stop_example.dart`)
- Create routes with multiple destinations
- Silent waypoints for route shaping
- Waypoint reordering and optimization
- Progress tracking through multiple stops

#### 4. **Free Drive Mode** (`lib/free_drive_example.dart`)
- Passive navigation without destination
- Real-time location tracking
- Map exploration with user location

#### 5. **Advanced Features** (`lib/advanced_example.dart`)
- Custom map styles (day/night themes)
- Voice instruction configuration
- Route alternatives selection
- Background navigation setup

### Key UI Components

- **Navigation Controls**: Start/stop navigation, simulation toggle
- **Route Planning**: Waypoint management, route options
- **Map Settings**: Style selection, zoom levels, user preferences
- **Marker Management**: Add/remove markers, clustering settings
- **Voice Settings**: Language, units (metric/imperial), volume

## 🛠 Customizing the Example

### Adding New Navigation Features

1. **Custom Markers**:
   ```dart
   // Add a custom restaurant marker
   final marker = StaticMarker(
     id: 'restaurant_1',
     latitude: 37.7749,
     longitude: -122.4194,
     title: 'Great Restaurant',
     category: 'restaurant',
     iconId: 'restaurant',
     customColor: '#FF5722',
   );
   
   await MapBoxNavigation.instance.addStaticMarkers([marker]);
   ```

2. **Route Configuration**:
   ```dart
   // Create a multi-stop route with preferences
   final waypoints = [
     MapBoxWayPoint(name: "Start", latitude: 37.7749, longitude: -122.4194),
     MapBoxWayPoint(name: "Stop 1", latitude: 37.7849, longitude: -122.4094, isSilent: true), // Silent waypoint
     MapBoxWayPoint(name: "Destination", latitude: 37.7949, longitude: -122.3994),
   ];
   
   final options = MapBoxOptions(
     mode: MapBoxNavigationMode.driving,
     simulateRoute: false,
     language: "en",
     units: VoiceUnits.metric,
     alternatives: true,
   );
   ```

3. **Custom Map Styles**:
   ```dart
   final options = MapBoxOptions(
     mapStyleUrlDay: "mapbox://styles/your-username/your-style-id",
     mapStyleUrlNight: "mapbox://styles/your-username/your-night-style-id",
   );
   ```

### Extending Functionality

#### Adding New Screens
1. Create a new file in `lib/` (e.g., `my_feature_example.dart`)
2. Implement your navigation feature
3. Add navigation to it from the main screen

#### Custom Event Handling
```dart
// Listen to navigation events
MapBoxNavigation.instance.registerRouteEventListener((event) {
  switch (event.eventType) {
    case MapBoxEvent.navigation_running:
      // Handle ongoing navigation
      break;
    case MapBoxEvent.on_arrival:
      // Handle arrival at destination
      break;
    case MapBoxEvent.route_built:
      // Handle successful route building
      break;
  }
});
```

#### Marker Interaction
```dart
// Handle marker taps
MapBoxNavigation.instance.setMarkerTapListener((marker) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(marker.title),
      content: Text(marker.description ?? 'No description'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Close'),
        ),
        TextButton(
          onPressed: () {
            // Navigate to this marker
            Navigator.pop(context);
            _navigateToMarker(marker);
          },
          child: Text('Navigate Here'),
        ),
      ],
    ),
  );
});
```

## 🏗 Project Structure

```
lib/
├── main.dart                 # Main app entry point and basic navigation
├── app.dart                  # App configuration and routing
├── marker_example.dart       # Static markers demonstration
├── multi_stop_example.dart   # Multi-waypoint navigation
├── free_drive_example.dart   # Free drive mode
├── advanced_example.dart     # Advanced features showcase
├── popup_example.dart        # Marker popup interactions
└── widgets/
    ├── navigation_controls.dart    # Reusable navigation UI
    ├── marker_list.dart           # Marker management UI
    └── route_options.dart         # Route configuration UI
```

## 🧪 Testing Different Scenarios

### Navigation Modes
- **Driving**: Default mode with traffic-aware routing
- **Walking**: Pedestrian-friendly routes and timing
- **Cycling**: Bike-friendly paths and routing

### Route Types
- **Simple A→B**: Direct navigation between two points
- **Multi-stop**: Delivery routes, sightseeing tours
- **Optimized**: Automatically reorder waypoints for efficiency
- **Silent waypoints**: Force routes through specific areas without stopping

### Testing Features
- **Simulation**: Test navigation without moving your device
- **Different locations**: Try various cities and terrains
- **Network conditions**: Test offline vs online behavior
- **Day/Night modes**: Test different map styles

## 🔧 Troubleshooting

### Common Issues

1. **Build Failures**: Ensure Mapbox tokens are properly configured
2. **No Navigation Voice**: Check device volume and voice instruction settings
3. **Markers Not Showing**: Verify marker coordinates and zoom level
4. **Route Building Fails**: Check network connectivity and valid coordinates

### Debug Mode
Enable debug logging to see detailed plugin activity:
```dart
// Add this to see detailed logs in debug console
MapBoxNavigation.instance.enableDebugLogging();
```

## 📚 Next Steps

- **Read the Full Documentation**: Check [CLAUDE.md](../CLAUDE.md) for complete setup and API documentation
- **Explore the Plugin API**: Review `../lib/flutter_mapbox_navigation.dart` for all available methods
- **Check the Test Suite**: Look at `../test/` for example usage patterns
- **Join the Community**: Report issues and contribute on GitHub

## 🎯 Real-World Applications

This example demonstrates patterns useful for:
- **Delivery Apps**: Multi-stop routing with customer locations
- **Tourism Apps**: Sightseeing routes with POI markers
- **Fleet Management**: Vehicle tracking and route optimization
- **Ride-sharing**: Dynamic routing and real-time updates
- **Food Delivery**: Efficient routing with restaurant and customer markers

## 📖 Additional Resources

- [Mapbox Navigation SDK Documentation](https://docs.mapbox.com/android/navigation/)
- [Flutter Platform Channels](https://docs.flutter.dev/development/platform-integration/platform-channels)
- [Mapbox Studio](https://studio.mapbox.com/) - Create custom map styles
- [Plugin GitHub Repository](https://github.com/eopeter/flutter_mapbox_navigation) - Source code and issues