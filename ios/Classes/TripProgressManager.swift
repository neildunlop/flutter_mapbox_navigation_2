import Foundation
import MapboxDirections

/// Callback type for progress updates
public typealias TripProgressListener = (TripProgressData) -> Void

/// Manages trip progress tracking and provides data to the TripProgressOverlay.
///
/// This class stores waypoint information when navigation starts and
/// calculates progress data from route updates.
public class TripProgressManager {

    /// Singleton instance
    public static let shared = TripProgressManager()

    private init() {}

    /// Information about a waypoint for progress tracking
    public struct WaypointInfo {
        let name: String
        let category: String
        let description: String?
        let iconId: String?
        let isCheckpoint: Bool
        let latitude: Double
        let longitude: Double
    }

    private var waypoints: [WaypointInfo] = []
    private var progressListener: TripProgressListener?

    /// Set waypoints for this navigation session.
    /// Call this when navigation starts.
    public func setWaypoints(_ waypointList: [Waypoint], checkpointInfo: [Int: CheckpointInfo]? = nil) {
        waypoints = waypointList.enumerated().map { (index, wp) in
            let checkpoint = checkpointInfo?[index]
            return WaypointInfo(
                name: checkpoint?.title ?? wp.name ?? "Waypoint \(index + 1)",
                category: checkpoint != nil ? "checkpoint" : "waypoint",
                description: checkpoint?.description,
                iconId: checkpoint?.iconId ?? (checkpoint != nil ? "flag" : "pin"),
                isCheckpoint: checkpoint != nil,
                latitude: wp.coordinate.latitude,
                longitude: wp.coordinate.longitude
            )
        }
        print("TripProgressManager: Set \(waypoints.count) waypoints for tracking")
    }

    /// Set waypoints from static markers (for integration with marker system).
    public func setWaypointsFromMarkers(_ waypointList: [Waypoint], markers: [StaticMarker]) {
        // Build a map of marker locations for quick lookup
        let markerMap = Dictionary(uniqueKeysWithValues: markers.map { marker in
            (String(format: "%.5f,%.5f", marker.latitude, marker.longitude), marker)
        })

        waypoints = waypointList.enumerated().map { (index, wp) in
            let locationKey = String(format: "%.5f,%.5f", wp.coordinate.latitude, wp.coordinate.longitude)
            let marker = markerMap[locationKey]

            return WaypointInfo(
                name: marker?.title ?? wp.name ?? "Waypoint \(index + 1)",
                category: marker?.category ?? "waypoint",
                description: marker?.description,
                iconId: marker?.iconId,
                isCheckpoint: marker?.category?.lowercased() == "checkpoint",
                latitude: wp.coordinate.latitude,
                longitude: wp.coordinate.longitude
            )
        }
        print("TripProgressManager: Set \(waypoints.count) waypoints from markers")
    }

    /// Set a listener for progress updates.
    public func setProgressListener(_ listener: TripProgressListener?) {
        progressListener = listener
    }

    /// Update progress based on route progress data from Mapbox.
    ///
    /// - Parameters:
    ///   - legIndex: Current leg index (0 = heading to first waypoint after origin)
    ///   - distanceToNextWaypoint: Distance remaining in current leg (meters)
    ///   - totalDistanceRemaining: Total distance to final destination (meters)
    ///   - totalDurationRemaining: Total time to final destination (seconds)
    public func updateProgress(
        legIndex: Int,
        distanceToNextWaypoint: Double,
        totalDistanceRemaining: Double,
        totalDurationRemaining: Double
    ) {
        guard !waypoints.isEmpty else {
            print("TripProgressManager: No waypoints set, cannot update progress")
            return
        }

        let nextWaypointIndex = min(max(legIndex, 0), waypoints.count - 1)
        let nextWaypoint = waypoints[nextWaypointIndex]

        let progressData = TripProgressData(
            currentWaypointIndex: nextWaypointIndex,
            totalWaypoints: waypoints.count,
            nextWaypointName: nextWaypoint.name,
            nextWaypointCategory: nextWaypoint.category,
            nextWaypointDescription: nextWaypoint.description,
            nextWaypointIconId: nextWaypoint.iconId,
            distanceToNextWaypoint: distanceToNextWaypoint,
            totalDistanceRemaining: totalDistanceRemaining,
            totalDurationRemaining: totalDurationRemaining,
            isNextWaypointCheckpoint: nextWaypoint.isCheckpoint
        )

        progressListener?(progressData)
    }

    /// Clear all waypoint data.
    public func clear() {
        waypoints = []
        progressListener = nil
        print("TripProgressManager: Cleared trip progress data")
    }

    /// Get the total number of waypoints.
    public var waypointCount: Int {
        return waypoints.count
    }

    /// Check if waypoints are loaded.
    public var hasWaypoints: Bool {
        return !waypoints.isEmpty
    }

    /// Information about a checkpoint for progress display.
    public struct CheckpointInfo {
        let title: String
        let description: String?
        let iconId: String?
    }
}
