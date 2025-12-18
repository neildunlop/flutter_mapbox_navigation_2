import Foundation
import UIKit

/// Configuration for the dynamic marker system.
///
/// This configuration controls animation, state thresholds, trail rendering,
/// prediction behavior, and display settings for dynamic markers.
@objc public class DynamicMarkerConfiguration: NSObject, Codable {
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
    @objc public let animationDurationMs: Int

    /// Enable smooth animation between positions.
    ///
    /// When false, markers jump instantly to new positions.
    /// Default: true
    @objc public let enableAnimation: Bool

    /// Enable rotation animation for heading changes.
    ///
    /// When true, markers smoothly rotate to face their heading.
    /// Default: true
    @objc public let animateHeading: Bool

    // ---------------------------------------------------------------------------
    // State Thresholds
    // ---------------------------------------------------------------------------

    /// Time without updates before marking as stale (milliseconds).
    ///
    /// Default: 10000ms (10 seconds)
    @objc public let staleThresholdMs: Int

    /// Time without updates before marking as offline (milliseconds).
    ///
    /// Default: 30000ms (30 seconds)
    @objc public let offlineThresholdMs: Int

    /// Time without updates before auto-removing marker (milliseconds).
    ///
    /// Set to nil to disable auto-expiration.
    /// Default: nil (no auto-expiration)
    @objc public let expiredThresholdMs: Int

    /// Speed threshold below which entity is considered stationary (m/s).
    ///
    /// Default: 0.5 m/s (~1.8 km/h)
    @objc public let stationarySpeedThreshold: Double

    /// Duration at low speed before marking stationary (milliseconds).
    ///
    /// Default: 30000ms (30 seconds)
    @objc public let stationaryDurationMs: Int

    // ---------------------------------------------------------------------------
    // Trail/Breadcrumb Settings
    // ---------------------------------------------------------------------------

    /// Enable trail rendering by default for new markers.
    ///
    /// Individual markers can override via [DynamicMarker.showTrail].
    /// Default: false
    @objc public let enableTrail: Bool

    /// Maximum number of trail points per marker.
    ///
    /// Default: 50
    @objc public let maxTrailPoints: Int

    /// Trail line color (ARGB integer).
    ///
    /// Default: Blue with 50% opacity
    @objc public let trailColor: Int

    /// Trail line width in logical pixels.
    ///
    /// Default: 3.0
    @objc public let trailWidth: Double

    /// Enable gradient fade on trail (solid at marker, transparent at end).
    ///
    /// Default: true
    @objc public let trailGradient: Bool

    /// Minimum distance between trail points in meters.
    ///
    /// Prevents dense clustering when stationary.
    /// Default: 5.0
    @objc public let minTrailPointDistance: Double

    // ---------------------------------------------------------------------------
    // Prediction Settings
    // ---------------------------------------------------------------------------

    /// Enable dead-reckoning prediction when updates are delayed.
    ///
    /// When enabled, the marker continues moving based on last known
    /// speed and heading until a new update arrives.
    /// Default: true
    @objc public let enablePrediction: Bool

    /// Maximum prediction window in milliseconds.
    ///
    /// Prediction stops after this duration without an update.
    /// Default: 2000ms
    @objc public let predictionWindowMs: Int

    // ---------------------------------------------------------------------------
    // Label Settings
    // ---------------------------------------------------------------------------

    /// Enable text labels below markers.
    ///
    /// When true, displays the marker title as a label below the icon.
    /// Default: false
    @objc public let showLabels: Bool

    /// Label text size in logical pixels.
    ///
    /// Default: 12.0
    @objc public let labelTextSize: Double

    /// Label text color (ARGB integer).
    ///
    /// Default: White (0xFFFFFFFF)
    @objc public let labelTextColor: Int

    /// Label background/halo color (ARGB integer).
    ///
    /// Default: Dark gray with opacity (0xCC333333)
    @objc public let labelHaloColor: Int

    /// Label halo width in logical pixels.
    ///
    /// Default: 1.5
    @objc public let labelHaloWidth: Double

    /// Vertical offset of label from marker icon.
    ///
    /// Positive values move label down.
    /// Default: 1.5
    @objc public let labelOffsetY: Double

    // ---------------------------------------------------------------------------
    // Display Settings
    // ---------------------------------------------------------------------------

    /// Z-index for dynamic markers (relative to static markers).
    ///
    /// Higher values render above lower values.
    /// Default: 100 (above default static markers at 0)
    @objc public let zIndex: Int

