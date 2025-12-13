import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_mapbox_navigation/src/exceptions/navigation_exception.dart';

void main() {
  group('NavigationErrorCode', () {
    test('should have all expected error codes', () {
      expect(NavigationErrorCode.values.length, equals(14));
      expect(NavigationErrorCode.values, contains(NavigationErrorCode.unknown));
      expect(NavigationErrorCode.values, contains(NavigationErrorCode.permissionDenied));
      expect(NavigationErrorCode.values, contains(NavigationErrorCode.locationUnavailable));
      expect(NavigationErrorCode.values, contains(NavigationErrorCode.routeNotFound));
      expect(NavigationErrorCode.values, contains(NavigationErrorCode.networkError));
      expect(NavigationErrorCode.values, contains(NavigationErrorCode.invalidArguments));
      expect(NavigationErrorCode.values, contains(NavigationErrorCode.sessionNotFound));
      expect(NavigationErrorCode.values, contains(NavigationErrorCode.mapLoadFailed));
      expect(NavigationErrorCode.values, contains(NavigationErrorCode.tokenInvalid));
      expect(NavigationErrorCode.values, contains(NavigationErrorCode.notImplemented));
      expect(NavigationErrorCode.values, contains(NavigationErrorCode.timeout));
      expect(NavigationErrorCode.values, contains(NavigationErrorCode.cancelled));
      expect(NavigationErrorCode.values, contains(NavigationErrorCode.invalidWaypoint));
      expect(NavigationErrorCode.values, contains(NavigationErrorCode.offlineUnavailable));
    });

    test('fromString should parse known error codes', () {
      expect(NavigationErrorCode.fromString('permissiondenied'),
          equals(NavigationErrorCode.permissionDenied));
      expect(NavigationErrorCode.fromString('PERMISSION_DENIED'),
          equals(NavigationErrorCode.permissionDenied));
      expect(NavigationErrorCode.fromString('routeNotFound'),
          equals(NavigationErrorCode.routeNotFound));
    });

    test('fromString should return unknown for unrecognized codes', () {
      expect(NavigationErrorCode.fromString('invalid_code'),
          equals(NavigationErrorCode.unknown));
      expect(NavigationErrorCode.fromString(''),
          equals(NavigationErrorCode.unknown));
      expect(NavigationErrorCode.fromString('xyz123'),
          equals(NavigationErrorCode.unknown));
    });
  });

  group('NavigationException', () {
    test('should create with message only', () {
      const exception = NavigationException('Test error');

      expect(exception.message, equals('Test error'));
      expect(exception.code, equals(NavigationErrorCode.unknown));
      expect(exception.details, isNull);
      expect(exception.stackTrace, isNull);
    });

    test('should create with all parameters', () {
      final stackTrace = StackTrace.current;
      final exception = NavigationException(
        'Test error',
        code: NavigationErrorCode.routeNotFound,
        details: {'key': 'value'},
        stackTrace: stackTrace,
      );

      expect(exception.message, equals('Test error'));
      expect(exception.code, equals(NavigationErrorCode.routeNotFound));
      expect(exception.details, equals({'key': 'value'}));
      expect(exception.stackTrace, equals(stackTrace));
    });

    test('should convert to string correctly', () {
      const exception = NavigationException(
        'Route not found',
        code: NavigationErrorCode.routeNotFound,
      );

      expect(exception.toString(),
          equals('NavigationException: Route not found (code: routeNotFound)'));
    });

    group('fromPlatformException', () {
      test('should map PERMISSION_DENIED code', () {
        final platformException = PlatformException(
          code: 'PERMISSION_DENIED',
          message: 'Permission denied',
        );

        final exception = NavigationException.fromPlatformException(platformException);

        expect(exception.code, equals(NavigationErrorCode.permissionDenied));
        expect(exception.message, equals('Permission denied'));
      });

      test('should map LOCATION_PERMISSION_DENIED code', () {
        final platformException = PlatformException(
          code: 'LOCATION_PERMISSION_DENIED',
          message: 'Location permission denied',
        );

        final exception = NavigationException.fromPlatformException(platformException);

        expect(exception.code, equals(NavigationErrorCode.permissionDenied));
      });

      test('should map ROUTE_NOT_FOUND code', () {
        final platformException = PlatformException(
          code: 'ROUTE_NOT_FOUND',
          message: 'No route available',
        );

        final exception = NavigationException.fromPlatformException(platformException);

        expect(exception.code, equals(NavigationErrorCode.routeNotFound));
      });

      test('should map NO_ROUTE code', () {
        final platformException = PlatformException(
          code: 'NO_ROUTE',
          message: 'No route available',
        );

        final exception = NavigationException.fromPlatformException(platformException);

        expect(exception.code, equals(NavigationErrorCode.routeNotFound));
      });

      test('should map NETWORK_ERROR code', () {
        final platformException = PlatformException(
          code: 'NETWORK_ERROR',
          message: 'Network error',
        );

        final exception = NavigationException.fromPlatformException(platformException);

        expect(exception.code, equals(NavigationErrorCode.networkError));
      });

      test('should map INVALID_TOKEN code', () {
        final platformException = PlatformException(
          code: 'INVALID_TOKEN',
          message: 'Invalid token',
        );

        final exception = NavigationException.fromPlatformException(platformException);

        expect(exception.code, equals(NavigationErrorCode.tokenInvalid));
      });

      test('should map TOKEN_EXPIRED code', () {
        final platformException = PlatformException(
          code: 'TOKEN_EXPIRED',
          message: 'Token expired',
        );

        final exception = NavigationException.fromPlatformException(platformException);

        expect(exception.code, equals(NavigationErrorCode.tokenInvalid));
      });

      test('should map NOT_IMPLEMENTED code', () {
        final platformException = PlatformException(
          code: 'NOT_IMPLEMENTED',
          message: 'Not implemented',
        );

        final exception = NavigationException.fromPlatformException(platformException);

        expect(exception.code, equals(NavigationErrorCode.notImplemented));
      });

      test('should map TIMEOUT code', () {
        final platformException = PlatformException(
          code: 'TIMEOUT',
          message: 'Operation timed out',
        );

        final exception = NavigationException.fromPlatformException(platformException);

        expect(exception.code, equals(NavigationErrorCode.timeout));
      });

      test('should map CANCELLED code', () {
        final platformException = PlatformException(
          code: 'CANCELLED',
          message: 'Operation cancelled',
        );

        final exception = NavigationException.fromPlatformException(platformException);

        expect(exception.code, equals(NavigationErrorCode.cancelled));
      });

      test('should handle null message', () {
        final platformException = PlatformException(
          code: 'UNKNOWN',
          message: null,
        );

        final exception = NavigationException.fromPlatformException(platformException);

        expect(exception.message, equals('Platform error occurred'));
      });

      test('should handle Map details', () {
        final platformException = PlatformException(
          code: 'ERROR',
          message: 'Error',
          details: <String, Object?>{'key': 'value', 'count': 42},
        );

        final exception = NavigationException.fromPlatformException(platformException);

        expect(exception.details, equals({'key': 'value', 'count': 42}));
      });

      test('should wrap non-Map details', () {
        final platformException = PlatformException(
          code: 'ERROR',
          message: 'Error',
          details: 'string details',
        );

        final exception = NavigationException.fromPlatformException(platformException);

        expect(exception.details, equals({'raw': 'string details'}));
      });

      test('should handle null details', () {
        final platformException = PlatformException(
          code: 'ERROR',
          message: 'Error',
          details: null,
        );

        final exception = NavigationException.fromPlatformException(platformException);

        expect(exception.details, isNull);
      });

      test('should preserve stack trace', () {
        final platformException = PlatformException(
          code: 'ERROR',
          message: 'Error',
        );
        final stackTrace = StackTrace.current;

        final exception = NavigationException.fromPlatformException(
          platformException,
          stackTrace,
        );

        expect(exception.stackTrace, equals(stackTrace));
      });
    });
  });

  group('LocationPermissionException', () {
    test('should create with permanentlyDenied true', () {
      const exception = LocationPermissionException(permanentlyDenied: true);

      expect(exception.permanentlyDenied, isTrue);
      expect(exception.code, equals(NavigationErrorCode.permissionDenied));
      expect(exception.message,
          equals('Location permission permanently denied. Please enable in settings.'));
    });

    test('should create with permanentlyDenied false', () {
      const exception = LocationPermissionException(permanentlyDenied: false);

      expect(exception.permanentlyDenied, isFalse);
      expect(exception.message, equals('Location permission denied'));
    });

    test('should use custom message when provided', () {
      const exception = LocationPermissionException(
        permanentlyDenied: true,
        message: 'Custom message',
      );

      expect(exception.message, equals('Custom message'));
    });
  });

  group('RouteCalculationException', () {
    test('should create with message only', () {
      const exception = RouteCalculationException(
        message: 'No route found',
      );

      expect(exception.message, equals('No route found'));
      expect(exception.code, equals(NavigationErrorCode.routeNotFound));
      expect(exception.originLat, isNull);
      expect(exception.originLng, isNull);
      expect(exception.destinationLat, isNull);
      expect(exception.destinationLng, isNull);
    });

    test('should create with all coordinates', () {
      const exception = RouteCalculationException(
        message: 'No route found',
        originLat: 37.7749,
        originLng: -122.4194,
        destinationLat: 34.0522,
        destinationLng: -118.2437,
      );

      expect(exception.originLat, equals(37.7749));
      expect(exception.originLng, equals(-122.4194));
      expect(exception.destinationLat, equals(34.0522));
      expect(exception.destinationLng, equals(-118.2437));
    });
  });

  group('InvalidTokenException', () {
    test('should create with default message', () {
      const exception = InvalidTokenException();

      expect(exception.message, equals('Invalid or expired Mapbox access token'));
      expect(exception.code, equals(NavigationErrorCode.tokenInvalid));
    });

    test('should create with custom message', () {
      const exception = InvalidTokenException('Token is malformed');

      expect(exception.message, equals('Token is malformed'));
    });
  });

  group('InvalidWaypointException', () {
    test('should create with message only', () {
      const exception = InvalidWaypointException(
        message: 'Invalid waypoint',
      );

      expect(exception.message, equals('Invalid waypoint'));
      expect(exception.code, equals(NavigationErrorCode.invalidWaypoint));
      expect(exception.waypointIndex, isNull);
    });

    test('should create with waypoint index', () {
      const exception = InvalidWaypointException(
        message: 'Invalid waypoint at index 2',
        waypointIndex: 2,
      );

      expect(exception.waypointIndex, equals(2));
    });
  });

  group('NavigationTimeoutException', () {
    test('should create with default message', () {
      const exception = NavigationTimeoutException();

      expect(exception.message, equals('Operation timed out'));
      expect(exception.code, equals(NavigationErrorCode.timeout));
      expect(exception.timeout, isNull);
    });

    test('should create with custom message and timeout', () {
      const exception = NavigationTimeoutException(
        message: 'Route calculation timed out',
        timeout: Duration(seconds: 30),
      );

      expect(exception.message, equals('Route calculation timed out'));
      expect(exception.timeout, equals(const Duration(seconds: 30)));
    });
  });

  group('OfflineUnavailableException', () {
    test('should create with default message', () {
      const exception = OfflineUnavailableException();

      expect(exception.message,
          equals('Offline routing is not available for this area'));
      expect(exception.code, equals(NavigationErrorCode.offlineUnavailable));
    });

    test('should create with custom message', () {
      const exception = OfflineUnavailableException(
        'Offline maps not downloaded for this region',
      );

      expect(exception.message,
          equals('Offline maps not downloaded for this region'));
    });
  });
}
