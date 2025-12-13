import 'dart:async';
import 'package:flutter/material.dart';
import '../embedded/view.dart';
import '../embedded/controller.dart';
import '../models/models.dart';
import '../managers/marker_popup_manager.dart';
import '../utilities/coordinate_converter.dart';

/// Enhanced navigation view that supports marker popup overlays
class MapBoxNavigationViewWithPopups extends StatefulWidget {
  /// MapBox options for the navigation view
  final MapBoxOptions? options;
  
  /// Callback when the navigation view is created
  final OnNavigationViewCreatedCallBack? onCreated;
  
  /// Callback for route events
  final ValueSetter<RouteEvent>? onRouteEvent;
  
  /// Configuration for marker display and popup behavior
  final MarkerConfiguration? markerConfiguration;
  
  /// Optional initial map viewport (for coordinate conversion)
  final MapViewport? initialViewport;
  
  /// Whether to enable coordinate conversion estimates
  final bool enableCoordinateConversion;
  
  const MapBoxNavigationViewWithPopups({
    super.key,
    this.options,
    this.onCreated,
    this.onRouteEvent,
    this.markerConfiguration,
    this.initialViewport,
    this.enableCoordinateConversion = true,
  });

  @override
  State<MapBoxNavigationViewWithPopups> createState() => _MapBoxNavigationViewWithPopupsState();
}

class _MapBoxNavigationViewWithPopupsState extends State<MapBoxNavigationViewWithPopups> {
  // ignore: unused_field
  MapBoxNavigationViewController? _controller;
  MarkerPopupManager? _popupManager;
  StreamSubscription<StaticMarker>? _markerTapSubscription;
  
  // Track map state for coordinate conversion
  MapViewport? _currentViewport;
  Size _mapSize = Size.zero;
  
  @override
  void initState() {
    super.initState();
    _initializePopupManager();
  }
  
  void _initializePopupManager() {
    _popupManager = MarkerPopupManager();
    
    if (widget.markerConfiguration != null) {
      _popupManager!.setConfiguration(widget.markerConfiguration!);
    }
    
    // Set initial viewport if provided
    if (widget.initialViewport != null) {
      _popupManager!.updateMapViewport(widget.initialViewport!);
      _currentViewport = widget.initialViewport;
    }
  }
  
  @override
  void didUpdateWidget(MapBoxNavigationViewWithPopups oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.markerConfiguration != oldWidget.markerConfiguration) {
      if (widget.markerConfiguration != null) {
        _popupManager?.setConfiguration(widget.markerConfiguration!);
      }
    }
  }
  
  void _onNavigationViewCreated(MapBoxNavigationViewController controller) {
    _controller = controller;
    
    // Set up marker tap listener
    _setupMarkerTapListener();
    
    // Call the original callback
    widget.onCreated?.call(controller);
  }
  
  void _setupMarkerTapListener() {
    // Listen for marker tap events through the existing navigation system
    // This integrates with the platform channel marker tap events
    // TODO: This needs to be connected to the actual platform marker events
    
    // For now, we'll set up a listener that can be triggered manually
    // In a real implementation, this would connect to platform channel events
  }
  
  void _onRouteEvent(RouteEvent event) {
    // Update map viewport information when route events occur
    _updateMapViewport(event);
    
    // Call the original callback
    widget.onRouteEvent?.call(event);
  }
  
  void _updateMapViewport(RouteEvent event) {
    if (!widget.enableCoordinateConversion) return;
    
    // Extract viewport information from route event if available
    // This is a simplified implementation - in practice, you'd get this from platform
    if (_currentViewport != null && _mapSize != Size.zero) {
      final updatedViewport = MapViewport(
        center: _currentViewport!.center,
        zoomLevel: _currentViewport!.zoomLevel,
        size: _mapSize,
        bearing: _currentViewport!.bearing,
        tilt: _currentViewport!.tilt,
      );
      
      _popupManager?.updateMapViewport(updatedViewport);
    }
  }
  
  /// Manually trigger a marker tap for testing purposes
  /// In production, this would be called automatically by platform events
  void triggerMarkerTap(StaticMarker marker) {
    if (_popupManager == null || widget.markerConfiguration?.popupBuilder == null) {
      return;
    }
    
    // Estimate screen position if we have viewport information
    Offset? screenPosition;
    if (_currentViewport != null && widget.enableCoordinateConversion) {
      screenPosition = _currentViewport!.coordinateToScreen(
        marker.latitude,
        marker.longitude,
      );
    }
    
    _popupManager!.handleMarkerTap(marker, screenPosition: screenPosition);
  }
  
  /// Update the map viewport manually (useful for testing)
  void updateViewport(MapViewport viewport) {
    _currentViewport = viewport;
    _popupManager?.updateMapViewport(viewport);
  }
  
  @override
  void dispose() {
    _markerTapSubscription?.cancel();
    _popupManager?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _mapSize = constraints.biggest;
        
        // Update viewport size if we have one
        if (_currentViewport != null) {
          final updatedViewport = MapViewport(
            center: _currentViewport!.center,
            zoomLevel: _currentViewport!.zoomLevel,
            size: _mapSize,
            bearing: _currentViewport!.bearing,
            tilt: _currentViewport!.tilt,
          );
          
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _popupManager?.updateMapViewport(updatedViewport);
          });
        }
        
        Widget navigationView = MapBoxNavigationView(
          options: widget.options,
          onCreated: _onNavigationViewCreated,
          onRouteEvent: _onRouteEvent,
        );
        
        // Wrap with popup overlay if configuration is provided
        if (widget.markerConfiguration?.popupBuilder != null) {
          return MarkerPopupProvider(
            configuration: widget.markerConfiguration!,
            child: navigationView,
          );
        }
        
        return navigationView;
      },
    );
  }
}

