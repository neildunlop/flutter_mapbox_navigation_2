import Foundation
import MapboxMaps
import Flutter
import UIKit

/// Callback type for dynamic marker tap events.
public typealias DynamicMarkerTapListener = (DynamicMarker) -> Void

/// Manages dynamic markers for the Mapbox Navigation plugin.
///
/// Dynamic markers differ from static markers in that they:
/// - Animate smoothly between position updates
/// - Have state management (tracking, stale, offline, etc.)
/// - Support trail/breadcrumb rendering
/// - Support heading-based rotation
@objc public class DynamicMarkerManager: NSObject {
    private var markers: [String: DynamicMarker] = [:]
    private var configuration: DynamicMarkerConfiguration = DynamicMarkerConfiguration.default
    private var eventSink: FlutterEventSink?
    private var mapView: MapView?
    private var pointAnnotationManager: PointAnnotationManager?
    private var markerAnnotations: [String: PointAnnotation] = [:]
    private var activeAnimators: [String: PositionAnimator] = [:]
    private var markerTapListener: DynamicMarkerTapListener?

    // State check timer
    private var stateCheckTimer: Timer?
    private let stateCheckInterval: TimeInterval = 1.0

    // Trail management
    private var trailSourceIds: [String: String] = [:]
    private var trailLayerIds: [String: String] = [:]

    // MARK: - Singleton

    @objc public static let shared = DynamicMarkerManager()

    private override init() {
        super.init()
    }

    // MARK: - Setup

    @objc public func setMapView(_ mapView: MapView?) {
        self.mapView = mapView
        if let mapView = mapView {
            initializeMarkerSystem()
            startStateCheckTimer()
        } else {
            stopStateCheckTimer()
            cleanupMarkerSystem()
        }
    }

    @objc public func setEventSink(_ eventSink: FlutterEventSink?) {
        self.eventSink = eventSink
    }

    /// Set a listener for marker tap events.
    public func setMarkerTapListener(_ listener: DynamicMarkerTapListener?) {
        self.markerTapListener = listener
    }

    private func initializeMarkerSystem() {
        guard let mapView = mapView else { return }
        pointAnnotationManager = mapView.annotations.makePointAnnotationManager()
        refreshAllMarkers()
    }

    private func cleanupMarkerSystem() {
        // Cancel all animations
        for animator in activeAnimators.values {
            animator.cancel()
        }
        activeAnimators.removeAll()

        // Clear annotations
        pointAnnotationManager = nil
        markerAnnotations.removeAll()

        // Clear trails
        trailSourceIds.removeAll()
        trailLayerIds.removeAll()
    }

    // MARK: - State Check Timer

    private func startStateCheckTimer() {
        stopStateCheckTimer()
        stateCheckTimer = Timer.scheduledTimer(
            withTimeInterval: stateCheckInterval,
            repeats: true
        ) { [weak self] _ in
            self?.checkMarkerStates()
        }
    }

    private func stopStateCheckTimer() {
        stateCheckTimer?.invalidate()
        stateCheckTimer = nil
    }

    private func checkMarkerStates() {
        let now = Date()
        let dateFormatter = ISO8601DateFormatter()

        for (markerId, marker) in markers {
            let lastUpdateTime: Date
            if let lastUpdatedString = marker.lastUpdated,
               let parsed = dateFormatter.date(from: lastUpdatedString) {
                lastUpdateTime = parsed
            } else {
                lastUpdateTime = now
            }

            let timeSinceUpdateMs = now.timeIntervalSince(lastUpdateTime) * 1000
            let oldState = marker.state

            var newState: DynamicMarkerState = marker.state

            if let expiredThreshold = configuration.expiredThresholdMsOptional,
               timeSinceUpdateMs > Double(expiredThreshold) {
                newState = .expired
            } else if timeSinceUpdateMs > Double(configuration.offlineThresholdMs) {
                newState = .offline
            } else if timeSinceUpdateMs > Double(configuration.staleThresholdMs) {
                newState = .stale
            } else if let speed = marker.speed,
                      speed < configuration.stationarySpeedThreshold {
                newState = .stationary
            }

            if newState != oldState {
                marker.state = newState

                // Send state change event
                sendStateChangedEvent(marker, oldState: oldState)

                // Handle expiration
                if newState == .expired {
                    sendMarkerExpiredEvent(marker)
                    _ = removeDynamicMarker(markerId)
                } else {
                    updateMarkerAnnotation(marker)
                }
            }
        }
    }

    // MARK: - Public API - CRUD Operations

