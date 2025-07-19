import 'package:flutter_mapbox_navigation/flutter_mapbox_navigation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_mapbox_navigation/src/models/options.dart';
import 'package:flutter_mapbox_navigation/src/models/voice_units.dart';

void main() {
  group('Route Options Tests', () {
    late MapBoxOptions options;

    setUp(() {
      options = MapBoxOptions(
        initialLatitude: 51.5074,
        initialLongitude: -0.1278,
        zoom: 13.0,
        tilt: 0.0,
        bearing: 0.0,
        enableRefresh: true,
        alternatives: true,
        voiceInstructionsEnabled: true,
        bannerInstructionsEnabled: true,
        allowsUTurnAtWayPoints: true,
        mode: MapBoxNavigationMode.drivingWithTraffic,
        units: VoiceUnits.metric,
        simulateRoute: true,
        language: "en",
      );
    });

    test('should handle different navigation modes', () {
      // Test driving mode
      options.mode = MapBoxNavigationMode.driving;
      expect(options.mode, equals(MapBoxNavigationMode.driving));
      expect(options.toMap()['mode'], equals('driving'));

      // Test walking mode
      options.mode = MapBoxNavigationMode.walking;
      expect(options.mode, equals(MapBoxNavigationMode.walking));
      expect(options.toMap()['mode'], equals('walking'));

      // Test cycling mode
      options.mode = MapBoxNavigationMode.cycling;
      expect(options.mode, equals(MapBoxNavigationMode.cycling));
      expect(options.toMap()['mode'], equals('cycling'));

      // Test driving with traffic mode
      options.mode = MapBoxNavigationMode.drivingWithTraffic;
      expect(options.mode, equals(MapBoxNavigationMode.drivingWithTraffic));
      expect(options.toMap()['mode'], equals('drivingWithTraffic'));

      // Test mode switching behavior
      final newOptions = MapBoxOptions.from(options);
      expect(newOptions.mode, equals(options.mode));
      
      // Test mode-specific route options
      options.mode = MapBoxNavigationMode.driving;
      expect(options.toMap()['mode'], equals('driving'));
      expect(options.toMap()['alternatives'], isTrue);
      expect(options.toMap()['allowsUTurnAtWayPoints'], isTrue);
    });

    test('should handle voice instruction settings', () {
      // Test voice enabled/disabled
      options.voiceInstructionsEnabled = false;
      expect(options.voiceInstructionsEnabled, isFalse);
      expect(options.toMap()['voiceInstructionsEnabled'], isFalse);

      options.voiceInstructionsEnabled = true;
      expect(options.voiceInstructionsEnabled, isTrue);
      expect(options.toMap()['voiceInstructionsEnabled'], isTrue);

      // Test voice language
      options.language = "fr";
      expect(options.language, equals("fr"));
      expect(options.toMap()['language'], equals("fr"));

      // Test different languages
      final supportedLanguages = ["en", "fr", "de", "es", "it", "pt", "ru", "zh"];
      for (final lang in supportedLanguages) {
        options.language = lang;
        expect(options.language, equals(lang));
        expect(options.toMap()['language'], equals(lang));
      }

      // Test voice instruction persistence
      final newOptions = MapBoxOptions.from(options);
      expect(newOptions.voiceInstructionsEnabled, equals(options.voiceInstructionsEnabled));
      expect(newOptions.language, equals(options.language));
    });

    test('should handle unit preferences', () {
      // Test metric units
      options.units = VoiceUnits.metric;
      expect(options.units, equals(VoiceUnits.metric));
      expect(options.toMap()['units'], equals('metric'));

      // Test imperial units
      options.units = VoiceUnits.imperial;
      expect(options.units, equals(VoiceUnits.imperial));
      expect(options.toMap()['units'], equals('imperial'));

      // Test unit persistence
      final newOptions = MapBoxOptions.from(options);
      expect(newOptions.units, equals(options.units));

      // Test unit switching
      options.units = VoiceUnits.metric;
      expect(options.units, equals(VoiceUnits.metric));
      expect(options.toMap()['units'], equals('metric'));
    });

    test('should handle map display options', () {
      // Test zoom level
      options.zoom = 15.0;
      expect(options.zoom, equals(15.0));
      expect(options.toMap()['zoom'], equals(15.0));

      // Test bearing
      options.bearing = 45.0;
      expect(options.bearing, equals(45.0));
      expect(options.toMap()['bearing'], equals(45.0));

      // Test tilt
      options.tilt = 30.0;
      expect(options.tilt, equals(30.0));
      expect(options.toMap()['tilt'], equals(30.0));

      // Test map style
      options.mapStyleUrlDay = "mapbox://styles/mapbox/streets-v11";
      expect(options.mapStyleUrlDay, equals("mapbox://styles/mapbox/streets-v11"));
      expect(options.toMap()['mapStyleUrlDay'], equals("mapbox://styles/mapbox/streets-v11"));

      options.mapStyleUrlNight = "mapbox://styles/mapbox/dark-v10";
      expect(options.mapStyleUrlNight, equals("mapbox://styles/mapbox/dark-v10"));
      expect(options.toMap()['mapStyleUrlNight'], equals("mapbox://styles/mapbox/dark-v10"));

      // Test refresh settings
      options.enableRefresh = false;
      expect(options.enableRefresh, isFalse);
      expect(options.toMap()['enableRefresh'], isFalse);

      // Test map interaction
      options.enableOnMapTapCallback = true;
      expect(options.enableOnMapTapCallback, isTrue);
      expect(options.toMap()['enableOnMapTapCallback'], isTrue);

      // Test display options persistence
      final newOptions = MapBoxOptions.from(options);
      expect(newOptions.zoom, equals(options.zoom));
      expect(newOptions.bearing, equals(options.bearing));
      expect(newOptions.tilt, equals(options.tilt));
      expect(newOptions.mapStyleUrlDay, equals(options.mapStyleUrlDay));
      expect(newOptions.mapStyleUrlNight, equals(options.mapStyleUrlNight));
      expect(newOptions.enableRefresh, equals(options.enableRefresh));
      expect(newOptions.enableOnMapTapCallback, equals(options.enableOnMapTapCallback));
    });
  });
} 