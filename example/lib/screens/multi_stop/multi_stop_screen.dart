/// Multi-Stop Navigation Screen
///
/// Demonstrates navigation through multiple waypoints:
/// - Multiple waypoints (2-25+)
/// - Silent waypoints (isSilent: true) for route shaping
/// - Dynamic waypoint addition (addWayPoints())
/// - Arrival events at each waypoint
///
/// Platform notes:
/// - iOS: drivingWithTraffic mode limited to 3 waypoints
/// - Mapbox API recommends max 25 waypoints

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_mapbox_navigation/flutter_mapbox_navigation.dart';
import '../../core/constants.dart';
import '../../data/sample_waypoints.dart';
import '../../shared/widgets/status_bar.dart';
import '../../shared/widgets/event_log.dart';

class MultiStopScreen extends StatefulWidget {
  const MultiStopScreen({super.key});

  @override
  State<MultiStopScreen> createState() => _MultiStopScreenState();
}

class _MultiStopScreenState extends State<MultiStopScreen> {
  // ===========================================================================
  // STATE
  // ===========================================================================

  final _navigation = MapBoxNavigation.instance;

  // Waypoints
  List<WayPoint> _waypoints = [];

  // Configuration
  bool _simulateRoute = true;
  VoiceUnits _units = VoiceUnits.metric;
  MapBoxNavigationMode _mode = MapBoxNavigationMode.driving;

  // Navigation state
  bool _isNavigating = false;
  bool _routeBuilt = false;
  int _currentWaypointIndex = 0;

  // Progress
  double? _distanceRemaining;
  double? _durationRemaining;
  String? _currentInstruction;
  String? _lastEventType;

  // Event log
  final List<EventLogEntry> _eventLog = [];

  // ===========================================================================
  // LIFECYCLE
  // ===========================================================================

  @override
  void initState() {
    super.initState();
    _waypoints = List.from(SampleWaypoints.dcMonumentsTour);
    _registerEventListener();
  }

  Future<void> _registerEventListener() async {
    await _navigation.registerRouteEventListener(_onRouteEvent);
  }

  // ===========================================================================
  // EVENT HANDLING
  // ===========================================================================

  void _onRouteEvent(RouteEvent event) {
    if (!mounted) return;

    setState(() {
      _lastEventType = event.eventType.toString().split('.').last;
      _eventLog.add(event.toLogEntry());
    });

    switch (event.eventType) {
      case MapBoxEvent.route_built:
        setState(() => _routeBuilt = true);
        break;

      case MapBoxEvent.route_build_failed:
        setState(() => _routeBuilt = false);
        _showError('Failed to build route');
        break;

      case MapBoxEvent.navigation_running:
        setState(() => _isNavigating = true);
        break;

      case MapBoxEvent.progress_change:
        if (event.data is RouteProgressEvent) {
          final progress = event.data as RouteProgressEvent;
          setState(() {
            _distanceRemaining = progress.distance;
            _durationRemaining = progress.duration;
            _currentInstruction = progress.currentStepInstruction;
            if (progress.legIndex != null) {
              _currentWaypointIndex = progress.legIndex!;
            }
          });
        }
        break;

      case MapBoxEvent.on_arrival:
        _showMessage('Arrived at waypoint ${_currentWaypointIndex + 1}!');
        setState(() => _currentWaypointIndex++);
        break;

      case MapBoxEvent.navigation_finished:
      case MapBoxEvent.navigation_cancelled:
        setState(() {
          _isNavigating = false;
          _routeBuilt = false;
          _currentWaypointIndex = 0;
          _distanceRemaining = null;
          _durationRemaining = null;
          _currentInstruction = null;
        });
        break;

      default:
        break;
    }
  }

  // ===========================================================================
  // ACTIONS
  // ===========================================================================

