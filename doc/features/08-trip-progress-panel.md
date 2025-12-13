# Feature Spec: Trip Progress Panel

## Overview

The Trip Progress Panel provides a customizable UI overlay showing navigation progress, waypoint information, and controls for multi-stop navigation. It supports skip/previous buttons, progress indicators, and full theming.

**Priority:** P2 - Nice to Have
**Effort:** Medium
**Dependencies:** Multi-Stop Navigation (03)

## User Stories

1. **As a user**, I can see my progress through multiple waypoints.
2. **As a user**, I can skip to the next waypoint if I change my mind.
3. **As a user**, I can go back to a previous waypoint.
4. **As a user**, I can see distance and time to the next waypoint.
5. **As a user**, I can see my estimated time of arrival.
6. **As a developer**, I can customize the appearance of the progress panel.

## Technical Approach

The Trip Progress Panel is a native UI component with configuration passed from Flutter:
- Configuration is serialized and sent via method channel
- Native platforms render the panel with provided settings
- Theme customization affects colors, dimensions, and layout

## API Reference

### TripProgressConfig

```dart
class TripProgressConfig {
  final bool showSkipButtons;
  final bool showProgressBar;
  final bool showEta;
  final bool showTotalDistance;
  final bool showEndNavigationButton;
  final bool showWaypointCount;
  final bool showDistanceToNext;
  final bool showDurationToNext;
  final bool enableAudioFeedback;
  final TripProgressTheme? theme;
}
```

### Factory Methods

```dart
// Default configuration (all features enabled)
final defaultConfig = TripProgressConfig.defaults();

// Minimal configuration (essential features only)
final minimalConfig = TripProgressConfig.minimal();
```

### Builder Pattern

```dart
final config = TripProgressConfigBuilder()
  .withSkipButtons()           // Enable skip prev/next buttons
  .withProgressBar()           // Show progress bar
  .withEta()                   // Show estimated arrival time
  .withWaypointCount()         // Show "Waypoint 3/8"
  .withDistanceToNext()        // Show distance to next waypoint
  .withDurationToNext()        // Show time to next waypoint
  .withDarkTheme()             // Apply dark theme
  .build();
```

### TripProgressTheme

```dart
class TripProgressTheme {
  final Color primaryColor;
  final Color accentColor;
  final Color backgroundColor;
  final Color textColor;
  final Color secondaryTextColor;
  final Color progressBarColor;
  final Color progressBarBackgroundColor;
  final Color endButtonColor;
  final Color endButtonTextColor;
  final double cornerRadius;
  final Map<String, Color> categoryColors;
}
```

### Theme Factories

```dart
// Light theme
final lightTheme = TripProgressTheme.light();

// Dark theme
final darkTheme = TripProgressTheme.dark();
```

### Theme Builder

```dart
final customTheme = TripProgressThemeBuilder()
  .fromLight()                                    // Start with light theme
  .primaryColor(Colors.indigo)                    // Custom primary color
  .accentColor(Colors.amber)                      // Checkpoint accent color
  .backgroundColor(Color(0xFFFAFAFA))             // Panel background
  .textColor(Colors.black87)                      // Primary text color
  .secondaryTextColor(Colors.black54)             // Secondary text color
  .endButtonColor(Colors.red)                     // End navigation button
  .cornerRadius(20.0)                             // Rounded corners
  .addCategoryColor('checkpoint', Colors.orange)  // Custom category color
  .addCategoryColor('scenic', Colors.green)
  .addCategoryColor('restaurant', Colors.deepOrange)
  .build();
```

### Using Trip Progress Config

```dart
await MapBoxNavigation.instance.startNavigation(
  wayPoints: waypoints,
  options: MapBoxOptions(
    tripProgressConfig: TripProgressConfigBuilder()
      .withSkipButtons()
      .withProgressBar()
      .withEta()
      .withWaypointCount()
      .withTheme(customTheme)
      .build(),
    simulateRoute: true,
  ),
);
```

## Default Category Colors

| Category | Color | Usage |
|----------|-------|-------|
| checkpoint | Orange | Important stops |
| waypoint | Blue | Regular waypoints |
| poi | Green | Points of interest |
| scenic | Light Green | Scenic viewpoints |
| restaurant, food | Deep Orange | Dining locations |
| hotel, accommodation | Purple | Lodging |
| petrol_station, fuel | Blue Grey | Fuel stops |
| hospital, medical | Red | Medical facilities |
| charging_station | Cyan | EV charging |

## Panel Components

### Progress Bar
Visual indicator showing percentage of trip completed.

### Waypoint Count
Displays current waypoint position, e.g., "Waypoint 3 of 8"

### Distance/Duration to Next
Shows remaining distance and time to next waypoint.

### ETA
Estimated time of arrival at final destination.

### Skip Buttons
- **Skip Next**: Jump to next waypoint without visiting current
- **Skip Previous**: Return to previous waypoint (if applicable)

