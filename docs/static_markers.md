# Static Markers

The Flutter Mapbox Navigation plugin now supports static markers that can be displayed on the map during navigation, free drive mode, and embedded map views. This feature allows developers to highlight points of interest such as scenic locations, petrol stations, restaurants, speed cameras, and more.

## Features

- **Flexible Categories**: String-based categories defined by developers
- **Custom Icons**: Predefined icon set with 30+ icons across 5 categories
- **Rich Metadata**: Flexible metadata map for category-specific information
- **Smart Visibility**: Distance-based filtering and zoom-level controls
- **Clustering**: Automatic clustering for dense marker areas
- **Interactive**: Tap callbacks with detailed information display
- **Performance Optimized**: Configurable limits and efficient rendering

## Quick Start

### 1. Create Static Markers

```dart
import 'package:flutter_mapbox_navigation/flutter_mapbox_navigation.dart';

final markers = [
  StaticMarker(
    id: 'scenic_1',
    latitude: 37.7749,
    longitude: -122.4194,
    title: 'Golden Gate Bridge',
    category: 'scenic',
    description: 'Iconic suspension bridge',
    iconId: MarkerIcons.scenic,
    customColor: Colors.orange,
    priority: 5,
    metadata: {'rating': 4.8, 'best_time': 'sunset'},
  ),
  StaticMarker(
    id: 'petrol_1',
    latitude: 37.7849,
    longitude: -122.4094,
    title: 'Shell Gas Station',
    category: 'petrol_station',
    description: '24/7 fuel station',
    iconId: MarkerIcons.petrolStation,
    customColor: Colors.green,
    metadata: {'price': 1.85, 'brand': 'Shell'},
  ),
];
```

### 2. Add Markers to Map

```dart
await MapBoxNavigation.instance.addStaticMarkers(
  markers: markers,
  configuration: MarkerConfiguration(
    maxDistanceFromRoute: 5.0, // 5km from route
    enableClustering: true,
    onMarkerTap: (marker) {
      print('Tapped: ${marker.title}');
    },
  ),
);
```

### 3. Handle Marker Taps

```dart
// Register tap listener
await MapBoxNavigation.instance.registerStaticMarkerTapListener(
  (marker) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(marker.title),
        content: Text(marker.description ?? ''),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  },
);
```

## API Reference

### StaticMarker

Represents a static marker that can be displayed on the map.

#### Properties

| Property | Type | Required | Description |
|----------|------|----------|-------------|
| `id` | `String` | Yes | Unique identifier for the marker |
| `latitude` | `double` | Yes | Latitude coordinate |
| `longitude` | `double` | Yes | Longitude coordinate |
| `title` | `String` | Yes | Title/name of the marker |
| `category` | `String` | Yes | Category (flexible string defined by developers) |
| `description` | `String?` | No | Optional description |
| `iconId` | `String?` | No | Icon identifier from MarkerIcons |
| `customColor` | `Color?` | No | Custom color for the marker |
| `priority` | `int?` | No | Priority level (higher = more important) |
| `isVisible` | `bool` | No | Whether marker is visible (default: true) |
| `metadata` | `Map<String, dynamic>?` | No | Flexible metadata map |

#### Methods

- `toJson()`: Converts marker to JSON map
- `fromJson(Map<String, dynamic>)`: Creates marker from JSON
- `copyWith(...)`: Creates copy with updated fields

### MarkerConfiguration

Configuration for marker display and behavior.

#### Properties

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `showDuringNavigation` | `bool` | `true` | Show markers during navigation |
| `showInFreeDrive` | `bool` | `true` | Show markers in free drive mode |
| `showOnEmbeddedMap` | `bool` | `true` | Show markers on embedded map |
| `maxDistanceFromRoute` | `double?` | `null` | Max distance from route (km) |
| `minZoomLevel` | `double` | `10.0` | Minimum zoom to show markers |
| `enableClustering` | `bool` | `true` | Enable marker clustering |
| `maxMarkersToShow` | `int?` | `null` | Maximum markers to display |
| `onMarkerTap` | `Function(StaticMarker)?` | `null` | Tap callback function |
| `defaultIconId` | `String?` | `null` | Default icon for markers |
| `defaultColor` | `Color?` | `null` | Default color for markers |

### MarkerIcons

Predefined icon identifiers organized by category.

#### Categories

**Transportation**
- `petrolStation` - Gas station
- `chargingStation` - Electric charging station
- `parking` - Parking area
- `busStop` - Bus stop
- `trainStation` - Train station
- `airport` - Airport
- `port` - Port/harbor

**Food & Services**
- `restaurant` - Restaurant
- `cafe` - Cafe/coffee shop
- `hotel` - Hotel/accommodation
- `shop` - Shop/store
- `pharmacy` - Pharmacy
- `hospital` - Hospital
- `police` - Police station
- `fireStation` - Fire station

