/// Sample Waypoints
///
/// Pre-defined waypoints for testing different navigation scenarios.
/// These can be easily copied and modified for your own use.

import 'package:flutter_mapbox_navigation/flutter_mapbox_navigation.dart';

/// Collection of sample waypoints organized by region and use case
class SampleWaypoints {
  SampleWaypoints._();

  // ===========================================================================
  // SAN FRANCISCO BAY AREA
  // ===========================================================================

  /// Golden Gate Park - good starting point
  static WayPoint get sfGoldenGatePark => WayPoint(
        name: 'Golden Gate Park',
        latitude: 37.7694,
        longitude: -122.4862,
      );

  /// Fisherman's Wharf - popular tourist destination
  static WayPoint get sfFishermansWharf => WayPoint(
        name: "Fisherman's Wharf",
        latitude: 37.8080,
        longitude: -122.4177,
      );

  /// Union Square - downtown SF
  static WayPoint get sfUnionSquare => WayPoint(
        name: 'Union Square',
        latitude: 37.7879,
        longitude: -122.4074,
      );

  /// Ferry Building
  static WayPoint get sfFerryBuilding => WayPoint(
        name: 'Ferry Building',
        latitude: 37.7955,
        longitude: -122.3937,
      );

  /// Pier 39
  static WayPoint get sfPier39 => WayPoint(
        name: 'Pier 39',
        latitude: 37.8087,
        longitude: -122.4098,
      );

  // ===========================================================================
  // MOUNTAIN VIEW / SILICON VALLEY
  // ===========================================================================

  /// Google Headquarters
  static WayPoint get mvGoogleHQ => WayPoint(
        name: 'Google HQ',
        latitude: 37.4220,
        longitude: -122.0841,
      );

  /// Computer History Museum
  static WayPoint get mvComputerHistoryMuseum => WayPoint(
        name: 'Computer History Museum',
        latitude: 37.4143,
        longitude: -122.0777,
      );

  /// Shoreline Amphitheatre
  static WayPoint get mvShorelineAmphitheatre => WayPoint(
        name: 'Shoreline Amphitheatre',
        latitude: 37.4267,
        longitude: -122.0806,
      );

  // ===========================================================================
  // WASHINGTON DC
  // ===========================================================================

  /// The White House
  static WayPoint get dcWhiteHouse => WayPoint(
        name: 'The White House',
        latitude: 38.8977,
        longitude: -77.0365,
      );

  /// Lincoln Memorial
  static WayPoint get dcLincolnMemorial => WayPoint(
        name: 'Lincoln Memorial',
        latitude: 38.8893,
        longitude: -77.0502,
      );

  /// US Capitol
  static WayPoint get dcCapitol => WayPoint(
        name: 'US Capitol',
        latitude: 38.8899,
        longitude: -77.0091,
      );

  /// Washington Monument
  static WayPoint get dcWashingtonMonument => WayPoint(
        name: 'Washington Monument',
        latitude: 38.8895,
        longitude: -77.0353,
      );

  /// National Mall
  static WayPoint get dcNationalMall => WayPoint(
        name: 'National Mall',
        latitude: 38.8895,
        longitude: -77.0230,
      );

  // ===========================================================================
  // SILENT WAYPOINTS (for route shaping)
  // ===========================================================================

  /// Silent waypoint - route shaping point (no announcement)
  static WayPoint get dcSilentWaypoint1 => WayPoint(
        name: 'Route Shape Point 1',
        latitude: 38.8920,
        longitude: -77.0420,
        isSilent: true,
      );

  /// Silent waypoint - another shaping point
  static WayPoint get dcSilentWaypoint2 => WayPoint(
        name: 'Route Shape Point 2',
        latitude: 38.8910,
        longitude: -77.0280,
        isSilent: true,
      );

  // ===========================================================================
  // PRE-BUILT ROUTES
  // ===========================================================================

  /// Simple 2-point route for basic navigation testing
  /// San Francisco: Golden Gate Park to Fisherman's Wharf
  static List<WayPoint> get basicRoute => [
        sfGoldenGatePark,
        sfFishermansWharf,
      ];

  /// 3-point route (safe for iOS drivingWithTraffic mode)
  /// San Francisco tourist route
  static List<WayPoint> get shortTouristRoute => [
        sfGoldenGatePark,
        sfUnionSquare,
        sfFishermansWharf,
      ];

  /// Multi-stop route with 5 waypoints
  /// Washington DC monuments tour
  static List<WayPoint> get dcMonumentsTour => [
        dcWhiteHouse,
        dcWashingtonMonument,
        dcLincolnMemorial,
        dcNationalMall,
        dcCapitol,
      ];

  /// Route with silent waypoints for route shaping
  /// Demonstrates silent waypoint feature
  static List<WayPoint> get routeWithSilentWaypoints => [
        dcWhiteHouse,
        dcSilentWaypoint1, // No announcement at this point
        dcLincolnMemorial,
        dcSilentWaypoint2, // No announcement at this point
        dcCapitol,
      ];

  /// Silicon Valley tech tour
  static List<WayPoint> get siliconValleyTour => [
        mvGoogleHQ,
        mvComputerHistoryMuseum,
        mvShorelineAmphitheatre,
      ];

  /// Long route for stress testing (uses SF area)
  static List<WayPoint> get longRoute => [
        sfGoldenGatePark,
        sfUnionSquare,
        sfFerryBuilding,
        sfPier39,
        sfFishermansWharf,
        mvGoogleHQ,
        mvComputerHistoryMuseum,
      ];

  /// Get all available route presets as a map
  static Map<String, List<WayPoint>> get allRoutes => {
        'Basic (2 stops)': basicRoute,
        'Short Tourist (3 stops)': shortTouristRoute,
        'DC Monuments (5 stops)': dcMonumentsTour,
        'With Silent Waypoints': routeWithSilentWaypoints,
        'Silicon Valley': siliconValleyTour,
        'Long Route (7 stops)': longRoute,
      };
}
