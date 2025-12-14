import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_mapbox_navigation/src/models/route_progress_event.dart';
import 'package:flutter_mapbox_navigation/src/models/route_leg.dart';

// Helper to create RouteLeg from JSON for testing
RouteLeg createRouteLeg({
  String? profileIdentifier,
  String? name,
  double? distance,
  double? expectedTravelTime,
}) {
  return RouteLeg.fromJson({
    'profileIdentifier': profileIdentifier,
    'name': name,
    'distance': distance,
    'expectedTravelTime': expectedTravelTime,
  });
}

void main() {
  group('RouteProgressEvent', () {
    group('constructor', () {
      test('creates instance with all parameters', () {
        final currentLeg = createRouteLeg(
          profileIdentifier: 'driving',
          name: 'Current Leg',
          distance: 1000.0,
          expectedTravelTime: 300.0,
        );
        final priorLeg = createRouteLeg(
          profileIdentifier: 'driving',
          name: 'Prior Leg',
          distance: 500.0,
        );
        final remainingLeg = createRouteLeg(
          profileIdentifier: 'driving',
          name: 'Remaining Leg',
          distance: 2000.0,
        );

        final event = RouteProgressEvent(
          arrived: false,
          distance: 3500.0,
          duration: 900.0,
          distanceTraveled: 1500.0,
          currentLegDistanceTraveled: 500.0,
          currentLegDistanceRemaining: 500.0,
          currentStepInstruction: 'Turn right onto Main Street',
          currentLeg: currentLeg,
          priorLeg: priorLeg,
          remainingLegs: [remainingLeg],
          legIndex: 1,
          stepIndex: 3,
          isProgressEvent: true,
        );

        expect(event.arrived, isFalse);
        expect(event.distance, equals(3500.0));
        expect(event.duration, equals(900.0));
        expect(event.distanceTraveled, equals(1500.0));
        expect(event.currentLegDistanceTraveled, equals(500.0));
        expect(event.currentLegDistanceRemaining, equals(500.0));
        expect(event.currentStepInstruction, equals('Turn right onto Main Street'));
        expect(event.currentLeg, equals(currentLeg));
        expect(event.priorLeg, equals(priorLeg));
        expect(event.remainingLegs, hasLength(1));
        expect(event.remainingLegs!.first.name, equals('Remaining Leg'));
        expect(event.legIndex, equals(1));
        expect(event.stepIndex, equals(3));
        expect(event.isProgressEvent, isTrue);
      });

      test('creates instance with null parameters', () {
        final event = RouteProgressEvent();

        expect(event.arrived, isNull);
        expect(event.distance, isNull);
        expect(event.duration, isNull);
        expect(event.distanceTraveled, isNull);
        expect(event.currentLegDistanceTraveled, isNull);
        expect(event.currentLegDistanceRemaining, isNull);
        expect(event.currentStepInstruction, isNull);
        expect(event.currentLeg, isNull);
        expect(event.priorLeg, isNull);
        expect(event.remainingLegs, isNull);
        expect(event.legIndex, isNull);
        expect(event.stepIndex, isNull);
        expect(event.isProgressEvent, isNull);
      });

      test('creates instance with only arrived set', () {
        final event = RouteProgressEvent(arrived: true);
        expect(event.arrived, isTrue);
        expect(event.isProgressEvent, isNull);
      });

      test('creates instance with empty remainingLegs', () {
        final event = RouteProgressEvent(remainingLegs: []);
        expect(event.remainingLegs, isEmpty);
      });

      test('creates instance with multiple remainingLegs', () {
        final legs = <RouteLeg>[
          createRouteLeg(profileIdentifier: 'driving', name: 'Leg 1'),
          createRouteLeg(profileIdentifier: 'driving', name: 'Leg 2'),
          createRouteLeg(profileIdentifier: 'driving', name: 'Leg 3'),
        ];

        final event = RouteProgressEvent(remainingLegs: legs);
        expect(event.remainingLegs, hasLength(3));
      });
    });

    group('fromJson', () {
      test('parses complete progress event', () {
        final json = {
          'arrived': false,
          'distance': 5000.0,
          'duration': 1200.0,
          'distanceTraveled': 2000.0,
          'currentLegDistanceTraveled': 800.0,
          'currentLegDistanceRemaining': 200.0,
          'currentStepInstruction': 'Continue straight',
          'currentLeg': {
            'profileIdentifier': 'driving',
            'name': 'Test Leg',
            'distance': 1000.0,
            'expectedTravelTime': 300.0,
          },
          'legIndex': 2,
          'stepIndex': 5,
        };

        final event = RouteProgressEvent.fromJson(json);

        expect(event.isProgressEvent, isTrue);
        expect(event.arrived, isFalse);
        expect(event.distance, equals(5000.0));
        expect(event.duration, equals(1200.0));
        expect(event.distanceTraveled, equals(2000.0));
        expect(event.currentLegDistanceTraveled, equals(800.0));
        expect(event.currentLegDistanceRemaining, equals(200.0));
        expect(event.currentStepInstruction, equals('Continue straight'));
        expect(event.currentLeg, isNotNull);
        expect(event.currentLeg!.name, equals('Test Leg'));
        expect(event.legIndex, equals(2));
        expect(event.stepIndex, equals(5));
      });

      test('parses arrival event', () {
        final json = {
          'arrived': true,
          'distance': 0.0,
          'duration': 0.0,
          'distanceTraveled': 5000.0,
        };

        final event = RouteProgressEvent.fromJson(json);

        expect(event.isProgressEvent, isTrue);
        expect(event.arrived, isTrue);
        expect(event.distance, equals(0.0));
        expect(event.distanceTraveled, equals(5000.0));
      });

      test('parses event with null arrived sets isProgressEvent to false', () {
        final json = {
          'distance': 1000.0,
          'duration': 300.0,
        };

        final event = RouteProgressEvent.fromJson(json);
        expect(event.isProgressEvent, isFalse); // arrived is null so isProgressEvent is false
        expect(event.arrived, isFalse); // arrived defaults to false when null
      });

      test('parses event with null values defaults to 0.0', () {
        final json = {
          'arrived': true,
          'distance': null,
          'duration': null,
          'distanceTraveled': null,
          'currentLegDistanceTraveled': null,
          'currentLegDistanceRemaining': null,
        };

        final event = RouteProgressEvent.fromJson(json);

        expect(event.distance, equals(0.0));
        expect(event.duration, equals(0.0));
        expect(event.distanceTraveled, equals(0.0));
        expect(event.currentLegDistanceTraveled, equals(0.0));
        expect(event.currentLegDistanceRemaining, equals(0.0));
      });

      test('parses event with zero values defaults to 0.0', () {
        final json = {
          'arrived': true,
          'distance': 0,
          'duration': 0,
          'distanceTraveled': 0,
          'currentLegDistanceTraveled': 0,
          'currentLegDistanceRemaining': 0,
        };

        final event = RouteProgressEvent.fromJson(json);

        expect(event.distance, equals(0.0));
        expect(event.duration, equals(0.0));
        expect(event.distanceTraveled, equals(0.0));
        expect(event.currentLegDistanceTraveled, equals(0.0));
        expect(event.currentLegDistanceRemaining, equals(0.0));
      });

      test('parses event with integer values converts to double', () {
        final json = {
          'arrived': false,
          'distance': 5000,
          'duration': 1200,
          'distanceTraveled': 2000,
          'currentLegDistanceTraveled': 800,
          'currentLegDistanceRemaining': 200,
        };

        final event = RouteProgressEvent.fromJson(json);

        expect(event.distance, isA<double>());
        expect(event.distance, equals(5000.0));
        expect(event.duration, equals(1200.0));
        expect(event.distanceTraveled, equals(2000.0));
        expect(event.currentLegDistanceTraveled, equals(800.0));
        expect(event.currentLegDistanceRemaining, equals(200.0));
      });

      test('parses event with currentLeg', () {
        final json = {
          'arrived': false,
          'currentLeg': {
            'profileIdentifier': 'driving',
            'name': 'Current Leg Name',
            'distance': 1500.0,
            'expectedTravelTime': 450.0,
          },
        };

        final event = RouteProgressEvent.fromJson(json);

        expect(event.currentLeg, isNotNull);
        expect(event.currentLeg!.profileIdentifier, equals('driving'));
        expect(event.currentLeg!.name, equals('Current Leg Name'));
        expect(event.currentLeg!.distance, equals(1500.0));
        expect(event.currentLeg!.expectedTravelTime, equals(450.0));
      });

      test('parses event with null currentLeg', () {
        final json = {
          'arrived': false,
          'currentLeg': null,
        };

        final event = RouteProgressEvent.fromJson(json);
        expect(event.currentLeg, isNull);
      });

      test('parses event with priorLeg', () {
        final json = {
          'arrived': false,
          'priorLeg': {
            'profileIdentifier': 'driving',
            'name': 'Prior Leg Name',
            'distance': 2000.0,
          },
        };

        final event = RouteProgressEvent.fromJson(json);

        expect(event.priorLeg, isNotNull);
        expect(event.priorLeg!.name, equals('Prior Leg Name'));
        expect(event.priorLeg!.distance, equals(2000.0));
      });

      test('parses event with null priorLeg', () {
        final json = {
          'arrived': false,
          'priorLeg': null,
        };

        final event = RouteProgressEvent.fromJson(json);
        expect(event.priorLeg, isNull);
      });

      test('parses event with remainingLegs', () {
        final json = {
          'arrived': false,
          'remainingLegs': [
            {
              'profileIdentifier': 'driving',
              'name': 'Remaining Leg 1',
              'distance': 1000.0,
            },
            {
              'profileIdentifier': 'driving',
              'name': 'Remaining Leg 2',
              'distance': 2000.0,
            },
          ],
        };

        final event = RouteProgressEvent.fromJson(json);

        expect(event.remainingLegs, isNotNull);
        expect(event.remainingLegs, hasLength(2));
        expect(event.remainingLegs![0].name, equals('Remaining Leg 1'));
        expect(event.remainingLegs![1].name, equals('Remaining Leg 2'));
      });

      test('parses event with null remainingLegs', () {
        final json = {
          'arrived': false,
          'remainingLegs': null,
        };

        final event = RouteProgressEvent.fromJson(json);
        expect(event.remainingLegs, isNull);
      });

      test('parses event with empty remainingLegs', () {
        final json = {
          'arrived': false,
          'remainingLegs': <dynamic>[],
        };

        final event = RouteProgressEvent.fromJson(json);
        expect(event.remainingLegs, isEmpty);
      });

      test('parses event with null currentStepInstruction', () {
        final json = {
          'arrived': false,
          'currentStepInstruction': null,
        };

        final event = RouteProgressEvent.fromJson(json);
        expect(event.currentStepInstruction, isNull);
      });

      test('parses event with empty currentStepInstruction', () {
        final json = {
          'arrived': false,
          'currentStepInstruction': '',
        };

        final event = RouteProgressEvent.fromJson(json);
        expect(event.currentStepInstruction, equals(''));
      });

      test('parses event with legIndex and stepIndex', () {
        final json = {
          'arrived': false,
          'legIndex': 3,
          'stepIndex': 7,
        };

        final event = RouteProgressEvent.fromJson(json);

        expect(event.legIndex, equals(3));
        expect(event.stepIndex, equals(7));
      });

      test('parses event with null legIndex and stepIndex', () {
        final json = {
          'arrived': false,
          'legIndex': null,
          'stepIndex': null,
        };

        final event = RouteProgressEvent.fromJson(json);

        expect(event.legIndex, isNull);
        expect(event.stepIndex, isNull);
      });

      test('parses event from empty json', () {
        final json = <String, dynamic>{};

        final event = RouteProgressEvent.fromJson(json);

        expect(event.isProgressEvent, isFalse);
        expect(event.arrived, isFalse); // defaults to false when null
        expect(event.distance, equals(0.0));
        expect(event.duration, equals(0.0));
        expect(event.distanceTraveled, equals(0.0));
        expect(event.currentLegDistanceTraveled, equals(0.0));
        expect(event.currentLegDistanceRemaining, equals(0.0));
        expect(event.currentStepInstruction, isNull);
        expect(event.currentLeg, isNull);
        expect(event.priorLeg, isNull);
        expect(event.remainingLegs, isNull);
        expect(event.legIndex, isNull);
        expect(event.stepIndex, isNull);
      });

      test('parses real-world navigation progress', () {
        // Simulates actual navigation progress data from Mapbox SDK
        final json = {
          'arrived': false,
          'distance': 15234.5,
          'duration': 2847.3,
          'distanceTraveled': 5678.9,
          'currentLegDistanceTraveled': 2345.6,
          'currentLegDistanceRemaining': 789.1,
          'currentStepInstruction': 'In 500 meters, turn left onto Broadway',
          'currentLeg': {
            'profileIdentifier': 'driving-traffic',
            'name': 'I-5 South',
            'distance': 3134.7,
            'expectedTravelTime': 547.0,
            'steps': [],
          },
          'priorLeg': {
            'profileIdentifier': 'driving-traffic',
            'name': 'Local Roads',
            'distance': 2544.2,
            'expectedTravelTime': 423.0,
          },
          'remainingLegs': [
            {
              'profileIdentifier': 'driving-traffic',
              'name': 'Downtown',
              'distance': 9555.6,
              'expectedTravelTime': 1877.3,
            },
          ],
          'legIndex': 1,
          'stepIndex': 4,
        };

        final event = RouteProgressEvent.fromJson(json);

        expect(event.isProgressEvent, isTrue);
        expect(event.arrived, isFalse);
        expect(event.distance, equals(15234.5));
        expect(event.duration, equals(2847.3));
        expect(event.distanceTraveled, equals(5678.9));
        expect(event.currentLegDistanceTraveled, equals(2345.6));
        expect(event.currentLegDistanceRemaining, equals(789.1));
        expect(event.currentStepInstruction, contains('Broadway'));
        expect(event.currentLeg!.name, equals('I-5 South'));
        expect(event.priorLeg!.name, equals('Local Roads'));
        expect(event.remainingLegs, hasLength(1));
        expect(event.remainingLegs![0].name, equals('Downtown'));
        expect(event.legIndex, equals(1));
        expect(event.stepIndex, equals(4));
      });
    });

    group('property mutation', () {
      test('properties can be modified after creation', () {
        final event = RouteProgressEvent();

        event.arrived = true;
        event.distance = 1000.0;
        event.duration = 300.0;
        event.distanceTraveled = 500.0;
        event.currentStepInstruction = 'Turn left';
        event.legIndex = 2;
        event.stepIndex = 5;

        expect(event.arrived, isTrue);
        expect(event.distance, equals(1000.0));
        expect(event.duration, equals(300.0));
        expect(event.distanceTraveled, equals(500.0));
        expect(event.currentStepInstruction, equals('Turn left'));
        expect(event.legIndex, equals(2));
        expect(event.stepIndex, equals(5));
      });

      test('currentLeg can be set after creation', () {
        final event = RouteProgressEvent();
        expect(event.currentLeg, isNull);

        event.currentLeg = createRouteLeg(
          profileIdentifier: 'driving',
          name: 'New Leg',
        );

        expect(event.currentLeg, isNotNull);
        expect(event.currentLeg!.name, equals('New Leg'));
      });

      test('remainingLegs can be set after creation', () {
        final event = RouteProgressEvent();
        expect(event.remainingLegs, isNull);

        event.remainingLegs = [
          createRouteLeg(profileIdentifier: 'driving', name: 'Leg 1'),
          createRouteLeg(profileIdentifier: 'driving', name: 'Leg 2'),
        ];

        expect(event.remainingLegs, hasLength(2));
      });
    });

    group('edge cases', () {
      test('handles very large distance values', () {
        final json = {
          'arrived': false,
          'distance': 999999999.99,
          'duration': 86400.0,
          'distanceTraveled': 500000000.0,
        };

        final event = RouteProgressEvent.fromJson(json);

        expect(event.distance, equals(999999999.99));
        expect(event.duration, equals(86400.0));
        expect(event.distanceTraveled, equals(500000000.0));
      });

      test('handles very small distance values', () {
        final json = {
          'arrived': false,
          'distance': 0.001,
          'duration': 0.5,
          'distanceTraveled': 0.0001,
        };

        final event = RouteProgressEvent.fromJson(json);

        expect(event.distance, equals(0.001));
        expect(event.duration, equals(0.5));
        expect(event.distanceTraveled, equals(0.0001));
      });

      test('handles negative values', () {
        // This shouldn't happen in practice but test robustness
        final json = {
          'arrived': false,
          'distance': -100.0,
          'duration': -50.0,
        };

        final event = RouteProgressEvent.fromJson(json);

        expect(event.distance, equals(-100.0));
        expect(event.duration, equals(-50.0));
      });

      test('handles unicode in currentStepInstruction', () {
        final json = {
          'arrived': false,
          'currentStepInstruction': 'Tournez à gauche sur Rue de la Paix 街道',
        };

        final event = RouteProgressEvent.fromJson(json);

        expect(event.currentStepInstruction, contains('Paix'));
        expect(event.currentStepInstruction, contains('街道'));
      });

      test('handles very long currentStepInstruction', () {
        final longInstruction = 'Turn ' * 100 + 'left on Main Street';
        final json = {
          'arrived': false,
          'currentStepInstruction': longInstruction,
        };

        final event = RouteProgressEvent.fromJson(json);
        expect(event.currentStepInstruction, equals(longInstruction));
      });

      test('handles many remaining legs', () {
        final manyLegs = List.generate(
          50,
          (i) => {
            'profileIdentifier': 'driving',
            'name': 'Leg $i',
            'distance': i * 1000.0,
          },
        );

        final json = {
          'arrived': false,
          'remainingLegs': manyLegs,
        };

        final event = RouteProgressEvent.fromJson(json);
        expect(event.remainingLegs, hasLength(50));
        expect(event.remainingLegs![49].name, equals('Leg 49'));
      });
    });
  });
}
