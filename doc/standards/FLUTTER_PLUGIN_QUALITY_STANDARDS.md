# Quality Standards for Flutter Plugin Development

This document defines the non-negotiable quality standards for the Mapbox Navigation Flutter plugin. Claude Code must follow these standards without exception.

---

## 1. Test-Driven Development (TDD)

### The TDD Mandate

**Every piece of functionality MUST be written using TDD.** This is not optional.

```
RED    → Write a failing test
GREEN  → Write minimum code to pass
REFACTOR → Improve while tests pass
```

### TDD Workflow for Flutter Plugins

Plugin development involves three layers, each requiring TDD:

1. **Dart API layer** - Public interface consumed by apps
2. **Platform channel layer** - Communication bridge
3. **Native implementation** - iOS (Swift) and Android (Kotlin)

#### Step 1: Write the Dart Test FIRST

```dart
// test/mapbox_navigation_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:mapbox_navigation/mapbox_navigation.dart';
import 'package:mapbox_navigation/mapbox_navigation_platform_interface.dart';
import 'package:mocktail/mocktail.dart';

class MockMapboxNavigationPlatform extends Mock
    implements MapboxNavigationPlatform {}

void main() {
  group('MapboxNavigation', () {
    late MapboxNavigationPlatform mockPlatform;

    setUp(() {
      mockPlatform = MockMapboxNavigationPlatform();
      MapboxNavigationPlatform.instance = mockPlatform;
    });

    test('startNavigation calls platform with correct route', () async {
      final route = NavigationRoute(
        origin: LatLng(51.5074, -0.1278),
        destination: LatLng(48.8566, 2.3522),
      );
      
      when(() => mockPlatform.startNavigation(route))
          .thenAnswer((_) async => NavigationSession(id: 'session-123'));

      final session = await MapboxNavigation.startNavigation(route);

      expect(session.id, equals('session-123'));
      verify(() => mockPlatform.startNavigation(route)).called(1);
    });
  });
}
```

#### Step 2: Run the Test - MUST FAIL

```bash
flutter test test/mapbox_navigation_test.dart
```

**Expected output:** Test fails because `startNavigation` doesn't exist.

**If the test passes without implementation, your test is wrong.**

#### Step 3: Write Minimum Code to Pass

```dart
// lib/mapbox_navigation.dart

class MapboxNavigation {
  static Future<NavigationSession> startNavigation(NavigationRoute route) {
    return MapboxNavigationPlatform.instance.startNavigation(route);
  }
}
```

#### Step 4: Run Test Again - MUST PASS

```bash
flutter test test/mapbox_navigation_test.dart
```

#### Step 5: Add Edge Cases and Error Handling

```dart
group('startNavigation', () {
  test('starts navigation with valid route', () async {
    // ... happy path test
  });

  test('throws NavigationException when route has no waypoints', () async {
    final invalidRoute = NavigationRoute(
      origin: LatLng(51.5074, -0.1278),
      destination: LatLng(51.5074, -0.1278), // Same as origin
    );

    when(() => mockPlatform.startNavigation(invalidRoute))
        .thenThrow(NavigationException('Origin and destination cannot be the same'));

    expect(
      () => MapboxNavigation.startNavigation(invalidRoute),
      throwsA(isA<NavigationException>()),
    );
  });

  test('throws NavigationException when location permission denied', () async {
    when(() => mockPlatform.startNavigation(any()))
        .thenThrow(NavigationException(
          'Location permission denied',
          code: NavigationErrorCode.permissionDenied,
        ));

    expect(
      () => MapboxNavigation.startNavigation(validRoute),
      throwsA(
        isA<NavigationException>()
            .having((e) => e.code, 'code', NavigationErrorCode.permissionDenied),
      ),
    );
  });
});
```

### TDD Anti-Patterns to Avoid

```dart
// ❌ WRONG: Writing implementation first, tests after
class MapboxNavigation {
  static Future<void> startNavigation(route) async {
    // Full implementation here
  }
}

// Then writing tests that just confirm what's already written
test('startNavigation works', () async {
  await MapboxNavigation.startNavigation(route);
  // No assertions - what does this prove?
});
```

```dart
// ❌ WRONG: Tests that don't verify behavior
test('navigation session exists', () {
  final session = NavigationSession(id: 'test');
  expect(session, isNotNull); // What does this prove?
});
```

```dart
// ❌ WRONG: Not testing platform channel contracts
// If your Dart code expects a Map with 'latitude' but native sends 'lat',
// you won't catch this without proper platform channel tests
```

---

## 2. Testing Patterns

### Test Categories for Flutter Plugins

| Test Type | Purpose | Location |
|-----------|---------|----------|
| Unit Tests | Dart logic in isolation | `test/` |
| Platform Interface Tests | Method channel contracts | `test/` |
| Widget Tests | UI components (map view) | `test/` |
| Integration Tests | Full plugin flow | `example/integration_test/` |
| Native Unit Tests | iOS/Android logic | `ios/Tests/`, `android/src/test/` |

### Unit Test Structure

Use **Arrange-Act-Assert** pattern:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mapbox_navigation/src/models/navigation_route.dart';

