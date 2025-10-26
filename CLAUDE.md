# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Common Development Commands

### Testing and Analysis
```bash
# Run static analysis (372 issues remaining after major cleanup)
flutter analyze

# Run all tests (52 tests currently)
flutter test

# Run specific test categories
flutter test test/unit/                # Unit tests
flutter test test/integration/         # Integration tests
flutter test test/widget/              # Widget tests

# Run specific test file
flutter test test/unit/waypoint_test.dart

# Run tests with coverage
flutter test --coverage

# Clean project
flutter clean
flutter pub get
```

### Building and Running

**Prerequisites:** Ensure Mapbox tokens are configured (see Security Configuration section)

```bash
# Set up Java environment (required for Android)
export JAVA_HOME="/opt/homebrew/opt/openjdk@21"
export PATH="$JAVA_HOME/bin:$PATH"

# Clean and rebuild
flutter clean
flutter pub get

# Run example app
cd example
flutter run

# iOS specific
cd example/ios
pod install

# Android - ensure all gradle.properties files have downloads token
# See Security Configuration section for complete setup
```

**Troubleshooting Build Issues:**
```bash
# Clear Gradle cache if authentication issues persist
cd example/android
./gradlew clean

# Verify Java version (should be 21)
java -version

# Check Gradle version compatibility
./gradlew --version
```

### Platform-Specific Commands
```bash
# iOS - Update pods after plugin changes
cd ios
pod install --repo-update

# Android - Build debug APK
cd example
flutter build apk --debug
```

## Architecture Overview

This is a Flutter plugin that wraps the Mapbox Navigation SDKs for iOS and Android, providing turn-by-turn navigation capabilities.

### Key Architecture Components

1. **Flutter Layer** (`lib/`)
   - `flutter_mapbox_navigation.dart`: Main singleton entry point (`MapBoxNavigation.instance`)
   - Platform interface using method channels for native communication
   - Event-driven architecture for navigation updates

2. **Platform Implementations**
   - **Android** (`android/src/main/kotlin/`):
     - `FlutterMapboxNavigationPlugin.kt`: Main plugin handler
     - `TurnByTurn.kt`: Core navigation logic
     - `EmbeddedNavigationMapView.kt`: Embedded view implementation
     - `StaticMarkerManager.kt`: Marker management system
   
   - **iOS** (`ios/Classes/`):
     - `FlutterMapboxNavigationPlugin.swift`: Main plugin handler
     - `NavigationFactory.swift`: Core navigation logic
     - `EmbeddedNavigationView.swift`: Embedded view implementation
     - `StaticMarkerManager.swift`: Marker management system

3. **Communication Channels**
   - Method Channel: `flutter_mapbox_navigation` - for commands
   - Event Channel: `flutter_mapbox_navigation/events` - for navigation events
   - Marker Event Channel: `flutter_mapbox_navigation/marker_events` - for marker interactions

### Navigation Modes & Features
- **Full Screen Navigation**: Launches native navigation UI
- **Embedded Navigation**: Navigation view within Flutter app
- **Free Drive Mode**: Passive navigation without destination
- **Multi-Stop Navigation**: Support for multiple waypoints with silent waypoints
- **Static Markers**: Custom POI markers with clustering support

### Critical Implementation Details

1. **Waypoint Management**
   - Minimum 2 waypoints required for navigation
   - Silent waypoints (`isSilent: true`) for route shaping
   - First and last waypoints cannot be silent
   - iOS limitation: `drivingWithTraffic` mode limited to 3 waypoints

2. **Voice Units**
   - Units are locked at first navigation initialization
   - Display units can change but voice units remain constant per session

3. **Platform Differences**
   - Android uses `FlutterFragmentActivity` as base activity
   - iOS requires background modes for audio and location
   - Android supports more markers (12 implemented, 35+ fallback to default)
   - iOS has full SF Symbols coverage for all marker types

4. **Event System**
   - Progress events provide navigation updates
   - Route building/built/failed events for route status
   - Arrival events for waypoint completion
   - Marker tap events for interactive POIs

