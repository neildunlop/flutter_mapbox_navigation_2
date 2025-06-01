///A `WayPoint` object indicates a location along a route.
///It may be the route's origin or destination, or it may be another location
///that the route visits. A waypoint object indicates the location's geographic
///location along with other optional information, such as a name or
///the user's direction approaching the waypoint.
class WayPoint {
  ///Constructor
  WayPoint({
    required this.name,
    required this.latitude,
    required this.longitude,
    this.isSilent = false,
  }) {
    assert(latitude != null, 'Latitude cannot be null');
    assert(longitude != null, 'Longitude cannot be null');
    assert(latitude! >= -90 && latitude! <= 90, 'Latitude must be between -90 and 90');
    assert(longitude! >= -180 && longitude! <= 180, 'Longitude must be between -180 and 180');
  }

  /// create [WayPoint] from a json
  WayPoint.fromJson(Map<String, dynamic> json) {
    name = json['name'] as String?;
    
    // Handle latitude
    if (json['latitude'] is String) {
      latitude = double.tryParse(json['latitude'] as String);
      if (latitude == null) {
        throw FormatException('Invalid latitude format: ${json['latitude']}');
      }
    } else {
      latitude = json['latitude'] as double?;
    }

    // Handle longitude
    if (json['longitude'] is String) {
      longitude = double.tryParse(json['longitude'] as String);
      if (longitude == null) {
        throw FormatException('Invalid longitude format: ${json['longitude']}');
      }
    } else {
      longitude = json['longitude'] as double?;
    }

    if (json['isSilent'] == null) {
      isSilent = false;
    } else {
      isSilent = json['isSilent'] as bool;
    }

    // Validate coordinate ranges
    if (latitude == null) {
      throw FormatException('Latitude cannot be null');
    }
    if (longitude == null) {
      throw FormatException('Longitude cannot be null');
    }
    if (latitude! < -90 || latitude! > 90) {
      throw FormatException('Latitude must be between -90 and 90');
    }
    if (longitude! < -180 || longitude! > 180) {
      throw FormatException('Longitude must be between -180 and 180');
    }
  }

  /// Validates a list of waypoints for duplicates
  /// Throws [FormatException] if duplicate coordinates are found
  static void validateWaypoints(List<WayPoint> waypoints) {
    final coordinates = <String>{};
    for (final waypoint in waypoints) {
      final coordKey = '${waypoint.latitude},${waypoint.longitude}';
      if (coordinates.contains(coordKey)) {
        throw FormatException('Duplicate waypoint coordinates found: ($coordKey)');
      }
      coordinates.add(coordKey);
    }
  }

  /// Waypoint [name]
  String? name;

  /// Waypoint latitude
  double? latitude;

  /// Waypoint longitude
  double? longitude;

  /// Waypoint property isSilent
  bool? isSilent;

  @override
  String toString() {
    return 'WayPoint{latitude: $latitude, longitude: $longitude}';
  }
}