    /// Minimum zoom level for marker visibility.
    ///
    /// Default: 0.0 (always visible)
    @objc public let minZoomLevel: Double

    /// Maximum distance from map center before hiding (kilometers).
    ///
    /// nil = no limit
    /// Default: nil
    @objc public let maxDistanceFromCenter: Double

    @objc public init(
        animationDurationMs: Int = 1000,
        enableAnimation: Bool = true,
        animateHeading: Bool = true,
        staleThresholdMs: Int = 10000,
        offlineThresholdMs: Int = 30000,
        expiredThresholdMs: Int = -1, // -1 means nil/disabled
        stationarySpeedThreshold: Double = 0.5,
        stationaryDurationMs: Int = 30000,
        enableTrail: Bool = false,
        maxTrailPoints: Int = 50,
        trailColor: Int = 0x7F2196F3,
        trailWidth: Double = 3.0,
        trailGradient: Bool = true,
        minTrailPointDistance: Double = 5.0,
        enablePrediction: Bool = true,
        predictionWindowMs: Int = 2000,
        showLabels: Bool = false,
        labelTextSize: Double = 12.0,
        labelTextColor: Int = Int(bitPattern: 0xFFFFFFFF),
        labelHaloColor: Int = Int(bitPattern: 0xCC333333),
        labelHaloWidth: Double = 1.5,
        labelOffsetY: Double = 1.5,
        zIndex: Int = 100,
        minZoomLevel: Double = 0.0,
        maxDistanceFromCenter: Double = -1.0 // -1 means nil/no limit
    ) {
        self.animationDurationMs = animationDurationMs
        self.enableAnimation = enableAnimation
        self.animateHeading = animateHeading
        self.staleThresholdMs = staleThresholdMs
        self.offlineThresholdMs = offlineThresholdMs
        self.expiredThresholdMs = expiredThresholdMs
        self.stationarySpeedThreshold = stationarySpeedThreshold
        self.stationaryDurationMs = stationaryDurationMs
        self.enableTrail = enableTrail
        self.maxTrailPoints = maxTrailPoints
        self.trailColor = trailColor
        self.trailWidth = trailWidth
        self.trailGradient = trailGradient
        self.minTrailPointDistance = minTrailPointDistance
        self.enablePrediction = enablePrediction
        self.predictionWindowMs = predictionWindowMs
        self.showLabels = showLabels
        self.labelTextSize = labelTextSize
        self.labelTextColor = labelTextColor
        self.labelHaloColor = labelHaloColor
        self.labelHaloWidth = labelHaloWidth
        self.labelOffsetY = labelOffsetY
        self.zIndex = zIndex
        self.minZoomLevel = minZoomLevel
        self.maxDistanceFromCenter = maxDistanceFromCenter

        // Validate configuration values
        precondition(animationDurationMs > 0, "animationDurationMs must be positive")
        precondition(trailWidth > 0, "trailWidth must be positive")
        precondition(labelTextSize > 0, "labelTextSize must be positive")
        precondition(labelHaloWidth >= 0, "labelHaloWidth must be non-negative")
    }

    /// Default configuration instance.
    @objc public static let `default` = DynamicMarkerConfiguration()

    // MARK: - Helper Methods

    /// Returns the expired threshold as an optional.
    public var expiredThresholdMsOptional: Int? {
        return expiredThresholdMs > 0 ? expiredThresholdMs : nil
    }

    /// Returns the max distance as an optional.
    public var maxDistanceFromCenterOptional: Double? {
        return maxDistanceFromCenter > 0 ? maxDistanceFromCenter : nil
    }

    /// Returns the trail color as a UIColor.
    @objc public var trailUIColor: UIColor {
        let alpha = CGFloat((trailColor >> 24) & 0xFF) / 255.0
        let red = CGFloat((trailColor >> 16) & 0xFF) / 255.0
        let green = CGFloat((trailColor >> 8) & 0xFF) / 255.0
        let blue = CGFloat(trailColor & 0xFF) / 255.0
        return UIColor(red: red, green: green, blue: blue, alpha: alpha)
    }

    // MARK: - JSON Conversion

