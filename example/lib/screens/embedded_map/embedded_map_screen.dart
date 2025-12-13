/// Embedded Map Screen
///
/// Demonstrates navigation embedded in the Flutter widget tree:
/// - Using MapBoxNavigationView widget
/// - Controlling navigation via MapBoxNavigationViewController
/// - Building routes with controller.buildRoute()
/// - Starting navigation with controller.startNavigation()
///
/// Platform notes:
/// - Uses platform views for native map performance
/// - Supports Flutter-rendered overlays

import 'package:flutter/material.dart';
import 'package:flutter_mapbox_navigation/flutter_mapbox_navigation.dart';
import '../../core/constants.dart';
import '../../data/sample_waypoints.dart';
import '../../shared/widgets/event_log.dart';

class EmbeddedMapScreen extends StatefulWidget {
  const EmbeddedMapScreen({super.key});

  @override
  State<EmbeddedMapScreen> createState() => _EmbeddedMapScreenState();
}

class _EmbeddedMapScreenState extends State<EmbeddedMapScreen> {
  // ===========================================================================
  // STATE
  // ===========================================================================

  MapBoxNavigationViewController? _controller;

  // Configuration
  late MapBoxOptions _options;
  List<WayPoint> _waypoints = [];
  bool _simulateRoute = true;

  // Navigation state
  bool _isNavigating = false;
  bool _routeBuilt = false;
  bool _isLoading = false;

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
    _waypoints = List.from(SampleWaypoints.basicRoute);
    _initializeOptions();
  }

  void _initializeOptions() {
    _options = MapBoxOptions(
      initialLatitude: MapDefaults.defaultLatitude,
      initialLongitude: MapDefaults.defaultLongitude,
      zoom: 13.0,
      voiceInstructionsEnabled: true,
      bannerInstructionsEnabled: true,
      units: VoiceUnits.metric,
      mode: MapBoxNavigationMode.drivingWithTraffic,
      simulateRoute: _simulateRoute,
      animateBuildRoute: true,
      longPressDestinationEnabled: false,
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  // ===========================================================================
  // CONTROLLER CALLBACKS
  // ===========================================================================

  void _onMapCreated(MapBoxNavigationViewController controller) {
    _controller = controller;
    controller.initialize();
  }

  void _onRouteEvent(RouteEvent event) {
    if (!mounted) return;

    setState(() {
      _lastEventType = event.eventType.toString().split('.').last;
      _eventLog.add(event.toLogEntry());
    });

    switch (event.eventType) {
      case MapBoxEvent.route_building:
        setState(() {
          _isLoading = true;
          _routeBuilt = false;
        });
        break;

      case MapBoxEvent.route_built:
        setState(() {
          _isLoading = false;
          _routeBuilt = true;
        });
        break;

      case MapBoxEvent.route_build_failed:
      case MapBoxEvent.route_build_no_routes_found:
        setState(() {
          _isLoading = false;
          _routeBuilt = false;
        });
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
  // ACTIONS
  // ===========================================================================

  Future<void> _buildRoute() async {
    if (_controller == null || _waypoints.length < 2) {
      _showError('Need at least 2 waypoints');
      return;
    }

    setState(() => _isLoading = true);
    _initializeOptions();

    try {
      await _controller!.buildRoute(
        wayPoints: _waypoints,
        options: _options,
      );
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Failed to build route: $e');
    }
  }

  Future<void> _startNavigation() async {
    if (_controller == null) return;

    try {
      await _controller!.startNavigation();
    } catch (e) {
      _showError('Failed to start navigation: $e');
    }
  }

  Future<void> _clearRoute() async {
    if (_controller == null) return;

    try {
      await _controller!.clearRoute();
      setState(() {
        _routeBuilt = false;
        _isNavigating = false;
        _distanceRemaining = null;
        _durationRemaining = null;
        _currentInstruction = null;
      });
    } catch (e) {
      _showError('Failed to clear route: $e');
    }
  }

  Future<void> _finishNavigation() async {
    if (_controller == null) return;

    try {
      await _controller!.finishNavigation();
    } catch (e) {
      _showError('Failed to finish navigation: $e');
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  // ===========================================================================
  // BUILD
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Embedded Map'),
      ),
      body: Column(
        children: [
          // Map view (takes remaining space)
          Expanded(
            child: Stack(
              children: [
                // Embedded navigation view
                MapBoxNavigationView(
                  options: _options,
                  onCreated: _onMapCreated,
                  onRouteEvent: _onRouteEvent,
                ),

                // Loading overlay
                if (_isLoading)
                  Container(
                    color: Colors.black26,
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
              ],
            ),
          ),

          // Controls panel
          Container(
            color: Colors.white,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(UIConstants.defaultPadding),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Compact status bar
                    _buildCompactStatus(),
                    const SizedBox(height: 12),

                    // Route selector
                    _buildRouteSelector(),
                    const SizedBox(height: 12),

                    // Action buttons
                    _buildActionButtons(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactStatus() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          _buildStatusChip(
            'Route',
            _routeBuilt,
            Colors.blue,
          ),
          const SizedBox(width: 8),
          _buildStatusChip(
            'Navigating',
            _isNavigating,
            Colors.green,
          ),
          const Spacer(),
          if (_distanceRemaining != null) ...[
            Icon(Icons.straighten, size: 16, color: Colors.grey.shade600),
            const SizedBox(width: 4),
            Text(
              _formatDistance(_distanceRemaining!),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusChip(String label, bool isActive, Color activeColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? activeColor.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isActive ? activeColor : Colors.grey.shade300,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive ? activeColor : Colors.grey.shade400,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isActive ? activeColor : Colors.grey.shade600,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteSelector() {
    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<String>(
            value: 'Basic (2 stops)',
            decoration: const InputDecoration(
              labelText: 'Route',
              border: OutlineInputBorder(),
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            items: SampleWaypoints.allRoutes.keys.map((name) {
              return DropdownMenuItem(
                value: name,
                child: Text(name, style: const TextStyle(fontSize: 14)),
              );
            }).toList(),
            onChanged: _isNavigating
                ? null
                : (value) {
                    if (value != null) {
                      setState(() {
                        _waypoints =
                            List.from(SampleWaypoints.allRoutes[value] ?? []);
                      });
                    }
                  },
          ),
        ),
        const SizedBox(width: 8),
        // Simulate toggle
        Row(
          children: [
            const Text('Sim', style: TextStyle(fontSize: 12)),
            Switch(
              value: _simulateRoute,
              onChanged: _isNavigating
                  ? null
                  : (value) => setState(() => _simulateRoute = value),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: _isNavigating || _isLoading
                ? null
                : _routeBuilt
                    ? _clearRoute
                    : _buildRoute,
            child: Text(_routeBuilt ? 'Clear' : 'Build Route'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ElevatedButton(
            onPressed: _routeBuilt
                ? _isNavigating
                    ? _finishNavigation
                    : _startNavigation
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: _isNavigating ? Colors.red : Colors.green,
              foregroundColor: Colors.white,
            ),
            child: Text(_isNavigating ? 'Stop' : 'Start'),
          ),
        ),
      ],
    );
  }

  String _formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.toStringAsFixed(0)} m';
    } else {
      return '${(meters / 1000).toStringAsFixed(1)} km';
    }
  }
}
