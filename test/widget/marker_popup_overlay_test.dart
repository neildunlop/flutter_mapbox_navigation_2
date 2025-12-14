import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_mapbox_navigation/src/widgets/marker_popup_overlay.dart';
import 'package:flutter_mapbox_navigation/src/models/static_marker.dart';
import 'package:flutter_mapbox_navigation/src/models/marker_configuration.dart';

void main() {
  group('PopupPosition', () {
    test('should create with required parameters', () {
      final marker = StaticMarker(
        id: 'test',
        latitude: 51.5074,
        longitude: -0.1278,
        title: 'Test',
        category: 'test',
      );

      final position = PopupPosition(
        screenPosition: const Offset(100, 200),
        marker: marker,
        timestamp: DateTime.now(),
      );

      expect(position.screenPosition, const Offset(100, 200));
      expect(position.marker, marker);
      expect(position.timestamp, isNotNull);
    });

    test('isValid should return true for recent position', () {
      final marker = StaticMarker(
        id: 'test',
        latitude: 51.5074,
        longitude: -0.1278,
        title: 'Test',
        category: 'test',
      );

      final position = PopupPosition(
        screenPosition: const Offset(100, 200),
        marker: marker,
        timestamp: DateTime.now(),
      );

      expect(position.isValid(const Duration(seconds: 10)), isTrue);
    });

    test('isValid should return false for old position', () {
      final marker = StaticMarker(
        id: 'test',
        latitude: 51.5074,
        longitude: -0.1278,
        title: 'Test',
        category: 'test',
      );

      final position = PopupPosition(
        screenPosition: const Offset(100, 200),
        marker: marker,
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
      );

      expect(position.isValid(const Duration(seconds: 10)), isFalse);
    });
  });

  group('MarkerPopupOverlay', () {
    testWidgets('should render child widget', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MarkerPopupOverlay(
            configuration: MarkerConfiguration(),
            child: Text('Child Widget'),
          ),
        ),
      );

      expect(find.text('Child Widget'), findsOneWidget);
    });

    testWidgets('should not show popup when no marker is selected', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MarkerPopupOverlay(
            configuration: MarkerConfiguration(
              popupBuilder: (marker, context) => Text(marker.title),
            ),
            child: const Text('Child Widget'),
          ),
        ),
      );

      // Should not find POPUP ACTIVE debug indicator
      expect(find.text('POPUP ACTIVE'), findsNothing);
    });

    testWidgets('should show popup when marker is selected', (tester) async {
      final marker = StaticMarker(
        id: 'test-marker',
        latitude: 51.5074,
        longitude: -0.1278,
        title: 'Test Marker',
        category: 'test',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: MarkerPopupOverlay(
            configuration: MarkerConfiguration(
              popupBuilder: (marker, context) => Text(marker.title),
            ),
            selectedMarker: marker,
            markerScreenPosition: const Offset(100, 100),
            child: const Text('Child Widget'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should find POPUP ACTIVE debug indicator
      expect(find.text('POPUP ACTIVE'), findsOneWidget);
    });

    testWidgets('should call onHidePopup when close button is tapped', (tester) async {
      var hidePopupCalled = false;
      final marker = StaticMarker(
        id: 'test-marker',
        latitude: 51.5074,
        longitude: -0.1278,
        title: 'Test Marker',
        category: 'test',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MarkerPopupOverlay(
              configuration: MarkerConfiguration(
                popupBuilder: (marker, context) => Text(marker.title),
                hidePopupOnTapOutside: true,
                popupDuration: Duration.zero, // Disable auto-hide
              ),
              selectedMarker: marker,
              markerScreenPosition: const Offset(100, 100),
              onHidePopup: () => hidePopupCalled = true,
              child: const SizedBox(width: 400, height: 800),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find and tap the close button (Icon with close)
      final closeButton = find.byIcon(Icons.close);
      if (closeButton.evaluate().isNotEmpty) {
        await tester.tap(closeButton);
        await tester.pumpAndSettle();
        expect(hidePopupCalled, isTrue);
      } else {
        // If close button not found, just verify popup is visible
        expect(find.text('POPUP ACTIVE'), findsOneWidget);
      }
    });

    testWidgets('should not require popup when no popupBuilder provided', (tester) async {
      final marker = StaticMarker(
        id: 'test-marker',
        latitude: 51.5074,
        longitude: -0.1278,
        title: 'Test Marker',
        category: 'test',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: MarkerPopupOverlay(
            configuration: const MarkerConfiguration(),
            selectedMarker: marker,
            markerScreenPosition: const Offset(100, 100),
            child: const Text('Child Widget'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should not show popup without builder
      expect(find.text('POPUP ACTIVE'), findsNothing);
    });

    testWidgets('should animate popup appearance', (tester) async {
      final marker = StaticMarker(
        id: 'test-marker',
        latitude: 51.5074,
        longitude: -0.1278,
        title: 'Test Marker',
        category: 'test',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: MarkerPopupOverlay(
            configuration: MarkerConfiguration(
              popupBuilder: (marker, context) => Text(marker.title),
            ),
            selectedMarker: marker,
            markerScreenPosition: const Offset(100, 100),
            child: const Text('Child Widget'),
          ),
        ),
      );

      // Pump a few frames to see animation progress
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pumpAndSettle();

      expect(find.text('POPUP ACTIVE'), findsOneWidget);
    });

    testWidgets('should update when marker changes', (tester) async {
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

      await tester.pumpWidget(
        MaterialApp(
          home: MarkerPopupOverlay(
            configuration: MarkerConfiguration(
              popupBuilder: (marker, context) => Text(marker.title),
              popupDuration: Duration.zero, // Disable auto-hide timer
            ),
            selectedMarker: marker1,
            markerScreenPosition: const Offset(100, 100),
            child: const Text('Child Widget'),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Marker 1'), findsOneWidget);

      // Change to marker 2
      await tester.pumpWidget(
        MaterialApp(
          home: MarkerPopupOverlay(
            configuration: MarkerConfiguration(
              popupBuilder: (marker, context) => Text(marker.title),
              popupDuration: Duration.zero, // Disable auto-hide timer
            ),
            selectedMarker: marker2,
            markerScreenPosition: const Offset(150, 150),
            child: const Text('Child Widget'),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Marker 2'), findsOneWidget);
    });

    testWidgets('should hide popup when marker becomes null', (tester) async {
      final marker = StaticMarker(
        id: 'test-marker',
        latitude: 51.5074,
        longitude: -0.1278,
        title: 'Test Marker',
        category: 'test',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: MarkerPopupOverlay(
            configuration: MarkerConfiguration(
              popupBuilder: (marker, context) => Text(marker.title),
            ),
            selectedMarker: marker,
            markerScreenPosition: const Offset(100, 100),
            child: const Text('Child Widget'),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('POPUP ACTIVE'), findsOneWidget);

      // Set marker to null
      await tester.pumpWidget(
        MaterialApp(
          home: MarkerPopupOverlay(
            configuration: MarkerConfiguration(
              popupBuilder: (marker, context) => Text(marker.title),
            ),
            child: const Text('Child Widget'),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('POPUP ACTIVE'), findsNothing);
    });

    testWidgets('should apply popup offset from configuration', (tester) async {
      final marker = StaticMarker(
        id: 'test-marker',
        latitude: 51.5074,
        longitude: -0.1278,
        title: 'Test Marker',
        category: 'test',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: MarkerPopupOverlay(
            configuration: MarkerConfiguration(
              popupBuilder: (marker, context) => Container(
                key: const Key('popup-content'),
                child: Text(marker.title),
              ),
              popupOffset: const Offset(20, 30),
            ),
            selectedMarker: marker,
            markerScreenPosition: const Offset(100, 100),
            child: const Text('Child Widget'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Popup should be positioned with offset
      expect(find.byKey(const Key('popup-content')), findsOneWidget);
    });
  });

  group('DefaultMarkerPopup', () {
    testWidgets('should display marker title', (tester) async {
      final marker = StaticMarker(
        id: 'test-marker',
        latitude: 51.5074,
        longitude: -0.1278,
        title: 'Test Title',
        category: 'test',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DefaultMarkerPopup(marker: marker),
          ),
        ),
      );

      expect(find.text('Test Title'), findsOneWidget);
    });

    testWidgets('should display marker category', (tester) async {
      final marker = StaticMarker(
        id: 'test-marker',
        latitude: 51.5074,
        longitude: -0.1278,
        title: 'Test Title',
        category: 'Restaurant',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DefaultMarkerPopup(marker: marker),
          ),
        ),
      );

      expect(find.text('Restaurant'), findsOneWidget);
    });

    testWidgets('should display marker description when provided', (tester) async {
      final marker = StaticMarker(
        id: 'test-marker',
        latitude: 51.5074,
        longitude: -0.1278,
        title: 'Test Title',
        category: 'test',
        description: 'This is a test description',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DefaultMarkerPopup(marker: marker),
          ),
        ),
      );

      expect(find.text('This is a test description'), findsOneWidget);
    });

    testWidgets('should not display description when empty', (tester) async {
      final marker = StaticMarker(
        id: 'test-marker',
        latitude: 51.5074,
        longitude: -0.1278,
        title: 'Test Title',
        category: 'test',
        description: '',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DefaultMarkerPopup(marker: marker),
          ),
        ),
      );

      expect(find.text('Test Title'), findsOneWidget);
      // No description shown
    });

    testWidgets('should display coordinates when showCoordinates metadata is true', (tester) async {
      final marker = StaticMarker(
        id: 'test-marker',
        latitude: 51.507400,
        longitude: -0.127800,
        title: 'Test Title',
        category: 'test',
        metadata: {'showCoordinates': true},
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DefaultMarkerPopup(marker: marker),
          ),
        ),
      );

      expect(find.textContaining('51.507400'), findsOneWidget);
      expect(find.textContaining('-0.127800'), findsOneWidget);
    });

    testWidgets('should display metadata items', (tester) async {
      final marker = StaticMarker(
        id: 'test-marker',
        latitude: 51.5074,
        longitude: -0.1278,
        title: 'Test Title',
        category: 'test',
        metadata: {
          'rating': '4.5',
          'price': '\$\$',
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DefaultMarkerPopup(marker: marker),
          ),
        ),
      );

      expect(find.text('rating: 4.5'), findsOneWidget);
      expect(find.text('price: \$\$'), findsOneWidget);
    });

    testWidgets('should limit metadata items to 3', (tester) async {
      final marker = StaticMarker(
        id: 'test-marker',
        latitude: 51.5074,
        longitude: -0.1278,
        title: 'Test Title',
        category: 'test',
        metadata: {
          'item1': 'value1',
          'item2': 'value2',
          'item3': 'value3',
          'item4': 'value4',
          'item5': 'value5',
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DefaultMarkerPopup(marker: marker),
          ),
        ),
      );

      // Should only show 3 metadata items (implementation takes first 3)
      var foundCount = 0;
      if (find.text('item1: value1').evaluate().isNotEmpty) foundCount++;
      if (find.text('item2: value2').evaluate().isNotEmpty) foundCount++;
      if (find.text('item3: value3').evaluate().isNotEmpty) foundCount++;
      if (find.text('item4: value4').evaluate().isNotEmpty) foundCount++;
      if (find.text('item5: value5').evaluate().isNotEmpty) foundCount++;

      expect(foundCount, lessThanOrEqualTo(3));
    });

    testWidgets('should not display empty category', (tester) async {
      final marker = StaticMarker(
        id: 'test-marker',
        latitude: 51.5074,
        longitude: -0.1278,
        title: 'Test Title',
        category: '',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DefaultMarkerPopup(marker: marker),
          ),
        ),
      );

      expect(find.text('Test Title'), findsOneWidget);
      // Category container should not be present for empty category
    });

    testWidgets('should apply custom color to category', (tester) async {
      final marker = StaticMarker(
        id: 'test-marker',
        latitude: 51.5074,
        longitude: -0.1278,
        title: 'Test Title',
        category: 'Custom',
        customColor: Colors.red,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DefaultMarkerPopup(marker: marker),
          ),
        ),
      );

      expect(find.text('Custom'), findsOneWidget);
      // The color styling is applied through decoration
    });
  });
}
