import Foundation

/// Data structure representing the current trip progress.
///
/// This is used to update the trip progress overlay with current navigation state.
/// Matches the Android TripProgressData for cross-platform consistency.
public struct TripProgressData {
    /// Index of the current waypoint we're heading to (0-indexed)
    public let currentWaypointIndex: Int

    /// Total number of waypoints in the trip
    public let totalWaypoints: Int

    /// Name of the next waypoint/checkpoint
    public let nextWaypointName: String

    /// Category/type of the next waypoint (checkpoint, waypoint, poi, etc.)
    public let nextWaypointCategory: String

    /// Optional description of the next waypoint
    public let nextWaypointDescription: String?

    /// Icon ID for the next waypoint
    public let nextWaypointIconId: String?

    /// Distance remaining to the next waypoint in meters
    public let distanceToNextWaypoint: Double

    /// Duration remaining to the next waypoint in seconds
    public let durationToNextWaypoint: Double

    /// Distance remaining to the final destination in meters
    public let totalDistanceRemaining: Double

    /// Duration remaining to the final destination in seconds
    public let totalDurationRemaining: Double

    /// Whether this is a checkpoint (vs regular waypoint)
    public let isNextWaypointCheckpoint: Bool

    /// Initialize with all fields
    public init(
        currentWaypointIndex: Int,
        totalWaypoints: Int,
        nextWaypointName: String,
        nextWaypointCategory: String,
        nextWaypointDescription: String? = nil,
        nextWaypointIconId: String? = nil,
        distanceToNextWaypoint: Double,
        durationToNextWaypoint: Double = 0,
        totalDistanceRemaining: Double,
        totalDurationRemaining: Double,
        isNextWaypointCheckpoint: Bool
    ) {
        self.currentWaypointIndex = currentWaypointIndex
        self.totalWaypoints = totalWaypoints
        self.nextWaypointName = nextWaypointName
        self.nextWaypointCategory = nextWaypointCategory
        self.nextWaypointDescription = nextWaypointDescription
        self.nextWaypointIconId = nextWaypointIconId
        self.distanceToNextWaypoint = distanceToNextWaypoint
        self.durationToNextWaypoint = durationToNextWaypoint
        self.totalDistanceRemaining = totalDistanceRemaining
        self.totalDurationRemaining = totalDurationRemaining
        self.isNextWaypointCheckpoint = isNextWaypointCheckpoint
    }

    /// Get progress as a fraction (0.0 to 1.0)
    public var progressFraction: Float {
        if totalWaypoints > 1 {
            return Float(currentWaypointIndex) / Float(totalWaypoints - 1)
        }
        return 0
    }

    /// Get formatted progress string (e.g., "Waypoint 3/8")
    public var progressString: String {
        return "Waypoint \(currentWaypointIndex + 1)/\(totalWaypoints)"
    }

    /// Get formatted distance to next waypoint
    public func getFormattedDistanceToNext(useImperial: Bool = true) -> String {
        if useImperial {
            let miles = distanceToNextWaypoint / 1609.34
            if miles < 0.1 {
                let feet = distanceToNextWaypoint * 3.28084
                return "\(Int(feet)) ft"
            } else {
                return String(format: "%.1f mi", miles)
            }
        } else {
            if distanceToNextWaypoint < 1000 {
                return "\(Int(distanceToNextWaypoint)) m"
            } else {
                return String(format: "%.1f km", distanceToNextWaypoint / 1000)
            }
        }
    }

    /// Get formatted duration to next waypoint
    public func getFormattedDurationToNext() -> String {
        let totalMinutes = Int(durationToNextWaypoint / 60)
        if totalMinutes < 1 {
            return "< 1 min"
        } else if totalMinutes < 60 {
            return "~\(totalMinutes) min"
        } else {
            let hours = totalMinutes / 60
            let mins = totalMinutes % 60
            if mins > 0 {
                return "~\(hours)h \(mins)m"
            } else {
                return "~\(hours)h"
            }
        }
    }

    /// Get formatted total distance remaining
    public func getFormattedTotalDistanceRemaining(useImperial: Bool = true) -> String {
        if useImperial {
            let miles = totalDistanceRemaining / 1609.34
            if miles < 0.1 {
                let feet = totalDistanceRemaining * 3.28084
                return "\(Int(feet)) ft"
            } else {
                return String(format: "%.1f mi", miles)
            }
        } else {
            if totalDistanceRemaining < 1000 {
                return "\(Int(totalDistanceRemaining)) m"
            } else {
                return String(format: "%.1f km", totalDistanceRemaining / 1000)
            }
        }
    }

    /// Get formatted duration remaining
    public func getFormattedDurationRemaining() -> String {
        let totalMinutes = Int(totalDurationRemaining / 60)
        if totalMinutes < 60 {
            return "\(totalMinutes) min"
        } else {
            let hours = totalMinutes / 60
            let mins = totalMinutes % 60
            if mins > 0 {
                return "\(hours)h \(mins)m"
            } else {
                return "\(hours)h"
            }
        }
    }

    /// Get formatted ETA
    public func getFormattedEta() -> String {
        let arrivalDate = Date().addingTimeInterval(totalDurationRemaining)
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: arrivalDate)
    }
}
