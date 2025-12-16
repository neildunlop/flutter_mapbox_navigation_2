import 'package:flutter/material.dart';
import 'dynamic_marker.dart';

/// Configuration for the dynamic marker system.
class DynamicMarkerConfiguration {
  // ---------------------------------------------------------------------------
  // Animation Settings
  // ---------------------------------------------------------------------------

  /// Duration of position animation in milliseconds.
  ///
  /// This should be roughly equal to or slightly longer than
  /// the expected interval between position updates to ensure
  /// smooth continuous motion.
  ///
  /// Default: 1000ms (suitable for 1Hz update rate)
  final int animationDurationMs;

  /// Enable smooth animation between positions.
  ///
  /// When false, markers jump instantly to new positions.
  /// Default: true
  final bool enableAnimation;

  /// Enable rotation animation for heading changes.
  ///
  /// When true, markers smoothly rotate to face their heading.
  /// Default: true
  final bool animateHeading;

  // ---------------------------------------------------------------------------
  // State Thresholds
  // ---------------------------------------------------------------------------

  /// Time without updates before marking as stale (milliseconds).
  ///
  /// Default: 10000ms (10 seconds)
  final int staleThresholdMs;

  /// Time without updates before marking as offline (milliseconds).
  ///
  /// Default: 30000ms (30 seconds)
  final int offlineThresholdMs;

  /// Time without updates before auto-removing marker (milliseconds).
  ///
  /// Set to null to disable auto-expiration.
  /// Default: null (no auto-expiration)
  final int? expiredThresholdMs;

  /// Speed threshold below which entity is considered stationary (m/s).
  ///
  /// Default: 0.5 m/s (~1.8 km/h)
  final double stationarySpeedThreshold;

  /// Duration at low speed before marking stationary (milliseconds).
  ///
  /// Default: 30000ms (30 seconds)
  final int stationaryDurationMs;

  // ---------------------------------------------------------------------------
  // Trail/Breadcrumb Settings
  // ---------------------------------------------------------------------------

  /// Enable trail rendering by default for new markers.
  ///
  /// Individual markers can override via [DynamicMarker.showTrail].
  /// Default: false
  final bool enableTrail;

  /// Maximum number of trail points per marker.
  ///
  /// Default: 50
  final int maxTrailPoints;

  /// Trail line color.
  ///
  /// Default: Blue with 50% opacity
  final Color trailColor;

  /// Trail line width in logical pixels.
  ///
  /// Default: 3.0
  final double trailWidth;

  /// Enable gradient fade on trail (solid at marker, transparent at end).
  ///
  /// Default: true
  final bool trailGradient;

  /// Minimum distance between trail points in meters.
  ///
  /// Prevents dense clustering when stationary.
  /// Default: 5.0
  final double minTrailPointDistance;

  // ---------------------------------------------------------------------------
  // Prediction Settings
  // ---------------------------------------------------------------------------

  /// Enable dead-reckoning prediction when updates are delayed.
  ///
  /// When enabled, the marker continues moving based on last known
  /// speed and heading until a new update arrives.
  /// Default: true
  final bool enablePrediction;

  /// Maximum prediction window in milliseconds.
  ///
  /// Prediction stops after this duration without an update.
  /// Default: 2000ms
  final int predictionWindowMs;

  // ---------------------------------------------------------------------------
  // Display Settings
  // ---------------------------------------------------------------------------

  /// Z-index for dynamic markers (relative to static markers).
  ///
  /// Higher values render above lower values.
  /// Default: 100 (above default static markers at 0)
  final int zIndex;

  /// Minimum zoom level for marker visibility.
  ///
  /// Default: 0.0 (always visible)
  final double minZoomLevel;

  /// Maximum distance from map center before hiding (kilometers).
  ///
  /// null = no limit
  /// Default: null
  final double? maxDistanceFromCenter;

  // ---------------------------------------------------------------------------
  // Callbacks
  // ---------------------------------------------------------------------------

  /// Called when a dynamic marker is tapped.
  final void Function(DynamicMarker marker)? onMarkerTap;

  /// Called when a marker's state changes.
  final void Function(DynamicMarker marker, DynamicMarkerState oldState)?
      onMarkerStateChanged;

  /// Called when a marker is auto-removed due to expiration.
  final void Function(DynamicMarker marker)? onMarkerExpired;

  /// Creates a configuration for dynamic markers.
  const DynamicMarkerConfiguration({
    this.animationDurationMs = 1000,
    this.enableAnimation = true,
    this.animateHeading = true,
    this.staleThresholdMs = 10000,
    this.offlineThresholdMs = 30000,
    this.expiredThresholdMs,
    this.stationarySpeedThreshold = 0.5,
    this.stationaryDurationMs = 30000,
    this.enableTrail = false,
    this.maxTrailPoints = 50,
    this.trailColor = const Color(0x7F2196F3),
    this.trailWidth = 3.0,
    this.trailGradient = true,
    this.minTrailPointDistance = 5.0,
    this.enablePrediction = true,
    this.predictionWindowMs = 2000,
    this.zIndex = 100,
    this.minZoomLevel = 0.0,
    this.maxDistanceFromCenter,
    this.onMarkerTap,
    this.onMarkerStateChanged,
    this.onMarkerExpired,
  });