void main() {
  group('NavigationRoute', () {
    group('distanceInMeters', () {
      test('calculates distance between two points correctly', () {
        // Arrange
        final route = NavigationRoute(
          origin: LatLng(51.5074, -0.1278), // London
          destination: LatLng(48.8566, 2.3522), // Paris
        );

        // Act
        final distance = route.distanceInMeters;

        // Assert
        expect(distance, closeTo(343000, 1000)); // ~343km with 1km tolerance
      });

      test('returns zero for same origin and destination', () {
        // Arrange
        final point = LatLng(51.5074, -0.1278);
        final route = NavigationRoute(origin: point, destination: point);

        // Act
        final distance = route.distanceInMeters;

        // Assert
        expect(distance, equals(0));
      });
    });

    group('toJson', () {
      test('serializes all properties correctly', () {
        // Arrange
        final route = NavigationRoute(
          origin: LatLng(51.5074, -0.1278),
          destination: LatLng(48.8566, 2.3522),
          waypoints: [LatLng(49.4431, 1.0993)],
          profile: NavigationProfile.driving,
        );

        // Act
        final json = route.toJson();

        // Assert
        expect(json['origin'], {'latitude': 51.5074, 'longitude': -0.1278});
        expect(json['destination'], {'latitude': 48.8566, 'longitude': 2.3522});
        expect(json['waypoints'], hasLength(1));
        expect(json['profile'], 'driving');
      });
    });
  });
}
```

### Platform Channel Tests

Platform channel contracts are critical - they define the API between Dart and native code.

```dart
// test/mapbox_navigation_method_channel_test.dart

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mapbox_navigation/src/mapbox_navigation_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MethodChannelMapboxNavigation', () {
    late MethodChannelMapboxNavigation platform;
    late List<MethodCall> methodCalls;

    setUp(() {
      platform = MethodChannelMapboxNavigation();
      methodCalls = [];

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('com.example/mapbox_navigation'),
        (MethodCall methodCall) async {
          methodCalls.add(methodCall);
          
          switch (methodCall.method) {
            case 'startNavigation':
              return {'sessionId': 'mock-session-123', 'status': 'active'};
            case 'stopNavigation':
              return {'success': true};
            case 'getCurrentLocation':
              return {'latitude': 51.5074, 'longitude': -0.1278, 'bearing': 45.0};
            default:
              throw PlatformException(
                code: 'UNIMPLEMENTED',
                message: 'Method ${methodCall.method} not implemented',
              );
          }
        },
      );
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('com.example/mapbox_navigation'),
        null,
      );
    });

    test('startNavigation sends correct method call', () async {
      final route = NavigationRoute(
        origin: LatLng(51.5074, -0.1278),
        destination: LatLng(48.8566, 2.3522),
      );

      await platform.startNavigation(route);

      expect(methodCalls, hasLength(1));
      expect(methodCalls.first.method, 'startNavigation');
      expect(methodCalls.first.arguments['origin'], {
        'latitude': 51.5074,
        'longitude': -0.1278,
      });
    });

    test('startNavigation parses response correctly', () async {
      final route = NavigationRoute(
        origin: LatLng(51.5074, -0.1278),
        destination: LatLng(48.8566, 2.3522),
      );

      final session = await platform.startNavigation(route);

      expect(session.id, 'mock-session-123');
      expect(session.status, NavigationStatus.active);
    });

    test('handles platform exception gracefully', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('com.example/mapbox_navigation'),
        (MethodCall methodCall) async {
          throw PlatformException(
            code: 'NAVIGATION_ERROR',
            message: 'Route calculation failed',
            details: {'reason': 'No route found'},
          );
        },
      );

      expect(
        () => platform.startNavigation(validRoute),
        throwsA(
          isA<NavigationException>()
              .having((e) => e.code, 'code', NavigationErrorCode.routeNotFound),
        ),
      );
    });
  });
}
```

### Event Channel Tests

For streaming data (location updates, navigation instructions):

```dart
// test/navigation_events_test.dart

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NavigationEventChannel', () {
    late EventChannel eventChannel;
    
    setUp(() {
      eventChannel = const EventChannel('com.example/mapbox_navigation/events');
    });

    test('emits location updates correctly', () async {
      final mockEvents = [
        {'type': 'locationUpdate', 'latitude': 51.5074, 'longitude': -0.1278},
        {'type': 'locationUpdate', 'latitude': 51.5080, 'longitude': -0.1280},
      ];

      // Set up mock event stream
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockStreamHandler(
        eventChannel,
        MockStreamHandler.inline(
          onListen: (args, sink) {
            for (final event in mockEvents) {
              sink.success(event);
            }
          },
        ),
      );

      final events = await platform.locationUpdates.take(2).toList();

      expect(events, hasLength(2));
      expect(events[0].latitude, 51.5074);
      expect(events[1].latitude, 51.5080);
    });

    test('handles stream errors', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockStreamHandler(
        eventChannel,
        MockStreamHandler.inline(
          onListen: (args, sink) {
            sink.error(code: 'GPS_ERROR', message: 'GPS signal lost');
          },
        ),
      );

      expect(
        platform.locationUpdates.first,
        throwsA(isA<NavigationException>()),
      );
    });
  });
}
```

### Widget Tests for Map Components

```dart
// test/widgets/navigation_map_view_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mapbox_navigation/mapbox_navigation.dart';
import 'package:mocktail/mocktail.dart';

