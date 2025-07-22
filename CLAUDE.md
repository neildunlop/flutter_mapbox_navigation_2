# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is `flutter_mapbox_navigation`, a Flutter plugin providing turn-by-turn navigation using the Mapbox SDK. The plugin offers both full-screen and embedded navigation views with comprehensive features including waypoint management, static markers, voice instructions, and multi-stop routing.

## Common Development Commands

### Testing Commands
```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage

# Run specific test types
flutter test test/unit/
flutter test test/integration/

# Run specific test file
flutter test test/unit/waypoint_test.dart

# Generate HTML coverage report (requires lcov)
genhtml coverage/lcov.info -o coverage/html
```

### Build Commands
```bash
# Analyze code using very_good_analysis
flutter analyze

# Format code
flutter format .

# Build example app for Android
cd example && flutter build apk

# Build example app for iOS
cd example && flutter build ios

# Run example app
cd example && flutter run
```

### Platform-Specific Commands
```bash
# Android: Clean and rebuild
cd android && ./gradlew clean
cd example/android && ./gradlew clean

# iOS: Clean pods
cd example/ios && rm -rf Pods Podfile.lock && pod install

# Validate iOS podspec
pod lib lint flutter_mapbox_navigation.podspec
```

## Architecture Overview

### High-Level Structure
The plugin follows Flutter's platform channel architecture:
- **Flutter layer**: Provides unified API (`lib/src/flutter_mapbox_navigation.dart`)
- **Android layer**: Kotlin implementation using Mapbox Navigation SDK v2.16
- **iOS layer**: Swift implementation using Mapbox Navigation SDK v2.11

### Key Components
1. **Navigation Core** (`lib/src/flutter_mapbox_navigation.dart`): Singleton class managing navigation state
2. **Platform Interface** (`lib/src/flutter_mapbox_navigation_platform_interface.dart`): Abstract interface for platform implementations
3. **Method Channel** (`lib/src/flutter_mapbox_navigation_method_channel.dart`): Concrete implementation of platform interface
4. **Models** (`lib/src/models/`): Data classes for waypoints, options, events, and static markers
5. **Embedded View** (`lib/src/embedded/`): Widget for embedded navigation view
6. **Widgets** (`lib/src/widgets/`): Full-screen navigation and overlay components

### Platform-Specific Architecture

#### Android Implementation
- **Main Plugin** (`android/../FlutterMapboxNavigationPlugin.kt`): Method channel handler
- **Navigation Activity** (`android/../activity/NavigationActivity.kt`): Full-screen navigation
- **Static Markers** (`android/../StaticMarkerManager.kt`): Marker management system
- **Utilities** (`android/../utilities/`): Helper classes and custom UI components

#### iOS Implementation  
- **Main Plugin** (`ios/Classes/FlutterMapboxNavigationPlugin.swift`): Method channel handler
- **View Controllers**: Navigation view management
- **Mapbox SDK Integration**: Direct integration with Mapbox iOS SDK

## Development Guidelines

### Code Style
- Uses `very_good_analysis` for linting (see `analysis_options.yaml`)
- Follow Flutter/Dart naming conventions
- All public APIs must be documented
- Platform-specific code should mirror the Flutter API structure

### Testing Strategy
- **Unit tests** (`test/unit/`): Test individual classes and functions
- **Widget tests** (`test/widget/`): Test UI components
- **Integration tests** (`test/integration/`): Test platform communication
- Comprehensive test coverage for waypoint validation and navigation events

### Platform Configuration

#### Android Setup Requirements
- **Mapbox Download Token**: Set `MAPBOX_DOWNLOADS_TOKEN` in `gradle.properties`
- **API Token**: Configure in `android/app/src/main/res/values/mapbox_access_token.xml`
- **Minimum SDK**: API 21 (Android 5.0)
- **Target SDK**: API 35 (Android 15)
- **Kotlin Version**: 1.8.10
- **Gradle Version**: 8.1.0

#### iOS Setup Requirements
- **Download Token**: Configure in `~/.netrc` file
- **API Token**: Set `MBXAccessToken` in Info.plist
- **Minimum iOS**: 12.0
- **Swift Version**: 5.0
- **Mapbox SDK**: Navigation v2.11, Maps v10.16

### Key Features to Understand

#### Navigation Modes
- **Full-screen navigation**: Complete navigation UI takeover
- **Embedded navigation**: Navigation view within app widget tree
- **Free drive mode**: Passive navigation without destination

#### Waypoint System
- Minimum 2 waypoints required for navigation
- Support for silent waypoints (route shaping without announcements)
- Dynamic waypoint addition during navigation
- Validation against Mapbox API limits (25 waypoints recommended)

#### Static Markers System
- 30+ predefined icons across 5 categories
- Flexible string-based categories
- Rich metadata support with clustering
- Distance-based filtering from route
- Interactive tap callbacks

#### Event Handling
- Comprehensive event system for navigation progress
- Route building/built/failed events
- Arrival events (per waypoint)
- Navigation state changes (running/finished/cancelled)

## Important Notes

### Platform Limitations
- **iOS Traffic Mode**: Limited to 3 waypoints when using `drivingWithTraffic`
- **Voice Units**: Locked at first initialization (SDK limitation)
- **Offline Routing**: Not implemented (planned feature)

### Security Considerations
- Never commit Mapbox tokens to version control
- Use `.gitignore` for `gradle.properties` and token files
- Environment variable fallbacks for CI/CD

### Testing Considerations
- Mock platform channels for unit tests
- Use test-specific Mapbox tokens
- Integration tests require real Mapbox API access
- Coverage reports generated in `coverage/` directory

### Branch Strategy
- **Main branch**: `master`
- **Current development**: `full-screen-optimisation`
- Feature branches should be created from `master`

### Documentation
Comprehensive documentation available in `docs/` directory including architecture overview, testing strategy, and feature comparisons.