import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mapbox_navigation/flutter_mapbox_navigation.dart';

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
      name: "Way Point 1",
      latitude: 38.9111117447887,
      longitude: -77.04012393951416,
      isSilent: true);
  final _stop1 = WayPoint(
      name: "Way Point 2",
      latitude: 38.91113678979344,
      longitude: -77.03847169876099,
      isSilent: true);
  final _stop2 = WayPoint(
      name: "Way Point 3",
      latitude: 38.91040213277608,
      longitude: -77.03848242759705,
      isSilent: false);
  final _stop3 = WayPoint(
      name: "Way Point 4",
      latitude: 38.909650771013034,
      longitude: -77.03850388526917,
      isSilent: true);
  final _destination = WayPoint(
      name: "Way Point 5",
      latitude: 38.90894949285854,
      longitude: -77.03651905059814,
      isSilent: false);

  final _home = WayPoint(
      name: "Home",
      latitude: 37.77440680146262,
      longitude: -122.43539772352648,
      isSilent: false);

  final _store = WayPoint(
      name: "Store",
      latitude: 37.76556957793795,
      longitude: -122.42409811526268,
      isSilent: false);

  bool _isMultipleStop = false;
  double? _distanceRemaining, _durationRemaining;
  MapBoxNavigationViewController? _controller;
  bool _routeBuilt = false;
  bool _isNavigating = false;
  bool _inFreeDrive = false;
  late MapBoxOptions _navigationOption;
  bool _isMetric = true;
  
  // Static marker state
  bool _markersAdded = false;
  String? _lastTappedMarker;

  // Sample static markers
  final List<StaticMarker> _sampleMarkers = [
    StaticMarker(
      id: 'scenic_1',
      latitude: 37.7749,
      longitude: -122.4194,
      title: 'Golden Gate Bridge',
      category: 'scenic',
      description: 'Iconic suspension bridge spanning the Golden Gate strait',
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
      description: '24/7 fuel station with convenience store',
      iconId: MarkerIcons.petrolStation,
      customColor: Colors.green,
      priority: 3,
      metadata: {'price': 1.85, 'brand': 'Shell', 'open_24h': true},
    ),
    StaticMarker(
      id: 'restaurant_1',
      latitude: 37.7649,
      longitude: -122.4294,
      title: 'Fisherman\'s Wharf Restaurant',
      category: 'restaurant',
      description: 'Fresh seafood with waterfront views',
      iconId: MarkerIcons.restaurant,
      customColor: Colors.red,
      priority: 4,
      metadata: {'cuisine': 'seafood', 'price_range': r'$$$', 'rating': 4.2},
    ),
    StaticMarker(
      id: 'speed_camera_1',
      latitude: 37.7549,
      longitude: -122.4394,
      title: 'Speed Camera',
      category: 'speed_camera',
      description: 'Speed enforcement camera - 25 mph limit',
      iconId: MarkerIcons.speedCamera,
      customColor: Colors.red,
      priority: 2,
      metadata: {'speed_limit': 25, 'enforcement': 'active'},
    ),
    StaticMarker(
      id: 'park_1',
      latitude: 37.7694,
      longitude: -122.4094,
      title: 'Alcatraz Island',
      category: 'park',
      description: 'Historic federal prison and national park',
      iconId: MarkerIcons.park,
      customColor: Colors.green,
      priority: 4,
      metadata: {'type': 'national_park', 'tours_available': true},
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

    _navigationOption = MapBoxOptions(
      initialLatitude: 36.1175275,
      initialLongitude: -115.1839524,
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
    MapBoxNavigation.instance.registerRouteEventListener(_onEmbeddedRouteEvent);
    
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

  // Handle static marker taps
  void _onMarkerTap(StaticMarker marker) {
    setState(() {
      _lastTappedMarker = '${marker.title} (${marker.category})';
    });
    
    // Show a snackbar with marker info
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Tapped: ${marker.title}\n${marker.description ?? ''}'),
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'More Info',
          onPressed: () {
            _showMarkerDetails(marker);
          },
        ),
      ),
    );
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
        ),
      );
      
      if (success == true) {
        setState(() {
          _markersAdded = true;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Static markers added successfully!'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error adding markers: $e'),
          backgroundColor: Colors.red,
        ),
      );
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
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Static markers removed'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error removing markers: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Plugin example app'),
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
                          },
                        ),
                        ElevatedButton(
                          child: const Text("Start A to B (Imperial)"),
                          onPressed: () async {
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
                          },
                        ),
                        ElevatedButton(
                          child: const Text("Start Multi Stop"),
                          onPressed: () async {
                            _isMultipleStop = true;
                            var wayPoints = <WayPoint>[];
                            wayPoints.add(_origin);
                            wayPoints.add(_stop1);
                            wayPoints.add(_stop2);
                            wayPoints.add(_stop3);
                            wayPoints.add(_destination);

                            MapBoxNavigation.instance.startNavigation(
                                wayPoints: wayPoints,
                                options: MapBoxOptions(
                                    mode: MapBoxNavigationMode.driving,
                                    simulateRoute: true,
                                    language: "en",
                                    allowsUTurnAtWayPoints: true,
                                    units: VoiceUnits.metric));
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
                          child: const Text("Free Drive"),
                          onPressed: () async {
                            await MapBoxNavigation.instance.startFreeDrive();
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
                            ? () {
                                var opt = MapBoxOptions.from(_navigationOption);
                                opt.units = VoiceUnits.metric;
                                _controller?.startNavigation(options: opt);
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
              child: MapBoxNavigationView(
                  options: _navigationOption,
                  onRouteEvent: _onEmbeddedRouteEvent,
                  onCreated:
                      (MapBoxNavigationViewController controller) async {
                    _controller = controller;
                    controller.initialize();
                  }),
            ),
          )
        ]),
      ),
    );
  }

  Future<void> _onEmbeddedRouteEvent(e) async {
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
        });
        break;
      default:
        break;
    }
    setState(() {});
  }

  void _onMapReady() {
    _navigationOption = MapBoxOptions(
      initialLatitude: 36.1175275,
      initialLongitude: -115.1839524,
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
  }

  void _startNavigation() async {
    var wayPoints = <WayPoint>[];
    wayPoints.add(_origin);
    wayPoints.add(_destination);

    await MapBoxNavigation.instance.startNavigation(
      wayPoints: wayPoints,
      options: MapBoxOptions(
        initialLatitude: _origin.latitude!,
        initialLongitude: _origin.longitude!,
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
      ),
    );
  }

  void _startFreeDrive() async {
    await MapBoxNavigation.instance.startFreeDrive(
      options: MapBoxOptions(
        initialLatitude: _origin.latitude!,
        initialLongitude: _origin.longitude!,
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
      ),
    );
  }

  void _toggleMetric() {
    setState(() {
      _isMetric = !_isMetric;
      _navigationOption = MapBoxOptions(
        initialLatitude: _navigationOption.initialLatitude,
        initialLongitude: _navigationOption.initialLongitude,
        zoom: _navigationOption.zoom,
        tilt: _navigationOption.tilt,
        bearing: _navigationOption.bearing,
        enableRefresh: _navigationOption.enableRefresh,
        alternatives: _navigationOption.alternatives,
        voiceInstructionsEnabled: _navigationOption.voiceInstructionsEnabled,
        bannerInstructionsEnabled: _navigationOption.bannerInstructionsEnabled,
        allowsUTurnAtWayPoints: _navigationOption.allowsUTurnAtWayPoints,
        mode: _navigationOption.mode,
        units: _isMetric ? VoiceUnits.metric : VoiceUnits.imperial,
        simulateRoute: _navigationOption.simulateRoute,
        language: _navigationOption.language,
      );
    });
  }
}
