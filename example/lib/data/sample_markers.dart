/// Sample Markers
///
/// Pre-defined static markers organized by category for testing
/// marker display, clustering, and popup features.

import 'package:flutter/material.dart';
import 'package:flutter_mapbox_navigation/flutter_mapbox_navigation.dart';

/// Collection of sample markers organized by category
class SampleMarkers {
  SampleMarkers._();

  // ===========================================================================
  // RESTAURANTS
  // ===========================================================================

  static List<StaticMarker> get restaurants => [
        StaticMarker(
          id: 'restaurant_1',
          latitude: 37.7749,
          longitude: -122.4194,
          title: 'The Italian Place',
          category: 'restaurant',
          description: 'Authentic Italian cuisine with homemade pasta',
          iconId: MarkerIcons.restaurant,
          customColor: Colors.red,
          priority: 1,
          metadata: {
            'rating': 4.5,
            'priceRange': '\$\$',
            'cuisine': 'Italian',
            'phone': '(415) 555-0101',
            'hours': '11:00 AM - 10:00 PM',
          },
        ),
        StaticMarker(
          id: 'restaurant_2',
          latitude: 37.7850,
          longitude: -122.4080,
          title: 'Sushi Express',
          category: 'restaurant',
          description: 'Fresh sushi and Japanese specialties',
          iconId: MarkerIcons.restaurant,
          customColor: Colors.red,
          priority: 2,
          metadata: {
            'rating': 4.2,
            'priceRange': '\$\$\$',
            'cuisine': 'Japanese',
            'phone': '(415) 555-0102',
            'hours': '12:00 PM - 9:00 PM',
          },
        ),
        StaticMarker(
          id: 'restaurant_3',
          latitude: 37.7920,
          longitude: -122.4050,
          title: 'Taco Town',
          category: 'restaurant',
          description: 'Best tacos in the city',
          iconId: MarkerIcons.restaurant,
          customColor: Colors.red,
          priority: 3,
          metadata: {
            'rating': 4.8,
            'priceRange': '\$',
            'cuisine': 'Mexican',
            'phone': '(415) 555-0103',
            'hours': '10:00 AM - 11:00 PM',
          },
        ),
      ];

  // ===========================================================================
  // GAS STATIONS
  // ===========================================================================

  static List<StaticMarker> get gasStations => [
        StaticMarker(
          id: 'gas_1',
          latitude: 37.7700,
          longitude: -122.4300,
          title: 'QuickFuel Station',
          category: 'gas_station',
          description: 'Open 24/7 with convenience store',
          iconId: MarkerIcons.petrolStation,
          customColor: Colors.blue,
          priority: 1,
          metadata: {
            'regularPrice': '\$4.59',
            'premiumPrice': '\$5.19',
            'dieselPrice': '\$5.29',
            'amenities': ['Restroom', 'ATM', 'Car Wash'],
            'open24Hours': true,
          },
        ),
        StaticMarker(
          id: 'gas_2',
          latitude: 37.7950,
          longitude: -122.4100,
          title: 'GreenGo Gas',
          category: 'gas_station',
          description: 'Eco-friendly fuel options available',
          iconId: MarkerIcons.petrolStation,
          customColor: Colors.blue,
          priority: 2,
          metadata: {
            'regularPrice': '\$4.49',
            'premiumPrice': '\$5.09',
            'hasEV': true,
            'amenities': ['Restroom', 'Coffee Shop'],
            'open24Hours': false,
          },
        ),
      ];

  // ===========================================================================
  // EV CHARGING
  // ===========================================================================

  static List<StaticMarker> get evCharging => [
        StaticMarker(
          id: 'ev_1',
          latitude: 37.7800,
          longitude: -122.4000,
          title: 'SuperCharger Station',
          category: 'ev_charging',
          description: '8 Tesla Superchargers available',
          iconId: MarkerIcons.chargingStation,
          customColor: Colors.green,
          priority: 1,
          metadata: {
            'chargerType': 'Tesla Supercharger',
            'ports': 8,
            'maxPower': '250 kW',
            'pricing': '\$0.28/kWh',
            'available': 5,
          },
        ),
        StaticMarker(
          id: 'ev_2',
          latitude: 37.7880,
          longitude: -122.3950,
          title: 'ChargePoint Hub',
          category: 'ev_charging',
          description: 'Universal EV charging',
          iconId: MarkerIcons.chargingStation,
          customColor: Colors.green,
          priority: 2,
          metadata: {
            'chargerType': 'CCS/CHAdeMO',
            'ports': 4,
            'maxPower': '150 kW',
            'pricing': '\$0.35/kWh',
            'available': 2,
          },
        ),
      ];

  // ===========================================================================
  // SCENIC VIEWPOINTS
  // ===========================================================================

