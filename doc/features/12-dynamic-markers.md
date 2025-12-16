# Feature Spec: Dynamic Markers

## Overview

Dynamic Markers enable real-time visualization of moving entities on the navigation map with smooth animated transitions. Unlike static markers which remain fixed, dynamic markers continuously update their position based on an external data stream, with native-level animation for smooth 60fps movement.

**Priority:** P2 - Nice to Have
**Effort:** Large
**Dependencies:** Static Markers (05), Turn-by-Turn Navigation (01), Embedded Navigation View (04)

## User Stories

1. **As a developer**, I can display moving entities on the map with smooth animation between position updates.
2. **As a developer**, I can track any moving object (vehicles, people, drones, assets, etc.) by providing position updates via a stream.
3. **As a developer**, I can customize the appearance of dynamic markers based on entity metadata.
4. **As a user**, I can see other entities moving smoothly on the map in near real-time.
5. **As a user**, I can see a trail/breadcrumb showing where an entity has been.
6. **As a user**, I can tell when an entity's connection is lost (stale/offline indicators).

---

## 1. Core Design Philosophy

### Key Differentiators from Static Markers

| Aspect | Static Markers | Dynamic Markers |
|--------|---------------|-----------------|
| Position | Fixed at creation | Updated continuously |
| Animation | None | Smooth interpolation between positions |
| Update Rate | Manual via `updateStaticMarkers()` | Automatic via stream subscription |
| Data Source | Point-in-time | Continuous stream (WebSocket/MQTT/Firebase/etc) |
| State | Immutable | Mutable position, immutable identity |
| Heading | Not tracked | Tracked for rotation animation |
| History | None | Optional trail/breadcrumb |

### Design Principles

1. **Entity-Agnostic** - The marker system makes no assumptions about what is being tracked. It could be vehicles, people, drones, packages, wildlife, or any other moving entity.
2. **ID-Driven** - Each marker has a unique `id` provided by the consuming application. The plugin does not generate or manage IDs.
3. **Metadata-Flexible** - All entity-specific data is stored in a generic `metadata` map. The plugin provides sensible defaults but the application controls interpretation.
4. **Stream-Based** - Position updates flow through a standard Dart `Stream`, allowing integration with any backend (WebSocket, Firebase, MQTT, REST polling, etc.).

### Performance Goals

- **Smooth 60fps animation** - Native-level interpolation between position updates
- **Low latency** - Sub-200ms from position update receipt to visual update
- **Battery efficient** - Intelligent update batching and throttling
- **Scalable** - Support for 100+ simultaneous moving markers

---

## 2. Data Model Architecture

### 2.1 DynamicMarker

```dart
/// Represents a marker that can move and animate across the map.
///
/// The marker's position is updated via [DynamicMarkerPositionUpdate] events,
/// and the plugin handles smooth animation between positions.
class DynamicMarker {
  /// Unique identifier for this marker.
  ///
  /// This ID is provided by the consuming application and must be unique
  /// within the set of dynamic markers. It is used to correlate position
  /// updates with markers.
  final String id;

  /// Current geographic position of the marker.
  final LatLng position;

  /// Previous position (used internally for interpolation).
  final LatLng? previousPosition;

  /// Current heading/bearing in degrees (0-360, where 0 = north).
  ///
  /// When provided, the marker icon rotates to face this direction.
  /// If null, the marker does not rotate based on direction.
  final double? heading;

  /// Current speed in meters per second.
  ///
  /// Used for position prediction when updates are delayed.
  /// If null, prediction is disabled for this marker.
  final double? speed;

  /// Timestamp of the last position update.
  final DateTime lastUpdated;

  /// Display title for the marker.
  ///
  /// Shown in callouts/popups when the marker is tapped.
  final String title;

  /// Icon identifier from the standard marker icon set.
  ///
  /// See [MarkerIcons] for available options. Common choices for
  /// moving entities include: 'vehicle', 'person', 'drone', 'pin'.
  final String? iconId;

  /// Custom color for the marker.
  ///
  /// Overrides the default category-based color.
  final Color? customColor;

  /// Category string for grouping and default styling.
  ///
  /// Common categories: 'vehicle', 'person', 'drone', 'asset', 'delivery'.
  /// The plugin provides default colors/icons per category, but these
  /// can be overridden via [customColor] and [iconId].
  final String category;

  /// Arbitrary metadata associated with this marker.
  ///
  /// This is the primary mechanism for storing entity-specific data.
  /// The plugin does not interpret this data; it is passed through to
  /// callbacks and can be used by the application to render custom UI.
  ///
  /// Example metadata for different use cases:
  /// ```dart
  /// // Fleet tracking
  /// {'vehicleType': 'truck', 'licensePlate': 'ABC123', 'driverId': '42'}
  ///
  /// // Delivery tracking
  /// {'orderId': 'ORD-789', 'eta': '14:30', 'status': 'in_transit'}
  ///
  /// // Wildlife tracking
  /// {'species': 'elephant', 'tagId': 'E-2847', 'herdId': 'H12'}
  ///
  /// // Drone monitoring
  /// {'altitude': 120.5, 'batteryPct': 78, 'missionId': 'M-001'}
  /// ```
  final Map<String, dynamic>? metadata;

  /// Current state of the marker.
  final DynamicMarkerState state;

  /// Whether to render a trail/breadcrumb behind this marker.
  final bool showTrail;

  /// Maximum number of trail points to retain.
  final int trailLength;

  /// Historical positions for trail rendering.
  final List<LatLng>? positionHistory;

  const DynamicMarker({
    required this.id,
    required this.position,
    required this.title,
    required this.category,
    this.previousPosition,
    this.heading,
    this.speed,
    DateTime? lastUpdated,
    this.iconId,
    this.customColor,
    this.metadata,
    this.state = DynamicMarkerState.tracking,
    this.showTrail = false,
    this.trailLength = 50,
    this.positionHistory,
  }) : lastUpdated = lastUpdated ?? DateTime.now();
}
```

### 2.2 DynamicMarkerState

```dart
/// Represents the current state of a dynamic marker.
enum DynamicMarkerState {
  /// Marker is actively receiving position updates.
  tracking,

  /// Marker is currently animating between positions.
  animating,

