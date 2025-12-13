import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Error codes for navigation operations.
///
/// These codes provide machine-readable error identification for
/// programmatic error handling.
enum NavigationErrorCode {
  /// An unknown error occurred.
  unknown,

  /// Location permission was denied by the user.
  permissionDenied,

  /// Location services are unavailable or disabled.
  locationUnavailable,

  /// No route could be found between the specified points.
  routeNotFound,

  /// A network error occurred during the operation.
  networkError,

  /// Invalid arguments were provided to the operation.
  invalidArguments,

  /// The requested navigation session was not found.
  sessionNotFound,

  /// The map failed to load.
  mapLoadFailed,

  /// The Mapbox access token is invalid or expired.
  tokenInvalid,

  /// The operation is not implemented on this platform.
  notImplemented,

  /// The operation timed out.
  timeout,

  /// The route calculation was cancelled.
  cancelled,

  /// Invalid waypoint data was provided.
  invalidWaypoint,

  /// Offline routing is not available for the requested area.
  offlineUnavailable,
  ;

  /// Creates an error code from a string representation.
  ///
  /// Returns [NavigationErrorCode.unknown] if the string doesn't match
  /// any known error code.
  static NavigationErrorCode fromString(String code) {
    final normalizedCode = code.toLowerCase().replaceAll('_', '');
    return NavigationErrorCode.values.firstWhere(
      (e) => e.name.toLowerCase() == normalizedCode,
      orElse: () => NavigationErrorCode.unknown,
    );
  }
}

/// Base exception for all navigation-related errors.
///
/// This exception provides structured error information including
/// a human-readable message, machine-readable error code, and
/// optional additional details.
///
/// ## Example
///
/// ```dart
/// try {
///   await navigation.startNavigation(route);
/// } on NavigationException catch (e) {
///   switch (e.code) {
///     case NavigationErrorCode.permissionDenied:
///       showPermissionDialog();
///       break;
///     case NavigationErrorCode.routeNotFound:
///       showNoRouteMessage();
///       break;
///     default:
///       showGenericError(e.message);
///   }
/// }
/// ```
@immutable
class NavigationException implements Exception {
  /// Human-readable error message.
  final String message;

  /// Machine-readable error code.
  final NavigationErrorCode code;

  /// Additional error details.
  ///
  /// May contain platform-specific information about the error.
  final Map<String, Object?>? details;

  /// Stack trace when the error occurred.
  final StackTrace? stackTrace;

  /// Creates a navigation exception.
  const NavigationException(
    this.message, {
    this.code = NavigationErrorCode.unknown,
    this.details,
    this.stackTrace,
  });

  /// Creates an exception from a [PlatformException].
  ///
  /// Maps platform error codes to [NavigationErrorCode] values.
  factory NavigationException.fromPlatformException(
    PlatformException e, [
    StackTrace? stackTrace,
  ]) {
    return NavigationException(
      e.message ?? 'Platform error occurred',
      code: _mapPlatformCode(e.code),
      details: e.details is Map<String, Object?>
          ? e.details as Map<String, Object?>
          : e.details != null
              ? {'raw': e.details}
              : null,
      stackTrace: stackTrace,
    );
  }

  static NavigationErrorCode _mapPlatformCode(String code) {
    switch (code.toUpperCase()) {
      case 'PERMISSION_DENIED':
      case 'LOCATION_PERMISSION_DENIED':
        return NavigationErrorCode.permissionDenied;
      case 'LOCATION_UNAVAILABLE':
      case 'GPS_ERROR':
        return NavigationErrorCode.locationUnavailable;
      case 'ROUTE_NOT_FOUND':
      case 'NO_ROUTE':
        return NavigationErrorCode.routeNotFound;
      case 'NETWORK_ERROR':
      case 'CONNECTION_ERROR':
        return NavigationErrorCode.networkError;
      case 'INVALID_ARGUMENTS':
      case 'INVALID_PARAMS':
        return NavigationErrorCode.invalidArguments;
      case 'SESSION_NOT_FOUND':
        return NavigationErrorCode.sessionNotFound;
      case 'MAP_LOAD_FAILED':
        return NavigationErrorCode.mapLoadFailed;
      case 'INVALID_TOKEN':
      case 'TOKEN_EXPIRED':
        return NavigationErrorCode.tokenInvalid;
      case 'NOT_IMPLEMENTED':
      case 'UNIMPLEMENTED':
        return NavigationErrorCode.notImplemented;
      case 'TIMEOUT':
        return NavigationErrorCode.timeout;
      case 'CANCELLED':
        return NavigationErrorCode.cancelled;
      default:
        return NavigationErrorCode.fromString(code);
    }
  }

  @override
  String toString() => 'NavigationException: $message (code: ${code.name})';
}

/// Thrown when location permissions are denied.
///
/// Check [permanentlyDenied] to determine if the user can be prompted
/// again or if they need to enable permissions in system settings.
@immutable
class LocationPermissionException extends NavigationException {
  /// Whether the permission was permanently denied.
  ///
  /// If true, the user must enable permissions in system settings.
  /// If false, the app can request permission again.
  final bool permanentlyDenied;

  /// Creates a location permission exception.
  const LocationPermissionException({
    required this.permanentlyDenied,
    String? message,
  }) : super(
          message ?? (permanentlyDenied
              ? 'Location permission permanently denied. Please enable in settings.'
              : 'Location permission denied'),
          code: NavigationErrorCode.permissionDenied,
        );
}

/// Thrown when route calculation fails.
///
/// Contains the origin and destination that failed to route,
/// which can be useful for error reporting and debugging.
@immutable
class RouteCalculationException extends NavigationException {
  /// The route origin latitude, if available.
  final double? originLat;

  /// The route origin longitude, if available.
  final double? originLng;

  /// The route destination latitude, if available.
  final double? destinationLat;

  /// The route destination longitude, if available.
  final double? destinationLng;

  /// Creates a route calculation exception.
  const RouteCalculationException({
    required String message,
    this.originLat,
    this.originLng,
    this.destinationLat,
    this.destinationLng,
  }) : super(message, code: NavigationErrorCode.routeNotFound);
}

/// Thrown when the Mapbox access token is invalid or expired.
@immutable
class InvalidTokenException extends NavigationException {
  /// Creates an invalid token exception.
  const InvalidTokenException([String? message])
      : super(
          message ?? 'Invalid or expired Mapbox access token',
          code: NavigationErrorCode.tokenInvalid,
        );
}

/// Thrown when a waypoint has invalid data.
@immutable
class InvalidWaypointException extends NavigationException {
  /// The index of the invalid waypoint, if applicable.
  final int? waypointIndex;

  /// Creates an invalid waypoint exception.
  const InvalidWaypointException({
    required String message,
    this.waypointIndex,
  }) : super(message, code: NavigationErrorCode.invalidWaypoint);
}

/// Thrown when an operation times out.
@immutable
class NavigationTimeoutException extends NavigationException {
  /// The duration that was exceeded.
  final Duration? timeout;

  /// Creates a timeout exception.
  const NavigationTimeoutException({
    String? message,
    this.timeout,
  }) : super(
          message ?? 'Operation timed out',
          code: NavigationErrorCode.timeout,
        );
}

/// Thrown when offline routing is not available.
@immutable
class OfflineUnavailableException extends NavigationException {
  /// Creates an offline unavailable exception.
  const OfflineUnavailableException([String? message])
      : super(
          message ?? 'Offline routing is not available for this area',
          code: NavigationErrorCode.offlineUnavailable,
        );
}
