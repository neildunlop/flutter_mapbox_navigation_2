import Foundation
import MapboxMaps

@objc public class StaticMarker: NSObject, Codable {
    @objc public let id: String
    @objc public let latitude: Double
    @objc public let longitude: Double
    @objc public let title: String
    @objc public let category: String
    @objc public let description: String?
    @objc public let iconId: String?
    @objc public let customColor: String?
    @objc public let priority: Int
    @objc public let isVisible: Bool
    @objc public let metadata: [String: Any]?
    
    @objc public init(
        id: String,
        latitude: Double,
        longitude: Double,
        title: String,
        category: String,
        description: String? = nil,
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
        self.description = description
        self.iconId = iconId
        self.customColor = customColor
        self.priority = priority
        self.isVisible = isVisible
        self.metadata = metadata
    }
    
    // MARK: - JSON Conversion
    
    @objc public func toJson() -> [String: Any] {
        var json: [String: Any] = [
            "id": id,
            "latitude": latitude,
            "longitude": longitude,
            "title": title,
            "category": category,
            "priority": priority,
            "isVisible": isVisible
        ]
        
        if let description = description {
            json["description"] = description
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
    
    @objc public static func fromJson(_ json: [String: Any]) -> StaticMarker? {
        guard let id = json["id"] as? String,
              let latitude = json["latitude"] as? Double,
              let longitude = json["longitude"] as? Double,
              let title = json["title"] as? String,
              let category = json["category"] as? String else {
            return nil
        }
        
        let description = json["description"] as? String
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
            description: description,
            iconId: iconId,
            customColor: customColor,
            priority: priority,
            isVisible: isVisible,
            metadata: metadata
        )
    }
    
    // MARK: - Mapbox Integration
    
    @objc public func toMapboxPoint() -> Point {
        return Point(CLLocationCoordinate2D(latitude: latitude, longitude: longitude))
    }
    
    @objc public func getDefaultIconId() -> String {
        return iconId ?? "ic_pin"
    }
    
    @objc public func getDefaultColor() -> String {
        return customColor ?? "#FF0000"
    }
    
    // MARK: - Codable Implementation
    
    private enum CodingKeys: String, CodingKey {
        case id, latitude, longitude, title, category, description, iconId, customColor, priority, isVisible, metadata
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        latitude = try container.decode(Double.self, forKey: .latitude)
        longitude = try container.decode(Double.self, forKey: .longitude)
        title = try container.decode(String.self, forKey: .title)
        category = try container.decode(String.self, forKey: .category)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        iconId = try container.decodeIfPresent(String.self, forKey: .iconId)
        customColor = try container.decodeIfPresent(String.self, forKey: .customColor)
        priority = try container.decode(Int.self, forKey: .priority)
        isVisible = try container.decode(Bool.self, forKey: .isVisible)
        metadata = try container.decodeIfPresent([String: Any].self, forKey: .metadata)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(latitude, forKey: .latitude)
        try container.encode(longitude, forKey: .longitude)
        try container.encode(title, forKey: .title)
        try container.encode(category, forKey: .category)
        try container.encodeIfPresent(description, forKey: .description)
        try container.encodeIfPresent(iconId, forKey: .iconId)
        try container.encodeIfPresent(customColor, forKey: .customColor)
        try container.encode(priority, forKey: .priority)
        try container.encode(isVisible, forKey: .isVisible)
        try container.encodeIfPresent(metadata, forKey: .metadata)
    }
} 