  /// Entity has stopped moving (speed below threshold).
  stationary,

  /// No update received within the stale threshold.
  ///
  /// Visual appearance changes (e.g., grayed out) to indicate
  /// the position may be outdated.
  stale,

  /// No update received for an extended period.
  ///
  /// The entity's data source appears to be disconnected.
  offline,

  /// Marker is about to be automatically removed due to expiration.
  expired,
}
```

### 2.3 DynamicMarkerPositionUpdate

```dart
/// Represents a position update for a dynamic marker.
///
/// These updates are typically received from an external data source
/// (WebSocket, Firebase, MQTT, etc.) and converted to this format
/// before being passed to the plugin.
class DynamicMarkerPositionUpdate {
  /// The marker ID this update applies to.
  ///
  /// Must match an existing marker's [DynamicMarker.id].
  final String markerId;

  /// New latitude coordinate.
  final double latitude;

  /// New longitude coordinate.
  final double longitude;

  /// New heading in degrees (0-360, north = 0).
  ///
  /// If provided, the marker will animate rotation to this heading.
  final double? heading;

  /// Current speed in meters per second.
  ///
  /// Used for prediction and stationary detection.
  final double? speed;

  /// Altitude in meters (for 3D tracking scenarios).
  final double? altitude;

  /// GPS accuracy in meters.
  ///
  /// Used for filtering noisy GPS data via Kalman filter.
  final double? accuracy;

  /// Timestamp when this position was recorded.
  ///
  /// Used for ordering updates and calculating prediction windows.
  final DateTime timestamp;

  /// Additional data associated with this update.
  ///
  /// This data is merged into the marker's metadata on update.
  /// Use this for frequently-changing values like battery level,
  /// status codes, or sensor readings.
  final Map<String, dynamic>? additionalData;

  const DynamicMarkerPositionUpdate({
    required this.markerId,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    this.heading,
    this.speed,
    this.altitude,
    this.accuracy,
    this.additionalData,
  });

  /// Creates an update from a generic map.
  ///
  /// Useful for converting data from JSON/WebSocket messages.
  factory DynamicMarkerPositionUpdate.fromMap(Map<String, dynamic> map) {
    return DynamicMarkerPositionUpdate(
      markerId: map['id'] as String,
      latitude: (map['latitude'] ?? map['lat']) as double,
      longitude: (map['longitude'] ?? map['lng'] ?? map['lon']) as double,
      heading: map['heading'] as double?,
      speed: map['speed'] as double?,
      altitude: map['altitude'] as double?,
      accuracy: map['accuracy'] as double?,
      timestamp: map['timestamp'] != null
          ? DateTime.parse(map['timestamp'] as String)
          : DateTime.now(),
      additionalData: map['data'] as Map<String, dynamic>?,
    );
  }
}
```

### 2.4 DynamicMarkerConfiguration

```dart
/// Configuration for the dynamic marker system.
class DynamicMarkerConfiguration {
  // ---------------------------------------------------------------------------
  // Animation Settings
  // ---------------------------------------------------------------------------

  /// Duration of position animation in milliseconds.
  ///
  /// This should be roughly equal to or slightly longer than
  /// the expected interval between position updates to ensure
  /// smooth continuous motion.
  ///
  /// Default: 1000ms (suitable for 1Hz update rate)
  final int animationDurationMs;

  /// Enable smooth animation between positions.
  ///
  /// When false, markers jump instantly to new positions.
  /// Default: true
  final bool enableAnimation;

  /// Easing curve for position animation.
  ///
  /// Default: Curves.easeInOut (natural acceleration/deceleration)
  final Curve animationCurve;

  /// Enable rotation animation for heading changes.
  ///
  /// When true, markers smoothly rotate to face their heading.
  /// Default: true
  final bool animateHeading;

  // ---------------------------------------------------------------------------
  // State Thresholds
  // ---------------------------------------------------------------------------

  /// Time without updates before marking as stale (milliseconds).
  ///
  /// Default: 10000ms (10 seconds)
  final int staleThresholdMs;

  /// Time without updates before marking as offline (milliseconds).
  ///
  /// Default: 30000ms (30 seconds)
  final int offlineThresholdMs;

  /// Time without updates before auto-removing marker (milliseconds).
  ///
  /// Set to null to disable auto-expiration.
  /// Default: null (no auto-expiration)
  final int? expiredThresholdMs;

  /// Speed threshold below which entity is considered stationary (m/s).
  ///
  /// Default: 0.5 m/s (~1.8 km/h)
  final double stationarySpeedThreshold;

  /// Duration at low speed before marking stationary (milliseconds).
  ///
  /// Default: 30000ms (30 seconds)
  final int stationaryDurationMs;

  // ---------------------------------------------------------------------------
  // Trail/Breadcrumb Settings
  // ---------------------------------------------------------------------------

  /// Enable trail rendering by default for new markers.
  ///
  /// Individual markers can override via [DynamicMarker.showTrail].
  /// Default: false
  final bool enableTrail;

  /// Maximum number of trail points per marker.
  ///
  /// Default: 50
  final int maxTrailPoints;

  /// Trail line color.
  ///
  /// Default: Blue with 50% opacity
  final Color trailColor;

  /// Trail line width in logical pixels.
  ///
  /// Default: 3.0
  final double trailWidth;

  /// Enable gradient fade on trail (solid at marker, transparent at end).
  ///
  /// Default: true
  final bool trailGradient;

  /// Minimum distance between trail points in meters.
  ///
  /// Prevents dense clustering when stationary.
  /// Default: 5.0
  final double minTrailPointDistance;

  // ---------------------------------------------------------------------------
  // Prediction Settings
  // ---------------------------------------------------------------------------

  /// Enable dead-reckoning prediction when updates are delayed.
  ///
  /// When enabled, the marker continues moving based on last known
  /// speed and heading until a new update arrives.
  /// Default: true
  final bool enablePrediction;

  /// Maximum prediction window in milliseconds.
  ///
  /// Prediction stops after this duration without an update.
  /// Default: 2000ms
  final int predictionWindowMs;

  // ---------------------------------------------------------------------------
  // Display Settings
  // ---------------------------------------------------------------------------

  /// Z-index for dynamic markers (relative to static markers).
  ///
  /// Higher values render above lower values.
  /// Default: 100 (above default static markers at 0)
  final int zIndex;

