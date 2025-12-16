/// Fake Position Generator
///
/// Simulates real-time position updates for multiple vehicles.
/// Used to demonstrate dynamic marker tracking functionality.
///
/// Each simulated vehicle moves in a pattern around a center point,
/// generating position updates at configurable intervals.

import 'dart:async';
import 'dart:math';

/// Configuration for a simulated vehicle
class SimulatedVehicle {
  final String id;
  final String title;
  final String category;
  final double startLatitude;
  final double startLongitude;
  final double speed; // meters per second
  final MovementPattern pattern;
  final String? iconId;

  SimulatedVehicle({
    required this.id,
    required this.title,
    required this.category,
    required this.startLatitude,
    required this.startLongitude,
    this.speed = 15.0, // ~54 km/h default
    this.pattern = MovementPattern.circular,
    this.iconId,
  });
}

/// Movement patterns for simulated vehicles
enum MovementPattern {
  circular, // Moves in a circle around start point
  linear, // Moves back and forth in a line
  random, // Random walk with direction changes
  figure8, // Figure-8 pattern
}

/// Position update from the generator
class PositionUpdate {
  final String markerId;
  final double latitude;
  final double longitude;
  final double heading;
  final double speed;
  final DateTime timestamp;

  PositionUpdate({
    required this.markerId,
    required this.latitude,
    required this.longitude,
    required this.heading,
    required this.speed,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'markerId': markerId,
        'latitude': latitude,
        'longitude': longitude,
        'heading': heading,
        'speed': speed,
        'timestamp': timestamp.toIso8601String(),
      };
}

/// Generates fake position updates for simulated vehicles
class FakePositionGenerator {
  final List<SimulatedVehicle> vehicles;
  final Duration updateInterval;
  final void Function(PositionUpdate)? onPositionUpdate;

  Timer? _timer;
  final Map<String, _VehicleState> _vehicleStates = {};
  final Random _random = Random();

  bool get isRunning => _timer != null && _timer!.isActive;

  FakePositionGenerator({
    required this.vehicles,
    this.updateInterval = const Duration(seconds: 1),
    this.onPositionUpdate,
  }) {
    // Initialize vehicle states
    for (final vehicle in vehicles) {
      _vehicleStates[vehicle.id] = _VehicleState(
        latitude: vehicle.startLatitude,
        longitude: vehicle.startLongitude,
        heading: _random.nextDouble() * 360,
        angle: _random.nextDouble() * 2 * pi,
        speed: vehicle.speed,
      );
    }
  }

  /// Start generating position updates
  void start() {
    if (_timer != null) return;

    _timer = Timer.periodic(updateInterval, (_) => _generateUpdates());
    // Generate initial positions immediately
    _generateUpdates();
  }

  /// Stop generating position updates
  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  /// Get current position for a vehicle
  PositionUpdate? getCurrentPosition(String vehicleId) {
    // Verify vehicle exists
    if (!vehicles.any((v) => v.id == vehicleId)) {
      throw ArgumentError('Vehicle not found: $vehicleId');
    }

    final state = _vehicleStates[vehicleId];
    if (state == null) return null;

    return PositionUpdate(
      markerId: vehicleId,
      latitude: state.latitude,
      longitude: state.longitude,
      heading: state.heading,
      speed: state.speed,
      timestamp: DateTime.now(),
    );
  }

  /// Get all current positions
  List<PositionUpdate> getAllPositions() {
    return vehicles
        .map((v) => getCurrentPosition(v.id))
        .whereType<PositionUpdate>()
        .toList();
  }

  void _generateUpdates() {
    final now = DateTime.now();

    for (final vehicle in vehicles) {
      final state = _vehicleStates[vehicle.id]!;
      final newState = _updateVehiclePosition(vehicle, state);
      _vehicleStates[vehicle.id] = newState;

      final update = PositionUpdate(
        markerId: vehicle.id,
        latitude: newState.latitude,
        longitude: newState.longitude,
        heading: newState.heading,
        speed: newState.speed,
        timestamp: now,
      );

      onPositionUpdate?.call(update);
    }
  }

  _VehicleState _updateVehiclePosition(
      SimulatedVehicle vehicle, _VehicleState state) {
    switch (vehicle.pattern) {
      case MovementPattern.circular:
        return _updateCircular(vehicle, state);
      case MovementPattern.linear:
        return _updateLinear(vehicle, state);
      case MovementPattern.random:
        return _updateRandom(vehicle, state);
      case MovementPattern.figure8:
        return _updateFigure8(vehicle, state);
    }
  }

