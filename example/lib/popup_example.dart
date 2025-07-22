import 'package:flutter/material.dart';
import 'package:flutter_mapbox_navigation/flutter_mapbox_navigation.dart';

/// Example demonstrating the new Flutter-based popup overlay system
class PopupExamplePage extends StatefulWidget {
  const PopupExamplePage({super.key});

  @override
  State<PopupExamplePage> createState() => _PopupExamplePageState();
}

class _PopupExamplePageState extends State<PopupExamplePage> {
  MapBoxNavigationViewController? _controller;
  String _lastInteraction = 'None';
  
  late List<StaticMarker> _markers;
  late MarkerConfiguration _markerConfiguration;

  @override
  void initState() {
    super.initState();
    _setupMarkers();
    _setupMarkerConfiguration();
  }

  void _setupMarkers() {
    _markers = [
      StaticMarker(
        id: 'restaurant_1',
        latitude: 37.7749,
        longitude: -122.4194,
        title: 'Golden Gate Grill',
        category: 'restaurant',
        description: 'Amazing seafood with a view of the Golden Gate Bridge',
        iconId: MarkerIcons.restaurant,
        customColor: Colors.orange,
        metadata: {
          'rating': 4.5,
          'price_range': '\$\$\$',
          'cuisine': 'Seafood',
          'open_hours': '11AM - 10PM',
        },
      ),
      StaticMarker(
        id: 'gas_station_1',
        latitude: 37.7849,
        longitude: -122.4094,
        title: 'Shell Gas Station',
        category: 'petrol_station',
        description: '24/7 fuel station with convenience store',
        iconId: MarkerIcons.petrolStation,
        customColor: Colors.green,
        metadata: {
          'price_per_gallon': 4.85,
          'services': 'Car wash, ATM',
          'hours': '24/7',
        },
      ),
      StaticMarker(
        id: 'hotel_1',
        latitude: 37.7649,
        longitude: -122.4294,
        title: 'Bay View Hotel',
        category: 'hotel',
        description: 'Luxury hotel with panoramic city views',
        iconId: MarkerIcons.hotel,
        customColor: Colors.blue,
        metadata: {
          'stars': 4,
          'price_range': '\$\$\$\$',
          'amenities': 'Pool, Spa, Restaurant',
          'availability': 'Available',
        },
      ),
      StaticMarker(
        id: 'hospital_1',
        latitude: 37.7549,
        longitude: -122.4394,
        title: 'General Hospital',
        category: 'hospital',
        description: 'Full-service medical center with emergency care',
        iconId: MarkerIcons.hospital,
        customColor: Colors.red,
        metadata: {
          'emergency': 'Yes',
          'phone': '(555) 123-4567',
          'services': 'ER, Surgery, Maternity',
        },
      ),
    ];
  }

  void _setupMarkerConfiguration() {
    _markerConfiguration = MarkerConfiguration(
      enableClustering: true,
      showDuringNavigation: true,
      showInFreeDrive: true,
      showOnEmbeddedMap: true,
      maxDistanceFromRoute: 10.0,
      popupBuilder: _buildCustomPopup,
      popupDuration: const Duration(seconds: 8),
      popupOffset: const Offset(0, -80),
      hidePopupOnTapOutside: true,
      onMarkerTap: _onMarkerTapped,
    );
  }

  Widget _buildCustomPopup(StaticMarker marker, BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 280),
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
                  color: marker.customColor?.withOpacity(0.2) ?? Colors.blue.withOpacity(0.2),
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
          
          // Metadata display
          if (marker.metadata?.isNotEmpty == true) ...[
            const SizedBox(height: 12),
            ...marker.metadata!.entries.take(3).map((entry) => 
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Icon(
                      _getMetadataIcon(entry.key),
                      size: 14,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${_formatMetadataKey(entry.key)}: ${entry.value}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          
          const SizedBox(height: 12),
          
          // Action buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _navigateToMarker(marker),
                  icon: const Icon(Icons.directions, size: 16),
                  label: const Text('Navigate'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: marker.customColor ?? Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () => _showMarkerDetails(marker),
                icon: const Icon(Icons.info_outline, size: 16),
                label: const Text('Details'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ],
          ),
        ],
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
      default:
        return Icons.place;
    }
  }

