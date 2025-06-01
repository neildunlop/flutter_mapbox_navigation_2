# Mapbox Navigation Options Overview

This document provides a comprehensive guide to the configuration options available in the Flutter Mapbox Navigation plugin.

## MapBoxOptions

The `MapBoxOptions` class is the main configuration object for customizing the navigation experience. Here's a detailed breakdown of each option:

### Basic Map Configuration

```dart
MapBoxOptions(
    initialLatitude: 51.5074,    // Starting latitude
    initialLongitude: -0.1278,   // Starting longitude
    zoom: 13.0,                  // Initial zoom level (0-22)
    tilt: 0.0,                   // Map tilt in degrees (0-60)
    bearing: 0.0,                // Map rotation in degrees (0-360)
)
```

- `initialLatitude` and `initialLongitude`: Set the initial map center point
- `zoom`: Controls the map's zoom level (higher values = more zoomed in)
- `tilt`: Adjusts the map's perspective (0 = flat, 60 = maximum tilt)
- `bearing`: Rotates the map view (0 = north, 90 = east, etc.)

### Navigation Mode

```dart
mode: MapBoxNavigationMode.drivingWithTraffic
```

Available modes:
- `driving`: Standard driving directions
- `drivingWithTraffic`: Driving with real-time traffic updates
- `walking`: Pedestrian navigation
- `cycling`: Bicycle navigation

### Voice and Banner Instructions

```dart
voiceInstructionsEnabled: true,
bannerInstructionsEnabled: true,
language: "en",
units: VoiceUnits.metric,
```

- `voiceInstructionsEnabled`: Toggle voice guidance
- `bannerInstructionsEnabled`: Toggle on-screen instructions
- `language`: Set instruction language (e.g., "en", "es", "fr")
- `units`: Choose between `metric` or `imperial` units. This setting affects:
  - Voice instructions (e.g., "Turn left in 100 meters" vs "Turn left in 300 feet")
  - Banner instructions (e.g., "100m" vs "300ft")
  - Distance remaining display
  - Route calculations and raw distance values
  - Navigation UI distance formatting

Note: The units setting is consistently applied across both iOS and Android platforms, affecting all distance-related features in the navigation experience.

### Route Options

```dart
alternatives: true,
allowsUTurnAtWayPoints: true,
enableRefresh: true,
```

- `alternatives`: Show alternative routes when available
- `allowsUTurnAtWayPoints`: Permit U-turns at waypoints
- `enableRefresh`: Allow route recalculation during navigation

### Simulation and Testing

```dart
simulateRoute: true,
animateBuildRoute: true,
```

- `simulateRoute`: Simulate navigation for testing
- `animateBuildRoute`: Animate the route drawing

### Advanced Options

```dart
longPressDestinationEnabled: true,
```

- `longPressDestinationEnabled`: Allow setting destination via long press

## Usage Examples

### Basic Navigation Setup

```dart
final options = MapBoxOptions(
    initialLatitude: 51.5074,
    initialLongitude: -0.1278,
    zoom: 13.0,
    mode: MapBoxNavigationMode.drivingWithTraffic,
    voiceInstructionsEnabled: true,
    bannerInstructionsEnabled: true,
    language: "en",
    units: VoiceUnits.metric,
);

await MapBoxNavigation.instance.startNavigation(
    wayPoints: wayPoints,
    options: options,
);
```

### Walking Navigation

```dart
final options = MapBoxOptions(
    initialLatitude: 51.5074,
    initialLongitude: -0.1278,
    zoom: 15.0,
    mode: MapBoxNavigationMode.walking,
    voiceInstructionsEnabled: true,
    bannerInstructionsEnabled: true,
    language: "en",
    units: VoiceUnits.metric,
);
```

### Cycling Navigation

```dart
final options = MapBoxOptions(
    initialLatitude: 51.5074,
    initialLongitude: -0.1278,
    zoom: 14.0,
    mode: MapBoxNavigationMode.cycling,
    voiceInstructionsEnabled: true,
    bannerInstructionsEnabled: true,
    language: "en",
    units: VoiceUnits.metric,
);
```

## Best Practices

1. **Zoom Levels**
   - Driving: 13-15
   - Walking: 15-17
   - Cycling: 14-16

