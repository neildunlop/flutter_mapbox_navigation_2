# Flutter Mapbox Navigation Package Architecture

This document provides an overview of the architecture of the `flutter_mapbox_navigation` package, which is a Flutter wrapper around the Mapbox SDK for implementing turn-by-turn navigation in Flutter applications.

## Architecture Overview

The package follows a platform-specific implementation pattern, where Flutter code provides a unified API that developers can use, while platform-specific implementations (Android and iOS) handle the actual Mapbox SDK integration.

### Key Features

- **Turn-by-turn Navigation**: Full-screen and embedded navigation views
- **Multi-stop Navigation**: Support for multiple waypoints with silent waypoint options
- **Free Drive Mode**: Passive navigation without destination
- **Static Markers**: Custom POI markers with clustering and tap interactions
- **Trip Progress Panel**: Customizable waypoint progress with skip functionality
- **Offline Navigation**: Download map tiles and routing data for offline use
- **Event System**: Comprehensive events for navigation progress and user interactions

### Key Components

1. **Flutter Layer**
   - Provides a unified API for developers
   - Handles platform-specific implementations through Flutter's platform channel system
   - Manages configuration options and state

2. **Platform-Specific Implementations**
   - Android: Kotlin implementation interfacing with Mapbox Android SDK v2.16
   - iOS: Swift implementation interfacing with Mapbox iOS SDK v2.11
   - Each platform handles its own navigation view and routing logic

## Key Files and Their Purposes

### Flutter Layer

- `lib/src/flutter_mapbox_navigation.dart`
  - Main entry point for the package
  - Provides the `MapBoxNavigation` singleton class
  - Manages default options and navigation state

- `lib/src/models/options.dart`
  - Defines `MapBoxOptions` class
  - Contains all configurable options for navigation
  - Handles conversion between Flutter and platform-specific options

- `lib/src/models/voice_units.dart`
  - Defines the `VoiceUnits` enum
  - Manages unit system settings (imperial/metric)

- `lib/src/embedded/view.dart`
  - Handles platform-specific view creation
  - Manages the embedded navigation view lifecycle

### Android Implementation

- `android/src/main/kotlin/com/neiladunlop/fluttermapboxnavigation2/FlutterMapboxNavigationPlugin.kt`
  - Main plugin class for Android
  - Handles method channel communication
  - Manages navigation state and options

- `android/src/main/kotlin/com/neiladunlop/fluttermapboxnavigation2/TurnByTurn.kt`
  - Core navigation implementation for Android
  - Handles route building and navigation
  - Manages waypoints and navigation options

- `android/src/main/kotlin/com/neiladunlop/fluttermapboxnavigation2/models/views/EmbeddedNavigationMapView.kt`
  - Implements the embedded navigation view for Android
  - Handles map view lifecycle and user interactions

- `android/src/main/kotlin/com/neiladunlop/fluttermapboxnavigation2/StaticMarkerManager.kt`
  - Manages static marker display and interactions
  - Handles marker tap events and native notifications
  - Integrates with Maps SDK annotations API

### iOS Implementation

- `ios/Classes/FlutterMapboxNavigationPlugin.swift`
  - Main plugin class for iOS
  - Handles method channel communication
  - Manages navigation state and options

- `ios/Classes/NavigationFactory.swift`
  - Core navigation implementation for iOS
  - Handles route building and navigation
  - Manages waypoints and navigation options

- `ios/Classes/EmbeddedNavigationView.swift`
  - Implements the embedded navigation view for iOS
  - Handles map view lifecycle and user interactions

- `ios/Classes/StaticMarkerManager.swift`
  - Manages static marker display and interactions
  - Handles marker tap events and native notifications
  - Integrates with MapboxMaps SDK annotations

## Platform Channel Communication

The package uses Flutter's platform channel system to communicate between Flutter and native code:

1. **Method Channel**
   - Used for direct method calls (e.g., starting navigation, adding waypoints, offline downloads)
   - Channel name: `flutter_mapbox_navigation`

2. **Event Channel**
   - Used for streaming events (e.g., navigation progress, route updates)
   - Channel name: `flutter_mapbox_navigation/events`

3. **Static Marker Event Channel**
   - Used for marker tap events and interactions
   - Channel name: `flutter_mapbox_navigation/marker_events`

4. **Offline Download Progress**
   - Progress updates for offline region downloads are handled via callbacks
   - Supports real-time progress tracking (0.0 to 1.0)

## Adding New Features

When adding new features from the Mapbox SDK:

1. **Flutter Layer**
   - Add new options to `MapBoxOptions` if needed
   - Update the platform interface in `flutter_mapbox_navigation_platform_interface.dart`
   - Implement the feature in the method channel implementation

2. **Platform-Specific Implementation**
   - Add the feature to both Android and iOS implementations
   - Ensure proper option passing through platform channels
   - Handle platform-specific differences in implementation

## Common Issues and Debugging

1. **Platform-Specific Differences**
   - Some features may work differently or be unavailable on certain platforms
   - Check both platform implementations when debugging issues
   - Verify option passing through platform channels

2. **Configuration Issues**
   - Verify options are being passed correctly from Flutter to native code
   - Check default values in platform-specific implementations
   - Ensure proper initialization of Mapbox SDK components

## Best Practices

1. **Feature Implementation**
   - Implement features on both platforms simultaneously
   - Test thoroughly on both platforms
   - Document platform-specific differences

2. **Code Organization**
   - Keep platform-specific code in respective directories
   - Maintain consistent naming and structure across platforms
   - Use clear and descriptive names for methods and variables

3. **Error Handling**
   - Implement proper error handling on both platforms
   - Provide meaningful error messages
   - Handle platform-specific edge cases

## Resources

- [Mapbox Navigation SDK Documentation](https://docs.mapbox.com/android/navigation/overview/)
- [Flutter Platform Channels Documentation](https://docs.flutter.dev/development/platform-integration/platform-channels)
- [Mapbox iOS SDK Documentation](https://docs.mapbox.com/ios/navigation/overview/) 
