import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mapbox_navigation/flutter_mapbox_navigation.dart';
import 'popup_example.dart';

void main() {
  runApp(const SampleNavigationApp());
}

class SampleNavigationApp extends StatelessWidget {
  const SampleNavigationApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mapbox Navigation Example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const SampleNavigationHome(),
    );
  }
}

class SampleNavigationHome extends StatefulWidget {
  const SampleNavigationHome({super.key});

  @override
  State<SampleNavigationHome> createState() => _SampleNavigationHomeState();
}

class _SampleNavigationHomeState extends State<SampleNavigationHome> {
  String? _platformVersion;
  String? _instruction;
  final _origin = WayPoint(
      name: "Google HQ",
      latitude: 37.4220,
      longitude: -122.0841,
      isSilent: false);
  final _stop1 = WayPoint(
      name: "Computer History Museum",
      latitude: 37.4143,
      longitude: -122.0768,
      isSilent: true);
  final _stop2 = WayPoint(
      name: "Shoreline Amphitheatre",
      latitude: 37.4267,
      longitude: -122.0806,
      isSilent: false);
  final _stop3 = WayPoint(
      name: "LinkedIn HQ",
      latitude: 37.4249,
      longitude: -122.0657,
      isSilent: true);
  final _destination = WayPoint(
      name: "Stanford University",
      latitude: 37.4275,
      longitude: -122.1697,
      isSilent: false);

  final _home = WayPoint(
      name: "Google HQ (Start)",
      latitude: 37.4220,
      longitude: -122.0841,
      isSilent: false);

  final _store = WayPoint(
      name: "Downtown Palo Alto",
      latitude: 37.4419,
      longitude: -122.1430,
      isSilent: false);

  bool _isMultipleStop = false;
  double? _distanceRemaining, _durationRemaining;
  MapBoxNavigationViewController? _controller;
  bool _routeBuilt = false;
  bool _isNavigating = false;
  bool _inFreeDrive = false;
  bool _isFullScreenNavigation = false; // Track if we're in full-screen vs embedded navigation
  late MapBoxOptions _navigationOption;
  
  // Static marker state
  bool _markersAdded = false;
  String? _lastTappedMarker;
  // bool _justFinishedFlutterNavigation = false; // TODO: Remove if not needed

  final List<StaticMarker> _sampleMarkers = [
    // MOUNTAIN VIEW / GOOGLE HQ AREA TEST MARKERS
    const StaticMarker(
      id: 'google_hq_test',
      latitude: 37.4220, // Amphitheatre Parkway, Mountain View
      longitude: -122.0841,
      title: '🔴 LARGE MARKER (3x size)',
      category: 'pin',
      description: 'Large test marker at Google headquarters',
      iconId: MarkerIcons.pin,
      customColor: Colors.red,
      priority: 10,
      size: 3.0, // 3x size to demonstrate scaling
      metadata: {'type': 'test', 'location': 'google_hq', 'size': 3.0},
    ),
    const StaticMarker(
      id: 'computer_history_test',
      latitude: 37.4143,
      longitude: -122.0768,
      title: '🟡 SMALL MARKER (0.5x size)',
      category: 'scenic',
      description: 'Small test marker at Computer History Museum',
      iconId: MarkerIcons.scenic,
      customColor: Colors.orange,
      priority: 8,
      size: 0.5, // Half size to demonstrate small markers
      metadata: {'type': 'test', 'location': 'museum', 'size': 0.5},
    ),
    const StaticMarker(
      id: 'shoreline_test',
      latitude: 37.4267,
      longitude: -122.0806,
      title: '🟢 NORMAL MARKER (default size)',
      category: 'restaurant',
      description: 'Default size marker at Shoreline Amphitheatre',
      iconId: MarkerIcons.restaurant,
      customColor: Colors.green,
      priority: 7,
      // No size specified = uses default size (1.0)
      metadata: {'type': 'test', 'location': 'venue'},
    ),
    const StaticMarker(
      id: 'linkedin_test',
      latitude: 37.4249,
      longitude: -122.0657,
      title: '🔵 LINKEDIN HQ',
      category: 'hotel',
      description: 'Test marker at LinkedIn headquarters',
      iconId: MarkerIcons.hotel,
      customColor: Colors.blue,
      priority: 6,
      metadata: {'type': 'test', 'location': 'office'},
    ),
    
    // MORE MOUNTAIN VIEW / PALO ALTO AREA MARKERS
    const StaticMarker(
      id: 'stanford_test',
      latitude: 37.4275, // Stanford University
      longitude: -122.1697,
      title: '🎓 STANFORD UNIVERSITY',
      category: 'hospital', // Using hospital icon as academic building
      description: 'Test marker at Stanford University',
      iconId: MarkerIcons.hospital,
      customColor: Colors.red,
      priority: 9,
      size: 1.5, // Medium-large size
      metadata: {'type': 'test', 'location': 'university', 'size': 1.5},
    ),
    const StaticMarker(
      id: 'palo_alto_test',
      latitude: 37.4419, // Downtown Palo Alto
      longitude: -122.1430,
      title: '🏪 DOWNTOWN PALO ALTO',
      category: 'restaurant',
      description: 'Test marker in downtown Palo Alto',
      iconId: MarkerIcons.restaurant,
      customColor: Colors.orange,
      priority: 8,
      metadata: {'type': 'test', 'location': 'downtown'},
    ),
    const StaticMarker(
      id: 'apple_park_test',
      latitude: 37.3349, // Apple Park, Cupertino
      longitude: -122.0090,
      title: '🍎 APPLE PARK',
      category: 'hotel', // Using hotel icon for office building
      description: 'Test marker at Apple Park campus',
      iconId: MarkerIcons.hotel,
      customColor: Colors.grey,
      priority: 9,
      size: 2.0, // Large size for major landmark
      metadata: {'type': 'test', 'location': 'office', 'size': 2.0},
    ),
    const StaticMarker(
      id: 'san_jose_test',
      latitude: 37.3382, // Downtown San Jose
      longitude: -121.8863,
      title: '🏙️ SAN JOSE DOWNTOWN',
      category: 'petrol_station',
      description: 'Test marker in downtown San Jose',
      iconId: MarkerIcons.petrolStation,
      customColor: Colors.cyan,
      priority: 7,
      size: 0.8, // Slightly smaller size
      metadata: {'type': 'test', 'location': 'downtown', 'size': 0.8},
    ),
  ];

