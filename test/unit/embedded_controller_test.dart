import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_mapbox_navigation/src/embedded/controller.dart';
import 'package:flutter_mapbox_navigation/src/models/models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MapBoxNavigationViewController', () {
    late MapBoxNavigationViewController controller;
    late List<MethodCall> methodCalls;
    const viewId = 123;

    setUp(() {
      methodCalls = [];

      // Set up mock method channel handler
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        MethodChannel('flutter_mapbox_navigation/$viewId'),
        (MethodCall call) async {
          methodCalls.add(call);

          switch (call.method) {
            case 'getPlatformVersion':
              return 'Test Platform 1.0';
            case 'getDistanceRemaining':
              return 1500.5;
            case 'getDurationRemaining':
              return 900.0;
            case 'buildRoute':
              return true;
            case 'clearRoute':
              return true;
            case 'startFreeDrive':
              return true;
            case 'startNavigation':
              return true;
            case 'finishNavigation':
              return true;
            default:
              return null;
          }
        },
      );

      controller = MapBoxNavigationViewController(viewId, null);
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        MethodChannel('flutter_mapbox_navigation/$viewId'),
        null,
      );
    });

    group('Constructor', () {
      test('should create controller with view id', () {
        expect(controller, isNotNull);
      });

      test('should accept route event notifier', () {
        RouteEvent? capturedEvent;
        final controllerWithNotifier = MapBoxNavigationViewController(
          viewId,
          (event) => capturedEvent = event,
        );

        expect(controllerWithNotifier, isNotNull);
      });
    });

    group('platformVersion', () {
      test('should return platform version string', () async {
        final version = await controller.platformVersion;

        expect(version, 'Test Platform 1.0');
        expect(methodCalls.length, 1);
        expect(methodCalls.first.method, 'getPlatformVersion');
      });
    });

    group('distanceRemaining', () {
      test('should return remaining distance', () async {
        final distance = await controller.distanceRemaining;

        expect(distance, 1500.5);
        expect(methodCalls.any((c) => c.method == 'getDistanceRemaining'), isTrue);
      });
    });

    group('durationRemaining', () {
      test('should return remaining duration', () async {
        final duration = await controller.durationRemaining;

        expect(duration, 900.0);
        expect(methodCalls.any((c) => c.method == 'getDurationRemaining'), isTrue);
      });
    });

    group('buildRoute', () {
      test('should build route with waypoints', () async {
        final wayPoints = [
          WayPoint(
            name: 'Origin',
            latitude: 51.5074,
            longitude: -0.1278,
          ),
          WayPoint(
            name: 'Destination',
            latitude: 48.8566,
            longitude: 2.3522,
          ),
        ];

        final result = await controller.buildRoute(wayPoints: wayPoints);

        expect(result, isTrue);
        expect(methodCalls.any((c) => c.method == 'buildRoute'), isTrue);
      });

      test('should build route with options', () async {
        final wayPoints = [
          WayPoint(name: 'Start', latitude: 51.5, longitude: -0.1),
          WayPoint(name: 'End', latitude: 51.6, longitude: -0.2),
        ];
        final options = MapBoxOptions(
          simulateRoute: true,
          mode: MapBoxNavigationMode.driving,
          units: VoiceUnits.metric,
        );

        final result = await controller.buildRoute(
          wayPoints: wayPoints,
          options: options,
        );

        expect(result, isTrue);

        final buildRouteCall = methodCalls.firstWhere(
          (c) => c.method == 'buildRoute',
        );
        expect(buildRouteCall.arguments['simulateRoute'], isTrue);
      });

      test('should include waypoint data in arguments', () async {
        final wayPoints = [
          WayPoint(name: 'A', latitude: 10.0, longitude: 20.0),
          WayPoint(name: 'B', latitude: 30.0, longitude: 40.0, isSilent: true),
          WayPoint(name: 'C', latitude: 50.0, longitude: 60.0),
        ];

        await controller.buildRoute(wayPoints: wayPoints);

        final buildRouteCall = methodCalls.firstWhere(
          (c) => c.method == 'buildRoute',
        );
        final args = buildRouteCall.arguments as Map<dynamic, dynamic>;
        final wayPointMap = args['wayPoints'] as Map<dynamic, dynamic>;

        expect(wayPointMap.length, 3);
        expect(wayPointMap[0]['Name'], 'A');
        expect(wayPointMap[1]['Name'], 'B');
        expect(wayPointMap[1]['IsSilent'], true);
        expect(wayPointMap[2]['Name'], 'C');
      });
    });

    group('clearRoute', () {
      test('should clear route', () async {
        final result = await controller.clearRoute();

        expect(result, isTrue);
        expect(methodCalls.any((c) => c.method == 'clearRoute'), isTrue);
      });
    });

    group('startFreeDrive', () {
      test('should start free drive without options', () async {
        final result = await controller.startFreeDrive();

        expect(result, isTrue);
        expect(methodCalls.any((c) => c.method == 'startFreeDrive'), isTrue);
      });

      test('should start free drive with options', () async {
        final options = MapBoxOptions(zoom: 18.0, units: VoiceUnits.metric);
        final result = await controller.startFreeDrive(options: options);

        expect(result, isTrue);

        final startCall = methodCalls.firstWhere(
          (c) => c.method == 'startFreeDrive',
        );
        expect(startCall.arguments['zoom'], 18.0);
      });
    });

    group('startNavigation', () {
      test('should start navigation without options', () async {
        final result = await controller.startNavigation();

        expect(result, isTrue);
        expect(methodCalls.any((c) => c.method == 'startNavigation'), isTrue);
      });

      test('should start navigation with options', () async {
        final options = MapBoxOptions(
          simulateRoute: true,
          voiceInstructionsEnabled: true,
          units: VoiceUnits.metric,
        );
        final result = await controller.startNavigation(options: options);

        expect(result, isTrue);

        final startCall = methodCalls.firstWhere(
          (c) => c.method == 'startNavigation',
        );
        expect(startCall.arguments['simulateRoute'], isTrue);
        expect(startCall.arguments['voiceInstructionsEnabled'], isTrue);
      });
    });

    group('finishNavigation', () {
      test('should finish navigation', () async {
        final result = await controller.finishNavigation();

        expect(result, isTrue);
        expect(methodCalls.any((c) => c.method == 'finishNavigation'), isTrue);
      });
    });

    group('dispose', () {
      test('should dispose without error after initialize', () async {
        // Initialize first to set up the subscription
        await controller.initialize();

        // Now dispose should work
        expect(() => controller.dispose(), returnsNormally);
      });

      test('should dispose without error after buildRoute', () async {
        final wayPoints = [
          WayPoint(name: 'A', latitude: 10.0, longitude: 20.0),
          WayPoint(name: 'B', latitude: 30.0, longitude: 40.0),
        ];

        await controller.buildRoute(wayPoints: wayPoints);

        expect(() => controller.dispose(), returnsNormally);
      });
    });

    group('initialize', () {
      test('should initialize without error', () async {
        // Initialize sets up event stream subscription
        expect(() => controller.initialize(), returnsNormally);
      });
    });
  });

  group('RouteEvent parsing', () {
    test('should identify progress event correctly', () {
      final progressJson = {
        'arrived': false,
        'distance': 1000.0,
        'duration': 600.0,
        'distanceTraveled': 500.0,
      };

      final progressEvent = RouteProgressEvent.fromJson(progressJson);

      expect(progressEvent.isProgressEvent, isTrue);
      expect(progressEvent.arrived, false);
      expect(progressEvent.distance, 1000.0);
    });

    test('should identify non-progress event correctly', () {
      final nonProgressJson = <String, dynamic>{
        'eventType': 'route_built',
        'data': 'route_data',
      };

      // RouteProgressEvent without 'arrived' field
      final progressJson = <String, dynamic>{
        'distance': 1000.0,
      };

      final progressEvent = RouteProgressEvent.fromJson(progressJson);

      expect(progressEvent.isProgressEvent, false);
    });
  });

  group('Method call handling', () {
    test('should handle sendFromNative method', () async {
      const viewId = 456;
      late MapBoxNavigationViewController controller;
      String? receivedText;

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        MethodChannel('flutter_mapbox_navigation/$viewId'),
        (MethodCall call) async {
          return null;
        },
      );

      controller = MapBoxNavigationViewController(viewId, null);

      // The _handleMethod is private, but we can verify the controller
      // is set up correctly for handling method calls
      expect(controller, isNotNull);

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        MethodChannel('flutter_mapbox_navigation/$viewId'),
        null,
      );
    });
  });
}
