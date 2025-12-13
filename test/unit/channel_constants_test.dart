import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_mapbox_navigation/src/platform/channel_constants.dart';

void main() {
  group('Channel Names', () {
    test('kMethodChannelName should have correct value', () {
      expect(kMethodChannelName, equals('flutter_mapbox_navigation'));
    });

    test('kEventChannelName should have correct value', () {
      expect(kEventChannelName, equals('flutter_mapbox_navigation/events'));
    });

    test('kMarkerEventChannelName should have correct value', () {
      expect(kMarkerEventChannelName, equals('flutter_mapbox_navigation/marker_events'));
    });

    test('kOfflineProgressChannelName should have correct value', () {
      expect(kOfflineProgressChannelName, equals('flutter_mapbox_navigation/offline_progress'));
    });

    test('channel names should be unique', () {
      final channelNames = {
        kMethodChannelName,
        kEventChannelName,
        kMarkerEventChannelName,
        kOfflineProgressChannelName,
      };
      expect(channelNames.length, equals(4));
    });
  });

  group('Methods', () {
    group('Core Navigation Methods', () {
      test('getPlatformVersion should be defined', () {
        expect(Methods.getPlatformVersion, equals('getPlatformVersion'));
      });

      test('startNavigation should be defined', () {
        expect(Methods.startNavigation, equals('startNavigation'));
      });

      test('startFreeDrive should be defined', () {
        expect(Methods.startFreeDrive, equals('startFreeDrive'));
      });

      test('finishNavigation should be defined', () {
        expect(Methods.finishNavigation, equals('finishNavigation'));
      });

      test('getDistanceRemaining should be defined', () {
        expect(Methods.getDistanceRemaining, equals('getDistanceRemaining'));
      });

      test('getDurationRemaining should be defined', () {
        expect(Methods.getDurationRemaining, equals('getDurationRemaining'));
      });

      test('addWayPoints should be defined', () {
        expect(Methods.addWayPoints, equals('addWayPoints'));
      });
    });

    group('Offline Navigation Methods', () {
      test('enableOfflineRouting should be defined', () {
        expect(Methods.enableOfflineRouting, equals('enableOfflineRouting'));
      });

      test('downloadOfflineRegion should be defined', () {
        expect(Methods.downloadOfflineRegion, equals('downloadOfflineRegion'));
      });

      test('isOfflineRoutingAvailable should be defined', () {
        expect(Methods.isOfflineRoutingAvailable, equals('isOfflineRoutingAvailable'));
      });

      test('deleteOfflineRegion should be defined', () {
        expect(Methods.deleteOfflineRegion, equals('deleteOfflineRegion'));
      });

      test('getOfflineCacheSize should be defined', () {
        expect(Methods.getOfflineCacheSize, equals('getOfflineCacheSize'));
      });

      test('clearOfflineCache should be defined', () {
        expect(Methods.clearOfflineCache, equals('clearOfflineCache'));
      });

      test('getOfflineRegionStatus should be defined', () {
        expect(Methods.getOfflineRegionStatus, equals('getOfflineRegionStatus'));
      });

      test('listOfflineRegions should be defined', () {
        expect(Methods.listOfflineRegions, equals('listOfflineRegions'));
      });
    });

    group('Static Marker Methods', () {
      test('addStaticMarkers should be defined', () {
        expect(Methods.addStaticMarkers, equals('addStaticMarkers'));
      });

      test('removeStaticMarkers should be defined', () {
        expect(Methods.removeStaticMarkers, equals('removeStaticMarkers'));
      });

      test('clearAllStaticMarkers should be defined', () {
        expect(Methods.clearAllStaticMarkers, equals('clearAllStaticMarkers'));
      });

      test('updateMarkerConfiguration should be defined', () {
        expect(Methods.updateMarkerConfiguration, equals('updateMarkerConfiguration'));
      });

      test('getStaticMarkers should be defined', () {
        expect(Methods.getStaticMarkers, equals('getStaticMarkers'));
      });

      test('getMarkerScreenPosition should be defined', () {
        expect(Methods.getMarkerScreenPosition, equals('getMarkerScreenPosition'));
      });
    });

    group('Map Viewport Methods', () {
      test('getMapViewport should be defined', () {
        expect(Methods.getMapViewport, equals('getMapViewport'));
      });
    });
  });

  group('EventTypes', () {
    group('Route Events', () {
      test('navigationStarted should be defined', () {
        expect(EventTypes.navigationStarted, equals('navigation_started'));
      });

      test('routeBuilding should be defined', () {
        expect(EventTypes.routeBuilding, equals('route_building'));
      });

      test('routeBuilt should be defined', () {
        expect(EventTypes.routeBuilt, equals('route_built'));
      });

      test('routeBuildFailed should be defined', () {
        expect(EventTypes.routeBuildFailed, equals('route_build_failed'));
      });

      test('progressChange should be defined', () {
        expect(EventTypes.progressChange, equals('progress_change'));
      });

      test('userOffRoute should be defined', () {
        expect(EventTypes.userOffRoute, equals('user_off_route'));
      });

      test('milestoneEvent should be defined', () {
        expect(EventTypes.milestoneEvent, equals('milestone_event'));
      });

      test('routeRerouted should be defined', () {
        expect(EventTypes.routeRerouted, equals('route_rerouted'));
      });

      test('onArrival should be defined', () {
        expect(EventTypes.onArrival, equals('on_arrival'));
      });

      test('navigationCancelled should be defined', () {
        expect(EventTypes.navigationCancelled, equals('navigation_cancelled'));
      });

      test('navigationFinished should be defined', () {
        expect(EventTypes.navigationFinished, equals('navigation_finished'));
      });
    });

    group('Marker Events', () {
      test('markerTapped should be defined', () {
        expect(EventTypes.markerTapped, equals('marker_tapped'));
      });

      test('markerCalloutTapped should be defined', () {
        expect(EventTypes.markerCalloutTapped, equals('marker_callout_tapped'));
      });
    });

    group('Offline Events', () {
      test('downloadProgress should be defined', () {
        expect(EventTypes.downloadProgress, equals('download_progress'));
      });

      test('downloadComplete should be defined', () {
        expect(EventTypes.downloadComplete, equals('download_complete'));
      });

      test('downloadFailed should be defined', () {
        expect(EventTypes.downloadFailed, equals('download_failed'));
      });
    });

    test('all event types should be unique', () {
      final eventTypes = {
        EventTypes.navigationStarted,
        EventTypes.routeBuilding,
        EventTypes.routeBuilt,
        EventTypes.routeBuildFailed,
        EventTypes.progressChange,
        EventTypes.userOffRoute,
        EventTypes.milestoneEvent,
        EventTypes.routeRerouted,
        EventTypes.onArrival,
        EventTypes.navigationCancelled,
        EventTypes.navigationFinished,
        EventTypes.markerTapped,
        EventTypes.markerCalloutTapped,
        EventTypes.downloadProgress,
        EventTypes.downloadComplete,
        EventTypes.downloadFailed,
      };
      expect(eventTypes.length, equals(16));
    });
  });

  group('ErrorCodes', () {
    test('permissionDenied should be defined', () {
      expect(ErrorCodes.permissionDenied, equals('PERMISSION_DENIED'));
    });

    test('locationUnavailable should be defined', () {
      expect(ErrorCodes.locationUnavailable, equals('LOCATION_UNAVAILABLE'));
    });

    test('routeNotFound should be defined', () {
      expect(ErrorCodes.routeNotFound, equals('ROUTE_NOT_FOUND'));
    });

    test('networkError should be defined', () {
      expect(ErrorCodes.networkError, equals('NETWORK_ERROR'));
    });

    test('invalidArguments should be defined', () {
      expect(ErrorCodes.invalidArguments, equals('INVALID_ARGUMENTS'));
    });

    test('invalidToken should be defined', () {
      expect(ErrorCodes.invalidToken, equals('INVALID_TOKEN'));
    });

    test('notImplemented should be defined', () {
      expect(ErrorCodes.notImplemented, equals('NOT_IMPLEMENTED'));
    });

    test('timeout should be defined', () {
      expect(ErrorCodes.timeout, equals('TIMEOUT'));
    });

    test('cancelled should be defined', () {
      expect(ErrorCodes.cancelled, equals('CANCELLED'));
    });

    test('all error codes should be uppercase', () {
      final codes = [
        ErrorCodes.permissionDenied,
        ErrorCodes.locationUnavailable,
        ErrorCodes.routeNotFound,
        ErrorCodes.networkError,
        ErrorCodes.invalidArguments,
        ErrorCodes.invalidToken,
        ErrorCodes.notImplemented,
        ErrorCodes.timeout,
        ErrorCodes.cancelled,
      ];

      for (final code in codes) {
        expect(code, equals(code.toUpperCase()),
            reason: 'Error code "$code" should be uppercase');
      }
    });

    test('all error codes should be unique', () {
      final codes = {
        ErrorCodes.permissionDenied,
        ErrorCodes.locationUnavailable,
        ErrorCodes.routeNotFound,
        ErrorCodes.networkError,
        ErrorCodes.invalidArguments,
        ErrorCodes.invalidToken,
        ErrorCodes.notImplemented,
        ErrorCodes.timeout,
        ErrorCodes.cancelled,
      };
      expect(codes.length, equals(9));
    });
  });

  group('Contract Consistency', () {
    test('all method names should match their constant names', () {
      // Verify method names are consistent (snake_case pattern check)
      expect(Methods.getPlatformVersion, contains('Platform'));
      expect(Methods.startNavigation, contains('Navigation'));
      expect(Methods.addStaticMarkers, contains('Markers'));
      expect(Methods.getMapViewport, contains('Viewport'));
    });

    test('all event types should use snake_case', () {
      final eventTypes = [
        EventTypes.navigationStarted,
        EventTypes.routeBuilding,
        EventTypes.routeBuilt,
        EventTypes.progressChange,
        EventTypes.userOffRoute,
      ];

      for (final eventType in eventTypes) {
        expect(eventType, matches(RegExp(r'^[a-z_]+$')),
            reason: 'Event type "$eventType" should be snake_case');
      }
    });
  });
}
