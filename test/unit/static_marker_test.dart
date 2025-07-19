import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_mapbox_navigation/src/models/static_marker.dart';
import 'package:flutter_mapbox_navigation/src/models/marker_configuration.dart';
import 'package:flutter_mapbox_navigation/src/models/marker_icons.dart';

void main() {
  group('StaticMarker Tests', () {
    test('should create StaticMarker with required fields', () {
      final marker = StaticMarker(
        id: 'test_1',
        latitude: 37.7749,
        longitude: -122.4194,
        title: 'Test Location',
        category: 'test_category',
      );

      expect(marker.id, 'test_1');
      expect(marker.latitude, 37.7749);
      expect(marker.longitude, -122.4194);
      expect(marker.title, 'Test Location');
      expect(marker.category, 'test_category');
      expect(marker.isVisible, true);
    });

    test('should create StaticMarker with all optional fields', () {
      final marker = StaticMarker(
        id: 'test_2',
        latitude: 37.7849,
        longitude: -122.4094,
        title: 'Test Location 2',
        category: 'scenic',
        description: 'A beautiful test location',
        iconId: MarkerIcons.scenic,
        customColor: Colors.red,
        priority: 5,
        isVisible: false,
        metadata: {'rating': 4.5, 'visited': true},
      );

      expect(marker.description, 'A beautiful test location');
      expect(marker.iconId, MarkerIcons.scenic);
      expect(marker.customColor, Colors.red);
      expect(marker.priority, 5);
      expect(marker.isVisible, false);
      expect(marker.metadata?['rating'], 4.5);
      expect(marker.metadata?['visited'], true);
    });

    test('should convert to and from JSON', () {
      final originalMarker = StaticMarker(
        id: 'test_3',
        latitude: 37.7949,
        longitude: -122.3994,
        title: 'Test Location 3',
        category: 'petrol_station',
        description: 'A test petrol station',
        iconId: MarkerIcons.petrolStation,
        customColor: Colors.green,
        priority: 3,
        isVisible: true,
        metadata: {'price': 1.85, 'brand': 'Shell'},
      );

      final json = originalMarker.toJson();
      final restoredMarker = StaticMarker.fromJson(json);

      expect(restoredMarker.id, originalMarker.id);
      expect(restoredMarker.latitude, originalMarker.latitude);
      expect(restoredMarker.longitude, originalMarker.longitude);
      expect(restoredMarker.title, originalMarker.title);
      expect(restoredMarker.category, originalMarker.category);
      expect(restoredMarker.description, originalMarker.description);
      expect(restoredMarker.iconId, originalMarker.iconId);
      expect(restoredMarker.customColor?.value, originalMarker.customColor?.value);
      expect(restoredMarker.priority, originalMarker.priority);
      expect(restoredMarker.isVisible, originalMarker.isVisible);
      expect(restoredMarker.metadata?['price'], originalMarker.metadata?['price']);
      expect(restoredMarker.metadata?['brand'], originalMarker.metadata?['brand']);
    });

    test('should create copy with updated fields', () {
      final originalMarker = StaticMarker(
        id: 'test_4',
        latitude: 37.8049,
        longitude: -122.3894,
        title: 'Original Title',
        category: 'restaurant',
        description: 'Original description',
        iconId: MarkerIcons.restaurant,
        customColor: Colors.blue,
        priority: 1,
        isVisible: true,
      );

      final updatedMarker = originalMarker.copyWith(
        title: 'Updated Title',
        description: 'Updated description',
        customColor: Colors.orange,
        priority: 2,
        isVisible: false,
      );

      expect(updatedMarker.id, originalMarker.id);
      expect(updatedMarker.latitude, originalMarker.latitude);
      expect(updatedMarker.longitude, originalMarker.longitude);
      expect(updatedMarker.title, 'Updated Title');
      expect(updatedMarker.category, originalMarker.category);
      expect(updatedMarker.description, 'Updated description');
      expect(updatedMarker.iconId, originalMarker.iconId);
      expect(updatedMarker.customColor, Colors.orange);
      expect(updatedMarker.priority, 2);
      expect(updatedMarker.isVisible, false);
    });

    test('should implement equality correctly', () {
      final marker1 = StaticMarker(
        id: 'same_id',
        latitude: 37.8149,
        longitude: -122.3794,
        title: 'Test Location',
        category: 'test',
      );

      final marker2 = StaticMarker(
        id: 'same_id',
        latitude: 37.8249,
        longitude: -122.3694,
        title: 'Different Title',
        category: 'different',
      );

      final marker3 = StaticMarker(
        id: 'different_id',
        latitude: 37.8149,
        longitude: -122.3794,
        title: 'Test Location',
        category: 'test',
      );

      expect(marker1, equals(marker2)); // Same ID
      expect(marker1, isNot(equals(marker3))); // Different ID
    });

    test('should have correct string representation', () {
      final marker = StaticMarker(
        id: 'test_5',
        latitude: 37.8349,
        longitude: -122.3594,
        title: 'Test Location 5',
        category: 'cafe',
      );

      final stringRep = marker.toString();
      expect(stringRep, contains('test_5'));
      expect(stringRep, contains('Test Location 5'));
      expect(stringRep, contains('cafe'));
      expect(stringRep, contains('37.8349'));
      expect(stringRep, contains('-122.3594'));
    });
  });

  group('MarkerConfiguration Tests', () {
    test('should create MarkerConfiguration with default values', () {
      final config = MarkerConfiguration();

      expect(config.showDuringNavigation, true);
      expect(config.showInFreeDrive, true);
      expect(config.showOnEmbeddedMap, true);
      expect(config.maxDistanceFromRoute, null);
      expect(config.minZoomLevel, 10.0);
      expect(config.enableClustering, true);
      expect(config.maxMarkersToShow, null);
      expect(config.onMarkerTap, null);
      expect(config.defaultIconId, null);
      expect(config.defaultColor, null);
    });

    test('should create MarkerConfiguration with custom values', () {
      final config = MarkerConfiguration(
        showDuringNavigation: false,
        showInFreeDrive: true,
        showOnEmbeddedMap: false,
        maxDistanceFromRoute: 5.0,
        minZoomLevel: 12.0,
        enableClustering: false,
        maxMarkersToShow: 100,
        defaultIconId: MarkerIcons.pin,
        defaultColor: Colors.red,
      );

      expect(config.showDuringNavigation, false);
      expect(config.showInFreeDrive, true);
      expect(config.showOnEmbeddedMap, false);
      expect(config.maxDistanceFromRoute, 5.0);
      expect(config.minZoomLevel, 12.0);
      expect(config.enableClustering, false);
      expect(config.maxMarkersToShow, 100);
      expect(config.defaultIconId, MarkerIcons.pin);
      expect(config.defaultColor, Colors.red);
    });

    test('should convert to and from JSON', () {
      final originalConfig = MarkerConfiguration(
        showDuringNavigation: true,
        showInFreeDrive: false,
        showOnEmbeddedMap: true,
        maxDistanceFromRoute: 10.0,
        minZoomLevel: 11.0,
        enableClustering: true,
        maxMarkersToShow: 50,
        defaultIconId: MarkerIcons.star,
        defaultColor: Colors.blue,
      );

      final json = originalConfig.toJson();
      final restoredConfig = MarkerConfiguration.fromJson(json);

      expect(restoredConfig.showDuringNavigation, originalConfig.showDuringNavigation);
      expect(restoredConfig.showInFreeDrive, originalConfig.showInFreeDrive);
      expect(restoredConfig.showOnEmbeddedMap, originalConfig.showOnEmbeddedMap);
      expect(restoredConfig.maxDistanceFromRoute, originalConfig.maxDistanceFromRoute);
      expect(restoredConfig.minZoomLevel, originalConfig.minZoomLevel);
      expect(restoredConfig.enableClustering, originalConfig.enableClustering);
      expect(restoredConfig.maxMarkersToShow, originalConfig.maxMarkersToShow);
      expect(restoredConfig.defaultIconId, originalConfig.defaultIconId);
      expect(restoredConfig.defaultColor?.value, originalConfig.defaultColor?.value);
    });

    test('should create copy with updated fields', () {
      final originalConfig = MarkerConfiguration(
        maxDistanceFromRoute: 5.0,
        enableClustering: true,
      );

      final updatedConfig = originalConfig.copyWith(
        maxDistanceFromRoute: 15.0,
        enableClustering: false,
        defaultIconId: MarkerIcons.heart,
      );

      expect(updatedConfig.maxDistanceFromRoute, 15.0);
      expect(updatedConfig.enableClustering, false);
      expect(updatedConfig.defaultIconId, MarkerIcons.heart);
      expect(updatedConfig.showDuringNavigation, originalConfig.showDuringNavigation);
      expect(updatedConfig.minZoomLevel, originalConfig.minZoomLevel);
    });
  });

  group('MarkerIcons Tests', () {
    test('should provide valid icon IDs', () {
      final icons = MarkerIcons.getAllIcons();
      
      expect(icons, contains(MarkerIcons.petrolStation));
      expect(icons, contains(MarkerIcons.scenic));
      expect(icons, contains(MarkerIcons.restaurant));
      expect(icons, contains(MarkerIcons.speedCamera));
      expect(icons, contains(MarkerIcons.pin));
    });

    test('should validate icon IDs correctly', () {
      expect(MarkerIcons.isValidIcon(MarkerIcons.petrolStation), true);
      expect(MarkerIcons.isValidIcon(MarkerIcons.scenic), true);
      expect(MarkerIcons.isValidIcon('invalid_icon'), false);
      expect(MarkerIcons.isValidIcon(''), false);
    });

    test('should group icons by category', () {
      final groupedIcons = MarkerIcons.getIconsByCategory();
      
      expect(groupedIcons.keys, contains('Transportation'));
      expect(groupedIcons.keys, contains('Food & Services'));
      expect(groupedIcons.keys, contains('Scenic & Recreation'));
      expect(groupedIcons.keys, contains('Safety & Traffic'));
      expect(groupedIcons.keys, contains('General'));
      
      expect(groupedIcons['Transportation'], contains(MarkerIcons.petrolStation));
      expect(groupedIcons['Food & Services'], contains(MarkerIcons.restaurant));
      expect(groupedIcons['Scenic & Recreation'], contains(MarkerIcons.scenic));
      expect(groupedIcons['Safety & Traffic'], contains(MarkerIcons.speedCamera));
      expect(groupedIcons['General'], contains(MarkerIcons.pin));
    });
  });
} 