  @override
  void initState() {
    super.initState();
    initialize();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initialize() async {
    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    // Reduce Mapbox SDK logging (optional)
    // Note: This might not affect all Mapbox logs as some are at native level

    _navigationOption = MapBoxOptions(
      initialLatitude: 37.4220,
      initialLongitude: -122.0841,
      zoom: 15.0,
      tilt: 0.0,
      bearing: 0.0,
      enableRefresh: true,
      alternatives: true,
      voiceInstructionsEnabled: true,
      bannerInstructionsEnabled: true,
      allowsUTurnAtWayPoints: true,
      mode: MapBoxNavigationMode.drivingWithTraffic,
      units: VoiceUnits.metric,
      simulateRoute: true,
      language: "en",
    );
    MapBoxNavigation.instance.registerRouteEventListener(_onRouteEvent);
    
    // Register full-screen event listener for marker taps during full-screen navigation
    MapBoxNavigation.instance.registerFullScreenEventListener(_onFullScreenEvent);
    
    // Register static marker tap listener
    MapBoxNavigation.instance.registerStaticMarkerTapListener(_onMarkerTap);

    String? platformVersion;
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      platformVersion = await MapBoxNavigation.instance.getPlatformVersion();
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }

    setState(() {
      _platformVersion = platformVersion;
    });
  }