  Future<void> _startNavigation() async {
    // Validate waypoints
    final validation = WayPoint.validateWaypointCount(_waypoints);
    if (!validation.isValid) {
      _showError(validation.warnings.isNotEmpty
          ? validation.warnings.first
          : 'Invalid waypoints');
      return;
    }

    // Show warnings if any
    for (final warning in validation.warnings) {
      _showWarning(warning);
    }

    // Check iOS limitation
    if (Platform.isIOS &&
        _mode == MapBoxNavigationMode.drivingWithTraffic &&
        _waypoints.length > 3) {
      _showWarning(
          'iOS: drivingWithTraffic supports max 3 waypoints. Switching to driving mode.');
      setState(() => _mode = MapBoxNavigationMode.driving);
    }

    final options = MapBoxOptions(
      initialLatitude: _waypoints.first.latitude,
      initialLongitude: _waypoints.first.longitude,
      zoom: 15.0,
      voiceInstructionsEnabled: true,
      bannerInstructionsEnabled: true,
      units: _units,
      mode: _mode,
      simulateRoute: _simulateRoute,
      animateBuildRoute: true,
    );

    try {
      await _navigation.startNavigation(
        wayPoints: _waypoints,
        options: options,
      );
    } catch (e) {
      _showError('Failed to start navigation: $e');
    }
  }

  Future<void> _addWaypointDuringNavigation() async {
    if (!_isNavigating) {
      _showError('Start navigation first');
      return;
    }

    // Add a new waypoint
    final newWaypoint = WayPoint(
      name: 'Added Stop ${DateTime.now().second}',
      latitude: 38.8950,
      longitude: -77.0200,
    );

    try {
      await _navigation.addWayPoints(wayPoints: [newWaypoint]);
      setState(() => _waypoints.add(newWaypoint));
      _showMessage('Waypoint added!');
    } catch (e) {
      _showError('Failed to add waypoint: $e');
    }
  }

  void _addWaypoint() {
    // Add a sample waypoint
    setState(() {
      _waypoints.add(WayPoint(
        name: 'Stop ${_waypoints.length + 1}',
        latitude: 38.8900 + (_waypoints.length * 0.002),
        longitude: -77.0300 + (_waypoints.length * 0.002),
      ));
    });
  }

  void _removeWaypoint(int index) {
    if (_waypoints.length <= 2) {
      _showError('Need at least 2 waypoints');
      return;
    }
    setState(() => _waypoints.removeAt(index));
  }

  void _toggleSilent(int index) {
    // First and last waypoints cannot be silent
    if (index == 0 || index == _waypoints.length - 1) {
      _showError('First and last waypoints cannot be silent');
      return;
    }

    setState(() {
      final wp = _waypoints[index];
      _waypoints[index] = WayPoint(
        name: wp.name,
        latitude: wp.latitude,
        longitude: wp.longitude,
        isSilent: !(wp.isSilent ?? false),
      );
    });
  }

  Future<void> _finishNavigation() async {
    try {
      await _navigation.finishNavigation();
    } catch (e) {
      _showError('Failed to finish navigation: $e');
    }
  }

  void _loadPreset(String presetName) {
    final route = SampleWaypoints.allRoutes[presetName];
    if (route != null) {
      setState(() => _waypoints = List.from(route));
    }
  }

