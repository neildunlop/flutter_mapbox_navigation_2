# Feature Spec: Accessibility Support

## Overview

Accessibility Support ensures the Flutter Mapbox Navigation plugin is usable by people with disabilities. This includes proper semantic labels, touch target sizes, screen reader support, and live region announcements.

**Priority:** P1 - Should Have
**Effort:** Medium
**Dependencies:** None

## User Stories

1. **As a user with vision impairment**, I can use a screen reader to understand navigation instructions.
2. **As a user with motor impairment**, I can easily tap buttons with appropriately sized touch targets.
3. **As a user with vision impairment**, I receive announcements about route changes and arrivals.
4. **As a developer**, I can add semantic labels to custom UI elements.
5. **As a developer**, I can ensure my marker popups are accessible.

## Technical Approach

Accessibility is implemented through:
1. **Semantic Widgets**: Wrap UI with Semantics for screen readers
2. **Touch Targets**: Ensure minimum 48x48 dp touch areas
3. **Live Regions**: Announce dynamic content changes
4. **Widget Extensions**: Easy-to-use accessibility helpers

## API Reference

### Touch Target Constants

```dart
/// Minimum touch target size (48 dp) per WCAG guidelines
const double kMinTouchTargetSize = 48.0;

/// Recommended touch target size (56 dp) for better accessibility
const double kRecommendedTouchTargetSize = 56.0;
```

### NavigationSemantics Class

Pre-defined semantic labels for navigation UI:

```dart
class NavigationSemantics {
  // Map labels
  static const String mapView = 'Navigation map';
  static const String mapViewHint = 'Shows your current route and position';

  // Marker labels
  static const String markerPopup = 'Marker details';
  static const String closeButton = 'Close';
  static const String closeButtonHint = 'Double tap to close this panel';
  static const String addToRouteButton = 'Add to route';
  static const String addToRouteButtonHint = 'Double tap to add this location to your route';

  // Navigation labels
  static const String instructionBanner = 'Navigation instruction';
  static const String routeProgress = 'Route progress';

  // Format functions
  static String markerTitle(String title) => 'Marker: $title';
  static String markerWithCategory(String title, String category) =>
      '$title, Category: $category';
  static String distanceRemaining(String distance) =>
      'Distance remaining: $distance';
  static String timeRemaining(String time) =>
      'Time remaining: $time';
  static String arrivedAt(String destination) =>
      'Arrived at $destination';
  static String nextTurn(String instruction) =>
      'Next: $instruction';
}
```

### AccessibleTouchTarget Widget

Ensures minimum touch target size:

```dart
class AccessibleTouchTarget extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double minSize;
  final String? semanticLabel;
  final String? semanticHint;

  const AccessibleTouchTarget({
    required this.child,
    this.onTap,
    this.minSize = kMinTouchTargetSize,
    this.semanticLabel,
    this.semanticHint,
  });
}
```

#### Usage

```dart
AccessibleTouchTarget(
  onTap: () => print('Tapped'),
  semanticLabel: 'Close popup',
  semanticHint: 'Double tap to close',
  child: Icon(Icons.close),
)
```

### AccessibleIconButton Widget

Pre-styled accessible icon button:

```dart
class AccessibleIconButton extends StatelessWidget {
  final IconData icon;
  final String semanticLabel;
  final String? semanticHint;
  final VoidCallback? onPressed;
  final double iconSize;
  final Color? iconColor;
  final Color? backgroundColor;
}
```

#### Usage

```dart
AccessibleIconButton(
  icon: Icons.close,
  semanticLabel: 'Close',
  semanticHint: 'Double tap to close this panel',
  onPressed: () => Navigator.pop(context),
  iconColor: Colors.white,
  backgroundColor: Colors.black54,
)
```

### LiveRegion Widget

Announces content changes to screen readers:

```dart
class LiveRegion extends StatelessWidget {
  final String announcement;
  final Widget child;
}
```

#### Usage

```dart
LiveRegion(
  announcement: 'Route updated: Now showing alternative route',
  child: RouteInfoWidget(),
)
```

### semanticMarkerContainer Function

Creates accessible marker popup containers:

```dart
Widget semanticMarkerContainer({
  required String markerTitle,
  String? markerCategory,
  String? markerDescription,
  required Widget child,
})
```

#### Usage

```dart
semanticMarkerContainer(
  markerTitle: 'Golden Gate Bridge',
  markerCategory: 'Scenic',
  markerDescription: 'Iconic suspension bridge',
  child: MarkerPopupContent(),
)
```

### Widget Extensions

Easy accessibility helpers for any widget:

```dart
extension AccessibilityExtensions on Widget {
  /// Add semantic label to widget
  Widget withSemanticLabel(String label, {String? hint});

  /// Mark widget as a button for screen readers
  Widget asSemanticButton(String label, {bool enabled = true});

  /// Mark widget as a live region for announcements
  Widget asLiveRegion(String announcement);
}
```

#### Usage

```dart
// Add semantic label
Text('Next turn').withSemanticLabel(
  'Next turn instruction',
  hint: 'Turn right in 500 meters',
)

// Mark as button
Container(
  child: Icon(Icons.add),
).asSemanticButton('Add waypoint', enabled: true)

// Live region
Text('Route updated').asLiveRegion('New route calculated')
```

### Screen Reader Announcements

```dart
/// Announce message to screen reader
void announceToScreenReader(
  String message, {
  TextDirection textDirection = TextDirection.ltr,
})
```

