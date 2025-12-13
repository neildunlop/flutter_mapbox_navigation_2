/// Home Screen
///
/// Main entry point displaying all available feature demonstrations.
/// Features are organized by category (Core, Map/Markers, Advanced).

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_mapbox_navigation/flutter_mapbox_navigation.dart';
import '../core/constants.dart';
import '../shared/widgets/feature_tile.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _platformVersion = 'Unknown';

  @override
  void initState() {
    super.initState();
    _getPlatformVersion();
  }

  Future<void> _getPlatformVersion() async {
    final version = await MapBoxNavigation.instance.getPlatformVersion();
    if (mounted) {
      setState(() => _platformVersion = version ?? 'Unknown');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapbox Navigation'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showAboutDialog,
            tooltip: 'About',
          ),
        ],
      ),
      body: ListView(
        children: [
          // Platform info header
          _PlatformInfoBanner(platformVersion: _platformVersion),

          // Core Navigation Features
          const FeatureCategoryHeader(category: FeatureCategory.core),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: UIConstants.defaultPadding),
            child: Column(
              children: [
                FeatureTile(
                  title: 'Basic Navigation',
                  description:
                      'Simple A-to-B turn-by-turn navigation with voice instructions',
                  icon: Icons.navigation,
                  route: AppRoutes.basicNavigation,
                  category: FeatureCategory.core,
                ),
                const SizedBox(height: 8),
                FeatureTile(
                  title: 'Free Drive',
                  description:
                      'Passive navigation mode without a destination',
                  icon: Icons.explore,
                  route: AppRoutes.freeDrive,
                  category: FeatureCategory.core,
                ),
                const SizedBox(height: 8),
                FeatureTile(
                  title: 'Multi-Stop Navigation',
                  description:
                      'Navigate through multiple waypoints with silent waypoints',
                  icon: Icons.route,
                  route: AppRoutes.multiStop,
                  category: FeatureCategory.core,
                ),
                const SizedBox(height: 8),
                FeatureTile(
                  title: 'Embedded Map',
                  description:
                      'Navigation view embedded in your Flutter widget tree',
                  icon: Icons.map,
                  route: AppRoutes.embeddedMap,
                  category: FeatureCategory.core,
                ),
              ],
            ),
          ),

          // Map & Marker Features
          const FeatureCategoryHeader(category: FeatureCategory.mapFeatures),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: UIConstants.defaultPadding),
            child: Column(
              children: [
                FeatureTile(
                  title: 'Static Markers',
                  description:
                      'Add custom POI markers with categories and clustering',
                  icon: Icons.place,
                  route: AppRoutes.staticMarkers,
                  category: FeatureCategory.mapFeatures,
                ),
                const SizedBox(height: 8),
                FeatureTile(
                  title: 'Marker Popups',
                  description:
                      'Custom Flutter-based popup overlays for markers',
                  icon: Icons.chat_bubble,
                  route: AppRoutes.markerPopups,
                  category: FeatureCategory.mapFeatures,
                ),
              ],
            ),
          ),

          // Advanced Features
          const FeatureCategoryHeader(category: FeatureCategory.advanced),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: UIConstants.defaultPadding),
            child: Column(
              children: [
                FeatureTile(
                  title: 'Trip Progress Panel',
                  description:
                      'Customizable progress overlay with theming options',
                  icon: Icons.linear_scale,
                  route: AppRoutes.tripProgress,
                  category: FeatureCategory.advanced,
                ),
                const SizedBox(height: 8),
                FeatureTile(
                  title: 'Events Demo',
                  description:
                      'Real-time navigation event logging and handling',
                  icon: Icons.bolt,
                  route: AppRoutes.eventsDemo,
                  category: FeatureCategory.advanced,
                ),
                const SizedBox(height: 8),
                FeatureTile(
                  title: 'Offline Navigation',
                  description:
                      'Download map regions for offline routing',
                  icon: Icons.cloud_download,
                  route: AppRoutes.offline,
                  category: FeatureCategory.advanced,
                ),
                const SizedBox(height: 8),
                FeatureTile(
                  title: 'Waypoint Validation',
                  description:
                      'Pre-flight validation and error handling patterns',
                  icon: Icons.check_circle,
                  route: AppRoutes.validation,
                  category: FeatureCategory.advanced,
                ),
                const SizedBox(height: 8),
                FeatureTile(
                  title: 'Accessibility',
                  description:
                      'Screen reader support and accessible UI patterns',
                  icon: Icons.accessibility,
                  route: AppRoutes.accessibility,
                  category: FeatureCategory.advanced,
                ),
              ],
            ),
          ),

          const SizedBox(height: UIConstants.largePadding),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Flutter Mapbox Navigation',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'A comprehensive Flutter plugin for turn-by-turn navigation '
              'using the Mapbox SDK.',
            ),
            const SizedBox(height: 16),
            Text('Platform: ${Platform.operatingSystem}'),
            Text('OS Version: $_platformVersion'),
            const SizedBox(height: 16),
            const Text(
              'This example app demonstrates all major features of the '
              'plugin with easy-to-copy code examples.',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _PlatformInfoBanner extends StatelessWidget {
  final String platformVersion;

  const _PlatformInfoBanner({required this.platformVersion});

  @override
  Widget build(BuildContext context) {
    final isIOS = Platform.isIOS;
    final isAndroid = Platform.isAndroid;

    return Container(
      margin: const EdgeInsets.all(UIConstants.defaultPadding),
      padding: const EdgeInsets.all(UIConstants.defaultPadding),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue.shade700,
            Colors.blue.shade500,
          ],
        ),
        borderRadius: BorderRadius.circular(UIConstants.borderRadius),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isIOS
                  ? Icons.phone_iphone
                  : isAndroid
                      ? Icons.phone_android
                      : Icons.devices,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Mapbox Navigation Demo',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Running on: $platformVersion',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 13,
                  ),
                ),
                if (isIOS)
                  Text(
                    'Note: Voice units locked after first navigation',
                    style: TextStyle(
                      color: Colors.yellow.shade200,
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
