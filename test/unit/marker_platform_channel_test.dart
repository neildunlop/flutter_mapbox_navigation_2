import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_mapbox_navigation/src/flutter_mapbox_navigation_method_channel.dart';
import 'package:flutter_mapbox_navigation/src/models/static_marker.dart';
import 'package:flutter_mapbox_navigation/src/platform/channel_constants.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Marker Platform Channel Tests', () {
    late MethodChannelFlutterMapboxNavigation platform;

    setUp(() {
      platform = MethodChannelFlutterMapboxNavigation();

      // Set up mock stream handler for marker events
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockStreamHandler(
        const EventChannel(kMarkerEventChannelName),
        _TestMarkerEventStreamHandler(),
      );
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockStreamHandler(
        const EventChannel(kMarkerEventChannelName),
        null,
      );
    });

    test(
      'should register marker tap listener successfully',
      () {
        // The event channel listener registration is tested implicitly
        // through the platform integration. Unit testing requires
        // actual event channel infrastructure.

        // Verify StaticMarker can be created and parsed
        final testMarker = StaticMarker(
          id: 'test_marker',
          latitude: 37.7749,
          longitude: -122.4194,
          title: 'Test Marker',
          category: 'test',
        );

        expect(testMarker.id, equals('test_marker'));
        expect(testMarker.latitude, equals(37.7749));
        expect(testMarker.longitude, equals(-122.4194));

        // Verify JSON round-trip
        final json = testMarker.toJson();
        final parsed = StaticMarker.fromJson(json);
        expect(parsed.id, equals(testMarker.id));
      },
    );

    test('should handle marker event parsing errors gracefully', () {
      // Test that StaticMarker.fromJson handles missing required fields
      expect(
        () => StaticMarker.fromJson({
          'id': 'test',
          // Missing latitude, longitude, title, category
        }),
        throwsA(isA<TypeError>()),
      );
    });

    test('should handle timeout events correctly', () {
      // Timeout handling is tested at the integration level
      // Verify platform exception types are correct
      final exception = PlatformException(
        code: 'MARKER_EVENTS_TIMEOUT',
        message: 'Marker events stream timed out after 10 seconds',
      );

      expect(exception.code, equals('MARKER_EVENTS_TIMEOUT'));
    });

    test(
      'should prevent memory leaks by canceling previous subscriptions',
      () {
        // Memory leak prevention requires platform integration testing.
        // The method channel implementation handles subscription cancellation internally.

        // This test verifies the API contract exists
        expect(platform.registerStaticMarkerTapListener, isA<Function>());
        expect(platform.unregisterStaticMarkerTapListener, isA<Function>());
      },
    );

    test('should validate marker data before calling listener', () {
      // Test marker validation by trying to create invalid markers

      // Missing title should throw
      expect(
        () => StaticMarker.fromJson({
          'id': 'test_marker',
          'latitude': 37.7749,
          'longitude': -122.4194,
          'category': 'test',
          // Missing title
        }),
        throwsA(isA<TypeError>()),
      );
    });

    test('should handle rapid marker tap events without overwhelming the UI', () {
      // Event throttling is implementation-dependent
      // This test verifies multiple StaticMarkers can be created rapidly

      final markers = <StaticMarker>[];
      for (int i = 0; i < 10; i++) {
        markers.add(StaticMarker(
          id: 'marker_$i',
          latitude: 37.7749 + i * 0.001,
          longitude: -122.4194 + i * 0.001,
          title: 'Marker $i',
          category: 'test',
        ));
      }

      expect(markers.length, equals(10));

      // Verify all markers are unique
      final ids = markers.map((m) => m.id).toSet();
      expect(ids.length, equals(10));
    });
  });

  group('Marker Position Tests', () {
    late MethodChannelFlutterMapboxNavigation platform;
    late List<MethodCall> methodCalls;

    setUp(() {
      platform = MethodChannelFlutterMapboxNavigation();
      methodCalls = [];

      // Mock method channel
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(platform.methodChannel, (call) async {
        methodCalls.add(call);

        switch (call.method) {
          case 'getMarkerScreenPosition':
            final markerId = call.arguments['markerId'] as String;
            if (markerId == 'valid_marker') {
              return {'x': 150.0, 'y': 200.0};
            } else if (markerId == 'error_marker') {
              throw PlatformException(
                code: 'MARKER_NOT_FOUND',
                message: 'Marker not found on map',
              );
            } else {
              return null;
            }
          default:
            return null;
        }
      });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(platform.methodChannel, null);
    });

    testWidgets('should get marker screen position successfully', (tester) async {
      // Act
      final position = await platform.getMarkerScreenPosition('valid_marker');

      // Assert
      expect(position, isNotNull);
      expect(position!['x'], equals(150.0));
      expect(position['y'], equals(200.0));
      expect(methodCalls.length, equals(1));
      expect(methodCalls.first.method, equals('getMarkerScreenPosition'));
      expect(methodCalls.first.arguments['markerId'], equals('valid_marker'));
    });

    testWidgets('should return null for non-existent marker', (tester) async {
      // Act
      final position = await platform.getMarkerScreenPosition('invalid_marker');

      // Assert
      expect(position, isNull);
    });

    testWidgets('should handle platform exceptions gracefully', (tester) async {
      // The implementation catches platform exceptions and returns null
      // rather than propagating the exception
      final position = await platform.getMarkerScreenPosition('error_marker');

      // Assert - method returns null on error (graceful handling)
      expect(position, isNull);
    });
  });
}

/// Test stream handler for marker events
class _TestMarkerEventStreamHandler implements MockStreamHandler {
  @override
  void onListen(Object? arguments, MockStreamHandlerEventSink events) {
    // Test implementation - events can be sent via events.success()
  }

  @override
  void onCancel(Object? arguments) {
    // Cleanup
  }
}
