import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../accessibility/accessibility_utils.dart';
import '../models/models.dart';

/// Flutter overlay widget for navigation marker details
/// This provides true Flutter UI overlays over native navigation
class NavigationOverlay extends StatefulWidget {
  final Map<String, dynamic>? initialMarkerData;
  
  const NavigationOverlay({Key? key, this.initialMarkerData}) : super(key: key);

  @override
  State<NavigationOverlay> createState() => _NavigationOverlayState();
}

class _NavigationOverlayState extends State<NavigationOverlay>
    with TickerProviderStateMixin {
  static const MethodChannel _channel = MethodChannel('navigation_overlay');
  
  StaticMarker? _currentMarker;
  bool _isVisible = false;
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    
    print('🎆 NavigationOverlay initState called - WIDGET IS BEING INITIALIZED');
    print('🎆 Initial marker data: ${widget.initialMarkerData}');
    
    // Setup animation controller
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    print('🎆 Animation controller created');
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 1.0), // Start from bottom
      end: Offset.zero, // End at normal position
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    print('🎆 Slide animation configured');

    // Setup method channel handler
    print('📡 Setting up method channel handler for navigation_overlay');
    _channel.setMethodCallHandler(_handleMethodCall);
    print('📡 Method channel handler set - READY TO RECEIVE MESSAGES');
    
    // If we have initial marker data, show it immediately
    if (widget.initialMarkerData != null) {
      print('🎆 Showing initial marker data immediately');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showMarkerOverlay(widget.initialMarkerData!);
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<dynamic> _handleMethodCall(MethodCall call) async {
    print('NavigationOverlay received method call: ${call.method}');
    print('Arguments: ${call.arguments}');
    
    switch (call.method) {
      case 'ping':
        print('✅ Ping received - Flutter overlay is responsive!');
        return 'pong'; // Respond to ping
      case 'showMarkerOverlay':
        print('Showing marker overlay with data: ${call.arguments}');
        _showMarkerOverlay(call.arguments);
        return 'overlay_shown'; // Confirm action
      case 'hideOverlay':
        print('Hiding overlay');
        _hideOverlay();
        return 'overlay_hidden'; // Confirm action
      default:
        print('Unknown method: ${call.method}');
        throw PlatformException(code: 'NotImplemented');
    }
  }

  void _showMarkerOverlay(dynamic arguments) {
    print('_showMarkerOverlay called with arguments: $arguments');
    
    try {
      final Map<String, dynamic> markerData = Map<String, dynamic>.from(arguments as Map);
      print('Parsed marker data: $markerData');
      
      setState(() {
        _currentMarker = StaticMarker.fromJson(markerData);
        _isVisible = true;
      });
      
      print('State updated, starting animation');
      _animationController.forward();
      
      // Auto-hide after 5 seconds
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted && _isVisible) {
          _hideOverlay();
        }
      });
      
      print('Marker overlay setup complete');
    } catch (e) {
      print('Error showing marker overlay: $e');
    }
  }

  void _hideOverlay() {
    _animationController.reverse().then((_) {
      if (mounted) {
        setState(() {
          _isVisible = false;
          _currentMarker = null;
        });
      }
    });
  }

  void _onClose() {
    print('🎯 NavigationOverlay: Closing overlay');
    _hideOverlay();
    
    // Send to both channels to ensure proper cleanup
    _channel.invokeMethod('hideOverlay');
    
    // Also notify the global app router directly
    try {
      const MethodChannel('app_router').invokeMethod('switchToNormalMode');
    } catch (e) {
      print('Could not notify app router: $e');
    }
  }

  void _onAddToRoute() {
    _channel.invokeMethod('addToRoute', _currentMarker?.toJson());
  }

  @override
  Widget build(BuildContext context) {
    print('NavigationOverlay build called, _isVisible: $_isVisible, _currentMarker: ${_currentMarker?.title}');
    
    if (!_isVisible || _currentMarker == null) {
      // Return a completely transparent, non-interactive widget
      return const IgnorePointer(
        child: SizedBox.expand(
          child: ColoredBox(color: Colors.transparent),
        ),
      );
    }

    return Stack(
      children: [
        // Semi-transparent background that only covers the middle area
        // Leave space for navigation controls at the bottom
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          bottom: 120, // Leave more space for navigation controls
          child: GestureDetector(
            onTap: _onClose,
            child: Container(
              color: Colors.black26,
            ),
          ),
        ),
        
        // Animated marker overlay card - positioned to not block controls
        Positioned(
          left: 16,
          right: 16,
          bottom: 140, // Well above navigation controls (usually at bottom 60-80px)
          child: SlideTransition(
            position: _slideAnimation,
            child: _buildMarkerCard(),
          ),
        ),
      ],
    );
  }

  Widget _buildMarkerCard() {
    final marker = _currentMarker!;

    // Build semantic description for screen readers
    final semanticDescription = StringBuffer(marker.title);
    if (marker.category.isNotEmpty) {
      semanticDescription.write(', ${marker.category}');
    }
    if (marker.description != null && marker.description!.isNotEmpty) {
      semanticDescription.write('. ${marker.description}');
    }

    // Announce marker to screen readers when shown
    WidgetsBinding.instance.addPostFrameCallback((_) {
      announceToScreenReader(
        '${NavigationSemantics.markerPopup}: $semanticDescription',
      );
    });

    return Semantics(
      label: NavigationSemantics.markerPopup,
      container: true,
      child: Card(
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
              // Header with icon, title, and close button
              Row(
                children: [
                  // Marker icon - decorative, excluded from semantics
                  ExcludeSemantics(
                    child: Container(
                      width: kMinTouchTargetSize,
                      height: kMinTouchTargetSize,
                      decoration: BoxDecoration(
                        color: marker.customColor ??
                            Theme.of(context).primaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _getMarkerIcon(marker.iconId),
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Title and category
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            marker.title,
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          if (marker.category.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              marker.category.toUpperCase(),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: Colors.grey[600],
                                    letterSpacing: 0.8,
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  // Close button with proper touch target
                  AccessibleIconButton(
                    icon: Icons.close,
                    semanticLabel: NavigationSemantics.closeButton,
                    semanticHint: NavigationSemantics.closeButtonHint,
                    onPressed: _onClose,
                  ),
                ],
              ),

              // Description
              if (marker.description != null &&
                  marker.description!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  marker.description!,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],

              // Metadata
              if (marker.metadata != null && marker.metadata!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Semantics(
                  label: 'Additional details',
                  child: Container(
                    width: double.infinity,
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
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                        const SizedBox(height: 8),
                        ...marker.metadata!.entries.map(
                          (entry) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Semantics(
                              label: '${entry.key}: ${entry.value}',
                              child: Text(
                                '${entry.key}: ${entry.value}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              // Action buttons with proper touch targets
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Semantics(
                    button: true,
                    label: NavigationSemantics.closeButton,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        minHeight: kMinTouchTargetSize,
                      ),
                      child: TextButton(
                        onPressed: _onClose,
                        child: const Text('CLOSE'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Semantics(
                    button: true,
                    label: NavigationSemantics.addToRouteButton,
                    hint: NavigationSemantics.addToRouteButtonHint,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        minHeight: kMinTouchTargetSize,
                      ),
                      child: ElevatedButton(
                        onPressed: _onAddToRoute,
                        child: const Text('ADD TO ROUTE'),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getMarkerIcon(String? iconId) {
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