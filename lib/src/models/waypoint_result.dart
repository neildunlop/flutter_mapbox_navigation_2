/// Result of a waypoint operation (e.g., adding waypoints)
class WaypointResult {
  /// Whether the operation was successful
  final bool success;

  /// Number of waypoints that were added/modified
  final int waypointsAdded;

  /// Optional error message if the operation failed
  final String? errorMessage;

  /// Creates a new [WaypointResult]
  const WaypointResult({
    required this.success,
    required this.waypointsAdded,
    this.errorMessage,
  });

  /// Creates a successful result
  factory WaypointResult.success({required int waypointsAdded}) {
    return WaypointResult(
      success: true,
      waypointsAdded: waypointsAdded,
    );
  }

  /// Creates a failed result
  factory WaypointResult.failure({
    required String errorMessage,
    int waypointsAdded = 0,
  }) {
    return WaypointResult(
      success: false,
      waypointsAdded: waypointsAdded,
      errorMessage: errorMessage,
    );
  }

  @override
  String toString() {
    if (success) {
      return 'WaypointResult(success: true, waypointsAdded: $waypointsAdded)';
    }
    return 'WaypointResult(success: false, waypointsAdded: $waypointsAdded, errorMessage: $errorMessage)';
  }
} 