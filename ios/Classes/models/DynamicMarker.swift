import Foundation
import MapboxMaps
import UIKit

/// Represents the current state of a dynamic marker.
@objc public enum DynamicMarkerState: Int, Codable {
    /// Marker is actively receiving position updates.
    case tracking = 0
    /// Marker is currently animating between positions.
    case animating = 1
    /// Entity has stopped moving (speed below threshold).
    case stationary = 2
    /// No update received within the stale threshold.
    case stale = 3
    /// No update received for an extended period.
    case offline = 4
    /// Marker is about to be automatically removed due to expiration.
    case expired = 5

    /// Creates a DynamicMarkerState from a string value.
    public static func fromString(_ value: String) -> DynamicMarkerState {
        switch value.lowercased() {
        case "tracking": return .tracking
        case "animating": return .animating
        case "stationary": return .stationary
        case "stale": return .stale
        case "offline": return .offline
        case "expired": return .expired
        default: return .tracking
        }
    }

    /// Returns the string representation for JSON serialization.
    public func toJsonString() -> String {
        switch self {
        case .tracking: return "tracking"
        case .animating: return "animating"
        case .stationary: return "stationary"
        case .stale: return "stale"
        case .offline: return "offline"
        case .expired: return "expired"
        }
    }
}

/// Represents a geographic coordinate with latitude and longitude.
@objc public class LatLng: NSObject, Codable {
    @objc public let latitude: Double
    @objc public let longitude: Double

    @objc public init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }

    @objc public static func fromJson(_ json: [String: Any]) -> LatLng? {
        guard let latitude = json["latitude"] as? Double,
              let longitude = json["longitude"] as? Double else {
            return nil
        }
        return LatLng(latitude: latitude, longitude: longitude)
    }

    @objc public func toJson() -> [String: Any] {
        return [
            "latitude": latitude,
            "longitude": longitude
        ]
    }
}

/// Represents a marker that can move and animate across the map.
///
/// Dynamic markers are used for tracking real-time entities like vehicles,
/// drones, or other moving objects. The marker's position can be smoothly
/// animated between updates.
@objc public class DynamicMarker: NSObject, Codable {
    /// Unique identifier for this marker.
    @objc public let id: String

    /// Current latitude coordinate.
    @objc public var latitude: Double

    /// Current longitude coordinate.
    @objc public var longitude: Double

    /// Display title for the marker.
    @objc public let title: String

    /// Category string for grouping and default styling.
    @objc public let category: String

    /// Previous latitude coordinate (used for interpolation).
    public var previousLatitude: Double?

    /// Previous longitude coordinate (used for interpolation).
    public var previousLongitude: Double?

    /// Current heading/bearing in degrees (0-360, where 0 = north).
    public var heading: Double?

    /// Current speed in meters per second.
    public var speed: Double?

    /// Timestamp of the last position update (ISO8601 string).
    @objc public var lastUpdated: String?

    /// Icon identifier from the standard marker icon set.
    @objc public let iconId: String?

    /// Custom color for the marker (hex string).
    @objc public let customColor: String?

    /// Arbitrary metadata associated with this marker.
    public let metadata: [String: Any]?

    /// Current state of the marker.
    @objc public var state: DynamicMarkerState

    /// Whether to render a trail/breadcrumb behind this marker.
    @objc public var showTrail: Bool

    /// Maximum number of trail points to retain.
    @objc public var trailLength: Int

    /// Historical positions for trail rendering.
    public var positionHistory: [LatLng]?

    public init(
        id: String,
        latitude: Double,
        longitude: Double,
        title: String,
        category: String,
        previousLatitude: Double? = nil,
        previousLongitude: Double? = nil,
        heading: Double? = nil,
        speed: Double? = nil,
        lastUpdated: String? = nil,
        iconId: String? = nil,
        customColor: String? = nil,
        metadata: [String: Any]? = nil,
        state: DynamicMarkerState = .tracking,
        showTrail: Bool = false,
        trailLength: Int = 50,
        positionHistory: [LatLng]? = nil
    ) {
        self.id = id
        self.latitude = latitude
        self.longitude = longitude
        self.title = title
        self.category = category
        self.previousLatitude = previousLatitude
        self.previousLongitude = previousLongitude
        self.heading = heading
        self.speed = speed
        self.lastUpdated = lastUpdated ?? ISO8601DateFormatter().string(from: Date())
        self.iconId = iconId
        self.customColor = customColor
        self.metadata = metadata
        self.state = state
        self.showTrail = showTrail
        self.trailLength = trailLength
        self.positionHistory = positionHistory
    }

    // MARK: - Computed Properties

    /// Returns the current position as a MapboxMaps Point.
    public func toMapboxPoint() -> Point {
        return Point(CLLocationCoordinate2D(latitude: latitude, longitude: longitude))
    }