**Scenic & Recreation**
- `scenic` - Scenic viewpoint
- `park` - Park/recreation area
- `beach` - Beach
- `mountain` - Mountain
- `lake` - Lake
- `waterfall` - Waterfall
- `viewpoint` - Viewpoint
- `hiking` - Hiking trail

**Safety & Traffic**
- `speedCamera` - Speed camera
- `accident` - Accident/incident
- `construction` - Road construction
- `trafficLight` - Traffic light
- `speedBump` - Speed bump
- `schoolZone` - School zone

**General**
- `pin` - Generic pin
- `star` - Star/favorite
- `heart` - Heart/like
- `flag` - Flag
- `warning` - Warning
- `info` - Information
- `question` - Question mark

#### Methods

- `getAllIcons()`: Returns all available icon IDs
- `getIconsByCategory()`: Returns icons grouped by category
- `isValidIcon(String)`: Validates if icon ID is supported

## Platform Icon Coverage

### Current Status

**iOS Platform:**
- ✅ **Complete Coverage**: 40+ SF Symbols for all marker types
- ✅ **High Quality**: Scalable, consistent system icons
- ✅ **All Categories**: Transportation, Food & Services, Scenic & Recreation, Safety & Traffic, General

**Android Platform:**
- ✅ **Essential Icons**: 12 core icons implemented
  - `ic_pin.xml`, `ic_scenic.xml`, `ic_petrol_station.xml`
  - `ic_charging_station.xml`, `ic_parking.xml`, `ic_restaurant.xml`
  - `ic_hotel.xml`, `ic_hospital.xml`, `ic_police.xml`
  - `ic_speed_camera.xml`, `ic_accident.xml`, `ic_construction.xml`
- ⚠️ **Missing Icons**: 35 additional icons fall back to default pin
  - Basic: star, heart, flag, warning, info, question
  - Transportation: bus_stop, train_station, airport, port
  - Food & Services: cafe, shop, pharmacy, fire_station
  - Scenic & Recreation: park, beach, mountain, lake, waterfall, viewpoint, hiking
  - Safety & Traffic: traffic_light, speed_bump, school_zone
  - Additional: school, church, shopping, bank, atm, gas_station, car_wash, toll, border, custom

### TODO: Complete Android Icon Implementation

**Priority**: Low (essential markers work on both platforms)

**Task**: Create 35 missing Android vector drawable files in `android/src/main/res/drawable/`:

1. **Basic Icons** (6 files):
   - `ic_star.xml`, `ic_heart.xml`, `ic_flag.xml`, `ic_warning.xml`, `ic_info.xml`, `ic_question.xml`

2. **Transportation Icons** (4 files):
   - `ic_bus_stop.xml`, `ic_train_station.xml`, `ic_airport.xml`, `ic_port.xml`

3. **Food & Services Icons** (4 files):
   - `ic_cafe.xml`, `ic_shop.xml`, `ic_pharmacy.xml`, `ic_fire_station.xml`

4. **Scenic & Recreation Icons** (7 files):
   - `ic_park.xml`, `ic_beach.xml`, `ic_mountain.xml`, `ic_lake.xml`, `ic_waterfall.xml`, `ic_viewpoint.xml`, `ic_hiking.xml`

5. **Safety & Traffic Icons** (3 files):
   - `ic_traffic_light.xml`, `ic_speed_bump.xml`, `ic_school_zone.xml`

6. **Additional Service Icons** (11 files):
   - `ic_school.xml`, `ic_church.xml`, `ic_shopping.xml`, `ic_bank.xml`, `ic_atm.xml`, `ic_gas_station.xml`, `ic_car_wash.xml`, `ic_toll.xml`, `ic_border.xml`, `ic_custom.xml`

**Impact**: Complete cross-platform icon parity for all 47 marker types.

**Note**: All markers are functional - missing icons simply fall back to the default pin icon on Android.

## Usage Examples

### Basic Marker

```dart
final marker = StaticMarker(
  id: 'simple_1',
  latitude: 37.7749,
  longitude: -122.4194,
  title: 'Simple Marker',
  category: 'custom',
);
```

### Marker with Custom Icon and Color

```dart
final marker = StaticMarker(
  id: 'custom_1',
  latitude: 37.7849,
  longitude: -122.4094,
  title: 'Custom Marker',
  category: 'restaurant',
  description: 'A great place to eat',
  iconId: MarkerIcons.restaurant,
  customColor: Colors.red,
  priority: 3,
);
```

### Marker with Metadata

