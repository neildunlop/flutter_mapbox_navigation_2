import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_mapbox_navigation/src/managers/marker_popup_manager.dart';
import 'package:flutter_mapbox_navigation/src/models/static_marker.dart';
import 'package:flutter_mapbox_navigation/src/models/marker_configuration.dart';
import 'package:flutter_mapbox_navigation/src/utilities/coordinate_converter.dart';

void main() {
  late MarkerPopupManager manager;

  setUp(() {
    manager = MarkerPopupManager();
    manager.reset(); // Reset singleton state
  });

  tearDown(() {
    manager.cleanup();
  });

  group('MarkerPopupManager', () {
    group('Singleton behavior', () {
      test('should return same instance', () {
        final instance1 = MarkerPopupManager();
        final instance2 = MarkerPopupManager();

        expect(identical(instance1, instance2), isTrue);
      });
    });

    group('Initial state', () {
      test('should have no selected marker initially', () {
        expect(manager.selectedMarker, isNull);
      });

      test('should have no marker screen position initially', () {
        expect(manager.markerScreenPosition, isNull);
      });

      test('should not have active popup initially', () {
        expect(manager.hasActivePopup, isFalse);
      });

      test('should be enabled by default', () {
        expect(manager.isEnabled, isTrue);
      });
    });

    group('showPopupForMarker', () {
      test('should select marker when showing popup', () {
        final marker = StaticMarker(
          id: 'test-marker-1',
          latitude: 51.5074,
          longitude: -0.1278,
          title: 'Test Marker',
          category: 'test',
        );

        manager.showPopupForMarker(marker);

        expect(manager.selectedMarker, equals(marker));
      });

      test('should set screen position when provided', () {
        final marker = StaticMarker(
          id: 'test-marker-2',
          latitude: 51.5074,
          longitude: -0.1278,
          title: 'Test Marker',
          category: 'test',
        );
        const screenPosition = Offset(100, 200);

        manager.showPopupForMarker(marker, screenPosition: screenPosition);

        expect(manager.markerScreenPosition, equals(screenPosition));
      });

      test('should have active popup after showing', () {
        final marker = StaticMarker(
          id: 'test-marker-3',
          latitude: 51.5074,
          longitude: -0.1278,
          title: 'Test Marker',
          category: 'test',
        );

        manager.showPopupForMarker(marker, screenPosition: const Offset(0, 0));

        expect(manager.hasActivePopup, isTrue);
      });

      test('should notify listeners when showing popup', () {
        final marker = StaticMarker(
          id: 'test-marker-4',
          latitude: 51.5074,
          longitude: -0.1278,
          title: 'Test Marker',
          category: 'test',
        );

        var notified = false;
        manager.addListener(() => notified = true);

        manager.showPopupForMarker(marker, screenPosition: const Offset(0, 0));

        expect(notified, isTrue);

        manager.removeListener(() => notified = true);
      });

      test('should replace previous marker when showing new one', () {
        final marker1 = StaticMarker(
          id: 'marker-1',
          latitude: 51.5074,
          longitude: -0.1278,
          title: 'Marker 1',
          category: 'test',
        );
        final marker2 = StaticMarker(
          id: 'marker-2',
          latitude: 48.8566,
          longitude: 2.3522,
          title: 'Marker 2',
          category: 'test',
        );

        manager.showPopupForMarker(marker1, screenPosition: const Offset(0, 0));
        manager.showPopupForMarker(marker2, screenPosition: const Offset(100, 100));

        expect(manager.selectedMarker, equals(marker2));
        expect(manager.markerScreenPosition, const Offset(100, 100));
      });
    });

    group('hidePopup', () {
      test('should clear selected marker', () {
        final marker = StaticMarker(
          id: 'test-marker',
          latitude: 51.5074,
          longitude: -0.1278,
          title: 'Test Marker',
          category: 'test',
        );

        manager.showPopupForMarker(marker, screenPosition: const Offset(0, 0));
        manager.hidePopup();

        expect(manager.selectedMarker, isNull);
      });

      test('should clear marker screen position', () {
        final marker = StaticMarker(
          id: 'test-marker',
          latitude: 51.5074,
          longitude: -0.1278,
          title: 'Test Marker',
          category: 'test',
        );

        manager.showPopupForMarker(marker, screenPosition: const Offset(100, 200));
        manager.hidePopup();

        expect(manager.markerScreenPosition, isNull);
      });

      test('should not have active popup after hiding', () {
        final marker = StaticMarker(
          id: 'test-marker',
          latitude: 51.5074,
          longitude: -0.1278,
          title: 'Test Marker',
          category: 'test',
        );

        manager.showPopupForMarker(marker, screenPosition: const Offset(0, 0));
        manager.hidePopup();

        expect(manager.hasActivePopup, isFalse);
      });

      test('should notify listeners when hiding popup', () {
        final marker = StaticMarker(
          id: 'test-marker',
          latitude: 51.5074,
          longitude: -0.1278,
          title: 'Test Marker',
          category: 'test',
        );

        manager.showPopupForMarker(marker, screenPosition: const Offset(0, 0));

        var notified = false;
        manager.addListener(() => notified = true);

        manager.hidePopup();

        expect(notified, isTrue);
      });

      test('should be safe to call when no popup is shown', () {
        // Should not throw
        expect(() => manager.hidePopup(), returnsNormally);
      });
    });

    group('setEnabled', () {
      test('should update enabled state', () {
        manager.setEnabled(false);
        expect(manager.isEnabled, isFalse);

        manager.setEnabled(true);
        expect(manager.isEnabled, isTrue);
      });

      test('should hide popup when disabled', () {
        final marker = StaticMarker(
          id: 'test-marker',
          latitude: 51.5074,
          longitude: -0.1278,
          title: 'Test Marker',
          category: 'test',
        );

        manager.showPopupForMarker(marker, screenPosition: const Offset(0, 0));
        manager.setEnabled(false);

        expect(manager.selectedMarker, isNull);
        expect(manager.hasActivePopup, isFalse);
      });

      test('should not hide popup when already enabled', () {
        final marker = StaticMarker(
          id: 'test-marker',
          latitude: 51.5074,
          longitude: -0.1278,
          title: 'Test Marker',
          category: 'test',
        );

        manager.showPopupForMarker(marker, screenPosition: const Offset(0, 0));
        manager.setEnabled(true);

        expect(manager.selectedMarker, equals(marker));
        expect(manager.hasActivePopup, isTrue);
      });
    });

    group('handleMarkerTap', () {
      test('should show popup when marker is tapped', () {
        final marker = StaticMarker(
          id: 'test-marker',
          latitude: 51.5074,
          longitude: -0.1278,
          title: 'Test Marker',
          category: 'test',
        );

        manager.handleMarkerTap(marker, screenPosition: const Offset(100, 200));

        expect(manager.selectedMarker, equals(marker));
      });

      test('should hide popup when same marker is tapped again', () {
        final marker = StaticMarker(
          id: 'test-marker',
          latitude: 51.5074,
          longitude: -0.1278,
          title: 'Test Marker',
          category: 'test',
        );

        manager.handleMarkerTap(marker, screenPosition: const Offset(0, 0));
        manager.handleMarkerTap(marker, screenPosition: const Offset(0, 0));

        expect(manager.selectedMarker, isNull);
      });

      test('should switch to new marker when different marker is tapped', () {
        final marker1 = StaticMarker(
          id: 'marker-1',
          latitude: 51.5074,
          longitude: -0.1278,
          title: 'Marker 1',
          category: 'test',
        );
        final marker2 = StaticMarker(
          id: 'marker-2',
          latitude: 48.8566,
          longitude: 2.3522,
          title: 'Marker 2',
          category: 'test',
        );

        manager.handleMarkerTap(marker1, screenPosition: const Offset(0, 0));
        manager.handleMarkerTap(marker2, screenPosition: const Offset(100, 100));

        expect(manager.selectedMarker, equals(marker2));
      });

      test('should not show popup when disabled', () {
        final marker = StaticMarker(
          id: 'test-marker',
          latitude: 51.5074,
          longitude: -0.1278,
          title: 'Test Marker',
          category: 'test',
        );

        manager.setEnabled(false);
        manager.handleMarkerTap(marker, screenPosition: const Offset(0, 0));

        expect(manager.selectedMarker, isNull);
      });
    });

    group('isMarkerSelected', () {
      test('should return true for selected marker', () {
        final marker = StaticMarker(
          id: 'test-marker',
          latitude: 51.5074,
          longitude: -0.1278,
          title: 'Test Marker',
          category: 'test',
        );

        manager.showPopupForMarker(marker, screenPosition: const Offset(0, 0));

        expect(manager.isMarkerSelected('test-marker'), isTrue);
      });

      test('should return false for non-selected marker', () {
        final marker = StaticMarker(
          id: 'test-marker',
          latitude: 51.5074,
          longitude: -0.1278,
          title: 'Test Marker',
          category: 'test',
        );

        manager.showPopupForMarker(marker, screenPosition: const Offset(0, 0));

        expect(manager.isMarkerSelected('other-marker'), isFalse);
      });

      test('should return false when no marker is selected', () {
        expect(manager.isMarkerSelected('any-marker'), isFalse);
      });
    });

    group('updateMapViewport', () {
      test('should update viewport', () {
        const viewport = MapViewport(
          center: LatLng(51.5074, -0.1278),
          zoomLevel: 15.0,
          size: Size(400, 800),
        );

        manager.updateMapViewport(viewport);

        // Verify it doesn't throw
        expect(() => manager.updateMapViewport(viewport), returnsNormally);
      });

      test('should recalculate marker position when viewport changes', () {
        final marker = StaticMarker(
          id: 'test-marker',
          latitude: 51.5074,
          longitude: -0.1278,
          title: 'Test Marker',
          category: 'test',
        );

        const viewport = MapViewport(
          center: LatLng(51.5074, -0.1278),
          zoomLevel: 15.0,
          size: Size(400, 800),
        );

        manager.showPopupForMarker(marker, screenPosition: const Offset(100, 100));
        manager.updateMapViewport(viewport);

        // After viewport update with marker at center, position should be calculated
        expect(manager.markerScreenPosition, isNotNull);
      });
    });

    group('setConfiguration', () {
      test('should set configuration', () {
        const config = MarkerConfiguration();

        // Should not throw
        expect(() => manager.setConfiguration(config), returnsNormally);
      });

      test('should set configuration with custom values', () {
        const config = MarkerConfiguration(
          popupDuration: Duration(seconds: 5),
          hidePopupOnTapOutside: false,
        );

        expect(() => manager.setConfiguration(config), returnsNormally);
      });
    });

    group('getScreenPositionForMarker', () {
      test('should return null when no viewport is set', () {
        final marker = StaticMarker(
          id: 'test-marker',
          latitude: 51.5074,
          longitude: -0.1278,
          title: 'Test Marker',
          category: 'test',
        );

        final position = manager.getScreenPositionForMarker(marker);

        expect(position, isNull);
      });

      test('should return position when viewport is set', () {
        final marker = StaticMarker(
          id: 'test-marker',
          latitude: 51.5074,
          longitude: -0.1278,
          title: 'Test Marker',
          category: 'test',
        );

        const viewport = MapViewport(
          center: LatLng(51.5074, -0.1278),
          zoomLevel: 15.0,
          size: Size(400, 800),
        );

        manager.updateMapViewport(viewport);
        final position = manager.getScreenPositionForMarker(marker);

        expect(position, isNotNull);
        // Marker at center should be at center of screen
        expect(position!.dx, closeTo(200, 1));
        expect(position.dy, closeTo(400, 1));
      });
    });

    group('cleanup', () {
      test('should reset all state', () {
        final marker = StaticMarker(
          id: 'test-marker',
          latitude: 51.5074,
          longitude: -0.1278,
          title: 'Test Marker',
          category: 'test',
        );

        const viewport = MapViewport(
          center: LatLng(51.5074, -0.1278),
          zoomLevel: 15.0,
          size: Size(400, 800),
        );

        const config = MarkerConfiguration();

        manager.showPopupForMarker(marker, screenPosition: const Offset(0, 0));
        manager.updateMapViewport(viewport);
        manager.setConfiguration(config);

        manager.cleanup();

        expect(manager.selectedMarker, isNull);
        expect(manager.markerScreenPosition, isNull);
        expect(manager.hasActivePopup, isFalse);
      });
    });

    group('reset', () {
      test('should cleanup and reset disposed state', () {
        final marker = StaticMarker(
          id: 'test-marker',
          latitude: 51.5074,
          longitude: -0.1278,
          title: 'Test Marker',
          category: 'test',
        );

        manager.showPopupForMarker(marker, screenPosition: const Offset(0, 0));
        manager.dispose(); // Mark as disposed
        manager.reset();

        expect(manager.selectedMarker, isNull);
        // Should still be able to show popup after reset
        manager.showPopupForMarker(marker, screenPosition: const Offset(0, 0));
        expect(manager.selectedMarker, equals(marker));
      });
    });
  });

  group('MarkerPopupExtensions', () {
    setUp(() {
      MarkerPopupManager().reset();
    });

    tearDown(() {
      MarkerPopupManager().cleanup();
    });

    test('showPopup should show popup for marker', () {
      final marker = StaticMarker(
        id: 'extension-test-marker',
        latitude: 51.5074,
        longitude: -0.1278,
        title: 'Extension Test',
        category: 'test',
      );

      marker.showPopup(screenPosition: const Offset(50, 50));

      expect(MarkerPopupManager().selectedMarker, equals(marker));
    });

    test('hasPopupShown should return true when marker has popup shown', () {
      final marker = StaticMarker(
        id: 'extension-test-marker',
        latitude: 51.5074,
        longitude: -0.1278,
        title: 'Extension Test',
        category: 'test',
      );

      marker.showPopup(screenPosition: const Offset(50, 50));

      expect(marker.hasPopupShown, isTrue);
    });

    test('hasPopupShown should return false when no popup is shown', () {
      final marker = StaticMarker(
        id: 'extension-test-marker',
        latitude: 51.5074,
        longitude: -0.1278,
        title: 'Extension Test',
        category: 'test',
      );

      expect(marker.hasPopupShown, isFalse);
    });

    test('hasPopupShown should return false for different marker', () {
      final marker1 = StaticMarker(
        id: 'marker-1',
        latitude: 51.5074,
        longitude: -0.1278,
        title: 'Marker 1',
        category: 'test',
      );
      final marker2 = StaticMarker(
        id: 'marker-2',
        latitude: 48.8566,
        longitude: 2.3522,
        title: 'Marker 2',
        category: 'test',
      );

      marker1.showPopup(screenPosition: const Offset(50, 50));

      expect(marker1.hasPopupShown, isTrue);
      expect(marker2.hasPopupShown, isFalse);
    });
  });
}
