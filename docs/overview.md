# Flutter Mapbox Navigation Package Architecture

This document provides an overview of the architecture of the `flutter_mapbox_navigation` package, which is a Flutter wrapper around the Mapbox SDK for implementing turn-by-turn navigation in Flutter applications.

## Architecture Overview

The package follows a platform-specific implementation pattern, where Flutter code provides a unified API that developers can use, while platform-specific implementations (Android and iOS) handle the actual Mapbox SDK integration.

### Key Components

1. **Flutter Layer**
   - Provides a unified API for developers
   - Handles platform-specific implementations through Flutter's platform channel system
   - Manages configuration options and state

2. **Platform-Specific Implementations**
   - Android: Kotlin implementation interfacing with Mapbox Android SDK
   - iOS: Swift implementation interfacing with Mapbox iOS SDK
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

- `android/src/main/kotlin/com/eopeter/fluttermapboxnavigation/FlutterMapboxNavigationPlugin.kt`
  - Main plugin class for Android
  - Handles method channel communication
  - Manages navigation state and options

- `android/src/main/kotlin/com/eopeter/fluttermapboxnavigation/TurnByTurn.kt`
  - Core navigation implementation for Android
  - Handles route building and navigation
  - Manages waypoints and navigation options

- `android/src/main/kotlin/com/eopeter/fluttermapboxnavigation/models/views/EmbeddedNavigationMapView.kt`
  - Implements the embedded navigation view for Android
  - Handles map view lifecycle and user interactions

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

## Platform Channel Communication

The package uses Flutter's platform channel system to communicate between Flutter and native code:

1. **Method Channel**
   - Used for direct method calls (e.g., starting navigation, adding waypoints)
   - Channel name: `flutter_mapbox_navigation`

2. **Event Channel**
   - Used for streaming events (e.g., navigation progress, route updates)
   - Channel name: `flutter_mapbox_navigation/events`

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