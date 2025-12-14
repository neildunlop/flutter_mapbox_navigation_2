import 'package:flutter_mapbox_navigation/flutter_mapbox_navigation.dart';

/// Known-good test data for deterministic integration tests.
///
/// All coordinates are real locations that will produce valid routes
/// from the Mapbox API. Using consistent test data ensures tests are
/// reproducible across runs.
class TestFixtures {
  // ═══════════════════════════════════════════════════════════════════
  // WAYPOINT FIXTURES - For navigation tests
  // ═══════════════════════════════════════════════════════════════════

  /// Short route in central London (~500m).
  /// Good for quick navigation lifecycle tests.
  static List<WayPoint> get shortLondonRoute => [
    WayPoint(
      name: 'Trafalgar Square',
      latitude: 51.508039,
      longitude: -0.128069,
    ),
    WayPoint(
      name: 'Leicester Square',
      latitude: 51.511290,
      longitude: -0.128270,
    ),
  ];

  /// Medium route in London (~1.5km).
  /// Good for testing progress events.
  static List<WayPoint> get mediumLondonRoute => [
    WayPoint(
      name: 'Trafalgar Square',
      latitude: 51.508039,
      longitude: -0.128069,
    ),
    WayPoint(
      name: 'Piccadilly Circus',
      latitude: 51.509865,
      longitude: -0.134436,
    ),
  ];

  /// Multi-stop route with 5 waypoints.
  /// Good for testing waypoint arrival events.
  static List<WayPoint> get multiStopRoute => [
    WayPoint(name: 'Start', latitude: 51.508039, longitude: -0.128069),
    WayPoint(name: 'Stop 1', latitude: 51.509000, longitude: -0.129500),
    WayPoint(name: 'Stop 2', latitude: 51.510000, longitude: -0.131000),
    WayPoint(name: 'Stop 3', latitude: 51.510500, longitude: -0.132500),
    WayPoint(name: 'End', latitude: 51.511290, longitude: -0.134436),
  ];

  /// Route with a silent waypoint for route shaping.
  /// Silent waypoints should not trigger arrival announcements.
  static List<WayPoint> get routeWithSilentWaypoint => [
    WayPoint(
      name: 'Start',
      latitude: 51.508039,
      longitude: -0.128069,
    ),
    WayPoint(
      name: 'Via Point (Silent)',
      latitude: 51.509500,
      longitude: -0.130000,
      isSilent: true,
    ),
    WayPoint(
      name: 'End',
      latitude: 51.511290,
      longitude: -0.128270,
    ),
  ];

  /// Route with mix of silent and regular waypoints.
  static List<WayPoint> get mixedWaypointRoute => [
    WayPoint(name: 'Origin', latitude: 51.508039, longitude: -0.128069),
    WayPoint(
      name: 'Shape 1',
      latitude: 51.509000,
      longitude: -0.129000,
      isSilent: true,
    ),
    WayPoint(name: 'Stop A', latitude: 51.510000, longitude: -0.130500),
    WayPoint(
      name: 'Shape 2',
      latitude: 51.510500,
      longitude: -0.132000,
      isSilent: true,
    ),
    WayPoint(name: 'Destination', latitude: 51.511290, longitude: -0.134436),
  ];

  // ═══════════════════════════════════════════════════════════════════
  // MARKER FIXTURES - For static marker tests
  // ═══════════════════════════════════════════════════════════════════

  /// Basic set of test markers with different categories.
  static List<StaticMarker> get basicMarkers => [
    StaticMarker(
      id: 'marker-restaurant-1',
      latitude: 51.508500,
      longitude: -0.129000,
      title: 'Test Restaurant',
      category: 'restaurant',
      description: 'A test restaurant marker for integration testing',
      metadata: {'cuisine': 'Italian', 'rating': 4.5},
    ),
    StaticMarker(
      id: 'marker-hotel-1',
      latitude: 51.509200,
      longitude: -0.131000,
      title: 'Test Hotel',
      category: 'hotel',
      description: 'A test hotel marker',
    ),
    StaticMarker(
      id: 'marker-parking-1',
      latitude: 51.507800,
      longitude: -0.127500,
      title: 'Test Parking',
      category: 'parking',
    ),
  ];