  /// Minimum zoom level for marker visibility.
  ///
  /// Default: 0.0 (always visible)
  final double minZoomLevel;

  /// Maximum distance from map center before hiding (kilometers).
  ///
  /// null = no limit
  /// Default: null
  final double? maxDistanceFromCenter;

  // ---------------------------------------------------------------------------
  // Callbacks
  // ---------------------------------------------------------------------------

  /// Called when a dynamic marker is tapped.
  final void Function(DynamicMarker marker)? onMarkerTap;

  /// Called when a marker's state changes.
  final void Function(DynamicMarker marker, DynamicMarkerState oldState)? onMarkerStateChanged;

  /// Called when a marker is auto-removed due to expiration.
  final void Function(DynamicMarker marker)? onMarkerExpired;

  const DynamicMarkerConfiguration({
    this.animationDurationMs = 1000,
    this.enableAnimation = true,
    this.animationCurve = Curves.easeInOut,
    this.animateHeading = true,
    this.staleThresholdMs = 10000,
    this.offlineThresholdMs = 30000,
    this.expiredThresholdMs,
    this.stationarySpeedThreshold = 0.5,
    this.stationaryDurationMs = 30000,
    this.enableTrail = false,
    this.maxTrailPoints = 50,
    this.trailColor = const Color(0x7F2196F3),
    this.trailWidth = 3.0,
    this.trailGradient = true,
    this.minTrailPointDistance = 5.0,
    this.enablePrediction = true,
    this.predictionWindowMs = 2000,
    this.zIndex = 100,
    this.minZoomLevel = 0.0,
    this.maxDistanceFromCenter,
    this.onMarkerTap,
    this.onMarkerStateChanged,
    this.onMarkerExpired,
  });
}
```

---

## 3. API Reference

### 3.1 Adding Dynamic Markers

```dart
/// Add a single dynamic marker to the map.
Future<bool?> addDynamicMarker({
  required DynamicMarker marker,
  DynamicMarkerConfiguration? configuration,
});

/// Add multiple dynamic markers to the map.
Future<bool?> addDynamicMarkers({
  required List<DynamicMarker> markers,
  DynamicMarkerConfiguration? configuration,
});
```

### 3.2 Updating Marker Positions

```dart
/// Update position for a single marker (triggers animation).
Future<bool?> updateDynamicMarkerPosition({
  required DynamicMarkerPositionUpdate update,
});

/// Batch update multiple marker positions.
///
/// More efficient than individual calls when updating many markers.
Future<bool?> updateDynamicMarkerPositions({
  required List<DynamicMarkerPositionUpdate> updates,
});
```

### 3.3 Managing Markers

```dart
/// Remove specific dynamic markers by ID.
Future<bool?> removeDynamicMarkers({
  required List<String> markerIds,
});

/// Remove all dynamic markers from the map.
Future<bool?> clearAllDynamicMarkers();

/// Get current list of dynamic markers.
Future<List<DynamicMarker>?> getDynamicMarkers();

/// Update the global configuration for dynamic markers.
Future<bool?> updateDynamicMarkerConfiguration({
  required DynamicMarkerConfiguration configuration,
});
```

### 3.4 Stream Integration

```dart
/// Subscribe to a stream of position updates.
///
/// This is the primary way to integrate with real-time data sources.
/// Updates are automatically batched for efficiency.
StreamSubscription<DynamicMarkerPositionUpdate>? subscribeToDynamicMarkerUpdates({
  required Stream<DynamicMarkerPositionUpdate> updateStream,
  int batchIntervalMs = 100,
});
```

### 3.5 Event Listeners

```dart
/// Register listeners for dynamic marker events.
Future<void> registerDynamicMarkerEventListener({
  void Function(DynamicMarker)? onTap,
  void Function(DynamicMarker, DynamicMarkerState)? onStateChanged,
  void Function(DynamicMarker)? onExpired,
});
```

---

## 4. Usage Examples

### 4.1 Basic Usage - Fleet Tracking

```dart
class FleetMapScreen extends StatefulWidget {
  @override
  _FleetMapScreenState createState() => _FleetMapScreenState();
}

class _FleetMapScreenState extends State<FleetMapScreen> {
  final _navigation = MapBoxNavigation.instance;
  StreamSubscription? _positionSubscription;

  @override
  void initState() {
    super.initState();
    _initializeTracking();
  }

  Future<void> _initializeTracking() async {
    // Configure dynamic markers
    await _navigation.updateDynamicMarkerConfiguration(
      DynamicMarkerConfiguration(
        animationDurationMs: 1000,
        enableTrail: true,
        maxTrailPoints: 30,
        trailColor: Colors.blue.withOpacity(0.5),
        staleThresholdMs: 15000,
        onMarkerTap: _onMarkerTapped,
        onMarkerStateChanged: _onStateChanged,
      ),
    );

    // Add initial markers from your data source
    final entities = await _fetchTrackedEntities();
    final markers = entities.map((e) => DynamicMarker(
      id: e.id,
      position: LatLng(e.latitude, e.longitude),
      title: e.name,
      category: e.type,  // 'vehicle', 'drone', etc.
      iconId: _getIconForType(e.type),
      heading: e.heading,
      speed: e.speed,
      metadata: {
        'entityType': e.type,
        'label': e.label,
        'status': e.status,
        // ... any other entity-specific data
      },
    )).toList();

    await _navigation.addDynamicMarkers(markers: markers);

    // Subscribe to position updates from your real-time source
    _positionSubscription = _navigation.subscribeToDynamicMarkerUpdates(
      updateStream: _positionUpdateStream(),
      batchIntervalMs: 100,
    );
  }

  /// Convert your data source updates to DynamicMarkerPositionUpdate
  Stream<DynamicMarkerPositionUpdate> _positionUpdateStream() {
    // Example: WebSocket connection
    return myWebSocketService.messages
        .where((msg) => msg.type == 'position_update')
        .map((msg) => DynamicMarkerPositionUpdate(
              markerId: msg.entityId,
              latitude: msg.lat,
              longitude: msg.lng,
              heading: msg.heading,
              speed: msg.speed,
              timestamp: msg.timestamp,
              additionalData: msg.metadata,
            ));
  }

