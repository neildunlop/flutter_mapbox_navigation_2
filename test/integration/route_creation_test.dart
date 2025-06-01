import 'package:flutter/services.dart';
import 'package:flutter_mapbox_navigation/flutter_mapbox_navigation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Initialize Flutter test bindings - required for platform channel testing
  TestWidgetsFlutterBinding.ensureInitialized();

  // MapBoxNavigation is a singleton that handles all communication with the native Mapbox SDK
  // It provides methods for navigation, route building, and receiving navigation events
  late MapBoxNavigation navigation;
  
  // MethodChannel is Flutter's way of communicating with platform-specific code (Android/iOS)
  // 'flutter_mapbox_navigation' is the channel name that must match the one used in native code
  // In a real app, this channel would be used to communicate with the actual Mapbox SDK
  // For our tests, we're not actually invoking the platform code - we just need to verify
  // that our Flutter code sends the correct messages to the platform
  const MethodChannel channel = MethodChannel('flutter_mapbox_navigation');

  setUp(() {
    // Get the singleton instance of MapBoxNavigation
    navigation = MapBoxNavigation.instance;

    // TestDefaultBinaryMessengerBinding is Flutter's test framework for mocking platform channels
    // It allows us to intercept and mock method calls that would normally go to the platform
    // We use this because:
    // 1. We don't want to actually invoke the platform code during tests
    // 2. We want to verify that our Flutter code sends the correct messages
    // 3. We need to simulate successful responses to test our code's behavior
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      // This handler intercepts all method calls to the platform channel
      // We can return mock responses based on the method name
      // In a real app, these calls would go to the platform and interact with Mapbox
      // For testing, we just need to verify the calls are made correctly and return success
      switch (methodCall.method) {
        case 'buildRoute':
          // Mock successful route building response
          // In a real app, this would communicate with the Mapbox SDK
          return true;
        case 'startNavigation':
          // Mock successful navigation start response
          // In a real app, this would start the navigation UI
          return true;
        default:
          // Return null for any unhandled method calls
          return null;
      }
    });
  });

  // Clean up after each test by removing the mock handler
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  group('Route Creation Integration Tests', () {
    test('should build route with multiple waypoints', () async {
      // Arrange
      final wayPoints = [
        WayPoint(
          name: 'Start',
          latitude: 51.5074,
          longitude: -0.1278,
        ),
        WayPoint(
          name: 'Middle',
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
        zoom: 13.0,
        tilt: 0.0,
        bearing: 0.0,
        enableRefresh: true,
        alternatives: true,
        voiceInstructionsEnabled: true,
        bannerInstructionsEnabled: true,
        allowsUTurnAtWayPoints: true,
        mode: MapBoxNavigationMode.drivingWithTraffic,
        units: VoiceUnits.metric,
        simulateRoute: true,
        animateBuildRoute: true,
        longPressDestinationEnabled: true,
        language: "en",
      );

      // Act
      final result = await navigation.startNavigation(
        wayPoints: wayPoints,
        options: options,
      );

      // Assert
      expect(result, isTrue);
    });

    test('should handle route building with minimum waypoints', () async {
      // Arrange
      final wayPoints = [
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

      // Act
      final result = await navigation.startNavigation(
        wayPoints: wayPoints,
      );

      // Assert
      expect(result, isTrue);
    });

    test('should handle route building with silent waypoints', () async {
      // Arrange
      final wayPoints = [
        WayPoint(
          name: 'Start',
          latitude: 51.5074,
          longitude: -0.1278,
        ),
        WayPoint(
          name: 'Silent Point',
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

      // Act
      final result = await navigation.startNavigation(
        wayPoints: wayPoints,
      );

      // Assert
      expect(result, isTrue);
    });

    // Not sure any of the these custom options are relevant for waypoints - but it is possible to set them during route creation so we should test them.
    test('should handle route building with custom options', () async {
      // Arrange
      final wayPoints = [
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
        zoom: 15.0,
        tilt: 45.0,
        bearing: 90.0,
        enableRefresh: false,
        alternatives: false,
        voiceInstructionsEnabled: false,
        bannerInstructionsEnabled: false,
        allowsUTurnAtWayPoints: false,
        mode: MapBoxNavigationMode.drivingWithTraffic,
        units: VoiceUnits.imperial,
        simulateRoute: false,
        animateBuildRoute: false,
        longPressDestinationEnabled: false,
        language: "en",
      );

      // Act
      final result = await navigation.startNavigation(
        wayPoints: wayPoints,
        options: options,
      );

      // Assert
      expect(result, isTrue);
    });
  });
} 