class MockMapController extends Mock implements MapController {}

void main() {
  group('NavigationMapView', () {
    testWidgets('renders map container', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: NavigationMapView(
              accessToken: 'test-token',
            ),
          ),
        ),
      );

      expect(find.byType(NavigationMapView), findsOneWidget);
    });

    testWidgets('calls onMapReady when platform view is created', (tester) async {
      bool mapReady = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NavigationMapView(
              accessToken: 'test-token',
              onMapReady: (controller) {
                mapReady = true;
              },
            ),
          ),
        ),
      );

      // Simulate platform view creation
      await tester.pumpAndSettle();

      // In real tests, you'd verify the callback was invoked
      // This requires platform view mocking
    });

    testWidgets('displays loading indicator initially', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: NavigationMapView(
              accessToken: 'test-token',
              loadingBuilder: CircularProgressIndicator.new,
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('passes style URL to platform view', (tester) async {
      const customStyle = 'mapbox://styles/mapbox/navigation-night-v1';

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: NavigationMapView(
              accessToken: 'test-token',
              styleUri: customStyle,
            ),
          ),
        ),
      );

      // Verify creation params include style URI
      // This requires inspecting the platform view creation parameters
    });
  });
}
```

### Integration Tests

Integration tests run on real devices/emulators and test the full plugin flow:

```dart
// example/integration_test/navigation_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mapbox_navigation/mapbox_navigation.dart';
import 'package:example/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Navigation Integration Tests', () {
    testWidgets('full navigation flow', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Wait for map to load
      await tester.pumpAndSettle(const Duration(seconds: 3));
      expect(find.byType(NavigationMapView), findsOneWidget);

      // Tap to set destination
      await tester.tap(find.byKey(const Key('set_destination_button')));
      await tester.pumpAndSettle();

      // Start navigation
      await tester.tap(find.byKey(const Key('start_navigation_button')));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Verify navigation UI appears
      expect(find.byType(NavigationInstructionBanner), findsOneWidget);
      expect(find.byType(NavigationBottomBar), findsOneWidget);

      // Stop navigation
      await tester.tap(find.byKey(const Key('stop_navigation_button')));
      await tester.pumpAndSettle();

      // Verify navigation UI dismissed
      expect(find.byType(NavigationInstructionBanner), findsNothing);
    });

    testWidgets('handles location permission denial', (tester) async {
      // This test requires device-specific setup to deny permissions
      app.main();
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('start_navigation_button')));
      await tester.pumpAndSettle();

      // Should show permission error
      expect(find.text('Location permission required'), findsOneWidget);
    });
  });
}
```

### Native Unit Tests

#### iOS (Swift) Tests

```swift
// ios/Tests/MapboxNavigationPluginTests.swift

import XCTest
@testable import mapbox_navigation

class MapboxNavigationPluginTests: XCTestCase {
    var plugin: MapboxNavigationPlugin!
    
    override func setUp() {
        super.setUp()
        plugin = MapboxNavigationPlugin()
    }
    
    override func tearDown() {
        plugin = nil
        super.tearDown()
    }
    
    func testParseRouteFromArguments() {
        let arguments: [String: Any] = [
            "origin": ["latitude": 51.5074, "longitude": -0.1278],
            "destination": ["latitude": 48.8566, "longitude": 2.3522],
            "profile": "driving"
        ]
        
        let route = try! plugin.parseRoute(from: arguments)
        
        XCTAssertEqual(route.origin.latitude, 51.5074, accuracy: 0.0001)
        XCTAssertEqual(route.origin.longitude, -0.1278, accuracy: 0.0001)
        XCTAssertEqual(route.destination.latitude, 48.8566, accuracy: 0.0001)
        XCTAssertEqual(route.profile, .driving)
    }
    
    func testParseRouteThrowsForMissingOrigin() {
        let arguments: [String: Any] = [
            "destination": ["latitude": 48.8566, "longitude": 2.3522]
        ]
        
        XCTAssertThrowsError(try plugin.parseRoute(from: arguments)) { error in
            XCTAssertEqual((error as? NavigationError)?.code, .invalidArguments)
        }
    }
    
    func testSerializeLocationUpdate() {
        let location = CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: 51.5074, longitude: -0.1278),
            altitude: 10,
            horizontalAccuracy: 5,
            verticalAccuracy: 3,
            course: 45,
            speed: 10,
            timestamp: Date()
        )
        
        let serialized = plugin.serializeLocation(location)
        
        XCTAssertEqual(serialized["latitude"] as? Double, 51.5074, accuracy: 0.0001)
        XCTAssertEqual(serialized["longitude"] as? Double, -0.1278, accuracy: 0.0001)
        XCTAssertEqual(serialized["bearing"] as? Double, 45, accuracy: 0.1)
        XCTAssertEqual(serialized["speed"] as? Double, 10, accuracy: 0.1)
    }
}
```

#### Android (Kotlin) Tests

```kotlin
// android/src/test/kotlin/com/example/mapbox_navigation/MapboxNavigationPluginTest.kt

package com.example.mapbox_navigation

import org.junit.Assert.*
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner

