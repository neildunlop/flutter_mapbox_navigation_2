import Foundation
import MapboxMaps
import Flutter

/// Callback type for marker tap events
public typealias MarkerTapListener = (StaticMarker) -> Void

@objc public class StaticMarkerManager: NSObject {
    private var markers: [String: StaticMarker] = [:]
    private var configuration: MarkerConfiguration = MarkerConfiguration()
    private var eventSink: FlutterEventSink?
    private var mapView: MapView?
    private var pointAnnotationManager: PointAnnotationManager?
    private var markerAnnotations: [String: PointAnnotation] = [:]

    /// Listener for marker tap events (for popup overlay)
    private var markerTapListener: MarkerTapListener?
    
    // MARK: - Singleton
    
    @objc public static let shared = StaticMarkerManager()
    
    private override init() {
        super.init()
    }
    
    // MARK: - Setup
    
    @objc public func setMapView(_ mapView: MapView?) {
        self.mapView = mapView
        if let mapView = mapView {
            // Initialize the annotation manager when the map is ready
            initializeAnnotationManager()
        } else {
            pointAnnotationManager = nil
        }
    }
    
    private func initializeAnnotationManager() {
        guard let mapView = mapView else { return }
        
        // Initialize the PointAnnotationManager
        pointAnnotationManager = mapView.annotations.makePointAnnotationManager()
        
        // Re-apply markers after initialization
        applyMarkersToMap()
    }
    
    @objc public func setEventSink(_ eventSink: FlutterEventSink?) {
        self.eventSink = eventSink
    }

    /// Set a listener for marker tap events (used by MarkerPopupOverlay)
    public func setMarkerTapListener(_ listener: MarkerTapListener?) {
        self.markerTapListener = listener
    }
    
    // MARK: - Marker Management
    
    @objc public func addStaticMarkers(_ markersList: [StaticMarker], config: MarkerConfiguration? = nil) -> Bool {
        do {
            // Update configuration if provided
            if let config = config {
                configuration = config
            }
            
            // Add markers to the map
            for marker in markersList {
                markers[marker.id] = marker
            }
            
            // Apply configuration and add markers to the map
            applyMarkersToMap()
            
            return true
        } catch {
            print("Error adding static markers: \(error)")
            return false
        }
    }
    
    @objc public func removeStaticMarkers(_ markerIds: [String]) -> Bool {
        do {
            for id in markerIds {
                markers.removeValue(forKey: id)
            }
            
            // Update the map
            applyMarkersToMap()
            
            return true
        } catch {
            print("Error removing static markers: \(error)")
            return false
        }
    }
    
    @objc public func clearAllStaticMarkers() -> Bool {
        do {
            markers.removeAll()
            applyMarkersToMap()
            return true
        } catch {
            print("Error clearing static markers: \(error)")
            return false
        }
    }
    
    @objc public func updateMarkerConfiguration(_ config: MarkerConfiguration) -> Bool {
        do {
            configuration = config
            applyMarkersToMap()
            return true
        } catch {
            print("Error updating marker configuration: \(error)")
            return false
        }
    }
    
    @objc public func getStaticMarkers() -> [StaticMarker] {
        return Array(markers.values)
    }
    
    // MARK: - Event Handling

    @objc public func onMarkerTap(_ marker: StaticMarker) {
        // Notify the popup overlay listener
        markerTapListener?(marker)

        // Send marker data to Flutter
        do {
            let markerData = marker.toJson()
            eventSink?(markerData)
        } catch {
            print("Error sending marker tap event: \(error)")
        }
    }
    
    // MARK: - Map Integration
    
    private func applyMarkersToMap() {
        guard let mapView = mapView else {
            print("MapView not available")
            return
        }
        
        do {
            // Filter markers based on configuration
            let visibleMarkers = markers.values.filter { marker in
                marker.isVisible && shouldShowMarker(marker)
            }
            
            // Apply clustering if enabled
            let finalMarkers = configuration.enableClustering ? 
                applyClustering(visibleMarkers) : visibleMarkers
            
            // Limit markers if maxMarkersToShow is set
            let limitedMarkers = configuration.maxMarkersToShow.map { max in
                Array(finalMarkers.prefix(max))
            } ?? finalMarkers
            
            // Add markers to the actual map
            addMarkersToMapboxMap(limitedMarkers)
            
        } catch {
            print("Error applying markers to map: \(error)")
        }
    }
    
