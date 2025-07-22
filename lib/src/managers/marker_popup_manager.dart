import 'dart:async';
import 'package:flutter/material.dart';
import '../models/static_marker.dart';
import '../models/marker_configuration.dart';
import '../utilities/coordinate_converter.dart';
import '../widgets/marker_popup_overlay.dart';

/// Manages the state and lifecycle of marker popups
class MarkerPopupManager extends ChangeNotifier {
  static final MarkerPopupManager _instance = MarkerPopupManager._internal();
  factory MarkerPopupManager() => _instance;
  MarkerPopupManager._internal();

  /// Currently selected marker for popup display
  StaticMarker? _selectedMarker;
  
  /// Screen position of the selected marker
  Offset? _markerScreenPosition;
  
  /// Current map viewport information
  MapViewport? _mapViewport;
  
  /// Current marker configuration
  MarkerConfiguration? _configuration;
  
  /// Timer for auto-hiding popup
  Timer? _autoHideTimer;
  
  /// Whether popup system is enabled
  bool _isEnabled = true;
  
  /// Getters
  StaticMarker? get selectedMarker => _selectedMarker;
  Offset? get markerScreenPosition => _markerScreenPosition;
  bool get hasActivePopup => _selectedMarker != null && _markerScreenPosition != null;
  bool get isEnabled => _isEnabled;
  
  /// Update the map viewport information
  void updateMapViewport(MapViewport viewport) {
    _mapViewport = viewport;
    
    // Recalculate marker position if we have an active popup
    if (_selectedMarker != null) {
      _updateMarkerScreenPosition();
    }
  }
  
  /// Set the marker configuration
  void setConfiguration(MarkerConfiguration configuration) {
    _configuration = configuration;
  }
  
  /// Show popup for a specific marker
  void showPopupForMarker(StaticMarker marker, {Offset? screenPosition}) {
    // Cancel any existing auto-hide timer
    _autoHideTimer?.cancel();
    
    _selectedMarker = marker;
    
    if (screenPosition != null) {
      _markerScreenPosition = screenPosition;
    } else {
      _updateMarkerScreenPosition();
    }
    
    // Schedule auto-hide if configured
    if (_configuration?.popupDuration != null && _configuration!.popupDuration.inMilliseconds > 0) {
      _autoHideTimer = Timer(_configuration!.popupDuration, () {
        hidePopup();
      });
    }
    
    notifyListeners();
    
    // NOTE: Don't call onMarkerTap callback here to avoid infinite loops
    // The callback is already handled by the caller (platform channel)
  }
  
  /// Hide the current popup
  void hidePopup() {
    _autoHideTimer?.cancel();
    _autoHideTimer = null;
    
    _selectedMarker = null;
    _markerScreenPosition = null;
    
    notifyListeners();
  }
  
  /// Update the screen position of the current marker based on map viewport
  void _updateMarkerScreenPosition() {
    if (_selectedMarker == null || _mapViewport == null) {
      _markerScreenPosition = null;
      return;
    }
    
    _markerScreenPosition = _mapViewport!.coordinateToScreen(
      _selectedMarker!.latitude,
      _selectedMarker!.longitude,
    );
    
    // Hide popup if marker moved off screen
    if (_markerScreenPosition == null) {
      hidePopup();
    }
  }
  
  /// Enable or disable the popup system
  void setEnabled(bool enabled) {
    if (!enabled && _selectedMarker != null) {
      hidePopup();
    }
    _isEnabled = enabled;
  }
  
  /// Handle marker tap events from the platform
  void handleMarkerTap(StaticMarker marker, {Offset? screenPosition}) {
    if (!_isEnabled) return;
    
    // If the same marker is tapped, hide the popup
    if (_selectedMarker?.id == marker.id) {
      hidePopup();
    } else {
      showPopupForMarker(marker, screenPosition: screenPosition);
    }
  }
  
  /// Check if a marker is currently selected
  bool isMarkerSelected(String markerId) {
    return _selectedMarker?.id == markerId;
  }
  
  /// Get screen position for a given marker coordinate
  Offset? getScreenPositionForMarker(StaticMarker marker) {
    if (_mapViewport == null) return null;
    
    return _mapViewport!.coordinateToScreen(
      marker.latitude,
      marker.longitude,
    );
  }
  
  /// Dispose resources
  @override
  void dispose() {
    _autoHideTimer?.cancel();
    super.dispose();
  }
}

/// Widget that provides marker popup functionality to its child
class MarkerPopupProvider extends StatefulWidget {
  final Widget child;
  final MarkerConfiguration configuration;
  
  const MarkerPopupProvider({
    super.key,
    required this.child,
    required this.configuration,
  });

  @override
  State<MarkerPopupProvider> createState() => _MarkerPopupProviderState();
}

class _MarkerPopupProviderState extends State<MarkerPopupProvider> {
  late MarkerPopupManager _popupManager;
  
  @override
  void initState() {
    super.initState();
    _popupManager = MarkerPopupManager();
    _popupManager.setConfiguration(widget.configuration);
    _popupManager.addListener(_onPopupStateChanged);
  }
  
  @override
  void didUpdateWidget(MarkerPopupProvider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.configuration != oldWidget.configuration) {
      _popupManager.setConfiguration(widget.configuration);
    }
  }
  
  void _onPopupStateChanged() {
    if (mounted) {
      setState(() {}); // Rebuild when popup state changes
    }
  }
  
  @override
  void dispose() {
    _popupManager.removeListener(_onPopupStateChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.configuration.popupBuilder == null) {
      // No popup builder provided, just return the child
      return widget.child;
    }
    
    return MarkerPopupOverlay(
      configuration: widget.configuration,
      selectedMarker: _popupManager.selectedMarker,
      markerScreenPosition: _popupManager.markerScreenPosition,
      onHidePopup: _popupManager.hidePopup,
      child: widget.child,
    );
  }
}

/// Extension methods for easier access to popup functionality
extension MarkerPopupExtensions on StaticMarker {
  /// Show popup for this marker
  void showPopup({Offset? screenPosition}) {
    MarkerPopupManager().showPopupForMarker(this, screenPosition: screenPosition);
  }
  
  /// Check if this marker currently has a popup shown
  bool get hasPopupShown => MarkerPopupManager().isMarkerSelected(id);
}