    @objc public func addDynamicMarker(_ marker: DynamicMarker) -> Bool {
        markers[marker.id] = marker
        createMarkerAnnotation(marker)
        if marker.showTrail {
            setupTrailForMarker(marker)
        }
        return true
    }

    @objc public func addDynamicMarkers(_ markerList: [DynamicMarker]) -> Bool {
        for marker in markerList {
            markers[marker.id] = marker
        }
        refreshAllMarkers()
        return true
    }

    @objc public func updateDynamicMarkerPosition(_ update: DynamicMarkerPositionUpdate) -> Bool {
        guard var existingMarker = markers[update.markerId] else {
            return false
        }

        let updatedMarker = existingMarker.withPosition(
            newLatitude: update.latitude,
            newLongitude: update.longitude,
            newHeading: update.heading,
            newSpeed: update.speed,
            timestamp: update.timestamp
        )

        markers[update.markerId] = updatedMarker

        if configuration.enableAnimation {
            animateMarkerPosition(from: existingMarker, to: updatedMarker)
        } else {
            updateMarkerAnnotation(updatedMarker)
        }

        // Update trail if enabled
        if updatedMarker.showTrail {
            updateTrailForMarker(updatedMarker)
        }

        // Send position updated event
        sendPositionUpdatedEvent(updatedMarker)

        return true
    }

    @objc public func batchUpdateDynamicMarkerPositions(_ updates: [DynamicMarkerPositionUpdate]) -> Bool {
        for update in updates {
            _ = updateDynamicMarkerPosition(update)
        }
        return true
    }

    @objc public func updateDynamicMarker(
        markerId: String,
        title: String? = nil,
        snippet: String? = nil,
        iconId: String? = nil,
        showTrail: Bool? = nil,
        metadata: [String: Any]? = nil
    ) -> Bool {
        guard let existingMarker = markers[markerId] else {
            return false
        }

        // Create updated marker with new properties
        let updatedMarker = DynamicMarker(
            id: existingMarker.id,
            latitude: existingMarker.latitude,
            longitude: existingMarker.longitude,
            title: title ?? existingMarker.title,
            category: existingMarker.category,
            previousLatitude: existingMarker.previousLatitude,
            previousLongitude: existingMarker.previousLongitude,
            heading: existingMarker.heading,
            speed: existingMarker.speed,
            lastUpdated: existingMarker.lastUpdated,
            iconId: iconId ?? existingMarker.iconId,
            customColor: existingMarker.customColor,
            metadata: metadata ?? existingMarker.metadata,
            state: existingMarker.state,
            showTrail: showTrail ?? existingMarker.showTrail,
            trailLength: existingMarker.trailLength,
            positionHistory: existingMarker.positionHistory
        )

        markers[markerId] = updatedMarker
        updateMarkerAnnotation(updatedMarker)

        // Handle trail toggle
        if let newShowTrail = showTrail {
            if newShowTrail && !existingMarker.showTrail {
                setupTrailForMarker(updatedMarker)
            } else if !newShowTrail && existingMarker.showTrail {
                removeTrailForMarker(markerId)
            }
        }

        return true
    }

    @objc public func removeDynamicMarker(_ markerId: String) -> Bool {
        markers.removeValue(forKey: markerId)

        // Cancel any active animation
        activeAnimators[markerId]?.cancel()
        activeAnimators.removeValue(forKey: markerId)

        // Remove annotation
        if let annotation = markerAnnotations[markerId],
           let manager = pointAnnotationManager {
            manager.remove(annotation)
        }
        markerAnnotations.removeValue(forKey: markerId)

        // Remove trail
        removeTrailForMarker(markerId)

        return true
    }

    @objc public func removeDynamicMarkers(_ markerIds: [String]) -> Bool {
        for markerId in markerIds {
            _ = removeDynamicMarker(markerId)
        }
        return true
    }

    @objc public func clearAllDynamicMarkers() -> Bool {
        // Cancel all animations
        for animator in activeAnimators.values {
            animator.cancel()
        }
        activeAnimators.removeAll()

        // Clear markers
        markers.removeAll()

        // Clear annotations
        if let manager = pointAnnotationManager {
            for annotation in markerAnnotations.values {
                manager.remove(annotation)
            }
        }
        markerAnnotations.removeAll()

        // Clear all trails
        clearAllTrails()

        return true
    }

    @objc public func getDynamicMarker(_ markerId: String) -> DynamicMarker? {
        return markers[markerId]
    }

    @objc public func getDynamicMarkers() -> [DynamicMarker] {
        return Array(markers.values)
    }

