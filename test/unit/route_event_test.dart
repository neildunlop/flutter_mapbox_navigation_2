import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_mapbox_navigation/flutter_mapbox_navigation.dart';

void main() {
  group('RouteEvent', () {
    group('Constructor', () {
      test('should create RouteEvent with eventType and data', () {
        final event = RouteEvent(
          eventType: MapBoxEvent.progress_change,
          data: 'test data',
        );

        expect(event.eventType, MapBoxEvent.progress_change);
        expect(event.data, 'test data');
      });

      test('should create RouteEvent with null values', () {
        final event = RouteEvent();

        expect(event.eventType, isNull);
        expect(event.data, isNull);
      });

      test('should create RouteEvent with RouteProgressEvent data', () {
        final progressEvent = RouteProgressEvent(
          arrived: false,
          distance: 1000.0,
          duration: 600.0,
        );

        final event = RouteEvent(
          eventType: MapBoxEvent.progress_change,
          data: progressEvent,
        );

        expect(event.eventType, MapBoxEvent.progress_change);
        expect(event.data, isA<RouteProgressEvent>());
        expect((event.data as RouteProgressEvent).distance, 1000.0);
      });
    });

    group('fromJson', () {
      test('should parse progress_change event with RouteProgressEvent data', () {
        final json = {
          'eventType': 'progress_change',
          'data': {
            'arrived': false,
            'distance': 1500.5,
            'duration': 900.0,
            'distanceTraveled': 500.0,
            'currentLegDistanceTraveled': 500.0,
            'currentLegDistanceRemaining': 1000.5,
            'currentStepInstruction': 'Turn right',
            'legIndex': 0,
            'stepIndex': 2,
          },
        };

        final event = RouteEvent.fromJson(json);

        expect(event.eventType, MapBoxEvent.progress_change);
        expect(event.data, isA<RouteProgressEvent>());

        final progressData = event.data as RouteProgressEvent;
        expect(progressData.arrived, false);
        expect(progressData.distance, 1500.5);
        expect(progressData.duration, 900.0);
        expect(progressData.currentStepInstruction, 'Turn right');
      });

      test('should parse navigation_finished event with feedback data', () {
        final feedbackJson = jsonEncode({
          'rating': 5,
          'comment': 'Great navigation!',
        });

        final json = {
          'eventType': 'navigation_finished',
          'data': feedbackJson,
        };

        final event = RouteEvent.fromJson(json);

        expect(event.eventType, MapBoxEvent.navigation_finished);
        expect(event.data, isA<MapBoxFeedback>());

        final feedback = event.data as MapBoxFeedback;
        expect(feedback.rating, 5);
        expect(feedback.comment, 'Great navigation!');
      });

      test('should parse navigation_finished event with empty data', () {
        final json = {
          'eventType': 'navigation_finished',
          'data': '',
        };

        final event = RouteEvent.fromJson(json);

        expect(event.eventType, MapBoxEvent.navigation_finished);
        // With empty data, it should encode as json string
        expect(event.data, isA<String>());
      });

      test('should parse route_built event', () {
        final json = {
          'eventType': 'route_built',
          'data': 'route_data',
        };

        final event = RouteEvent.fromJson(json);

        expect(event.eventType, MapBoxEvent.route_built);
        expect(event.data, isA<String>());
      });

      test('should parse route_building event', () {
        final json = {
          'eventType': 'route_building',
          'data': null,
        };

        final event = RouteEvent.fromJson(json);

        expect(event.eventType, MapBoxEvent.route_building);
      });

      test('should parse route_build_failed event', () {
        final json = {
          'eventType': 'route_build_failed',
          'data': 'Error message',
        };

        final event = RouteEvent.fromJson(json);

        expect(event.eventType, MapBoxEvent.route_build_failed);
      });

      test('should parse on_arrival event', () {
        final json = {
          'eventType': 'on_arrival',
          'data': {
            'arrived': true,
            'distance': 0.0,
          },
        };

        final event = RouteEvent.fromJson(json);

        expect(event.eventType, MapBoxEvent.on_arrival);
      });

      test('should parse user_off_route event', () {
        final json = {
          'eventType': 'user_off_route',
          'data': 'off_route_data',
        };

        final event = RouteEvent.fromJson(json);

        expect(event.eventType, MapBoxEvent.user_off_route);
      });

      test('should parse milestone_event', () {
        final json = {
          'eventType': 'milestone_event',
          'data': 'milestone_reached',
        };

        final event = RouteEvent.fromJson(json);

        expect(event.eventType, MapBoxEvent.milestone_event);
      });

      test('should parse navigation_running event', () {
        final json = {
          'eventType': 'navigation_running',
          'data': null,
        };

        final event = RouteEvent.fromJson(json);

        expect(event.eventType, MapBoxEvent.navigation_running);
      });

      test('should parse navigation_cancelled event', () {
        final json = {
          'eventType': 'navigation_cancelled',
          'data': null,
        };

        final event = RouteEvent.fromJson(json);

        expect(event.eventType, MapBoxEvent.navigation_cancelled);
      });

      test('should parse faster_route_found event', () {
        final json = {
          'eventType': 'faster_route_found',
          'data': 'new_route_data',
        };

        final event = RouteEvent.fromJson(json);

        expect(event.eventType, MapBoxEvent.faster_route_found);
      });

      test('should parse speech_announcement event', () {
        final json = {
          'eventType': 'speech_announcement',
          'data': 'In 500 meters, turn right',
        };

        final event = RouteEvent.fromJson(json);

        expect(event.eventType, MapBoxEvent.speech_announcement);
      });

      test('should parse banner_instruction event', () {
        final json = {
          'eventType': 'banner_instruction',
          'data': 'instruction_data',
        };

        final event = RouteEvent.fromJson(json);

        expect(event.eventType, MapBoxEvent.banner_instruction);
      });

      test('should parse map_ready event', () {
        final json = {
          'eventType': 'map_ready',
          'data': null,
        };

        final event = RouteEvent.fromJson(json);

        expect(event.eventType, MapBoxEvent.map_ready);
      });

      test('should parse reroute_along event', () {
        final json = {
          'eventType': 'reroute_along',
          'data': 'reroute_data',
        };

        final event = RouteEvent.fromJson(json);

        expect(event.eventType, MapBoxEvent.reroute_along);
      });

      test('should parse failed_to_reroute event', () {
        final json = {
          'eventType': 'failed_to_reroute',
          'data': 'error_message',
        };

        final event = RouteEvent.fromJson(json);

        expect(event.eventType, MapBoxEvent.failed_to_reroute);
      });

      test('should handle unknown event type gracefully', () {
        final json = {
          'eventType': 'unknown_event_type',
          'data': 'some_data',
        };

        final event = RouteEvent.fromJson(json);

        // Should have null eventType since unknown type is caught
        expect(event.eventType, isNull);
      });

      test('should handle missing eventType', () {
        final json = <String, dynamic>{
          'data': 'some_data',
        };

        // This should not throw but eventType will be null
        final event = RouteEvent.fromJson(json);
        expect(event.eventType, isNull);
      });

      test('should parse marker_tap_fullscreen event', () {
        final json = {
          'eventType': 'marker_tap_fullscreen',
          'data': 'marker_data',
        };

        final event = RouteEvent.fromJson(json);

        expect(event.eventType, MapBoxEvent.marker_tap_fullscreen);
      });

      test('should parse map_tap_fullscreen event', () {
        final json = {
          'eventType': 'map_tap_fullscreen',
          'data': 'tap_data',
        };

        final event = RouteEvent.fromJson(json);

        expect(event.eventType, MapBoxEvent.map_tap_fullscreen);
      });
    });

    group('MapBoxEvent enum', () {
      test('should have all expected event types', () {
        expect(MapBoxEvent.values, contains(MapBoxEvent.map_ready));
        expect(MapBoxEvent.values, contains(MapBoxEvent.route_building));
        expect(MapBoxEvent.values, contains(MapBoxEvent.route_built));
        expect(MapBoxEvent.values, contains(MapBoxEvent.route_build_failed));
        expect(MapBoxEvent.values, contains(MapBoxEvent.route_build_cancelled));
        expect(
          MapBoxEvent.values,
          contains(MapBoxEvent.route_build_no_routes_found),
        );
        expect(MapBoxEvent.values, contains(MapBoxEvent.progress_change));
        expect(MapBoxEvent.values, contains(MapBoxEvent.user_off_route));
        expect(MapBoxEvent.values, contains(MapBoxEvent.milestone_event));
        expect(MapBoxEvent.values, contains(MapBoxEvent.navigation_running));
        expect(MapBoxEvent.values, contains(MapBoxEvent.navigation_cancelled));
        expect(MapBoxEvent.values, contains(MapBoxEvent.navigation_finished));
        expect(MapBoxEvent.values, contains(MapBoxEvent.faster_route_found));
        expect(MapBoxEvent.values, contains(MapBoxEvent.speech_announcement));
        expect(MapBoxEvent.values, contains(MapBoxEvent.banner_instruction));
        expect(MapBoxEvent.values, contains(MapBoxEvent.on_arrival));
        expect(MapBoxEvent.values, contains(MapBoxEvent.failed_to_reroute));
        expect(MapBoxEvent.values, contains(MapBoxEvent.reroute_along));
        expect(MapBoxEvent.values, contains(MapBoxEvent.on_map_tap));
        expect(MapBoxEvent.values, contains(MapBoxEvent.marker_tap_fullscreen));
        expect(MapBoxEvent.values, contains(MapBoxEvent.map_tap_fullscreen));
      });

      test('should have correct enum count', () {
        expect(MapBoxEvent.values.length, 21);
      });
    });
  });

  group('RouteProgressEvent', () {
    group('Constructor', () {
      test('should create with all parameters', () {
        final event = RouteProgressEvent(
          arrived: true,
          distance: 1000.0,
          duration: 600.0,
          distanceTraveled: 500.0,
          currentLegDistanceTraveled: 500.0,
          currentLegDistanceRemaining: 500.0,
          currentStepInstruction: 'Turn left',
          legIndex: 0,
          stepIndex: 1,
          isProgressEvent: true,
        );

        expect(event.arrived, true);
        expect(event.distance, 1000.0);
        expect(event.duration, 600.0);
        expect(event.distanceTraveled, 500.0);
        expect(event.currentStepInstruction, 'Turn left');
        expect(event.legIndex, 0);
        expect(event.stepIndex, 1);
        expect(event.isProgressEvent, true);
      });

      test('should create with null parameters', () {
        final event = RouteProgressEvent();

        expect(event.arrived, isNull);
        expect(event.distance, isNull);
        expect(event.duration, isNull);
      });
    });

    group('fromJson', () {
      test('should parse complete JSON', () {
        final json = {
          'arrived': false,
          'distance': 2500.5,
          'duration': 1800.0,
          'distanceTraveled': 1000.0,
          'currentLegDistanceTraveled': 1000.0,
          'currentLegDistanceRemaining': 1500.5,
          'currentStepInstruction': 'Continue straight',
          'legIndex': 1,
          'stepIndex': 5,
        };

        final event = RouteProgressEvent.fromJson(json);

        expect(event.isProgressEvent, true); // arrived != null
        expect(event.arrived, false);
        expect(event.distance, 2500.5);
        expect(event.duration, 1800.0);
        expect(event.distanceTraveled, 1000.0);
        expect(event.currentLegDistanceTraveled, 1000.0);
        expect(event.currentLegDistanceRemaining, 1500.5);
        expect(event.currentStepInstruction, 'Continue straight');
        expect(event.legIndex, 1);
        expect(event.stepIndex, 5);
      });

      test('should handle null distance values', () {
        final json = <String, dynamic>{
          'arrived': true,
          'distance': null,
          'duration': null,
        };

        final event = RouteProgressEvent.fromJson(json);

        expect(event.distance, 0.0);
        expect(event.duration, 0.0);
      });

      test('should handle zero distance values', () {
        final json = {
          'arrived': true,
          'distance': 0,
          'duration': 0,
        };

        final event = RouteProgressEvent.fromJson(json);

        expect(event.distance, 0.0);
        expect(event.duration, 0.0);
      });

      test('should handle integer values', () {
        final json = {
          'arrived': false,
          'distance': 1000,
          'duration': 600,
        };

        final event = RouteProgressEvent.fromJson(json);

        expect(event.distance, 1000.0);
        expect(event.duration, 600.0);
      });

      test('should set isProgressEvent based on arrived field', () {
        // With arrived field
        final jsonWithArrived = {
          'arrived': false,
          'distance': 1000,
        };
        final eventWithArrived = RouteProgressEvent.fromJson(jsonWithArrived);
        expect(eventWithArrived.isProgressEvent, true);

        // Without arrived field
        final jsonWithoutArrived = <String, dynamic>{
          'distance': 1000,
        };
        final eventWithoutArrived =
            RouteProgressEvent.fromJson(jsonWithoutArrived);
        expect(eventWithoutArrived.isProgressEvent, false);
      });

      test('should handle missing optional fields', () {
        final json = <String, dynamic>{
          'arrived': true,
        };

        final event = RouteProgressEvent.fromJson(json);

        expect(event.arrived, true);
        expect(event.currentStepInstruction, isNull);
        expect(event.currentLeg, isNull);
        expect(event.priorLeg, isNull);
        expect(event.remainingLegs, isNull);
        expect(event.legIndex, isNull);
        expect(event.stepIndex, isNull);
      });
    });
  });

  group('MapBoxFeedback', () {
    group('Constructor', () {
      test('should create with rating and comment', () {
        final feedback = MapBoxFeedback(
          rating: 5,
          comment: 'Excellent!',
        );

        expect(feedback.rating, 5);
        expect(feedback.comment, 'Excellent!');
      });

      test('should create with null values', () {
        final feedback = MapBoxFeedback();

        expect(feedback.rating, isNull);
        expect(feedback.comment, isNull);
      });
    });

    group('fromJson', () {
      test('should parse complete JSON', () {
        final json = {
          'rating': 4,
          'comment': 'Good navigation',
        };

        final feedback = MapBoxFeedback.fromJson(json);

        expect(feedback.rating, 4);
        expect(feedback.comment, 'Good navigation');
      });

      test('should handle null values in JSON', () {
        final json = <String, dynamic>{
          'rating': null,
          'comment': null,
        };

        final feedback = MapBoxFeedback.fromJson(json);

        expect(feedback.rating, isNull);
        expect(feedback.comment, isNull);
      });

      test('should handle missing fields', () {
        final json = <String, dynamic>{};

        final feedback = MapBoxFeedback.fromJson(json);

        expect(feedback.rating, isNull);
        expect(feedback.comment, isNull);
      });

      test('should handle only rating', () {
        final json = <String, dynamic>{
          'rating': 3,
        };

        final feedback = MapBoxFeedback.fromJson(json);

        expect(feedback.rating, 3);
        expect(feedback.comment, isNull);
      });

      test('should handle only comment', () {
        final json = {
          'comment': 'Needs improvement',
        };

        final feedback = MapBoxFeedback.fromJson(json);

        expect(feedback.rating, isNull);
        expect(feedback.comment, 'Needs improvement');
      });
    });
  });
}
