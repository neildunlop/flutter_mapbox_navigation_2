import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_mapbox_navigation/src/models/models.dart';

void main() {
  group('FullScreenEvent Tests', () {
    test('should parse flattened JSON correctly from Android', () {
      // This simulates the new flattened JSON structure sent from Android
      const flattenedJson = '''
      {
        "type": "marker_tap",
        "mode": "fullscreen",
        "marker_id": "test1",
        "marker_latitude": 37.7749,
        "marker_longitude": -122.4194,
        "marker_title": "Test Marker",
        "marker_category": "test",
        "marker_description": "A test marker",
        "marker_iconId": "pin",
        "marker_isVisible": true
      }''';
      
      // This should not throw an exception
      final event = FullScreenEvent.fromJson(flattenedJson);

      expect(event.type, equals('marker_tap'));
      expect(event.mode, equals('fullscreen'));
      expect(event.marker, isNotNull);
      expect(event.marker!.id, equals('test1'));
      expect(event.marker!.title, equals('Test Marker'));
      expect(event.marker!.latitude, equals(37.7749));
      expect(event.marker!.longitude, equals(-122.4194));
    });
    
    test('should parse legacy nested JSON correctly', () {
      // This tests backward compatibility with the old nested format
      const legacyJson = '''
      {
        "type": "marker_tap",
        "mode": "fullscreen",
        "marker": {
          "id": "test1",
          "latitude": 37.7749,
          "longitude": -122.4194,
          "title": "Test Marker",
          "category": "test",
          "description": "A test marker",
          "iconId": "pin",
          "customColor": null,
          "priority": null,
          "isVisible": true,
          "metadata": null
        }
      }''';
      
      final event = FullScreenEvent.fromJson(legacyJson);

      expect(event.type, equals('marker_tap'));
      expect(event.mode, equals('fullscreen'));
      expect(event.marker, isNotNull);
      expect(event.marker!.id, equals('test1'));
      expect(event.marker!.title, equals('Test Marker'));
      expect(event.marker!.latitude, equals(37.7749));
      expect(event.marker!.longitude, equals(-122.4194));
    });

    test('should handle map tap events', () {
      const mapTapJson = '''
      {
        "type": "map_tap",
        "mode": "fullscreen",
        "latitude": 37.7749,
        "longitude": -122.4194
      }''';

      final event = FullScreenEvent.fromJson(mapTapJson);

      expect(event.type, equals('map_tap'));
      expect(event.mode, equals('fullscreen'));
      expect(event.marker, isNull);
      expect(event.latitude, equals(37.7749));
      expect(event.longitude, equals(-122.4194));
    });

    test('should create event with toMap correctly', () {
      final marker = StaticMarker(
        id: 'test1',
        latitude: 37.7749,
        longitude: -122.4194,
        title: 'Test Marker',
        category: 'test',
      );

      final event = FullScreenEvent(
        type: 'marker_tap',
        mode: 'fullscreen',
        marker: marker,
      );

      final map = event.toMap();
      
      expect(map['type'], equals('marker_tap'));
      expect(map['mode'], equals('fullscreen'));
      expect(map['marker'], isNotNull);
      expect(map['marker']['id'], equals('test1'));
    });
  });
}