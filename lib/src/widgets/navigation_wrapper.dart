import 'package:flutter/material.dart';
import 'package:flutter_mapbox_navigation/src/models/models.dart';
import 'fullscreen_overlay.dart';

/// A wrapper widget that enhances any navigation component with Flutter-based overlays
/// This is used to replace native Android dialogs in full-screen navigation
class NavigationWrapper extends StatelessWidget {
  final Widget child;
  final void Function(StaticMarker)? onMarkerTap;
  final void Function(double lat, double lng)? onMapTap;
  final bool enableFullScreenOverlays;
  final bool showDebugInfo;

  const NavigationWrapper({
    Key? key,
    required this.child,
    this.onMarkerTap,
    this.onMapTap,
    this.enableFullScreenOverlays = false, // Default to false to avoid conflicts
    this.showDebugInfo = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // For most use cases, just return the child directly to avoid layout conflicts
    // Only enable the overlay when specifically requested
    if (!enableFullScreenOverlays) {
      return child;
    }

    // When enabled, use the overlay with safety checks
    return FullScreenNavigationOverlay(
      onMarkerDetails: onMarkerTap,
      onMapTap: onMapTap,
      showDebugInfo: showDebugInfo,
      child: child,
    );
  }
}

/// Helper class for showing marker dialogs in embedded navigation
class MarkerDialogHelper {
  /// Shows a marker details dialog for embedded navigation
  static void showMarkerDialog(
    BuildContext context,
    StaticMarker marker, {
    VoidCallback? onClose,
  }) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: marker.customColor ?? Theme.of(context).primaryColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  _getMarkerIcon(marker.iconId),
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      marker.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (marker.category.isNotEmpty)
                      Text(
                        marker.category.toUpperCase(),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                          letterSpacing: 0.5,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (marker.description != null && marker.description!.isNotEmpty)
                Text(marker.description!),
              
              if (marker.metadata != null && marker.metadata!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Details',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...marker.metadata!.entries.map(
                        (entry) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            '${entry.key}: ${entry.value}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onClose?.call();
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  static IconData _getMarkerIcon(String? iconId) {
    // Map marker icon IDs to Flutter icons
    switch (iconId) {
      case 'petrolStation':
        return Icons.local_gas_station;
      case 'restaurant':
        return Icons.restaurant;
      case 'hotel':
        return Icons.hotel;
      case 'hospital':
        return Icons.local_hospital;
      case 'police':
        return Icons.local_police;
      case 'parking':
        return Icons.local_parking;
      case 'scenic':
        return Icons.landscape;
      case 'chargingStation':
        return Icons.ev_station;
      case 'speedCamera':
        return Icons.speed;
      case 'accident':
        return Icons.warning;
      case 'construction':
        return Icons.construction;
      default:
        return Icons.place;
    }
  }
}