  /// Large set of markers for clustering tests.
  static List<StaticMarker> get clusteringMarkers {
    final markers = <StaticMarker>[];
    const centerLat = 51.508039;
    const centerLng = -0.128069;

    for (var i = 0; i < 20; i++) {
      final lat = centerLat + (i * 0.0002) - 0.002;
      final lng = centerLng + ((i % 5) * 0.0003) - 0.0006;
      markers.add(
        StaticMarker(
          id: 'cluster-marker-$i',
          latitude: lat,
          longitude: lng,
          title: 'Marker $i',
          category: i % 2 == 0 ? 'poi' : 'scenic',
        ),
      );
    }
    return markers;
  }

  /// Single marker for simple tests.
  static StaticMarker get singleMarker => StaticMarker(
        id: 'single-test-marker',
        latitude: 51.508500,
        longitude: -0.128500,
        title: 'Single Test Marker',
        category: 'checkpoint',
        description: 'A single marker for basic tests',
      );

  // ═══════════════════════════════════════════════════════════════════
  // INVALID DATA FIXTURES - For error handling tests
  // ═══════════════════════════════════════════════════════════════════

  /// Single waypoint (invalid - need at least 2).
  static List<WayPoint> get singleWaypoint => [
    WayPoint(
      name: 'Lonely Point',
      latitude: 51.508039,
      longitude: -0.128069,
    ),
  ];

  /// Empty waypoint list (invalid).
  static List<WayPoint> get emptyWaypoints => [];

  /// Waypoints with same origin and destination.
  static List<WayPoint> get sameOriginDestination => [
    WayPoint(name: 'Same Place', latitude: 51.508039, longitude: -0.128069),
    WayPoint(name: 'Same Place', latitude: 51.508039, longitude: -0.128069),
  ];

  /// Waypoints in the ocean (no road route possible).
  static List<WayPoint> get oceanWaypoints => [
    WayPoint(name: 'Atlantic 1', latitude: 45.0, longitude: -30.0),
    WayPoint(name: 'Atlantic 2', latitude: 46.0, longitude: -31.0),
  ];

  /// First waypoint is silent (invalid).
  static List<WayPoint> get firstWaypointSilent => [
    WayPoint(
      name: 'Silent Start',
      latitude: 51.508039,
      longitude: -0.128069,
      isSilent: true,
    ),
    WayPoint(name: 'End', latitude: 51.511290, longitude: -0.128270),
  ];

  /// Last waypoint is silent (invalid).
  static List<WayPoint> get lastWaypointSilent => [
    WayPoint(name: 'Start', latitude: 51.508039, longitude: -0.128069),
    WayPoint(
      name: 'Silent End',
      latitude: 51.511290,
      longitude: -0.128270,
      isSilent: true,
    ),
  ];

  // ═══════════════════════════════════════════════════════════════════
  // NAVIGATION OPTIONS - For testing different configurations
  // ═══════════════════════════════════════════════════════════════════

  /// Default options for simulated navigation.
  static MapBoxOptions get simulatedNavigationOptions => MapBoxOptions(
        simulateRoute: true,
        units: VoiceUnits.metric,
        voiceInstructionsEnabled: true,
        bannerInstructionsEnabled: true,
        mode: MapBoxNavigationMode.drivingWithTraffic,
      );

  /// Options for free drive mode.
  static MapBoxOptions get freeDriveOptions => MapBoxOptions(
        units: VoiceUnits.metric,
        zoom: 16.0,
        voiceInstructionsEnabled: false,
      );

  /// Options with imperial units.
  static MapBoxOptions get imperialUnitsOptions => MapBoxOptions(
        simulateRoute: true,
        units: VoiceUnits.imperial,
        mode: MapBoxNavigationMode.driving,
      );

  /// Minimal marker configuration.
  static MarkerConfiguration get minimalMarkerConfig =>
      const MarkerConfiguration(
        showDuringNavigation: true,
        showInFreeDrive: true,
        enableClustering: false,
      );

  /// Marker configuration with clustering.
  static MarkerConfiguration get clusteringMarkerConfig =>
      const MarkerConfiguration(
        showDuringNavigation: true,
        showInFreeDrive: true,
        enableClustering: true,
        minZoomLevel: 10.0,
      );
}