    /// Returns the previous position as a LatLng, or nil if not set.
    public var previousPosition: LatLng? {
        guard let prevLat = previousLatitude, let prevLng = previousLongitude else {
            return nil
        }
        return LatLng(latitude: prevLat, longitude: prevLng)
    }

    // MARK: - JSON Conversion

    public func toJson() -> [String: Any] {
        var json: [String: Any] = [
            "id": id,
            "latitude": latitude,
            "longitude": longitude,
            "title": title,
            "category": category,
            "state": state.toJsonString(),
            "showTrail": showTrail,
            "trailLength": trailLength
        ]

        if let previousLatitude = previousLatitude {
            json["previousLatitude"] = previousLatitude
        }
        if let previousLongitude = previousLongitude {
            json["previousLongitude"] = previousLongitude
        }
        if let heading = heading {
            json["heading"] = heading
        }
        if let speed = speed {
            json["speed"] = speed
        }
        if let lastUpdated = lastUpdated {
            json["lastUpdated"] = lastUpdated
        }
        if let iconId = iconId {
            json["iconId"] = iconId
        }
        if let customColor = customColor {
            json["customColor"] = customColor
        }
        if let metadata = metadata {
            json["metadata"] = metadata
        }
        if let positionHistory = positionHistory {
            json["positionHistory"] = positionHistory.map { $0.toJson() }
        }

        return json
    }

    @objc public static func fromJson(_ json: [String: Any]) -> DynamicMarker? {
        guard let id = json["id"] as? String,
              let latitude = json["latitude"] as? Double,
              let longitude = json["longitude"] as? Double,
              let title = json["title"] as? String,
              let category = json["category"] as? String else {
            return nil
        }

        var positionHistory: [LatLng]? = nil
        if let historyArray = json["positionHistory"] as? [[String: Any]] {
            positionHistory = historyArray.compactMap { LatLng.fromJson($0) }
        }

        let stateValue = json["state"] as? String ?? "tracking"

        return DynamicMarker(
            id: id,
            latitude: latitude,
            longitude: longitude,
            title: title,
            category: category,
            previousLatitude: json["previousLatitude"] as? Double,
            previousLongitude: json["previousLongitude"] as? Double,
            heading: json["heading"] as? Double,
            speed: json["speed"] as? Double,
            lastUpdated: json["lastUpdated"] as? String,
            iconId: json["iconId"] as? String,
            customColor: json["customColor"] as? String,
            metadata: json["metadata"] as? [String: Any],
            state: DynamicMarkerState.fromString(stateValue),
            showTrail: json["showTrail"] as? Bool ?? false,
            trailLength: json["trailLength"] as? Int ?? 50,
            positionHistory: positionHistory
        )
    }

    // MARK: - Position Update

    /// Creates a copy with an updated position.
    public func withPosition(
        newLatitude: Double,
        newLongitude: Double,
        newHeading: Double? = nil,
        newSpeed: Double? = nil,
        timestamp: String? = nil
    ) -> DynamicMarker {
        // Build new position history
        var newHistory = positionHistory ?? []
        newHistory.append(LatLng(latitude: latitude, longitude: longitude))

        // Trim to max trail length
        while newHistory.count > trailLength {
            newHistory.removeFirst()
        }

        return DynamicMarker(
            id: id,
            latitude: newLatitude,
            longitude: newLongitude,
            title: title,
            category: category,
            previousLatitude: latitude,
            previousLongitude: longitude,
            heading: newHeading ?? heading,
            speed: newSpeed ?? speed,
            lastUpdated: timestamp ?? ISO8601DateFormatter().string(from: Date()),
            iconId: iconId,
            customColor: customColor,
            metadata: metadata,
            state: .tracking,
            showTrail: showTrail,
            trailLength: trailLength,
            positionHistory: showTrail ? newHistory : nil
        )
    }

    // MARK: - Color

    /// Gets the marker color, using custom color if available.
    @objc public func getMarkerColor() -> UIColor {
        if let customColorHex = customColor, let color = UIColor(hex: customColorHex) {
            return color
        }
        return getDefaultColorForCategory()
    }

