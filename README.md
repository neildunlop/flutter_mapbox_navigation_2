[![Pub][pub_badge]][pub] [![BuyMeACoffee][buy_me_a_coffee_badge]][buy_me_a_coffee]

# flutter_mapbox_navigation

Add Turn By Turn Navigation to Your Flutter Application Using MapBox. Never leave your app when you need to navigate your users to a location.

## Features

### Core Navigation Features
* A full-fledged turn-by-turn navigation UI for Flutter that's ready to drop into your application
* Worldwide driving, cycling, and walking directions powered by [open data](https://www.mapbox.com/about/open/) and user feedback
* Traffic avoidance and proactive rerouting based on current conditions in [over 55 countries](https://docs.mapbox.com/help/how-mapbox-works/directions/#traffic-data)

### Map & UI Features
* [Professionally designed map styles](https://www.mapbox.com/maps/) for daytime and nighttime driving
* Customizable navigation UI with embedded view support
* Support for multiple waypoints and route alternatives

### Voice & Language Features
* Natural-sounding turn instructions powered by [Amazon Polly](https://aws.amazon.com/polly/) (no configuration needed)
* [Support for over two dozen languages](https://docs.mapbox.com/ios/navigation/overview/localization-and-internationalization/)
* Customizable voice instructions and banner guidance

## Setup Instructions

### Prerequisites
1. A Mapbox account with access tokens
2. Flutter development environment set up
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

### Event Handling

```dart
// Register for navigation events
MapBoxNavigation.instance.registerRouteEventListener(_onRouteEvent);

Future<void> _onRouteEvent(e) async {
    // Get remaining distance and duration
    _distanceRemaining = await _directions.distanceRemaining;
    _durationRemaining = await _directions.durationRemaining;

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
                await _controller.finishNavigation();
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
MapBoxNavigationViewController _controller;

// 2. Add to widget tree
Container(
    color: Colors.grey,
    child: MapBoxNavigationView(
        options: _options,
        onRouteEvent: _onRouteEvent,
        onCreated: (MapBoxNavigationViewController controller) async {
            _controller = controller;
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
_controller.buildRoute(wayPoints: wayPoints);

// Start navigation
_controller.startNavigation();
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

## Roadmap
* [DONE] Android Implementation
* [DONE] Add more settings like Navigation Mode (driving, walking, etc)
* [DONE] Stream Events like relevant navigation notifications, metrics, current location, etc. 
* [DONE] Embeddable Navigation View 
* Offline Routing

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