  void _onMarkerTapped(DynamicMarker marker) {
    showModalBottomSheet(
      context: context,
      builder: (context) => EntityDetailSheet(
        id: marker.id,
        title: marker.title,
        category: marker.category,
        position: marker.position,
        heading: marker.heading,
        speed: marker.speed,
        lastUpdated: marker.lastUpdated,
        metadata: marker.metadata,
      ),
    );
  }

  void _onStateChanged(DynamicMarker marker, DynamicMarkerState oldState) {
    if (marker.state == DynamicMarkerState.stale) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${marker.title}: Connection lost')),
      );
    }
  }

  String _getIconForType(String type) {
    switch (type) {
      case 'vehicle': return MarkerIcons.vehicle;
      case 'drone': return MarkerIcons.drone;
      case 'person': return MarkerIcons.person;
      default: return MarkerIcons.pin;
    }
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _navigation.clearAllDynamicMarkers();
    super.dispose();
  }
}
```

### 4.2 Generic Position Update Adapter

```dart
/// Example adapter for converting various data formats to position updates.
///
/// Customize this for your specific backend data format.
class PositionUpdateAdapter {
  /// From a generic JSON map
  static DynamicMarkerPositionUpdate fromJson(Map<String, dynamic> json) {
    return DynamicMarkerPositionUpdate(
      markerId: json['id'] as String,
      latitude: (json['lat'] ?? json['latitude']) as double,
      longitude: (json['lng'] ?? json['lon'] ?? json['longitude']) as double,
      heading: json['heading'] as double?,
      speed: json['speed'] as double?,
      accuracy: json['accuracy'] as double?,
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
      additionalData: json['meta'] as Map<String, dynamic>?,
    );
  }

  /// From Firebase Realtime Database
  static DynamicMarkerPositionUpdate fromFirebase(
    String entityId,
    Map<dynamic, dynamic> data,
  ) {
    return DynamicMarkerPositionUpdate(
      markerId: entityId,
      latitude: data['lat'] as double,
      longitude: data['lng'] as double,
      heading: data['hdg'] as double?,
      speed: data['spd'] as double?,
      timestamp: DateTime.fromMillisecondsSinceEpoch(data['ts'] as int),
    );
  }

  /// From MQTT message payload
  static DynamicMarkerPositionUpdate fromMqtt(String topic, String payload) {
    final parts = topic.split('/');
    final entityId = parts.last;
    final json = jsonDecode(payload) as Map<String, dynamic>;

    return DynamicMarkerPositionUpdate(
      markerId: entityId,
      latitude: json['lat'] as double,
      longitude: json['lon'] as double,
      heading: json['cog'] as double?,  // Course over ground
      speed: json['sog'] as double?,    // Speed over ground
      timestamp: DateTime.now(),
    );
  }
}
```

### 4.3 Delivery Tracking Example

```dart
/// Example: Tracking a delivery in progress
Future<void> trackDelivery(String orderId) async {
  final navigation = MapBoxNavigation.instance;
  final delivery = await fetchDeliveryDetails(orderId);

  // Add the delivery marker
  await navigation.addDynamicMarker(
    marker: DynamicMarker(
      id: 'delivery_$orderId',
      position: LatLng(delivery.currentLat, delivery.currentLng),
      title: 'Your Delivery',
      category: 'delivery',
      iconId: MarkerIcons.delivery,
      customColor: Colors.green,
      showTrail: true,
      metadata: {
        'orderId': orderId,
        'driverName': delivery.driverName,
        'eta': delivery.estimatedArrival.toIso8601String(),
        'status': delivery.status,
      },
    ),
    configuration: DynamicMarkerConfiguration(
      animationDurationMs: 2000,  // Slower updates for delivery
      enableTrail: true,
      trailColor: Colors.green.withOpacity(0.3),
      onMarkerTap: (marker) => _showDeliveryDetails(marker),
    ),
  );

  // Subscribe to delivery position updates
  final subscription = deliveryService
      .trackDelivery(orderId)
      .listen((update) {
        navigation.updateDynamicMarkerPosition(
          update: DynamicMarkerPositionUpdate(
            markerId: 'delivery_$orderId',
            latitude: update.lat,
            longitude: update.lng,
            heading: update.heading,
            speed: update.speed,
            timestamp: update.timestamp,
            additionalData: {
              'eta': update.eta?.toIso8601String(),
              'status': update.status,
            },
          ),
        );
      });
}
```

---

## 5. Platform Channel Contract

### 5.1 Method Channel Methods

```dart
// channel_constants.dart additions

abstract class Methods {
  // ... existing methods ...

  // ---------------------------------------------------------------------------
  // Dynamic Marker Methods
  // ---------------------------------------------------------------------------

  /// Add a single dynamic marker
  static const String addDynamicMarker = 'addDynamicMarker';

  /// Add multiple dynamic markers
  static const String addDynamicMarkers = 'addDynamicMarkers';

  /// Update position for a dynamic marker (triggers animation)
  static const String updateDynamicMarkerPosition = 'updateDynamicMarkerPosition';

  /// Batch update multiple marker positions
  static const String updateDynamicMarkerPositions = 'updateDynamicMarkerPositions';

  /// Remove specific dynamic markers
  static const String removeDynamicMarkers = 'removeDynamicMarkers';

  /// Clear all dynamic markers
  static const String clearAllDynamicMarkers = 'clearAllDynamicMarkers';

  /// Get current dynamic markers
  static const String getDynamicMarkers = 'getDynamicMarkers';

  /// Update configuration
  static const String updateDynamicMarkerConfiguration = 'updateDynamicMarkerConfiguration';

  /// Set marker state manually
  static const String setDynamicMarkerState = 'setDynamicMarkerState';

  /// Get position history for trail rendering
  static const String getDynamicMarkerTrail = 'getDynamicMarkerTrail';
}
```

### 5.2 Event Types

```dart
abstract class EventTypes {
  // ... existing events ...

  /// Dynamic marker position animation completed
  static const String dynamicMarkerPositionChanged = 'dynamic_marker_position_changed';

  /// Dynamic marker state changed
  static const String dynamicMarkerStateChanged = 'dynamic_marker_state_changed';

  /// Dynamic marker tapped
  static const String dynamicMarkerTapped = 'dynamic_marker_tapped';

