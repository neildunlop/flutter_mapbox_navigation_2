import 'dart:io';

/// Configuration constants for integration tests.
///
/// These values are tuned for reliable test execution across
/// different devices and network conditions.
class TestConfiguration {
  /// Maximum time to wait for app to be ready after launch.
  static const Duration appReadyTimeout = Duration(seconds: 5);

  /// Maximum time to wait for map view to load.
  static const Duration mapLoadTimeout = Duration(seconds: 10);

  /// Maximum time to wait for route to be built.
  static const Duration routeBuildTimeout = Duration(seconds: 15);

  /// Maximum time to wait for a short simulated navigation.
  static const Duration shortNavigationTimeout = Duration(seconds: 30);

  /// Maximum time to wait for a multi-stop navigation.
  static const Duration longNavigationTimeout = Duration(minutes: 2);

  /// Delay between navigation progress checks.
  static const Duration progressCheckInterval = Duration(milliseconds: 500);

  /// Delay after UI actions to allow state to settle.
  static const Duration uiSettleDelay = Duration(milliseconds: 300);

  /// Whether running on iOS platform.
  static bool get isIOS => Platform.isIOS;

  /// Whether running on Android platform.
  static bool get isAndroid => Platform.isAndroid;

  /// Whether to capture screenshots on test failure.
  static const bool captureScreenshotsOnFailure = true;

  /// Directory for storing test artifacts.
  static const String artifactDirectory = 'test_artifacts';

  /// Whether to run in verbose mode with extra logging.
  static const bool verboseLogging = true;

  /// Log a test message if verbose logging is enabled.
  static void log(String message) {
    if (verboseLogging) {
      // ignore: avoid_print
      print('[IntegrationTest] $message');
    }
  }
}
