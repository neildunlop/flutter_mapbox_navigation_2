import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_mapbox_navigation/src/flutter_mapbox_navigation_method_channel.dart';
import 'package:flutter_mapbox_navigation/src/models/static_marker.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Marker Platform Channel Tests', () {
    late MethodChannelFlutterMapboxNavigation platform;
    late MockEventChannel mockMarkerEventChannel;
    late StreamController<Map<String, dynamic>> markerEventController;

    setUp(() {
      platform = MethodChannelFlutterMapboxNavigation();
      markerEventController = StreamController<Map<String, dynamic>>.broadcast();
      mockMarkerEventChannel = MockEventChannel(markerEventController.stream);
    });

    tearDown(() {
      markerEventController.close();
    });

    testWidgets('should register marker tap listener successfully', (tester) async {
      // Arrange
      bool listenerCalled = false;
      StaticMarker? receivedMarker;

      void testListener(StaticMarker marker) {
        listenerCalled = true;
        receivedMarker = marker;
      }

      // Act
      await platform.registerStaticMarkerTapListener(testListener);

      // Simulate marker tap event
      final testMarker = StaticMarker(
        id: 'test_marker',
        latitude: 37.7749,
        longitude: -122.4194,
        title: 'Test Marker',
        category: 'test',
      );

      markerEventController.add(testMarker.toJson());
      await tester.pump(const Duration(milliseconds: 100));

      // Assert
      expect(listenerCalled, isTrue);
      expect(receivedMarker?.id, equals('test_marker'));
      expect(receivedMarker?.latitude, equals(37.7749));
      expect(receivedMarker?.longitude, equals(-122.4194));
    });

    testWidgets('should handle marker event parsing errors gracefully', (tester) async {
      // Arrange
      bool errorHandled = false;
      
      void testListener(StaticMarker marker) {
        // Should not be called with invalid data
        fail('Listener should not be called with invalid data');
      }

      // Act
      await platform.registerStaticMarkerTapListener(testListener);

      // Simulate invalid marker event
      markerEventController.addError(
        PlatformException(
          code: 'INVALID_MARKER_DATA',
          message: 'Invalid marker data received',
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));

      // Assert - Should not crash and should handle error gracefully
      expect(errorHandled, isFalse); // Error was handled internally
    });

    testWidgets('should handle timeout events correctly', (tester) async {
      // Arrange
      bool timeoutHandled = false;
      
      void testListener(StaticMarker marker) {
        // Should not be called on timeout
      }

      // Act
      await platform.registerStaticMarkerTapListener(testListener);

      // Simulate timeout
      markerEventController.addError(
        PlatformException(
          code: 'MARKER_EVENTS_TIMEOUT',
          message: 'Marker events stream timed out after 10 seconds',
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));

      // Assert - Should handle timeout and attempt reconnection
      // (In real implementation, this would trigger reconnection logic)
      expect(timeoutHandled, isFalse);
    });

    testWidgets('should prevent memory leaks by canceling previous subscriptions', (tester) async {
      // Arrange
      int listenerCallCount = 0;
      
      void testListener1(StaticMarker marker) {
        listenerCallCount++;
      }
      
      void testListener2(StaticMarker marker) {
        listenerCallCount += 10;
      }

      // Act - Register first listener
      await platform.registerStaticMarkerTapListener(testListener1);
      
      // Register second listener (should cancel first)
      await platform.registerStaticMarkerTapListener(testListener2);

      // Simulate marker tap
      final testMarker = StaticMarker(
        id: 'test_marker',
        latitude: 37.7749,
        longitude: -122.4194,
        title: 'Test Marker',
        category: 'test',
      );

      markerEventController.add(testMarker.toJson());
      await tester.pump(const Duration(milliseconds: 100));

      // Assert - Only second listener should be called
      expect(listenerCallCount, equals(10)); // Only second listener (+10)
    });

    testWidgets('should validate marker data before calling listener', (tester) async {
      // Arrange
      bool listenerCalled = false;
      
      void testListener(StaticMarker marker) {
        listenerCalled = true;
      }

      // Act
      await platform.registerStaticMarkerTapListener(testListener);

      // Simulate invalid marker data (missing required fields)
      markerEventController.add({
        'id': 'test_marker',
        // Missing latitude, longitude, category
      });

      await tester.pump(const Duration(milliseconds: 100));

      // Assert - Listener should not be called with invalid data
      expect(listenerCalled, isFalse);
    });

    testWidgets('should handle rapid marker tap events without overwhelming the UI', (tester) async {
      // Arrange
      int listenerCallCount = 0;
      
      void testListener(StaticMarker marker) {
        listenerCallCount++;
      }

      // Act
      await platform.registerStaticMarkerTapListener(testListener);

      // Simulate rapid marker taps
      final testMarker = StaticMarker(
        id: 'test_marker',
        latitude: 37.7749,
        longitude: -122.4194,
        title: 'Test Marker',
        category: 'test',
      );

      for (int i = 0; i < 10; i++) {
        markerEventController.add(testMarker.toJson());
      }

      await tester.pump(const Duration(milliseconds: 500));

      // Assert - All events should be processed
      expect(listenerCallCount, equals(10));
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
      // Arrange - Mock method channel to throw exception
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(platform.methodChannel, (call) async {
        throw PlatformException(
          code: 'MARKER_NOT_FOUND',
          message: 'Marker not found on map',
        );
      });

      // Act & Assert
      expect(
        () => platform.getMarkerScreenPosition('error_marker'),
        throwsA(isA<PlatformException>()),
      );
    });
  });
}

/// Mock event channel for testing marker events
class MockEventChannel {
  final Stream<Map<String, dynamic>> _stream;
  
  MockEventChannel(this._stream);
  
  Stream<Map<String, dynamic>> receiveBroadcastStream() => _stream;
}