  /// Dynamic marker expired and removed
  static const String dynamicMarkerExpired = 'dynamic_marker_expired';
}
```

### 5.3 Event Channel

```dart
/// Event channel for dynamic marker events
const String kDynamicMarkerEventChannelName =
    'flutter_mapbox_navigation/dynamic_marker_events';
```

---

## 6. Native Implementation Architecture

### 6.1 Android: DynamicMarkerManager.kt

```kotlin
/**
 * Manages animated/moving markers for real-time entity tracking.
 *
 * Key responsibilities:
 * - Position interpolation and animation via ValueAnimator
 * - Heading rotation animation
 * - Trail/breadcrumb rendering via PolylineAnnotationManager
 * - Stale marker detection
 * - Efficient batch updates
 */
class DynamicMarkerManager {

    // Marker storage
    private val markers = ConcurrentHashMap<String, DynamicMarker>()
    private val markerAnnotations = ConcurrentHashMap<String, PointAnnotation>()
    private val trailPolylines = ConcurrentHashMap<String, PolylineAnnotation>()

    // Animation state
    private val activeAnimations = ConcurrentHashMap<String, ValueAnimator>()
    private val pendingUpdates = ConcurrentLinkedQueue<PositionUpdate>()

    // Configuration
    private var configuration = DynamicMarkerConfiguration()

    // Native components
    private var mapView: MapView? = null
    private var pointAnnotationManager: PointAnnotationManager? = null
    private var polylineAnnotationManager: PolylineAnnotationManager? = null
    private var eventSink: EventChannel.EventSink? = null

    // Timing
    private val handler = Handler(Looper.getMainLooper())
    private var staleCheckRunnable: Runnable? = null

    companion object {
        @Volatile
        private var INSTANCE: DynamicMarkerManager? = null

        fun getInstance(): DynamicMarkerManager {
            return INSTANCE ?: synchronized(this) {
                INSTANCE ?: DynamicMarkerManager().also { INSTANCE = it }
            }
        }
    }

    /**
     * Updates marker position with smooth animation
     */
    fun updateMarkerPosition(update: PositionUpdate) {
        val marker = markers[update.markerId] ?: return

        // Cancel any existing animation
        activeAnimations[update.markerId]?.cancel()

        if (configuration.enableAnimation) {
            animateMarkerToPosition(marker, update)
        } else {
            setMarkerPosition(marker, update.latitude, update.longitude)
        }

        // Update heading with rotation animation
        if (configuration.animateHeading && update.heading != null) {
            animateMarkerHeading(marker, update.heading)
        }

        // Update trail
        if (configuration.enableTrail || marker.showTrail) {
            updateMarkerTrail(marker, update)
        }

        // Update marker state
        marker.lastUpdated = System.currentTimeMillis()
        marker.state = DynamicMarkerState.TRACKING
    }

    /**
     * Smooth position animation using ValueAnimator
     */
    private fun animateMarkerToPosition(
        marker: DynamicMarker,
        update: PositionUpdate
    ) {
        val startLat = marker.latitude
        val startLng = marker.longitude
        val endLat = update.latitude
        val endLng = update.longitude

        val animator = ValueAnimator.ofFloat(0f, 1f).apply {
            duration = configuration.animationDurationMs.toLong()
            interpolator = getInterpolator(configuration.curve)

            addUpdateListener { animation ->
                val fraction = animation.animatedValue as Float

                // Linear interpolation
                val currentLat = startLat + (endLat - startLat) * fraction
                val currentLng = startLng + (endLng - startLng) * fraction

                setMarkerPosition(marker, currentLat, currentLng)
            }

            addListener(object : AnimatorListenerAdapter() {
                override fun onAnimationEnd(animation: Animator) {
                    activeAnimations.remove(marker.id)
                    marker.state = DynamicMarkerState.TRACKING
                    notifyPositionChanged(marker)
                }
            })
        }

        activeAnimations[marker.id] = animator
        marker.state = DynamicMarkerState.ANIMATING
        animator.start()
    }

    /**
     * Heading rotation animation with shortest path
     */
    private fun animateMarkerHeading(marker: DynamicMarker, targetHeading: Double) {
        val currentHeading = marker.heading ?: 0.0

        // Find shortest rotation path
        var delta = targetHeading - currentHeading
        if (delta > 180) delta -= 360
        if (delta < -180) delta += 360

        val animator = ValueAnimator.ofFloat(0f, 1f).apply {
            duration = (configuration.animationDurationMs / 2).toLong()
            interpolator = DecelerateInterpolator()

            addUpdateListener { animation ->
                val fraction = animation.animatedValue as Float
                val heading = currentHeading + delta * fraction
                setMarkerHeading(marker, heading)
            }
        }

        animator.start()
    }

    /**
     * Periodically check for stale markers
     */
    private fun startStaleCheck() {
        staleCheckRunnable = object : Runnable {
            override fun run() {
                val now = System.currentTimeMillis()
                markers.values.forEach { marker ->
                    val age = now - marker.lastUpdated
                    val newState = when {
                        configuration.expiredThresholdMs != null &&
                            age > configuration.expiredThresholdMs -> DynamicMarkerState.EXPIRED
                        age > configuration.offlineThresholdMs -> DynamicMarkerState.OFFLINE
                        age > configuration.staleThresholdMs -> DynamicMarkerState.STALE
                        else -> null
                    }

                    if (newState != null && marker.state != newState) {
                        val oldState = marker.state
                        marker.state = newState
                        notifyStateChanged(marker, oldState)
                        updateMarkerAppearance(marker)

                        if (newState == DynamicMarkerState.EXPIRED) {
                            removeMarker(marker.id)
                            notifyMarkerExpired(marker)
                        }
                    }
                }
                handler.postDelayed(this, 1000)
            }
        }
        handler.postDelayed(staleCheckRunnable!!, 1000)
    }
}
```

### 6.2 iOS: DynamicMarkerManager.swift

```swift
/// Manages animated/moving markers for real-time entity tracking.
public class DynamicMarkerManager: NSObject {

    // MARK: - Singleton
    public static let shared = DynamicMarkerManager()

