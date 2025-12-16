/// Dynamic Markers Demo Screen
///
/// Demonstrates real-time tracking of multiple moving entities:
/// - Device position (simulated center point)
/// - 3 simulated vehicles with different movement patterns
/// - Smooth position animation between updates
/// - Trail/breadcrumb rendering
/// - State management (tracking, stale, offline)
///
/// This demo showcases the dynamic marker system designed for
/// fleet tracking, delivery monitoring, and multiplayer scenarios.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_mapbox_navigation/flutter_mapbox_navigation.dart';
import '../../core/constants.dart';
import '../../services/fake_position_generator.dart';

class DynamicMarkersDemoScreen extends StatefulWidget {
  const DynamicMarkersDemoScreen({super.key});

  @override
  State<DynamicMarkersDemoScreen> createState() =>
      _DynamicMarkersDemoScreenState();
}

class _DynamicMarkersDemoScreenState extends State<DynamicMarkersDemoScreen> {
  // ===========================================================================
  // STATE
  // ===========================================================================

  final _navigation = MapBoxNavigation.instance;
  MapBoxNavigationViewController? _controller;

  // Configuration
  late MapBoxOptions _options;

  // Position generator for simulated vehicles
  FakePositionGenerator? _positionGenerator;
  bool _isTracking = false;
  bool _showTrails = true;
  int _updateCount = 0;

  // Simulated "device" position (center of the demo area)
  final double _deviceLatitude = MapDefaults.defaultLatitude;
  final double _deviceLongitude = MapDefaults.defaultLongitude;

  // Vehicle states for UI display
  final Map<String, _VehicleDisplayInfo> _vehicleInfo = {};

  // Event log entries
  final List<String> _eventLog = [];
  static const int _maxLogEntries = 50;

  // ===========================================================================
  // LIFECYCLE
  // ===========================================================================

  @override
  void initState() {
    super.initState();
    _initializeOptions();
    _setupPositionGenerator();
    _registerDynamicMarkerListener();
  }

  void _initializeOptions() {
    _options = MapBoxOptions(
      initialLatitude: _deviceLatitude,
      initialLongitude: _deviceLongitude,
      zoom: 14.0, // Closer zoom to see vehicle movements
      voiceInstructionsEnabled: false,
      bannerInstructionsEnabled: false,
      mode: MapBoxNavigationMode.drivingWithTraffic,
      units: VoiceUnits.metric,
      simulateRoute: false,
      animateBuildRoute: false,
      longPressDestinationEnabled: false,
    );
  }

  void _setupPositionGenerator() {
    // Vehicle colors
    const colorOrange = Color(0xFFFF9800);
    const colorBlue = Color(0xFF2196F3);
    const colorRed = Color(0xFFF44336);

    // Create 3 simulated vehicles with different characteristics
    final vehicles = [
      SimulatedVehicle(
        id: 'vehicle_1',
        title: 'Delivery Truck',
        category: 'delivery',
        startLatitude: _deviceLatitude + 0.002,
        startLongitude: _deviceLongitude + 0.002,
        speed: 12.0, // ~43 km/h
        pattern: MovementPattern.circular,
      ),
      SimulatedVehicle(
        id: 'vehicle_2',
        title: 'Service Van',
        category: 'vehicle',
        startLatitude: _deviceLatitude - 0.002,
        startLongitude: _deviceLongitude + 0.001,
        speed: 18.0, // ~65 km/h
        pattern: MovementPattern.figure8,
      ),
      SimulatedVehicle(
        id: 'vehicle_3',
        title: 'Emergency Response',
        category: 'emergency',
        startLatitude: _deviceLatitude + 0.001,
        startLongitude: _deviceLongitude - 0.003,
        speed: 25.0, // ~90 km/h
        pattern: MovementPattern.random,
      ),
    ];

    // Vehicle color mapping
    final vehicleColors = {
      'vehicle_1': colorOrange,
      'vehicle_2': colorBlue,
      'vehicle_3': colorRed,
    };

    // Initialize display info
    for (final vehicle in vehicles) {
      _vehicleInfo[vehicle.id] = _VehicleDisplayInfo(
        id: vehicle.id,
        title: vehicle.title,
        category: vehicle.category,
        color: vehicleColors[vehicle.id] ?? Colors.grey,
        latitude: vehicle.startLatitude,
        longitude: vehicle.startLongitude,
        speed: 0,
        heading: 0,
      );
    }

    _positionGenerator = FakePositionGenerator(
      vehicles: vehicles,
      updateInterval: const Duration(seconds: 1),
      onPositionUpdate: _onPositionUpdate,
    );
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
    _controller?.dispose();
    super.dispose();
  }

