/// Dynamic Markers Navigation Demo Screen
///
/// Demonstrates real-time tracking during full-screen turn-by-turn navigation:
/// - Dynamic markers visible during active navigation
/// - Simulated fleet vehicles moving alongside the route
/// - Smooth position animation during navigation
/// - Trail rendering during navigation
///
/// This demo showcases how dynamic markers work in a real navigation
/// scenario - useful for fleet tracking, delivery monitoring, etc.

import 'package:flutter/material.dart';
import 'package:flutter_mapbox_navigation/flutter_mapbox_navigation.dart';
import '../../core/constants.dart';
import '../../data/sample_waypoints.dart';
import '../../services/fake_position_generator.dart';
import '../../shared/widgets/status_bar.dart';

class DynamicMarkersNavigationScreen extends StatefulWidget {
  const DynamicMarkersNavigationScreen({super.key});

  @override
  State<DynamicMarkersNavigationScreen> createState() =>
      _DynamicMarkersNavigationScreenState();
}

class _DynamicMarkersNavigationScreenState
    extends State<DynamicMarkersNavigationScreen> {
  // ===========================================================================
  // STATE
  // ===========================================================================

  final _navigation = MapBoxNavigation.instance;

  // Configuration
  late MapBoxOptions _options;
  List<WayPoint> _waypoints = [];
  bool _simulateRoute = true;

  // Navigation state
  bool _isNavigating = false;
  bool _routeBuilt = false;

  // Progress state
  double? _distanceRemaining;
  double? _durationRemaining;
  String? _currentInstruction;
  String? _lastEventType;

  // Dynamic markers
  FakePositionGenerator? _positionGenerator;
  bool _markersAdded = false;
  int _updateCount = 0;

  // Event log (simple string entries for this demo)
  final List<_LogEntry> _logEntries = [];

  // ===========================================================================
  // LIFECYCLE
  // ===========================================================================

  @override
  void initState() {
    super.initState();
    _waypoints = List.from(SampleWaypoints.basicRoute);
    _initializeOptions();
    _registerEventListener();
    _setupPositionGenerator();
    _registerDynamicMarkerListener();
  }

  void _initializeOptions() {
    _options = MapBoxOptions(
      initialLatitude: _waypoints.first.latitude,
      initialLongitude: _waypoints.first.longitude,
      zoom: 14.0,
      voiceInstructionsEnabled: true,
      bannerInstructionsEnabled: true,
      units: VoiceUnits.metric,
      mode: MapBoxNavigationMode.drivingWithTraffic,
      simulateRoute: _simulateRoute,
      animateBuildRoute: true,
      longPressDestinationEnabled: false,
    );
  }

  void _setupPositionGenerator() {
    // Use the same area as the navigation route (San Francisco)
    final centerLat = _waypoints.first.latitude ?? MapDefaults.defaultLatitude;
    final centerLng = _waypoints.first.longitude ?? MapDefaults.defaultLongitude;

    final vehicles = [
      SimulatedVehicle(
        id: 'nav_vehicle_1',
        title: 'Delivery Truck #1',
        category: 'delivery',
        startLatitude: centerLat + 0.003,
        startLongitude: centerLng + 0.002,
        speed: 10.0,
        pattern: MovementPattern.circular,
      ),
      SimulatedVehicle(
        id: 'nav_vehicle_2',
        title: 'Service Van',
        category: 'vehicle',
        startLatitude: centerLat - 0.002,
        startLongitude: centerLng + 0.003,
        speed: 15.0,
        pattern: MovementPattern.figure8,
      ),
      SimulatedVehicle(
        id: 'nav_vehicle_3',
        title: 'Support Unit',
        category: 'emergency',
        startLatitude: centerLat + 0.001,
        startLongitude: centerLng - 0.002,
        speed: 20.0,
        pattern: MovementPattern.random,
      ),
    ];

    _positionGenerator = FakePositionGenerator(
      vehicles: vehicles,
      updateInterval: const Duration(seconds: 1),
      onPositionUpdate: _onPositionUpdate,
    );
  }

  Future<void> _registerEventListener() async {
    await _navigation.registerRouteEventListener(_onRouteEvent);
  }

  Future<void> _registerDynamicMarkerListener() async {
    try {
      await _navigation.registerDynamicMarkerEventListener(_onDynamicMarkerEvent);
    } catch (e) {
      // Event listener is optional - markers still work without it
      debugPrint('Dynamic marker event listener not available: $e');
    }
  }

  @override
  void dispose() {
    _positionGenerator?.dispose();
    _cleanupMarkers();
    super.dispose();
  }

  Future<void> _cleanupMarkers() async {
    await _navigation.clearAllDynamicMarkers();
  }

  // ===========================================================================
  // EVENT HANDLING
  // ===========================================================================

  void _onRouteEvent(RouteEvent event) {
    if (!mounted) return;

    final eventName = event.eventType.toString().split('.').last;
    setState(() {
      _lastEventType = eventName;
    });
    _addLogEntry('Nav: $eventName');

    switch (event.eventType) {
      case MapBoxEvent.route_building:
        setState(() => _routeBuilt = false);
        break;

      case MapBoxEvent.route_built:
        setState(() => _routeBuilt = true);
        break;

      case MapBoxEvent.route_build_failed:
      case MapBoxEvent.route_build_no_routes_found:
        setState(() => _routeBuilt = false);
        _showError('Failed to build route');
        break;

      case MapBoxEvent.navigation_running:
        setState(() => _isNavigating = true);
        // Start position updates when navigation starts
        _positionGenerator?.start();
        break;

      case MapBoxEvent.progress_change:
        if (event.data is RouteProgressEvent) {
          final progress = event.data as RouteProgressEvent;
          setState(() {
            _distanceRemaining = progress.distance;
            _durationRemaining = progress.duration;
            _currentInstruction = progress.currentStepInstruction;
          });
        }
        break;

      case MapBoxEvent.on_arrival:
        _showMessage('Arrived at destination!');
        break;

      case MapBoxEvent.navigation_finished:
      case MapBoxEvent.navigation_cancelled:
        setState(() {
          _isNavigating = false;
          _routeBuilt = false;
          _distanceRemaining = null;
          _durationRemaining = null;
          _currentInstruction = null;
        });
        // Stop position updates when navigation ends
        _positionGenerator?.stop();
        break;

      default:
        break;
    }
  }

  void _onPositionUpdate(PositionUpdate update) {
    if (!mounted) return;

    // Update the dynamic marker position
    _navigation.updateDynamicMarkerPosition(
      update: DynamicMarkerPositionUpdate(
        markerId: update.markerId,
        latitude: update.latitude,
        longitude: update.longitude,
        heading: update.heading,
        speed: update.speed,
        timestamp: update.timestamp,
      ),
    );

    setState(() => _updateCount++);
  }

  void _onDynamicMarkerEvent(DynamicMarker marker) {
    _addLogEntry('Marker: ${marker.id} - ${marker.state.name}', isMarker: true);
  }

  void _addLogEntry(String message, {bool isMarker = false}) {
    if (!mounted) return;
    setState(() {
      _logEntries.add(_LogEntry(
        timestamp: DateTime.now(),
        message: message,
        isMarker: isMarker,
      ));
      // Keep only last 100 entries
      if (_logEntries.length > 100) {
        _logEntries.removeAt(0);
      }
    });
  }

  // ===========================================================================
  // ACTIONS
  // ===========================================================================

  Future<void> _addDynamicMarkers() async {
    if (_positionGenerator == null || _markersAdded) return;

    final vehicleColors = <String, Color>{
      'nav_vehicle_1': const Color(0xFFFF9800), // Orange
      'nav_vehicle_2': const Color(0xFF2196F3), // Blue
      'nav_vehicle_3': const Color(0xFFF44336), // Red
    };

    final markers = _positionGenerator!.vehicles.map((vehicle) {
      return DynamicMarker(
        id: vehicle.id,
        latitude: vehicle.startLatitude,
        longitude: vehicle.startLongitude,
        title: vehicle.title,
        category: vehicle.category,
        customColor: vehicleColors[vehicle.id],
        showTrail: true,
        trailLength: 20,
      );
    }).toList();

    final success = await _navigation.addDynamicMarkers(markers: markers);

    if (success == true) {
      setState(() => _markersAdded = true);
      _addLogEntry('Added ${markers.length} dynamic markers');

      // Configure the dynamic marker system
      await _navigation.updateDynamicMarkerConfiguration(
        configuration: const DynamicMarkerConfiguration(
          animationDurationMs: 1000,
          enableAnimation: true,
          animateHeading: true,
          enableTrail: true,
          maxTrailPoints: 20,
          trailWidth: 3.0,
          trailGradient: true,
          staleThresholdMs: 5000,
          offlineThresholdMs: 15000,
        ),
      );
    } else {
      _showError('Failed to add dynamic markers');
    }
  }

  Future<void> _startNavigation() async {
    if (_waypoints.length < 2) {
      _showError('Need at least 2 waypoints');
      return;
    }

    // Add dynamic markers before starting navigation
    if (!_markersAdded) {
      await _addDynamicMarkers();
    }

    _initializeOptions();

    try {
      await _navigation.startNavigation(
        wayPoints: _waypoints,
        options: _options,
      );
    } catch (e) {
      _showError('Failed to start navigation: $e');
    }
  }

  Future<void> _finishNavigation() async {
    try {
      await _navigation.finishNavigation();
    } catch (e) {
      _showError('Failed to finish navigation: $e');
    }
  }

  Future<void> _clearMarkers() async {
    _positionGenerator?.stop();
    await _navigation.clearAllDynamicMarkers();
    setState(() {
      _markersAdded = false;
      _updateCount = 0;
    });
    _addLogEntry('Cleared all dynamic markers');
  }

  // ===========================================================================
  // UI HELPERS
  // ===========================================================================

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // ===========================================================================
  // BUILD
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Navigation + Dynamic Markers'),
        actions: [
          // Marker status indicator
          Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _markersAdded ? Colors.green : Colors.grey,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _markersAdded ? Icons.location_on : Icons.location_off,
                  size: 16,
                  color: Colors.white,
                ),
                const SizedBox(width: 4),
                Text(
                  '$_updateCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(UIConstants.defaultPadding),
        children: [
          // Status bar
          StatusBar(
            isNavigating: _isNavigating,
            routeBuilt: _routeBuilt,
            distanceRemaining: _distanceRemaining,
            durationRemaining: _durationRemaining,
            currentInstruction: _currentInstruction,
            lastEventType: _lastEventType,
          ),
          const SizedBox(height: 16),

          // Info card
          _buildInfoCard(),
          const SizedBox(height: 16),

          // Dynamic markers status card
          _buildMarkersCard(),
          const SizedBox(height: 16),

          // Options
          _buildOptionsCard(),
          const SizedBox(height: 16),

          // Action buttons
          _buildActionButtons(),
          const SizedBox(height: 16),

          // Event log
          _buildEventLog(),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(UIConstants.defaultPadding),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.blue.shade700),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Fleet Tracking Demo',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Start navigation to see 3 simulated vehicles moving '
                    'on the map during turn-by-turn navigation.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue.shade800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMarkersCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(UIConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.local_shipping, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Fleet Vehicles',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _markersAdded
                        ? Colors.green.shade100
                        : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _markersAdded ? 'Active' : 'Not Added',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color:
                          _markersAdded ? Colors.green.shade800 : Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildVehicleRow(
              'Delivery Truck #1',
              const Color(0xFFFF9800),
              'Circular pattern',
            ),
            _buildVehicleRow(
              'Service Van',
              const Color(0xFF2196F3),
              'Figure-8 pattern',
            ),
            _buildVehicleRow(
              'Support Unit',
              const Color(0xFFF44336),
              'Random movement',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleRow(String name, Color color, String pattern) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(name, style: const TextStyle(fontSize: 13)),
          ),
          Text(
            pattern,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(UIConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.settings, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Options',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              title: const Text('Simulate Route'),
              subtitle: const Text('Move along route automatically'),
              value: _simulateRoute,
              onChanged: _isNavigating
                  ? null
                  : (value) => setState(() => _simulateRoute = value),
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        // Pre-add markers button (optional)
        if (!_markersAdded)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _addDynamicMarkers,
              icon: const Icon(Icons.add_location_alt),
              label: const Text('Add Dynamic Markers'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        if (!_markersAdded) const SizedBox(height: 8),

        // Start navigation
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isNavigating ? null : _startNavigation,
            icon: const Icon(Icons.navigation),
            label: Text(_markersAdded
                ? 'Start Navigation'
                : 'Start Navigation (adds markers)'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 8),

        // Stop navigation
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _isNavigating ? _finishNavigation : null,
            icon: const Icon(Icons.stop),
            label: const Text('Stop Navigation'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              foregroundColor: Colors.red,
            ),
          ),
        ),
        const SizedBox(height: 8),

        // Clear markers
        SizedBox(
          width: double.infinity,
          child: TextButton.icon(
            onPressed: _markersAdded ? _clearMarkers : null,
            icon: const Icon(Icons.clear_all),
            label: const Text('Clear Dynamic Markers'),
          ),
        ),
      ],
    );
  }

  Widget _buildEventLog() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(UIConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.list_alt, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Event Log',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () => setState(() => _logEntries.clear()),
                  child: const Text('Clear'),
                ),
              ],
            ),
            const Divider(),
            SizedBox(
              height: 200,
              child: _logEntries.isEmpty
                  ? Center(
                      child: Text(
                        'No events yet',
                        style: TextStyle(color: Colors.grey.shade500),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _logEntries.length,
                      itemBuilder: (context, index) {
                        final entry = _logEntries[_logEntries.length - 1 - index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text(
                            '[${_formatTime(entry.timestamp)}] ${entry.message}',
                            style: TextStyle(
                              fontSize: 11,
                              fontFamily: 'monospace',
                              color: entry.isMarker
                                  ? Colors.blue.shade700
                                  : Colors.grey.shade700,
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}:'
        '${time.second.toString().padLeft(2, '0')}';
  }
}

/// Simple log entry for this demo screen
class _LogEntry {
  final DateTime timestamp;
  final String message;
  final bool isMarker;

  _LogEntry({
    required this.timestamp,
    required this.message,
    this.isMarker = false,
  });
}