#### Usage

```dart
// Announce arrival
announceToScreenReader('Arrived at San Francisco');

// Announce route change
announceToScreenReader('Route recalculated. New ETA: 15 minutes');
```

## Implementation Examples

### Accessible Marker Popup

```dart
class AccessibleMarkerPopup extends StatelessWidget {
  final StaticMarker marker;
  final VoidCallback onClose;
  final VoidCallback? onAddToRoute;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '${marker.title}. ${marker.category}. ${marker.description ?? ""}',
      child: Container(
        child: Column(
          children: [
            // Header with close button
            Row(
              children: [
                Expanded(
                  child: Text(marker.title)
                    .withSemanticLabel(NavigationSemantics.markerTitle(marker.title)),
                ),
                AccessibleIconButton(
                  icon: Icons.close,
                  semanticLabel: NavigationSemantics.closeButton,
                  semanticHint: NavigationSemantics.closeButtonHint,
                  onPressed: onClose,
                ),
              ],
            ),
            // Add to route button
            if (onAddToRoute != null)
              AccessibleTouchTarget(
                onTap: onAddToRoute,
                semanticLabel: NavigationSemantics.addToRouteButton,
                semanticHint: NavigationSemantics.addToRouteButtonHint,
                child: ElevatedButton(
                  onPressed: onAddToRoute,
                  child: Text('Add to Route'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
```

### Accessible Navigation Status

```dart
class AccessibleNavigationStatus extends StatelessWidget {
  final double? distanceRemaining;
  final double? durationRemaining;
  final String? currentInstruction;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: _buildAccessibleLabel(),
      liveRegion: true,
      child: Column(
        children: [
          if (currentInstruction != null)
            Text(currentInstruction!)
              .withSemanticLabel(NavigationSemantics.nextTurn(currentInstruction!)),
          if (distanceRemaining != null)
            Text('${(distanceRemaining! / 1000).toStringAsFixed(1)} km')
              .withSemanticLabel(
                NavigationSemantics.distanceRemaining(
                  '${(distanceRemaining! / 1000).toStringAsFixed(1)} kilometers',
                ),
              ),
        ],
      ),
    );
  }

  String _buildAccessibleLabel() {
    final parts = <String>[];
    if (currentInstruction != null) {
      parts.add(NavigationSemantics.nextTurn(currentInstruction!));
    }
    if (distanceRemaining != null) {
      parts.add(NavigationSemantics.distanceRemaining(
        '${(distanceRemaining! / 1000).toStringAsFixed(1)} kilometers',
      ));
    }
    return parts.join('. ');
  }
}
```

## Test Cases

### Unit Tests

```dart
// test/unit/accessibility_utils_test.dart

void main() {
  group('Touch Target Constants', () {
    test('kMinTouchTargetSize should be 48.0', () {
      expect(kMinTouchTargetSize, equals(48.0));
    });

    test('kRecommendedTouchTargetSize should be 56.0', () {
      expect(kRecommendedTouchTargetSize, equals(56.0));
    });
  });

  group('NavigationSemantics', () {
    test('markerTitle should format correctly', () {
      expect(
        NavigationSemantics.markerTitle('Gas Station'),
        equals('Marker: Gas Station'),
      );
    });

    test('distanceRemaining should format correctly', () {
      expect(
        NavigationSemantics.distanceRemaining('5 km'),
        equals('Distance remaining: 5 km'),
      );
    });
  });
}
```

### Widget Tests

```dart
// test/widget/accessibility_widgets_test.dart

void main() {
  testWidgets('AccessibleTouchTarget should have minimum size', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AccessibleTouchTarget(
            child: Icon(Icons.close),
          ),
        ),
      ),
    );

    final size = tester.getSize(find.byType(AccessibleTouchTarget));
    expect(size.width, greaterThanOrEqualTo(kMinTouchTargetSize));
    expect(size.height, greaterThanOrEqualTo(kMinTouchTargetSize));
  });

  testWidgets('AccessibleIconButton should have semantics', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AccessibleIconButton(
            icon: Icons.close,
            semanticLabel: 'Close button',
            semanticHint: 'Closes the panel',
          ),
        ),
      ),
    );

    expect(
      find.bySemanticsLabel('Close button'),
      findsOneWidget,
    );
  });

  testWidgets('LiveRegion should mark as live region', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LiveRegion(
            announcement: 'Route updated',
            child: Text('Content'),
          ),
        ),
      ),
    );

    final semantics = tester.getSemantics(find.byType(LiveRegion));
    expect(semantics.hasFlag(SemanticsFlag.isLiveRegion), isTrue);
  });
}
```

### Integration Tests

```dart
// test/integration/accessibility_test.dart

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('navigation UI is accessible', (tester) async {
    // Start navigation
    // Verify semantic labels are present
    // Verify touch targets are large enough
    // Verify screen reader can navigate UI
  });
}
```

## Acceptance Criteria

- [ ] All interactive elements have semantic labels
- [ ] All buttons have minimum 48x48 dp touch targets
- [ ] Screen readers can navigate the UI
- [ ] Live regions announce dynamic content changes
- [ ] Marker popups are fully accessible
- [ ] Navigation instructions are announced
- [ ] Route progress is announced
- [ ] Arrival is announced
- [ ] AccessibleTouchTarget enforces minimum size
- [ ] AccessibleIconButton includes proper semantics
- [ ] Widget extensions work correctly
- [ ] Works with iOS VoiceOver
- [ ] Works with Android TalkBack
