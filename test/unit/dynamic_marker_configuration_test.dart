import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_mapbox_navigation/src/models/dynamic_marker_configuration.dart';

void main() {
  group('DynamicMarkerConfiguration Tests', () {
    test('should create configuration with default values', () {
      final config = DynamicMarkerConfiguration();

      // Animation settings
      expect(config.animationDurationMs, 1000);
      expect(config.enableAnimation, true);
      expect(config.animateHeading, true);

      // State thresholds
      expect(config.staleThresholdMs, 10000);
      expect(config.offlineThresholdMs, 30000);
      expect(config.expiredThresholdMs, isNull);
      expect(config.stationarySpeedThreshold, 0.5);
      expect(config.stationaryDurationMs, 30000);

      // Trail settings
      expect(config.enableTrail, false);
      expect(config.maxTrailPoints, 50);
      expect(config.trailColor, const Color(0x7F2196F3));
      expect(config.trailWidth, 3.0);
      expect(config.trailGradient, true);
      expect(config.minTrailPointDistance, 5.0);

      // Prediction settings
      expect(config.enablePrediction, true);
      expect(config.predictionWindowMs, 2000);

      // Display settings
      expect(config.zIndex, 100);
      expect(config.minZoomLevel, 0.0);
      expect(config.maxDistanceFromCenter, isNull);

      // Callbacks
      expect(config.onMarkerTap, isNull);
      expect(config.onMarkerStateChanged, isNull);
      expect(config.onMarkerExpired, isNull);
    });

    test('should create configuration with custom animation settings', () {
      final config = DynamicMarkerConfiguration(
        animationDurationMs: 500,
        enableAnimation: false,
        animateHeading: false,
      );

      expect(config.animationDurationMs, 500);
      expect(config.enableAnimation, false);
      expect(config.animateHeading, false);
    });

    test('should create configuration with custom state thresholds', () {
      final config = DynamicMarkerConfiguration(
        staleThresholdMs: 5000,
        offlineThresholdMs: 15000,
        expiredThresholdMs: 60000,
        stationarySpeedThreshold: 1.0,
        stationaryDurationMs: 60000,
      );

      expect(config.staleThresholdMs, 5000);
      expect(config.offlineThresholdMs, 15000);
      expect(config.expiredThresholdMs, 60000);
      expect(config.stationarySpeedThreshold, 1.0);
      expect(config.stationaryDurationMs, 60000);
    });

    test('should create configuration with custom trail settings', () {
      final config = DynamicMarkerConfiguration(
        enableTrail: true,
        maxTrailPoints: 100,
        trailColor: Colors.red,
        trailWidth: 5.0,
        trailGradient: false,
        minTrailPointDistance: 10.0,
      );

      expect(config.enableTrail, true);
      expect(config.maxTrailPoints, 100);
      expect(config.trailColor, Colors.red);
      expect(config.trailWidth, 5.0);
      expect(config.trailGradient, false);
      expect(config.minTrailPointDistance, 10.0);
    });

    test('should create configuration with custom prediction settings', () {
      final config = DynamicMarkerConfiguration(
        enablePrediction: false,
        predictionWindowMs: 5000,
      );

      expect(config.enablePrediction, false);
      expect(config.predictionWindowMs, 5000);
    });

    test('should create configuration with custom display settings', () {
      final config = DynamicMarkerConfiguration(
        zIndex: 200,
        minZoomLevel: 10.0,
        maxDistanceFromCenter: 50.0,
      );

      expect(config.zIndex, 200);
      expect(config.minZoomLevel, 10.0);
      expect(config.maxDistanceFromCenter, 50.0);
    });

    test('should create configuration with callbacks', () {
      int tapCount = 0;
      int stateChangeCount = 0;
      int expiredCount = 0;

      final config = DynamicMarkerConfiguration(
        onMarkerTap: (marker) => tapCount++,
        onMarkerStateChanged: (marker, oldState) => stateChangeCount++,
        onMarkerExpired: (marker) => expiredCount++,
      );

      expect(config.onMarkerTap, isNotNull);
      expect(config.onMarkerStateChanged, isNotNull);
      expect(config.onMarkerExpired, isNotNull);
    });

    test('should convert to and from JSON', () {
      final original = DynamicMarkerConfiguration(
        animationDurationMs: 750,
        enableAnimation: true,
        animateHeading: false,
        staleThresholdMs: 8000,
        offlineThresholdMs: 20000,
        expiredThresholdMs: 45000,
        stationarySpeedThreshold: 0.8,
        stationaryDurationMs: 45000,
        enableTrail: true,
        maxTrailPoints: 75,
        trailColor: Colors.blue,
        trailWidth: 4.0,
        trailGradient: true,
        minTrailPointDistance: 8.0,
        enablePrediction: true,
        predictionWindowMs: 3000,
        zIndex: 150,
        minZoomLevel: 8.0,
        maxDistanceFromCenter: 25.0,
      );

      final json = original.toJson();
      final restored = DynamicMarkerConfiguration.fromJson(json);

      expect(restored.animationDurationMs, original.animationDurationMs);
      expect(restored.enableAnimation, original.enableAnimation);
      expect(restored.animateHeading, original.animateHeading);
      expect(restored.staleThresholdMs, original.staleThresholdMs);
      expect(restored.offlineThresholdMs, original.offlineThresholdMs);
      expect(restored.expiredThresholdMs, original.expiredThresholdMs);
      expect(restored.stationarySpeedThreshold, original.stationarySpeedThreshold);
      expect(restored.stationaryDurationMs, original.stationaryDurationMs);
      expect(restored.enableTrail, original.enableTrail);
      expect(restored.maxTrailPoints, original.maxTrailPoints);
      expect(restored.trailColor.value, original.trailColor.value);
      expect(restored.trailWidth, original.trailWidth);
      expect(restored.trailGradient, original.trailGradient);
      expect(restored.minTrailPointDistance, original.minTrailPointDistance);
      expect(restored.enablePrediction, original.enablePrediction);
      expect(restored.predictionWindowMs, original.predictionWindowMs);
      expect(restored.zIndex, original.zIndex);
      expect(restored.minZoomLevel, original.minZoomLevel);
      expect(restored.maxDistanceFromCenter, original.maxDistanceFromCenter);
    });

    test('should handle null values in JSON deserialization', () {
      final json = <String, dynamic>{
        'animationDurationMs': 1000,
        'enableAnimation': true,
        'expiredThresholdMs': null,
        'maxDistanceFromCenter': null,
      };

      final config = DynamicMarkerConfiguration.fromJson(json);

      expect(config.expiredThresholdMs, isNull);
      expect(config.maxDistanceFromCenter, isNull);
    });

    test('should create copy with updated fields', () {
      final original = DynamicMarkerConfiguration(
        animationDurationMs: 1000,
        enableAnimation: true,
        enableTrail: false,
        zIndex: 100,
      );

      final updated = original.copyWith(
        animationDurationMs: 500,
        enableTrail: true,
      );

      expect(updated.animationDurationMs, 500);
      expect(updated.enableAnimation, original.enableAnimation);
      expect(updated.enableTrail, true);
      expect(updated.zIndex, original.zIndex);
    });

    test('should have correct string representation', () {
      final config = DynamicMarkerConfiguration(
        animationDurationMs: 1000,
        enableAnimation: true,
        enableTrail: true,
      );

      final stringRep = config.toString();
      expect(stringRep, contains('DynamicMarkerConfiguration'));
      expect(stringRep, contains('animationDurationMs: 1000'));
      expect(stringRep, contains('enableAnimation: true'));
      expect(stringRep, contains('enableTrail: true'));
    });

    test('should serialize callbacks as null in JSON', () {
      final config = DynamicMarkerConfiguration(
        onMarkerTap: (marker) {},
        onMarkerStateChanged: (marker, oldState) {},
        onMarkerExpired: (marker) {},
      );

      final json = config.toJson();

      // Callbacks should not be serialized
      expect(json.containsKey('onMarkerTap'), false);
      expect(json.containsKey('onMarkerStateChanged'), false);
      expect(json.containsKey('onMarkerExpired'), false);
    });
  });
}