@RunWith(RobolectricTestRunner::class)
class MapboxNavigationPluginTest {
    private lateinit var plugin: MapboxNavigationPlugin

    @Before
    fun setUp() {
        plugin = MapboxNavigationPlugin()
    }

    @Test
    fun `parseRoute extracts coordinates correctly`() {
        val arguments = mapOf(
            "origin" to mapOf("latitude" to 51.5074, "longitude" to -0.1278),
            "destination" to mapOf("latitude" to 48.8566, "longitude" to 2.3522),
            "profile" to "driving"
        )

        val route = plugin.parseRoute(arguments)

        assertEquals(51.5074, route.origin.latitude, 0.0001)
        assertEquals(-0.1278, route.origin.longitude, 0.0001)
        assertEquals(48.8566, route.destination.latitude, 0.0001)
        assertEquals(NavigationProfile.DRIVING, route.profile)
    }

    @Test(expected = IllegalArgumentException::class)
    fun `parseRoute throws for missing origin`() {
        val arguments = mapOf(
            "destination" to mapOf("latitude" to 48.8566, "longitude" to 2.3522)
        )

        plugin.parseRoute(arguments)
    }

    @Test
    fun `serializeLocation includes all properties`() {
        val location = Location("test").apply {
            latitude = 51.5074
            longitude = -0.1278
            bearing = 45f
            speed = 10f
            accuracy = 5f
        }

        val serialized = plugin.serializeLocation(location)

        assertEquals(51.5074, serialized["latitude"] as Double, 0.0001)
        assertEquals(-0.1278, serialized["longitude"] as Double, 0.0001)
        assertEquals(45.0, serialized["bearing"] as Double, 0.1)
        assertEquals(10.0, serialized["speed"] as Double, 0.1)
    }

    @Test
    fun `handleMethodCall returns error for unknown method`() {
        val result = MockMethodChannel.Result()
        
        plugin.onMethodCall(
            MethodCall("unknownMethod", null),
            result
        )

        assertTrue(result.notImplementedCalled)
    }
}
```

### Test Coverage Requirements

| Category | Minimum | Target |
|----------|---------|--------|
| Dart Unit Tests | 80% | 90% |
| Platform Channel Tests | 100% | 100% |
| Widget Tests | 70% | 85% |
| Native iOS Tests | 70% | 85% |
| Native Android Tests | 70% | 85% |
| Integration Tests | Critical paths | All user flows |

```bash
# Check Dart coverage
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html

# iOS tests
cd ios && xcodebuild test -scheme mapbox_navigation -destination 'platform=iOS Simulator,name=iPhone 15'

# Android tests
cd android && ./gradlew test
```

---

## 3. Type Safety

### No `dynamic` Types - EVER

```dart
// ❌ NEVER DO THIS
void processData(dynamic data) {
  return data['value']; // No type safety
}

// ✅ CORRECT: Use proper types
void processData(Map<String, Object?> data) {
  final value = data['value'];
  if (value is! String) {
    throw ArgumentError('Expected String for value');
  }
  return value;
}
```

### Typed Platform Channel Data

```dart
// ❌ WRONG: Untyped platform response
Future<void> handleResponse(dynamic response) async {
  final lat = response['latitude']; // dynamic
  final lng = response['longitude']; // dynamic
}

// ✅ CORRECT: Parse and validate platform data
Future<LatLng> handleResponse(Object? response) async {
  if (response is! Map<Object?, Object?>) {
    throw PlatformException(
      code: 'INVALID_RESPONSE',
      message: 'Expected Map, got ${response.runtimeType}',
    );
  }
  
  final lat = response['latitude'];
  final lng = response['longitude'];
  
  if (lat is! double || lng is! double) {
    throw PlatformException(
      code: 'INVALID_RESPONSE',
      message: 'Invalid coordinate types',
    );
  }
  
  return LatLng(lat, lng);
}
```

### Model Classes with Validation

```dart
// lib/src/models/navigation_route.dart

@immutable
class NavigationRoute {
  final LatLng origin;
  final LatLng destination;
  final List<LatLng> waypoints;
  final NavigationProfile profile;

  NavigationRoute({
    required this.origin,
    required this.destination,
    this.waypoints = const [],
    this.profile = NavigationProfile.driving,
  }) {
    _validate();
  }

  void _validate() {
    if (origin == destination) {
      throw ArgumentError('Origin and destination cannot be the same');
    }
    if (!origin.isValid) {
      throw ArgumentError('Invalid origin coordinates');
    }
    if (!destination.isValid) {
      throw ArgumentError('Invalid destination coordinates');
    }
    for (final waypoint in waypoints) {
      if (!waypoint.isValid) {
        throw ArgumentError('Invalid waypoint coordinates');
      }
    }
  }

  factory NavigationRoute.fromJson(Map<String, Object?> json) {
    final originJson = json['origin'];
    final destJson = json['destination'];
    final waypointsJson = json['waypoints'];
    final profileJson = json['profile'];

    if (originJson is! Map<String, Object?>) {
      throw FormatException('Invalid origin format');
    }
    if (destJson is! Map<String, Object?>) {
      throw FormatException('Invalid destination format');
    }

    return NavigationRoute(
      origin: LatLng.fromJson(originJson),
      destination: LatLng.fromJson(destJson),
      waypoints: (waypointsJson as List<Object?>?)
              ?.map((w) => LatLng.fromJson(w as Map<String, Object?>))
              .toList() ??
          [],
      profile: NavigationProfile.fromString(profileJson as String? ?? 'driving'),
    );
  }

