import Foundation

@objc public class MarkerConfiguration: NSObject, Codable {
    @objc public var enableClustering: Bool
    @objc public var showDuringNavigation: Bool
    @objc public var showInFreeDrive: Bool
    @objc public var showOnEmbeddedMap: Bool
    @objc public var maxDistanceFromRoute: Double?
    @objc public var maxMarkersToShow: Int?
    @objc public var minZoomLevel: Double
    @objc public var maxZoomLevel: Double
    @objc public var onMarkerTapCallback: String?
    
    @objc public init(
        enableClustering: Bool = true,
        showDuringNavigation: Bool = true,
        showInFreeDrive: Bool = true,
        showOnEmbeddedMap: Bool = true,
        maxDistanceFromRoute: Double? = nil,
        maxMarkersToShow: Int? = nil,
        minZoomLevel: Double = 10.0,
        maxZoomLevel: Double = 20.0,
        onMarkerTapCallback: String? = nil
    ) {
        self.enableClustering = enableClustering
        self.showDuringNavigation = showDuringNavigation
        self.showInFreeDrive = showInFreeDrive
        self.showOnEmbeddedMap = showOnEmbeddedMap
        self.maxDistanceFromRoute = maxDistanceFromRoute
        self.maxMarkersToShow = maxMarkersToShow
        self.minZoomLevel = minZoomLevel
        self.maxZoomLevel = maxZoomLevel
        self.onMarkerTapCallback = onMarkerTapCallback
    }
    
    // MARK: - JSON Conversion
    
    @objc public func toJson() -> [String: Any] {
        var json: [String: Any] = [
            "enableClustering": enableClustering,
            "showDuringNavigation": showDuringNavigation,
            "showInFreeDrive": showInFreeDrive,
            "showOnEmbeddedMap": showOnEmbeddedMap,
            "minZoomLevel": minZoomLevel,
            "maxZoomLevel": maxZoomLevel
        ]
        
        if let maxDistanceFromRoute = maxDistanceFromRoute {
            json["maxDistanceFromRoute"] = maxDistanceFromRoute
        }
        
        if let maxMarkersToShow = maxMarkersToShow {
            json["maxMarkersToShow"] = maxMarkersToShow
        }
        
        if let onMarkerTapCallback = onMarkerTapCallback {
            json["onMarkerTapCallback"] = onMarkerTapCallback
        }
        
        return json
    }
    
    @objc public static func fromJson(_ json: [String: Any]) -> MarkerConfiguration {
        let enableClustering = json["enableClustering"] as? Bool ?? true
        let showDuringNavigation = json["showDuringNavigation"] as? Bool ?? true
        let showInFreeDrive = json["showInFreeDrive"] as? Bool ?? true
        let showOnEmbeddedMap = json["showOnEmbeddedMap"] as? Bool ?? true
        let maxDistanceFromRoute = json["maxDistanceFromRoute"] as? Double
        let maxMarkersToShow = json["maxMarkersToShow"] as? Int
        let minZoomLevel = json["minZoomLevel"] as? Double ?? 10.0
        let maxZoomLevel = json["maxZoomLevel"] as? Double ?? 20.0
        let onMarkerTapCallback = json["onMarkerTapCallback"] as? String
        
        return MarkerConfiguration(
            enableClustering: enableClustering,
            showDuringNavigation: showDuringNavigation,
            showInFreeDrive: showInFreeDrive,
            showOnEmbeddedMap: showOnEmbeddedMap,
            maxDistanceFromRoute: maxDistanceFromRoute,
            maxMarkersToShow: maxMarkersToShow,
            minZoomLevel: minZoomLevel,
            maxZoomLevel: maxZoomLevel,
            onMarkerTapCallback: onMarkerTapCallback
        )
    }
    
    // MARK: - Codable Implementation
    
    private enum CodingKeys: String, CodingKey {
        case enableClustering, showDuringNavigation, showInFreeDrive, showOnEmbeddedMap
        case maxDistanceFromRoute, maxMarkersToShow, minZoomLevel, maxZoomLevel, onMarkerTapCallback
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        enableClustering = try container.decode(Bool.self, forKey: .enableClustering)
        showDuringNavigation = try container.decode(Bool.self, forKey: .showDuringNavigation)
        showInFreeDrive = try container.decode(Bool.self, forKey: .showInFreeDrive)
        showOnEmbeddedMap = try container.decode(Bool.self, forKey: .showOnEmbeddedMap)
        maxDistanceFromRoute = try container.decodeIfPresent(Double.self, forKey: .maxDistanceFromRoute)
        maxMarkersToShow = try container.decodeIfPresent(Int.self, forKey: .maxMarkersToShow)
        minZoomLevel = try container.decode(Double.self, forKey: .minZoomLevel)
        maxZoomLevel = try container.decode(Double.self, forKey: .maxZoomLevel)
        onMarkerTapCallback = try container.decodeIfPresent(String.self, forKey: .onMarkerTapCallback)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(enableClustering, forKey: .enableClustering)
        try container.encode(showDuringNavigation, forKey: .showDuringNavigation)
        try container.encode(showInFreeDrive, forKey: .showInFreeDrive)
        try container.encode(showOnEmbeddedMap, forKey: .showOnEmbeddedMap)
        try container.encodeIfPresent(maxDistanceFromRoute, forKey: .maxDistanceFromRoute)
        try container.encodeIfPresent(maxMarkersToShow, forKey: .maxMarkersToShow)
        try container.encode(minZoomLevel, forKey: .minZoomLevel)
        try container.encode(maxZoomLevel, forKey: .maxZoomLevel)
        try container.encodeIfPresent(onMarkerTapCallback, forKey: .onMarkerTapCallback)
    }
} 