    @objc public func updateDynamicMarkerConfiguration(_ config: DynamicMarkerConfiguration) -> Bool {
        self.configuration = config
        refreshAllMarkers()
        return true
    }

    @objc public func clearDynamicMarkerTrail(_ markerId: String) -> Bool {
        guard let marker = markers[markerId] else {
            return false
        }
        marker.positionHistory = nil
        updateTrailForMarker(marker)
        return true
    }

    @objc public func clearAllDynamicMarkerTrails() -> Bool {
        for markerId in markers.keys {
            _ = clearDynamicMarkerTrail(markerId)
        }
        return true
    }

    // MARK: - Animation

    private func animateMarkerPosition(from oldMarker: DynamicMarker, to newMarker: DynamicMarker) {
        // Cancel existing animation
        activeAnimators[oldMarker.id]?.cancel()

        let animator = PositionAnimator(
            duration: TimeInterval(configuration.animationDurationMs) / 1000.0,
            fromLatitude: oldMarker.latitude,
            fromLongitude: oldMarker.longitude,
            toLatitude: newMarker.latitude,
            toLongitude: newMarker.longitude,
            fromHeading: oldMarker.heading,
            toHeading: newMarker.heading,
            animateHeading: configuration.animateHeading
        ) { [weak self] lat, lng, heading in
            guard let self = self else { return }
            // Update annotation position during animation
            if let annotation = self.markerAnnotations[newMarker.id],
               let manager = self.pointAnnotationManager {
                var updatedAnnotation = annotation
                updatedAnnotation.point = Point(CLLocationCoordinate2D(latitude: lat, longitude: lng))
                if let heading = heading {
                    updatedAnnotation.iconRotate = heading
                }
                manager.update([updatedAnnotation])
            }
        }

        animator.start()
        activeAnimators[oldMarker.id] = animator
    }

    // MARK: - Annotation Management

    private func createMarkerAnnotation(_ marker: DynamicMarker) {
        guard let manager = pointAnnotationManager else { return }

        var annotationOptions = PointAnnotationOptions()
        annotationOptions.point = marker.toMapboxPoint()

        // Set icon
        let iconId = marker.iconId ?? "ic_pin"
        if let iconImage = IconResourceMapper.getIconImage(for: iconId) {
            annotationOptions.iconImage = iconImage
        }

        // Set opacity based on state
        annotationOptions.iconOpacity = getOpacityForState(marker.state)

        // Set rotation if heading is available
        if let heading = marker.heading {
            annotationOptions.iconRotate = heading
        }

        let annotation = manager.create(annotationOptions)
        markerAnnotations[marker.id] = annotation

        // Add click listener
        manager.addClickListener { [weak self] clickedAnnotation in
            if clickedAnnotation == annotation {
                self?.onMarkerTap(marker)
                return true
            }
            return false
        }
    }

    private func updateMarkerAnnotation(_ marker: DynamicMarker) {
        guard let annotation = markerAnnotations[marker.id],
              let manager = pointAnnotationManager else {
            createMarkerAnnotation(marker)
            return
        }

        var updatedAnnotation = annotation
        updatedAnnotation.point = marker.toMapboxPoint()
        updatedAnnotation.iconOpacity = getOpacityForState(marker.state)
        if let heading = marker.heading {
            updatedAnnotation.iconRotate = heading
        }
        manager.update([updatedAnnotation])
    }

    private func refreshAllMarkers() {
        guard let manager = pointAnnotationManager else { return }

        // Remove all existing annotations
        for annotation in markerAnnotations.values {
            manager.remove(annotation)
        }
        markerAnnotations.removeAll()

        // Recreate all markers
        for marker in markers.values {
            createMarkerAnnotation(marker)
            if marker.showTrail {
                setupTrailForMarker(marker)
            }
        }
    }

    private func getOpacityForState(_ state: DynamicMarkerState) -> Double {
        switch state {
        case .tracking, .animating: return 1.0
        case .stationary: return 0.9
        case .stale: return 0.6
        case .offline: return 0.4
        case .expired: return 0.2
        }
    }

    // MARK: - Trail Management

    private func setupTrailForMarker(_ marker: DynamicMarker) {
        // Trail implementation using GeoJSON source and line layer
        // Note: Full implementation would require MapboxMaps style manipulation
        let sourceId = "trail_source_\(marker.id)"
        let layerId = "trail_layer_\(marker.id)"

        trailSourceIds[marker.id] = sourceId
        trailLayerIds[marker.id] = layerId

        updateTrailForMarker(marker)
    }