  Map<String, Object?> toJson() => {
        'origin': origin.toJson(),
        'destination': destination.toJson(),
        'waypoints': waypoints.map((w) => w.toJson()).toList(),
        'profile': profile.value,
      };
}
```

### Strict Analysis Options

```yaml
# analysis_options.yaml

include: package:flutter_lints/flutter.yaml

analyzer:
  language:
    strict-casts: true
    strict-inference: true
    strict-raw-types: true
  errors:
    missing_return: error
    missing_required_param: error
    must_be_immutable: error
    avoid_dynamic_calls: error
  exclude:
    - "**/*.g.dart"
    - "**/*.freezed.dart"

linter:
  rules:
    # Type safety
    avoid_dynamic_calls: true
    avoid_returning_null_for_future: true
    avoid_types_on_closure_parameters: false
    always_declare_return_types: true
    always_specify_types: false
    prefer_typing_uninitialized_variables: true
    type_annotate_public_apis: true
    
    # Error handling
    avoid_catches_without_on_clauses: true
    only_throw_errors: true
    use_rethrow_when_possible: true
    
    # Code quality
    avoid_print: true
    prefer_const_constructors: true
    prefer_const_declarations: true
    prefer_final_fields: true
    prefer_final_locals: true
    unnecessary_await_in_return: true
    unnecessary_lambdas: true
    
    # Documentation
    public_member_api_docs: true
    package_api_docs: true
```

---

## 4. Error Handling

### Custom Exception Classes

```dart
// lib/src/exceptions/navigation_exception.dart

/// Base exception for all navigation-related errors.
@immutable
class NavigationException implements Exception {
  /// Human-readable error message.
  final String message;

  /// Machine-readable error code.
  final NavigationErrorCode code;

  /// Additional error details.
  final Map<String, Object?>? details;

  /// Stack trace when the error occurred.
  final StackTrace? stackTrace;

  const NavigationException(
    this.message, {
    this.code = NavigationErrorCode.unknown,
    this.details,
    this.stackTrace,
  });

  /// Creates exception from a [PlatformException].
  factory NavigationException.fromPlatformException(PlatformException e) {
    return NavigationException(
      e.message ?? 'Platform error occurred',
      code: NavigationErrorCode.fromString(e.code),
      details: e.details is Map<String, Object?>
          ? e.details as Map<String, Object?>
          : null,
    );
  }

  @override
  String toString() => 'NavigationException: $message (code: ${code.name})';
}

/// Error codes for navigation operations.
enum NavigationErrorCode {
  unknown,
  permissionDenied,
  locationUnavailable,
  routeNotFound,
  networkError,
  invalidArguments,
  sessionNotFound,
  mapLoadFailed,
  tokenInvalid,
  ;

  static NavigationErrorCode fromString(String code) {
    return NavigationErrorCode.values.firstWhere(
      (e) => e.name.toLowerCase() == code.toLowerCase(),
      orElse: () => NavigationErrorCode.unknown,
    );
  }
}
```

### Specific Exception Types

```dart
/// Thrown when location permissions are denied.
class LocationPermissionException extends NavigationException {
  final bool permanentlyDenied;

  const LocationPermissionException({
    required this.permanentlyDenied,
    String? message,
  }) : super(
          message ?? 'Location permission denied',
          code: NavigationErrorCode.permissionDenied,
        );
}

/// Thrown when route calculation fails.
class RouteCalculationException extends NavigationException {
  final LatLng? origin;
  final LatLng? destination;

  const RouteCalculationException({
    required String message,
    this.origin,
    this.destination,
  }) : super(message, code: NavigationErrorCode.routeNotFound);
}

/// Thrown when the Mapbox access token is invalid.
class InvalidTokenException extends NavigationException {
  const InvalidTokenException([String? message])
      : super(
          message ?? 'Invalid Mapbox access token',
          code: NavigationErrorCode.tokenInvalid,
        );
}
```

### Platform Exception Handling

```dart
// lib/src/mapbox_navigation_method_channel.dart

class MethodChannelMapboxNavigation extends MapboxNavigationPlatform {
  final MethodChannel _channel = const MethodChannel('com.example/mapbox_navigation');

  @override
  Future<NavigationSession> startNavigation(NavigationRoute route) async {
    try {
      final result = await _channel.invokeMethod<Map<Object?, Object?>>(
        'startNavigation',
        route.toJson(),
      );

      if (result == null) {
        throw const NavigationException(
          'Received null response from platform',
          code: NavigationErrorCode.unknown,
        );
      }

      return NavigationSession.fromJson(_castMap(result));
    } on PlatformException catch (e, stackTrace) {
      throw _handlePlatformException(e, stackTrace);
    }
  }

