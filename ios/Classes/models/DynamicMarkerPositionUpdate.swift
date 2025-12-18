import Foundation

/// Represents a position update for a dynamic marker.
///
/// These updates are typically received from an external data source
/// (WebSocket, Firebase, MQTT, etc.) and converted to this format
/// before being passed to the marker manager.
@objc public class DynamicMarkerPositionUpdate: NSObject, Codable {
    /// The marker ID this update applies to.
    @objc public let markerId: String

    /// New latitude coordinate.
    @objc public let latitude: Double

    /// New longitude coordinate.
    @objc public let longitude: Double

    /// Timestamp when this position was recorded (ISO8601 string).
    @objc public let timestamp: String

    /// New heading in degrees (0-360, north = 0).
    public let heading: Double?

    /// Current speed in meters per second.
    public let speed: Double?

    /// Altitude in meters (for 3D tracking scenarios).
    public let altitude: Double?

    /// GPS accuracy in meters.
    public let accuracy: Double?

    /// Additional data associated with this update.
    public let additionalData: [String: Any]?

    public init(
        markerId: String,
        latitude: Double,
        longitude: Double,
        timestamp: String? = nil,
        heading: Double? = nil,
        speed: Double? = nil,
        altitude: Double? = nil,
        accuracy: Double? = nil,
        additionalData: [String: Any]? = nil
    ) {
        self.markerId = markerId
        self.latitude = latitude
        self.longitude = longitude
        self.timestamp = timestamp ?? ISO8601DateFormatter().string(from: Date())
        self.heading = heading
        self.speed = speed
        self.altitude = altitude
        self.accuracy = accuracy
        self.additionalData = additionalData
    }

    // MARK: - JSON Conversion

    public func toJson() -> [String: Any] {
        var json: [String: Any] = [
            "markerId": markerId,
            "latitude": latitude,
            "longitude": longitude,
            "timestamp": timestamp
        ]

        if let heading = heading {
            json["heading"] = heading
        }
        if let speed = speed {
            json["speed"] = speed
        }
        if let altitude = altitude {
            json["altitude"] = altitude
        }
        if let accuracy = accuracy {
            json["accuracy"] = accuracy
        }
        if let additionalData = additionalData {
            json["additionalData"] = additionalData
        }

        return json
    }

    public static func fromJson(_ json: [String: Any]) -> DynamicMarkerPositionUpdate? {
        guard let markerId = json["markerId"] as? String,
              let latitude = json["latitude"] as? Double,
              let longitude = json["longitude"] as? Double else {
            return nil
        }

        return DynamicMarkerPositionUpdate(
            markerId: markerId,
            latitude: latitude,
            longitude: longitude,
            timestamp: json["timestamp"] as? String,
            heading: json["heading"] as? Double,
            speed: json["speed"] as? Double,
            altitude: json["altitude"] as? Double,
            accuracy: json["accuracy"] as? Double,
            additionalData: json["additionalData"] as? [String: Any]
        )
    }

    /// Creates an update from a generic map with flexible key names.
    ///
    /// Supports various coordinate key names:
    /// - latitude/longitude
    /// - lat/lng
    /// - lat/lon
    public static func fromMap(_ map: [String: Any]) -> DynamicMarkerPositionUpdate? {
        // Extract marker ID
        guard let markerId = (map["markerId"] ?? map["id"]) as? String else {
            return nil
        }

        // Extract latitude - support multiple key names
        let lat = map["latitude"] ?? map["lat"]
        guard let latitude = (lat as? Double) ?? (lat as? NSNumber)?.doubleValue else {
            return nil
        }

        // Extract longitude - support multiple key names
        let lng = map["longitude"] ?? map["lng"] ?? map["lon"]
        guard let longitude = (lng as? Double) ?? (lng as? NSNumber)?.doubleValue else {
            return nil
        }

        // Parse timestamp
        let timestamp = map["timestamp"] as? String

        return DynamicMarkerPositionUpdate(
            markerId: markerId,
            latitude: latitude,
            longitude: longitude,
            timestamp: timestamp,
            heading: map["heading"] as? Double,
            speed: map["speed"] as? Double,
            altitude: map["altitude"] as? Double,
            accuracy: map["accuracy"] as? Double,
            additionalData: (map["data"] ?? map["additionalData"]) as? [String: Any]
        )
    }

    // MARK: - Codable Implementation

    private enum CodingKeys: String, CodingKey {
        case markerId, latitude, longitude, timestamp
        case heading, speed, altitude, accuracy, additionalData
    }

    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        markerId = try container.decode(String.self, forKey: .markerId)
        latitude = try container.decode(Double.self, forKey: .latitude)
        longitude = try container.decode(Double.self, forKey: .longitude)
        timestamp = try container.decode(String.self, forKey: .timestamp)
        heading = try container.decodeIfPresent(Double.self, forKey: .heading)
        speed = try container.decodeIfPresent(Double.self, forKey: .speed)
        altitude = try container.decodeIfPresent(Double.self, forKey: .altitude)
        accuracy = try container.decodeIfPresent(Double.self, forKey: .accuracy)
        additionalData = nil // [String: Any] is not Codable - skip decoding
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(markerId, forKey: .markerId)
        try container.encode(latitude, forKey: .latitude)
        try container.encode(longitude, forKey: .longitude)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encodeIfPresent(heading, forKey: .heading)
        try container.encodeIfPresent(speed, forKey: .speed)
        try container.encodeIfPresent(altitude, forKey: .altitude)
        try container.encodeIfPresent(accuracy, forKey: .accuracy)
        // additionalData is [String: Any] which is not Codable - skip encoding
    }

    // MARK: - Equality

    override public func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? DynamicMarkerPositionUpdate else { return false }
        return markerId == other.markerId && timestamp == other.timestamp
    }

    override public var hash: Int {
        return markerId.hashValue ^ timestamp.hashValue
    }

    override public var description: String {
        return "DynamicMarkerPositionUpdate(markerId='\(markerId)', lat=\(latitude), lng=\(longitude), timestamp=\(timestamp))"
    }
}
