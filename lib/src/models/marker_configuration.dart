import 'package:flutter/material.dart';
import 'static_marker.dart';

/// Configuration for static marker display and behavior
class MarkerConfiguration {
  /// Whether to show markers during navigation
  final bool showDuringNavigation;
  
  /// Whether to show markers in free drive mode
  final bool showInFreeDrive;
  
  /// Whether to show markers on embedded map view
  final bool showOnEmbeddedMap;
  
  /// Maximum distance in kilometers from the current route to show markers
  /// If null, all markers will be shown regardless of route distance
  final double? maxDistanceFromRoute;
  
  /// Minimum zoom level to show markers (markers hidden when zoomed out too far)
  final double minZoomLevel;
  
  /// Whether to enable marker clustering for dense areas
  final bool enableClustering;
  
  /// Maximum number of markers to display at once (for performance)
  final int? maxMarkersToShow;
  
  /// Callback function when a marker is tapped
  final void Function(StaticMarker)? onMarkerTap;
  
  /// Flutter widget builder for popup overlays when markers are tapped
  /// If provided, popups will be shown as Flutter overlays
  final Widget Function(StaticMarker, BuildContext)? popupBuilder;

  /// Duration to show popup before auto-hiding (if popup builder is provided)
  final Duration popupDuration;

  /// Offset from marker position to show popup (if popup builder is provided)
  /// Positive y values move popup down, negative values move it up
  final Offset popupOffset;

  /// Whether to automatically hide popup when user taps elsewhere
  final bool hidePopupOnTapOutside;

  /// Default icon ID to use when marker doesn't specify one
  final String? defaultIconId;
  
  /// Default color to use when marker doesn't specify one
  final Color? defaultColor;

  /// Default size multiplier for markers (1.0 = default, 2.0 = double size)
  final double defaultSize;

  /// Creates a new marker configuration with the given settings
  const MarkerConfiguration({
    this.showDuringNavigation = true,
    this.showInFreeDrive = true,
    this.showOnEmbeddedMap = true,
    this.maxDistanceFromRoute,
    this.minZoomLevel = 10.0,
    this.enableClustering = true,
    this.maxMarkersToShow,
    this.onMarkerTap,
    this.popupBuilder,
    this.popupDuration = const Duration(seconds: 5),
    this.popupOffset = const Offset(0, -60),
    this.hidePopupOnTapOutside = true,
    this.defaultIconId,
    this.defaultColor,
    this.defaultSize = 1.0,
  });

  /// Creates a MarkerConfiguration from a JSON map
  factory MarkerConfiguration.fromJson(Map<String, dynamic> json) {
    return MarkerConfiguration(
      showDuringNavigation: json['showDuringNavigation'] as bool? ?? true,
      showInFreeDrive: json['showInFreeDrive'] as bool? ?? true,
      showOnEmbeddedMap: json['showOnEmbeddedMap'] as bool? ?? true,
      maxDistanceFromRoute: json['maxDistanceFromRoute'] as double?,
      minZoomLevel: json['minZoomLevel'] as double? ?? 10.0,
      enableClustering: json['enableClustering'] as bool? ?? true,
      maxMarkersToShow: json['maxMarkersToShow'] as int?,
      defaultIconId: json['defaultIconId'] as String?,
      defaultColor: json['defaultColor'] != null 
          ? Color(json['defaultColor'] as int) 
          : null,
      defaultSize: json['defaultSize'] as double? ?? 1.0,
    );
  }

  /// Converts the MarkerConfiguration to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'showDuringNavigation': showDuringNavigation,
      'showInFreeDrive': showInFreeDrive,
      'showOnEmbeddedMap': showOnEmbeddedMap,
      'maxDistanceFromRoute': maxDistanceFromRoute,
      'minZoomLevel': minZoomLevel,
      'enableClustering': enableClustering,
      'maxMarkersToShow': maxMarkersToShow,
      'defaultIconId': defaultIconId,
      'defaultColor': defaultColor?.value,
      'defaultSize': defaultSize,
    };
  }

  /// Creates a copy of this configuration with updated fields
  MarkerConfiguration copyWith({
    bool? showDuringNavigation,
    bool? showInFreeDrive,
    bool? showOnEmbeddedMap,
    double? maxDistanceFromRoute,
    double? minZoomLevel,
    bool? enableClustering,
    int? maxMarkersToShow,
    Function(StaticMarker)? onMarkerTap,
    Widget Function(StaticMarker, BuildContext)? popupBuilder,
    Duration? popupDuration,
    Offset? popupOffset,
    bool? hidePopupOnTapOutside,
    String? defaultIconId,
    Color? defaultColor,
    double? defaultSize,
  }) {
    return MarkerConfiguration(
      showDuringNavigation: showDuringNavigation ?? this.showDuringNavigation,
      showInFreeDrive: showInFreeDrive ?? this.showInFreeDrive,
      showOnEmbeddedMap: showOnEmbeddedMap ?? this.showOnEmbeddedMap,
      maxDistanceFromRoute: maxDistanceFromRoute ?? this.maxDistanceFromRoute,
      minZoomLevel: minZoomLevel ?? this.minZoomLevel,
      enableClustering: enableClustering ?? this.enableClustering,
      maxMarkersToShow: maxMarkersToShow ?? this.maxMarkersToShow,
      onMarkerTap: onMarkerTap ?? this.onMarkerTap,
      popupBuilder: popupBuilder ?? this.popupBuilder,
      popupDuration: popupDuration ?? this.popupDuration,
      popupOffset: popupOffset ?? this.popupOffset,
      hidePopupOnTapOutside: hidePopupOnTapOutside ?? this.hidePopupOnTapOutside,
      defaultIconId: defaultIconId ?? this.defaultIconId,
      defaultColor: defaultColor ?? this.defaultColor,
      defaultSize: defaultSize ?? this.defaultSize,
    );
  }

  @override
  String toString() {
    return 'MarkerConfiguration('
        'showDuringNavigation: $showDuringNavigation, '
        'showInFreeDrive: $showInFreeDrive, '
        'showOnEmbeddedMap: $showOnEmbeddedMap, '
        'maxDistanceFromRoute: $maxDistanceFromRoute, '
        'minZoomLevel: $minZoomLevel, '
        'enableClustering: $enableClustering, '
        'maxMarkersToShow: $maxMarkersToShow)';
  }
} 