  NavigationException _handlePlatformException(
    PlatformException e,
    StackTrace stackTrace,
  ) {
    switch (e.code) {
      case 'PERMISSION_DENIED':
        return LocationPermissionException(
          permanentlyDenied: e.details?['permanent'] == true,
          message: e.message,
        );
      case 'ROUTE_NOT_FOUND':
        return RouteCalculationException(message: e.message ?? 'Route not found');
      case 'INVALID_TOKEN':
        return InvalidTokenException(e.message);
      case 'NETWORK_ERROR':
        return NavigationException(
          e.message ?? 'Network error',
          code: NavigationErrorCode.networkError,
          stackTrace: stackTrace,
        );
      default:
        return NavigationException.fromPlatformException(e);
    }
  }

  Map<String, Object?> _castMap(Map<Object?, Object?> map) {
    return map.map((key, value) => MapEntry(key.toString(), value));
  }
}
```

---

## 5. Platform Channel Contract

### Method Channel Definition

The platform channel contract is the API between Dart and native code. It MUST be documented and tested.

```dart
// lib/src/platform/channel_constants.dart

/// Channel name for method calls.
const String kMethodChannelName = 'com.example/mapbox_navigation';

/// Channel name for event streams.
const String kEventChannelName = 'com.example/mapbox_navigation/events';

/// Method names - MUST match native implementations exactly.
abstract class Methods {
  static const String initialize = 'initialize';
  static const String startNavigation = 'startNavigation';
  static const String stopNavigation = 'stopNavigation';
  static const String getCurrentLocation = 'getCurrentLocation';
  static const String setDestination = 'setDestination';
  static const String recalculateRoute = 'recalculateRoute';
  static const String setMapStyle = 'setMapStyle';
}

/// Event types received from native - MUST match native implementations.
abstract class EventTypes {
  static const String locationUpdate = 'locationUpdate';
  static const String routeProgress = 'routeProgress';
  static const String navigationInstruction = 'navigationInstruction';
  static const String arrivalEvent = 'arrivalEvent';
  static const String offRouteEvent = 'offRouteEvent';
  static const String errorEvent = 'errorEvent';
}
```

### Platform Interface Definition

```dart
// lib/src/mapbox_navigation_platform_interface.dart

import 'package:plugin_platform_interface/plugin_platform_interface.dart';

/// Platform interface for Mapbox Navigation plugin.
///
/// This class defines the API that platform-specific implementations must provide.
abstract class MapboxNavigationPlatform extends PlatformInterface {
  MapboxNavigationPlatform() : super(token: _token);

  static final Object _token = Object();

  static MapboxNavigationPlatform _instance = MethodChannelMapboxNavigation();

  /// The instance of [MapboxNavigationPlatform] to use.
  static MapboxNavigationPlatform get instance => _instance;

  /// Sets the instance - only for testing.
  @visibleForTesting
  static set instance(MapboxNavigationPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Initializes the plugin with the Mapbox access token.
  Future<void> initialize(String accessToken);

  /// Starts navigation along the given route.
  Future<NavigationSession> startNavigation(NavigationRoute route);

  /// Stops the current navigation session.
  Future<void> stopNavigation(String sessionId);

  /// Gets the current device location.
  Future<LatLng> getCurrentLocation();

  /// Stream of location updates during navigation.
  Stream<LocationUpdate> get locationUpdates;

  /// Stream of navigation instructions.
  Stream<NavigationInstruction> get navigationInstructions;

  /// Stream of route progress updates.
  Stream<RouteProgress> get routeProgress;
}
```

### Contract Documentation

Document the exact format expected by each platform:

```dart
/// Platform channel contract for startNavigation.
///
/// ## Method
/// `startNavigation`
///
/// ## Arguments (Map<String, Object?>)
/// ```json
/// {
///   "origin": {
///     "latitude": double,    // Required: -90 to 90
///     "longitude": double    // Required: -180 to 180
///   },
///   "destination": {
///     "latitude": double,    // Required
///     "longitude": double    // Required
///   },
///   "waypoints": [           // Optional
///     {"latitude": double, "longitude": double}
///   ],
///   "profile": string,       // Optional: "driving" | "walking" | "cycling"
///   "simulateRoute": bool    // Optional: for testing
/// }
/// ```
///
/// ## Response (Map<String, Object?>)
/// ```json
/// {
///   "sessionId": string,     // Unique session identifier
///   "status": string,        // "active" | "paused"
///   "estimatedDuration": int,// Seconds
///   "estimatedDistance": double // Meters
/// }
/// ```
///
/// ## Errors
/// - `PERMISSION_DENIED`: Location permission not granted
/// - `ROUTE_NOT_FOUND`: No route between points
/// - `INVALID_TOKEN`: Mapbox token invalid
/// - `NETWORK_ERROR`: Network request failed
```

---

## 6. Documentation Standards

### Public API Documentation

Every public member MUST have documentation:

```dart
/// A geographic coordinate representing a point on Earth.
///
/// Coordinates are represented in degrees, with [latitude] ranging
/// from -90 to 90 and [longitude] ranging from -180 to 180.
///
/// ## Example
///
/// ```dart
/// final london = LatLng(51.5074, -0.1278);
/// final paris = LatLng(48.8566, 2.3522);
///
/// final distance = london.distanceTo(paris);
/// print('Distance: ${distance / 1000} km');
/// ```
@immutable
class LatLng {
  /// The latitude in degrees.
  ///
  /// Must be between -90 and 90 inclusive.
  final double latitude;