### End Navigation Button
Button to cancel and exit navigation.

## Test Cases

### Unit Tests

```dart
// test/unit/trip_progress_config_test.dart

void main() {
  group('TripProgressConfig', () {
    test('should create default config with all features', () {
      final config = TripProgressConfig.defaults();

      expect(config.showSkipButtons, isTrue);
      expect(config.showProgressBar, isTrue);
      expect(config.showEta, isTrue);
      expect(config.showWaypointCount, isTrue);
    });

    test('should create minimal config', () {
      final config = TripProgressConfig.minimal();

      expect(config.showSkipButtons, isFalse);
      expect(config.showProgressBar, isTrue);
      expect(config.showEta, isFalse);
    });

    test('builder should chain correctly', () {
      final config = TripProgressConfigBuilder()
        .withSkipButtons()
        .withProgressBar()
        .withEta()
        .build();

      expect(config.showSkipButtons, isTrue);
      expect(config.showProgressBar, isTrue);
      expect(config.showEta, isTrue);
    });
  });

  group('TripProgressTheme', () {
    test('should create light theme', () {
      final theme = TripProgressTheme.light();

      expect(theme.backgroundColor, isNotNull);
      expect(theme.textColor, isNotNull);
    });

    test('should create dark theme', () {
      final theme = TripProgressTheme.dark();

      expect(theme.backgroundColor, isNotNull);
      expect(theme.textColor, isNotNull);
    });

    test('builder should customize theme', () {
      final theme = TripProgressThemeBuilder()
        .fromLight()
        .primaryColor(Colors.indigo)
        .cornerRadius(20.0)
        .build();

      expect(theme.primaryColor, equals(Colors.indigo));
      expect(theme.cornerRadius, equals(20.0));
    });

    test('should add category colors', () {
      final theme = TripProgressThemeBuilder()
        .fromLight()
        .addCategoryColor('custom', Colors.purple)
        .build();

      expect(theme.categoryColors['custom'], equals(Colors.purple));
    });
  });
}
```

### Integration Tests

```dart
// test/integration/trip_progress_panel_test.dart

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('should display trip progress panel', (tester) async {
    final waypoints = [
      WayPoint(name: 'A', latitude: 37.7749, longitude: -122.4194),
      WayPoint(name: 'B', latitude: 37.7849, longitude: -122.4094),
      WayPoint(name: 'C', latitude: 37.7949, longitude: -122.3994),
    ];

    await MapBoxNavigation.instance.startNavigation(
      wayPoints: waypoints,
      options: MapBoxOptions(
        tripProgressConfig: TripProgressConfig.defaults(),
        simulateRoute: true,
      ),
    );

    // Verify panel is displayed
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // Panel verification would require platform-specific testing
  });

  testWidgets('should serialize config correctly', (tester) async {
    final config = TripProgressConfigBuilder()
      .withSkipButtons()
      .withProgressBar()
      .withTheme(TripProgressTheme.dark())
      .build();

    final json = config.toJson();

    expect(json['showSkipButtons'], isTrue);
    expect(json['showProgressBar'], isTrue);
    expect(json['theme'], isNotNull);
  });
}
```

### E2E Tests

```dart
// test/e2e/trip_progress_panel_test.dart

void main() {
  group('Trip Progress Panel E2E', () {
    testWidgets('skip to next waypoint', (tester) async {
      // 1. Start multi-stop navigation
      // 2. Tap skip next button
      // 3. Verify current waypoint skipped
      // 4. Verify navigation continues to next
    });

    testWidgets('go back to previous waypoint', (tester) async {
      // 1. Start multi-stop navigation
      // 2. Progress past first waypoint
      // 3. Tap skip previous button
      // 4. Verify route recalculated back
    });

    testWidgets('progress bar updates', (tester) async {
      // 1. Start navigation
      // 2. Simulate movement
      // 3. Verify progress bar increases
    });

    testWidgets('waypoint count updates', (tester) async {
      // 1. Start with 5 waypoints
      // 2. Verify shows "1 of 5"
      // 3. Complete first waypoint
      // 4. Verify shows "2 of 5"
    });

    testWidgets('theme applies correctly', (tester) async {
      // 1. Start with custom theme
      // 2. Verify colors match configuration
    });
  });
}
```

## Acceptance Criteria

- [ ] Panel displays during multi-stop navigation
- [ ] Progress bar shows trip completion percentage
- [ ] Waypoint count shows current/total
- [ ] Distance to next waypoint is displayed
- [ ] Duration to next waypoint is displayed
- [ ] ETA is calculated and displayed
- [ ] Skip next button advances to next waypoint
- [ ] Skip previous button returns to previous waypoint
- [ ] End navigation button finishes navigation
- [ ] Light theme applies correctly
- [ ] Dark theme applies correctly
- [ ] Custom theme colors apply correctly
- [ ] Category colors affect waypoint icons
- [ ] Config builder produces correct configuration
- [ ] Works on both iOS and Android
