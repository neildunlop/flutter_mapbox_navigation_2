package com.neiladunlop.fluttermapboxnavigation2.models

import android.graphics.Color

/**
 * Configuration for the dynamic marker system.
 *
 * This configuration controls animation, state thresholds, trail rendering,
 * prediction behavior, and display settings for dynamic markers.
 */
data class DynamicMarkerConfiguration(
    // ---------------------------------------------------------------------------
    // Animation Settings
    // ---------------------------------------------------------------------------

    /**
     * Duration of position animation in milliseconds.
     *
     * This should be roughly equal to or slightly longer than
     * the expected interval between position updates to ensure
     * smooth continuous motion.
     *
     * Default: 1000ms (suitable for 1Hz update rate)
     */
    val animationDurationMs: Int = 1000,

    /**
     * Enable smooth animation between positions.
     *
     * When false, markers jump instantly to new positions.
     * Default: true
     */
    val enableAnimation: Boolean = true,

    /**
     * Enable rotation animation for heading changes.
     *
     * When true, markers smoothly rotate to face their heading.
     * Default: true
     */
    val animateHeading: Boolean = true,

    // ---------------------------------------------------------------------------
    // State Thresholds
    // ---------------------------------------------------------------------------

    /**
     * Time without updates before marking as stale (milliseconds).
     *
     * Default: 10000ms (10 seconds)
     */
    val staleThresholdMs: Int = 10000,

    /**
     * Time without updates before marking as offline (milliseconds).
     *
     * Default: 30000ms (30 seconds)
     */
    val offlineThresholdMs: Int = 30000,

    /**
     * Time without updates before auto-removing marker (milliseconds).
     *
     * Set to null to disable auto-expiration.
     * Default: null (no auto-expiration)
     */
    val expiredThresholdMs: Int? = null,

    /**
     * Speed threshold below which entity is considered stationary (m/s).
     *
     * Default: 0.5 m/s (~1.8 km/h)
     */
    val stationarySpeedThreshold: Double = 0.5,

    /**
     * Duration at low speed before marking stationary (milliseconds).
     *
     * Default: 30000ms (30 seconds)
     */
    val stationaryDurationMs: Int = 30000,

    // ---------------------------------------------------------------------------
    // Trail/Breadcrumb Settings
    // ---------------------------------------------------------------------------

    /**
     * Enable trail rendering by default for new markers.
     *
     * Individual markers can override via [DynamicMarker.showTrail].
     * Default: false
     */
    val enableTrail: Boolean = false,

    /**
     * Maximum number of trail points per marker.
     *
     * Default: 50
     */
    val maxTrailPoints: Int = 50,

    /**
     * Trail line color (ARGB integer).
     *
     * Default: Blue with 50% opacity (0x7F2196F3)
     */
    val trailColor: Int = 0x7F2196F3,

    /**
     * Trail line width in logical pixels.
     *
     * Default: 3.0
     */
    val trailWidth: Double = 3.0,

    /**
     * Enable gradient fade on trail (solid at marker, transparent at end).
     *
     * Default: true
     */
    val trailGradient: Boolean = true,

    /**
     * Minimum distance between trail points in meters.
     *
     * Prevents dense clustering when stationary.
     * Default: 5.0
     */
    val minTrailPointDistance: Double = 5.0,

    // ---------------------------------------------------------------------------
    // Prediction Settings
    // ---------------------------------------------------------------------------

    /**
     * Enable dead-reckoning prediction when updates are delayed.
     *
     * When enabled, the marker continues moving based on last known
     * speed and heading until a new update arrives.
     * Default: true
     */
    val enablePrediction: Boolean = true,

    /**
     * Maximum prediction window in milliseconds.
     *
     * Prediction stops after this duration without an update.
     * Default: 2000ms
     */
    val predictionWindowMs: Int = 2000,

    // ---------------------------------------------------------------------------
    // Display Settings
    // ---------------------------------------------------------------------------

    /**
     * Z-index for dynamic markers (relative to static markers).
     *
     * Higher values render above lower values.
     * Default: 100 (above default static markers at 0)
     */
    val zIndex: Int = 100,

    /**
     * Minimum zoom level for marker visibility.
     *
     * Default: 0.0 (always visible)
     */
    val minZoomLevel: Double = 0.0,

    /**
     * Maximum distance from map center before hiding (kilometers).
     *
     * null = no limit
     * Default: null
     */
    val maxDistanceFromCenter: Double? = null
) {
    companion object {
        /**
         * Default configuration instance.
         */
        val DEFAULT = DynamicMarkerConfiguration()

        /**
         * Creates a DynamicMarkerConfiguration from a JSON map.
         */
        fun fromJson(json: Map<String, Any>): DynamicMarkerConfiguration {
            return DynamicMarkerConfiguration(
                animationDurationMs = json["animationDurationMs"] as? Int ?: 1000,
                enableAnimation = json["enableAnimation"] as? Boolean ?: true,
                animateHeading = json["animateHeading"] as? Boolean ?: true,
                staleThresholdMs = json["staleThresholdMs"] as? Int ?: 10000,
                offlineThresholdMs = json["offlineThresholdMs"] as? Int ?: 30000,
                expiredThresholdMs = json["expiredThresholdMs"] as? Int,
                stationarySpeedThreshold = (json["stationarySpeedThreshold"] as? Number)?.toDouble() ?: 0.5,
                stationaryDurationMs = json["stationaryDurationMs"] as? Int ?: 30000,
                enableTrail = json["enableTrail"] as? Boolean ?: false,
                maxTrailPoints = json["maxTrailPoints"] as? Int ?: 50,
                trailColor = json["trailColor"] as? Int ?: 0x7F2196F3,
                trailWidth = (json["trailWidth"] as? Number)?.toDouble() ?: 3.0,
                trailGradient = json["trailGradient"] as? Boolean ?: true,
                minTrailPointDistance = (json["minTrailPointDistance"] as? Number)?.toDouble() ?: 5.0,
                enablePrediction = json["enablePrediction"] as? Boolean ?: true,
                predictionWindowMs = json["predictionWindowMs"] as? Int ?: 2000,
                zIndex = json["zIndex"] as? Int ?: 100,
                minZoomLevel = (json["minZoomLevel"] as? Number)?.toDouble() ?: 0.0,
                maxDistanceFromCenter = (json["maxDistanceFromCenter"] as? Number)?.toDouble()
            )
        }
    }

    /**
     * Converts this configuration to a JSON map.
     */
    fun toJson(): Map<String, Any?> {
        return mapOf(
            "animationDurationMs" to animationDurationMs,
            "enableAnimation" to enableAnimation,
            "animateHeading" to animateHeading,
            "staleThresholdMs" to staleThresholdMs,
            "offlineThresholdMs" to offlineThresholdMs,
            "expiredThresholdMs" to expiredThresholdMs,
            "stationarySpeedThreshold" to stationarySpeedThreshold,
            "stationaryDurationMs" to stationaryDurationMs,
            "enableTrail" to enableTrail,
            "maxTrailPoints" to maxTrailPoints,
            "trailColor" to trailColor,
            "trailWidth" to trailWidth,
            "trailGradient" to trailGradient,
            "minTrailPointDistance" to minTrailPointDistance,
            "enablePrediction" to enablePrediction,
            "predictionWindowMs" to predictionWindowMs,
            "zIndex" to zIndex,
            "minZoomLevel" to minZoomLevel,
            "maxDistanceFromCenter" to maxDistanceFromCenter
        )
    }

    override fun toString(): String {
        return "DynamicMarkerConfiguration(" +
                "animationDurationMs=$animationDurationMs, " +
                "enableAnimation=$enableAnimation, " +
                "enableTrail=$enableTrail, " +
                "staleThresholdMs=$staleThresholdMs)"
    }
}