    private func shouldShowMarker(_ marker: StaticMarker) -> Bool {
        // Check if marker is within distance from route
        if let maxDistance = configuration.maxDistanceFromRoute {
            // This would need to be implemented with actual route data
            // For now, we'll show all markers
            return true
        }
        
        return true
    }
    
    private func applyClustering(_ markers: [StaticMarker]) -> [StaticMarker] {
        if !configuration.enableClustering {
            return markers
        }
        
        // Simple clustering implementation
        // In a real implementation, this would use Mapbox's clustering features
        var clusteredMarkers: [StaticMarker] = []
        let clusterRadius: Double = 0.01 // Approximately 1km at equator
        
        for marker in markers {
            let nearbyMarker = clusteredMarkers.first { existing in
                let latDiff = abs(existing.latitude - marker.latitude)
                let lngDiff = abs(existing.longitude - marker.longitude)
                return latDiff < clusterRadius && lngDiff < clusterRadius
            }
            
            if nearbyMarker == nil {
                clusteredMarkers.append(marker)
            }
            // If nearby marker exists, we could merge them or prioritize based on priority
        }
        
        return clusteredMarkers
    }
    
    private func addMarkersToMapboxMap(_ markers: [StaticMarker]) {
        guard let annotationManager = pointAnnotationManager else { return }
        
        // Clear existing annotations
        for annotation in markerAnnotations.values {
            annotationManager.remove(annotation)
        }
        markerAnnotations.removeAll()
        
        for marker in markers {
            do {
                // Create point for the marker
                let point = Point(latitude: marker.latitude, longitude: marker.longitude)
                
                // Create annotation options
                var annotationOptions = PointAnnotationOptions()
                annotationOptions.point = point
                
                // Set title
                annotationOptions.textField = marker.title
                
                // Set icon based on marker configuration
                let iconId = marker.iconId ?? "ic_pin"
                if let iconImage = IconResourceMapper.getIconImage(for: iconId) {
                    annotationOptions.iconImage = iconImage
                }
                
                // Set color if specified
                if let customColor = marker.customColor {
                    annotationOptions.iconColor = StyleColor(customColor)
                }
                
                // Set text color and size
                annotationOptions.textColor = StyleColor("#000000")
                annotationOptions.textSize = 12.0
                
                // Set anchor point for text
                annotationOptions.textAnchor = .top
                annotationOptions.textOffset = [0, -2]
                
                // Create and add the annotation
                let annotation = annotationManager.create(annotationOptions)
                
                // Store the annotation for later management
                markerAnnotations[marker.id] = annotation
                
                // Add click listener
                annotationManager.addClickListener { [weak self] clickedAnnotation in
                    if clickedAnnotation == annotation {
                        self?.onMarkerTap(marker)
                        return true
                    }
                    return false
                }
                
            } catch {
                print("Failed to add marker \(marker.id): \(error)")
            }
        }
    }
    
    // MARK: - Utility Methods
    
    @objc public func shouldShowMarkersInCurrentMode(isNavigationMode: Bool, isFreeDriveMode: Bool, isEmbeddedMode: Bool) -> Bool {
        if isNavigationMode {
            return configuration.showDuringNavigation
        } else if isFreeDriveMode {
            return configuration.showInFreeDrive
        } else if isEmbeddedMode {
            return configuration.showOnEmbeddedMap
        }
        return true
    }
    
    @objc public func getMarkersWithinDistance(latitude: Double, longitude: Double, maxDistanceKm: Double) -> [StaticMarker] {
        return markers.values.filter { marker in
            let distance = calculateDistance(latitude: latitude, longitude: longitude, 
                                          markerLat: marker.latitude, markerLng: marker.longitude)
            return distance <= maxDistanceKm
        }
    }
    
    private func calculateDistance(latitude: Double, longitude: Double, markerLat: Double, markerLng: Double) -> Double {
        let r = 6371.0 // Earth's radius in kilometers
        let dLat = (markerLat - latitude) * .pi / 180.0
        let dLon = (markerLng - longitude) * .pi / 180.0
        let a = sin(dLat / 2) * sin(dLat / 2) +
                cos(latitude * .pi / 180.0) * cos(markerLat * .pi / 180.0) *
                sin(dLon / 2) * sin(dLon / 2)
        let c = 2 * atan2(sqrt(a), sqrt(1 - a))
        return r * c
    }
} 