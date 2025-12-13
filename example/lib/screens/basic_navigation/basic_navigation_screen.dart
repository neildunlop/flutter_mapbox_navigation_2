/// Basic Navigation Screen
///
/// Demonstrates the fundamental turn-by-turn navigation features:
/// - Starting navigation with MapBoxNavigation.instance.startNavigation()
/// - Configuring MapBoxOptions for voice/banner instructions
/// - Listening to route events
/// - Finishing navigation
///
/// Platform notes:
/// - iOS: Voice units are locked after first navigation session
/// - Android: Requires FlutterFragmentActivity as base activity

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_mapbox_navigation/flutter_mapbox_navigation.dart';
import '../../core/constants.dart';
import '../../data/sample_waypoints.dart';
import '../../shared/widgets/status_bar.dart';
import '../../shared/widgets/event_log.dart';
import '../../shared/widgets/section_header.dart';

class BasicNavigationScreen extends StatefulWidget {
  const BasicNavigationScreen({super.key});

  @override
  State<BasicNavigationScreen> createState() => _BasicNavigationScreenState();
}

class _BasicNavigationScreenState extends State<BasicNavigationScreen> {
  // ===========================================================================
  // STATE
  // ===========================================================================

  // Navigation instance
  final _navigation = MapBoxNavigation.instance;

  // Configuration
  late MapBoxOptions _options;
  List<WayPoint> _waypoints = [];
  bool _simulateRoute = true;
  bool _voiceEnabled = true;
  bool _bannerEnabled = true;
  VoiceUnits _units = VoiceUnits.metric;

  // Navigation state
  bool _isNavigating = false;
  bool _routeBuilt = false;

  // Progress state
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
    _waypoints = List.from(SampleWaypoints.basicRoute);
    _initializeOptions();
    _registerEventListener();
  }

  void _initializeOptions() {
    _options = MapBoxOptions(
      initialLatitude: _waypoints.first.latitude,
      initialLongitude: _waypoints.first.longitude,
      zoom: 15.0,
      voiceInstructionsEnabled: _voiceEnabled,
      bannerInstructionsEnabled: _bannerEnabled,
      units: _units,
      mode: MapBoxNavigationMode.drivingWithTraffic,
      simulateRoute: _simulateRoute,
      animateBuildRoute: true,
      longPressDestinationEnabled: false,
    );
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
        break;

      default:
        break;
    }
  }

  // ===========================================================================
  // NAVIGATION ACTIONS
  // ===========================================================================

  Future<void> _startNavigation() async {
    if (_waypoints.length < 2) {
      _showError('Need at least 2 waypoints');
      return;
    }

    // Update options before starting
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
        title: const Text('Basic Navigation'),
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

          // Route selection
          _buildRouteSelectionSection(),
          const SizedBox(height: 16),

          // Options section
          _buildOptionsSection(),
          const SizedBox(height: 16),

          // Action buttons
          _buildActionButtons(),
          const SizedBox(height: 16),

          // Event log
          const SectionHeader(
            title: 'Event Log',
            icon: Icons.list_alt,
          ),
          EventLogWidget(
            entries: _eventLog,
            maxHeight: 250,
            onClear: () => setState(() => _eventLog.clear()),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteSelectionSection() {
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
                  'Route',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Route presets dropdown
            DropdownButtonFormField<String>(
              value: 'Basic (2 stops)',
              decoration: const InputDecoration(
                labelText: 'Select Route',
                border: OutlineInputBorder(),
              ),
              items: SampleWaypoints.allRoutes.keys.map((name) {
                return DropdownMenuItem(
                  value: name,
                  child: Text(name),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _waypoints =
                        List.from(SampleWaypoints.allRoutes[value] ?? []);
                  });
                }
              },
            ),
            const SizedBox(height: 12),

            // Waypoint list
            Text(
              'Waypoints (${_waypoints.length}):',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 4),
            ...List.generate(_waypoints.length, (index) {
              final wp = _waypoints[index];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: index == 0
                            ? Colors.green
                            : index == _waypoints.length - 1
                                ? Colors.red
                                : Colors.blue,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        wp.name,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    if (wp.isSilent ?? false)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Silent',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.orange.shade800,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionsSection() {
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

            // Voice instructions toggle
            SwitchListTile(
              title: const Text('Voice Instructions'),
              subtitle: const Text('Spoken turn-by-turn guidance'),
              value: _voiceEnabled,
              onChanged: _isNavigating
                  ? null
                  : (value) => setState(() => _voiceEnabled = value),
              contentPadding: EdgeInsets.zero,
            ),

            // Banner instructions toggle
            SwitchListTile(
              title: const Text('Banner Instructions'),
              subtitle: const Text('Visual turn instructions'),
              value: _bannerEnabled,
              onChanged: _isNavigating
                  ? null
                  : (value) => setState(() => _bannerEnabled = value),
              contentPadding: EdgeInsets.zero,
            ),

            // Simulate route toggle
            SwitchListTile(
              title: const Text('Simulate Route'),
              subtitle: const Text('For testing without driving'),
              value: _simulateRoute,
              onChanged: _isNavigating
                  ? null
                  : (value) => setState(() => _simulateRoute = value),
              contentPadding: EdgeInsets.zero,
            ),

            const Divider(),

            // Units selection
            Row(
              children: [
                const Text('Units: '),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Metric'),
                  selected: _units == VoiceUnits.metric,
                  onSelected: _isNavigating
                      ? null
                      : (selected) {
                          if (selected) {
                            setState(() => _units = VoiceUnits.metric);
                          }
                        },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Imperial'),
                  selected: _units == VoiceUnits.imperial,
                  onSelected: _isNavigating
                      ? null
                      : (selected) {
                          if (selected) {
                            setState(() => _units = VoiceUnits.imperial);
                          }
                        },
                ),
              ],
            ),

            // iOS warning about units
            if (Platform.isIOS) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline,
                        size: 16, color: Colors.orange.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'iOS: Voice units are locked after first navigation',
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
            label: const Text('Start Navigation'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 8),
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
      ],
    );
  }
}
