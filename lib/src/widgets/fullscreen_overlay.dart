import 'package:flutter/material.dart';
import 'package:flutter_mapbox_navigation/src/models/models.dart';
import 'package:flutter_mapbox_navigation/src/flutter_mapbox_navigation.dart';

/// Overlay widget for handling full-screen navigation events
/// This replaces native Android dialogs with Flutter UI components
class FullScreenNavigationOverlay extends StatefulWidget {
  final Widget child;
  final Function(StaticMarker)? onMarkerDetails;
  final Function(double lat, double lng)? onMapTap;
  final Duration animationDuration;
  final bool showDebugInfo;

  const FullScreenNavigationOverlay({
    Key? key,
    required this.child,
    this.onMarkerDetails,
    this.onMapTap,
    this.animationDuration = const Duration(milliseconds: 300),
    this.showDebugInfo = false,
  }) : super(key: key);

  @override
  State<FullScreenNavigationOverlay> createState() => _FullScreenNavigationOverlayState();
}

class _FullScreenNavigationOverlayState extends State<FullScreenNavigationOverlay>
    with TickerProviderStateMixin {
  OverlayEntry? _overlayEntry;
  StaticMarker? _currentMarker;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _registerFullScreenListener();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));
  }

  void _registerFullScreenListener() {
    try {
      // Register for full-screen navigation events
      MapBoxNavigation.instance.registerFullScreenEventListener((FullScreenEvent event) {
        _handleFullScreenEvent(event);
      });
    } catch (e) {
      if (widget.showDebugInfo) {
        debugPrint('⚠️ Could not register full-screen event listener: $e');
      }
    }
  }

  void _handleFullScreenEvent(FullScreenEvent event) {
    if (!mounted) return;

    switch (event.type) {
      case 'marker_tap':
        if (event.marker != null) {
          // For full-screen navigation, show a different UI approach
          // Since the overlay won't be visible in the NavigationActivity,
          // we'll use the callback to let the app handle it appropriately
          widget.onMarkerDetails?.call(event.marker!);
          
          if (widget.showDebugInfo) {
            debugPrint('🎯 Full-screen marker event handled via callback: ${event.marker!.title}');
          }
        }
        break;
      case 'map_tap':
        if (event.latitude != null && event.longitude != null) {
          _handleMapTap(event.latitude!, event.longitude!);
        }
        break;
    }
  }

  void _showMarkerOverlay(StaticMarker marker) {
    // For the main Flutter app context, we should not create overlays
    // since we're already in Flutter. Instead, use the callback.
    // Overlays are primarily for native navigation contexts.
    
    if (widget.showDebugInfo) {
      debugPrint('🎯 Handling marker via callback instead of overlay: ${marker.title}');
    }
    
    // Use callback instead of creating conflicting overlay
    widget.onMarkerDetails?.call(marker);
  }

  void _handleMapTap(double latitude, double longitude) {
    widget.onMapTap?.call(latitude, longitude);
    
    if (widget.showDebugInfo) {
      debugPrint('🗺️ Full-screen map tap: $latitude, $longitude');
    }
  }

  Widget _buildMarkerOverlay(StaticMarker marker) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Stack(
          children: [
            // Background overlay
            FadeTransition(
              opacity: _fadeAnimation,
              child: GestureDetector(
                onTap: _dismissOverlay,
                child: Container(
                  width: double.infinity,
                  height: double.infinity,
                  color: Colors.black54,
                ),
              ),
            ),
            
            // Marker info card
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 20,
              left: 16,
              right: 16,
              child: SlideTransition(
                position: _slideAnimation,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: _buildMarkerCard(marker),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMarkerCard(StaticMarker marker) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with title and close button
            Row(
              children: [
                // Marker icon
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: marker.customColor ?? Theme.of(context).primaryColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    _getMarkerIcon(marker.iconId),
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // Title and category
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        marker.title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
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
                
                // Close button
                IconButton(
                  onPressed: _dismissOverlay,
                  icon: const Icon(Icons.close),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.grey[100],
                  ),
                ),
              ],
            ),
            
            // Description
            if (marker.description != null && marker.description!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                marker.description!,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
            
            // Metadata
            if (marker.metadata != null && marker.metadata!.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildMetadataSection(marker.metadata!),
            ],
            
            // Action buttons
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (marker.metadata != null && marker.metadata!.isNotEmpty)
                  TextButton(
                    onPressed: () {
                      widget.onMarkerDetails?.call(marker);
                    },
                    child: const Text('Details'),
                  ),
                
                const SizedBox(width: 8),
                
                ElevatedButton(
                  onPressed: _dismissOverlay,
                  child: const Text('Close'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetadataSection(Map<String, dynamic> metadata) {
    return Container(
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
            'Information',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          ...metadata.entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${entry.key}: ',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      entry.value.toString(),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getMarkerIcon(String? iconId) {
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

  void _dismissOverlay() {
    if (_overlayEntry != null) {
      _animationController.reverse().then((_) {
        _removeOverlay();
      });
    }
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    _currentMarker = null;
  }

  @override
  void dispose() {
    _removeOverlay();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Simply return the child without any wrapper that might interfere
    // with Scaffold layout. The event handling is done through callbacks.
    return widget.child;
  }
}