  IconData _getMetadataIcon(String key) {
    switch (key.toLowerCase()) {
      case 'rating':
        return Icons.star;
      case 'price_range':
      case 'price_per_gallon':
        return Icons.attach_money;
      case 'phone':
        return Icons.phone;
      case 'hours':
      case 'open_hours':
        return Icons.access_time;
      case 'services':
      case 'amenities':
        return Icons.list_alt;
      default:
        return Icons.info;
    }
  }

  String _formatMetadataKey(String key) {
    return key.replaceAll('_', ' ').toLowerCase().split(' ')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  void _onMarkerTapped(StaticMarker marker) {
    setState(() {
      _lastInteraction = 'Tapped: ${marker.title}';
    });
  }

  void _navigateToMarker(StaticMarker marker) {
    setState(() {
      _lastInteraction = 'Navigate to: ${marker.title}';
    });
    
    // Hide the popup
    MarkerPopupManager().hidePopup();
    
    // Here you would typically start navigation to the marker
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Navigation to ${marker.title} would start here'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showMarkerDetails(StaticMarker marker) {
    setState(() {
      _lastInteraction = 'Show details: ${marker.title}';
    });
    
    // Hide the popup
    MarkerPopupManager().hidePopup();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(marker.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (marker.description != null)
              Text(marker.description!),
            const SizedBox(height: 16),
            const Text(
              'Details:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...marker.metadata!.entries.map((entry) => 
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text('${_formatMetadataKey(entry.key)}: ${entry.value}'),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Coordinates: ${marker.latitude.toStringAsFixed(6)}, ${marker.longitude.toStringAsFixed(6)}',
              style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _onNavigationViewCreated(MapBoxNavigationViewController controller) async {
    _controller = controller;
    await controller.initialize();
    
    // Add markers to the map
    await MapBoxNavigation.instance.addStaticMarkers(
      markers: _markers,
      configuration: _markerConfiguration,
    );
    
    // Set up marker tap listener
    await MapBoxNavigation.instance.registerStaticMarkerTapListener(
      (marker) {
        // The popup will be handled automatically by the MarkerPopupProvider
        setState(() {
          _lastInteraction = 'Platform tap: ${marker.title}';
        });
      },
    );
  }

  void _onRouteEvent(RouteEvent event) {
    // Handle route events if needed
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter Popup Example'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Status bar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Flutter Popup System Demo',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text('Last interaction: $_lastInteraction'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _simulateMarkerTap,
                      icon: const Icon(Icons.touch_app, size: 16),
                      label: const Text('Test Popup'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => MarkerPopupManager().hidePopup(),
                      icon: const Icon(Icons.close, size: 16),
                      label: const Text('Hide Popup'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Navigation view with popup support
          Expanded(
            child: MapBoxNavigationViewWithPopups(
              options: MapBoxOptions(
                initialLatitude: 37.7749,
                initialLongitude: -122.4194,
                zoom: 12.0,
                enableRefresh: false,
                alternatives: true,
                voiceInstructionsEnabled: false,
                bannerInstructionsEnabled: false,
                mode: MapBoxNavigationMode.driving,
                units: VoiceUnits.imperial,
                simulateRoute: true,
                language: "en",
              ),
              onCreated: _onNavigationViewCreated,
              onRouteEvent: _onRouteEvent,
              markerConfiguration: _markerConfiguration,
              initialViewport: MapViewport(
                center: const LatLng(37.7749, -122.4194),
                zoomLevel: 12.0,
                size: const Size(400, 600), // Will be updated by LayoutBuilder
              ),
              enableCoordinateConversion: true,
            ),
          ),
        ],
      ),
    );
  }

  /// Simulate a marker tap for testing purposes
  void _simulateMarkerTap() {
    if (_markers.isNotEmpty) {
      final marker = _markers[0]; // Tap the first marker
      MarkerPopupManager().showPopupForMarker(
        marker,
        screenPosition: const Offset(200, 300), // Simulated screen position
      );
    }
  }
}