  static List<StaticMarker> get scenicViewpoints => [
        StaticMarker(
          id: 'scenic_1',
          latitude: 37.8199,
          longitude: -122.4783,
          title: 'Golden Gate Vista',
          category: 'scenic',
          description: 'Stunning views of the Golden Gate Bridge',
          iconId: MarkerIcons.scenic,
          customColor: Colors.teal,
          priority: 1,
          metadata: {
            'bestTime': 'Sunset',
            'parking': 'Street parking available',
            'accessibility': 'Wheelchair accessible',
            'photoSpot': true,
          },
        ),
        StaticMarker(
          id: 'scenic_2',
          latitude: 37.8024,
          longitude: -122.4058,
          title: 'Bay View Point',
          category: 'scenic',
          description: 'Panoramic views of San Francisco Bay',
          iconId: MarkerIcons.viewpoint,
          customColor: Colors.teal,
          priority: 2,
          metadata: {
            'bestTime': 'Morning',
            'parking': 'Paid lot nearby',
            'accessibility': 'Steps required',
            'photoSpot': true,
          },
        ),
      ];

  // ===========================================================================
  // HOTELS
  // ===========================================================================

  static List<StaticMarker> get hotels => [
        StaticMarker(
          id: 'hotel_1',
          latitude: 37.7879,
          longitude: -122.4074,
          title: 'Grand Plaza Hotel',
          category: 'hotel',
          description: 'Luxury accommodation in Union Square',
          iconId: MarkerIcons.hotel,
          customColor: Colors.purple,
          priority: 1,
          metadata: {
            'rating': 4.7,
            'stars': 5,
            'priceRange': '\$\$\$\$',
            'amenities': ['Pool', 'Spa', 'Restaurant', 'Gym'],
            'phone': '(415) 555-0201',
          },
        ),
        StaticMarker(
          id: 'hotel_2',
          latitude: 37.7955,
          longitude: -122.3937,
          title: 'Waterfront Inn',
          category: 'hotel',
          description: 'Beautiful bay views',
          iconId: MarkerIcons.hotel,
          customColor: Colors.purple,
          priority: 2,
          metadata: {
            'rating': 4.3,
            'stars': 4,
            'priceRange': '\$\$\$',
            'amenities': ['Restaurant', 'Gym', 'Business Center'],
            'phone': '(415) 555-0202',
          },
        ),
      ];

  // ===========================================================================
  // EMERGENCY SERVICES
  // ===========================================================================

  static List<StaticMarker> get emergencyServices => [
        StaticMarker(
          id: 'hospital_1',
          latitude: 37.7630,
          longitude: -122.4580,
          title: 'SF General Hospital',
          category: 'hospital',
          description: 'Level 1 Trauma Center',
          iconId: MarkerIcons.hospital,
          customColor: Colors.red.shade700,
          priority: 1,
          metadata: {
            'emergency': true,
            'phone': '(415) 555-0911',
            'open24Hours': true,
          },
        ),
        StaticMarker(
          id: 'police_1',
          latitude: 37.7750,
          longitude: -122.4180,
          title: 'Central Police Station',
          category: 'police',
          description: 'SFPD Central Station',
          iconId: MarkerIcons.police,
          customColor: Colors.blue.shade800,
          priority: 1,
          metadata: {
            'emergency': true,
            'phone': '(415) 555-0100',
            'open24Hours': true,
          },
        ),
      ];

  // ===========================================================================
  // PARKING
  // ===========================================================================

  static List<StaticMarker> get parking => [
        StaticMarker(
          id: 'parking_1',
          latitude: 37.7870,
          longitude: -122.4060,
          title: 'Downtown Garage',
          category: 'parking',
          description: 'Covered parking with 500 spaces',
          iconId: MarkerIcons.parking,
          customColor: Colors.blueGrey,
          priority: 2,
          metadata: {
            'type': 'Garage',
            'spaces': 500,
            'hourlyRate': '\$5',
            'dailyMax': '\$35',
            'ev Charging': true,
          },
        ),
        StaticMarker(
          id: 'parking_2',
          latitude: 37.8050,
          longitude: -122.4150,
          title: 'Wharf Parking Lot',
          category: 'parking',
          description: 'Open lot near Fishermans Wharf',
          iconId: MarkerIcons.parking,
          customColor: Colors.blueGrey,
          priority: 3,
          metadata: {
            'type': 'Surface Lot',
            'spaces': 200,
            'hourlyRate': '\$8',
            'dailyMax': '\$50',
            'evCharging': false,
          },
        ),
      ];

  // ===========================================================================
  // COMBINED COLLECTIONS
  // ===========================================================================

  /// All markers combined
  static List<StaticMarker> get all => [
        ...restaurants,
        ...gasStations,
        ...evCharging,
        ...scenicViewpoints,
        ...hotels,
        ...emergencyServices,
        ...parking,
      ];

  /// Markers useful during navigation (gas, food, rest stops)
  static List<StaticMarker> get navigationPOIs => [
        ...restaurants,
        ...gasStations,
        ...evCharging,
      ];

  /// Tourist-oriented markers
  static List<StaticMarker> get touristPOIs => [
        ...scenicViewpoints,
        ...hotels,
        ...restaurants,
      ];

  /// Get markers by category
  static Map<String, List<StaticMarker>> get byCategory => {
        'Restaurants': restaurants,
        'Gas Stations': gasStations,
        'EV Charging': evCharging,
        'Scenic': scenicViewpoints,
        'Hotels': hotels,
        'Emergency': emergencyServices,
        'Parking': parking,
      };
}
