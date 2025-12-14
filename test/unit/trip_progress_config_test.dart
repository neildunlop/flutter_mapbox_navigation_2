import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_mapbox_navigation/src/models/trip_progress_config.dart';

void main() {
  group('TripProgressConfig', () {
    group('Constructor', () {
      test('should create with default values', () {
        const config = TripProgressConfig();

        expect(config.showSkipButtons, isTrue);
        expect(config.showProgressBar, isTrue);
        expect(config.showEta, isTrue);
        expect(config.showTotalDistance, isTrue);
        expect(config.showEndNavigationButton, isTrue);
        expect(config.showWaypointCount, isTrue);
        expect(config.showDistanceToNext, isTrue);
        expect(config.showDurationToNext, isTrue);
        expect(config.showCurrentSpeed, isFalse);
        expect(config.enableAudioFeedback, isTrue);
        expect(config.panelHeight, isNull);
        expect(config.theme, isNull);
      });

      test('should create with custom values', () {
        const config = TripProgressConfig(
          showSkipButtons: false,
          showProgressBar: false,
          showEta: false,
          showCurrentSpeed: true,
          panelHeight: 100.0,
        );

        expect(config.showSkipButtons, isFalse);
        expect(config.showProgressBar, isFalse);
        expect(config.showEta, isFalse);
        expect(config.showCurrentSpeed, isTrue);
        expect(config.panelHeight, 100.0);
      });
    });

    group('Factory constructors', () {
      test('defaults() should return config with all features enabled', () {
        final config = TripProgressConfig.defaults();

        expect(config.showSkipButtons, isTrue);
        expect(config.showProgressBar, isTrue);
        expect(config.showEta, isTrue);
        expect(config.showTotalDistance, isTrue);
      });

      test('minimal() should return config with minimal features', () {
        final config = TripProgressConfig.minimal();

        expect(config.showSkipButtons, isFalse);
        expect(config.showProgressBar, isFalse);
        expect(config.showEta, isFalse);
        expect(config.showTotalDistance, isFalse);
        expect(config.showWaypointCount, isFalse);
        expect(config.enableAudioFeedback, isFalse);
      });
    });

    group('toMap', () {
      test('should convert to map with all fields', () {
        const config = TripProgressConfig(
          showSkipButtons: true,
          showProgressBar: true,
          showEta: true,
          showTotalDistance: true,
          showEndNavigationButton: true,
          showWaypointCount: true,
          showDistanceToNext: true,
          showDurationToNext: true,
          showCurrentSpeed: true,
          enableAudioFeedback: true,
        );

        final map = config.toMap();

        expect(map['showSkipButtons'], isTrue);
        expect(map['showProgressBar'], isTrue);
        expect(map['showEta'], isTrue);
        expect(map['showTotalDistance'], isTrue);
        expect(map['showEndNavigationButton'], isTrue);
        expect(map['showWaypointCount'], isTrue);
        expect(map['showDistanceToNext'], isTrue);
        expect(map['showDurationToNext'], isTrue);
        expect(map['showCurrentSpeed'], isTrue);
        expect(map['enableAudioFeedback'], isTrue);
      });

      test('should include panelHeight when set', () {
        const config = TripProgressConfig(panelHeight: 150.0);

        final map = config.toMap();

        expect(map['panelHeight'], 150.0);
      });

      test('should not include panelHeight when null', () {
        const config = TripProgressConfig();

        final map = config.toMap();

        expect(map.containsKey('panelHeight'), isFalse);
      });

      test('should include theme when set', () {
        final config = TripProgressConfig(theme: TripProgressTheme.light());

        final map = config.toMap();

        expect(map.containsKey('theme'), isTrue);
        expect(map['theme'], isA<Map>());
      });
    });

    group('copyWith', () {
      test('should copy with updated fields', () {
        const original = TripProgressConfig(
          showSkipButtons: true,
          showProgressBar: true,
        );

        final copy = original.copyWith(
          showSkipButtons: false,
          showCurrentSpeed: true,
        );

        expect(copy.showSkipButtons, isFalse);
        expect(copy.showProgressBar, isTrue);
        expect(copy.showCurrentSpeed, isTrue);
      });

      test('should preserve unchanged fields', () {
        const original = TripProgressConfig(
          panelHeight: 200.0,
        );

        final copy = original.copyWith(showEta: false);

        expect(copy.panelHeight, 200.0);
        expect(copy.showEta, isFalse);
      });
    });
  });

  group('TripProgressTheme', () {
    group('Constructor', () {
      test('should create with null values', () {
        const theme = TripProgressTheme();

        expect(theme.primaryColor, isNull);
        expect(theme.accentColor, isNull);
        expect(theme.backgroundColor, isNull);
      });

      test('should create with custom values', () {
        const theme = TripProgressTheme(
          primaryColor: Colors.blue,
          accentColor: Colors.red,
          cornerRadius: 20.0,
        );

        expect(theme.primaryColor, Colors.blue);
        expect(theme.accentColor, Colors.red);
        expect(theme.cornerRadius, 20.0);
      });
    });

    group('Factory constructors', () {
      test('light() should create light theme', () {
        final theme = TripProgressTheme.light();

        expect(theme.backgroundColor, const Color(0xFFFFFFFF));
        expect(theme.textPrimaryColor, const Color(0xFF1A1A1A));
        expect(theme.cornerRadius, 16.0);
        expect(theme.buttonSize, 36.0);
        expect(theme.iconSize, 32.0);
      });

      test('dark() should create dark theme', () {
        final theme = TripProgressTheme.dark();

        expect(theme.backgroundColor, const Color(0xFF1E1E1E));
        expect(theme.textPrimaryColor, const Color(0xFFFFFFFF));
        expect(theme.cornerRadius, 16.0);
        expect(theme.buttonSize, 36.0);
        expect(theme.iconSize, 32.0);
      });
    });

    group('getCategoryColor', () {
      test('should return custom category color when defined', () {
        final theme = TripProgressTheme(
          categoryColors: {'checkpoint': Colors.purple},
        );

        final color = theme.getCategoryColor('checkpoint');

        expect(color, Colors.purple);
      });

      test('should return default category color when not customized', () {
        const theme = TripProgressTheme();

        final color = theme.getCategoryColor('checkpoint');

        expect(color, const Color(0xFF1565C0));
      });

      test('should be case insensitive', () {
        final theme = TripProgressTheme(
          categoryColors: {'checkpoint': Colors.purple},
        );

        final color = theme.getCategoryColor('CHECKPOINT');

        expect(color, Colors.purple);
      });

      test('should return primaryColor for unknown category', () {
        const theme = TripProgressTheme(primaryColor: Colors.orange);

        final color = theme.getCategoryColor('unknown_category');

        expect(color, Colors.orange);
      });

      test('should return default blue for unknown category without primaryColor', () {
        const theme = TripProgressTheme();

        final color = theme.getCategoryColor('unknown_category');

        expect(color, const Color(0xFF2196F3));
      });
    });

    group('defaultCategoryColors', () {
      test('should contain expected categories', () {
        expect(TripProgressTheme.defaultCategoryColors.containsKey('checkpoint'), isTrue);
        expect(TripProgressTheme.defaultCategoryColors.containsKey('waypoint'), isTrue);
        expect(TripProgressTheme.defaultCategoryColors.containsKey('poi'), isTrue);
        expect(TripProgressTheme.defaultCategoryColors.containsKey('scenic'), isTrue);
        expect(TripProgressTheme.defaultCategoryColors.containsKey('restaurant'), isTrue);
        expect(TripProgressTheme.defaultCategoryColors.containsKey('petrol_station'), isTrue);
      });
    });

    group('toMap', () {
      test('should convert all fields to map', () {
        const theme = TripProgressTheme(
          primaryColor: Color(0xFF123456),
          accentColor: Color(0xFF654321),
          cornerRadius: 12.0,
          buttonSize: 40.0,
          iconSize: 28.0,
        );

        final map = theme.toMap();

        expect(map['primaryColor'], 0xFF123456);
        expect(map['accentColor'], 0xFF654321);
        expect(map['cornerRadius'], 12.0);
        expect(map['buttonSize'], 40.0);
        expect(map['iconSize'], 28.0);
      });

      test('should not include null fields', () {
        const theme = TripProgressTheme(primaryColor: Color(0xFF123456));

        final map = theme.toMap();

        expect(map.containsKey('primaryColor'), isTrue);
        expect(map.containsKey('accentColor'), isFalse);
        expect(map.containsKey('backgroundColor'), isFalse);
      });

      test('should include categoryColors when set', () {
        final theme = TripProgressTheme(
          categoryColors: {
            'checkpoint': const Color(0xFFFF0000),
            'waypoint': const Color(0xFF00FF00),
          },
        );

        final map = theme.toMap();

        expect(map.containsKey('categoryColors'), isTrue);
        final categoryMap = map['categoryColors'] as Map<String, int>;
        expect(categoryMap['checkpoint'], 0xFFFF0000);
        expect(categoryMap['waypoint'], 0xFF00FF00);
      });
    });

    group('copyWith', () {
      test('should copy with updated fields', () {
        final original = TripProgressTheme.light();

        final copy = original.copyWith(
          primaryColor: Colors.purple,
          cornerRadius: 24.0,
        );

        expect(copy.primaryColor, Colors.purple);
        expect(copy.cornerRadius, 24.0);
        expect(copy.backgroundColor, original.backgroundColor);
      });

      test('should preserve unchanged fields', () {
        final original = TripProgressTheme.dark();

        final copy = original.copyWith(buttonSize: 50.0);

        expect(copy.buttonSize, 50.0);
        expect(copy.backgroundColor, original.backgroundColor);
        expect(copy.textPrimaryColor, original.textPrimaryColor);
      });
    });
  });

  group('TripProgressConfigBuilder', () {
    test('should build with all defaults', () {
      final config = TripProgressConfigBuilder().build();

      expect(config.showSkipButtons, isTrue);
      expect(config.showProgressBar, isTrue);
      expect(config.showEta, isTrue);
      expect(config.enableAudioFeedback, isTrue);
    });

    test('minimal() should start with minimal config', () {
      final config = TripProgressConfigBuilder.minimal().build();

      expect(config.showSkipButtons, isFalse);
      expect(config.showProgressBar, isFalse);
      expect(config.showEta, isFalse);
      expect(config.enableAudioFeedback, isFalse);
    });

    test('should chain methods fluently', () {
      final config = TripProgressConfigBuilder()
          .hideSkipButtons()
          .hideProgressBar()
          .withCurrentSpeed()
          .withPanelHeight(120.0)
          .disableAudioFeedback()
          .build();

      expect(config.showSkipButtons, isFalse);
      expect(config.showProgressBar, isFalse);
      expect(config.showCurrentSpeed, isTrue);
      expect(config.panelHeight, 120.0);
      expect(config.enableAudioFeedback, isFalse);
    });

    test('should toggle methods correctly', () {
      final config = TripProgressConfigBuilder()
          .hideSkipButtons()
          .withSkipButtons()
          .hideEta()
          .withEta()
          .build();

      expect(config.showSkipButtons, isTrue);
      expect(config.showEta, isTrue);
    });

    test('withLightTheme should apply light theme', () {
      final config = TripProgressConfigBuilder()
          .withLightTheme()
          .build();

      expect(config.theme, isNotNull);
      expect(config.theme!.backgroundColor, const Color(0xFFFFFFFF));
    });

    test('withDarkTheme should apply dark theme', () {
      final config = TripProgressConfigBuilder()
          .withDarkTheme()
          .build();

      expect(config.theme, isNotNull);
      expect(config.theme!.backgroundColor, const Color(0xFF1E1E1E));
    });

    test('withTheme should apply custom theme', () {
      const customTheme = TripProgressTheme(primaryColor: Colors.green);

      final config = TripProgressConfigBuilder()
          .withTheme(customTheme)
          .build();

      expect(config.theme, isNotNull);
      expect(config.theme!.primaryColor, Colors.green);
    });

    test('all show/hide methods should work', () {
      final builder = TripProgressConfigBuilder()
          .hideSkipButtons()
          .hideProgressBar()
          .hideEta()
          .hideTotalDistance()
          .hideEndNavigationButton()
          .hideWaypointCount()
          .hideDistanceToNext()
          .hideDurationToNext()
          .hideCurrentSpeed();

      final config = builder.build();

      expect(config.showSkipButtons, isFalse);
      expect(config.showProgressBar, isFalse);
      expect(config.showEta, isFalse);
      expect(config.showTotalDistance, isFalse);
      expect(config.showEndNavigationButton, isFalse);
      expect(config.showWaypointCount, isFalse);
      expect(config.showDistanceToNext, isFalse);
      expect(config.showDurationToNext, isFalse);
      expect(config.showCurrentSpeed, isFalse);
    });

    test('all with methods should work', () {
      final builder = TripProgressConfigBuilder.minimal()
          .withSkipButtons()
          .withProgressBar()
          .withEta()
          .withTotalDistance()
          .withEndNavigationButton()
          .withWaypointCount()
          .withDistanceToNext()
          .withDurationToNext()
          .withCurrentSpeed()
          .enableAudioFeedback();

      final config = builder.build();

      expect(config.showSkipButtons, isTrue);
      expect(config.showProgressBar, isTrue);
      expect(config.showEta, isTrue);
      expect(config.showTotalDistance, isTrue);
      expect(config.showEndNavigationButton, isTrue);
      expect(config.showWaypointCount, isTrue);
      expect(config.showDistanceToNext, isTrue);
      expect(config.showDurationToNext, isTrue);
      expect(config.showCurrentSpeed, isTrue);
      expect(config.enableAudioFeedback, isTrue);
    });
  });

  group('TripProgressThemeBuilder', () {
    test('should build with null values by default', () {
      final theme = TripProgressThemeBuilder().build();

      expect(theme.primaryColor, isNull);
      expect(theme.accentColor, isNull);
    });

    test('fromLight() should initialize with light theme values', () {
      final theme = TripProgressThemeBuilder()
          .fromLight()
          .build();

      expect(theme.backgroundColor, const Color(0xFFFFFFFF));
      expect(theme.textPrimaryColor, const Color(0xFF1A1A1A));
    });

    test('fromDark() should initialize with dark theme values', () {
      final theme = TripProgressThemeBuilder()
          .fromDark()
          .build();

      expect(theme.backgroundColor, const Color(0xFF1E1E1E));
      expect(theme.textPrimaryColor, const Color(0xFFFFFFFF));
    });

    test('should chain color methods fluently', () {
      final theme = TripProgressThemeBuilder()
          .fromLight()
          .primaryColor(Colors.indigo)
          .accentColor(Colors.amber)
          .backgroundColor(Colors.grey)
          .textPrimaryColor(Colors.black)
          .textSecondaryColor(Colors.grey)
          .build();

      expect(theme.primaryColor, Colors.indigo);
      expect(theme.accentColor, Colors.amber);
      expect(theme.backgroundColor, Colors.grey);
      expect(theme.textPrimaryColor, Colors.black);
      expect(theme.textSecondaryColor, Colors.grey);
    });

    test('should set button and progress colors', () {
      final theme = TripProgressThemeBuilder()
          .buttonBackgroundColor(Colors.blue)
          .endButtonColor(Colors.red)
          .progressBarColor(Colors.green)
          .progressBarBackgroundColor(Colors.grey)
          .build();

      expect(theme.buttonBackgroundColor, Colors.blue);
      expect(theme.endButtonColor, Colors.red);
      expect(theme.progressBarColor, Colors.green);
      expect(theme.progressBarBackgroundColor, Colors.grey);
    });

    test('should set dimension properties', () {
      final theme = TripProgressThemeBuilder()
          .cornerRadius(20.0)
          .buttonSize(48.0)
          .iconSize(36.0)
          .build();

      expect(theme.cornerRadius, 20.0);
      expect(theme.buttonSize, 48.0);
      expect(theme.iconSize, 36.0);
    });

    test('addCategoryColor should add single category', () {
      final theme = TripProgressThemeBuilder()
          .addCategoryColor('custom', Colors.purple)
          .build();

      expect(theme.categoryColors, isNotNull);
      expect(theme.categoryColors!['custom'], Colors.purple);
    });

    test('addCategoryColor should be case insensitive', () {
      final theme = TripProgressThemeBuilder()
          .addCategoryColor('CUSTOM', Colors.purple)
          .build();

      expect(theme.categoryColors!['custom'], Colors.purple);
    });

    test('categoryColors should set all at once', () {
      final theme = TripProgressThemeBuilder()
          .categoryColors({
            'checkpoint': Colors.blue,
            'WAYPOINT': Colors.green,
          })
          .build();

      expect(theme.categoryColors!['checkpoint'], Colors.blue);
      expect(theme.categoryColors!['waypoint'], Colors.green);
    });

    test('addCategoryColor should accumulate colors', () {
      final theme = TripProgressThemeBuilder()
          .addCategoryColor('one', Colors.red)
          .addCategoryColor('two', Colors.blue)
          .addCategoryColor('three', Colors.green)
          .build();

      expect(theme.categoryColors!.length, 3);
      expect(theme.categoryColors!['one'], Colors.red);
      expect(theme.categoryColors!['two'], Colors.blue);
      expect(theme.categoryColors!['three'], Colors.green);
    });
  });
}