    // MARK: - Properties
    private var markers: [String: DynamicMarker] = [:]
    private var markerAnnotations: [String: PointAnnotation] = [:]
    private var trailAnnotations: [String: PolylineAnnotation] = [:]
    private var displayLinks: [String: CADisplayLink] = [:]

    private var mapView: MapView?
    private var pointAnnotationManager: PointAnnotationManager?
    private var polylineAnnotationManager: PolylineAnnotationManager?
    private var eventSink: FlutterEventSink?

    private var configuration = DynamicMarkerConfiguration()
    private var staleCheckTimer: Timer?

    // Animation state
    private struct AnimationState {
        var startPosition: CLLocationCoordinate2D
        var endPosition: CLLocationCoordinate2D
        var startTime: CFTimeInterval
        var duration: CFTimeInterval
        var startHeading: Double
        var endHeading: Double
    }
    private var animations: [String: AnimationState] = [:]

    // MARK: - Position Updates

    /// Updates marker position with smooth animation
    public func updateMarkerPosition(_ update: PositionUpdate) {
        guard let marker = markers[update.markerId] else { return }

        if configuration.enableAnimation {
            startPositionAnimation(marker: marker, update: update)
        } else {
            setMarkerPosition(marker: marker,
                           latitude: update.latitude,
                           longitude: update.longitude)
        }

        if configuration.enableTrail || marker.showTrail {
            updateMarkerTrail(marker: marker, update: update)
        }

        marker.lastUpdated = Date()
        marker.state = .tracking
    }

    /// Uses CADisplayLink for smooth 60fps animation
    private func startPositionAnimation(marker: DynamicMarker, update: PositionUpdate) {
        displayLinks[marker.id]?.invalidate()

        animations[marker.id] = AnimationState(
            startPosition: CLLocationCoordinate2D(
                latitude: marker.latitude,
                longitude: marker.longitude
            ),
            endPosition: CLLocationCoordinate2D(
                latitude: update.latitude,
                longitude: update.longitude
            ),
            startTime: CACurrentMediaTime(),
            duration: Double(configuration.animationDurationMs) / 1000.0,
            startHeading: marker.heading ?? 0,
            endHeading: update.heading ?? marker.heading ?? 0
        )

        let displayLink = CADisplayLink(target: self, selector: #selector(animationTick))
        displayLink.preferredFramesPerSecond = 60
        displayLink.add(to: .main, forMode: .common)

        objc_setAssociatedObject(displayLink, &AssociatedKeys.markerId,
                                  marker.id, .OBJC_ASSOCIATION_RETAIN)

        displayLinks[marker.id] = displayLink
        marker.state = .animating
    }

    @objc private func animationTick(_ displayLink: CADisplayLink) {
        guard let markerId = objc_getAssociatedObject(displayLink,
                                                       &AssociatedKeys.markerId) as? String,
              let marker = markers[markerId],
              let state = animations[markerId] else {
            displayLink.invalidate()
            return
        }

        let elapsed = CACurrentMediaTime() - state.startTime
        var progress = elapsed / state.duration

        if progress >= 1.0 {
            progress = 1.0
            displayLink.invalidate()
            displayLinks.removeValue(forKey: markerId)
            animations.removeValue(forKey: markerId)
            marker.state = .tracking
            notifyPositionChanged(marker)
        }

        let easedProgress = applyEasingCurve(progress)

        let lat = state.startPosition.latitude +
                  (state.endPosition.latitude - state.startPosition.latitude) * easedProgress
        let lng = state.startPosition.longitude +
                  (state.endPosition.longitude - state.startPosition.longitude) * easedProgress

        setMarkerPosition(marker: marker, latitude: lat, longitude: lng)

        if configuration.animateHeading {
            let heading = interpolateHeading(
                from: state.startHeading,
                to: state.endHeading,
                progress: easedProgress
            )
            setMarkerHeading(marker: marker, heading: heading)
        }
    }

    /// Interpolates heading via shortest path
    private func interpolateHeading(from: Double, to: Double, progress: Double) -> Double {
        var delta = to - from
        if delta > 180 { delta -= 360 }
        if delta < -180 { delta += 360 }
        return from + delta * progress
    }
}
```

---

## 7. Animation Implementation Details

### 7.1 Interpolation Strategies

```
┌─────────────────────────────────────────────────────────────────┐
│                     POSITION INTERPOLATION                       │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│   Linear (Fast, simple - default):                              │
│     lat_t = lat_0 + (lat_1 - lat_0) * t                        │
│     lng_t = lng_0 + (lng_1 - lng_0) * t                        │
│                                                                 │
│   Spherical (Accurate, for distances > 1km):                    │
│     Uses great-circle interpolation                             │
│     Accounts for Earth curvature                                │
│                                                                 │
│   Bezier (Smooth curves for predicted paths):                   │
│     Cubic bezier with control points from heading               │
│     Creates natural-looking curved motion                       │
│                                                                 │
├─────────────────────────────────────────────────────────────────┤
│                       EASING CURVES                              │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│   Linear     ────────────────────  (constant speed)             │
│   EaseIn        ───────────╱      (slow start)                  │
│   EaseOut      ╱───────────       (slow end)                    │
│   EaseInOut   ───╱────╱───        (default - natural motion)    │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### 7.2 Frame Rate and Timing

```
┌─────────────────────────────────────────────────────────────────┐
│                     ANIMATION TIMING                             │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│   Typical update rates from data sources:                       │
│     GPS devices: 1 Hz (1 update/second)                         │
│     Fleet tracking: 0.1-1 Hz (every 1-10 seconds)              │
│     High-precision: 5-10 Hz                                     │
│                                                                 │
│   Animation: 60 fps (16.67ms per frame)                         │
│   Default animation duration: 1000ms                            │
│                                                                 │
│   Timeline example (1Hz updates):                               │
│   ├─ T=0ms    Position A received, start animation             │
│   ├─ T=16ms   Frame 1: 1.6% progress                           │
│   ├─ T=500ms  Frame 30: 50% progress (midpoint)                │
│   ├─ T=1000ms Position B received, animation A ends            │
│   │           Start new animation A→B                           │
│   └─ ...      Seamless continuous motion                        │
│                                                                 │
│   Key: animationDurationMs ≈ expected update interval           │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### 7.3 Heading Animation

```
┌─────────────────────────────────────────────────────────────────┐
│                    HEADING INTERPOLATION                         │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│   Problem: Rotating 350° → 10° should go +20°, not -340°       │
│                                                                 │
│   Solution: Shortest path interpolation                          │
│                                                                 │
│   interpolateHeading(from, to, progress):                       │
│       delta = to - from                                         │
│       if (delta > 180) delta -= 360                            │
│       if (delta < -180) delta += 360                           │
│       return from + delta * progress                            │
│                                                                 │
│   Visual compass:                                                │
│                  N (0°)                                          │
│                   │                                              │
│            NW     │     NE                                       │
│              ╲    │    ╱                                         │
│         W ───────●─────── E (90°)                               │
│              ╱    │    ╲                                         │
│            SW     │     SE                                       │
│                   │                                              │
│                 S (180°)                                         │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## 8. Trail/Breadcrumb Rendering

### 8.1 Trail Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                      TRAIL RENDERING                             │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│   Implementation:                                                │
│   - PolylineAnnotationManager (separate from point markers)     │
│   - One polyline per tracked entity                              │
│   - Updated on each position change                              │
│   - Rendered below marker layer                                  │
│                                                                 │
│   Trail Point Management:                                        │
│   - Fixed-size circular buffer (default 50 points)              │
│   - Points added on position update                              │
│   - Oldest point dropped when buffer full                        │
│   - Optional Douglas-Peucker compression                         │
│                                                                 │
│   Visual:                                                        │
│   ●════════════════════════════════════════→ ▲                  │
│   │                                           │                  │
│   Fades to transparent               Solid at marker             │
│   (oldest)                           (current position)          │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### 8.2 Trail Configuration

```dart
class TrailConfiguration {
  final int maxPoints;           // Default: 50
  final double lineWidth;        // Default: 3.0
  final Color color;             // Default: Blue 50% opacity
  final bool enableGradient;     // Default: true
  final double minPointDistance; // Default: 5.0 meters
  final bool enableCompression;  // Default: true
  final double compressionTolerance; // Default: 0.00001 (~1m)
}
```

---

## 9. State Management

### 9.1 State Machine

```
┌─────────────────────────────────────────────────────────────────┐
│                    DYNAMIC MARKER STATES                         │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│                      ┌──────────┐                               │
│           ┌─────────▶│ TRACKING │◀─────────┐                   │
│           │          └────┬─────┘          │                   │
│           │               │                │                    │
│      Update received      │ No update      │ Update received   │
│           │               │ (threshold)    │                    │
│           │               ▼                │                    │
│           │          ┌──────────┐          │                    │
│           │          │  STALE   │──────────┘                   │
│           │          └────┬─────┘                               │
│           │               │ Extended timeout                    │
│           │               ▼                                     │
│           │          ┌──────────┐                               │
│           │          │ OFFLINE  │                               │
│           │          └────┬─────┘                               │
│           │               │ Expiration (optional)               │
│           │               ▼                                     │
│           │          ┌──────────┐                               │
│           └──────────│ EXPIRED  │──────▶ (Auto-removed)        │
│                      └──────────┘                               │
│                                                                 │
│   Parallel states:                                               │
│   ┌───────────┐                                                 │
│   │ANIMATING  │ (During position transition)                    │
│   └───────────┘                                                 │
│   ┌───────────┐                                                 │
│   │STATIONARY │ (Speed < threshold for duration)                │
│   └───────────┘                                                 │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### 9.2 State-Based Visual Appearance

| State | Opacity | Color | Indicator |
|-------|---------|-------|-----------|
| Tracking | 1.0 | Base color | None |
| Animating | 1.0 | Base color | None |
| Stationary | 0.9 | Base color | Pause icon |
| Stale | 0.6 | Grayed | Warning icon |
| Offline | 0.4 | Grayed | Offline icon |

---

## 10. Performance Optimizations

### 10.1 Batch Processing

```dart
/// Update batching reduces native bridge calls
class DynamicMarkerUpdateBatcher {
  final int batchIntervalMs;
  final int maxBatchSize;

