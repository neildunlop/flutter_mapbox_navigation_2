import 'package:flutter/material.dart';
import 'package:flutter_mapbox_navigation/flutter_mapbox_navigation.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mapbox Navigation Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Mapbox Navigation Demo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final List<StaticMarker> _markers = [];
  final List<MarkerOverlay> _markerOverlays = [];
  bool _isNavigationActive = false;

  @override
  void initState() {
    super.initState();
    _initializeMarkers();
    _setupMarkerEventListener();
  }

  void _initializeMarkers() {
    _markers.addAll([
      StaticMarker(
        id: 'scenic_1',
        latitude: 37.7749,
        longitude: -122.4194,
        title: 'Golden Gate Bridge',
        category: 'scenic',
        description: 'Iconic suspension bridge',
        iconId: MarkerIcons.scenic,
        customColor: const Color(0xFFFF6B35),
      ),
      StaticMarker(
        id: 'petrol_1',
        latitude: 37.7849,
        longitude: -122.4094,
        title: 'Shell Station',
        category: 'petrol_station',
        description: '24/7 fuel station',
        iconId: MarkerIcons.petrolStation,
        customColor: const Color(0xFF4CAF50),
      ),
      StaticMarker(
        id: 'restaurant_1',
        latitude: 37.7649,
        longitude: -122.4294,
        title: 'Fisherman\'s Wharf',
        category: 'restaurant',
        description: 'Famous seafood restaurants',
        iconId: MarkerIcons.restaurant,
        customColor: const Color(0xFFFF9800),
      ),
    ]);
  }

  void _setupMarkerEventListener() {
    MapBoxNavigation.instance.registerRouteEventListener((RouteEvent event) {
      if (event.eventType == MapBoxEvent.on_map_tap) {
        // Handle marker tap events
        print('Marker tapped: ${event.data}');
        _showMarkerInfo(event.data);
      }
    });
  }

  void _showMarkerInfo(dynamic markerData) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(markerData['title'] ?? 'Marker'),
        content: Text(markerData['description'] ?? 'No description available'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
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
        maxMarkersToShow: 50,
        showDuringNavigation: true,
        showInFreeDrive: true,
        showOnEmbeddedMap: true,
      ),
    );

    if (success == true) {
      setState(() {
        // Create marker overlays for visual rendering on Android
        _markerOverlays.clear();
        for (final marker in _markers) {
          _markerOverlays.add(MarkerOverlay(
            id: marker.id,
            title: marker.title,
            latitude: marker.latitude,
            longitude: marker.longitude,
            iconId: marker.iconId ?? MarkerIcons.pin,
            customColor: marker.customColor,
            onTap: () => _showMarkerInfo({
              'title': marker.title,
              'description': marker.description,
              'category': marker.category,
            }),
          ));
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Markers added successfully!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to add markers')),
      );
    }
  }

  Future<void> _removeMarkers() async {
    final success = await MapBoxNavigation.instance.removeStaticMarkers(
      markerIds: _markers.map((m) => m.id).toList(),
    );

    if (success == true) {
      setState(() {
        _markerOverlays.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Markers removed successfully!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to remove markers')),
      );
    }
  }

  Future<void> _clearMarkers() async {
    final success = await MapBoxNavigation.instance.clearAllStaticMarkers();

    if (success == true) {
      setState(() {
        _markerOverlays.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All markers cleared!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to clear markers')),
      );
    }
  }

  Future<void> _startNavigation() async {
    final wayPoints = [
      WayPoint(
        name: "San Francisco",
        latitude: 37.7749,
        longitude: -122.4194,
      ),
      WayPoint(
        name: "Golden Gate Bridge",
        latitude: 37.8199,
        longitude: -122.4783,
      ),
    ];

    final success = await MapBoxNavigation.instance.startNavigation(
      wayPoints: wayPoints,
      options: MapBoxOptions(
        zoom: 15.0,
        voiceInstructionsEnabled: true,
        bannerInstructionsEnabled: true,
        mode: MapBoxNavigationMode.drivingWithTraffic,
        units: VoiceUnits.metric,
        simulateRoute: true,
      ),
    );

    if (success == true) {
      setState(() {
        _isNavigationActive = true;
      });
    }
  }

  Future<void> _startFreeDrive() async {
    final success = await MapBoxNavigation.instance.startFreeDrive(
      options: MapBoxOptions(
        zoom: 15.0,
        voiceInstructionsEnabled: false,
        bannerInstructionsEnabled: false,
        mode: MapBoxNavigationMode.driving,
        units: VoiceUnits.metric,
      ),
    );

    if (success == true) {
      setState(() {
        _isNavigationActive = true;
      });
    }
  }

  Future<void> _finishNavigation() async {
    final success = await MapBoxNavigation.instance.finishNavigation();

    if (success == true) {
      setState(() {
        _isNavigationActive = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Stack(
        children: [
          // Mapbox Navigation View
          Container(
            color: Colors.grey[300],
            child: const Center(
              child: Text(
                'Mapbox Navigation View\n(Visual markers implemented via Flutter overlays)',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
          
          // Marker Overlays for Android Visual Rendering
          if (_markerOverlays.isNotEmpty)
            ..._markerOverlays.map((overlay) => overlay.build(context)),
          
          // Control Panel
          Positioned(
            top: 16,
            right: 16,
            child: Column(
              children: [
                FloatingActionButton(
                  onPressed: _addMarkers,
                  tooltip: 'Add Markers',
                  child: const Icon(Icons.add_location),
                ),
                const SizedBox(height: 8),
                FloatingActionButton(
                  onPressed: _removeMarkers,
                  tooltip: 'Remove Markers',
                  child: const Icon(Icons.location_off),
                ),
                const SizedBox(height: 8),
                FloatingActionButton(
                  onPressed: _clearMarkers,
                  tooltip: 'Clear All Markers',
                  child: const Icon(Icons.clear_all),
                ),
              ],
            ),
          ),
          
          // Navigation Controls
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: _isNavigationActive ? null : _startNavigation,
                  child: const Text('Start Navigation'),
                ),
                ElevatedButton(
                  onPressed: _isNavigationActive ? null : _startFreeDrive,
                  child: const Text('Free Drive'),
                ),
                ElevatedButton(
                  onPressed: _isNavigationActive ? _finishNavigation : null,
                  child: const Text('Finish'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Marker Overlay Widget for Visual Android Rendering
class MarkerOverlay {
  final String id;
  final String title;
  final double latitude;
  final double longitude;
  final String iconId;
  final Color? customColor;
  final VoidCallback onTap;

  MarkerOverlay({
    required this.id,
    required this.title,
    required this.latitude,
    required this.longitude,
    required this.iconId,
    this.customColor,
    required this.onTap,
  });

  Widget build(BuildContext context) {
    // This is a simplified overlay - in a real implementation,
    // you would convert lat/lng to screen coordinates
    return Positioned(
      left: 100, // Simplified positioning
      top: 200,  // Simplified positioning
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _getMarkerColor(),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _getMarkerIcon(),
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getMarkerColor() {
    if (customColor != null) {
      return customColor!;
    }
    
    // Default colors based on category
    switch (iconId) {
      case MarkerIcons.scenic:
        return Colors.orange;
      case MarkerIcons.petrolStation:
        return Colors.green;
      case MarkerIcons.restaurant:
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  IconData _getMarkerIcon() {
    switch (iconId) {
      case MarkerIcons.scenic:
        return Icons.landscape;
      case MarkerIcons.petrolStation:
        return Icons.local_gas_station;
      case MarkerIcons.restaurant:
        return Icons.restaurant;
      default:
        return Icons.location_on;
    }
  }
}