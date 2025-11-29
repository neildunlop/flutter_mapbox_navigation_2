package com.eopeter.fluttermapboxnavigation.utilities

import android.util.Log
import com.eopeter.fluttermapboxnavigation.models.TripProgressData
import com.eopeter.fluttermapboxnavigation.models.Waypoint

/**
 * Manages trip progress tracking and provides data to the TripProgressOverlay.
 *
 * This class stores waypoint information when navigation starts and
 * calculates progress data from route updates.
 */
class TripProgressManager {

    private var waypoints: List<WaypointInfo> = emptyList()
    private var progressListener: ((TripProgressData) -> Unit)? = null
    private var lastProgressData: TripProgressData? = null  // Cache for new listeners
    private var originalTotalWaypoints: Int = 0  // Track original count for display
    private var skippedWaypointsCount: Int = 0  // Track how many have been skipped
    private var initialTotalDistance: Double = 0.0  // Track initial distance for progress bar

    /**
     * Information about a waypoint for progress tracking.
     */
    data class WaypointInfo(
        val name: String,
        val category: String,
        val description: String?,
        val iconId: String?,
        val isCheckpoint: Boolean,
        val latitude: Double,
        val longitude: Double
    )

    /**
     * Set the waypoints for this navigation session.
     * Call this when navigation starts.
     */
    fun setWaypoints(waypointList: List<Waypoint>, checkpointInfo: Map<Int, CheckpointInfo>? = null) {
        waypoints = waypointList.mapIndexed { index, wp ->
            val checkpoint = checkpointInfo?.get(index)
            WaypointInfo(
                name = checkpoint?.title ?: wp.name ?: "Waypoint ${index + 1}",
                category = if (checkpoint != null) "checkpoint" else "waypoint",
                description = checkpoint?.description,
                iconId = checkpoint?.iconId ?: if (checkpoint != null) "flag" else "pin",
                isCheckpoint = checkpoint != null,
                latitude = wp.point.latitude(),
                longitude = wp.point.longitude()
            )
        }
        Log.d("TripProgressManager", "Set ${waypoints.size} waypoints for tracking")
    }

    /**
     * Set waypoints from static markers (for integration with marker system).
     * @param isInitialSetup If true, this is the first call and we should set the original total
     */
    fun setWaypointsFromMarkers(waypointList: List<Waypoint>, markers: List<com.eopeter.fluttermapboxnavigation.models.StaticMarker>, isInitialSetup: Boolean = false) {
        // Build a map of marker locations for quick lookup
        val markerMap = markers.associateBy { marker ->
            "${String.format("%.5f", marker.latitude)},${String.format("%.5f", marker.longitude)}"
        }

        Log.d("TripProgressManager", "setWaypointsFromMarkers: ${waypointList.size} waypoints, ${markers.size} markers, isInitialSetup=$isInitialSetup")

        // Track original total on first setup
        if (isInitialSetup || originalTotalWaypoints == 0) {
            originalTotalWaypoints = waypointList.size
            skippedWaypointsCount = 0
            Log.d("TripProgressManager", "Set original total waypoints: $originalTotalWaypoints")
        }

        waypoints = waypointList.mapIndexed { index, wp ->
            val locationKey = "${String.format("%.5f", wp.point.latitude())},${String.format("%.5f", wp.point.longitude())}"
            val marker = markerMap[locationKey]

            // Get the name - prioritize marker title, then waypoint name, then fallback
            val waypointName = when {
                marker?.title?.isNotEmpty() == true -> marker.title
                wp.name.isNotEmpty() -> wp.name
                else -> "Waypoint ${index + 1}"
            }

            Log.d("TripProgressManager", "Waypoint $index: name='$waypointName', marker=${marker?.title}")

            WaypointInfo(
                name = waypointName,
                category = marker?.category ?: "waypoint",
                description = marker?.description,
                iconId = marker?.iconId,
                isCheckpoint = marker?.category?.equals("checkpoint", ignoreCase = true) == true,
                latitude = wp.point.latitude(),
                longitude = wp.point.longitude()
            )
        }
        Log.d("TripProgressManager", "Set ${waypoints.size} waypoints from markers")
    }