  final List<DynamicMarkerPositionUpdate> _pending = [];
  Timer? _batchTimer;

  void enqueue(DynamicMarkerPositionUpdate update) {
    _pending.add(update);

    if (_pending.length >= maxBatchSize) {
      _flush();
    } else {
      _batchTimer ??= Timer(
        Duration(milliseconds: batchIntervalMs),
        _flush,
      );
    }
  }

  void _flush() {
    if (_pending.isEmpty) return;

    final batch = List.of(_pending);
    _pending.clear();
    _batchTimer?.cancel();
    _batchTimer = null;

    MapBoxNavigation.instance.updateDynamicMarkerPositions(updates: batch);
  }
}
```

### 10.2 Marker Culling

- Only animate markers visible in current viewport
- Off-screen markers: update position directly without animation
- Reduces GPU/CPU load with many markers

### 10.3 Memory Management

- Trail point compression using Douglas-Peucker algorithm
- Animation cleanup on completion
- Automatic marker expiration (optional)

---

## 11. Position Prediction

### 11.1 Dead Reckoning

When position updates are delayed, prediction maintains smooth movement:

```kotlin
fun predictPosition(marker: DynamicMarker, targetTime: Long): Point? {
    if (marker.speed == null || marker.heading == null) return null

    val timeDelta = targetTime - marker.lastUpdated
    if (timeDelta < 0 || timeDelta > configuration.predictionWindowMs) return null

    val timeSeconds = timeDelta / 1000.0
    val distanceMeters = marker.speed!! * timeSeconds
    val headingRad = Math.toRadians(marker.heading!!)

    // 1 degree latitude ≈ 111,320 meters
    val latOffset = (distanceMeters * cos(headingRad)) / 111320.0
    val lngOffset = (distanceMeters * sin(headingRad)) /
                    (111320.0 * cos(Math.toRadians(marker.latitude)))

    return Point.fromLngLat(
        marker.longitude + lngOffset,
        marker.latitude + latOffset
    )
}
```

### 11.2 Prediction Confidence Decay

```
Confidence = 1.0 - (elapsed / predictionWindow)²

After predictionWindow expires: Stop predicting, show stale indicator
```

---

## 12. Error Handling

### 12.1 Edge Case Matrix

| Scenario | Detection | Handling |
|----------|-----------|----------|
| GPS jitter | Position variance > threshold | Kalman filter smoothing |
| Teleportation | Distance > 1km in 1 update | Configurable: animate fast or snap |
| Duplicate updates | Same timestamp | Ignore |
| Out-of-order updates | Older timestamp | Queue and process in order |
| No heading data | heading == null | Don't rotate marker |
| App backgrounded | Lifecycle event | Pause animations, queue updates |
| Memory pressure | System warning | Reduce trail points |

### 12.2 GPS Jitter Filtering

```dart
/// Kalman filter for GPS smoothing
class GpsFilter {
  double _lat = 0, _lng = 0;
  double _variance = 1e10;