  // ===========================================================================
  // UI HELPERS
  // ===========================================================================

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showWarning(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.orange),
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
        title: const Text('Multi-Stop Navigation'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: _loadPreset,
            itemBuilder: (context) => SampleWaypoints.allRoutes.keys
                .map((name) => PopupMenuItem(value: name, child: Text(name)))
                .toList(),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(UIConstants.defaultPadding),
        children: [
          // Status
          StatusBar(
            isNavigating: _isNavigating,
            routeBuilt: _routeBuilt,
            distanceRemaining: _distanceRemaining,
            durationRemaining: _durationRemaining,
            currentInstruction: _currentInstruction,
            lastEventType: _lastEventType,
          ),
          const SizedBox(height: 16),

          // Progress indicator
          if (_isNavigating) ...[
            _buildProgressIndicator(),
            const SizedBox(height: 16),
          ],

          // Waypoint list
          _buildWaypointList(),
          const SizedBox(height: 16),

          // Options
          _buildOptionsCard(),
          const SizedBox(height: 16),

          // Action buttons
          _buildActionButtons(),
          const SizedBox(height: 16),

          // Event log
          EventLogWidget(
            entries: _eventLog,
            maxHeight: 200,
            onClear: () => setState(() => _eventLog.clear()),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Card(
      color: Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(UIConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.flag, color: Colors.green.shade700),
                const SizedBox(width: 8),
                Text(
                  'Progress: ${_currentWaypointIndex + 1} / ${_waypoints.length}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: _waypoints.isNotEmpty
                  ? (_currentWaypointIndex + 1) / _waypoints.length
                  : 0,
              backgroundColor: Colors.green.shade100,
              valueColor: AlwaysStoppedAnimation(Colors.green.shade700),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWaypointList() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(UIConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.route, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Waypoints (${_waypoints.length})',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Spacer(),
                if (!_isNavigating)
                  IconButton(
                    icon: const Icon(Icons.add_circle),
                    onPressed: _addWaypoint,
                    tooltip: 'Add waypoint',
                  ),
              ],
            ),
            const Divider(),
            ...List.generate(_waypoints.length, (index) {
              final wp = _waypoints[index];
              final isFirst = index == 0;
              final isLast = index == _waypoints.length - 1;
              final isCurrent = _isNavigating && index == _currentWaypointIndex;
              final isPassed = _isNavigating && index < _currentWaypointIndex;

              return Container(
                padding: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  color: isCurrent
                      ? Colors.blue.shade50
                      : isPassed
                          ? Colors.grey.shade100
                          : null,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    // Index circle
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: isPassed
                            ? Colors.grey
                            : isFirst
                                ? Colors.green
                                : isLast
                                    ? Colors.red
                                    : (wp.isSilent ?? false)
                                        ? Colors.orange
                                        : Colors.blue,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: isPassed
                            ? const Icon(Icons.check,
                                color: Colors.white, size: 16)
                            : Text(
                                '${index + 1}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Waypoint name
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            wp.name,
                            style: TextStyle(
                              fontWeight:
                                  isCurrent ? FontWeight.bold : FontWeight.normal,
                              decoration:
                                  isPassed ? TextDecoration.lineThrough : null,
                            ),
                          ),
                          if (wp.isSilent ?? false)
                            Text(
                              'Silent waypoint (no announcement)',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.orange.shade700,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                        ],
                      ),
                    ),

                    // Actions
                    if (!_isNavigating) ...[
                      // Toggle silent (not for first/last)
                      if (!isFirst && !isLast)
                        IconButton(
                          icon: Icon(
                            (wp.isSilent ?? false)
                                ? Icons.volume_off
                                : Icons.volume_up,
                            size: 20,
                            color: (wp.isSilent ?? false) ? Colors.orange : Colors.grey,
                          ),
                          onPressed: () => _toggleSilent(index),
                          tooltip: 'Toggle silent',
                        ),
                      // Remove (if > 2 waypoints)
                      if (_waypoints.length > 2)
                        IconButton(
                          icon: const Icon(Icons.remove_circle,
                              size: 20, color: Colors.red),
                          onPressed: () => _removeWaypoint(index),
                          tooltip: 'Remove',
                        ),
                    ],
                  ],
                ),
              );
            }),
          ],
        ),
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
            const SizedBox(height: 12),

            SwitchListTile(
              title: const Text('Simulate Route'),
              value: _simulateRoute,
              onChanged: _isNavigating
                  ? null
                  : (value) => setState(() => _simulateRoute = value),
              contentPadding: EdgeInsets.zero,
            ),

            // iOS warning
            if (Platform.isIOS) ...[
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline,
                        size: 16, color: Colors.orange.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'iOS: drivingWithTraffic limited to 3 waypoints',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isNavigating ? null : _startNavigation,
            icon: const Icon(Icons.navigation),
            label: const Text('Start Multi-Stop Navigation'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isNavigating ? _addWaypointDuringNavigation : null,
                icon: const Icon(Icons.add_location),
                label: const Text('Add Stop'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isNavigating ? _finishNavigation : null,
                icon: const Icon(Icons.stop),
                label: const Text('Stop'),
                style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
