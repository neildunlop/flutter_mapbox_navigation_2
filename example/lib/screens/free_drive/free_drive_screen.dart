/// Free Drive Screen
///
/// Demonstrates passive navigation mode without a destination:
/// - Starting free drive with startFreeDrive()
/// - Monitoring location and speed updates
/// - Transitioning from free drive to active navigation
///
/// Use case: Exploring an area without setting a destination

import 'package:flutter/material.dart';
import 'package:flutter_mapbox_navigation/flutter_mapbox_navigation.dart';
import '../../core/constants.dart';
import '../../shared/widgets/status_bar.dart';
import '../../shared/widgets/event_log.dart';

class FreeDriveScreen extends StatefulWidget {
  const FreeDriveScreen({super.key});

  @override
  State<FreeDriveScreen> createState() => _FreeDriveScreenState();
}

class _FreeDriveScreenState extends State<FreeDriveScreen> {
  // ===========================================================================
  // STATE
  // ===========================================================================

  final _navigation = MapBoxNavigation.instance;

  // Navigation state
  bool _inFreeDrive = false;
  String? _lastEventType;

  // Options
  bool _simulateRoute = true;
  VoiceUnits _units = VoiceUnits.metric;

  // Event log
  final List<EventLogEntry> _eventLog = [];

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
      _lastEventType = event.eventType.toString().split('.').last;
      _eventLog.add(event.toLogEntry());
    });

    switch (event.eventType) {
      case MapBoxEvent.navigation_running:
        setState(() => _inFreeDrive = true);
        break;

      case MapBoxEvent.navigation_finished:
      case MapBoxEvent.navigation_cancelled:
        setState(() => _inFreeDrive = false);
        break;

      default:
        break;
    }
  }

  // ===========================================================================
  // ACTIONS
  // ===========================================================================

  Future<void> _startFreeDrive() async {
    final options = MapBoxOptions(
      initialLatitude: MapDefaults.defaultLatitude,
      initialLongitude: MapDefaults.defaultLongitude,
      zoom: MapDefaults.defaultZoom,
      units: _units,
      simulateRoute: _simulateRoute,
      voiceInstructionsEnabled: true,
      bannerInstructionsEnabled: true,
    );

    try {
      await _navigation.startFreeDrive(options: options);
    } catch (e) {
      _showError('Failed to start free drive: $e');
    }
  }

  Future<void> _stopFreeDrive() async {
    try {
      await _navigation.finishNavigation();
    } catch (e) {
      _showError('Failed to stop free drive: $e');
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
        title: const Text('Free Drive Mode'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(UIConstants.defaultPadding),
        children: [
          // Description card
          _buildDescriptionCard(),
          const SizedBox(height: 16),

          // Status
          StatusBar(
            isNavigating: _inFreeDrive,
            routeBuilt: false,
            lastEventType: _lastEventType,
          ),
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

  Widget _buildDescriptionCard() {
    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(UIConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.explore, color: Colors.blue.shade700),
                const SizedBox(width: 8),
                Text(
                  'What is Free Drive?',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Free Drive mode enables passive navigation without a set destination. '
              'The map follows your location and provides context about nearby roads '
              'without giving turn-by-turn directions.',
              style: TextStyle(color: Colors.blue.shade900),
            ),
            const SizedBox(height: 8),
            Text(
              'Use cases:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade900,
              ),
            ),
            const SizedBox(height: 4),
            _buildBulletPoint('Exploring a new area'),
            _buildBulletPoint('Monitoring your location while driving'),
            _buildBulletPoint('Discovering nearby points of interest'),
            _buildBulletPoint('Later transitioning to active navigation'),
          ],
        ),
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, top: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('• ', style: TextStyle(color: Colors.blue.shade900)),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: Colors.blue.shade900),
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
            const SizedBox(height: 12),

            SwitchListTile(
              title: const Text('Simulate Movement'),
              subtitle: const Text('For testing without actually moving'),
              value: _simulateRoute,
              onChanged: _inFreeDrive
                  ? null
                  : (value) => setState(() => _simulateRoute = value),
              contentPadding: EdgeInsets.zero,
            ),

            const Divider(),

            Row(
              children: [
                const Text('Units: '),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Metric'),
                  selected: _units == VoiceUnits.metric,
                  onSelected: _inFreeDrive
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
                  onSelected: _inFreeDrive
                      ? null
                      : (selected) {
                          if (selected) {
                            setState(() => _units = VoiceUnits.imperial);
                          }
                        },
                ),
              ],
            ),
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
            onPressed: _inFreeDrive ? null : _startFreeDrive,
            icon: const Icon(Icons.explore),
            label: const Text('Start Free Drive'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _inFreeDrive ? _stopFreeDrive : null,
            icon: const Icon(Icons.stop),
            label: const Text('Stop Free Drive'),
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
