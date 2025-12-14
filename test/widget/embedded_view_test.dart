import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_mapbox_navigation/src/embedded/view.dart';
import 'package:flutter_mapbox_navigation/src/embedded/controller.dart';
import 'package:flutter_mapbox_navigation/src/models/models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MapBoxNavigationView', () {
    test('should have correct viewType constant', () {
      expect(MapBoxNavigationView.viewType, 'FlutterMapboxNavigationView');
    });

    testWidgets('should create widget with options', (tester) async {
      final options = MapBoxOptions(
        zoom: 15.0,
        tilt: 0.0,
        bearing: 0.0,
        enableRefresh: false,
        alternatives: true,
        voiceInstructionsEnabled: true,
        bannerInstructionsEnabled: true,
        allowsUTurnAtWayPoints: true,
        mode: MapBoxNavigationMode.driving,
        simulateRoute: false,
        animateBuildRoute: true,
        longPressDestinationEnabled: true,
        units: VoiceUnits.metric,
      );

      // The widget requires Platform.isAndroid or Platform.isIOS
      // In test environment, we can't fully test platform-specific behavior
      // but we can verify the widget is created without errors
      expect(
        () => MapBoxNavigationView(
          options: options,
          onCreated: (controller) {},
          onRouteEvent: (event) {},
        ),
        returnsNormally,
      );
    });

    testWidgets('should create widget with null callbacks', (tester) async {
      final options = MapBoxOptions(units: VoiceUnits.metric);

      expect(
        () => MapBoxNavigationView(options: options),
        returnsNormally,
      );
    });

    testWidgets('should pass options to widget', (tester) async {
      final options = MapBoxOptions(
        zoom: 18.0,
        simulateRoute: true,
        units: VoiceUnits.metric,
      );

      final widget = MapBoxNavigationView(
        options: options,
        onCreated: (controller) {},
      );

      expect(widget.options, equals(options));
      expect(widget.options?.zoom, 18.0);
      expect(widget.options?.simulateRoute, true);
    });

    testWidgets('should have onCreated callback', (tester) async {
      MapBoxNavigationViewController? capturedController;

      final widget = MapBoxNavigationView(
        options: MapBoxOptions(units: VoiceUnits.metric),
        onCreated: (controller) {
          capturedController = controller;
        },
      );

      expect(widget.onCreated, isNotNull);
    });

    testWidgets('should have onRouteEvent callback', (tester) async {
      RouteEvent? capturedEvent;

      final widget = MapBoxNavigationView(
        options: MapBoxOptions(units: VoiceUnits.metric),
        onRouteEvent: (event) {
          capturedEvent = event;
        },
      );

      expect(widget.onRouteEvent, isNotNull);
    });

    // Note: Platform-specific rendering (Android/iOS) requires integration tests
    // on actual devices or emulators. The following tests verify the structure
    // without requiring platform-specific code.

    testWidgets('widget should be a StatelessWidget', (tester) async {
      final widget = MapBoxNavigationView(
        options: MapBoxOptions(units: VoiceUnits.metric),
      );

      expect(widget, isA<StatelessWidget>());
    });
  });

  group('OnNavigationViewCreatedCallBack', () {
    test('should be a valid function type', () {
      // Verify the callback type is correctly defined
      OnNavigationViewCreatedCallBack? callback;

      callback = (MapBoxNavigationViewController controller) {
        // Callback implementation
      };

      expect(callback, isNotNull);
    });

    test('should accept MapBoxNavigationViewController parameter', () {
      var callbackInvoked = false;

      final callback = (MapBoxNavigationViewController controller) {
        callbackInvoked = true;
      };

      // We can't create a real controller without platform channels,
      // but we can verify the callback signature
      expect(callback, isA<Function>());
    });
  });

  group('MapBoxOptions integration', () {
    test('should convert options to map correctly', () {
      final options = MapBoxOptions(
        zoom: 15.0,
        tilt: 45.0,
        bearing: 90.0,
        enableRefresh: true,
        alternatives: true,
        voiceInstructionsEnabled: true,
        bannerInstructionsEnabled: true,
        allowsUTurnAtWayPoints: false,
        mode: MapBoxNavigationMode.drivingWithTraffic,
        simulateRoute: true,
        animateBuildRoute: false,
        longPressDestinationEnabled: false,
        units: VoiceUnits.imperial,
      );

      final map = options.toMap();

      expect(map['zoom'], 15.0);
      expect(map['tilt'], 45.0);
      expect(map['bearing'], 90.0);
      expect(map['enableRefresh'], true);
      expect(map['alternatives'], true);
      expect(map['voiceInstructionsEnabled'], true);
      expect(map['bannerInstructionsEnabled'], true);
      expect(map['allowsUTurnAtWayPoints'], false);
      expect(map['simulateRoute'], true);
      expect(map['animateBuildRoute'], false);
      expect(map['longPressDestinationEnabled'], false);
    });

    test('should handle null values in options', () {
      final options = MapBoxOptions(units: VoiceUnits.metric);
      final map = options.toMap();

      // Default values should be present
      expect(map, isNotEmpty);
    });

    test('should handle different navigation modes', () {
      final drivingOptions = MapBoxOptions(
        mode: MapBoxNavigationMode.driving,
        units: VoiceUnits.metric,
      );
      final trafficOptions = MapBoxOptions(
        mode: MapBoxNavigationMode.drivingWithTraffic,
        units: VoiceUnits.metric,
      );
      final walkingOptions = MapBoxOptions(
        mode: MapBoxNavigationMode.walking,
        units: VoiceUnits.metric,
      );
      final cyclingOptions = MapBoxOptions(
        mode: MapBoxNavigationMode.cycling,
        units: VoiceUnits.metric,
      );

      expect(drivingOptions.mode, MapBoxNavigationMode.driving);
      expect(trafficOptions.mode, MapBoxNavigationMode.drivingWithTraffic);
      expect(walkingOptions.mode, MapBoxNavigationMode.walking);
      expect(cyclingOptions.mode, MapBoxNavigationMode.cycling);
    });

    test('should handle different voice units', () {
      final metricOptions = MapBoxOptions(units: VoiceUnits.metric);
      final imperialOptions = MapBoxOptions(units: VoiceUnits.imperial);

      expect(metricOptions.units, VoiceUnits.metric);
      expect(imperialOptions.units, VoiceUnits.imperial);
    });
  });
}