### Security Configuration Required

⚠️ **CRITICAL**: Mapbox authentication requires both downloads tokens (for SDK dependencies) and API tokens (for runtime access).

#### Mapbox Token Requirements
1. **Downloads Token** (`sk.xxx`): Required for downloading Mapbox SDK dependencies during build
   - Must have `DOWNLOADS:READ` scope enabled in SECRET SCOPES section
   - Used in `gradle.properties` files for Maven authentication
   
2. **Public API Token** (`pk.xxx`): Required for runtime API access to Mapbox services
   - Used in application code and manifest files
   - Different from downloads token

#### Android Setup (CRITICAL - Required for Build Success)

**Step 1: Configure Downloads Token for SDK Dependencies**
The downloads token must be configured in **ALL** these locations:

```bash
# 1. Root project gradle.properties
echo "MAPBOX_DOWNLOADS_TOKEN=sk.your_secret_token_here" >> gradle.properties

# 2. Plugin-level gradle.properties  
echo "MAPBOX_DOWNLOADS_TOKEN=sk.your_secret_token_here" >> android/gradle.properties

# 3. Example app gradle.properties (CRITICAL - often missed!)
echo "MAPBOX_DOWNLOADS_TOKEN=sk.your_secret_token_here" >> example/android/gradle.properties
```

**Step 2: Configure API Token for Runtime**
```bash
# Create runtime API token file
cat > example/android/app/src/main/res/values/mapbox_access_token.xml << EOF
<?xml version="1.0" encoding="utf-8"?>
<resources xmlns:tools="http://schemas.android.com/tools">
    <string name="mapbox_access_token" translatable="false" tools:ignore="UnusedResources">pk.your_public_token_here</string>
</resources>
EOF
```

**Step 3: Verify Gradle/Java Compatibility**
- Android Gradle Plugin: Minimum 8.2.1 (for Java 21 compatibility)
- Kotlin: Minimum 2.1.0 (for Flutter compatibility)
- Java: OpenJDK 21

Update `example/android/settings.gradle`:
```gradle
plugins {
    id "com.android.application" version "8.2.1" apply false
    id "org.jetbrains.kotlin.android" version "2.1.0" apply false
}
```

#### iOS Setup
1. Create `.netrc` file with Mapbox download token
2. Add `MBXAccessToken` to Info.plist  
3. Configure location permissions

#### Common Authentication Issues

**401 Unauthorized Errors:**
- Downloads token missing `DOWNLOADS:READ` scope
- Downloads token not in `example/android/gradle.properties` (most common!)
- Using public token (`pk.xxx`) instead of secret token (`sk.xxx`) for downloads

**Java Compatibility Errors:**
- AGP version < 8.2.1 with Java 21
- Need to upgrade both AGP and Kotlin versions

**Build Context Issues:**
- The `example/android/build.gradle` runs in its own Gradle context
- Must have downloads token in `example/android/gradle.properties`, not just root level

### Testing Strategy

The project has comprehensive test coverage across:
- Unit tests: Waypoint validation, static markers, platform communication
- Integration tests: Platform waypoint handling, route creation, unit settings
- Many test stubs marked as "not yet implemented" for future work

### Known Issues & Limitations

1. **Offline Routing**: API exists but not implemented (returns "NOT_IMPLEMENTED")
2. **Voice Units**: Cannot change after first navigation initialization
3. **Mapbox API Limits**: Officially supports 25 waypoints (not enforced in plugin)
4. **Android Markers**: Only 12/47 icons implemented, others fallback to default pin

### Development Best Practices

1. **Adding Features**: Implement on both platforms simultaneously
2. **Testing**: Always test on both iOS and Android devices
3. **Error Handling**: Provide meaningful error messages through platform channels
4. **Code Style**: Follow existing patterns - Kotlin for Android, Swift for iOS
5. **Documentation**: Update README.md and relevant docs/ files when adding features