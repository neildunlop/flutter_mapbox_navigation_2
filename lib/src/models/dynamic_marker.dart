import 'package:flutter/material.dart';
import 'package:flutter_mapbox_navigation/src/utilities/coordinate_converter.dart';

// Re-export LatLng for convenience so users can import from dynamic_marker.dart
export 'package:flutter_mapbox_navigation/src/utilities/coordinate_converter.dart'
    show LatLng;

/// Represents the current state of a dynamic marker.
enum DynamicMarkerState {
  /// Marker is actively receiving position updates.
  tracking,

  /// Marker is currently animating between positions.
  animating,

  /// Entity has stopped moving (speed below threshold).
  stationary,

  /// No update received within the stale threshold.
  stale,

  /// No update received for an extended period.
  offline,

  /// Marker is about to be automatically removed due to expiration.
  expired;

  /// Creates a DynamicMarkerState from a string value.
  static DynamicMarkerState fromString(String value) {
    return DynamicMarkerState.values.firstWhere(
      (state) => state.name == value,
      orElse: () => DynamicMarkerState.tracking,
    );
  }
}

/// Represents a marker that can move and animate across the map.
///
/// The marker's position is updated via [DynamicMarkerPositionUpdate] events,
/// and the plugin handles smooth animation between positions.
class DynamicMarker {
  /// Unique identifier for this marker.
  final String id;

  /// Current latitude coordinate.
  final double latitude;

  /// Current longitude coordinate.
  final double longitude;

  /// Previous latitude coordinate (used for interpolation).
  final double? previousLatitude;

  /// Previous longitude coordinate (used for interpolation).
  final double? previousLongitude;

  /// Current heading/bearing in degrees (0-360, where 0 = north).
  final double? heading;

  /// Current speed in meters per second.
  final double? speed;

  /// Timestamp of the last position update.
  final DateTime lastUpdated;

  /// Display title for the marker.
  final String title;

  /// Category string for grouping and default styling.
  final String category;

  /// Icon identifier from the standard marker icon set.
  final String? iconId;

  /// Custom color for the marker.
  final Color? customColor;

  /// Arbitrary metadata associated with this marker.
  final Map<String, dynamic>? metadata;

  /// Current state of the marker.
  final DynamicMarkerState state;

  /// Whether to render a trail/breadcrumb behind this marker.
  final bool showTrail;

  /// Maximum number of trail points to retain.
  final int trailLength;

  /// Historical positions for trail rendering.
  final List<LatLng>? positionHistory;

  /// Creates a dynamic marker.
  DynamicMarker({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.title,
    required this.category,
    this.previousLatitude,
    this.previousLongitude,
    this.heading,
    this.speed,
    DateTime? lastUpdated,
    this.iconId,
    this.customColor,
    this.metadata,
    this.state = DynamicMarkerState.tracking,
    this.showTrail = false,
    this.trailLength = 50,
    this.positionHistory,
  }) : lastUpdated = lastUpdated ?? DateTime.now();

  /// Returns the current position as a [LatLng].
  LatLng get position => LatLng(latitude, longitude);

  /// Returns the previous position as a [LatLng], or null if not set.
  LatLng? get previousPosition {
    if (previousLatitude != null && previousLongitude != null) {
      return LatLng(previousLatitude!, previousLongitude!);
    }
    return null;
  }

  /// Creates a DynamicMarker from a JSON map.
  factory DynamicMarker.fromJson(Map<String, dynamic> json) {
    List<LatLng>? history;
    if (json['positionHistory'] != null) {
      history = (json['positionHistory'] as List<dynamic>)
          .map((item) => LatLng.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList();
    }

    return DynamicMarker(
      id: json['id'] as String? ?? '',
      latitude: json['latitude'] != null
          ? (json['latitude'] as num).toDouble()
          : 0.0,
      longitude: json['longitude'] != null
          ? (json['longitude'] as num).toDouble()
          : 0.0,
      title: json['title'] as String? ?? '',
      category: json['category'] as String? ?? '',
      previousLatitude: json['previousLatitude'] != null
          ? (json['previousLatitude'] as num).toDouble()
          : null,
      previousLongitude: json['previousLongitude'] != null
          ? (json['previousLongitude'] as num).toDouble()
          : null,
      heading:
          json['heading'] != null ? (json['heading'] as num).toDouble() : null,
      speed: json['speed'] != null ? (json['speed'] as num).toDouble() : null,
      lastUpdated: json['lastUpdated'] != null
          ? DateTime.parse(json['lastUpdated'] as String)
          : null,
      iconId: json['iconId'] as String?,
      customColor: json['customColor'] != null
          ? Color(json['customColor'] as int)
          : null,
      metadata: json['metadata'] != null
          ? Map<String, dynamic>.from(json['metadata'] as Map)
          : null,
      state: json['state'] != null
          ? DynamicMarkerState.fromString(json['state'] as String)
          : DynamicMarkerState.tracking,
      showTrail: json['showTrail'] as bool? ?? false,
      trailLength: json['trailLength'] as int? ?? 50,
      positionHistory: history,
    );
  }

  /// Converts this DynamicMarker to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'latitude': latitude,
      'longitude': longitude,
      'title': title,
      'category': category,
      'previousLatitude': previousLatitude,
      'previousLongitude': previousLongitude,
      'heading': heading,
      'speed': speed,
      'lastUpdated': lastUpdated.toIso8601String(),
      'iconId': iconId,
      'customColor': customColor?.value,
      'metadata': metadata,
      'state': state.name,
      'showTrail': showTrail,
      'trailLength': trailLength,
      'positionHistory': positionHistory?.map((p) => p.toJson()).toList(),
    };
  }

  /// Creates a copy of this marker with updated fields.
  DynamicMarker copyWith({
    String? id,
    double? latitude,
    double? longitude,
    String? title,
    String? category,
    double? previousLatitude,
    double? previousLongitude,
    double? heading,
    double? speed,
    DateTime? lastUpdated,
    String? iconId,
    Color? customColor,
    Map<String, dynamic>? metadata,
    DynamicMarkerState? state,
    bool? showTrail,
    int? trailLength,
    List<LatLng>? positionHistory,
  }) {
    return DynamicMarker(
      id: id ?? this.id,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      title: title ?? this.title,
      category: category ?? this.category,
      previousLatitude: previousLatitude ?? this.previousLatitude,
      previousLongitude: previousLongitude ?? this.previousLongitude,
      heading: heading ?? this.heading,
      speed: speed ?? this.speed,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      iconId: iconId ?? this.iconId,
      customColor: customColor ?? this.customColor,
      metadata: metadata ?? this.metadata,
      state: state ?? this.state,
      showTrail: showTrail ?? this.showTrail,
      trailLength: trailLength ?? this.trailLength,
      positionHistory: positionHistory ?? this.positionHistory,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DynamicMarker && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'DynamicMarker(id: $id, title: $title, category: $category, '
        'lat: $latitude, lng: $longitude, state: ${state.name})';
  }
}