```dart
final marker = StaticMarker(
  id: 'detailed_1',
  latitude: 37.7949,
  longitude: -122.3994,
  title: 'Detailed Marker',
  category: 'petrol_station',
  description: '24/7 fuel station',
  iconId: MarkerIcons.petrolStation,
  metadata: {
    'price': 1.85,
    'brand': 'Shell',
    'open_24h': true,
    'services': ['fuel', 'convenience_store', 'car_wash'],
    'rating': 4.2,
  },
);
```

### Configuration Examples

#### Basic Configuration

```dart
final config = MarkerConfiguration(
  maxDistanceFromRoute: 5.0,
  enableClustering: true,
);
```

#### Advanced Configuration

```dart
final config = MarkerConfiguration(
  showDuringNavigation: true,
  showInFreeDrive: true,
  showOnEmbeddedMap: true,
  maxDistanceFromRoute: 10.0,
  minZoomLevel: 12.0,
  enableClustering: true,
  maxMarkersToShow: 100,
  defaultIconId: MarkerIcons.pin,
  defaultColor: Colors.blue,
  onMarkerTap: (marker) {
    print('Marker tapped: ${marker.title}');
  },
);
```

### Complete Example

```dart
import 'package:flutter/material.dart';
import 'package:flutter_mapbox_navigation/flutter_mapbox_navigation.dart';

class MarkerExample extends StatefulWidget {
  @override
  _MarkerExampleState createState() => _MarkerExampleState();
}

class _MarkerExampleState extends State<MarkerExample> {
  bool _markersAdded = false;

  final List<StaticMarker> _markers = [
    StaticMarker(
      id: 'scenic_1',
      latitude: 37.7749,
      longitude: -122.4194,
      title: 'Golden Gate Bridge',
      category: 'scenic',
      description: 'Iconic suspension bridge',
      iconId: MarkerIcons.scenic,
      customColor: Colors.orange,
    ),
    StaticMarker(
      id: 'petrol_1',
      latitude: 37.7849,
      longitude: -122.4094,
      title: 'Shell Gas Station',
      category: 'petrol_station',
      description: '24/7 fuel station',
      iconId: MarkerIcons.petrolStation,
      customColor: Colors.green,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _setupMarkerListener();
  }

  void _setupMarkerListener() {
    MapBoxNavigation.instance.registerStaticMarkerTapListener((marker) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Tapped: ${marker.title}'),
          action: SnackBarAction(
            label: 'Details',
            onPressed: () => _showMarkerDetails(marker),
          ),
        ),
      );
    });
  }

  void _showMarkerDetails(StaticMarker marker) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(marker.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Category: ${marker.category}'),
            if (marker.description != null) ...[
              const SizedBox(height: 8),
              Text('Description: ${marker.description}'),
            ],
            if (marker.metadata != null && marker.metadata!.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text('Details:', style: TextStyle(fontWeight: FontWeight.bold)),
              ...marker.metadata!.entries.map((entry) => 
                Text('• ${entry.key}: ${entry.value}'),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _addMarkers() async {
    final success = await MapBoxNavigation.instance.addStaticMarkers(
      markers: _markers,
      configuration: MarkerConfiguration(
        maxDistanceFromRoute: 5.0,
        enableClustering: true,
      ),
    );

    if (success == true) {
      setState(() {
        _markersAdded = true;
      });
    }
  }

  Future<void> _removeMarkers() async {
    final success = await MapBoxNavigation.instance.clearAllStaticMarkers();
    
    if (success == true) {
      setState(() {
        _markersAdded = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Static Markers Example')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: _markersAdded ? null : _addMarkers,
              child: const Text('Add Static Markers'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _markersAdded ? _removeMarkers : null,
              child: const Text('Remove Markers'),
            ),
          ],
        ),
      ),
    );
  }
}
```

## Best Practices

### 1. Icon Selection

- Use appropriate icons for each category
- Consider color coding for different marker types
- Use priority levels for important markers

### 2. Performance

- Limit the number of markers (use `maxMarkersToShow`)
- Enable clustering for dense areas
- Use distance filtering to show only relevant markers

### 3. User Experience

- Provide meaningful titles and descriptions
- Use metadata for additional context
- Implement tap callbacks for interaction
- Consider adding markers as waypoints

### 4. Categories

- Use consistent category names across your app
- Consider hierarchical categories (e.g., "restaurant.fast_food")
- Document your category system

## Limitations

- **Platform Support**: Currently supports iOS and Android
- **Icon Customization**: Limited to predefined icon set (URL support planned)
- **Clustering**: Basic clustering implementation
- **Performance**: Large numbers of markers may impact performance

## Future Enhancements

- [ ] Custom icon URLs
- [ ] Advanced clustering options
- [ ] Category-based filtering
- [ ] Marker animations
- [ ] Custom marker shapes
- [ ] Offline marker support 