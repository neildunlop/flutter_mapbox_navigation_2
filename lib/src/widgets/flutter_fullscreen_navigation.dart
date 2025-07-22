import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mapbox_navigation/src/models/models.dart';
import 'package:flutter_mapbox_navigation/src/flutter_mapbox_navigation.dart';

/// Flutter-controlled full-screen navigation widget using platform views
/// This replaces the native NavigationActivity with a Flutter implementation
/// that embeds the map as a platform view, allowing perfect overlay control
class FlutterFullScreenNavigation extends StatefulWidget {
  final List<WayPoint> wayPoints;
  final MapBoxOptions options;
  final Function(StaticMarker)? onMarkerTap;
  final Function(double lat, double lng)? onMapTap;
  final Function(RouteEvent)? onRouteEvent;
  final Function()? onNavigationFinished;
  final bool showDebugOverlay;
  
  const FlutterFullScreenNavigation({
    Key? key,
    required this.wayPoints,
    required this.options,
    this.onMarkerTap,
    this.onMapTap,
    this.onRouteEvent,
    this.onNavigationFinished,
    this.showDebugOverlay = false,
  }) : super(key: key);

  @override
  State<FlutterFullScreenNavigation> createState() => _FlutterFullScreenNavigationState();
}

class _FlutterFullScreenNavigationState extends State<FlutterFullScreenNavigation>
    with TickerProviderStateMixin {
  
  static const String _viewType = 'flutter_mapbox_navigation_platform_view';
  
  // Navigation state
  bool _isNavigating = false;
  bool _isInitialized = false;
  String? _currentInstruction;
  double? _distanceRemaining;
  double? _durationRemaining;
  
  // Overlay state
  StaticMarker? _selectedMarker;
  late AnimationController _overlayAnimationController;
  late Animation<double> _overlayFadeAnimation;
  late Animation<Offset> _overlaySlideAnimation;
  
  // Platform view controller
  int? _platformViewId;
  
  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initializeNavigation();
  }
  
  void _setupAnimations() {
    _overlayAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _overlayFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _overlayAnimationController,
      curve: Curves.easeInOut,
    ));
    
    _overlaySlideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _overlayAnimationController,
      curve: Curves.easeOutBack,
    ));
  }
  
  Future<void> _initializeNavigation() async {
    try {
      // Register event listeners
      MapBoxNavigation.instance.registerRouteEventListener(_onRouteEvent);
      MapBoxNavigation.instance.registerStaticMarkerTapListener(_onMarkerTap);
      MapBoxNavigation.instance.registerFullScreenEventListener(_onFullScreenEvent);
      
      setState(() {
        _isInitialized = true;
      });
      
      if (widget.showDebugOverlay) {
        debugPrint('🚀 Flutter full-screen navigation initialized');
      }
    } catch (e) {
      debugPrint('❌ Failed to initialize Flutter full-screen navigation: $e');
    }
  }
  
  void _onRouteEvent(RouteEvent event) {
    widget.onRouteEvent?.call(event);
    
    switch (event.eventType) {
      case MapBoxEvent.progress_change:
        if (event.data is RouteProgressEvent) {
          final progress = event.data as RouteProgressEvent;
          setState(() {
            _currentInstruction = progress.currentStepInstruction;
          });
        }
        break;
      case MapBoxEvent.navigation_running:
        setState(() {
          _isNavigating = true;
        });
        break;
      case MapBoxEvent.navigation_finished:
      case MapBoxEvent.navigation_cancelled:
        setState(() {
          _isNavigating = false;
        });
        widget.onNavigationFinished?.call();
        break;
      default:
        break;
    }
    
    // Update distance and duration
    _updateNavigationProgress();
  }
  
  void _onMarkerTap(StaticMarker marker) {
    widget.onMarkerTap?.call(marker);
    _showMarkerOverlay(marker);
  }
  
  void _onFullScreenEvent(FullScreenEvent event) {
    if (event.marker != null) {
      _onMarkerTap(event.marker!);
    } else if (event.latitude != null && event.longitude != null) {
      widget.onMapTap?.call(event.latitude!, event.longitude!);
    }
  }
  
  Future<void> _updateNavigationProgress() async {
    try {
      final distance = await MapBoxNavigation.instance.getDistanceRemaining();
      final duration = await MapBoxNavigation.instance.getDurationRemaining();
      
      if (mounted) {
        setState(() {
          _distanceRemaining = distance;
          _durationRemaining = duration;
        });
      }
    } catch (e) {
      debugPrint('Failed to update navigation progress: $e');
    }
  }
  
  void _showMarkerOverlay(StaticMarker marker) {
    setState(() {
      _selectedMarker = marker;
    });
    _overlayAnimationController.forward();
    
    if (widget.showDebugOverlay) {
      debugPrint('🎯 Showing marker overlay: ${marker.title}');
    }
  }
  
  void _hideMarkerOverlay() {
    _overlayAnimationController.reverse().then((_) {
      if (mounted) {
        setState(() {
          _selectedMarker = null;
        });
      }
    });
  }
  
  Future<void> _finishNavigation() async {
    try {
      await MapBoxNavigation.instance.finishNavigation();
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      debugPrint('Failed to finish navigation: $e');
    }
  }
  
  @override
  void dispose() {
    _overlayAnimationController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Platform view containing the native navigation map
          if (_isInitialized)
            _buildPlatformView()
          else
            const Center(
              child: CircularProgressIndicator(),
            ),
          
          // Flutter-controlled overlays
          if (_isInitialized) ...[
            _buildNavigationUI(),
            if (_selectedMarker != null)
              _buildMarkerOverlay(),
            if (widget.showDebugOverlay)
              _buildDebugOverlay(),
          ],
        ],
      ),
    );
  }
  
  Widget _buildPlatformView() {
    return PlatformViewLink(
      viewType: _viewType,
      surfaceFactory: (context, controller) {
        return AndroidViewSurface(
          controller: controller as AndroidViewController,
          gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
            Factory<OneSequenceGestureRecognizer>(
              () => EagerGestureRecognizer(),
            ),
          },
          hitTestBehavior: PlatformViewHitTestBehavior.opaque,
        );
      },
      onCreatePlatformView: (params) {
        final viewId = params.id;
        _platformViewId = viewId;
        
        // Pass navigation parameters to the platform view
        final args = _buildNavigationArgs();
        
        return PlatformViewsService.initAndroidView(
          id: viewId,
          viewType: _viewType,
          layoutDirection: TextDirection.ltr,
          creationParams: args,
          creationParamsCodec: const StandardMessageCodec(),
          onFocus: () => params.onFocusChanged(true),
        );
      },
    );
  }
  
  Map<String, dynamic> _buildNavigationArgs() {
    final pointList = <Map<String, Object?>>[];
    
    for (var i = 0; i < widget.wayPoints.length; i++) {
      final wayPoint = widget.wayPoints[i];
      pointList.add({
        'Order': i,
        'Name': wayPoint.name,
        'Latitude': wayPoint.latitude,
        'Longitude': wayPoint.longitude,
        'IsSilent': wayPoint.isSilent,
      });
    }
    
    final args = widget.options.toMap();
    args['wayPoints'] = {for (var i = 0; i < pointList.length; i++) i: pointList[i]};
    args['platformViewMode'] = true; // Flag to indicate platform view mode
    
    return args;
  }
  
  Widget _buildNavigationUI() {
    return SafeArea(
      child: Column(
        children: [
          // Top navigation bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.7),
                  Colors.transparent,
                ],
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: _finishNavigation,
                  icon: const Icon(Icons.close, color: Colors.white),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black.withOpacity(0.3),
                  ),
                ),
                const Spacer(),
                if (widget.showDebugOverlay)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'FLUTTER MODE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          const Spacer(),
          
          // Bottom instruction panel
          if (_currentInstruction != null || _distanceRemaining != null)
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_currentInstruction != null) ...[
                    Text(
                      _currentInstruction!,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (_distanceRemaining != null || _durationRemaining != null)
                    Row(
                      children: [
                        if (_distanceRemaining != null) ...[
                          const Icon(Icons.straight, size: 16, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            '${(_distanceRemaining! * 0.000621371).toStringAsFixed(1)} mi',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                        if (_durationRemaining != null) ...[
                          if (_distanceRemaining != null)
                            const SizedBox(width: 16),
                          const Icon(Icons.access_time, size: 16, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            '${(_durationRemaining! / 60).toStringAsFixed(0)} min',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ],
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildMarkerOverlay() {
    return AnimatedBuilder(
      animation: _overlayAnimationController,
      builder: (context, child) {
        return Stack(
          children: [
            // Background overlay
            FadeTransition(
              opacity: _overlayFadeAnimation,
              child: GestureDetector(
                onTap: _hideMarkerOverlay,
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
                position: _overlaySlideAnimation,
                child: FadeTransition(
                  opacity: _overlayFadeAnimation,
                  child: _buildMarkerCard(_selectedMarker!),
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
            // Header
            Row(
              children: [
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
                IconButton(
                  onPressed: _hideMarkerOverlay,
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
            
            // Action buttons
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    _hideMarkerOverlay();
                    // Add as waypoint functionality could be added here
                  },
                  child: const Text('Add to Route'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _hideMarkerOverlay,
                  child: const Text('Close'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDebugOverlay() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 60,
      right: 16,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.8),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'DEBUG INFO',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Platform View ID: $_platformViewId',
              style: const TextStyle(color: Colors.white, fontSize: 10),
            ),
            Text(
              'Navigating: $_isNavigating',
              style: const TextStyle(color: Colors.white, fontSize: 10),
            ),
            Text(
              'Overlay: ${_selectedMarker != null ? _selectedMarker!.title : 'None'}',
              style: const TextStyle(color: Colors.white, fontSize: 10),
            ),
          ],
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