    private func getDefaultColorForCategory() -> UIColor {
        switch category.lowercased() {
        case "vehicle", "car", "truck", "bus":
            return UIColor(red: 0.13, green: 0.59, blue: 0.95, alpha: 1) // Blue
        case "drone", "aircraft", "plane", "helicopter":
            return UIColor(red: 0.61, green: 0.15, blue: 0.69, alpha: 1) // Purple
        case "person", "pedestrian", "runner", "cyclist":
            return UIColor(red: 0.30, green: 0.69, blue: 0.31, alpha: 1) // Green
        case "delivery", "courier", "package":
            return UIColor(red: 1.0, green: 0.60, blue: 0.0, alpha: 1) // Orange
        case "emergency", "ambulance", "police", "fire":
            return UIColor(red: 0.96, green: 0.26, blue: 0.21, alpha: 1) // Red
        case "transit", "train", "subway", "tram":
            return UIColor(red: 0.0, green: 0.74, blue: 0.83, alpha: 1) // Cyan
        case "boat", "ship", "vessel":
            return UIColor(red: 0.25, green: 0.32, blue: 0.71, alpha: 1) // Indigo
        default:
            return UIColor(red: 0.18, green: 0.40, blue: 0.47, alpha: 1) // Primary teal
        }
    }

    /// Gets the icon resource name for the marker.
    @objc public func getIconResourceName() -> String {
        return iconId ?? getDefaultIconForCategory()
    }

    private func getDefaultIconForCategory() -> String {
        switch category.lowercased() {
        case "vehicle", "car": return "ic_vehicle"
        case "truck": return "ic_truck"
        case "bus": return "ic_bus"
        case "drone": return "ic_drone"
        case "aircraft", "plane": return "ic_aircraft"
        case "helicopter": return "ic_helicopter"
        case "person", "pedestrian": return "ic_person"
        case "runner": return "ic_runner"
        case "cyclist": return "ic_cyclist"
        case "delivery", "courier": return "ic_delivery"
        case "emergency", "ambulance": return "ic_ambulance"
        case "police": return "ic_police"
        case "fire": return "ic_fire_station"
        case "transit", "train": return "ic_train"
        case "subway": return "ic_subway"
        case "boat", "ship": return "ic_boat"
        default: return "ic_marker_dynamic"
        }
    }

    // MARK: - Codable Implementation

    private enum CodingKeys: String, CodingKey {
        case id, latitude, longitude, title, category
        case previousLatitude, previousLongitude, heading, speed, lastUpdated
        case iconId, customColor, metadata, state, showTrail, trailLength, positionHistory
    }

    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        latitude = try container.decode(Double.self, forKey: .latitude)
        longitude = try container.decode(Double.self, forKey: .longitude)
        title = try container.decode(String.self, forKey: .title)
        category = try container.decode(String.self, forKey: .category)
        previousLatitude = try container.decodeIfPresent(Double.self, forKey: .previousLatitude)
        previousLongitude = try container.decodeIfPresent(Double.self, forKey: .previousLongitude)
        heading = try container.decodeIfPresent(Double.self, forKey: .heading)
        speed = try container.decodeIfPresent(Double.self, forKey: .speed)
        lastUpdated = try container.decodeIfPresent(String.self, forKey: .lastUpdated)
        iconId = try container.decodeIfPresent(String.self, forKey: .iconId)
        customColor = try container.decodeIfPresent(String.self, forKey: .customColor)
        metadata = nil // [String: Any] is not Codable - skip decoding
        state = try container.decodeIfPresent(DynamicMarkerState.self, forKey: .state) ?? .tracking
        showTrail = try container.decodeIfPresent(Bool.self, forKey: .showTrail) ?? false
        trailLength = try container.decodeIfPresent(Int.self, forKey: .trailLength) ?? 50
        positionHistory = try container.decodeIfPresent([LatLng].self, forKey: .positionHistory)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(latitude, forKey: .latitude)
        try container.encode(longitude, forKey: .longitude)
        try container.encode(title, forKey: .title)
        try container.encode(category, forKey: .category)
        try container.encodeIfPresent(previousLatitude, forKey: .previousLatitude)
        try container.encodeIfPresent(previousLongitude, forKey: .previousLongitude)
        try container.encodeIfPresent(heading, forKey: .heading)
        try container.encodeIfPresent(speed, forKey: .speed)
        try container.encodeIfPresent(lastUpdated, forKey: .lastUpdated)
        try container.encodeIfPresent(iconId, forKey: .iconId)
        try container.encodeIfPresent(customColor, forKey: .customColor)
        // metadata is [String: Any] which is not Codable - skip encoding
        try container.encode(state, forKey: .state)
        try container.encode(showTrail, forKey: .showTrail)
        try container.encode(trailLength, forKey: .trailLength)
        try container.encodeIfPresent(positionHistory, forKey: .positionHistory)
    }

    // MARK: - Equality

    override public func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? DynamicMarker else { return false }
        return id == other.id
    }

    override public var hash: Int {
        return id.hashValue
    }

    override public var description: String {
        return "DynamicMarker(id='\(id)', title='\(title)', category='\(category)', lat=\(latitude), lng=\(longitude), state=\(state.toJsonString()))"
    }
}