2. **Language Support**
   - Use ISO 639-1 language codes
   - Default is "en" if language not supported
   - Check [supported languages](https://docs.mapbox.com/ios/navigation/overview/localization-and-internationalization/)

3. **Performance Considerations**
   - Disable `alternatives` for faster route calculation
   - Use `simulateRoute` for testing
   - Enable `enableRefresh` for real-time updates

4. **User Experience**
   - Always enable `bannerInstructionsEnabled`
   - Use `voiceInstructionsEnabled` based on app context
   - Set appropriate `zoom` level for navigation mode

## Common Issues and Solutions

1. **Route Not Building**
   - Check waypoint coordinates
   - Verify internet connection
   - Ensure valid navigation mode

2. **Voice Instructions Not Working**
   - Check device volume
   - Verify language support
   - Ensure permissions granted

3. **Map Not Updating**
   - Check `enableRefresh` setting
   - Verify location permissions
   - Ensure valid initial coordinates

## Platform-Specific Considerations

### iOS
- Requires location permissions in Info.plist
- Background modes for navigation
- Voice instructions require audio session

### Android
- Requires location permissions in manifest
- Background service for navigation
- Location accuracy settings

## Related Documentation
- [Mapbox Navigation SDK](https://docs.mapbox.com/ios/navigation/)
- [Mapbox Directions API](https://docs.mapbox.com/api/navigation/)
- [Mapbox Maps SDK](https://docs.mapbox.com/android/maps/)

## Waypoint Behavior

### Named vs Unnamed Waypoints

Waypoints can be created with or without names:

```dart
// Named waypoint
final namedWaypoint = WayPoint(
  name: 'Destination',
  latitude: 51.5074,
  longitude: -0.1278,
);

// Unnamed waypoint
final unnamedWaypoint = WayPoint(
  name: null,
  latitude: 51.5074,
  longitude: -0.1278,
);

// Empty name waypoint
final emptyNameWaypoint = WayPoint(
  name: '',
  latitude: 51.5074,
  longitude: -0.1278,
);
```

### Waypoint Types and Behavior

1. **Named Waypoints**
   - Show up in voice instructions
   - Display in banner instructions
   - Trigger arrival events
   - Used for route calculation
   - Example use cases:
     - Start/end points
     - Important stops
     - Points of interest

2. **Unnamed Waypoints**
   - Treated as silent waypoints
   - Used only for route calculation
   - Don't show in instructions
   - Don't trigger arrival events
   - Example use cases:
     - Route shaping
     - Intermediate points
     - Avoiding certain areas

3. **Silent Waypoints**
   - Can be named or unnamed
   - Controlled by `isSilent` parameter
   - Don't trigger arrival events
   - Don't show in instructions
   - Example use cases:
     - Route optimization
     - Traffic avoidance
     - Custom routing

### Best Practices

1. **Naming Strategy**
   - Always name the first and last waypoints
   - Use descriptive names for important stops
   - Leave intermediate waypoints unnamed if they're just for route shaping
   - Consider using `isSilent: true` for waypoints that don't need instructions

2. **Route Planning**
   - Use named waypoints for actual stops
   - Use unnamed waypoints for route shaping
   - Use silent waypoints to avoid certain areas
   - Keep waypoint count reasonable (2-25 waypoints)

3. **Performance Considerations**
   - More waypoints = longer route calculation time
   - Named waypoints require more processing
   - Silent waypoints are more efficient
   - Consider using waypoint optimization for long routes

4. **User Experience**
   - Clear naming helps users understand the route
   - Too many named waypoints can be confusing
   - Silent waypoints help create smoother routes
   - Balance between information and simplicity

### Common Patterns

1. **Simple A to B Navigation**
```dart
final wayPoints = [
  WayPoint(name: 'Start', latitude: 51.5074, longitude: -0.1278),
  WayPoint(name: 'End', latitude: 51.5074, longitude: -0.1278),
];
```

2. **Multi-Stop Route with Silent Points**
```dart
final wayPoints = [
  WayPoint(name: 'Start', latitude: 51.5074, longitude: -0.1278),
  WayPoint(name: null, latitude: 51.5074, longitude: -0.1278, isSilent: true),
  WayPoint(name: 'Stop 1', latitude: 51.5074, longitude: -0.1278),
  WayPoint(name: null, latitude: 51.5074, longitude: -0.1278, isSilent: true),
  WayPoint(name: 'End', latitude: 51.5074, longitude: -0.1278),
];
```

3. **Route Shaping**
```dart
final wayPoints = [
  WayPoint(name: 'Start', latitude: 51.5074, longitude: -0.1278),
  WayPoint(name: null, latitude: 51.5074, longitude: -0.1278),
  WayPoint(name: null, latitude: 51.5074, longitude: -0.1278),
  WayPoint(name: 'End', latitude: 51.5074, longitude: -0.1278),
];
```

### Troubleshooting

1. **Route Not Building**
   - Check waypoint coordinates
   - Verify waypoint count (2-25)
   - Ensure first/last waypoints are named
   - Check for invalid coordinates

2. **Missing Instructions**
   - Verify waypoint names
   - Check `isSilent` settings
   - Ensure voice/banner instructions are enabled
   - Check language settings

3. **Performance Issues**
   - Reduce waypoint count
   - Use silent waypoints
   - Optimize route calculation
   - Consider waypoint optimization 