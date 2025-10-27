import Foundation
import MapboxMaps
import Flutter

@objc public class StaticMarkerManager: NSObject {
    private var markers: [String: StaticMarker] = [:]
    private var configuration: MarkerConfiguration = MarkerConfiguration()
    private var eventSink: FlutterEventSink?
    private var mapView: MapView?
    private var pointAnnotationManager: PointAnnotationManager?
    private var markerAnnotations: [String: PointAnnotation] = [:]
    
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
        do {
            // Send marker data to Flutter
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
        annotationManager.annotations = []
        markerAnnotations.removeAll()
        
        var annotations: [PointAnnotation] = []
        
        for marker in markers {
            // Create point for the marker
            let coordinate = CLLocationCoordinate2D(latitude: marker.latitude, longitude: marker.longitude)
            
            // Create annotation
            var annotation = PointAnnotation(coordinate: coordinate)
            annotation.textField = marker.title
            
            // Set icon based on marker configuration
            let iconId = marker.iconId ?? "ic_pin"
            if let iconImage = IconResourceMapper.getIconImage(for: iconId) {
                annotation.image = .init(image: iconImage, name: iconId)
            }
            
            // Set color if specified (iOS uses different approach)
            if let customColor = marker.customColor {
                // Convert hex color string to UIColor
                if let color = hexStringToUIColor(customColor) {
                    annotation.iconColor = StyleColor(color)
                }
            }
            
            // Set marker size (default 1.0, use marker.metadata["size"] if provided)
            let markerSize: Double
            if let metadata = marker.metadata,
               let size = metadata["size"] as? Double {
                markerSize = size
            } else {
                markerSize = 1.0 // Default size
            }
            annotation.iconSize = markerSize
            
            // Set text properties
            annotation.textColor = StyleColor(.black)
            annotation.textSize = 12.0
            annotation.textAnchor = .top
            annotation.textOffset = [0, -2]
            
            // Store the annotation
            annotations.append(annotation)
            markerAnnotations[marker.id] = annotation
        }
        
        // Add all annotations to the manager
        annotationManager.annotations = annotations
        
        // Set up click handling (will be implemented via delegate)
        print("Added \(annotations.count) markers to map")
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
    
    private func hexStringToUIColor(_ hex: String) -> UIColor? {
        var hexString = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Remove # if present
        if hexString.hasPrefix("#") {
            hexString.removeFirst()
        }
        
        // Ensure we have 6 characters
        guard hexString.count == 6 else { return nil }
        
        var rgbValue: UInt64 = 0
        Scanner(string: hexString).scanHexInt64(&rgbValue)
        
        return UIColor(
            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
            alpha: 1.0
        )
    }
} 