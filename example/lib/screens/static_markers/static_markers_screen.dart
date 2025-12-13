/// Static Markers Screen
///
/// Demonstrates adding custom POI markers to the navigation map:
/// - addStaticMarkers() API
/// - StaticMarker model with all properties
/// - MarkerConfiguration options
/// - Marker tap events and popups
/// - Clustering and distance filtering

import 'package:flutter/material.dart';
import 'package:flutter_mapbox_navigation/flutter_mapbox_navigation.dart';
import '../../core/constants.dart';
import '../../data/sample_markers.dart';

class StaticMarkersScreen extends StatefulWidget {
  const StaticMarkersScreen({super.key});

  @override
  State<StaticMarkersScreen> createState() => _StaticMarkersScreenState();
}

class _StaticMarkersScreenState extends State<StaticMarkersScreen> {
  // ===========================================================================
  // STATE
  // ===========================================================================

  final _navigation = MapBoxNavigation.instance;
  MapBoxNavigationViewController? _controller;

  // Markers
  List<StaticMarker> _activeMarkers = [];
  StaticMarker? _lastTappedMarker;

  // Configuration
  bool _enableClustering = true;
  double? _maxDistanceFromRoute = 10.0;
  bool _showDuringNavigation = true;

  // Categories
  final Map<String, bool> _selectedCategories = {
    'Restaurants': true,
    'Gas Stations': true,
    'EV Charging': false,
    'Scenic': true,
    'Hotels': false,
    'Emergency': false,
    'Parking': false,
  };

  // ===========================================================================
  // LIFECYCLE
  // ===========================================================================

  @override
  void initState() {
    super.initState();
    _registerMarkerListener();
  }