/// Extension methods for easier integration with existing navigation views
extension MapBoxNavigationViewPopupExtensions on MapBoxNavigationViewController {
  /// Trigger a marker popup programmatically
  /// This can be used to show popups when markers are tapped
  void showMarkerPopup(StaticMarker marker, {Offset? screenPosition}) {
    MarkerPopupManager().showPopupForMarker(marker, screenPosition: screenPosition);
  }
  
  /// Hide any currently displayed popup
  void hideMarkerPopup() {
    MarkerPopupManager().hidePopup();
  }
  
  /// Update the map viewport for accurate popup positioning
  void updatePopupViewport(MapViewport viewport) {
    MarkerPopupManager().updateMapViewport(viewport);
  }
}

/// Helper widget that provides easy access to marker popup functionality
class MarkerPopupIntegration extends StatefulWidget {
  /// The navigation view to wrap
  final Widget child;
  
  /// List of markers that can show popups
  final List<StaticMarker> markers;
  
  /// Configuration for popup display
  final MarkerConfiguration configuration;
  
  /// Callback when a marker is tapped (before popup is shown)
  final void Function(StaticMarker)? onMarkerTap;
  
  const MarkerPopupIntegration({
    super.key,
    required this.child,
    required this.markers,
    required this.configuration,
    this.onMarkerTap,
  });

  @override
  State<MarkerPopupIntegration> createState() => _MarkerPopupIntegrationState();
}

class _MarkerPopupIntegrationState extends State<MarkerPopupIntegration> {
  late MarkerPopupManager _popupManager;
  
  @override
  void initState() {
    super.initState();
    _popupManager = MarkerPopupManager();
    _popupManager.setConfiguration(widget.configuration);
  }
  
  @override
  void didUpdateWidget(MarkerPopupIntegration oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.configuration != oldWidget.configuration) {
      _popupManager.setConfiguration(widget.configuration);
    }
  }
  
  /// Find marker by ID and trigger popup
  void showPopupForMarkerId(String markerId) {
    final marker = widget.markers.cast<StaticMarker?>().firstWhere(
      (m) => m?.id == markerId,
      orElse: () => null,
    );
    
    if (marker != null) {
      widget.onMarkerTap?.call(marker);
      _popupManager.showPopupForMarker(marker);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MarkerPopupProvider(
      configuration: widget.configuration,
      child: widget.child,
    );
  }
}