import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Utility class for converting geographic coordinates to screen positions
/// This is a simplified implementation that works with basic map projections
class CoordinateConverter {
  /// Convert latitude/longitude to screen position for a given map viewport
  /// 
  /// [latitude] The latitude coordinate
  /// [longitude] The longitude coordinate  
  /// [mapCenter] The center point of the map viewport
  /// [mapSize] The size of the map widget
  /// [zoomLevel] The current zoom level of the map
  /// 
  /// Returns the screen position as an Offset, or null if the coordinate is not visible
  static Offset? coordinateToScreen({
    required double latitude,
    required double longitude,
    required LatLng mapCenter,
    required Size mapSize,
    required double zoomLevel,
  }) {
    // Convert to Web Mercator projection
    final markerMercator = _latLngToMercator(latitude, longitude);
    final centerMercator = _latLngToMercator(mapCenter.latitude, mapCenter.longitude);
    
    // Calculate scale factor based on zoom level
    final scale = math.pow(2, zoomLevel);
    
    // Calculate pixel coordinates relative to map center
    final pixelsPerMeter = scale * 156543.03392; // Web Mercator scale at equator
    final deltaX = (markerMercator.dx - centerMercator.dx) * pixelsPerMeter;
    final deltaY = (markerMercator.dy - centerMercator.dy) * pixelsPerMeter;
    
    // Convert to screen coordinates
    final screenX = (mapSize.width / 2) + deltaX;
    final screenY = (mapSize.height / 2) - deltaY; // Y axis is flipped in screen coordinates
    
    // Check if coordinate is within viewport
    if (screenX < -50 || screenX > mapSize.width + 50 ||
        screenY < -50 || screenY > mapSize.height + 50) {
      return null; // Outside visible area with some buffer
    }
    
    return Offset(screenX, screenY);
  }
  
  /// Convert lat/lng to Web Mercator coordinates
  static Offset _latLngToMercator(double latitude, double longitude) {
    final x = longitude * 20037508.34 / 180;
    final y = math.log(math.tan((90 + latitude) * math.pi / 360)) / (math.pi / 180);
    final mercatorY = y * 20037508.34 / 180;
    
    return Offset(x, mercatorY);
  }
  
  /// Estimate screen position based on simple linear interpolation
  /// This is a fallback method when precise projection is not available
  static Offset estimateScreenPosition({
    required double latitude,
    required double longitude,
    required LatLng mapCenter,
    required Size mapSize,
    required double zoomLevel,
  }) {
    // Simple linear approximation
    final latDelta = latitude - mapCenter.latitude;
    final lngDelta = longitude - mapCenter.longitude;
    
    // Scale factor based on zoom (rough approximation)
    final scale = math.pow(2, zoomLevel - 10).clamp(0.1, 10.0);
    
    // Convert to screen pixels (rough approximation)
    final metersPerDegreeLat = 111320.0; // Approximately constant
    final metersPerDegreeLng = 111320.0 * math.cos(mapCenter.latitude * math.pi / 180);
    
    final pixelsPerMeterLat = mapSize.height / (20037508.34 * 2) * scale;
    final pixelsPerMeterLng = mapSize.width / (20037508.34 * 2) * scale;
    
    final screenX = (mapSize.width / 2) + (lngDelta * metersPerDegreeLng * pixelsPerMeterLng);
    final screenY = (mapSize.height / 2) - (latDelta * metersPerDegreeLat * pixelsPerMeterLat);
    
    return Offset(screenX, screenY);
  }
}

/// Simple data class for latitude/longitude pairs
class LatLng {
  final double latitude;
  final double longitude;

  const LatLng(this.latitude, this.longitude);

  /// Creates a LatLng from a JSON map.
  factory LatLng.fromJson(Map<String, dynamic> json) {
    return LatLng(
      (json['latitude'] as num).toDouble(),
      (json['longitude'] as num).toDouble(),
    );
  }

  /// Converts this LatLng to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  @override
  String toString() => 'LatLng($latitude, $longitude)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LatLng &&
          runtimeType == other.runtimeType &&
          latitude == other.latitude &&
          longitude == other.longitude;

  @override
  int get hashCode => latitude.hashCode ^ longitude.hashCode;
}

/// Map viewport information needed for coordinate conversion
class MapViewport {
  final LatLng center;
  final double zoomLevel;
  final Size size;
  final double bearing;
  final double tilt;
  
  const MapViewport({
    required this.center,
    required this.zoomLevel,
    required this.size,
    this.bearing = 0.0,
    this.tilt = 0.0,
  });
  
  /// Convert a coordinate to screen position within this viewport
  Offset? coordinateToScreen(double latitude, double longitude) {
    return CoordinateConverter.coordinateToScreen(
      latitude: latitude,
      longitude: longitude,
      mapCenter: center,
      mapSize: size,
      zoomLevel: zoomLevel,
    );
  }
  
  /// Check if a coordinate is visible within this viewport (with buffer)
  bool isCoordinateVisible(double latitude, double longitude, {double buffer = 0.1}) {
    final screenPos = coordinateToScreen(latitude, longitude);
    if (screenPos == null) return false;
    
    return screenPos.dx >= -buffer * size.width &&
           screenPos.dx <= size.width * (1 + buffer) &&
           screenPos.dy >= -buffer * size.height &&
           screenPos.dy <= size.height * (1 + buffer);
  }
}