  // Build custom popup for markers
  Widget _buildMarkerPopup(StaticMarker marker, BuildContext context) {
    return Container(
      constraints: const BoxConstraints(
        maxWidth: 280,
        maxHeight: 200, // Limit height to prevent overflow
      ),
      child: SingleChildScrollView( // Make content scrollable if too tall
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          // Header with icon and title
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (marker.customColor ?? Colors.blue).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getIconForCategory(marker.category),
                  color: marker.customColor ?? Colors.blue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      marker.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      marker.category.replaceAll('_', ' ').toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        color: marker.customColor ?? Colors.blue,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          if (marker.description != null) ...[
            const SizedBox(height: 8),
            Text(
              marker.description!,
              style: const TextStyle(fontSize: 14),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          
          // Show some metadata if available (condensed)
          if (marker.metadata?.isNotEmpty == true) ...[
            const SizedBox(height: 6),
            ...marker.metadata!.entries.take(1).map((entry) => // Show only 1 to save space
              Text(
                '${entry.key}: ${entry.value}',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
          
          const SizedBox(height: 8),
          
          // Action buttons (compact)
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _navigateToMarker(marker),
                  icon: const Icon(Icons.directions, size: 14),
                  label: const Text('Navigate', style: TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: marker.customColor ?? Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              OutlinedButton.icon(
                onPressed: () => _showMarkerDetails(marker),
                icon: const Icon(Icons.info_outline, size: 14),
                label: const Text('Details', style: TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
    );
  }

  IconData _getIconForCategory(String category) {
    switch (category) {
      case 'restaurant':
        return Icons.restaurant;
      case 'petrol_station':
        return Icons.local_gas_station;
      case 'hotel':
        return Icons.hotel;
      case 'hospital':
        return Icons.local_hospital;
      case 'scenic':
        return Icons.landscape;
      default:
        return Icons.place;
    }
  }

  void _navigateToMarker(StaticMarker marker) {
    setState(() {
      _lastTappedMarker = 'Navigate to: ${marker.title}';
    });
    
    // Hide the popup
    MarkerPopupManager().hidePopup();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Navigation to ${marker.title} would start here'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // Test popup functionality
  void _testPopup() {
    if (_sampleMarkers.isNotEmpty) {
      final marker = _sampleMarkers.first;
      
      setState(() {
        _lastTappedMarker = 'Test popup: ${marker.title}';
      });
      
      // Show popup manually for testing
      _showFlutterPopupForMarker(marker);
    }
  }

  // Show Flutter popup for a marker (with fallback positioning)
  void _showFlutterPopupForMarker(StaticMarker marker) {
    // For now, just use a fixed position since platform implementation isn't ready
    // TODO: Implement getMarkerScreenPosition in Android/iOS platform code
    const screenPosition = Offset(200, 150);
    
    // Show the Flutter popup overlay
    MarkerPopupManager().showPopupForMarker(
      marker,
      screenPosition: screenPosition,
    );
  }

  // Handle static marker taps from platform (when user clicks markers on map)
  void _onMarkerTap(StaticMarker marker) {
    setState(() {
      _lastTappedMarker = '${marker.title} (${marker.category})';
    });
    
    if (!mounted) return;
    
    // Show Flutter popup overlays for embedded navigation only
    // Full-screen navigation marker taps are handled by _handleFullScreenMarkerTapEvent
    // which is triggered by platform-specific event forwarding
    if (!_isFullScreenNavigation) {
      _showFlutterPopupForMarker(marker);
    }
    // Note: Full-screen navigation marker taps are handled by _handleFullScreenMarkerTapEvent
    // which is triggered by platform-specific event forwarding (Android: MarkerPopupBinder, iOS: StaticMarkerManager)
  }

  // Show a persistent notification overlay for full-screen navigation
  void _showPersistentMarkerNotification(StaticMarker marker) {
    print('🔔 _showPersistentMarkerNotification called for: ${marker.title}');
    print('🔔 Context: $context');
    print('🔔 Mounted: $mounted');
    
    try {
      // Use a more prominent SnackBar that's harder to miss
      ScaffoldMessenger.of(context).clearSnackBars(); // Clear any existing ones
      print('🔔 Cleared existing snackbars');
      
      final snackBar = SnackBar(
        content: Container(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.location_on, color: Colors.white, size: 24),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      marker.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              if (marker.description != null) ...[
                const SizedBox(height: 4),
                Text(
                  marker.description!,
                  style: const TextStyle(fontSize: 14, color: Colors.white),
                ),
              ],
              const SizedBox(height: 4),
              Text(
                'Category: ${marker.category}',
                style: const TextStyle(fontSize: 12, color: Colors.white70),
              ),
            ],
          ),
        ),
        backgroundColor: Colors.blue.shade800,
        duration: const Duration(seconds: 8), // Show longer for full-screen
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        action: SnackBarAction(
          label: 'Details',
          textColor: Colors.white,
          onPressed: () {
            _showMarkerDetails(marker);
          },
        ),
      );
      
      print('🔔 About to show snackbar');
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
      print('🔔 SnackBar shown successfully');
      
    } catch (e) {
      print('❌ Error in _showPersistentMarkerNotification: $e');
      // Fallback - simple notification
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Marker tapped: ${marker.title}'),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  // Show detailed marker information
  void _showMarkerDetails(StaticMarker marker) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
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
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Here you could add the marker as a waypoint
                _addMarkerAsWaypoint(marker);
              },
              child: const Text('Navigate To'),
            ),
          ],
        );
      },
    );
  }

  // Add marker as a waypoint (example functionality)
  void _addMarkerAsWaypoint(StaticMarker marker) {
    final waypoint = WayPoint(
      name: marker.title,
      latitude: marker.latitude,
      longitude: marker.longitude,
      isSilent: false,
    );
    
    MapBoxNavigation.instance.addWayPoints(wayPoints: [waypoint]);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added ${marker.title} to route'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // Add static markers to the map
  Future<void> _addStaticMarkers() async {
    try {
      final success = await MapBoxNavigation.instance.addStaticMarkers(
        markers: _sampleMarkers,
        configuration: MarkerConfiguration(
          maxDistanceFromRoute: 10.0, // 10km from route
          enableClustering: true,
          onMarkerTap: _onMarkerTap,
          // Enable Flutter popup overlays
          popupBuilder: _buildMarkerPopup,
          popupDuration: const Duration(seconds: 6),
          popupOffset: const Offset(0, -80),
          hidePopupOnTapOutside: true,
        ),
      );
      
      if (success == true) {
        setState(() {
          _markersAdded = true;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Static markers added successfully!'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding markers: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Remove static markers from the map
  Future<void> _removeStaticMarkers() async {
    try {
      final success = await MapBoxNavigation.instance.clearAllStaticMarkers();
      
      if (success == true) {
        setState(() {
          _markersAdded = false;
          _lastTappedMarker = null;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Static markers removed'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error removing markers: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapbox Navigation Demo'),
      ),
      body: Center(
        child: Column(children: <Widget>[
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(
                    height: 10,
                  ),
                  Text('Running on: $_platformVersion\n'),
                  
                  // Static Markers Section
                  Container(
                    color: Colors.blue,
                    width: double.infinity,
                    child: const Padding(
                      padding: EdgeInsets.all(10),
                      child: (Text(
                        "Static Markers",
                        style: TextStyle(color: Colors.white),
                        textAlign: TextAlign.center,
                      )),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Wrap(
                      spacing: 8.0,
                      runSpacing: 8.0,
                      alignment: WrapAlignment.center,
                      children: [
                        ElevatedButton(
                          onPressed: _markersAdded ? null : _addStaticMarkers,
                          child: const Text("Add Static Markers"),
                        ),
                        ElevatedButton(
                          onPressed: _markersAdded ? _removeStaticMarkers : null,
                          child: const Text("Remove Markers"),
                        ),
                        ElevatedButton(
                          onPressed: _markersAdded ? _testPopup : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text("Test Popup"),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const PopupExamplePage(),
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepOrange,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text("Advanced Popup Demo"),
                        ),
                        ElevatedButton(
                          onPressed: _controller != null && !_markersAdded ? _addMarkersToEmbeddedView : null,
                          child: const Text("Add to Embedded View"),
                        ),
                      ],
                    ),
                  ),
                  if (_lastTappedMarker != null)
                    Container(
                      margin: const EdgeInsets.all(8.0),
                      padding: const EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        border: Border.all(color: Colors.green),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Last tapped: $_lastTappedMarker',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  
                  Container(
                    color: Colors.grey,
                    width: double.infinity,
                    child: const Padding(
                      padding: EdgeInsets.all(10),
                      child: (Text(
                        "Full Screen Navigation",
                        style: TextStyle(color: Colors.white),
                        textAlign: TextAlign.center,
                      )),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Wrap(
                      spacing: 8.0, // gap between adjacent buttons
                      runSpacing: 8.0, // gap between lines
                      alignment: WrapAlignment.center,
                      children: [
                        ElevatedButton(
                          child: const Text("Start A to B (Metric)"),
                          onPressed: () async {
                            setState(() {
                              _isNavigating = true; // Set navigation state immediately
                              _isFullScreenNavigation = true; // Track full-screen mode
                            });
                            
                            var wayPoints = <WayPoint>[];
                            wayPoints.add(_home);
                            wayPoints.add(_store);
                            var opt = MapBoxOptions.from(_navigationOption);
                            opt.simulateRoute = true;
                            opt.voiceInstructionsEnabled = true;
                            opt.bannerInstructionsEnabled = true;
                            opt.units = VoiceUnits.metric;
                            await MapBoxNavigation.instance
                                .startNavigation(wayPoints: wayPoints, options: opt);
                            // Auto-add markers to this navigation view
                            await _addStaticMarkers();
                          },
                        ),
                        ElevatedButton(
                          child: const Text("Start A to B (Imperial)"),
                          onPressed: () async {
                            setState(() {
                              _isNavigating = true; // Set navigation state immediately
                              _isFullScreenNavigation = true; // Track full-screen mode
                            });
                            
                            var wayPoints = <WayPoint>[];
                            wayPoints.add(_home);
                            wayPoints.add(_store);
                            var opt = MapBoxOptions.from(_navigationOption);
                            opt.simulateRoute = true;
                            opt.voiceInstructionsEnabled = true;
                            opt.bannerInstructionsEnabled = true;
                            opt.units = VoiceUnits.imperial;
                            await MapBoxNavigation.instance
                                .startNavigation(wayPoints: wayPoints, options: opt);
                            // Auto-add markers to this navigation view
                            await _addStaticMarkers();
                          },
                        ),
                        ElevatedButton(
                          child: const Text("Start Multi Stop"),
                          onPressed: () async {
                            _isMultipleStop = true;
                            setState(() {
                              _isNavigating = true; // Set navigation state immediately
                              _isFullScreenNavigation = true; // Track full-screen mode
                            });
                            
                            var wayPoints = <WayPoint>[];
                            wayPoints.add(_origin);
                            wayPoints.add(_stop1);
                            wayPoints.add(_stop2);
                            wayPoints.add(_stop3);
                            wayPoints.add(_destination);

                            await MapBoxNavigation.instance.startNavigation(
                                wayPoints: wayPoints,
                                options: MapBoxOptions(
                                    mode: MapBoxNavigationMode.driving,
                                    simulateRoute: true,
                                    language: "en",
                                    allowsUTurnAtWayPoints: true,
                                    units: VoiceUnits.metric));
                            // Auto-add markers to this navigation view
                            await _addStaticMarkers();
                            //after 10 seconds add a new stop
                            await Future.delayed(const Duration(seconds: 10));
                            var stop = WayPoint(
                                name: "Gas Station",
                                latitude: 38.911176544398,
                                longitude: -77.04014366543564,
                                isSilent: false);
                            MapBoxNavigation.instance
                                .addWayPoints(wayPoints: [stop]);
                          },
                        ),
                        ElevatedButton(
                          child: const Text("Flutter Full-Screen"),
                          onPressed: () async {
                            setState(() {
                              _isNavigating = true; // Set navigation state immediately
                              _isFullScreenNavigation = true; // Track full-screen mode
                            });
                            
                            var wayPoints = <WayPoint>[];
                            wayPoints.add(_home);
                            wayPoints.add(_store);
                            
                            // Add markers before starting navigation
                            await _addStaticMarkers();
                            
                            // Set flag to indicate we're using Flutter-styled navigation with native overlays
                            // _justFinishedFlutterNavigation = true;
                            
                            // Use the new Drop-in UI approach (recommended)
                            await MapBoxNavigation.instance.startFlutterStyledNavigation(
                              wayPoints: wayPoints,
                              options: MapBoxOptions(
                                simulateRoute: true,
                                voiceInstructionsEnabled: true,
                                bannerInstructionsEnabled: true,
                                units: VoiceUnits.metric,
                              ),
                              showDebugOverlay: true,
                            );
                          },
                        ),
                        ElevatedButton(
                          child: const Text("Free Drive"),
                          onPressed: () async {
                            setState(() {
                              _isNavigating = true; // Set navigation state immediately for free drive
                              _isFullScreenNavigation = true; // Track full-screen mode
                            });
                            
                            await MapBoxNavigation.instance.startFreeDrive();
                            // Auto-add markers to free drive view
                            await _addStaticMarkers();
                          },
                        ),
                      ],
                    ),
                  ),
                  Container(
                    color: Colors.grey,
                    width: double.infinity,
                    child: const Padding(
                      padding: EdgeInsets.all(10),
                      child: (Text(
                        "Embedded Navigation",
                        style: TextStyle(color: Colors.white),
                        textAlign: TextAlign.center,
                      )),
                    ),
                  ),
                  Wrap(
                    spacing: 8.0,
                    runSpacing: 8.0,
                    alignment: WrapAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: _isNavigating
                            ? null
                            : () {
                                if (_routeBuilt) {
                                  _controller?.clearRoute();
                                } else {
                                  var wayPoints = <WayPoint>[];
                                  wayPoints.add(_home);
                                  wayPoints.add(_store);
                                  _isMultipleStop = wayPoints.length > 2;
                                  var opt = MapBoxOptions.from(_navigationOption);
                                  opt.units = VoiceUnits.metric;
                                  _controller?.buildRoute(
                                      wayPoints: wayPoints,
                                      options: opt);
                                }
                              },
                        child: Text(_routeBuilt && !_isNavigating
                            ? "Clear Route"
                            : "Build Route"),
                      ),
                      ElevatedButton(
                        onPressed: _routeBuilt && !_isNavigating
                            ? () async {
                                var opt = MapBoxOptions.from(_navigationOption);
                                opt.units = VoiceUnits.metric;
                                _controller?.startNavigation(options: opt);
                                // Auto-add markers to embedded navigation
                                await _addMarkersToEmbeddedView();
                              }
                            : null,
                        child: const Text("Start Embedded"),
                      ),
                      ElevatedButton(
                        onPressed: _isNavigating
                            ? () {
                                MapBoxNavigation.instance.finishNavigation();
                              }
                            : null,
                        child: const Text("Stop Navigation"),
                      ),
                      ElevatedButton(
                        onPressed: _inFreeDrive
                            ? null
                            : () async {
                                _inFreeDrive =
                                    await _controller?.startFreeDrive() ?? false;
                                // Auto-add markers to embedded free drive
                                await _addMarkersToEmbeddedView();
                              },
                        child: const Text("Free Drive"),
                      ),
                    ],
                  ),
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(10),
                      child: Text(
                        "Long-Press Embedded Map to Set Destination",
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  Container(
                    color: Colors.grey,
                    width: double.infinity,
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: (Text(
                        _instruction == null
                            ? "Banner Instruction Here"
                            : _instruction!,
                        style: const TextStyle(color: Colors.white),
                        textAlign: TextAlign.center,
                      )),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(
                        left: 20.0, right: 20, top: 20, bottom: 10),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            const Text("Duration Remaining: "),
                            Text(_durationRemaining != null
                                ? "${(_durationRemaining! / 60).toStringAsFixed(0)} minutes"
                                : "---")
                          ],
                        ),
                        Row(
                          children: <Widget>[
                            const Text("Distance Remaining: "),
                            Text(_distanceRemaining != null
                                ? "${(_distanceRemaining! * 0.000621371).toStringAsFixed(1)} miles"
                                : "---")
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Divider()
                ],
              ),
            ),
          ),
          SizedBox(
            height: 300,
            child: Container(
              color: Colors.grey,
              child: MapBoxNavigationViewWithPopups(
                  options: _navigationOption,
                  onRouteEvent: _onRouteEvent,
                  markerConfiguration: MarkerConfiguration(
                    popupBuilder: _buildMarkerPopup,
                    popupDuration: const Duration(seconds: 6),
                    popupOffset: const Offset(0, -80),
                    hidePopupOnTapOutside: true,
                    onMarkerTap: _onMarkerTap,
                    enableClustering: true,
                    maxDistanceFromRoute: 10.0,
                  ),
                  initialViewport: MapViewport(
                    center: LatLng(_navigationOption.initialLatitude!, _navigationOption.initialLongitude!),
                    zoomLevel: _navigationOption.zoom!,
                    size: const Size(400, 300), // Will be updated by LayoutBuilder
                  ),
                  enableCoordinateConversion: true,
                  onCreated:
                      (MapBoxNavigationViewController controller) async {
                    _controller = controller;
                    controller.initialize();
                    
                    // Automatically add markers to the embedded view after a short delay
                    await Future.delayed(const Duration(seconds: 2));
                    if (!_markersAdded && mounted) {
                      await _addMarkersToEmbeddedView();
                    }
                  }),
            ),
          )
        ]),
      ),
    );
  }

  Future<void> _onRouteEvent(e) async {
    _distanceRemaining = await MapBoxNavigation.instance.getDistanceRemaining();
    _durationRemaining = await MapBoxNavigation.instance.getDurationRemaining();

    switch (e.eventType) {
      case MapBoxEvent.progress_change:
        var progressEvent = e.data as RouteProgressEvent;
        if (progressEvent.currentStepInstruction != null) {
          _instruction = progressEvent.currentStepInstruction;
        }
        break;
      case MapBoxEvent.route_building:
      case MapBoxEvent.route_built:
        setState(() {
          _routeBuilt = true;
        });
        break;
      case MapBoxEvent.route_build_failed:
        setState(() {
          _routeBuilt = false;
        });
        break;
      case MapBoxEvent.navigation_running:
        setState(() {
          _isNavigating = true;
        });
        break;
      case MapBoxEvent.on_arrival:
        if (!_isMultipleStop) {
          await Future.delayed(const Duration(seconds: 3));
          await _controller?.finishNavigation();
        } else {}
        break;
      case MapBoxEvent.navigation_finished:
      case MapBoxEvent.navigation_cancelled:
        setState(() {
          _routeBuilt = false;
          _isNavigating = false;
          _isFullScreenNavigation = false; // Reset full-screen mode tracking
        });
        break;
      case MapBoxEvent.marker_tap_fullscreen:
        // Handle marker tap events from full-screen navigation
        _handleFullScreenMarkerTapEvent(e);
        break;
      default:
        break;
    }
    setState(() {});
  }

  void _onFullScreenEvent(FullScreenEvent event) {
    print('🎯 Full-screen event received: ${event.type}');
    switch (event.type) {
      case 'marker_tap':
        if (event.marker != null) {
          print('🎯 Full-screen marker tap: ${event.marker!.title}');
          print('🎯 Using native notification for full-screen navigation');
          // For full-screen navigation, use native platform notifications since
          // Flutter ScaffoldMessenger isn't visible during native navigation
          _showNativeMarkerNotification(event.marker!);
        } else {
          print('⚠️ Full-screen marker tap event received but marker is null');
          // Fallback notification
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Marker tapped in full-screen navigation'),
              duration: Duration(seconds: 3),
            ),
          );
        }
        break;
      default:
        print('🎯 Unknown full-screen event type: ${event.type}');
        break;
    }
  }

  void _showNativeMarkerNotification(StaticMarker marker) {
    // For full-screen navigation, the native platform (Android/iOS) shows
    // the notification directly. Flutter events are mainly for logging/consistency.
    print('🔔 Native notification should be shown by platform for: ${marker.title}');
    print('🔔 Platform (Android: Toast, iOS: Alert) handles the UI during full-screen navigation');
    
    // The actual notification is shown by the platform (see MarkerPopupBinder.showNativeToast)
    // This method exists mainly for consistent logging and potential future enhancements
  }

  void _handleFullScreenMarkerTapEvent(dynamic eventData) {
    try {
      // Parse the marker data from the route event
      // The data comes as a JSON string from Android
      final String jsonString = eventData.data as String;
      final Map<String, dynamic> data = json.decode(jsonString);
      
      // Reconstruct the marker from the flattened data
      final marker = StaticMarker(
        id: data['marker_id'] as String,
        latitude: data['marker_latitude'] as double,
        longitude: data['marker_longitude'] as double,
        title: data['marker_title'] as String,
        category: data['marker_category'] as String,
        description: data['marker_description'] as String?,
        iconId: data['marker_iconId'] as String?,
        customColor: data['marker_customColor'] != null 
            ? Color(data['marker_customColor'] as int) 
            : null,
        priority: data['marker_priority'] as int?,
        size: data['marker_size'] as double?,
        isVisible: data['marker_isVisible'] as bool? ?? true,
        metadata: data['marker_metadata'] != null 
            ? Map<String, dynamic>.from(data['marker_metadata'] as Map)
            : null,
      );
      
      // Show the persistent notification for this marker
      _showPersistentMarkerNotification(marker);
      
    } catch (e) {
      debugPrint('Error handling full-screen marker tap: $e');
      // Fallback - show a generic notification
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Marker tapped in full-screen navigation'),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _addMarkersToEmbeddedView() async {
    try {
      // Use a simpler configuration since MapBoxNavigationViewWithPopups handles popups
      final success = await MapBoxNavigation.instance.addStaticMarkers(
        markers: _sampleMarkers,
        configuration: MarkerConfiguration(
          maxDistanceFromRoute: 10.0,
          enableClustering: true,
          onMarkerTap: _onMarkerTap, // This will trigger our Flutter popup logic
        ),
      );

      if (success == true) {
        setState(() {
          _markersAdded = true;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Static markers added to embedded view successfully!'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to add static markers to embedded view.'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding markers: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
