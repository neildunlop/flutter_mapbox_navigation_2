import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_mapbox_navigation/src/models/event_data.dart';
import 'package:flutter_mapbox_navigation/src/models/route_leg.dart';
import 'package:flutter_mapbox_navigation/src/models/route_step.dart';

void main() {
  group('MapBoxEventData', () {
    group('Constructor', () {
      test('should create with data parameter', () {
        final eventData = MapBoxEventData(data: 'test data');

        expect(eventData.data, 'test data');
      });

      test('should create with null data', () {
        final eventData = MapBoxEventData();

        expect(eventData.data, isNull);
      });
    });

    group('fromJson', () {
      test('should parse data from JSON', () {
        final json = {'data': 'event data string'};

        final eventData = MapBoxEventData.fromJson(json);

        expect(eventData.data, 'event data string');
      });

      test('should handle empty string data', () {
        final json = {'data': ''};

        final eventData = MapBoxEventData.fromJson(json);

        expect(eventData.data, '');
      });
    });

    group('toJson', () {
      test('should convert to JSON correctly', () {
        final eventData = MapBoxEventData(data: 'test data');

        final json = eventData.toJson();

        expect(json['data'], 'test data');
      });

      test('should include null data in JSON', () {
        final eventData = MapBoxEventData();

        final json = eventData.toJson();

        expect(json.containsKey('data'), isTrue);
        expect(json['data'], isNull);
      });
    });
  });

  group('RouteStep', () {
    group('Constructor', () {
      test('should create with all parameters', () {
        final step = RouteStep(
          'Main Street',
          'Turn right onto Main Street',
          500.0,
          120.0,
        );

        expect(step.name, 'Main Street');
        expect(step.instructions, 'Turn right onto Main Street');
        expect(step.distance, 500.0);
        expect(step.expectedTravelTime, 120.0);
      });

      test('should create with null parameters', () {
        final step = RouteStep(null, null, null, null);

        expect(step.name, isNull);
        expect(step.instructions, isNull);
        expect(step.distance, isNull);
        expect(step.expectedTravelTime, isNull);
      });
    });

    group('fromJson', () {
      test('should parse complete JSON', () {
        final json = {
          'name': 'Highway 101',
          'instructions': 'Continue on Highway 101',
          'distance': 2500.5,
          'expectedTravelTime': 180.0,
        };

        final step = RouteStep.fromJson(json);

        expect(step.name, 'Highway 101');
        expect(step.instructions, 'Continue on Highway 101');
        expect(step.distance, 2500.5);
        expect(step.expectedTravelTime, 180.0);
      });

      test('should handle null distance values', () {
        final json = <String, dynamic>{
          'name': 'Test Street',
          'distance': null,
          'expectedTravelTime': null,
        };

        final step = RouteStep.fromJson(json);

        expect(step.distance, 0.0);
        expect(step.expectedTravelTime, 0.0);
      });

      test('should handle zero distance values', () {
        final json = {
          'name': 'Arrival',
          'distance': 0,
          'expectedTravelTime': 0,
        };

        final step = RouteStep.fromJson(json);

        expect(step.distance, 0.0);
        expect(step.expectedTravelTime, 0.0);
      });

      test('should handle integer values', () {
        final json = {
          'name': 'Test',
          'distance': 1000,
          'expectedTravelTime': 60,
        };

        final step = RouteStep.fromJson(json);

        expect(step.distance, 1000.0);
        expect(step.expectedTravelTime, 60.0);
      });

      test('should handle missing optional fields', () {
        final json = <String, dynamic>{};

        final step = RouteStep.fromJson(json);

        expect(step.name, isNull);
        expect(step.instructions, isNull);
        expect(step.distance, 0.0);
        expect(step.expectedTravelTime, 0.0);
      });
    });
  });

  group('RouteLeg', () {
    group('Constructor', () {
      test('should create with all parameters', () {
        final leg = RouteLeg(
          'driving',
          'Route to destination',
          10000.0,
          600.0,
          null,
          null,
          null,
        );

        expect(leg.profileIdentifier, 'driving');
        expect(leg.name, 'Route to destination');
        expect(leg.distance, 10000.0);
        expect(leg.expectedTravelTime, 600.0);
      });

      test('should create with null parameters', () {
        final leg = RouteLeg(null, null, null, null, null, null, null);

        expect(leg.profileIdentifier, isNull);
        expect(leg.name, isNull);
        expect(leg.distance, isNull);
        expect(leg.expectedTravelTime, isNull);
        expect(leg.source, isNull);
        expect(leg.destination, isNull);
        expect(leg.steps, isNull);
      });
    });

    group('fromJson', () {
      test('should parse complete JSON', () {
        final json = {
          'profileIdentifier': 'driving-traffic',
          'name': 'Main Route',
          'distance': 5000.5,
          'expectedTravelTime': 300.0,
        };

        final leg = RouteLeg.fromJson(json);

        expect(leg.profileIdentifier, 'driving-traffic');
        expect(leg.name, 'Main Route');
        expect(leg.distance, 5000.5);
        expect(leg.expectedTravelTime, 300.0);
      });

      test('should handle null distance values', () {
        final json = <String, dynamic>{
          'profileIdentifier': 'walking',
          'distance': null,
          'expectedTravelTime': null,
        };

        final leg = RouteLeg.fromJson(json);

        expect(leg.distance, 0.0);
        expect(leg.expectedTravelTime, 0.0);
      });

      test('should handle zero distance values', () {
        final json = {
          'profileIdentifier': 'cycling',
          'distance': 0,
          'expectedTravelTime': 0,
        };

        final leg = RouteLeg.fromJson(json);

        expect(leg.distance, 0.0);
        expect(leg.expectedTravelTime, 0.0);
      });

      test('should parse source waypoint', () {
        final json = {
          'profileIdentifier': 'driving',
          'distance': 1000.0,
          'source': {
            'name': 'Origin',
            'latitude': 51.5074,
            'longitude': -0.1278,
          },
        };

        final leg = RouteLeg.fromJson(json);

        expect(leg.source, isNotNull);
        expect(leg.source!.name, 'Origin');
        expect(leg.source!.latitude, 51.5074);
        expect(leg.source!.longitude, -0.1278);
      });

      test('should parse destination waypoint', () {
        final json = {
          'profileIdentifier': 'driving',
          'distance': 1000.0,
          'destination': {
            'name': 'Destination',
            'latitude': 48.8566,
            'longitude': 2.3522,
          },
        };

        final leg = RouteLeg.fromJson(json);

        expect(leg.destination, isNotNull);
        expect(leg.destination!.name, 'Destination');
        expect(leg.destination!.latitude, 48.8566);
        expect(leg.destination!.longitude, 2.3522);
      });

      test('should parse steps list', () {
        final json = {
          'profileIdentifier': 'driving',
          'distance': 1000.0,
          'steps': [
            {
              'name': 'Step 1',
              'instructions': 'Turn left',
              'distance': 500.0,
              'expectedTravelTime': 60.0,
            },
            {
              'name': 'Step 2',
              'instructions': 'Turn right',
              'distance': 500.0,
              'expectedTravelTime': 60.0,
            },
          ],
        };

        final leg = RouteLeg.fromJson(json);

        expect(leg.steps, isNotNull);
        expect(leg.steps!.length, 2);
        expect(leg.steps![0].name, 'Step 1');
        expect(leg.steps![0].instructions, 'Turn left');
        expect(leg.steps![1].name, 'Step 2');
        expect(leg.steps![1].instructions, 'Turn right');
      });

      test('should handle null source and destination', () {
        final json = <String, dynamic>{
          'profileIdentifier': 'driving',
          'distance': 1000.0,
          'source': null,
          'destination': null,
        };

        final leg = RouteLeg.fromJson(json);

        expect(leg.source, isNull);
        expect(leg.destination, isNull);
      });

      test('should handle null steps', () {
        final json = <String, dynamic>{
          'profileIdentifier': 'driving',
          'distance': 1000.0,
          'steps': null,
        };

        final leg = RouteLeg.fromJson(json);

        expect(leg.steps, isNull);
      });

      test('should handle empty steps list', () {
        final json = {
          'profileIdentifier': 'driving',
          'distance': 1000.0,
          'steps': <Map<String, dynamic>>[],
        };

        final leg = RouteLeg.fromJson(json);

        expect(leg.steps, isNotNull);
        expect(leg.steps!.isEmpty, isTrue);
      });

      test('should handle missing optional fields', () {
        final json = <String, dynamic>{};

        final leg = RouteLeg.fromJson(json);

        expect(leg.profileIdentifier, isNull);
        expect(leg.name, isNull);
        expect(leg.distance, 0.0);
        expect(leg.expectedTravelTime, 0.0);
        expect(leg.source, isNull);
        expect(leg.destination, isNull);
        expect(leg.steps, isNull);
      });

      test('should handle integer distance values', () {
        final json = {
          'profileIdentifier': 'driving',
          'distance': 5000,
          'expectedTravelTime': 300,
        };

        final leg = RouteLeg.fromJson(json);

        expect(leg.distance, 5000.0);
        expect(leg.expectedTravelTime, 300.0);
      });
    });
  });
}
