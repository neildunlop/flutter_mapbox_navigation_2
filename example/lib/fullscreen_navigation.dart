import 'package:flutter/material.dart';
import 'package:flutter_mapbox_navigation/flutter_mapbox_navigation.dart';

/// Full-screen Flutter navigation route
/// Uses the same embedded navigation widget in full-screen mode
class FullScreenNavigationPage extends StatefulWidget {
  final List<WayPoint> wayPoints;
  final MapBoxOptions options;
  final MarkerConfiguration? markerConfiguration;
  final List<StaticMarker>? markers;

  const FullScreenNavigationPage({
    super.key,
    required this.wayPoints,
    required this.options,
    this.markerConfiguration,
    this.markers,
  });

  @override
  State<FullScreenNavigationPage> createState() => _FullScreenNavigationPageState();
}

class _FullScreenNavigationPageState extends State<FullScreenNavigationPage> {
  MapBoxNavigationViewController? _controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // No app bar for true full-screen experience
      body: SafeArea(
        child: Stack(
          children: [
            // Full-screen navigation view with popup support
            SizedBox.expand(
              child: MapBoxNavigationViewWithPopups(
                options: widget.options,
                onRouteEvent: _onRouteEvent,
                onCreated: _onNavigationViewCreated,
                markerConfiguration: widget.markerConfiguration ?? MarkerConfiguration(),
                initialViewport: MapViewport(
                  center: LatLng(
                    widget.options.initialLatitude ?? 37.7749,
                    widget.options.initialLongitude ?? -122.4194,
                  ),
                  zoomLevel: widget.options.zoom ?? 15.0,
                  size: MediaQuery.of(context).size,
                ),
                enableCoordinateConversion: true,
              ),
            ),
            
            // Close button overlay
            Positioned(
              top: 16,
              right: 16,
              child: FloatingActionButton.small(
                heroTag: "close_fullscreen", // Prevent hero animation conflicts
                onPressed: () => Navigator.of(context).pop(),
                backgroundColor: Colors.black.withOpacity(0.7),
                child: const Icon(Icons.close, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onNavigationViewCreated(MapBoxNavigationViewController controller) async {
    _controller = controller;
    await controller.initialize();
    
    // Build route and start navigation
    await controller.buildRoute(
      wayPoints: widget.wayPoints,
      options: widget.options,
    );
    
    // Start navigation with built route
    await controller.startNavigation(options: widget.options);
    
    // Add markers if provided
    if (widget.markers != null && widget.markerConfiguration != null) {
      await MapBoxNavigation.instance.addStaticMarkers(
        markers: widget.markers!,
        configuration: widget.markerConfiguration!,
      );
    }
  }

  void _onRouteEvent(dynamic event) {
    // Handle route events (same as embedded view)
    print('Full-screen route event: $event');
  }

  @override
  void dispose() {
    // Clean up controller
    _controller?.dispose();
    
    // Just hide any active popup, don't cleanup the singleton
    MarkerPopupManager().hidePopup();
    
    super.dispose();
  }
}