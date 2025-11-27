package com.eopeter.fluttermapboxnavigation.models

/**
 * Data class representing the current trip progress.
 *
 * This is used to update the trip progress overlay with current navigation state.
 */
data class TripProgressData(
    /** Index of the current waypoint we're heading to (0-indexed) */
    val currentWaypointIndex: Int,

    /** Total number of waypoints in the trip */
    val totalWaypoints: Int,

    /** Name of the next waypoint/checkpoint */
    val nextWaypointName: String,

    /** Category/type of the next waypoint (checkpoint, waypoint, poi, etc.) */
    val nextWaypointCategory: String,

    /** Optional description of the next waypoint */
    val nextWaypointDescription: String?,

    /** Icon ID for the next waypoint */
    val nextWaypointIconId: String?,

    /** Distance remaining to the next waypoint in meters */
    val distanceToNextWaypoint: Double,

    /** Distance remaining to the final destination in meters */
    val totalDistanceRemaining: Double,

    /** Duration remaining to the final destination in seconds */
    val totalDurationRemaining: Double,

    /** Duration remaining to the next waypoint in seconds */
    val durationToNextWaypoint: Double = 0.0,

    /** Whether this is a checkpoint (vs regular waypoint) */
    val isNextWaypointCheckpoint: Boolean = false
) {
    /**
     * Get progress as a fraction (0.0 to 1.0)
     */
    val progressFraction: Float
        get() = if (totalWaypoints > 1) {
            (currentWaypointIndex.toFloat()) / (totalWaypoints - 1).toFloat()
        } else {
            0f
        }

    /**
     * Get formatted progress string (e.g., "Waypoint 3/8")
     */
    val progressString: String
        get() = "Waypoint ${currentWaypointIndex + 1}/$totalWaypoints"

    /**
     * Get formatted distance to next waypoint
     */
    fun getFormattedDistanceToNext(useImperial: Boolean = true): String {
        return if (useImperial) {
            val miles = distanceToNextWaypoint / 1609.34
            if (miles < 0.1) {
                val feet = distanceToNextWaypoint * 3.28084
                "${feet.toInt()} ft"
            } else {
                String.format("%.1f mi", miles)
            }
        } else {
            if (distanceToNextWaypoint < 1000) {
                "${distanceToNextWaypoint.toInt()} m"
            } else {
                String.format("%.1f km", distanceToNextWaypoint / 1000)
            }
        }
    }

    /**
     * Get formatted duration remaining to final destination
     */
    fun getFormattedDurationRemaining(): String {
        val totalMinutes = (totalDurationRemaining / 60).toInt()
        return when {
            totalMinutes < 60 -> "${totalMinutes} min"
            else -> {
                val hours = totalMinutes / 60
                val mins = totalMinutes % 60
                if (mins > 0) "${hours}h ${mins}m" else "${hours}h"
            }
        }
    }

    /**
     * Get formatted duration to next waypoint
     */
    fun getFormattedDurationToNext(): String {
        val totalMinutes = (durationToNextWaypoint / 60).toInt()
        return when {
            totalMinutes < 1 -> "< 1 min"
            totalMinutes < 60 -> "~${totalMinutes} min"
            else -> {
                val hours = totalMinutes / 60
                val mins = totalMinutes % 60
                if (mins > 0) "~${hours}h ${mins}m" else "~${hours}h"
            }
        }
    }

    /**
     * Get formatted ETA at final destination
     */
    fun getFormattedEta(): String {
        val now = System.currentTimeMillis()
        val etaMillis = now + (totalDurationRemaining * 1000).toLong()
        val calendar = java.util.Calendar.getInstance()
        calendar.timeInMillis = etaMillis
        val hour = calendar.get(java.util.Calendar.HOUR_OF_DAY)
        val minute = calendar.get(java.util.Calendar.MINUTE)
        return String.format("%d:%02d", if (hour == 0) 12 else if (hour > 12) hour - 12 else hour, minute) +
                if (hour < 12) "am" else "pm"
    }

    /**
     * Get formatted total distance remaining
     */
    fun getFormattedTotalDistanceRemaining(useImperial: Boolean = true): String {
        return if (useImperial) {
            val miles = totalDistanceRemaining / 1609.34
            String.format("%.1f mi", miles)
        } else {
            String.format("%.1f km", totalDistanceRemaining / 1000)
        }
    }
}
