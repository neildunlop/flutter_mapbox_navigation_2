import 'package:flutter/material.dart';
import '../models/static_marker.dart';
import '../models/marker_configuration.dart';

/// Data class for popup position information
class PopupPosition {
  final Offset screenPosition;
  final StaticMarker marker;
  final DateTime timestamp;
  
  const PopupPosition({
    required this.screenPosition,
    required this.marker,
    required this.timestamp,
  });
  
  /// Check if this popup position is still valid (not too old)
  bool isValid(Duration maxAge) {
    return DateTime.now().difference(timestamp) < maxAge;
  }
}

/// Widget that manages marker popup overlays on top of the map
class MarkerPopupOverlay extends StatefulWidget {
  /// Child widget (typically the map view)
  final Widget child;
  
  /// Configuration for marker behavior including popup builder
  final MarkerConfiguration configuration;
  
  /// Currently selected marker to show popup for
  final StaticMarker? selectedMarker;
  
  /// Screen position for the selected marker
  final Offset? markerScreenPosition;
  
  /// Callback when popup should be hidden
  final VoidCallback? onHidePopup;
  
  const MarkerPopupOverlay({
    super.key,
    required this.child,
    required this.configuration,
    this.selectedMarker,
    this.markerScreenPosition,
    this.onHidePopup,
  });

  @override
  State<MarkerPopupOverlay> createState() => _MarkerPopupOverlayState();
}

class _MarkerPopupOverlayState extends State<MarkerPopupOverlay>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  
  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }
  
  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));
    
    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    
    if (widget.selectedMarker != null) {
      _animationController.forward();
    }
  }
  
  @override
  void didUpdateWidget(MarkerPopupOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Show animation when marker is selected
    if (widget.selectedMarker != null && oldWidget.selectedMarker == null) {
      _animationController.forward();
      _scheduleAutoHide();
    }
    // Hide animation when marker is deselected
    else if (widget.selectedMarker == null && oldWidget.selectedMarker != null) {
      _animationController.reverse();
    }
    // Update animation if marker changed
    else if (widget.selectedMarker?.id != oldWidget.selectedMarker?.id) {
      if (widget.selectedMarker != null) {
        _animationController.reset();
        _animationController.forward();
        _scheduleAutoHide();
      }
    }
  }
  
  void _scheduleAutoHide() {
    // Cancel any existing timer
    Future.delayed(widget.configuration.popupDuration, () {
      if (mounted && widget.selectedMarker != null) {
        _hidePopup();
      }
    });
  }
  
  void _hidePopup() {
    widget.onHidePopup?.call();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.configuration.hidePopupOnTapOutside ? _hidePopup : null,
      child: Stack(
        children: [
          // Base map view
          widget.child,
          
          // Popup overlay
          if (widget.selectedMarker != null && 
              widget.markerScreenPosition != null &&
              widget.configuration.popupBuilder != null)
            _buildPopupOverlay(),
        ],
      ),
    );
  }
  
  Widget _buildPopupOverlay() {
    final marker = widget.selectedMarker!;
    final screenPosition = widget.markerScreenPosition!;
    final popupBuilder = widget.configuration.popupBuilder!;
    
    // Calculate popup position with offset
    final popupPosition = Offset(
      screenPosition.dx + widget.configuration.popupOffset.dx,
      screenPosition.dy + widget.configuration.popupOffset.dy,
    );
    
    return Positioned(
      left: popupPosition.dx,
      top: popupPosition.dy,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Opacity(
              opacity: _opacityAnimation.value,
              child: Material(
                color: Colors.transparent,
                child: _buildPopupContainer(marker, popupBuilder),
              ),
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildPopupContainer(StaticMarker marker, Widget Function(StaticMarker, BuildContext) popupBuilder) {
    return Container(
      constraints: const BoxConstraints(
        maxWidth: 280,
        maxHeight: 180, // Reduced height to prevent overflow
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Main popup content
          Card(
            elevation: 8,
            shadowColor: Colors.black26,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 160), // Constrain card content
              child: Padding(
                padding: const EdgeInsets.all(10), // Reduced padding
                child: SingleChildScrollView( // Make content scrollable
                  child: popupBuilder(marker, context),
                ),
              ),
            ),
          ),
          
          // Close button
          if (widget.configuration.hidePopupOnTapOutside)
            Positioned(
              top: -8,
              right: -8,
              child: GestureDetector(
                onTap: _hidePopup,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ),
            
          // Pointer arrow (pointing to marker)
          Positioned(
            bottom: -8,
            left: 20,
            child: Transform.rotate(
              angle: 3.14159 / 4, // 45 degrees
              child: Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 4,
                      offset: Offset(-2, 2),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Default popup widget for markers
class DefaultMarkerPopup extends StatelessWidget {
  final StaticMarker marker;
  
  const DefaultMarkerPopup({
    super.key,
    required this.marker,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        Text(
          marker.title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        
        if (marker.category.isNotEmpty) ...[
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: marker.customColor?.withOpacity(0.1) ?? 
                     Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: marker.customColor ?? Theme.of(context).primaryColor,
                width: 1,
              ),
            ),
            child: Text(
              marker.category,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: marker.customColor ?? Theme.of(context).primaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
        
        if (marker.description != null && marker.description!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            marker.description!,
            style: Theme.of(context).textTheme.bodyMedium,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
        
        // Show coordinates for debugging
        if (marker.metadata?.containsKey('showCoordinates') == true && 
            marker.metadata?['showCoordinates'] == true) ...[
          const SizedBox(height: 8),
          Text(
            '${marker.latitude.toStringAsFixed(6)}, ${marker.longitude.toStringAsFixed(6)}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
              fontFamily: 'monospace',
            ),
          ),
        ],
        
        // Show custom metadata
        if (marker.metadata?.isNotEmpty == true) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: marker.metadata!.entries
                .where((entry) => entry.key != 'showCoordinates')
                .take(3) // Limit to 3 metadata items
                .map((entry) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${entry.key}: ${entry.value}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ))
                .toList(),
          ),
        ],
      ],
    );
  }
}