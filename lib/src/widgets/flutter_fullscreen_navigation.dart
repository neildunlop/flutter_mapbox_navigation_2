import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mapbox_navigation/src/models/models.dart';
import 'package:flutter_mapbox_navigation/src/flutter_mapbox_navigation.dart';
import 'package:flutter_mapbox_navigation/src/widgets/marker_popup_overlay.dart';

/// Flutter-controlled full-screen navigation widget using platform views.
///
/// This widget embeds the native Mapbox navigation map inside Flutter,
/// allowing Flutter to render overlays (like marker popups) on top of the map.
///
/// Features:
/// - Native map performance via platform views
/// - Flutter-rendered marker popups (cross-platform)
/// - Customizable popup UI via [markerPopupBuilder]
/// - Default Material Design popup when no custom builder provided
///
/// Example usage:
/// ```dart
/// Navigator.push(context, MaterialPageRoute(
///   builder: (_) => FlutterFullScreenNavigation(
///     wayPoints: [origin, destination],
///     options: MapBoxOptions(simulateRoute: true),
///     markerPopupBuilder: (context, marker, onClose) {
///       return MyCustomPopup(marker: marker, onClose: onClose);
///     },
///   ),
/// ));
/// ```
class FlutterFullScreenNavigation extends StatefulWidget {
  final List<WayPoint> wayPoints;
  final MapBoxOptions options;

  /// Optional custom builder for marker popups.
  /// If not provided, [DefaultMarkerPopup] will be used.
  final MarkerPopupBuilder? markerPopupBuilder;

  /// Callback when a marker is tapped (called in addition to showing popup)
  final Function(StaticMarker)? onMarkerTap;

  /// Callback when the map is tapped (not on a marker)
  final Function(double lat, double lng)? onMapTap;

  /// Callback for route progress events
  final Function(RouteEvent)? onRouteEvent;

  /// Callback when navigation finishes or is cancelled
  final Function()? onNavigationFinished;

  /// Whether to show debug information overlay
  final bool showDebugOverlay;

  const FlutterFullScreenNavigation({
    Key? key,
    required this.wayPoints,
    required this.options,
    this.markerPopupBuilder,
    this.onMarkerTap,
    this.onMapTap,
    this.onRouteEvent,
    this.onNavigationFinished,
    this.showDebugOverlay = false,
  }) : super(key: key);

  @override
  State<FlutterFullScreenNavigation> createState() =>
      _FlutterFullScreenNavigationState();
}

class _FlutterFullScreenNavigationState
    extends State<FlutterFullScreenNavigation> with TickerProviderStateMixin {
  static const String _viewType = 'flutter_mapbox_navigation_platform_view';

  // Navigation state
  bool _isNavigating = false;
  bool _isInitialized = false;
  String? _currentInstruction;
  double? _distanceRemaining;
  double? _durationRemaining;

  // Popup state
  StaticMarker? _selectedMarker;
  late AnimationController _popupAnimationController;
  late Animation<double> _popupFadeAnimation;
  late Animation<Offset> _popupSlideAnimation;

  // Platform view
  int? _platformViewId;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initializeNavigation();
  }

  void _setupAnimations() {
    _popupAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _popupFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _popupAnimationController,
      curve: Curves.easeInOut,
    ));

    _popupSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _popupAnimationController,
      curve: Curves.easeOutBack,
    ));
  }

  Future<void> _initializeNavigation() async {
    try {
      // Register event listeners
      MapBoxNavigation.instance.registerRouteEventListener(_onRouteEvent);
      MapBoxNavigation.instance.registerStaticMarkerTapListener(_onMarkerTap);
      MapBoxNavigation.instance
          .registerFullScreenEventListener(_onFullScreenEvent);

      setState(() {
        _isInitialized = true;
      });

      if (widget.showDebugOverlay) {
        debugPrint('FlutterFullScreenNavigation: Initialized');
      }
    } catch (e) {
      debugPrint('FlutterFullScreenNavigation: Failed to initialize: $e');
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
            _distanceRemaining = progress.distance;
            _durationRemaining = progress.duration;
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
  }

  void _onMarkerTap(StaticMarker marker) {
    widget.onMarkerTap?.call(marker);
    _showMarkerPopup(marker);
  }

  void _onFullScreenEvent(FullScreenEvent event) {
    if (event.marker != null) {
      _onMarkerTap(event.marker!);
    } else if (event.latitude != null && event.longitude != null) {
      widget.onMapTap?.call(event.latitude!, event.longitude!);
    }
  }

  void _showMarkerPopup(StaticMarker marker) {
    // If same marker tapped, toggle off
    if (_selectedMarker?.id == marker.id) {
      _hideMarkerPopup();
      return;
    }

    setState(() {
      _selectedMarker = marker;
    });
    _popupAnimationController.forward();

    if (widget.showDebugOverlay) {
      debugPrint('FlutterFullScreenNavigation: Showing popup for ${marker.title}');
    }
  }

  void _hideMarkerPopup() {
    _popupAnimationController.reverse().then((_) {
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
      debugPrint('FlutterFullScreenNavigation: Failed to finish: $e');
    }
  }

  @override
  void dispose() {
    _popupAnimationController.dispose();
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
            const Center(child: CircularProgressIndicator()),

          // Flutter overlays
          if (_isInitialized) ...[
            // Top navigation bar with close button
            _buildTopBar(),

            // Marker popup overlay
            if (_selectedMarker != null) _buildMarkerPopupOverlay(),

            // Debug overlay
            if (widget.showDebugOverlay) _buildDebugOverlay(),
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
    args['wayPoints'] = {
      for (var i = 0; i < pointList.length; i++) i: pointList[i]
    };
    args['platformViewMode'] = true;

    return args;
  }

  Widget _buildTopBar() {
    return SafeArea(
      child: Container(
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
    );
  }

  Widget _buildMarkerPopupOverlay() {
    return AnimatedBuilder(
      animation: _popupAnimationController,
      builder: (context, child) {
        return Stack(
          children: [
            // Semi-transparent background - tap to dismiss
            FadeTransition(
              opacity: _popupFadeAnimation,
              child: GestureDetector(
                onTap: _hideMarkerPopup,
                child: Container(
                  width: double.infinity,
                  height: double.infinity,
                  color: Colors.black.withOpacity(0.3),
                ),
              ),
            ),

            // Popup card at bottom
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 20,
              left: 16,
              right: 16,
              child: SlideTransition(
                position: _popupSlideAnimation,
                child: FadeTransition(
                  opacity: _popupFadeAnimation,
                  child: _buildPopupContent(),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPopupContent() {
    final marker = _selectedMarker!;

    // Use custom builder if provided, otherwise use default
    if (widget.markerPopupBuilder != null) {
      return widget.markerPopupBuilder!(context, marker, _hideMarkerPopup);
    }

    // Default popup wrapped in a Card with close button
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: DefaultMarkerPopup(marker: marker),
                ),
                IconButton(
                  onPressed: _hideMarkerPopup,
                  icon: const Icon(Icons.close),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.grey[100],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: _hideMarkerPopup,
                child: const Text('Close'),
              ),
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
              'Popup: ${_selectedMarker?.title ?? 'None'}',
              style: const TextStyle(color: Colors.white, fontSize: 10),
            ),
            if (_distanceRemaining != null)
              Text(
                'Distance: ${(_distanceRemaining! / 1000).toStringAsFixed(1)} km',
                style: const TextStyle(color: Colors.white, fontSize: 10),
              ),
          ],
        ),
      ),
    );
  }
}