    /**
     * Set a listener for progress updates.
     * If there's cached progress data, it will be sent to the new listener immediately.
     */
    fun setProgressListener(listener: ((TripProgressData) -> Unit)?) {
        progressListener = listener
        // Send cached data to new listener immediately
        if (listener != null && lastProgressData != null) {
            Log.d("TripProgressManager", "Sending cached progress to new listener: ${lastProgressData?.nextWaypointName}")
            listener.invoke(lastProgressData!!)
        }
    }

    /**
     * Update progress based on route progress data from Mapbox.
     *
     * @param legIndex Current leg index (0 = heading to first waypoint after origin)
     * @param distanceToNextWaypoint Distance remaining in current leg (meters)
     * @param totalDistanceRemaining Total distance to final destination (meters)
     * @param totalDurationRemaining Total time to final destination (seconds)
     * @param durationToNextWaypoint Duration remaining to next waypoint (seconds)
     * @param currentSpeedMps Current speed in meters per second (from GPS)
     */
    fun updateProgress(
        legIndex: Int,
        distanceToNextWaypoint: Double,
        totalDistanceRemaining: Double,
        totalDurationRemaining: Double,
        durationToNextWaypoint: Double = 0.0,
        currentSpeedMps: Float = 0f
    ) {
        Log.d("TripProgressManager", "updateProgress called: legIndex=$legIndex, waypoints=${waypoints.size}, listener=${progressListener != null}")
        if (waypoints.isEmpty()) {
            Log.w("TripProgressManager", "No waypoints set, cannot update progress")
            return
        }

        // Set initial total distance on first progress update (used for progress bar calculation)
        if (initialTotalDistance <= 0 && totalDistanceRemaining > 0) {
            initialTotalDistance = totalDistanceRemaining
            Log.d("TripProgressManager", "Set initial total distance: ${String.format("%.1f", initialTotalDistance / 1609.34)} mi")
        }

        // legIndex is 0-based, represents which leg we're on
        // Leg 0 = origin to waypoint 0
        // Leg 1 = waypoint 0 to waypoint 1
        // etc.

        // The next waypoint index is legIndex (since leg 0 leads to waypoint 0)
        // But we need to cap it to the last waypoint
        val nextWaypointIndex = legIndex.coerceIn(0, waypoints.size - 1)
        val nextWaypoint = waypoints[nextWaypointIndex]

        // Calculate display index that accounts for skipped waypoints
        val displayIndex = nextWaypointIndex + skippedWaypointsCount
        val displayTotal = if (originalTotalWaypoints > 0) originalTotalWaypoints else waypoints.size

        Log.d("TripProgressManager", "Progress: legIndex=$legIndex, nextWaypointIndex=$nextWaypointIndex, skipped=$skippedWaypointsCount, displayIndex=$displayIndex, displayTotal=$displayTotal")

        val progressData = TripProgressData(
            currentWaypointIndex = displayIndex,  // Use display index that includes skipped
            totalWaypoints = displayTotal,  // Use original total
            nextWaypointName = nextWaypoint.name,
            nextWaypointCategory = nextWaypoint.category,
            nextWaypointDescription = nextWaypoint.description,
            nextWaypointIconId = nextWaypoint.iconId,
            distanceToNextWaypoint = distanceToNextWaypoint,
            totalDistanceRemaining = totalDistanceRemaining,
            totalDurationRemaining = totalDurationRemaining,
            durationToNextWaypoint = durationToNextWaypoint,
            isNextWaypointCheckpoint = nextWaypoint.isCheckpoint,
            initialTotalDistance = initialTotalDistance,
            currentSpeedMps = currentSpeedMps
        )

        // Cache for new listeners that attach later
        lastProgressData = progressData

        progressListener?.invoke(progressData)
    }

