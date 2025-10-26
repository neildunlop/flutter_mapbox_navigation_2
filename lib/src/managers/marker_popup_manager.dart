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
  
  bool _disposed = false;

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
    try {
      print('🎯 MarkerPopupManager.showPopupForMarker called for: ${marker.title}');
      print('🎯 Current state - disposed: $_disposed, hasListeners: $hasListeners');
      
      // Cancel any existing auto-hide timer
      _autoHideTimer?.cancel();
      
      _selectedMarker = marker;
      
      if (screenPosition != null) {
        _markerScreenPosition = screenPosition;
        print('🎯 Using provided screen position: $screenPosition');
      } else {
        _updateMarkerScreenPosition();
        print('🎯 Updated marker screen position: $_markerScreenPosition');
      }
      
      // Schedule auto-hide if configured
      if (_configuration?.popupDuration != null && _configuration!.popupDuration.inMilliseconds > 0) {
        _autoHideTimer = Timer(_configuration!.popupDuration, () {
          hidePopup();
        });
        print('🎯 Auto-hide scheduled for ${_configuration!.popupDuration}');
      }
      
      // Always notify listeners, but safely
      try {
        notifyListeners();
        print('✅ Listeners notified successfully');
      } catch (e) {
        print('❌ Error notifying listeners: $e');
      }
      
      // NOTE: Don't call onMarkerTap callback here to avoid infinite loops
      // The callback is already handled by the caller (platform channel)
    } catch (e) {
      print('Error showing popup (manager may be disposed): $e');
    }
  }
  
  /// Hide the current popup
  void hidePopup() {
    try {
      _autoHideTimer?.cancel();
      _autoHideTimer = null;
      
      _selectedMarker = null;
      _markerScreenPosition = null;
      
      // Always notify listeners, but safely
      try {
        notifyListeners();
        print('✅ Listeners notified for hidePopup');
      } catch (e) {
        print('❌ Error notifying listeners in hidePopup: $e');
      }
    } catch (e) {
      print('Error hiding popup (manager may be disposed): $e');
    }
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
  
  /// Clean up resources without disposing the singleton
  void cleanup() {
    _autoHideTimer?.cancel();
    _autoHideTimer = null;
    _selectedMarker = null;
    _markerScreenPosition = null;
    _mapViewport = null;
    _configuration = null;
  }
  
  /// Override dispose to prevent the singleton from being disposed
  @override
  void dispose() {
    // Don't actually dispose the singleton, just mark it as disposed for debugging
    _disposed = true;
    // Don't call super.dispose() to prevent actual disposal
    print('MarkerPopupManager dispose() called but prevented (singleton protection)');
  }
  
  /// Reset the disposed state and reinitialize if needed
  void reset() {
    _disposed = false;
    cleanup();
  }
  
  /// Method to actually dispose when app shuts down (not used in normal flow)
  void _actualDispose() {
    cleanup();
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
    _popupManager.reset(); // Reset in case it was previously marked as disposed
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
    // Just hide any active popup, don't cleanup or dispose the singleton
    _popupManager.hidePopup();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print('🎯 MarkerPopupProvider building - hasPopupBuilder: ${widget.configuration.popupBuilder != null}');
    print('🎯 Selected marker: ${_popupManager.selectedMarker?.title ?? "none"}');
    print('🎯 Screen position: ${_popupManager.markerScreenPosition}');
    
    if (widget.configuration.popupBuilder == null) {
      // No popup builder provided, just return the child
      print('❌ No popup builder provided, returning child only');
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