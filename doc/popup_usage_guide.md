# Flutter Popup System Usage Guide

This guide demonstrates how to use the new Flutter-based popup overlay system for static markers in the Mapbox Navigation plugin.

## Overview

The popup system provides cross-platform, Flutter-native popup overlays that appear when markers are tapped. Key benefits:

- **Cross-platform consistency**: Same appearance and behavior on iOS and Android
- **Flutter native**: Full access to Flutter widgets, themes, and styling
- **Highly customizable**: Custom popup builders with complete control over layout
- **Performance optimized**: Efficient overlay rendering with animations
- **Easy integration**: Works with existing navigation views and marker systems

## Quick Start

### 1. Basic Popup Configuration

```dart
final markerConfiguration = MarkerConfiguration(
  popupBuilder: (marker, context) => DefaultMarkerPopup(marker: marker),
  popupDuration: const Duration(seconds: 5),
  popupOffset: const Offset(0, -60),
  hidePopupOnTapOutside: true,
  onMarkerTap: (marker) {
    print('Marker tapped: ${marker.title}');
  },
);
```

### 2. Enhanced Navigation View

Replace your existing `MapBoxNavigationView` with `MapBoxNavigationViewWithPopups`:

```dart
MapBoxNavigationViewWithPopups(
  options: MapBoxOptions(
    initialLatitude: 37.7749,
    initialLongitude: -122.4194,
    zoom: 12.0,
  ),
  onCreated: _onNavigationViewCreated,
  markerConfiguration: markerConfiguration,
  enableCoordinateConversion: true,
)
```

### 3. Add Markers with Popup Support

```dart
final markers = [
  StaticMarker(
    id: 'restaurant_1',
    latitude: 37.7749,
    longitude: -122.4194,
    title: 'Golden Gate Grill',
    category: 'restaurant',
    description: 'Amazing seafood restaurant',
    iconId: MarkerIcons.restaurant,
    customColor: Colors.orange,
    metadata: {
      'rating': 4.5,
      'price': '\$\$\$',
      'hours': '11AM - 10PM',
    },
  ),
];

await MapBoxNavigation.instance.addStaticMarkers(
  markers: markers,
  configuration: markerConfiguration,
);
```

## Custom Popup Builders

### Simple Text Popup

```dart
Widget buildSimplePopup(StaticMarker marker, BuildContext context) {
  return Container(
    padding: const EdgeInsets.all(12),
    child: Text(
      marker.title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    ),
  );
}
```

### Rich Content Popup

```dart
Widget buildRichPopup(StaticMarker marker, BuildContext context) {
  return Container(
    constraints: const BoxConstraints(maxWidth: 300),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with icon
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: marker.customColor?.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getIconForCategory(marker.category),
                color: marker.customColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                marker.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        
        // Description
        if (marker.description != null) ...[
          const SizedBox(height: 8),
          Text(marker.description!),
        ],
        
        // Metadata
        if (marker.metadata.isNotEmpty) ...[
          const SizedBox(height: 12),
          ...marker.metadata.entries.map((entry) =>
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                '${entry.key}: ${entry.value}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ),
          ),
        ],
        
        // Action buttons
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _navigateToMarker(marker),
                icon: const Icon(Icons.directions, size: 16),
                label: const Text('Navigate'),
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: () => _showDetails(marker),
              icon: const Icon(Icons.info_outline, size: 16),
              label: const Text('Details'),
            ),
          ],
        ),
      ],
    ),
  );
}
```

### Interactive Popup with Forms

```dart
Widget buildInteractivePopup(StaticMarker marker, BuildContext context) {
  return StatefulBuilder(
    builder: (context, setState) {
      return Container(
        constraints: const BoxConstraints(maxWidth: 320),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              marker.title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            
            // Rating widget
            Row(
              children: [
                const Text('Rate this place: '),
                ...List.generate(5, (index) => 
                  IconButton(
                    onPressed: () => setState(() {
                      // Update rating logic here
                    }),
                    icon: Icon(
                      Icons.star,
                      color: index < 3 ? Colors.amber : Colors.grey,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
            
            // Comment field
            TextField(
              decoration: const InputDecoration(
                hintText: 'Add a comment...',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            
            const SizedBox(height: 12),
            
            ElevatedButton(
              onPressed: () {
                // Submit logic here
                MarkerPopupManager().hidePopup();
              },
              child: const Text('Submit Review'),
            ),
          ],
        ),
      );
    },
  );
}
```

## Configuration Options

### MarkerConfiguration Properties