  _VehicleState _updateCircular(SimulatedVehicle vehicle, _VehicleState state) {
    // Circle radius in degrees (roughly 200-400 meters)
    const radiusDegrees = 0.003;

    // Angular velocity based on speed
    // At ~15 m/s and radius ~300m, one revolution takes ~125 seconds
    final angularVelocity =
        vehicle.speed / (radiusDegrees * 111000) * updateInterval.inSeconds;

    final newAngle = state.angle + angularVelocity;

    // Calculate new position on circle
    final newLat =
        vehicle.startLatitude + radiusDegrees * sin(newAngle);
    final newLng =
        vehicle.startLongitude + radiusDegrees * cos(newAngle);

    // Heading is tangent to circle (perpendicular to radius)
    final heading = (newAngle * 180 / pi + 90) % 360;

    return _VehicleState(
      latitude: newLat,
      longitude: newLng,
      heading: heading,
      angle: newAngle,
      speed: vehicle.speed,
    );
  }

  _VehicleState _updateLinear(SimulatedVehicle vehicle, _VehicleState state) {
    // Move distance based on speed and update interval
    final distanceDegrees =
        vehicle.speed / 111000 * updateInterval.inSeconds;

    // Check if we need to reverse direction
    final distanceFromStart = sqrt(
      pow(state.latitude - vehicle.startLatitude, 2) +
          pow(state.longitude - vehicle.startLongitude, 2),
    );

    // Reverse if too far from start (about 500m)
    var heading = state.heading;
    if (distanceFromStart > 0.005) {
      heading = (heading + 180) % 360;
    }

    // Calculate new position
    final headingRad = heading * pi / 180;
    final newLat = state.latitude + distanceDegrees * cos(headingRad);
    final newLng = state.longitude + distanceDegrees * sin(headingRad);

    return _VehicleState(
      latitude: newLat,
      longitude: newLng,
      heading: heading,
      angle: state.angle,
      speed: vehicle.speed,
    );
  }

  _VehicleState _updateRandom(SimulatedVehicle vehicle, _VehicleState state) {
    // Occasionally change direction (10% chance per update)
    var heading = state.heading;
    if (_random.nextDouble() < 0.1) {
      // Turn up to 45 degrees
      heading = (heading + (_random.nextDouble() - 0.5) * 90) % 360;
      if (heading < 0) heading += 360;
    }

    // Move distance based on speed
    final distanceDegrees =
        vehicle.speed / 111000 * updateInterval.inSeconds;

    final headingRad = heading * pi / 180;
    var newLat = state.latitude + distanceDegrees * cos(headingRad);
    var newLng = state.longitude + distanceDegrees * sin(headingRad);

    // Keep within bounds (roughly 1km from start)
    const maxDistance = 0.01;
    final distanceFromStart = sqrt(
      pow(newLat - vehicle.startLatitude, 2) +
          pow(newLng - vehicle.startLongitude, 2),
    );

    if (distanceFromStart > maxDistance) {
      // Turn back toward start
      final toStartAngle = atan2(
            vehicle.startLongitude - newLng,
            vehicle.startLatitude - newLat,
          ) *
          180 /
          pi;
      heading = toStartAngle;
      if (heading < 0) heading += 360;

      newLat = state.latitude + distanceDegrees * cos(heading * pi / 180);
      newLng = state.longitude + distanceDegrees * sin(heading * pi / 180);
    }

    return _VehicleState(
      latitude: newLat,
      longitude: newLng,
      heading: heading,
      angle: state.angle,
      speed: vehicle.speed,
    );
  }

  _VehicleState _updateFigure8(SimulatedVehicle vehicle, _VehicleState state) {
    // Figure-8 using Lissajous curve
    const radiusDegrees = 0.003;

    final angularVelocity =
        vehicle.speed / (radiusDegrees * 111000) * updateInterval.inSeconds;

    final newAngle = state.angle + angularVelocity;

    // Lissajous curve: x = sin(t), y = sin(2t)
    final newLat =
        vehicle.startLatitude + radiusDegrees * sin(newAngle);
    final newLng =
        vehicle.startLongitude + radiusDegrees * sin(2 * newAngle);

    // Calculate heading from derivative
    final dx = cos(newAngle);
    final dy = 2 * cos(2 * newAngle);
    final heading = (atan2(dy, dx) * 180 / pi + 90) % 360;

    return _VehicleState(
      latitude: newLat,
      longitude: newLng,
      heading: heading >= 0 ? heading : heading + 360,
      angle: newAngle,
      speed: vehicle.speed,
    );
  }

  void dispose() {
    stop();
    _vehicleStates.clear();
  }
}

/// Internal state for tracking vehicle movement
class _VehicleState {
  final double latitude;
  final double longitude;
  final double heading;
  final double angle; // For circular/figure8 patterns
  final double speed;

  _VehicleState({
    required this.latitude,
    required this.longitude,
    required this.heading,
    required this.angle,
    required this.speed,
  });
}
