import 'waypoint_validation_result.dart';

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
    if (name.trim().isEmpty) {
      throw FormatException('Name cannot be empty or contain only whitespace');
    }
  }

  /// create [WayPoint] from a json
  WayPoint.fromJson(Map<String, dynamic> json) : name = _validateName(json['name']) {
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

  /// Validates and returns the name from JSON
  /// Throws [FormatException] if name is null or empty
  static String _validateName(dynamic name) {
    if (name == null) {
      throw FormatException('Name is required and cannot be null');
    }
    final nameStr = name.toString();
    if (nameStr.trim().isEmpty) {
      throw FormatException('Name is required and cannot be empty or contain only whitespace');
    }
    return nameStr;
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

  /// Validates waypoint count against Mapbox API limits
  /// Returns a [WaypointValidationResult] with warnings and recommendations
  static WaypointValidationResult validateWaypointCount(List<WayPoint> waypoints) {
    final count = waypoints.length;
    
    if (count < 2) {
      return WaypointValidationResult(
        isValid: false,
        warnings: ['Minimum 2 waypoints required for navigation'],
        recommendations: ['Add at least one more waypoint'],
      );
    }
    
    final warnings = <String>[];
    final recommendations = <String>[];
    
    if (count > 25) {
      warnings.add('Waypoint count ($count) exceeds recommended Mapbox API limit of 25');
      recommendations.add('Consider reducing waypoint count for better performance');
      recommendations.add('Use silent waypoints for route shaping instead of additional stops');
    } else if (count > 15) {
      warnings.add('High waypoint count ($count) may impact route calculation performance');
      recommendations.add('Consider optimizing route with fewer waypoints');
    }
    
    return WaypointValidationResult(
      isValid: count >= 2,
      warnings: warnings,
      recommendations: recommendations,
    );
  }

  /// Waypoint [name] - required for navigation and waypoint identification
  final String name;

  /// Waypoint latitude
  double? latitude;

  /// Waypoint longitude
  double? longitude;

  /// Waypoint property isSilent
  bool? isSilent;

  @override
  String toString() {
    return 'WayPoint{name: $name, latitude: $latitude, longitude: $longitude}';
  }
}
