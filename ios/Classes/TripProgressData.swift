import Foundation

/// Data structure representing the current trip progress.
///
/// This is used to update the trip progress overlay with current navigation state.
public struct TripProgressData {
    /// Index of the current waypoint we're heading to (0-indexed)
    let currentWaypointIndex: Int

    /// Total number of waypoints in the trip
    let totalWaypoints: Int

    /// Name of the next waypoint/checkpoint
    let nextWaypointName: String

    /// Category/type of the next waypoint (checkpoint, waypoint, poi, etc.)
    let nextWaypointCategory: String

    /// Optional description of the next waypoint
    let nextWaypointDescription: String?

    /// Icon ID for the next waypoint
    let nextWaypointIconId: String?

    /// Distance remaining to the next waypoint in meters
    let distanceToNextWaypoint: Double

    /// Distance remaining to the final destination in meters
    let totalDistanceRemaining: Double

    /// Duration remaining to the final destination in seconds
    let totalDurationRemaining: Double

    /// Whether this is a checkpoint (vs regular waypoint)
    let isNextWaypointCheckpoint: Bool

    /// Get progress as a fraction (0.0 to 1.0)
    var progressFraction: Float {
        if totalWaypoints > 1 {
            return Float(currentWaypointIndex) / Float(totalWaypoints - 1)
        }
        return 0
    }

    /// Get formatted progress string (e.g., "Stop 3/8")
    var progressString: String {
        return "Stop \(currentWaypointIndex + 1)/\(totalWaypoints)"
    }

    /// Get formatted distance to next waypoint
    func getFormattedDistanceToNext(useImperial: Bool = true) -> String {
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

    /// Get formatted duration remaining
    func getFormattedDurationRemaining() -> String {
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
}