  Future<void> _registerMarkerListener() async {
    await _navigation.registerStaticMarkerTapListener(_onMarkerTap);
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  // ===========================================================================
  // MARKER HANDLING
  // ===========================================================================

  void _onMarkerTap(StaticMarker marker) {
    setState(() => _lastTappedMarker = marker);
    _showMarkerDetails(marker);
  }

  void _onMapCreated(MapBoxNavigationViewController controller) {
    _controller = controller;
    controller.initialize();
  }

  Future<void> _addMarkers() async {
    // Collect markers from selected categories
    final markersToAdd = <StaticMarker>[];
    for (final category in _selectedCategories.entries) {
      if (category.value) {
        final categoryMarkers = SampleMarkers.byCategory[category.key];
        if (categoryMarkers != null) {
          markersToAdd.addAll(categoryMarkers);
        }
      }
    }

    if (markersToAdd.isEmpty) {
      _showMessage('Select at least one category');
      return;
    }

    final config = MarkerConfiguration(
      enableClustering: _enableClustering,
      maxDistanceFromRoute: _maxDistanceFromRoute,
      showDuringNavigation: _showDuringNavigation,
      onMarkerTap: _onMarkerTap,
    );

    try {
      await _navigation.addStaticMarkers(
        markers: markersToAdd,
        configuration: config,
      );
      setState(() => _activeMarkers = markersToAdd);
      _showMessage('Added ${markersToAdd.length} markers');
    } catch (e) {
      _showError('Failed to add markers: $e');
    }
  }

  Future<void> _removeMarkers() async {
    if (_activeMarkers.isEmpty) return;

    try {
      await _navigation.clearAllStaticMarkers();
      setState(() {
        _activeMarkers.clear();
        _lastTappedMarker = null;
      });
      _showMessage('Markers removed');
    } catch (e) {
      _showError('Failed to remove markers: $e');
    }
  }

  void _showMarkerDetails(StaticMarker marker) {
    showModalBottomSheet(
      context: context,
      builder: (context) => _MarkerDetailsSheet(marker: marker),
    );
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
        title: const Text('Static Markers'),
        actions: [
          IconButton(
            icon: const Icon(Icons.grid_view),
            onPressed: () =>
                Navigator.pushNamed(context, AppRoutes.markerGallery),
            tooltip: 'View all icons',
          ),
        ],
      ),
      body: Column(
        children: [
          // Map
          Expanded(
            flex: 2,
            child: MapBoxNavigationView(
              options: MapBoxOptions(
                initialLatitude: MapDefaults.defaultLatitude,
                initialLongitude: MapDefaults.defaultLongitude,
                zoom: 12.0,
                units: VoiceUnits.metric,
                voiceInstructionsEnabled: false,
                bannerInstructionsEnabled: false,
              ),
              onCreated: _onMapCreated,
              onRouteEvent: (_) {},
            ),
          ),

          // Controls
          Expanded(
            flex: 3,
            child: Container(
              color: Colors.white,
              child: ListView(
                padding: const EdgeInsets.all(UIConstants.defaultPadding),
                children: [
                  // Last tapped marker info
                  if (_lastTappedMarker != null) ...[
                    _buildLastTappedCard(),
                    const SizedBox(height: 16),
                  ],

                  // Category selection
                  _buildCategorySelection(),
                  const SizedBox(height: 16),

                  // Configuration
                  _buildConfigurationCard(),
                  const SizedBox(height: 16),

                  // Actions
                  _buildActionButtons(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLastTappedCard() {
    final marker = _lastTappedMarker!;
    return Card(
      color: Colors.green.shade50,
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: marker.customColor ?? Colors.blue,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.place, color: Colors.white),
        ),
        title: Text(marker.title),
        subtitle: Text(marker.category),
        trailing: IconButton(
          icon: const Icon(Icons.info_outline),
          onPressed: () => _showMarkerDetails(marker),
        ),
      ),
    );
  }

  Widget _buildCategorySelection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(UIConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.category, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Categories',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _selectedCategories.entries.map((entry) {
                return FilterChip(
                  label: Text(entry.key),
                  selected: entry.value,
                  onSelected: (selected) {
                    setState(() => _selectedCategories[entry.key] = selected);
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfigurationCard() {
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
                  'Configuration',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            SwitchListTile(
              title: const Text('Enable Clustering'),
              subtitle: const Text('Group nearby markers'),
              value: _enableClustering,
              onChanged: (value) => setState(() => _enableClustering = value),
              contentPadding: EdgeInsets.zero,
            ),

            SwitchListTile(
              title: const Text('Show During Navigation'),
              subtitle: const Text('Display markers while navigating'),
              value: _showDuringNavigation,
              onChanged: (value) =>
                  setState(() => _showDuringNavigation = value),
              contentPadding: EdgeInsets.zero,
            ),

            SwitchListTile(
              title: const Text('Distance Filter'),
              subtitle: Text(_maxDistanceFromRoute != null
                  ? 'Max ${_maxDistanceFromRoute!.toInt()} km from route'
                  : 'Show all markers'),
              value: _maxDistanceFromRoute != null,
              onChanged: (value) {
                setState(
                    () => _maxDistanceFromRoute = value ? 10.0 : null);
              },
              contentPadding: EdgeInsets.zero,
            ),

            if (_maxDistanceFromRoute != null) ...[
              Slider(
                value: _maxDistanceFromRoute!,
                min: 1,
                max: 50,
                divisions: 49,
                label: '${_maxDistanceFromRoute!.toInt()} km',
                onChanged: (value) =>
                    setState(() => _maxDistanceFromRoute = value),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _addMarkers,
            icon: const Icon(Icons.add_location),
            label: const Text('Add Markers'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _activeMarkers.isNotEmpty ? _removeMarkers : null,
            icon: const Icon(Icons.clear),
            label: Text('Clear (${_activeMarkers.length})'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              foregroundColor: Colors.red,
            ),
          ),
        ),
      ],
    );
  }
}

/// Bottom sheet showing marker details
class _MarkerDetailsSheet extends StatelessWidget {
  final StaticMarker marker;

  const _MarkerDetailsSheet({required this.marker});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(UIConstants.defaultPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: marker.customColor ?? Colors.blue,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.place, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      marker.title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Text(
                      marker.category.toUpperCase(),
                      style: TextStyle(
                        color: marker.customColor ?? Colors.blue,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (marker.description != null) ...[
            const SizedBox(height: 16),
            Text(marker.description!),
          ],

          // Metadata
          if (marker.metadata != null && marker.metadata!.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            Text(
              'Details',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            ...marker.metadata!.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Text(
                      '${entry.key}: ',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    Expanded(
                      child: Text(entry.value.toString()),
                    ),
                  ],
                ),
              );
            }),
          ],

          const SizedBox(height: 16),

          // Actions
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  label: const Text('Close'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    // Could navigate to this marker
                  },
                  icon: const Icon(Icons.navigation),
                  label: const Text('Navigate'),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
