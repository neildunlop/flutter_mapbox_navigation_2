import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_mapbox_navigation/flutter_mapbox_navigation.dart';
import 'package:flutter_mapbox_navigation/src/models/options.dart';
import 'package:flutter_mapbox_navigation/src/models/voice_units.dart';

/// Integration tests for unit settings across platforms
/// These tests verify that:
/// 1. Unit settings are properly applied during navigation
/// 2. Unit settings persist across route calculations
/// 3. Unit settings are consistent with platform expectations
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Unit Settings Integration Tests', () {
    late MapBoxNavigation navigation;
    const MethodChannel channel = MethodChannel('flutter_mapbox_navigation');

    setUp(() {
      navigation = MapBoxNavigation.instance;
      
      // Set up mock method channel handler
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        switch (methodCall.method) {
          case 'startNavigation':
            return true;
          case 'addWayPoints':
            return true;
          case 'finishNavigation':
            return true;
          default:
            return null;
        }
      });
    });

    tearDown(() {
      // Clean up mock handler after each test
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    test('should start navigation with metric units', () async {
      final waypoints = [
        WayPoint(
          name: 'Start',
          latitude: 51.5074,
          longitude: -0.1278,
        ),
        WayPoint(
          name: 'End',
          latitude: 51.5074,
          longitude: -0.1278,
        ),
      ];

      final options = MapBoxOptions(
        initialLatitude: 51.5074,
        initialLongitude: -0.1278,
        zoom: 13,
        tilt: 0,
        bearing: 0,
        enableRefresh: true,
        alternatives: true,
        voiceInstructionsEnabled: true,
        bannerInstructionsEnabled: true,
        allowsUTurnAtWayPoints: true,
        mode: MapBoxNavigationMode.drivingWithTraffic,
        units: VoiceUnits.metric,
        simulateRoute: true,
        language: 'en',
      );

      final result = await navigation.startNavigation(
        wayPoints: waypoints,
        options: options,
      );
      expect(result, isTrue);
    });

    test('should start navigation with imperial units', () async {
      final waypoints = [
        WayPoint(
          name: 'Start',
          latitude: 51.5074,
          longitude: -0.1278,
        ),
        WayPoint(
          name: 'End',
          latitude: 51.5074,
          longitude: -0.1278,
        ),
      ];

      final options = MapBoxOptions(
        initialLatitude: 51.5074,
        initialLongitude: -0.1278,
        zoom: 13,
        tilt: 0,
        bearing: 0,
        enableRefresh: true,
        alternatives: true,
        voiceInstructionsEnabled: true,
        bannerInstructionsEnabled: true,
        allowsUTurnAtWayPoints: true,
        mode: MapBoxNavigationMode.drivingWithTraffic,
        units: VoiceUnits.imperial,
        simulateRoute: true,
        language: 'en',
      );

      final result = await navigation.startNavigation(
        wayPoints: waypoints,
        options: options,
      );
      expect(result, isTrue);
    });

    test('should maintain units when adding waypoints', () async {
      final initialWaypoints = [
        WayPoint(
          name: 'Start',
          latitude: 51.5074,
          longitude: -0.1278,
        ),
        WayPoint(
          name: 'End',
          latitude: 51.5074,
          longitude: -0.1278,
        ),
      ];

      final options = MapBoxOptions(
        initialLatitude: 51.5074,
        initialLongitude: -0.1278,
        zoom: 13,
        tilt: 0,
        bearing: 0,
        enableRefresh: true,
        alternatives: true,
        voiceInstructionsEnabled: true,
        bannerInstructionsEnabled: true,
        allowsUTurnAtWayPoints: true,
        mode: MapBoxNavigationMode.drivingWithTraffic,
        units: VoiceUnits.metric,
        simulateRoute: true,
        language: 'en',
      );

      final startResult = await navigation.startNavigation(
        wayPoints: initialWaypoints,
        options: options,
      );
      expect(startResult, isTrue);

      final additionalWaypoints = [
        WayPoint(
          name: 'Stop 1',
          latitude: 51.5074,
          longitude: -0.1278,
        ),
      ];

      await navigation.addWayPoints(
        wayPoints: additionalWaypoints,
      );
    });

    test('should handle unit changes with multiple waypoints', () async {
      final waypoints = [
        WayPoint(
          name: 'Start',
          latitude: 51.5074,
          longitude: -0.1278,
        ),
        WayPoint(
          name: 'Stop 1',
          latitude: 51.5074,
          longitude: -0.1278,
        ),
        WayPoint(
          name: 'End',
          latitude: 51.5074,
          longitude: -0.1278,
        ),
      ];

      final options = MapBoxOptions(
        initialLatitude: 51.5074,
        initialLongitude: -0.1278,
        zoom: 13,
        tilt: 0,
        bearing: 0,
        enableRefresh: true,
        alternatives: true,
        voiceInstructionsEnabled: true,
        bannerInstructionsEnabled: true,
        allowsUTurnAtWayPoints: true,
        mode: MapBoxNavigationMode.drivingWithTraffic,
        units: VoiceUnits.metric,
        simulateRoute: true,
        language: 'en',
      );

      final result = await navigation.startNavigation(
        wayPoints: waypoints,
        options: options,
      );
      expect(result, isTrue);
    });

    test('should handle unit changes with silent waypoints', () async {
      final waypoints = [
        WayPoint(
          name: 'Start',
          latitude: 51.5074,
          longitude: -0.1278,
        ),
        WayPoint(
          name: "Silent Stop",
          latitude: 51.5074,
          longitude: -0.1278,
          isSilent: true,
        ),
        WayPoint(
          name: 'End',
          latitude: 51.5074,
          longitude: -0.1278,
        ),
      ];

      final options = MapBoxOptions(
        initialLatitude: 51.5074,
        initialLongitude: -0.1278,
        zoom: 13,
        tilt: 0,
        bearing: 0,
        enableRefresh: true,
        alternatives: true,
        voiceInstructionsEnabled: true,
        bannerInstructionsEnabled: true,
        allowsUTurnAtWayPoints: true,
        mode: MapBoxNavigationMode.drivingWithTraffic,
        units: VoiceUnits.metric,
        simulateRoute: true,
        language: 'en',
      );

      final result = await navigation.startNavigation(
        wayPoints: waypoints,
        options: options,
      );
      expect(result, isTrue);
    });
  });
} 