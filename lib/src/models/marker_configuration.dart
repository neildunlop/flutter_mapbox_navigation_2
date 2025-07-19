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
  final Function(StaticMarker)? onMarkerTap;
  
  /// Default icon ID to use when marker doesn't specify one
  final String? defaultIconId;
  
  /// Default color to use when marker doesn't specify one
  final Color? defaultColor;

  const MarkerConfiguration({
    this.showDuringNavigation = true,
    this.showInFreeDrive = true,
    this.showOnEmbeddedMap = true,
    this.maxDistanceFromRoute,
    this.minZoomLevel = 10.0,
    this.enableClustering = true,
    this.maxMarkersToShow,
    this.onMarkerTap,
    this.defaultIconId,
    this.defaultColor,
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
    String? defaultIconId,
    Color? defaultColor,
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
      defaultIconId: defaultIconId ?? this.defaultIconId,
      defaultColor: defaultColor ?? this.defaultColor,
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