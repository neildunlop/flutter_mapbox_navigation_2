import Foundation
import MapboxDirections

/// Callback type for progress updates
public typealias TripProgressListener = (TripProgressData) -> Void

/// Manages trip progress tracking and provides data to the TripProgressOverlay.
///
/// This class stores waypoint information when navigation starts and
/// calculates progress data from route updates. Matches the Android
/// TripProgressManager for cross-platform consistency.
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
    private var lastProgressData: TripProgressData? // Cache for new listeners
    private var originalTotalWaypoints: Int = 0 // Track original count for display
    private var skippedWaypointsCount: Int = 0 // Track how many have been skipped

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
    /// - Parameters:
    ///   - waypointList: List of waypoints
    ///   - markers: List of static markers
    ///   - isInitialSetup: If true, this is the first call and we should set the original total
    public func setWaypointsFromMarkers(_ waypointList: [Waypoint], markers: [StaticMarker], isInitialSetup: Bool = false) {
        // Build a map of marker locations for quick lookup
        let markerMap = Dictionary(uniqueKeysWithValues: markers.map { marker in
            (String(format: "%.5f,%.5f", marker.latitude, marker.longitude), marker)
        })

        print("TripProgressManager: setWaypointsFromMarkers: \(waypointList.count) waypoints, \(markers.count) markers, isInitialSetup=\(isInitialSetup)")

        // Track original total on first setup
        if isInitialSetup || originalTotalWaypoints == 0 {
            originalTotalWaypoints = waypointList.count
            skippedWaypointsCount = 0
            print("TripProgressManager: Set original total waypoints: \(originalTotalWaypoints)")
        }

        waypoints = waypointList.enumerated().map { (index, wp) in
            let locationKey = String(format: "%.5f,%.5f", wp.coordinate.latitude, wp.coordinate.longitude)
            let marker = markerMap[locationKey]

            // Get the name - prioritize marker title, then waypoint name, then fallback
            let waypointName: String
            if let title = marker?.title, !title.isEmpty {
                waypointName = title
            } else if let name = wp.name, !name.isEmpty {
                waypointName = name
            } else {
                waypointName = "Waypoint \(index + 1)"
            }

            print("TripProgressManager: Waypoint \(index): name='\(waypointName)', marker=\(marker?.title ?? "nil")")

            return WaypointInfo(
                name: waypointName,
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
    /// If there's cached progress data, it will be sent to the new listener immediately.
    public func setProgressListener(_ listener: TripProgressListener?) {
        progressListener = listener
        // Send cached data to new listener immediately
        if let listener = listener, let lastData = lastProgressData {
            print("TripProgressManager: Sending cached progress to new listener: \(lastData.nextWaypointName)")
            listener(lastData)
        }
    }

    /// Update progress based on route progress data from Mapbox.
    ///
    /// - Parameters:
    ///   - legIndex: Current leg index (0 = heading to first waypoint after origin)
    ///   - distanceToNextWaypoint: Distance remaining in current leg (meters)
    ///   - totalDistanceRemaining: Total distance to final destination (meters)
    ///   - totalDurationRemaining: Total time to final destination (seconds)
    ///   - durationToNextWaypoint: Duration remaining to next waypoint (seconds)
    public func updateProgress(
        legIndex: Int,
        distanceToNextWaypoint: Double,
        totalDistanceRemaining: Double,
        totalDurationRemaining: Double,
        durationToNextWaypoint: Double = 0
    ) {
        print("TripProgressManager: updateProgress called: legIndex=\(legIndex), waypoints=\(waypoints.count), listener=\(progressListener != nil)")

        guard !waypoints.isEmpty else {
            print("TripProgressManager: No waypoints set, cannot update progress")
            return
        }

        // legIndex is 0-based, represents which leg we're on
        // Leg 0 = origin to waypoint 0
        // Leg 1 = waypoint 0 to waypoint 1
        // etc.

        // The next waypoint index is legIndex (since leg 0 leads to waypoint 0)
        // But we need to cap it to the last waypoint
        let nextWaypointIndex = min(max(legIndex, 0), waypoints.count - 1)
        let nextWaypoint = waypoints[nextWaypointIndex]

        // Calculate display index that accounts for skipped waypoints
        let displayIndex = nextWaypointIndex + skippedWaypointsCount
        let displayTotal = originalTotalWaypoints > 0 ? originalTotalWaypoints : waypoints.count

        print("TripProgressManager: Progress: legIndex=\(legIndex), nextWaypointIndex=\(nextWaypointIndex), skipped=\(skippedWaypointsCount), displayIndex=\(displayIndex), displayTotal=\(displayTotal)")

        let progressData = TripProgressData(
            currentWaypointIndex: displayIndex, // Use display index that includes skipped
            totalWaypoints: displayTotal, // Use original total
            nextWaypointName: nextWaypoint.name,
            nextWaypointCategory: nextWaypoint.category,
            nextWaypointDescription: nextWaypoint.description,
            nextWaypointIconId: nextWaypoint.iconId,
            distanceToNextWaypoint: distanceToNextWaypoint,
            durationToNextWaypoint: durationToNextWaypoint,
            totalDistanceRemaining: totalDistanceRemaining,
            totalDurationRemaining: totalDurationRemaining,
            isNextWaypointCheckpoint: nextWaypoint.isCheckpoint
        )

        // Cache for new listeners that attach later
        lastProgressData = progressData

        progressListener?(progressData)
    }

    /// Clear all waypoint data.
    public func clear() {
        waypoints = []
        progressListener = nil
        lastProgressData = nil
        originalTotalWaypoints = 0
        skippedWaypointsCount = 0
        print("TripProgressManager: Cleared trip progress data")
    }

    /// Increment the skipped waypoints count (called when a waypoint is skipped).
    public func incrementSkippedCount() {
        skippedWaypointsCount += 1
        print("TripProgressManager: Incremented skipped count to \(skippedWaypointsCount)")
    }

    /// Decrement the skipped waypoints count (called when going back to a previous waypoint).
    public func decrementSkippedCount() {
        if skippedWaypointsCount > 0 {
            skippedWaypointsCount -= 1
            print("TripProgressManager: Decremented skipped count to \(skippedWaypointsCount)")
        }
    }

    /// Get the current skipped count.
    public var skippedCount: Int {
        return skippedWaypointsCount
    }

    /// Get the total number of waypoints.
    public var waypointCount: Int {
        return waypoints.count
    }

    /// Check if waypoints are loaded.
    public var hasWaypoints: Bool {
        return !waypoints.isEmpty
    }

    /// Get all waypoint info.
    public func getWaypoints() -> [WaypointInfo] {
        return waypoints
    }

    /// Get waypoint at specific index.
    public func getWaypointAt(_ index: Int) -> WaypointInfo? {
        guard index >= 0 && index < waypoints.count else { return nil }
        return waypoints[index]
    }

    /// Remove waypoint at index and return updated list.
    /// Returns the updated list of waypoints or nil if index is invalid.
    public func removeWaypointAt(_ index: Int) -> [WaypointInfo]? {
        guard index >= 0 && index < waypoints.count else {
            print("TripProgressManager: Cannot remove waypoint at index \(index), only \(waypoints.count) waypoints")
            return nil
        }
        let removed = waypoints.remove(at: index)
        print("TripProgressManager: Removed waypoint '\(removed.name)' at index \(index), \(waypoints.count) remaining")
        return waypoints
    }

    /// Skip to next waypoint (removes current waypoint from list).
    /// Returns the index of the new current waypoint, or -1 if cannot skip.
    public func skipToNextWaypoint(_ currentIndex: Int) -> Int {
        guard currentIndex >= 0 && currentIndex < waypoints.count - 1 else {
            print("TripProgressManager: Cannot skip from index \(currentIndex), only \(waypoints.count) waypoints")
            return -1
        }
        _ = removeWaypointAt(currentIndex)
        // After removing, the next waypoint is now at currentIndex
        return min(currentIndex, waypoints.count - 1)
    }

    /// Check if we can go to a previous waypoint.
    public func canGoToPrevious(_ currentIndex: Int) -> Bool {
        return currentIndex > 0
    }

    /// Check if we can skip to the next waypoint.
    public func canSkipToNext(_ currentIndex: Int) -> Bool {
        return currentIndex < waypoints.count - 1
    }

    /// Information about a checkpoint for progress display.
    public struct CheckpointInfo {
        public let title: String
        public let description: String?
        public let iconId: String?

        public init(title: String, description: String? = nil, iconId: String? = nil) {
            self.title = title
            self.description = description
            self.iconId = iconId
        }
    }
}
