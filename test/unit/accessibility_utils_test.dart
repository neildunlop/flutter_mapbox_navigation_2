import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_mapbox_navigation/src/accessibility/accessibility_utils.dart';

void main() {
  group('Touch Target Size Constants', () {
    test('kMinTouchTargetSize should be 48.0', () {
      expect(kMinTouchTargetSize, equals(48.0));
    });

    test('kRecommendedTouchTargetSize should be 56.0', () {
      expect(kRecommendedTouchTargetSize, equals(56.0));
    });

    test('kRecommendedTouchTargetSize should be greater than kMinTouchTargetSize', () {
      expect(kRecommendedTouchTargetSize, greaterThan(kMinTouchTargetSize));
    });
  });

  group('NavigationSemantics', () {
    test('mapView should be defined', () {
      expect(NavigationSemantics.mapView, equals('Navigation map'));
    });

    test('mapViewHint should be defined', () {
      expect(NavigationSemantics.mapViewHint,
          equals('Shows your current route and position'));
    });

    test('markerPopup should be defined', () {
      expect(NavigationSemantics.markerPopup, equals('Marker details'));
    });

    test('closeButton should be defined', () {
      expect(NavigationSemantics.closeButton, equals('Close'));
    });

    test('closeButtonHint should be defined', () {
      expect(NavigationSemantics.closeButtonHint,
          equals('Double tap to close this panel'));
    });

    test('addToRouteButton should be defined', () {
      expect(NavigationSemantics.addToRouteButton, equals('Add to route'));
    });

    test('addToRouteButtonHint should be defined', () {
      expect(NavigationSemantics.addToRouteButtonHint,
          equals('Double tap to add this location to your route'));
    });

    test('instructionBanner should be defined', () {
      expect(NavigationSemantics.instructionBanner, equals('Navigation instruction'));
    });

    test('routeProgress should be defined', () {
      expect(NavigationSemantics.routeProgress, equals('Route progress'));
    });

    group('Format functions', () {
      test('markerTitle should format correctly', () {
        expect(NavigationSemantics.markerTitle('Gas Station'),
            equals('Marker: Gas Station'));
      });

      test('markerWithCategory should format correctly', () {
        expect(
            NavigationSemantics.markerWithCategory('Shell', 'Gas Station'),
            equals('Shell, Category: Gas Station'));
      });

      test('distanceRemaining should format correctly', () {
        expect(NavigationSemantics.distanceRemaining('5 km'),
            equals('Distance remaining: 5 km'));
      });

      test('timeRemaining should format correctly', () {
        expect(NavigationSemantics.timeRemaining('10 minutes'),
            equals('Time remaining: 10 minutes'));
      });

      test('arrivedAt should format correctly', () {
        expect(NavigationSemantics.arrivedAt('Home'),
            equals('Arrived at Home'));
      });

      test('nextTurn should format correctly', () {
        expect(NavigationSemantics.nextTurn('Turn right'),
            equals('Next: Turn right'));
      });
    });
  });

  group('AccessibleTouchTarget', () {
    testWidgets('should create widget with minimum size', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AccessibleTouchTarget(
              child: Text('Test'),
            ),
          ),
        ),
      );

      // Find the ConstrainedBox that's a descendant of AccessibleTouchTarget
      final finder = find.descendant(
        of: find.byType(AccessibleTouchTarget),
        matching: find.byType(ConstrainedBox),
      );

      final constrainedBox = tester.widget<ConstrainedBox>(finder.first);

      expect(constrainedBox.constraints.minWidth, equals(kMinTouchTargetSize));
      expect(constrainedBox.constraints.minHeight, equals(kMinTouchTargetSize));
    });

    testWidgets('should create widget with custom minimum size', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AccessibleTouchTarget(
              minSize: 56.0,
              child: Text('Test'),
            ),
          ),
        ),
      );

      final finder = find.descendant(
        of: find.byType(AccessibleTouchTarget),
        matching: find.byType(ConstrainedBox),
      );

      final constrainedBox = tester.widget<ConstrainedBox>(finder.first);

      expect(constrainedBox.constraints.minWidth, equals(56.0));
      expect(constrainedBox.constraints.minHeight, equals(56.0));
    });

    testWidgets('should add InkWell when onTap is provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AccessibleTouchTarget(
              onTap: () {},
              child: const Text('Test'),
            ),
          ),
        ),
      );

      expect(find.byType(InkWell), findsOneWidget);
    });

    testWidgets('should not add InkWell when onTap is null', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AccessibleTouchTarget(
              child: Text('Test'),
            ),
          ),
        ),
      );

      expect(find.byType(InkWell), findsNothing);
    });

    testWidgets('should add Semantics when label is provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AccessibleTouchTarget(
              semanticLabel: 'Test Button',
              semanticHint: 'Double tap to activate',
              child: Text('Test'),
            ),
          ),
        ),
      );

      expect(find.byWidgetPredicate((widget) =>
          widget is Semantics && widget.properties.label == 'Test Button'),
          findsOneWidget);
    });

    testWidgets('should trigger onTap callback', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AccessibleTouchTarget(
              onTap: () => tapped = true,
              child: const Text('Test'),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(InkWell));
      expect(tapped, isTrue);
    });
  });

  group('AccessibleIconButton', () {
    testWidgets('should create button with minimum touch target', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AccessibleIconButton(
              icon: Icons.close,
              semanticLabel: 'Close',
            ),
          ),
        ),
      );

      final finder = find.descendant(
        of: find.byType(AccessibleIconButton),
        matching: find.byType(ConstrainedBox),
      );

      final constrainedBox = tester.widget<ConstrainedBox>(finder.first);

      expect(constrainedBox.constraints.minWidth, equals(kMinTouchTargetSize));
      expect(constrainedBox.constraints.minHeight, equals(kMinTouchTargetSize));
    });

    testWidgets('should display correct icon', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AccessibleIconButton(
              icon: Icons.add,
              semanticLabel: 'Add',
            ),
          ),
        ),
      );

      final icon = tester.widget<Icon>(find.byType(Icon));
      expect(icon.icon, equals(Icons.add));
    });

    testWidgets('should use custom icon size', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AccessibleIconButton(
              icon: Icons.add,
              iconSize: 32.0,
              semanticLabel: 'Add',
            ),
          ),
        ),
      );

      final icon = tester.widget<Icon>(find.byType(Icon));
      expect(icon.size, equals(32.0));
    });

    testWidgets('should use custom colors', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AccessibleIconButton(
              icon: Icons.add,
              iconColor: Colors.red,
              backgroundColor: Colors.blue,
              semanticLabel: 'Add',
            ),
          ),
        ),
      );

      final icon = tester.widget<Icon>(find.byType(Icon));
      expect(icon.color, equals(Colors.red));

      final materialFinder = find.descendant(
        of: find.byType(AccessibleIconButton),
        matching: find.byType(Material),
      );
      final material = tester.widget<Material>(materialFinder.first);
      expect(material.color, equals(Colors.blue));
    });

    testWidgets('should trigger onPressed callback', (tester) async {
      bool pressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AccessibleIconButton(
              icon: Icons.close,
              semanticLabel: 'Close',
              onPressed: () => pressed = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(InkWell));
      expect(pressed, isTrue);
    });

    testWidgets('should have proper semantic properties', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AccessibleIconButton(
              icon: Icons.close,
              semanticLabel: 'Close button',
              semanticHint: 'Closes the dialog',
            ),
          ),
        ),
      );

      expect(
        find.byWidgetPredicate((widget) =>
            widget is Semantics &&
            widget.properties.label == 'Close button' &&
            widget.properties.button == true),
        findsOneWidget,
      );
    });
  });

  group('LiveRegion', () {
    testWidgets('should create widget with live region semantics', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LiveRegion(
              announcement: 'Route updated',
              child: Text('Content'),
            ),
          ),
        ),
      );

      expect(
        find.byWidgetPredicate((widget) =>
            widget is Semantics && widget.properties.liveRegion == true),
        findsOneWidget,
      );
    });

    testWidgets('should have correct announcement label', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LiveRegion(
              announcement: 'Arrived at destination',
              child: Text('Content'),
            ),
          ),
        ),
      );

      expect(
        find.byWidgetPredicate((widget) =>
            widget is Semantics &&
            widget.properties.label == 'Arrived at destination'),
        findsOneWidget,
      );
    });

    testWidgets('should display child widget', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LiveRegion(
              announcement: 'Test',
              child: Text('Child Content'),
            ),
          ),
        ),
      );

      expect(find.text('Child Content'), findsOneWidget);
    });
  });

  group('semanticMarkerContainer', () {
    testWidgets('should create container with title only', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: semanticMarkerContainer(
              markerTitle: 'Gas Station',
              child: const Text('Content'),
            ),
          ),
        ),
      );

      expect(
        find.byWidgetPredicate((widget) =>
            widget is Semantics && widget.properties.label == 'Gas Station'),
        findsOneWidget,
      );
    });

    testWidgets('should include category in label', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: semanticMarkerContainer(
              markerTitle: 'Shell',
              markerCategory: 'Gas Station',
              child: const Text('Content'),
            ),
          ),
        ),
      );

      expect(
        find.byWidgetPredicate((widget) =>
            widget is Semantics &&
            widget.properties.label == 'Shell. Category: Gas Station'),
        findsOneWidget,
      );
    });

    testWidgets('should include description in label', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: semanticMarkerContainer(
              markerTitle: 'Shell',
              markerDescription: 'Open 24 hours',
              child: const Text('Content'),
            ),
          ),
        ),
      );

      expect(
        find.byWidgetPredicate((widget) =>
            widget is Semantics &&
            widget.properties.label == 'Shell. Open 24 hours'),
        findsOneWidget,
      );
    });

    testWidgets('should include all fields in label', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: semanticMarkerContainer(
              markerTitle: 'Shell',
              markerCategory: 'Gas Station',
              markerDescription: 'Open 24 hours',
              child: const Text('Content'),
            ),
          ),
        ),
      );

      expect(
        find.byWidgetPredicate((widget) =>
            widget is Semantics &&
            widget.properties.label ==
                'Shell. Category: Gas Station. Open 24 hours'),
        findsOneWidget,
      );
    });

    testWidgets('should skip empty category', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: semanticMarkerContainer(
              markerTitle: 'Shell',
              markerCategory: '',
              markerDescription: 'Open 24 hours',
              child: const Text('Content'),
            ),
          ),
        ),
      );

      expect(
        find.byWidgetPredicate((widget) =>
            widget is Semantics &&
            widget.properties.label == 'Shell. Open 24 hours'),
        findsOneWidget,
      );
    });
  });

  group('AccessibilityExtensions', () {
    testWidgets('withSemanticLabel should add semantics', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: const Text('Content').withSemanticLabel('Test Label'),
          ),
        ),
      );

      expect(
        find.byWidgetPredicate((widget) =>
            widget is Semantics && widget.properties.label == 'Test Label'),
        findsOneWidget,
      );
    });

    testWidgets('withSemanticLabel should add hint', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: const Text('Content').withSemanticLabel(
              'Test Label',
              hint: 'Test Hint',
            ),
          ),
        ),
      );

      expect(
        find.byWidgetPredicate((widget) =>
            widget is Semantics && widget.properties.hint == 'Test Hint'),
        findsOneWidget,
      );
    });

    testWidgets('asSemanticButton should mark as button', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: const Text('Click me').asSemanticButton('Button Label'),
          ),
        ),
      );

      expect(
        find.byWidgetPredicate((widget) =>
            widget is Semantics && widget.properties.button == true),
        findsOneWidget,
      );
    });

    testWidgets('asSemanticButton should handle enabled state', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: const Text('Click me').asSemanticButton(
              'Button Label',
              enabled: false,
            ),
          ),
        ),
      );

      expect(
        find.byWidgetPredicate((widget) =>
            widget is Semantics && widget.properties.enabled == false),
        findsOneWidget,
      );
    });

    testWidgets('asLiveRegion should mark as live region', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: const Text('Content').asLiveRegion('Announcement'),
          ),
        ),
      );

      expect(
        find.byWidgetPredicate((widget) =>
            widget is Semantics && widget.properties.liveRegion == true),
        findsOneWidget,
      );
    });
  });

  group('announceToScreenReader', () {
    test('should not throw when called', () {
      // This test verifies the function doesn't throw
      // The actual announcement is handled by the platform
      expect(
        () => announceToScreenReader('Test message'),
        returnsNormally,
      );
    });

    test('should not throw with custom text direction', () {
      expect(
        () => announceToScreenReader(
          'Test message',
          textDirection: TextDirection.rtl,
        ),
        returnsNormally,
      );
    });
  });
}
