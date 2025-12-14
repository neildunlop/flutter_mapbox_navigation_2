import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_mapbox_navigation_example/main.dart' as app;

/// Integration Tests for Flutter Mapbox Navigation
///
/// These tests verify UI elements and screen navigation.
/// Route building is tested separately as it requires API calls.
///
/// Run with: flutter test integration_test/app_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Flutter Mapbox Navigation Integration Tests', () {
    testWidgets('App loads and all screens are accessible', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // =====================================================================
      // TEST 1: Home Screen
      // =====================================================================
      print('--- Test 1: Home Screen ---');
      expect(find.text('Mapbox Navigation'), findsOneWidget);
      expect(find.text('Basic Navigation'), findsOneWidget);
      expect(find.text('Free Drive'), findsOneWidget);
      expect(find.text('Embedded Map'), findsOneWidget);
      print('✅ Home screen displays all navigation options');

      // =====================================================================
      // TEST 2: Embedded Map Screen UI
      // =====================================================================
      print('--- Test 2: Embedded Map Screen ---');
      await _scrollToAndTap(tester, 'Embedded Map');
      await tester.pump(const Duration(seconds: 3));

      // Verify core UI elements exist
      expect(find.text('Build Route'), findsOneWidget,
          reason: 'Build Route button should be visible');
      print('✅ Build Route button found');

      expect(find.byType(DropdownButtonFormField<String>), findsOneWidget,
          reason: 'Route selector dropdown should exist');
      print('✅ Route selector dropdown found');

      expect(find.text('Sim'), findsOneWidget,
          reason: 'Simulate toggle label should exist');
      expect(find.byType(Switch), findsOneWidget,
          reason: 'Simulate switch should exist');
      print('✅ Simulate toggle found');

      // Navigate back
      await _goBack(tester);
      await tester.pumpAndSettle();
      expect(find.text('Mapbox Navigation'), findsOneWidget);
      print('✅ Navigated back from Embedded Map');

      // =====================================================================
      // TEST 3: Static Markers Screen
      // =====================================================================
      print('--- Test 3: Static Markers Screen ---');
      await _scrollToAndTap(tester, 'Static Markers');
      await tester.pump(const Duration(seconds: 3));

      expect(find.text('Static Markers'), findsOneWidget);
      print('✅ Static Markers screen loaded');

      // Navigate back
      await _goBack(tester);
      await tester.pumpAndSettle();
      expect(find.text('Mapbox Navigation'), findsOneWidget);
      print('✅ Navigated back from Static Markers');

      // =====================================================================
      // TEST 4: Free Drive Screen
      // =====================================================================
      print('--- Test 4: Free Drive Screen ---');
      await _scrollToAndTap(tester, 'Free Drive');
      await tester.pump(const Duration(seconds: 2));

      expect(find.byType(AppBar), findsOneWidget);
      print('✅ Free Drive screen loaded');

      // Navigate back
      await _goBack(tester);
      await tester.pumpAndSettle();
      expect(find.text('Mapbox Navigation'), findsOneWidget);
      print('✅ Navigated back from Free Drive');

      // =====================================================================
      // TEST 5: Multi-Stop Navigation Screen
      // =====================================================================
      print('--- Test 5: Multi-Stop Navigation Screen ---');
      await _scrollToAndTap(tester, 'Multi-Stop Navigation');
      await tester.pump(const Duration(seconds: 2));

      expect(find.byType(AppBar), findsOneWidget);
      print('✅ Multi-Stop Navigation screen loaded');

      // Navigate back
      await _goBack(tester);
      await tester.pumpAndSettle();
      expect(find.text('Mapbox Navigation'), findsOneWidget);
      print('✅ Navigated back from Multi-Stop Navigation');

      // =====================================================================
      // SUMMARY
      // =====================================================================
      print('');
      print('========================================');
      print('✅ ALL UI TESTS PASSED');
      print('========================================');
    });
  });
}

// =============================================================================
// HELPER FUNCTIONS
// =============================================================================

Future<void> _scrollToAndTap(WidgetTester tester, String text) async {
  final finder = find.text(text);

  // Check if the widget is already visible
  if (finder.evaluate().isEmpty) {
    // Try to scroll to make it visible
    final scrollables = find.byType(Scrollable);
    if (scrollables.evaluate().isNotEmpty) {
      await tester.scrollUntilVisible(
        finder,
        100,
        scrollable: scrollables.first,
      );
    }
  }

  await tester.tap(finder);
}

Future<void> _goBack(WidgetTester tester) async {
  final backButton = find.byType(BackButton);
  if (backButton.evaluate().isNotEmpty) {
    await tester.tap(backButton);
    return;
  }

  final iconBack = find.byIcon(Icons.arrow_back);
  if (iconBack.evaluate().isNotEmpty) {
    await tester.tap(iconBack);
  }
}