  // ===========================================================================
  // EVENT HANDLING
  // ===========================================================================

  void _onMapCreated(MapBoxNavigationViewController controller) {
    _controller = controller;
    controller.initialize();

    // Add initial dynamic markers after a short delay to ensure map is ready
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _addInitialMarkers();
      }
    });
  }

  void _onRouteEvent(RouteEvent event) {
    // We're not using navigation events in this demo,
    // but the callback is required by MapBoxNavigationView
  }

  void _onPositionUpdate(PositionUpdate update) {
    if (!mounted || !_isTracking) return;

    // Update the dynamic marker position via platform
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

    // Update UI state
    setState(() {
      _updateCount++;
      final info = _vehicleInfo[update.markerId];
      if (info != null) {
        _vehicleInfo[update.markerId] = info.copyWith(
          latitude: update.latitude,
          longitude: update.longitude,
          speed: update.speed,
          heading: update.heading,
        );
      }
    });
  }

  void _onDynamicMarkerEvent(DynamicMarker marker) {
    _addLogEntry('Marker event: ${marker.id} - ${marker.state.name}');
  }

  // ===========================================================================
  // ACTIONS
  // ===========================================================================

  Future<void> _addInitialMarkers() async {
    if (_positionGenerator == null) return;

    // Vehicle color mapping
    final vehicleColors = <String, Color>{
      'vehicle_1': const Color(0xFFFF9800), // Orange
      'vehicle_2': const Color(0xFF2196F3), // Blue
      'vehicle_3': const Color(0xFFF44336), // Red
    };

    // Create dynamic markers for each simulated vehicle
    final markers = _positionGenerator!.vehicles.map((vehicle) {
      return DynamicMarker(
        id: vehicle.id,
        latitude: vehicle.startLatitude,
        longitude: vehicle.startLongitude,
        title: vehicle.title,
        category: vehicle.category,
        customColor: vehicleColors[vehicle.id],
        showTrail: _showTrails,
        trailLength: 30,
      );
    }).toList();

    // Add all markers at once
    final success = await _navigation.addDynamicMarkers(markers: markers);

    if (success == true) {
      _addLogEntry('Added ${markers.length} dynamic markers');
    } else {
      _addLogEntry('Failed to add dynamic markers');
    }

    // Configure the dynamic marker system
    await _navigation.updateDynamicMarkerConfiguration(
      configuration: const DynamicMarkerConfiguration(
        animationDurationMs: 1000, // Match our update interval
        enableAnimation: true,
        animateHeading: true,
        enableTrail: true,
        maxTrailPoints: 30,
        trailWidth: 3.0,
        trailGradient: true,
        staleThresholdMs: 5000, // Mark stale after 5 seconds
        offlineThresholdMs: 15000, // Mark offline after 15 seconds
      ),
    );
  }

  void _startTracking() {
    if (_isTracking) return;

    _positionGenerator?.start();
    setState(() {
      _isTracking = true;
      _updateCount = 0;
    });
    _addLogEntry('Started tracking simulation');
  }

  void _stopTracking() {
    if (!_isTracking) return;

    _positionGenerator?.stop();
    setState(() => _isTracking = false);
    _addLogEntry('Stopped tracking simulation');
  }

  Future<void> _toggleTrails() async {
    setState(() => _showTrails = !_showTrails);

    // Update each marker's trail visibility
    for (final vehicle in _positionGenerator?.vehicles ?? []) {
      await _navigation.updateDynamicMarker(
        markerId: vehicle.id,
        showTrail: _showTrails,
      );
    }

    _addLogEntry('Trails ${_showTrails ? 'enabled' : 'disabled'}');
  }

  Future<void> _clearTrails() async {
    await _navigation.clearAllDynamicMarkerTrails();
    _addLogEntry('Cleared all trails');
  }

  Future<void> _clearAllMarkers() async {
    _stopTracking();
    await _navigation.clearAllDynamicMarkers();
    _addLogEntry('Cleared all dynamic markers');
  }

  void _addLogEntry(String message) {
    if (!mounted) return;
    setState(() {
      _eventLog.insert(0, '[${_formatTime(DateTime.now())}] $message');
      if (_eventLog.length > _maxLogEntries) {
        _eventLog.removeLast();
      }
    });
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}:'
        '${time.second.toString().padLeft(2, '0')}';
  }

  // ===========================================================================
  // BUILD
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dynamic Markers'),
        actions: [
          IconButton(
            icon: Icon(_showTrails ? Icons.timeline : Icons.timeline_outlined),
            onPressed: _toggleTrails,
            tooltip: 'Toggle Trails',
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: _clearTrails,
            tooltip: 'Clear Trails',
          ),
        ],
      ),
      body: Column(
        children: [
          // Map view
          Expanded(
            flex: 3,
            child: Stack(
              children: [
                MapBoxNavigationView(
                  options: _options,
                  onCreated: _onMapCreated,
                  onRouteEvent: _onRouteEvent,
                ),

                // Vehicle info overlay
                Positioned(
                  top: 8,
                  left: 8,
                  right: 8,
                  child: _buildVehicleCards(),
                ),

                // Update counter
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: _buildUpdateCounter(),
                ),
              ],
            ),
          ),

          // Control panel
          Container(
            color: Colors.white,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(UIConstants.defaultPadding),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildControlButtons(),
                    const SizedBox(height: 12),
                    _buildEventLog(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleCards() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _vehicleInfo.values.map((info) {
          return Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: info.color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      info.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      '${(info.speed * 3.6).toStringAsFixed(0)} km/h • '
                      '${info.heading.toStringAsFixed(0)}°',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildUpdateCounter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _isTracking ? Colors.green : Colors.grey,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _isTracking ? Icons.sensors : Icons.sensors_off,
            size: 16,
            color: Colors.white,
          ),
          const SizedBox(width: 4),
          Text(
            '$_updateCount updates',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _isTracking ? _stopTracking : _startTracking,
            icon: Icon(_isTracking ? Icons.stop : Icons.play_arrow),
            label: Text(_isTracking ? 'Stop Tracking' : 'Start Tracking'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _isTracking ? Colors.red : Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 8),
        OutlinedButton.icon(
          onPressed: _clearAllMarkers,
          icon: const Icon(Icons.clear_all),
          label: const Text('Clear'),
        ),
      ],
    );
  }

  Widget _buildEventLog() {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Event Log',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                GestureDetector(
                  onTap: () => setState(() => _eventLog.clear()),
                  child: Text(
                    'Clear',
                    style: TextStyle(
                      color: Colors.blue.shade700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _eventLog.length,
              itemBuilder: (context, index) {
                return Text(
                  _eventLog[index],
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade700,
                    fontFamily: 'monospace',
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Helper class to track vehicle display info
class _VehicleDisplayInfo {
  final String id;
  final String title;
  final String category;
  final Color color;
  final double latitude;
  final double longitude;
  final double speed;
  final double heading;

  _VehicleDisplayInfo({
    required this.id,
    required this.title,
    required this.category,
    required this.color,
    required this.latitude,
    required this.longitude,
    required this.speed,
    required this.heading,
  });

  _VehicleDisplayInfo copyWith({
    double? latitude,
    double? longitude,
    double? speed,
    double? heading,
  }) {
    return _VehicleDisplayInfo(
      id: id,
      title: title,
      category: category,
      color: color,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      speed: speed ?? this.speed,
      heading: heading ?? this.heading,
    );
  }
}