    @objc public func toJson() -> [String: Any] {
        return [
            "animationDurationMs": animationDurationMs,
            "enableAnimation": enableAnimation,
            "animateHeading": animateHeading,
            "staleThresholdMs": staleThresholdMs,
            "offlineThresholdMs": offlineThresholdMs,
            "expiredThresholdMs": expiredThresholdMs > 0 ? expiredThresholdMs : NSNull(),
            "stationarySpeedThreshold": stationarySpeedThreshold,
            "stationaryDurationMs": stationaryDurationMs,
            "enableTrail": enableTrail,
            "maxTrailPoints": maxTrailPoints,
            "trailColor": trailColor,
            "trailWidth": trailWidth,
            "trailGradient": trailGradient,
            "minTrailPointDistance": minTrailPointDistance,
            "enablePrediction": enablePrediction,
            "predictionWindowMs": predictionWindowMs,
            "showLabels": showLabels,
            "labelTextSize": labelTextSize,
            "labelTextColor": labelTextColor,
            "labelHaloColor": labelHaloColor,
            "labelHaloWidth": labelHaloWidth,
            "labelOffsetY": labelOffsetY,
            "zIndex": zIndex,
            "minZoomLevel": minZoomLevel,
            "maxDistanceFromCenter": maxDistanceFromCenter > 0 ? maxDistanceFromCenter : NSNull()
        ]
    }

    @objc public static func fromJson(_ json: [String: Any]) -> DynamicMarkerConfiguration {
        return DynamicMarkerConfiguration(
            animationDurationMs: json["animationDurationMs"] as? Int ?? 1000,
            enableAnimation: json["enableAnimation"] as? Bool ?? true,
            animateHeading: json["animateHeading"] as? Bool ?? true,
            staleThresholdMs: json["staleThresholdMs"] as? Int ?? 10000,
            offlineThresholdMs: json["offlineThresholdMs"] as? Int ?? 30000,
            expiredThresholdMs: json["expiredThresholdMs"] as? Int ?? -1,
            stationarySpeedThreshold: json["stationarySpeedThreshold"] as? Double ?? 0.5,
            stationaryDurationMs: json["stationaryDurationMs"] as? Int ?? 30000,
            enableTrail: json["enableTrail"] as? Bool ?? false,
            maxTrailPoints: json["maxTrailPoints"] as? Int ?? 50,
            trailColor: json["trailColor"] as? Int ?? 0x7F2196F3,
            trailWidth: json["trailWidth"] as? Double ?? 3.0,
            trailGradient: json["trailGradient"] as? Bool ?? true,
            minTrailPointDistance: json["minTrailPointDistance"] as? Double ?? 5.0,
            enablePrediction: json["enablePrediction"] as? Bool ?? true,
            predictionWindowMs: json["predictionWindowMs"] as? Int ?? 2000,
            showLabels: json["showLabels"] as? Bool ?? false,
            labelTextSize: json["labelTextSize"] as? Double ?? 12.0,
            labelTextColor: json["labelTextColor"] as? Int ?? Int(bitPattern: 0xFFFFFFFF),
            labelHaloColor: json["labelHaloColor"] as? Int ?? Int(bitPattern: 0xCC333333),
            labelHaloWidth: json["labelHaloWidth"] as? Double ?? 1.5,
            labelOffsetY: json["labelOffsetY"] as? Double ?? 1.5,
            zIndex: json["zIndex"] as? Int ?? 100,
            minZoomLevel: json["minZoomLevel"] as? Double ?? 0.0,
            maxDistanceFromCenter: json["maxDistanceFromCenter"] as? Double ?? -1.0
        )
    }

    // MARK: - Codable Implementation