  LatLng filter(double lat, double lng, double accuracy) {
    _variance += processNoise;

    final measurementVariance = accuracy * accuracy * measurementNoise;
    final kalmanGain = _variance / (_variance + measurementVariance);

    _lat = _lat + kalmanGain * (lat - _lat);
    _lng = _lng + kalmanGain * (lng - _lng);
    _variance = (1 - kalmanGain) * _variance;

    return LatLng(_lat, _lng);
  }
}
```

---

## 13. Test Cases

### Unit Tests

```dart
void main() {
  group('DynamicMarker', () {
    test('should interpolate position linearly', () {
      final interpolator = PositionInterpolator();
      final start = LatLng(0, 0);
      final end = LatLng(1, 1);

      expect(interpolator.interpolate(start, end, 0.0), equals(start));
      expect(interpolator.interpolate(start, end, 1.0), equals(end));
      expect(interpolator.interpolate(start, end, 0.5), equals(LatLng(0.5, 0.5)));
    });

    test('should interpolate heading via shortest path', () {
      // 350° to 10° should go clockwise (+20°)
      expect(interpolateHeading(350, 10, 0.5), closeTo(0, 0.1));

      // 10° to 350° should go counterclockwise (-20°)
      expect(interpolateHeading(10, 350, 0.5), closeTo(0, 0.1));
    });

    test('should detect stale markers', () {
      final marker = DynamicMarker(
        id: 'test',
        position: LatLng(0, 0),
        title: 'Test',
        category: 'test',
        lastUpdated: DateTime.now().subtract(Duration(seconds: 15)),
      );

      final config = DynamicMarkerConfiguration(staleThresholdMs: 10000);
      expect(evaluateState(marker, config), equals(DynamicMarkerState.stale));
    });
  });
}
```

### Integration Tests

```dart
testWidgets('should animate marker position smoothly', (tester) async {
  final navigation = MapBoxNavigation.instance;

  await navigation.addDynamicMarker(
    marker: DynamicMarker(
      id: 'test',
      position: LatLng(37.7749, -122.4194),
      title: 'Test Entity',
      category: 'vehicle',
    ),
  );

  await navigation.updateDynamicMarkerPosition(
    update: DynamicMarkerPositionUpdate(
      markerId: 'test',
      latitude: 37.7750,
      longitude: -122.4195,
      timestamp: DateTime.now(),
    ),
  );

  await tester.pump(Duration(milliseconds: 500));

  final markers = await navigation.getDynamicMarkers();
  final marker = markers!.firstWhere((m) => m.id == 'test');

  // Position should be between start and end (mid-animation)
  expect(marker.position.latitude, greaterThan(37.7749));
  expect(marker.position.latitude, lessThan(37.7750));
});
```

---

## 14. Implementation Phases

### Phase 1: Core Infrastructure
- [ ] Create `DynamicMarker`, `DynamicMarkerPositionUpdate`, `DynamicMarkerConfiguration` models
- [ ] Add platform channel methods and event channel
- [ ] Implement `DynamicMarkerManager` skeleton on Android
- [ ] Implement `DynamicMarkerManager` skeleton on iOS
- [ ] Add/remove/get markers (no animation)

### Phase 2: Animation Engine
- [ ] Android: `ValueAnimator` position interpolation
- [ ] iOS: `CADisplayLink` position interpolation
- [ ] Heading rotation animation
- [ ] Easing curve support
- [ ] Animation cancellation and queuing

### Phase 3: Trail System
- [ ] Trail point collection
- [ ] Polyline annotation rendering
- [ ] Gradient fade effect
- [ ] Trail compression algorithm

### Phase 4: State Management
- [ ] Stale detection timer
- [ ] State transitions
- [ ] Visual state indicators
- [ ] Event callbacks for state changes

### Phase 5: Prediction & Optimization
- [ ] Dead reckoning prediction
- [ ] GPS jitter filtering
- [ ] Batch update processing
- [ ] Marker culling for off-screen

### Phase 6: Testing & Documentation
- [ ] Unit tests
- [ ] Integration tests
- [ ] Performance benchmarking
- [ ] API documentation
- [ ] Usage examples

---

## 15. Acceptance Criteria

- [ ] Dynamic markers can be added, updated, and removed via API
- [ ] Position updates trigger smooth animated transitions
- [ ] Heading changes animate marker rotation
- [ ] Trail/breadcrumb rendering works correctly
- [ ] Stale/offline states are detected and visually indicated
- [ ] Metadata is preserved and accessible in callbacks
- [ ] Works during navigation, free drive, and embedded modes
- [ ] Works on both iOS and Android with identical behavior
- [ ] Performance is acceptable with 50+ simultaneous markers
- [ ] Batch updates are efficient
- [ ] Position prediction smooths delayed updates

---

## 16. Summary

The Dynamic Markers feature provides a generic, entity-agnostic system for displaying moving objects on the navigation map. Key design principles:

1. **Entity-Agnostic** - No assumptions about what is being tracked; works for vehicles, people, drones, deliveries, or any moving entity
2. **ID-Driven** - Applications provide unique IDs; the plugin correlates updates by ID
3. **Metadata-Flexible** - Generic `metadata` map carries entity-specific data
4. **Stream-Based** - Integrates with any real-time backend via standard Dart streams
5. **Native Performance** - 60fps animation via platform-native animators
6. **Configurable** - Extensive configuration for animation, trails, states, and thresholds

The key innovation is treating position updates as **animation targets** rather than immediate positions, enabling smooth continuous motion from discrete update events regardless of the data source.