  /// Creates a configuration from a JSON map.
  factory DynamicMarkerConfiguration.fromJson(Map<String, dynamic> json) {
    return DynamicMarkerConfiguration(
      animationDurationMs: json['animationDurationMs'] as int? ?? 1000,
      enableAnimation: json['enableAnimation'] as bool? ?? true,
      animateHeading: json['animateHeading'] as bool? ?? true,
      staleThresholdMs: json['staleThresholdMs'] as int? ?? 10000,
      offlineThresholdMs: json['offlineThresholdMs'] as int? ?? 30000,
      expiredThresholdMs: json['expiredThresholdMs'] as int?,
      stationarySpeedThreshold:
          (json['stationarySpeedThreshold'] as num?)?.toDouble() ?? 0.5,
      stationaryDurationMs: json['stationaryDurationMs'] as int? ?? 30000,
      enableTrail: json['enableTrail'] as bool? ?? false,
      maxTrailPoints: json['maxTrailPoints'] as int? ?? 50,
      trailColor: json['trailColor'] != null
          ? Color(json['trailColor'] as int)
          : const Color(0x7F2196F3),
      trailWidth: (json['trailWidth'] as num?)?.toDouble() ?? 3.0,
      trailGradient: json['trailGradient'] as bool? ?? true,
      minTrailPointDistance:
          (json['minTrailPointDistance'] as num?)?.toDouble() ?? 5.0,
      enablePrediction: json['enablePrediction'] as bool? ?? true,
      predictionWindowMs: json['predictionWindowMs'] as int? ?? 2000,
      zIndex: json['zIndex'] as int? ?? 100,
      minZoomLevel: (json['minZoomLevel'] as num?)?.toDouble() ?? 0.0,
      maxDistanceFromCenter:
          (json['maxDistanceFromCenter'] as num?)?.toDouble(),
    );
  }

  /// Converts this configuration to a JSON map.
  ///
  /// Note: Callbacks are not serialized.
  Map<String, dynamic> toJson() {
    return {
      'animationDurationMs': animationDurationMs,
      'enableAnimation': enableAnimation,
      'animateHeading': animateHeading,
      'staleThresholdMs': staleThresholdMs,
      'offlineThresholdMs': offlineThresholdMs,
      'expiredThresholdMs': expiredThresholdMs,
      'stationarySpeedThreshold': stationarySpeedThreshold,
      'stationaryDurationMs': stationaryDurationMs,
      'enableTrail': enableTrail,
      'maxTrailPoints': maxTrailPoints,
      'trailColor': trailColor.value,
      'trailWidth': trailWidth,
      'trailGradient': trailGradient,
      'minTrailPointDistance': minTrailPointDistance,
      'enablePrediction': enablePrediction,
      'predictionWindowMs': predictionWindowMs,
      'zIndex': zIndex,
      'minZoomLevel': minZoomLevel,
      'maxDistanceFromCenter': maxDistanceFromCenter,
    };
  }

  /// Creates a copy with updated fields.
  DynamicMarkerConfiguration copyWith({
    int? animationDurationMs,
    bool? enableAnimation,
    bool? animateHeading,
    int? staleThresholdMs,
    int? offlineThresholdMs,
    int? expiredThresholdMs,
    double? stationarySpeedThreshold,
    int? stationaryDurationMs,
    bool? enableTrail,
    int? maxTrailPoints,
    Color? trailColor,
    double? trailWidth,
    bool? trailGradient,
    double? minTrailPointDistance,
    bool? enablePrediction,
    int? predictionWindowMs,
    int? zIndex,
    double? minZoomLevel,
    double? maxDistanceFromCenter,
    void Function(DynamicMarker)? onMarkerTap,
    void Function(DynamicMarker, DynamicMarkerState)? onMarkerStateChanged,
    void Function(DynamicMarker)? onMarkerExpired,
  }) {
    return DynamicMarkerConfiguration(
      animationDurationMs: animationDurationMs ?? this.animationDurationMs,
      enableAnimation: enableAnimation ?? this.enableAnimation,
      animateHeading: animateHeading ?? this.animateHeading,
      staleThresholdMs: staleThresholdMs ?? this.staleThresholdMs,
      offlineThresholdMs: offlineThresholdMs ?? this.offlineThresholdMs,
      expiredThresholdMs: expiredThresholdMs ?? this.expiredThresholdMs,
      stationarySpeedThreshold:
          stationarySpeedThreshold ?? this.stationarySpeedThreshold,
      stationaryDurationMs: stationaryDurationMs ?? this.stationaryDurationMs,
      enableTrail: enableTrail ?? this.enableTrail,
      maxTrailPoints: maxTrailPoints ?? this.maxTrailPoints,
      trailColor: trailColor ?? this.trailColor,
      trailWidth: trailWidth ?? this.trailWidth,
      trailGradient: trailGradient ?? this.trailGradient,
      minTrailPointDistance:
          minTrailPointDistance ?? this.minTrailPointDistance,
      enablePrediction: enablePrediction ?? this.enablePrediction,
      predictionWindowMs: predictionWindowMs ?? this.predictionWindowMs,
      zIndex: zIndex ?? this.zIndex,
      minZoomLevel: minZoomLevel ?? this.minZoomLevel,
      maxDistanceFromCenter:
          maxDistanceFromCenter ?? this.maxDistanceFromCenter,
      onMarkerTap: onMarkerTap ?? this.onMarkerTap,
      onMarkerStateChanged: onMarkerStateChanged ?? this.onMarkerStateChanged,
      onMarkerExpired: onMarkerExpired ?? this.onMarkerExpired,
    );
  }

  @override
  String toString() {
    return 'DynamicMarkerConfiguration('
        'animationDurationMs: $animationDurationMs, '
        'enableAnimation: $enableAnimation, '
        'enableTrail: $enableTrail, '
        'staleThresholdMs: $staleThresholdMs)';
  }
}