  /// The longitude in degrees.
  ///
  /// Must be between -180 and 180 inclusive.
  final double longitude;

  /// Creates a geographic coordinate.
  ///
  /// Throws [ArgumentError] if [latitude] or [longitude] are out of range.
  const LatLng(this.latitude, this.longitude);

  /// Creates a coordinate from a JSON map.
  ///
  /// The map must contain `latitude` and `longitude` keys with numeric values.
  ///
  /// Throws [FormatException] if the map format is invalid.
  factory LatLng.fromJson(Map<String, Object?> json) {
    // ...
  }

  /// Calculates the distance in meters to another coordinate.
  ///
  /// Uses the Haversine formula for accurate great-circle distance.
  double distanceTo(LatLng other) {
    // ...
  }

  /// Whether this coordinate represents valid geographic coordinates.
  bool get isValid =>
      latitude >= -90 &&
      latitude <= 90 &&
      longitude >= -180 &&
      longitude <= 180;
}
```

### README Requirements

The plugin README must include:

1. **Installation instructions** - pubspec.yaml, iOS/Android setup
2. **Quick start example** - Complete working code
3. **API reference** - Link to generated docs
4. **Platform-specific setup** - Permissions, tokens, capabilities
5. **Troubleshooting** - Common issues and solutions

### Example App

The `example/` directory must contain a fully functional example app demonstrating:

- All public APIs
- Error handling
- Permission flows
- Common use cases

---

## 7. Accessibility Standards

### Map Accessibility

```dart
/// Navigation map view with accessibility support.
class NavigationMapView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Navigation map',
      hint: 'Shows your current route and position',
      child: Stack(
        children: [
          // Platform map view
          _buildPlatformView(),
          
          // Accessible route info overlay
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Semantics(
              liveRegion: true, // Announces changes
              child: RouteInfoBanner(
                distance: route.remainingDistance,
                duration: route.remainingDuration,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

### Navigation Instructions Accessibility

```dart
/// Announces navigation instructions to screen readers.
class NavigationInstructionAnnouncer extends StatefulWidget {
  final Stream<NavigationInstruction> instructions;

  @override
  State<NavigationInstructionAnnouncer> createState() =>
      _NavigationInstructionAnnouncerState();
}

class _NavigationInstructionAnnouncerState
    extends State<NavigationInstructionAnnouncer> {
  @override
  void initState() {
    super.initState();
    widget.instructions.listen(_announceInstruction);
  }

  void _announceInstruction(NavigationInstruction instruction) {
    // Announce to screen reader
    SemanticsService.announce(
      instruction.spokenInstruction,
      TextDirection.ltr,
    );
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
```

### Touch Target Sizes

```dart
// Minimum touch targets per platform guidelines
const double kMinTouchTargetSize = 48.0; // iOS: 44, Android: 48

// ❌ WRONG: Small touch target
IconButton(
  icon: const Icon(Icons.close, size: 16),
  onPressed: onClose,
)

// ✅ CORRECT: Adequate touch target
IconButton(
  icon: const Icon(Icons.close),
  iconSize: 24,
  padding: const EdgeInsets.all(12), // Total: 48x48
  constraints: const BoxConstraints(
    minWidth: kMinTouchTargetSize,
    minHeight: kMinTouchTargetSize,
  ),
  onPressed: onClose,
)
```

### Color Contrast

```dart
// Use theme colors that meet contrast requirements
class NavigationTheme {
  // Text on background: minimum 4.5:1 contrast
  static const Color textPrimary = Color(0xFF1A1A1A); // On white: 16:1
  static const Color textSecondary = Color(0xFF595959); // On white: 7:1
  
  // UI components: minimum 3:1 contrast
  static const Color buttonPrimary = Color(0xFF0066CC);
  static const Color buttonText = Color(0xFFFFFFFF); // On button: 4.5:1
  
  // Error states: must be distinguishable without color alone
  static const Color error = Color(0xFFD32F2F);
  // Also use icon + text, not just color
}
```

---

## 8. Performance Standards

### Startup Performance

```dart
// Lazy initialization - don't initialize until needed
class MapboxNavigation {
  static MapboxNavigationPlatform? _platform;
  
  static Future<void> ensureInitialized(String accessToken) async {
    _platform ??= await _initializePlatform(accessToken);
  }
}
```

### Memory Management

```dart
/// Properly dispose native resources.
class NavigationMapController {
  bool _disposed = false;

  /// Releases native map resources.
  ///
  /// Must be called when the map is no longer needed.
  /// After calling dispose, this controller can no longer be used.
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    
    await _channel.invokeMethod('disposeMap', {'viewId': _viewId});
    _locationSubscription?.cancel();
    _instructionSubscription?.cancel();
  }

  void _checkNotDisposed() {
    if (_disposed) {
      throw StateError('NavigationMapController has been disposed');
    }
  }
}
```

### Frame Rate Targets

```dart
// Target 60fps during navigation
// Avoid heavy computations on main thread

// ❌ WRONG: Heavy computation on UI thread
void onLocationUpdate(LatLng location) {
  final nearbyPOIs = searchNearbyPOIs(location); // Expensive
  setState(() => _pois = nearbyPOIs);
}

// ✅ CORRECT: Offload to isolate
void onLocationUpdate(LatLng location) async {
  final nearbyPOIs = await compute(searchNearbyPOIs, location);
  if (mounted) {
    setState(() => _pois = nearbyPOIs);
  }
}
```

### Battery Optimization

```dart
/// Location update configuration for battery optimization.
class LocationConfig {
  /// Update interval during active navigation.
  static const Duration activeInterval = Duration(seconds: 1);
  
  /// Update interval when app is backgrounded.
  static const Duration backgroundInterval = Duration(seconds: 5);
  
  /// Minimum displacement before update (meters).
  static const double minDisplacement = 5.0;
}
```

### Performance Testing

```dart
// example/integration_test/performance_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('map scrolling maintains 60fps', (tester) async {
    await tester.pumpWidget(const TestApp());
    await tester.pumpAndSettle();

    // Start frame timing
    await binding.traceAction(
      () async {
        // Simulate map pan gesture
        await tester.fling(
          find.byType(NavigationMapView),
          const Offset(-200, 0),
          1000,
        );
        await tester.pumpAndSettle();
      },
      reportKey: 'map_scroll_performance',
    );
  });

  testWidgets('location updates process under 16ms', (tester) async {
    // Test that location update handling doesn't cause jank
  });
}
```

---

## 9. Platform-Specific Requirements

### iOS Requirements

```yaml
# ios/mapbox_navigation.podspec

Pod::Spec.new do |s|
  s.name             = 'mapbox_navigation'
  s.version          = '1.0.0'
  s.platform         = :ios, '14.0'  # Minimum iOS version
  
  s.dependency 'Flutter'
  s.dependency 'MapboxNavigation', '~> 2.0'
  
  s.swift_version = '5.0'
end
```

#### Required iOS Permissions

```xml
<!-- ios/Runner/Info.plist -->
<key>NSLocationWhenInUseUsageDescription</key>
<string>We need your location to provide turn-by-turn navigation.</string>

<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>We need your location to provide navigation even when the app is in the background.</string>

<key>UIBackgroundModes</key>
<array>
  <string>location</string>
  <string>audio</string>
</array>
```

### Android Requirements

```groovy
// android/build.gradle

android {
    compileSdkVersion 34
    
    defaultConfig {
        minSdkVersion 21  // Minimum Android version
    }
    
    compileOptions {
        sourceCompatibility JavaVersion.VERSION_1_8
        targetCompatibility JavaVersion.VERSION_1_8
    }
    
    kotlinOptions {
        jvmTarget = '1.8'
    }
}

dependencies {
    implementation 'com.mapbox.navigation:android:2.0.0'
}
```

#### Required Android Permissions

```xml
<!-- android/src/main/AndroidManifest.xml -->
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION" />
```

### Platform Parity

Both iOS and Android implementations MUST:

1. Support identical Dart API
2. Return data in identical format
3. Emit events with identical structure
4. Handle errors with matching error codes
5. Have equivalent test coverage

```dart
// Contract test to verify platform parity
void main() {
  group('Platform Parity', () {
    test('startNavigation returns identical structure on both platforms', () {
      // This test would run on both iOS and Android
      // and verify the response format matches
    });
    
    test('locationUpdate events have identical structure', () {
      // Verify event format matches across platforms
    });
  });
}
```

---

## 10. Checklist Before Every PR

### Code Quality

```
□ All tests pass (flutter test)
□ Tests written BEFORE implementation (TDD)
□ No analyzer warnings (flutter analyze)
□ No dynamic types
□ All public APIs documented
□ Platform channel contract documented
□ Error handling uses custom exceptions
```

### Testing

```
□ Unit test coverage > 80%
□ Platform channel tests at 100%
□ Widget tests for all UI components
□ Integration tests for critical paths
□ Native tests pass (iOS and Android)
```

### Platform Specific

```
□ iOS implementation complete and tested
□ Android implementation complete and tested  
□ Platform parity verified
□ Minimum SDK versions documented
□ Required permissions documented
```

### Accessibility

```
□ Semantic labels on all interactive elements
□ Screen reader announces navigation instructions
□ Touch targets minimum 48x48dp
□ Color contrast meets WCAG AA
□ Works with TalkBack/VoiceOver
```

### Performance

```
□ No main thread blocking operations
□ Native resources properly disposed
□ Memory leaks checked with DevTools
□ Frame rate stable at 60fps during navigation
□ Battery impact acceptable
```

### Documentation

```
□ README updated
□ CHANGELOG updated
□ Example app demonstrates feature
□ Breaking changes documented
□ Migration guide if needed
```

---

## Quick Commands

```bash
# Run all Dart tests
flutter test

# Run tests with coverage
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html

# Run analyzer
flutter analyze

# Format code
dart format .

# Run integration tests (requires device/emulator)
cd example
flutter test integration_test/

# iOS native tests
cd ios
xcodebuild test -workspace Runner.xcworkspace -scheme mapbox_navigation -destination 'platform=iOS Simulator,name=iPhone 15'

# Android native tests  
cd android
./gradlew test

# Check documentation coverage
dart doc .

# Verify pub score
dart pub publish --dry-run
```
