/// Represents a position update for a dynamic marker.
///
/// These updates are typically received from an external data source
/// (WebSocket, Firebase, MQTT, etc.) and converted to this format
/// before being passed to the plugin.
class DynamicMarkerPositionUpdate {
  /// The marker ID this update applies to.
  final String markerId;

  /// New latitude coordinate.
  final double latitude;

  /// New longitude coordinate.
  final double longitude;

  /// New heading in degrees (0-360, north = 0).
  final double? heading;

  /// Current speed in meters per second.
  final double? speed;

  /// Altitude in meters (for 3D tracking scenarios).
  final double? altitude;

  /// GPS accuracy in meters.
  final double? accuracy;

  /// Timestamp when this position was recorded.
  final DateTime timestamp;

  /// Additional data associated with this update.
  final Map<String, dynamic>? additionalData;

  /// Creates a position update for a dynamic marker.
  const DynamicMarkerPositionUpdate({
    required this.markerId,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    this.heading,
    this.speed,
    this.altitude,
    this.accuracy,
    this.additionalData,
  });

  /// Creates an update from a JSON map.
  factory DynamicMarkerPositionUpdate.fromJson(Map<String, dynamic> json) {
    return DynamicMarkerPositionUpdate(
      markerId: json['markerId'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      timestamp: DateTime.parse(json['timestamp'] as String),
      heading:
          json['heading'] != null ? (json['heading'] as num).toDouble() : null,
      speed: json['speed'] != null ? (json['speed'] as num).toDouble() : null,
      altitude:
          json['altitude'] != null ? (json['altitude'] as num).toDouble() : null,
      accuracy:
          json['accuracy'] != null ? (json['accuracy'] as num).toDouble() : null,
      additionalData: json['additionalData'] != null
          ? Map<String, dynamic>.from(json['additionalData'] as Map)
          : null,
    );
  }

  /// Creates an update from a generic map.
  ///
  /// Useful for converting data from JSON/WebSocket messages.
  /// Supports various coordinate key names:
  /// - latitude/longitude
  /// - lat/lng
  /// - lat/lon
  factory DynamicMarkerPositionUpdate.fromMap(Map<String, dynamic> map) {
    // Extract latitude - support multiple key names
    final lat = map['latitude'] ?? map['lat'];
    final double latitude = lat is num ? lat.toDouble() : double.parse(lat.toString());

    // Extract longitude - support multiple key names
    final lng = map['longitude'] ?? map['lng'] ?? map['lon'];
    final double longitude = lng is num ? lng.toDouble() : double.parse(lng.toString());

    // Parse timestamp if provided
    DateTime timestamp;
    if (map['timestamp'] != null) {
      timestamp = map['timestamp'] is String
          ? DateTime.parse(map['timestamp'] as String)
          : map['timestamp'] as DateTime;
    } else {
      timestamp = DateTime.now();
    }

    return DynamicMarkerPositionUpdate(
      markerId: map['id'] as String,
      latitude: latitude,
      longitude: longitude,
      timestamp: timestamp,
      heading:
          map['heading'] != null ? (map['heading'] as num).toDouble() : null,
      speed: map['speed'] != null ? (map['speed'] as num).toDouble() : null,
      altitude:
          map['altitude'] != null ? (map['altitude'] as num).toDouble() : null,
      accuracy:
          map['accuracy'] != null ? (map['accuracy'] as num).toDouble() : null,
      additionalData: map['data'] != null
          ? Map<String, dynamic>.from(map['data'] as Map)
          : null,
    );
  }

  /// Converts this update to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'markerId': markerId,
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': timestamp.toIso8601String(),
      'heading': heading,
      'speed': speed,
      'altitude': altitude,
      'accuracy': accuracy,
      'additionalData': additionalData,
    };
  }

  /// Creates a copy with updated fields.
  DynamicMarkerPositionUpdate copyWith({
    String? markerId,
    double? latitude,
    double? longitude,
    DateTime? timestamp,
    double? heading,
    double? speed,
    double? altitude,
    double? accuracy,
    Map<String, dynamic>? additionalData,
  }) {
    return DynamicMarkerPositionUpdate(
      markerId: markerId ?? this.markerId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      timestamp: timestamp ?? this.timestamp,
      heading: heading ?? this.heading,
      speed: speed ?? this.speed,
      altitude: altitude ?? this.altitude,
      accuracy: accuracy ?? this.accuracy,
      additionalData: additionalData ?? this.additionalData,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DynamicMarkerPositionUpdate &&
        other.markerId == markerId &&
        other.timestamp == timestamp;
  }

  @override
  int get hashCode => markerId.hashCode ^ timestamp.hashCode;

  @override
  String toString() {
    return 'DynamicMarkerPositionUpdate(markerId: $markerId, '
        'lat: $latitude, lng: $longitude, timestamp: $timestamp)';
  }
}
