import 'package:flutter/material.dart';
import 'widgets/navigation_overlay.dart';

/// Main Flutter app for navigation overlays
/// This is registered with the Flutter engine in NavigationActivity
class NavigationOverlayApp extends StatelessWidget {
  const NavigationOverlayApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Navigation Overlay',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        // Use system brightness for proper theming
      ),
      home: const NavigationOverlay(),
    );
  }
}

/// Entry point for Flutter overlay engine
void main() {
  runApp(const NavigationOverlayApp());
}

/// Named entry point for cleaner initialization
@pragma('vm:entry-point')
void navigationOverlayMain() {
  runApp(const NavigationOverlayApp());
}