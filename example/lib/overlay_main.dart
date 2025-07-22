import 'package:flutter/material.dart';
import 'package:flutter_mapbox_navigation/src/widgets/navigation_overlay.dart';

/// Separate entry point for Flutter overlay
/// This runs as a completely separate Flutter app instance
void main() {
  print('🚀 overlay_main.dart started - SEPARATE OVERLAY INSTANCE');
  runApp(const NavigationOverlayApp());
}

class NavigationOverlayApp extends StatelessWidget {
  const NavigationOverlayApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    print('🎨 NavigationOverlayApp build called');
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