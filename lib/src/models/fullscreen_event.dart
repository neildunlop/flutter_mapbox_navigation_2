import 'dart:convert';
import 'static_marker.dart';

/// Event data for full-screen navigation interactions
class FullScreenEvent {
  final String type;
  final String mode;
  final StaticMarker? marker;
  final double? latitude;
  final double? longitude;
  final Map<String, dynamic>? metadata;

  const FullScreenEvent({
    required this.type,
    required this.mode,
    this.marker,
    this.latitude,
    this.longitude,
    this.metadata,
  });

  /// Creates a FullScreenEvent from JSON data
  factory FullScreenEvent.fromJson(String jsonString) {
    try {
      final dynamic decoded = jsonDecode(jsonString);
      final Map<String, dynamic> json = Map<String, dynamic>.from(decoded as Map);
      
      StaticMarker? marker;
      
      // Check for flattened marker data (new format from Android)
      if (json.keys.any((key) => key.startsWith('marker_'))) {
        // Extract flattened marker fields
        final markerMap = <String, dynamic>{};
        json.forEach((key, value) {
          if (key.startsWith('marker_')) {
            final markerKey = key.substring(7); // Remove 'marker_' prefix
            markerMap[markerKey] = value;
          }
        });
        marker = StaticMarker.fromJson(markerMap);
      } else if (json['marker'] != null) {
        // Handle legacy nested marker format
        if (json['marker'] is String) {
          // If marker is a JSON string, decode it first
          final markerJson = jsonDecode(json['marker'] as String);
          final markerMap = Map<String, dynamic>.from(markerJson as Map);
          marker = StaticMarker.fromJson(markerMap);
        } else if (json['marker'] is Map) {
          // If marker is already a Map, convert it to Map<String, dynamic>
          final markerMap = Map<String, dynamic>.from(json['marker'] as Map);
          marker = StaticMarker.fromJson(markerMap);
        }
      }
      
      return FullScreenEvent(
        type: json['type'] as String,
        mode: json['mode'] as String,
        marker: marker,
        latitude: json['latitude'] as double?,
        longitude: json['longitude'] as double?,
        metadata: json['metadata'] as Map<String, dynamic>?,
      );
    } catch (e) {
      throw FormatException('Failed to parse FullScreenEvent: $e');
    }
  }

  /// Converts this event to a JSON string
  String toJson() {
    final Map<String, dynamic> json = {
      'type': type,
      'mode': mode,
    };

    if (marker != null) {
      json['marker'] = marker!.toJson();
    }

    if (latitude != null) {
      json['latitude'] = latitude;
    }

    if (longitude != null) {
      json['longitude'] = longitude;
    }

    if (metadata != null) {
      json['metadata'] = metadata;
    }

    return jsonEncode(json);
  }

  /// Converts this event to a Map
  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'mode': mode,
      if (marker != null) 'marker': marker!.toJson(),
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (metadata != null) 'metadata': metadata,
    };
  }

  @override
  String toString() {
    return 'FullScreenEvent{type: $type, mode: $mode, marker: ${marker?.id}, lat: $latitude, lng: $longitude}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FullScreenEvent &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          mode == other.mode &&
          marker == other.marker &&
          latitude == other.latitude &&
          longitude == other.longitude;

  @override
  int get hashCode =>
      type.hashCode ^
      mode.hashCode ^
      marker.hashCode ^
      latitude.hashCode ^
      longitude.hashCode;
}