    private enum CodingKeys: String, CodingKey {
        case animationDurationMs, enableAnimation, animateHeading
        case staleThresholdMs, offlineThresholdMs, expiredThresholdMs
        case stationarySpeedThreshold, stationaryDurationMs
        case enableTrail, maxTrailPoints, trailColor, trailWidth, trailGradient, minTrailPointDistance
        case enablePrediction, predictionWindowMs
        case showLabels, labelTextSize, labelTextColor, labelHaloColor, labelHaloWidth, labelOffsetY
        case zIndex, minZoomLevel, maxDistanceFromCenter
    }

    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        animationDurationMs = try container.decodeIfPresent(Int.self, forKey: .animationDurationMs) ?? 1000
        enableAnimation = try container.decodeIfPresent(Bool.self, forKey: .enableAnimation) ?? true
        animateHeading = try container.decodeIfPresent(Bool.self, forKey: .animateHeading) ?? true
        staleThresholdMs = try container.decodeIfPresent(Int.self, forKey: .staleThresholdMs) ?? 10000
        offlineThresholdMs = try container.decodeIfPresent(Int.self, forKey: .offlineThresholdMs) ?? 30000
        expiredThresholdMs = try container.decodeIfPresent(Int.self, forKey: .expiredThresholdMs) ?? -1
        stationarySpeedThreshold = try container.decodeIfPresent(Double.self, forKey: .stationarySpeedThreshold) ?? 0.5
        stationaryDurationMs = try container.decodeIfPresent(Int.self, forKey: .stationaryDurationMs) ?? 30000
        enableTrail = try container.decodeIfPresent(Bool.self, forKey: .enableTrail) ?? false
        maxTrailPoints = try container.decodeIfPresent(Int.self, forKey: .maxTrailPoints) ?? 50
        trailColor = try container.decodeIfPresent(Int.self, forKey: .trailColor) ?? 0x7F2196F3
        trailWidth = try container.decodeIfPresent(Double.self, forKey: .trailWidth) ?? 3.0
        trailGradient = try container.decodeIfPresent(Bool.self, forKey: .trailGradient) ?? true
        minTrailPointDistance = try container.decodeIfPresent(Double.self, forKey: .minTrailPointDistance) ?? 5.0
        enablePrediction = try container.decodeIfPresent(Bool.self, forKey: .enablePrediction) ?? true
        predictionWindowMs = try container.decodeIfPresent(Int.self, forKey: .predictionWindowMs) ?? 2000
        showLabels = try container.decodeIfPresent(Bool.self, forKey: .showLabels) ?? false
        labelTextSize = try container.decodeIfPresent(Double.self, forKey: .labelTextSize) ?? 12.0
        labelTextColor = try container.decodeIfPresent(Int.self, forKey: .labelTextColor) ?? Int(bitPattern: 0xFFFFFFFF)
        labelHaloColor = try container.decodeIfPresent(Int.self, forKey: .labelHaloColor) ?? Int(bitPattern: 0xCC333333)
        labelHaloWidth = try container.decodeIfPresent(Double.self, forKey: .labelHaloWidth) ?? 1.5
        labelOffsetY = try container.decodeIfPresent(Double.self, forKey: .labelOffsetY) ?? 1.5
        zIndex = try container.decodeIfPresent(Int.self, forKey: .zIndex) ?? 100
        minZoomLevel = try container.decodeIfPresent(Double.self, forKey: .minZoomLevel) ?? 0.0
        maxDistanceFromCenter = try container.decodeIfPresent(Double.self, forKey: .maxDistanceFromCenter) ?? -1.0
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(animationDurationMs, forKey: .animationDurationMs)
        try container.encode(enableAnimation, forKey: .enableAnimation)
        try container.encode(animateHeading, forKey: .animateHeading)
        try container.encode(staleThresholdMs, forKey: .staleThresholdMs)
        try container.encode(offlineThresholdMs, forKey: .offlineThresholdMs)
        try container.encode(expiredThresholdMs, forKey: .expiredThresholdMs)
        try container.encode(stationarySpeedThreshold, forKey: .stationarySpeedThreshold)
        try container.encode(stationaryDurationMs, forKey: .stationaryDurationMs)
        try container.encode(enableTrail, forKey: .enableTrail)
        try container.encode(maxTrailPoints, forKey: .maxTrailPoints)
        try container.encode(trailColor, forKey: .trailColor)
        try container.encode(trailWidth, forKey: .trailWidth)
        try container.encode(trailGradient, forKey: .trailGradient)
        try container.encode(minTrailPointDistance, forKey: .minTrailPointDistance)
        try container.encode(enablePrediction, forKey: .enablePrediction)
        try container.encode(predictionWindowMs, forKey: .predictionWindowMs)
        try container.encode(showLabels, forKey: .showLabels)
        try container.encode(labelTextSize, forKey: .labelTextSize)
        try container.encode(labelTextColor, forKey: .labelTextColor)
        try container.encode(labelHaloColor, forKey: .labelHaloColor)
        try container.encode(labelHaloWidth, forKey: .labelHaloWidth)
        try container.encode(labelOffsetY, forKey: .labelOffsetY)
        try container.encode(zIndex, forKey: .zIndex)
        try container.encode(minZoomLevel, forKey: .minZoomLevel)
        try container.encode(maxDistanceFromCenter, forKey: .maxDistanceFromCenter)
    }

    override public var description: String {
        return "DynamicMarkerConfiguration(animationDurationMs=\(animationDurationMs), enableAnimation=\(enableAnimation), enableTrail=\(enableTrail), staleThresholdMs=\(staleThresholdMs))"
    }
}
