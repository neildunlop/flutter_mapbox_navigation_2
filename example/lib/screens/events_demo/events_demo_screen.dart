/// Events Demo Screen
///
/// Demonstrates the navigation event system:
/// - All MapBoxEvent types
/// - RouteProgressEvent data
/// - Real-time event logging
/// - Event filtering and analysis

import 'package:flutter/material.dart';
import 'package:flutter_mapbox_navigation/flutter_mapbox_navigation.dart';
import '../../core/constants.dart';
import '../../data/sample_waypoints.dart';
import '../../shared/widgets/event_log.dart';

class EventsDemoScreen extends StatefulWidget {
  const EventsDemoScreen({super.key});

  @override
  State<EventsDemoScreen> createState() => _EventsDemoScreenState();
}

class _EventsDemoScreenState extends State<EventsDemoScreen> {
  // ===========================================================================
  // STATE
  // ===========================================================================

  final _navigation = MapBoxNavigation.instance;

  // Event log
  final List<EventLogEntry> _eventLog = [];
  final Map<MapBoxEvent, int> _eventCounts = {};

  // Filter
  Set<MapBoxEvent> _enabledEvents = MapBoxEvent.values.toSet();

  // Navigation state
  bool _isNavigating = false;

  // ===========================================================================
  // LIFECYCLE
  // ===========================================================================

  @override
  void initState() {
    super.initState();
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
      // Add to log
      _eventLog.add(event.toLogEntry());

      // Update counts
      final eventType = event.eventType;
      if (eventType != null) {
        _eventCounts[eventType] = (_eventCounts[eventType] ?? 0) + 1;

        // Update navigation state
        if (eventType == MapBoxEvent.navigation_running) {
          _isNavigating = true;
        } else if (eventType == MapBoxEvent.navigation_finished ||
            eventType == MapBoxEvent.navigation_cancelled) {
          _isNavigating = false;
        }
      }
    });
  }

  // ===========================================================================
  // ACTIONS
  // ===========================================================================

  Future<void> _startNavigation() async {
    final waypoints = SampleWaypoints.dcMonumentsTour;

    final options = MapBoxOptions(
      initialLatitude: waypoints.first.latitude,
      initialLongitude: waypoints.first.longitude,
      zoom: 15.0,
      voiceInstructionsEnabled: true,
      bannerInstructionsEnabled: true,
      units: VoiceUnits.metric,
      mode: MapBoxNavigationMode.driving,
      simulateRoute: true,
    );

    try {
      await _navigation.startNavigation(
        wayPoints: waypoints,
        options: options,
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

  void _clearLog() {
    setState(() {
      _eventLog.clear();
      _eventCounts.clear();
    });
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  // ===========================================================================
  // BUILD
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Events Demo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear_all),
            onPressed: _clearLog,
            tooltip: 'Clear log',
          ),
        ],
      ),
      body: Column(
        children: [
          // Event statistics
          _buildEventStats(),

          // Event type reference
          _buildEventReference(),

          // Event log (scrollable)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(UIConstants.defaultPadding),
              child: EventLogWidget(
                entries: _eventLog
                    .where((e) => _enabledEvents.contains(e.eventType))
                    .toList(),
                maxHeight: double.infinity,
                onClear: _clearLog,
              ),
            ),
          ),

          // Action buttons
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildEventStats() {
    final totalEvents = _eventLog.length;
    final uniqueTypes = _eventCounts.keys.length;

    return Container(
      padding: const EdgeInsets.all(UIConstants.defaultPadding),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        border: Border(
          bottom: BorderSide(color: Colors.blue.shade100),
        ),
      ),
      child: Row(
        children: [
          _StatBox(
            label: 'Total',
            value: totalEvents.toString(),
            color: Colors.blue,
          ),
          const SizedBox(width: 16),
          _StatBox(
            label: 'Types',
            value: uniqueTypes.toString(),
            color: Colors.purple,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _eventCounts.entries
                    .where((e) => e.value > 0)
                    .toList()
                    .take(5)
                    .map((e) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Chip(
                            label: Text(
                              '${e.key.toString().split('.').last}: ${e.value}',
                              style: const TextStyle(fontSize: 10),
                            ),
                            padding: EdgeInsets.zero,
                            visualDensity: VisualDensity.compact,
                          ),
                        ))
                    .toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventReference() {
    return ExpansionTile(
      title: const Text('Event Types Reference'),
      children: [
        Padding(
          padding: const EdgeInsets.all(UIConstants.defaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildEventCategory('Route Events', [
                _EventInfo(MapBoxEvent.route_building, 'Route calculation started'),
                _EventInfo(MapBoxEvent.route_built, 'Route successfully calculated'),
                _EventInfo(MapBoxEvent.route_build_failed, 'Route calculation failed'),
                _EventInfo(MapBoxEvent.route_build_no_routes_found, 'No valid routes found'),
              ]),
              const SizedBox(height: 12),
              _buildEventCategory('Navigation Events', [
                _EventInfo(MapBoxEvent.navigation_running, 'Navigation active'),
                _EventInfo(MapBoxEvent.progress_change, 'Progress update'),
                _EventInfo(MapBoxEvent.on_arrival, 'Arrived at waypoint'),
                _EventInfo(MapBoxEvent.navigation_finished, 'Navigation completed'),
                _EventInfo(MapBoxEvent.navigation_cancelled, 'Navigation cancelled'),
              ]),
              const SizedBox(height: 12),
              _buildEventCategory('User Events', [
                _EventInfo(MapBoxEvent.user_off_route, 'User departed from route'),
                _EventInfo(MapBoxEvent.faster_route_found, 'Alternative route available'),
                _EventInfo(MapBoxEvent.milestone_event, 'Navigation milestone'),
              ]),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEventCategory(String title, List<_EventInfo> events) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        ...events.map((e) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _getEventColor(e.event),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    e.event.toString().split('.').last,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      e.description,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(UIConstants.defaultPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isNavigating ? null : _startNavigation,
                icon: const Icon(Icons.play_arrow),
                label: const Text('Start'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isNavigating ? _finishNavigation : null,
                icon: const Icon(Icons.stop),
                label: const Text('Stop'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getEventColor(MapBoxEvent event) {
    switch (event) {
      case MapBoxEvent.route_built:
        return Colors.green;
      case MapBoxEvent.route_building:
        return Colors.blue;
      case MapBoxEvent.route_build_failed:
      case MapBoxEvent.route_build_no_routes_found:
        return Colors.red;
      case MapBoxEvent.navigation_running:
        return Colors.green;
      case MapBoxEvent.navigation_finished:
        return Colors.teal;
      case MapBoxEvent.navigation_cancelled:
        return Colors.orange;
      case MapBoxEvent.progress_change:
        return Colors.blue;
      case MapBoxEvent.on_arrival:
        return Colors.purple;
      case MapBoxEvent.user_off_route:
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatBox({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}

class _EventInfo {
  final MapBoxEvent event;
  final String description;

  _EventInfo(this.event, this.description);
}
