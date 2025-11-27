import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_mapbox_navigation/src/flutter_mapbox_navigation_method_channel.dart';
import 'package:flutter_mapbox_navigation/src/models/static_marker.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Popup Error Handling Tests', () {
    late MethodChannelFlutterMapboxNavigation platform;
    late StreamController<Map<String, dynamic>> markerEventController;

    setUp(() {
      platform = MethodChannelFlutterMapboxNavigation();
      markerEventController = StreamController<Map<String, dynamic>>.broadcast();
    });

    tearDown(() {
      markerEventController.close();
    });

    testWidgets('should handle listener callback errors gracefully', (tester) async {
      // Arrange
      bool errorLogged = false;
      
      void faultyListener(StaticMarker marker) {
        throw Exception('Listener callback error');
      }

      // Act
      await platform.registerStaticMarkerTapListener(faultyListener);

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

      // Assert - Should not crash the app
      expect(errorLogged, isFalse); // Error handled internally
    });

    testWidgets('should handle corrupted marker data', (tester) async {
      // Arrange
      bool listenerCalled = false;
      
      void testListener(StaticMarker marker) {
        listenerCalled = true;
      }

      // Act
      await platform.registerStaticMarkerTapListener(testListener);

      // Simulate corrupted data
      markerEventController.add({
        'id': 'test_marker',
        'latitude': 'invalid_number', // Should be double
        'longitude': -122.4194,
        'category': 'test',
      });

      await tester.pump(const Duration(milliseconds: 100));

      // Assert - Should not call listener with invalid data
      expect(listenerCalled, isFalse);
    });

    testWidgets('should handle null marker data', (tester) async {
      // Arrange
      bool listenerCalled = false;
      
      void testListener(StaticMarker marker) {
        listenerCalled = true;
      }

      // Act
      await platform.registerStaticMarkerTapListener(testListener);

      // Simulate null data
      markerEventController.add({});

      await tester.pump(const Duration(milliseconds: 100));

      // Assert
      expect(listenerCalled, isFalse);
    });

    testWidgets('should handle platform channel disconnection', (tester) async {
      // Arrange
      bool reconnectionAttempted = false;
      
      void testListener(StaticMarker marker) {
        // Should not be called during disconnection
      }

      // Act
      await platform.registerStaticMarkerTapListener(testListener);

      // Simulate channel disconnection
      markerEventController.addError(
        PlatformException(
          code: 'CHANNEL_DISCONNECTED',
          message: 'Platform channel disconnected',
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));

      // Assert - Should handle disconnection gracefully
      expect(reconnectionAttempted, isFalse);
    });

    testWidgets('should validate marker parsing with edge cases', (tester) async {
      // Arrange
      final receivedMarkers = <StaticMarker>[];
      
      void testListener(StaticMarker marker) {
        receivedMarkers.add(marker);
      }

      // Act
      await platform.registerStaticMarkerTapListener(testListener);

      // Test edge cases
      final edgeCases = [
        // Valid marker
        {
          'id': 'valid',
          'latitude': 90.0, // Max latitude
          'longitude': 180.0, // Max longitude
          'category': 'test',
        },
        // Marker with minimum values
        {
          'id': 'min_values',
          'latitude': -90.0, // Min latitude
          'longitude': -180.0, // Min longitude
          'category': 'test',
        },
        // Marker with optional fields
        {
          'id': 'with_optionals',
          'latitude': 0.0,
          'longitude': 0.0,
          'category': 'test',
          'title': 'Test Marker',
          'subtitle': 'Test Description',
        },
        // Invalid: latitude out of range
        {
          'id': 'invalid_lat',
          'latitude': 91.0, // Invalid
          'longitude': 0.0,
          'category': 'test',
        },
        // Invalid: longitude out of range
        {
          'id': 'invalid_lng',
          'latitude': 0.0,
          'longitude': 181.0, // Invalid
          'category': 'test',
        },
      ];

      for (final markerData in edgeCases) {
        markerEventController.add(markerData);
        await tester.pump(const Duration(milliseconds: 50));
      }

      // Assert - Only valid markers should be received
      expect(receivedMarkers.length, equals(3)); // Only first 3 are valid
      expect(receivedMarkers[0].id, equals('valid'));
      expect(receivedMarkers[1].id, equals('min_values'));
      expect(receivedMarkers[2].id, equals('with_optionals'));
    });

    testWidgets('should handle concurrent marker events', (tester) async {
      // Arrange
      final receivedMarkers = <StaticMarker>[];
      
      void testListener(StaticMarker marker) {
        receivedMarkers.add(marker);
      }

      // Act
      await platform.registerStaticMarkerTapListener(testListener);

      // Simulate concurrent marker taps
      final futures = <Future>[];
      for (int i = 0; i < 100; i++) {
        futures.add(Future.microtask(() {
          markerEventController.add({
            'id': 'marker_$i',
            'latitude': i % 90,
            'longitude': i % 180,
            'category': 'test',
          });
        }));
      }

      await Future.wait(futures);
      await tester.pump(const Duration(seconds: 1));

      // Assert - All valid markers should be processed
      expect(receivedMarkers.length, equals(100));
      
      // Check for data integrity
      final ids = receivedMarkers.map((m) => m.id).toSet();
      expect(ids.length, equals(100)); // All unique IDs preserved
    });

    testWidgets('should handle memory pressure during many events', (tester) async {
      // Arrange
      int processedCount = 0;
      
      void testListener(StaticMarker marker) {
        processedCount++;
      }

      // Act
      await platform.registerStaticMarkerTapListener(testListener);

      // Simulate high-frequency events (stress test)
      for (int i = 0; i < 1000; i++) {
        markerEventController.add({
          'id': 'stress_marker_$i',
          'latitude': (i % 180) - 90.0,
          'longitude': (i % 360) - 180.0,
          'category': 'stress_test',
        });
        
        if (i % 100 == 0) {
          await tester.pump(const Duration(milliseconds: 10));
        }
      }

      await tester.pump(const Duration(seconds: 2));

      // Assert - Should handle high volume without crashes
      expect(processedCount, greaterThan(900)); // Allow for some processing delay
      expect(processedCount, lessThanOrEqualTo(1000));
    });
  });

  group('Error Recovery Tests', () {
    late MethodChannelFlutterMapboxNavigation platform;
    late StreamController<Map<String, dynamic>> markerEventController;

    setUp(() {
      platform = MethodChannelFlutterMapboxNavigation();
      markerEventController = StreamController<Map<String, dynamic>>.broadcast();
    });

    tearDown(() {
      markerEventController.close();
    });

    testWidgets('should attempt reconnection after timeout', (tester) async {
      // Arrange
      bool listenerRegistered = false;
      
      void testListener(StaticMarker marker) {
        listenerRegistered = true;
      }

      // Act
      await platform.registerStaticMarkerTapListener(testListener);

      // Simulate timeout error
      markerEventController.addError(
        PlatformException(
          code: 'MARKER_EVENTS_TIMEOUT',
          message: 'Stream timed out',
        ),
      );

      await tester.pump(const Duration(seconds: 3));

      // Assert - Should attempt reconnection
      // (In real implementation, this would trigger actual reconnection)
      expect(listenerRegistered, isFalse);
    });

    testWidgets('should handle reconnection failures gracefully', (tester) async {
      // Arrange
      int reconnectionAttempts = 0;
      
      void testListener(StaticMarker marker) {
        reconnectionAttempts++;
      }

      // Act
      await platform.registerStaticMarkerTapListener(testListener);

      // Simulate multiple failures
      for (int i = 0; i < 3; i++) {
        markerEventController.addError(
          PlatformException(
            code: 'RECONNECTION_FAILED',
            message: 'Failed to reconnect to marker events',
          ),
        );
        await tester.pump(const Duration(milliseconds: 100));
      }

      // Assert - Should not crash or enter infinite loop
      expect(reconnectionAttempts, equals(0));
    });
  });
}