```dart
MarkerConfiguration({
  // Popup-specific options
  Widget Function(StaticMarker, BuildContext)? popupBuilder,
  Duration popupDuration = const Duration(seconds: 5),
  Offset popupOffset = const Offset(0, -60),
  bool hidePopupOnTapOutside = true,
  
  // Existing marker options
  bool showDuringNavigation = true,
  bool showInFreeDrive = true,
  bool showOnEmbeddedMap = true,
  double? maxDistanceFromRoute,
  double minZoomLevel = 10.0,
  bool enableClustering = true,
  int? maxMarkersToShow,
  Function(StaticMarker)? onMarkerTap,
  String? defaultIconId,
  Color? defaultColor,
})
```

### Popup Positioning

The `popupOffset` parameter controls where the popup appears relative to the marker:

```dart
// Popup appears above marker
popupOffset: const Offset(0, -80),

// Popup appears to the right
popupOffset: const Offset(100, -40),

// Popup appears below marker
popupOffset: const Offset(0, 20),
```

## Manual Popup Control

### Show/Hide Popups Programmatically

```dart
// Show popup for specific marker
final marker = markers.first;
MarkerPopupManager().showPopupForMarker(
  marker,
  screenPosition: const Offset(200, 300), // Optional
);

// Hide current popup
MarkerPopupManager().hidePopup();

// Check if marker has popup shown
final hasPopup = marker.hasPopupShown;
```

### Integration with Navigation Controller

```dart
void _onNavigationViewCreated(MapBoxNavigationViewController controller) async {
  _controller = controller;
  
  // Show popup using controller extension
  controller.showMarkerPopup(marker);
  
  // Hide popup using controller extension
  controller.hideMarkerPopup();
  
  // Update viewport for accurate positioning
  final viewport = await MapBoxNavigation.instance.getMapViewport();
  if (viewport != null) {
    controller.updatePopupViewport(viewport);
  }
}
```

## Advanced Features

### Coordinate Conversion

The system includes utilities for converting geographic coordinates to screen positions:

```dart
// Get screen position for marker
final screenPosition = await MapBoxNavigation.instance
    .getMarkerScreenPosition('marker_id');

if (screenPosition != null) {
  print('Marker at screen position: $screenPosition');
}

// Get current map viewport
final viewport = await MapBoxNavigation.instance.getMapViewport();
if (viewport != null) {
  final markerScreen = viewport.coordinateToScreen(
    marker.latitude,
    marker.longitude,
  );
}
```

### Custom Animations

```dart
class AnimatedPopup extends StatefulWidget {
  final StaticMarker marker;
  
  const AnimatedPopup({super.key, required this.marker});

  @override
  State<AnimatedPopup> createState() => _AnimatedPopupState();
}

class _AnimatedPopupState extends State<AnimatedPopup>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    ));
    
    _controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(widget.marker.title),
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
```

## Best Practices

1. **Performance**: Keep popup builders lightweight and avoid complex layouts
2. **Positioning**: Use appropriate offsets to ensure popups don't overlap with markers
3. **Responsive Design**: Use constraints to ensure popups work on different screen sizes
4. **User Experience**: Provide clear close buttons or tap-to-dismiss functionality
5. **Accessibility**: Include semantic labels and proper focus management
6. **Error Handling**: Handle cases where coordinate conversion fails
7. **Memory Management**: Dispose of any controllers or subscriptions in popup widgets

## Troubleshooting

### Common Issues

1. **Popup not showing**: Check that `popupBuilder` is provided in `MarkerConfiguration`
2. **Wrong position**: Ensure map viewport is updated when map moves/zooms
3. **Performance issues**: Optimize popup builder and use constraints
4. **Platform differences**: Use Flutter widgets only, avoid platform-specific code

### Debugging

```dart
// Enable debug logging
MarkerPopupManager().setEnabled(true);

// Check current popup state
final manager = MarkerPopupManager();
print('Has active popup: ${manager.hasActivePopup}');
print('Selected marker: ${manager.selectedMarker?.title}');
print('Screen position: ${manager.markerScreenPosition}');
```

## Migration from Native Popups

If you were using native Android popups (e.g., `MarkerPopupBinder`), migrate to Flutter popups:

### Before (Native Android)
```kotlin
// Android-specific popup implementation
class MarkerPopupBinder : UIBinder {
  // Native Android popup code
}
```

### After (Flutter)
```dart
// Cross-platform Flutter popup
MarkerConfiguration(
  popupBuilder: (marker, context) => MyCustomPopup(marker: marker),
  popupDuration: const Duration(seconds: 5),
  hidePopupOnTapOutside: true,
)
```

This provides better consistency, easier maintenance, and more customization options across both platforms.