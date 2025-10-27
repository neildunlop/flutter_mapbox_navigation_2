import 'package:flutter/material.dart';
import 'src/widgets/navigation_overlay.dart';

/// Separate overlay entry point for NavigationActivity
void main() {
  print('🚀 PLUGIN overlay_main.dart started - SEPARATE OVERLAY INSTANCE');
  runApp(const NavigationOverlayApp());
}

/// Named entry point for Dart execution from Android
@pragma('vm:entry-point')
void overlayMain() {
  print('🚀 overlayMain() called - NAMED ENTRY POINT');
  runApp(const NavigationOverlayApp());
}

class NavigationOverlayApp extends StatelessWidget {
  const NavigationOverlayApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    print('🎨 NavigationOverlayApp build() called');
    return MaterialApp(
      title: 'Navigation Overlay',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const Material(
        color: Colors.transparent,
        child: NavigationOverlay(),
      ),
    );
  }
}