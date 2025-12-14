/// Integration Test Driver
///
/// This file is required for running integration tests with flutter drive,
/// which enables CI/CD testing on real devices or emulators.
///
/// Usage:
/// ```bash
/// cd example
/// flutter drive \
///   --driver=test_driver/integration_test.dart \
///   --target=integration_test/all_tests.dart
/// ```
///
/// For specific test files:
/// ```bash
/// flutter drive \
///   --driver=test_driver/integration_test.dart \
///   --target=integration_test/critical/01_navigation_lifecycle_test.dart
/// ```
library;

import 'package:integration_test/integration_test_driver.dart';

Future<void> main() => integrationDriver();