    /**
     * Clear all waypoint data.
     */
    fun clear() {
        waypoints = emptyList()
        progressListener = null
        lastProgressData = null
        originalTotalWaypoints = 0
        skippedWaypointsCount = 0
        initialTotalDistance = 0.0
        Log.d("TripProgressManager", "Cleared trip progress data")
    }

    /**
     * Increment the skipped waypoints count (called when a waypoint is skipped).
     */
    fun incrementSkippedCount() {
        skippedWaypointsCount++
        Log.d("TripProgressManager", "Incremented skipped count to $skippedWaypointsCount")
    }

    /**
     * Decrement the skipped waypoints count (called when going back to a previous waypoint).
     */
    fun decrementSkippedCount() {
        if (skippedWaypointsCount > 0) {
            skippedWaypointsCount--
            Log.d("TripProgressManager", "Decremented skipped count to $skippedWaypointsCount")
        }
    }

    /**
     * Get the current skipped count.
     */
    fun getSkippedCount(): Int = skippedWaypointsCount

    /**
     * Get the total number of waypoints.
     */
    fun getWaypointCount(): Int = waypoints.size

    /**
     * Check if waypoints are loaded.
     */
    fun hasWaypoints(): Boolean = waypoints.isNotEmpty()

    /**
     * Get all waypoint info.
     */
    fun getWaypoints(): List<WaypointInfo> = waypoints.toList()

    /**
     * Get waypoint at specific index.
     */
    fun getWaypointAt(index: Int): WaypointInfo? = waypoints.getOrNull(index)

    /**
     * Remove waypoint at index and return updated list.
     * Returns the updated list of waypoints or null if index is invalid.
     */
    fun removeWaypointAt(index: Int): List<WaypointInfo>? {
        if (index < 0 || index >= waypoints.size) {
            Log.w("TripProgressManager", "Cannot remove waypoint at index $index, only ${waypoints.size} waypoints")
            return null
        }
        val mutableWaypoints = waypoints.toMutableList()
        val removed = mutableWaypoints.removeAt(index)
        waypoints = mutableWaypoints
        Log.d("TripProgressManager", "Removed waypoint '${removed.name}' at index $index, ${waypoints.size} remaining")
        return waypoints
    }

    /**
     * Skip to next waypoint (removes current waypoint from list).
     * Returns the index of the new current waypoint, or -1 if cannot skip.
     */
    fun skipToNextWaypoint(currentIndex: Int): Int {
        if (currentIndex < 0 || currentIndex >= waypoints.size - 1) {
            Log.w("TripProgressManager", "Cannot skip from index $currentIndex, only ${waypoints.size} waypoints")
            return -1
        }
        removeWaypointAt(currentIndex)
        // After removing, the next waypoint is now at currentIndex
        return currentIndex.coerceIn(0, waypoints.size - 1)
    }

    /**
     * Go back to previous waypoint.
     * Note: This doesn't actually restore the waypoint (we'd need to store skipped ones),
     * it just returns the previous index for navigation purposes.
     */
    fun canGoToPrevious(currentIndex: Int): Boolean {
        return currentIndex > 0
    }

    /**
     * Check if we can skip to the next waypoint.
     */
    fun canSkipToNext(currentIndex: Int): Boolean {
        return currentIndex < waypoints.size - 1
    }

    /**
     * Information about a checkpoint for progress display.
     */
    data class CheckpointInfo(
        val title: String,
        val description: String?,
        val iconId: String?
    )

    companion object {
        @Volatile
        private var instance: TripProgressManager? = null

        fun getInstance(): TripProgressManager {
            return instance ?: synchronized(this) {
                instance ?: TripProgressManager().also { instance = it }
            }
        }
    }
}
