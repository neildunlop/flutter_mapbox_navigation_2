import Foundation
import MapboxMaps
import UIKit

@objc public class StaticMarker: NSObject, Codable {
    @objc public let id: String
    @objc public let latitude: Double
    @objc public let longitude: Double
    @objc public let title: String
    @objc public let category: String
    @objc public let markerDescription: String?
    @objc public let iconId: String?
    @objc public let customColor: String?
    @objc public let priority: Int
    @objc public let isVisible: Bool
    public let metadata: [String: Any]?
    
    @objc public init(
        id: String,
        latitude: Double,
        longitude: Double,
        title: String,
        category: String,
        markerDescription: String? = nil,
        iconId: String? = nil,
        customColor: String? = nil,
        priority: Int = 0,
        isVisible: Bool = true,
        metadata: [String: Any]? = nil
    ) {
        self.id = id
        self.latitude = latitude
        self.longitude = longitude
        self.title = title
        self.category = category
        self.markerDescription = markerDescription
        self.iconId = iconId
        self.customColor = customColor
        self.priority = priority
        self.isVisible = isVisible
        self.metadata = metadata
    }
    
    // MARK: - JSON Conversion

    public func toJson() -> [String: Any] {
        var json: [String: Any] = [
            "id": id,
            "latitude": latitude,
            "longitude": longitude,
            "title": title,
            "category": category,
            "priority": priority,
            "isVisible": isVisible
        ]

        if let markerDescription = markerDescription {
            json["description"] = markerDescription
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

        return json
    }

    public static func fromJson(_ json: [String: Any]) -> StaticMarker? {
        guard let id = json["id"] as? String,
              let latitude = json["latitude"] as? Double,
              let longitude = json["longitude"] as? Double,
              let title = json["title"] as? String,
              let category = json["category"] as? String else {
            return nil
        }

        let markerDescription = json["description"] as? String
        let iconId = json["iconId"] as? String
        let customColor = json["customColor"] as? String
        let priority = json["priority"] as? Int ?? 0
        let isVisible = json["isVisible"] as? Bool ?? true
        let metadata = json["metadata"] as? [String: Any]

        return StaticMarker(
            id: id,
            latitude: latitude,
            longitude: longitude,
            title: title,
            category: category,
            markerDescription: markerDescription,
            iconId: iconId,
            customColor: customColor,
            priority: priority,
            isVisible: isVisible,
            metadata: metadata
        )
    }
    
    // MARK: - Mapbox Integration

    public func toMapboxPoint() -> Point {
        return Point(CLLocationCoordinate2D(latitude: latitude, longitude: longitude))
    }
    
    @objc public func getDefaultIconId() -> String {
        return iconId ?? "ic_pin"
    }

    @objc public func getDefaultColor() -> String {
        return customColor ?? "#FF0000"
    }

    /// Gets the color for the marker, using custom color if available or category-based default.
    /// Colors aligned with app's design system: Primary: #2E6578 (teal), Checkpoint: #1565C0 (dark blue)
    @objc public func getMarkerColor() -> UIColor {
        // Use custom color if provided
        if let customColorHex = customColor, let color = UIColor(hex: customColorHex) {
            return color
        }

        // Use category-based default color
        return getDefaultColorForCategory()
    }

    private func getDefaultColorForCategory() -> UIColor {
        switch category.lowercased() {
        case "checkpoint":
            return UIColor(red: 0.08, green: 0.40, blue: 0.75, alpha: 1)  // #1565C0 Dark blue
        case "waypoint":
            return UIColor(red: 0.18, green: 0.40, blue: 0.47, alpha: 1)  // #2E6578 Primary teal
        case "scenic", "park", "beach", "mountain", "lake", "waterfall", "viewpoint", "hiking":
            return UIColor(red: 0.55, green: 0.76, blue: 0.29, alpha: 1)  // Light Green
        case "petrol_station", "charging_station", "parking":
            return UIColor(red: 0.38, green: 0.49, blue: 0.55, alpha: 1)  // Blue Grey
        case "restaurant", "cafe", "food":
            return UIColor(red: 1.0, green: 0.60, blue: 0.0, alpha: 1)    // Orange
        case "hotel", "accommodation":
            return UIColor(red: 0.36, green: 0.36, blue: 0.44, alpha: 1)  // Tertiary
        case "speed_camera", "accident", "construction", "warning":
            return UIColor(red: 0.96, green: 0.26, blue: 0.21, alpha: 1)  // Red
        case "hospital", "medical", "police", "fire_station":
            return UIColor(red: 0.13, green: 0.59, blue: 0.95, alpha: 1)  // Blue
        case "poi":
            return UIColor(red: 0.30, green: 0.69, blue: 0.31, alpha: 1)  // Green
        default:
            return UIColor(red: 0.18, green: 0.40, blue: 0.47, alpha: 1)  // Primary teal (default)
        }
    }
    
    // MARK: - Codable Implementation

    private enum CodingKeys: String, CodingKey {
        case id, latitude, longitude, title, category
        case markerDescription = "description"
        case iconId, customColor, priority, isVisible, metadata
    }

    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        latitude = try container.decode(Double.self, forKey: .latitude)
        longitude = try container.decode(Double.self, forKey: .longitude)
        title = try container.decode(String.self, forKey: .title)
        category = try container.decode(String.self, forKey: .category)
        markerDescription = try container.decodeIfPresent(String.self, forKey: .markerDescription)
        iconId = try container.decodeIfPresent(String.self, forKey: .iconId)
        customColor = try container.decodeIfPresent(String.self, forKey: .customColor)
        priority = try container.decode(Int.self, forKey: .priority)
        isVisible = try container.decode(Bool.self, forKey: .isVisible)
        metadata = nil // [String: Any] is not Codable - skip decoding
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(latitude, forKey: .latitude)
        try container.encode(longitude, forKey: .longitude)
        try container.encode(title, forKey: .title)
        try container.encode(category, forKey: .category)
        try container.encodeIfPresent(markerDescription, forKey: .markerDescription)
        try container.encodeIfPresent(iconId, forKey: .iconId)
        try container.encodeIfPresent(customColor, forKey: .customColor)
        try container.encode(priority, forKey: .priority)
        try container.encode(isVisible, forKey: .isVisible)
        // metadata is [String: Any] which is not Codable - skip encoding
    }
} 