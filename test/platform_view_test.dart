import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_mapbox_navigation/src/models/models.dart';
import 'package:flutter_mapbox_navigation/src/widgets/flutter_fullscreen_navigation.dart';

void main() {
  group('Flutter FullScreen Navigation Platform View Tests', () {
    testWidgets('should create FlutterFullScreenNavigation widget', (tester) async {
      final home = WayPoint(
        name: "Home",
        latitude: 37.77440680146262,
        longitude: -122.43539772352648,
        isSilent: false,
      );

      final store = WayPoint(
        name: "Store",
        latitude: 37.76556957793795,
        longitude: -122.42409811526268,
        isSilent: false,
      );

      final wayPoints = [home, store];
      final options = MapBoxOptions(
        simulateRoute: true,
        voiceInstructionsEnabled: true,
        bannerInstructionsEnabled: true,
        units: VoiceUnits.metric,
      );

      bool markerTapped = false;
      bool mapTapped = false;
      bool navigationFinished = false;

      await tester.pumpWidget(
        MaterialApp(
          home: FlutterFullScreenNavigation(
            wayPoints: wayPoints,
            options: options,
            onMarkerTap: (marker) {
              markerTapped = true;
            },
            onMapTap: (lat, lng) {
              mapTapped = true;
            },
            onNavigationFinished: () {
              navigationFinished = true;
            },
            showDebugOverlay: true,
          ),
        ),
      );

      // Let the widget settle
      await tester.pump();
      
      // Verify the widget tree contains expected elements
      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(Stack), findsWidgets);
      
      // Look for navigation UI elements
      expect(find.byIcon(Icons.close), findsOneWidget);
      
      // Verify the widget was created without errors
      expect(find.byType(FlutterFullScreenNavigation), findsOneWidget);
    });

    testWidgets('should handle marker overlay animation', (tester) async {
      final wayPoints = [
        WayPoint(name: "Start", latitude: 37.7749, longitude: -122.4194, isSilent: false),
        WayPoint(name: "End", latitude: 37.7849, longitude: -122.4094, isSilent: false),
      ];

      final options = MapBoxOptions(
        simulateRoute: true,
        units: VoiceUnits.metric,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: FlutterFullScreenNavigation(
            wayPoints: wayPoints,
            options: options,
          ),
        ),
      );

      await tester.pump();

      // Verify animation controllers are set up (no exceptions thrown)
      expect(find.byType(FlutterFullScreenNavigation), findsOneWidget);
    });

    test('should create navigation arguments correctly', () {
      final wayPoints = [
        WayPoint(name: "Origin", latitude: 37.7749, longitude: -122.4194, isSilent: false),
        WayPoint(name: "Destination", latitude: 37.7849, longitude: -122.4094, isSilent: false),
      ];

      final options = MapBoxOptions(
        simulateRoute: true,
        voiceInstructionsEnabled: true,
        bannerInstructionsEnabled: true,
        units: VoiceUnits.metric,
        zoom: 15.0,
        bearing: 0.0,
        tilt: 0.0,
      );

      // Test that waypoints and options can be created without errors
      expect(wayPoints.length, equals(2));
      expect(wayPoints[0].name, equals("Origin"));
      expect(wayPoints[1].name, equals("Destination"));
      
      expect(options.simulateRoute, isTrue);
      expect(options.voiceInstructionsEnabled, isTrue);
      expect(options.units, equals(VoiceUnits.metric));
    });
  });
}