    private func updateTrailForMarker(_ marker: DynamicMarker) {
        // Update trail geometry
        // Full implementation would update the GeoJSON source
        guard let _ = trailSourceIds[marker.id] else { return }

        // Trail update logic would go here
        // Using MapboxMaps style.updateGeoJSONSource
    }

    private func removeTrailForMarker(_ markerId: String) {
        // Remove trail source and layer
        guard let sourceId = trailSourceIds[markerId],
              let layerId = trailLayerIds[markerId] else { return }

        // Remove from map style
        // mapView?.mapboxMap.style.removeLayer(withId: layerId)
        // mapView?.mapboxMap.style.removeSource(withId: sourceId)

        trailSourceIds.removeValue(forKey: markerId)
        trailLayerIds.removeValue(forKey: markerId)
    }

    private func clearAllTrails() {
        for markerId in trailSourceIds.keys {
            removeTrailForMarker(markerId)
        }
    }

    // MARK: - Events

    private func onMarkerTap(_ marker: DynamicMarker) {
        // Notify listener
        markerTapListener?(marker)

        // Send event to Flutter
        let eventData: [String: Any] = [
            "eventType": "dynamic_marker_tapped",
            "marker": marker.toJson()
        ]
        eventSink?(eventData)
    }

    private func sendStateChangedEvent(_ marker: DynamicMarker, oldState: DynamicMarkerState) {
        let eventData: [String: Any] = [
            "eventType": "dynamic_marker_state_changed",
            "marker": marker.toJson(),
            "oldState": oldState.toJsonString(),
            "newState": marker.state.toJsonString()
        ]
        eventSink?(eventData)
    }

    private func sendPositionUpdatedEvent(_ marker: DynamicMarker) {
        let eventData: [String: Any] = [
            "eventType": "dynamic_marker_position_updated",
            "marker": marker.toJson()
        ]
        eventSink?(eventData)
    }

    private func sendMarkerExpiredEvent(_ marker: DynamicMarker) {
        let eventData: [String: Any] = [
            "eventType": "dynamic_marker_expired",
            "marker": marker.toJson()
        ]
        eventSink?(eventData)
    }
}

// MARK: - Position Animator

/// Helper class for animating marker positions.
private class PositionAnimator {
    private let duration: TimeInterval
    private let fromLatitude: Double
    private let fromLongitude: Double
    private let toLatitude: Double
    private let toLongitude: Double
    private let fromHeading: Double?
    private let toHeading: Double?
    private let animateHeading: Bool
    private let onUpdate: (Double, Double, Double?) -> Void

    private var displayLink: CADisplayLink?
    private var startTime: CFTimeInterval?
    private var isCancelled = false

    init(
        duration: TimeInterval,
        fromLatitude: Double,
        fromLongitude: Double,
        toLatitude: Double,
        toLongitude: Double,
        fromHeading: Double?,
        toHeading: Double?,
        animateHeading: Bool,
        onUpdate: @escaping (Double, Double, Double?) -> Void
    ) {
        self.duration = duration
        self.fromLatitude = fromLatitude
        self.fromLongitude = fromLongitude
        self.toLatitude = toLatitude
        self.toLongitude = toLongitude
        self.fromHeading = fromHeading
        self.toHeading = toHeading
        self.animateHeading = animateHeading
        self.onUpdate = onUpdate
    }

    func start() {
        displayLink = CADisplayLink(target: self, selector: #selector(update))
        displayLink?.add(to: .main, forMode: .common)
    }

    func cancel() {
        isCancelled = true
        displayLink?.invalidate()
        displayLink = nil
    }

    @objc private func update(_ displayLink: CADisplayLink) {
        guard !isCancelled else {
            cancel()
            return
        }

        if startTime == nil {
            startTime = displayLink.timestamp
        }

        let elapsed = displayLink.timestamp - startTime!
        let fraction = min(elapsed / duration, 1.0)

        // Linear interpolation
        let lat = fromLatitude + (toLatitude - fromLatitude) * fraction
        let lng = fromLongitude + (toLongitude - fromLongitude) * fraction

        var heading: Double? = nil
        if animateHeading, let fromH = fromHeading, let toH = toHeading {
            heading = lerpAngle(from: fromH, to: toH, fraction: fraction)
        } else if let toH = toHeading {
            heading = toH
        }

        onUpdate(lat, lng, heading)

        if fraction >= 1.0 {
            cancel()
        }
    }

    private func lerpAngle(from: Double, to: Double, fraction: Double) -> Double {
        var diff = to - from
        while diff > 180 { diff -= 360 }
        while diff < -180 { diff += 360 }
        return from + diff * fraction
    }
}
