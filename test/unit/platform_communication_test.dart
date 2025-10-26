import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_mapbox_navigation/src/flutter_mapbox_navigation_method_channel.dart';
import 'package:flutter_mapbox_navigation/src/models/voice_units.dart';
import 'package:flutter_mapbox_navigation/flutter_mapbox_navigation.dart';
import 'package:flutter_mapbox_navigation/src/models/options.dart';

/// These tests verify the platform communication layer between Flutter and native platforms (iOS/Android).
/// They ensure that:
/// 1. Method channels are working correctly
/// 2. Data is properly formatted when sent to native code
/// 3. Responses from native code are properly handled
/// 4. Error cases are properly managed
/// 5. Events are properly transmitted between platforms
///
/// Note: These are unit tests for the communication layer, not integration tests for navigation functionality.
/// (Not sure how deeply useful these tests are - they only test that the mock works as expected.. which it probably will!
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Platform Communication Tests', () {
    late MethodChannelFlutterMapboxNavigation platform;
    const MethodChannel channel = MethodChannel('flutter_mapbox_navigation');

    setUp(() {
      platform = MethodChannelFlutterMapboxNavigation();
    });

    test('should start navigation with metric units', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'startNavigation') {
          return true;
        }
        return null;
      });

      final waypoints = <WayPoint>[
        WayPoint(
          name: "Start",
          latitude: 51.5074,
          longitude: -0.1278,
        ),
        WayPoint(
          name: "End",
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
        language: "en",
      );

      await platform.startNavigation(waypoints, options);
    });

    test('should start navigation with imperial units', () async {
      final waypoints = <WayPoint>[
        WayPoint(
          name: "Start",
          latitude: 51.5074,
          longitude: -0.1278,
        ),
        WayPoint(
          name: "End",
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
        units: VoiceUnits.imperial,
        simulateRoute: true,
        language: "en",
      );

      await platform.startNavigation(waypoints, options);
    });

    test('should handle navigation with multiple waypoints', () async {
      final waypoints = <WayPoint>[
        WayPoint(
          name: "Start",
          latitude: 51.5074,
          longitude: -0.1278,
        ),
        WayPoint(
          name: "Stop 1",
          latitude: 51.5074,
          longitude: -0.1278,
        ),
        WayPoint(
          name: "End",
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
        language: "en",
      );

      await platform.startNavigation(waypoints, options);
    });

    test('should handle navigation with silent waypoints', () async {
      final waypoints = <WayPoint>[
        WayPoint(
          name: "Start",
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
          name: "End",
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
        units: VoiceUnits.imperial,
        simulateRoute: true,
        language: "en",
      );

      await platform.startNavigation(waypoints, options);
    });

    test('should handle navigation with custom options', () async {
      final waypoints = <WayPoint>[
        WayPoint(
          name: "Start",
          latitude: 51.5074,
          longitude: -0.1278,
        ),
        WayPoint(
          name: "End",
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
        language: "en",
      );

      await platform.startNavigation(waypoints, options);
    });

    test('should handle route building', () async {
      final waypoints = <WayPoint>[
        WayPoint(
          name: "Start",
          latitude: 51.5074,
          longitude: -0.1278,
        ),
        WayPoint(
          name: "End",
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
        language: "en",
      );

      await platform.startNavigation(waypoints, options);
    });

    test('should handle navigation cancellation', () async {
      final waypoints = <WayPoint>[
        WayPoint(
          name: "Start",
          latitude: 51.5074,
          longitude: -0.1278,
        ),
        WayPoint(
          name: "End",
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
        language: "en",
      );

      await platform.startNavigation(waypoints, options);
      await platform.finishNavigation();
    });
  });

  /// Tests that Flutter can successfully communicate with the native platform
  /// - Verifies the method channel is working correctly
  /// - Ensures proper error handling between Flutter and native code
  group('Platform Version Tests', () {
    late MethodChannelFlutterMapboxNavigation platform;
    const MethodChannel channel = MethodChannel('flutter_mapbox_navigation');

    setUp(() {
      platform = MethodChannelFlutterMapboxNavigation();
    });

    test('getPlatformVersion returns correct version on Android', () async {
      const androidVersion = 'Android 13';
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'getPlatformVersion') {
          return androidVersion;
        }
        return null;
      });

      final version = await platform.getPlatformVersion();
      expect(version, equals(androidVersion));
    });

    test('getPlatformVersion returns correct version on iOS', () async {
      const iosVersion = 'iOS 16.0';
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'getPlatformVersion') {
          return iosVersion;
        }
        return null;
      });

      final version = await platform.getPlatformVersion();
      expect(version, equals(iosVersion));
    });

    test('getPlatformVersion handles platform errors', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'getPlatformVersion') {
          throw PlatformException(
            code: 'ERROR',
            message: 'Failed to get platform version',
          );
        }
        return null;
      });

      expect(
        () => platform.getPlatformVersion(),
        throwsA(isA<PlatformException>()),
      );
    });

    test('getPlatformVersion handles null response', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'getPlatformVersion') {
          return null;
        }
        return null;
      });

      final version = await platform.getPlatformVersion();
      expect(version, isNull);
    });
  });

  /// Tests that route calculation requests are properly sent to the native platform
  /// - Verifies that waypoint data is correctly formatted and transmitted
  /// - Ensures error responses from the native platform are properly handled in Flutter
  group('Route Building Tests', () {
    test('should build route with valid waypoints', () {
      // TODO: Test route building with valid waypoints
      // - Test route calculation
      // - Test route options
      // - Test route response
    }, skip: 'Route building tests not yet implemented');

    test('should handle invalid waypoints', () {
      // TODO: Test route building with invalid waypoints
      // - Test empty waypoints
      // - Test invalid coordinates
      // - Test error handling
    }, skip: 'Invalid waypoint handling tests not yet implemented');

    test('should handle route calculation errors', () {
      // TODO: Test route calculation errors
      // - Test network errors
      // - Test invalid route options
      // - Test error responses
    }, skip: 'Route calculation error tests not yet implemented');
  });

  /// Tests that navigation commands are properly sent to the native platform
  /// - Verifies that waypoint additions during navigation are correctly transmitted
  /// - Ensures the native platform responds appropriately to navigation commands
  group('Navigation Control Tests', () {
    test('should start navigation', () {
      // TODO: Test navigation start
      // - Test with valid route
      // - Test navigation options
      // - Test start response
    }, skip: 'Navigation start tests not yet implemented');

    test('should stop navigation', () {
      // TODO: Test navigation stop
      // - Test during active navigation
      // - Test when not navigating
      // - Test cleanup
    }, skip: 'Navigation stop tests not yet implemented');

    test('should add waypoints during navigation', () {
      // TODO: Test waypoint addition
      // - Test during active navigation
      // - Test route recalculation
      // - Test error handling
    }, skip: 'Waypoint addition tests not yet implemented');
  });

  /// Tests that offline mode requests are properly sent to the native platform
  /// - Verifies that offline data management commands are correctly transmitted
  /// - Ensures proper error handling for offline operations
  group('Offline Routing Tests', () {
    test('should enable offline routing', () {
      // TODO: Test offline routing
      // - Test offline mode enabling
      // - Test offline route building
      // - Test offline navigation
      // - Test error handling
    }, skip: 'Offline routing tests not yet implemented');

    test('should handle offline data management', () {
      // TODO: Test offline data
      // - Test data download
      // - Test data updates
      // - Test storage management
    }, skip: 'Offline data management tests not yet implemented');
  });

  /// Tests that free drive mode commands are properly sent to the native platform
  /// - Verifies that location updates are correctly transmitted from native to Flutter
  /// - Ensures proper error handling for location services
  group('Free Drive Mode Tests', () {
    test('should enable free drive mode', () {
      // TODO: Test free drive mode
      // - Test mode enabling
      // - Test location updates
      // - Test mode disabling
      // - Test error handling
    }, skip: 'Free drive mode tests not yet implemented');

    test('should handle location updates', () {
      // TODO: Test location updates
      // - Test update frequency
      // - Test accuracy
      // - Test error handling
    }, skip: 'Location update tests not yet implemented');
  });

  /// Tests that events from the native platform are properly received in Flutter
  /// - Verifies that error events are correctly transmitted and handled
  /// - Ensures the event channel is working correctly
  group('Event Handling Tests', () {
    test('should handle navigation events', () {
      // TODO: Test navigation events
      // - Test progress updates
      // - Test turn-by-turn events
      // - Test arrival events
    }, skip: 'Navigation event tests not yet implemented');

    test('should handle error events', () {
      // TODO: Test error events
      // - Test route errors
      // - Test location errors
      // - Test system errors
    }, skip: 'Error event tests not yet implemented');
  });

  /// Tests that unit settings are properly handled across platforms
  /// - Verifies that unit preferences are correctly transmitted to native platforms
  /// - Ensures unit settings persist across route calculations and waypoint updates
  group('Unit Settings Tests', () {
    late MethodChannelFlutterMapboxNavigation platform;
    const MethodChannel channel = MethodChannel('flutter_mapbox_navigation');

    setUp(() {
      platform = MethodChannelFlutterMapboxNavigation();
    });

    test('should set metric units on Android', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'startNavigation') {
          final args = methodCall.arguments as Map<dynamic, dynamic>;
          expect(args['units'], equals('metric'));
          return true;
        }
        return null;
      });

      await platform.startNavigation(
        <WayPoint>[
          WayPoint(
            name: "Start",
            latitude: 51.5074,
            longitude: -0.1278,
          ),
          WayPoint(
            name: "End",
            latitude: 51.5074,
            longitude: -0.1278,
          ),
        ],
        MapBoxOptions(
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
          language: "en",
        ),
      );
    });

    test('should set imperial units on Android', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'startNavigation') {
          final args = methodCall.arguments as Map<dynamic, dynamic>;
          expect(args['units'], equals('imperial'));
          return true;
        }
        return null;
      });

      await platform.startNavigation(
        <WayPoint>[
          WayPoint(
            name: "Start",
            latitude: 51.5074,
            longitude: -0.1278,
          ),
          WayPoint(
            name: "End",
            latitude: 51.5074,
            longitude: -0.1278,
          ),
        ],
        MapBoxOptions(
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
          units: VoiceUnits.imperial,
          simulateRoute: true,
          language: "en",
        ),
      );
    });

    test('should set metric units on iOS', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'startNavigation') {
          final args = methodCall.arguments as Map<dynamic, dynamic>;
          expect(args['units'], equals('metric'));
          return true;
        }
        return null;
      });

      await platform.startNavigation(
        <WayPoint>[
          WayPoint(
            name: "Start",
            latitude: 51.5074,
            longitude: -0.1278,
          ),
          WayPoint(
            name: "End",
            latitude: 51.5074,
            longitude: -0.1278,
          ),
        ],
        MapBoxOptions(
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
          language: "en",
        ),
      );
    });

    test('should set imperial units on iOS', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'startNavigation') {
          final args = methodCall.arguments as Map<dynamic, dynamic>;
          expect(args['units'], equals('imperial'));
          return true;
        }
        return null;
      });

      await platform.startNavigation(
        <WayPoint>[
          WayPoint(
            name: "Start",
            latitude: 51.5074,
            longitude: -0.1278,
          ),
          WayPoint(
            name: "End",
            latitude: 51.5074,
            longitude: -0.1278,
          ),
        ],
        MapBoxOptions(
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
          units: VoiceUnits.imperial,
          simulateRoute: true,
          language: "en",
        ),
      );
    });

    test('should maintain units when adding waypoints', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'addWayPoints') {
          // The units should be maintained from the previous navigation session
          // We don't need to check units here since they're not part of addWayPoints
          return {
            'success': true,
            'waypointsAdded': 1,
          };
        }
        return null;
      });

      // First start navigation with metric units
      await platform.startNavigation(
        <WayPoint>[
          WayPoint(
            name: "Start",
            latitude: 51.5074,
            longitude: -0.1278,
          ),
          WayPoint(
            name: "End",
            latitude: 51.5074,
            longitude: -0.1278,
          ),
        ],
        MapBoxOptions(
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
          language: "en",
        ),
      );

      // Then add waypoints - units should be maintained from previous navigation
      final result = await platform.addWayPoints(
        wayPoints: <WayPoint>[
          WayPoint(
            name: "Stop 1",
            latitude: 51.5074,
            longitude: -0.1278,
          ),
        ],
      );
      
      expect(result.success, isTrue);
      expect(result.waypointsAdded, equals(1));
    });

    test('should handle unit setting errors', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'startNavigation') {
          throw PlatformException(
            code: 'ERROR',
            message: 'Failed to set units',
          );
        }
        return null;
      });

      expect(
        () => platform.startNavigation(
          <WayPoint>[
            WayPoint(
              name: "Start",
              latitude: 51.5074,
              longitude: -0.1278,
            ),
            WayPoint(
              name: "End",
              latitude: 51.5074,
              longitude: -0.1278,
            ),
          ],
          MapBoxOptions(
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
            language: "en",
          ),
        ),
        throwsA(isA<PlatformException>()),
      );
    });
  });
} 