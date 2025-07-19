[![Pub][pub_badge]][pub] [![BuyMeACoffee][buy_me_a_coffee_badge]][buy_me_a_coffee]

# flutter_mapbox_navigation

Add Turn By Turn Navigation to Your Flutter Application Using MapBox. Never leave your app when you need to navigate your users to a location.

## Features

### Core Navigation Features
* A full-fledged turn-by-turn navigation UI for Flutter that's ready to drop into your application
* Worldwide driving, cycling, and walking directions powered by [open data](https://www.mapbox.com/about/open/) and user feedback
* Traffic avoidance and proactive rerouting based on current conditions in [over 55 countries](https://docs.mapbox.com/help/how-mapbox-works/directions/#traffic-data)
* **Free Drive Mode** - Passive navigation without a set destination
* **Multi-stop Navigation** - Support for up to 25 waypoints with dynamic additions
* **Route Simulation** - Test navigation with simulated movement

### Map & UI Features
* [Professionally designed map styles](https://www.mapbox.com/maps/) for daytime and nighttime driving
* **Embedded Navigation View** - Customizable navigation UI that integrates seamlessly into your app
* Support for multiple waypoints and route alternatives
* **Map Controller** - Full programmatic control over navigation state and map interactions

### Voice & Language Features
* Natural-sounding turn instructions powered by [Amazon Polly](https://aws.amazon.com/polly/) (no configuration needed)
* [Support for over two dozen languages](https://docs.mapbox.com/ios/navigation/overview/localization-and-internationalization/)
* Customizable voice instructions and banner guidance
* **Unit System Support** - Imperial and metric units (note: voice units are locked at first initialization)

### Advanced Features
* **Event-Driven Architecture** - Comprehensive event system for navigation progress, route updates, and user interactions
* **Offline Routing** - Download navigation data for offline use *(Coming Soon)*
* **Modern Android Support** - Android 13+ compatibility with enhanced security
* **Type-Safe API** - Improved error handling and type safety across all platforms

## Setup Instructions

### Prerequisites
1. A Mapbox account with access tokens
2. Flutter development environment set up (SDK >=2.19.4, Flutter >=2.5.0)
3. iOS and/or Android development environment configured

### iOS Configuration

1. **Download Token Setup**
   - Go to your [Mapbox account dashboard](https://account.mapbox.com/)
   - Create an access token with the `DOWNLOADS:READ` scope
   - **IMPORTANT**: This is different from your production API token
   - Create or edit `.netrc` in your home directory:
     ```
     machine api.mapbox.com
       login mapbox
       password YOUR_DOWNLOAD_TOKEN
     ```

2. **API Token Configuration**
   - Get your API token from [Mapbox account page](https://account.mapbox.com/access-tokens/)
   - In Xcode, select your target → Info tab
   - Add `MBXAccessToken` with your token value
   - **SECURITY**: Never commit your token to source control

3. **Location & Background Setup**
   - Add `NSLocationWhenInUseUsageDescription` to Info.plist:
     ```xml
     <key>NSLocationWhenInUseUsageDescription</key>
     <string>Shows your location on the map and helps improve OpenStreetMap.</string>
     ```
   - Enable background modes in Xcode:
     - Audio, AirPlay, and Picture in Picture
     - Location updates

### Android Configuration

1. **API Token Setup**
   - Create `mapbox_access_token.xml` in `android/app/src/main/res/values/`
   - Add your token (never commit this file):
     ```xml
     <?xml version="1.0" encoding="utf-8"?>
     <resources xmlns:tools="http://schemas.android.com/tools">
         <string name="mapbox_access_token" translatable="false" tools:ignore="UnusedResources">YOUR_TOKEN_HERE</string>
     </resources>
     ```

2. **Permissions**
   - Add to `AndroidManifest.xml`:
     ```xml
     <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
     <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
     <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
     ```

3. **Download Token Setup**
   - Add to `gradle.properties`:
     ```
     MAPBOX_DOWNLOADS_TOKEN=YOUR_DOWNLOAD_TOKEN
     ```
   - **SECURITY**: Add this file to .gitignore

4. **Activity Configuration**
   - Update `MainActivity.kt`:
     ```kotlin
     import io.flutter.embedding.android.FlutterFragmentActivity
     
     class MainActivity: FlutterFragmentActivity() {
     }
     ```

5. **Kotlin Version**
   - Add to `android/app/build.gradle`:
     ```gradle
     implementation platform("org.jetbrains.kotlin:kotlin-bom:1.8.0")
     ```

## Usage Examples

### Basic Navigation Setup

```dart
// 1. Configure default options (optional)
MapBoxNavigation.instance.setDefaultOptions(MapBoxOptions(
    initialLatitude: 36.1175275,
    initialLongitude: -115.1839524,
    zoom: 13.0,
    tilt: 0.0,
    bearing: 0.0,
    enableRefresh: false,
    alternatives: true,
    voiceInstructionsEnabled: true,
    bannerInstructionsEnabled: true,
    allowsUTurnAtWayPoints: true,
    mode: MapBoxNavigationMode.drivingWithTraffic,
    units: VoiceUnits.imperial,
    simulateRoute: true,
    language: "en"
));

// 2. Define waypoints
final cityhall = WayPoint(
    name: "City Hall", 
    latitude: 42.886448, 
    longitude: -78.878372
);
final downtown = WayPoint(
    name: "Downtown Buffalo", 
    latitude: 42.8866177, 
    longitude: -78.8814924
);

// 3. Start navigation
await MapBoxNavigation.instance.startNavigation(
    wayPoints: [cityhall, downtown]
);
```

### Free Drive Mode

```dart
// Start free drive mode (passive navigation without destination)
await MapBoxNavigation.instance.startFreeDrive(
    options: MapBoxOptions(
        initialLatitude: 36.1175275,
        initialLongitude: -115.1839524,
        zoom: 15.0,
        mode: MapBoxNavigationMode.drivingWithTraffic,
        units: VoiceUnits.metric,
        language: "en"
    )
);
```

### Multi-Stop Navigation

```dart
// Define multiple waypoints
final waypoints = [
    WayPoint(name: "Start", latitude: 37.774406, longitude: -122.435397),
    WayPoint(name: "Stop 1", latitude: 37.765569, longitude: -122.424098, isSilent: true),
    WayPoint(name: "Stop 2", latitude: 37.784406, longitude: -122.445397, isSilent: false),
    WayPoint(name: "Destination", latitude: 37.794406, longitude: -122.455397),
];

// Start multi-stop navigation
await MapBoxNavigation.instance.startNavigation(
    wayPoints: waypoints,
    options: MapBoxOptions(
        mode: MapBoxNavigationMode.driving,
        simulateRoute: true,
        allowsUTurnAtWayPoints: true
    )
);

// Add waypoints during navigation
await Future.delayed(Duration(seconds: 10));
final newStop = WayPoint(
    name: "Gas Station",
    latitude: 37.774406,
    longitude: -122.435397,
    isSilent: false
);
await MapBoxNavigation.instance.addWayPoints(wayPoints: [newStop]);
```

### Event Handling

```dart
// Register for navigation events
MapBoxNavigation.instance.registerRouteEventListener(_onRouteEvent);

Future<void> _onRouteEvent(e) async {
    // Get remaining distance and duration
    _distanceRemaining = await MapBoxNavigation.instance.getDistanceRemaining();
    _durationRemaining = await MapBoxNavigation.instance.getDurationRemaining();

    // Handle different event types
    switch (e.eventType) {
        case MapBoxEvent.progress_change:
            var progressEvent = e.data as RouteProgressEvent;
            _arrived = progressEvent.arrived;
            if (progressEvent.currentStepInstruction != null) {
                _instruction = progressEvent.currentStepInstruction;
            }
            break;
            
        case MapBoxEvent.route_building:
        case MapBoxEvent.route_built:
            _routeBuilt = true;
            break;
            
        case MapBoxEvent.route_build_failed:
            _routeBuilt = false;
            break;
            
        case MapBoxEvent.navigation_running:
            _isNavigating = true;
            break;
            
        case MapBoxEvent.on_arrival:
            _arrived = true;
            if (!_isMultipleStop) {
                await Future.delayed(Duration(seconds: 3));
                await MapBoxNavigation.instance.finishNavigation();
            }
            break;
            
        case MapBoxEvent.navigation_finished:
        case MapBoxEvent.navigation_cancelled:
            _routeBuilt = false;
            _isNavigating = false;
            break;
    }
    
    // Update UI
    setState(() {});
}
```

### Embedded Navigation View

```dart
// 1. Declare controller
MapBoxNavigationViewController? _controller;

// 2. Add to widget tree
Container(
    height: 300,
    child: MapBoxNavigationView(
        options: _options,
        onRouteEvent: _onRouteEvent,
        onCreated: (MapBoxNavigationViewController controller) async {
            _controller = controller;
            await controller.initialize();
        }
    ),
)

// 3. Build and start navigation
var wayPoints = [
    _origin,
    _stop1,
    _stop2,
    _stop3,
    _stop4,
    _origin
];

// Build the route
await _controller?.buildRoute(wayPoints: wayPoints);

// Start navigation
await _controller?.startNavigation();

// Free drive in embedded view
await _controller?.startFreeDrive();
```

## Screenshots

### Full Screen Navigation
![Navigation View](screenshots/screenshot1.png?raw=true "iOS View") | ![Android View](screenshots/screenshot2.png?raw=true "Android View")
|:---:|:---:|
| iOS View | Android View |

### Embedded Navigation
![Navigation View](screenshots/screenshot3.png?raw=true "Embedded iOS View") | ![Navigation View](screenshots/screenshot4.png?raw=true "Embedded Android View")
|:---:|:---:|
| Embedded iOS View | Embedded Android View |

## Platform Support

| Platform | Status | Notes |
|----------|--------|-------|
| iOS | ✅ Fully Supported | iOS 10+ required |
| Android | ✅ Fully Supported | API 21+ required, Android 13+ optimized |

## Roadmap
* [DONE] Android Implementation
* [DONE] Add more settings like Navigation Mode (driving, walking, etc)
* [DONE] Stream Events like relevant navigation notifications, metrics, current location, etc. 
* [DONE] Embeddable Navigation View 
* [PLANNED] Offline Routing
* [DONE] Free Drive Mode
* [DONE] Multi-stop Navigation
* [DONE] Enhanced Error Handling
* [DONE] Android 13+ Security Updates
* [PLANNED] Map Markers System
* [PLANNED] Vehicle Movement Simulation
* [PLANNED] Enhanced UI Components
* [PLANNED] Offline Routing Implementation

## Technical Notes

### Voice Instruction Units
Voice instruction units are locked at first initialization of the navigation session by design in the Mapbox SDK. While display units can be changed at runtime, voice instructions will maintain their initial units throughout the navigation session.

### Android Security
The plugin has been updated for Android 13+ compatibility with proper receiver registration and enhanced security measures.

### Offline Routing Status
The `enableOfflineRouting()` method exists in the API but is not currently implemented. Android returns a "NOT_IMPLEMENTED" error, and iOS has the implementation commented out. This feature is planned for future releases.

## Documentation

For detailed technical documentation, architecture overview, and implementation guides, see the `/docs` directory:
- [Architecture Overview](docs/overview.md)
- [Feature Comparison](docs/feature_comparison.md)
- [Modernization Summary](docs/modernisation.md)
- [Testing Strategy](docs/testing_strategy.md)
- [Map Marker Implementation Plan](docs/marker_implementation.md)

## Changelog

### [Unreleased]
#### Breaking Changes
- Improved `addWayPoints` API to return meaningful results:
  - Now returns `WaypointResult` with success status and number of waypoints added
  - Added proper error handling and feedback
  - Makes the API more consistent with other navigation methods

#### Improvements
- Added better error handling for waypoint operations
- Improved type safety across the navigation API
- Enhanced test coverage for platform communication

<!-- Links -->
[pub_badge]: https://img.shields.io/pub/v/flutter_mapbox_navigation.svg
[pub]: https://pub.dev/packages/flutter_mapbox_navigation
[buy_me_a_coffee]: https://www.buymeacoffee.com/eopeter
[buy_me_a_coffee_badge]: https://img.buymeacoffee.com/button-api/?text=Donate&emoji=&slug=eopeter&button_colour=29b6f6&font_colour=000000&font_family=Cookie&outline_colour=000000&coffee_colour=FFDD00