package com.neiladunlop.fluttermapboxnavigation2.models

import android.graphics.Color

/**
 * Represents a geographic coordinate with latitude and longitude.
 */
data class LatLng(
    val latitude: Double,
    val longitude: Double
) {
    companion object {
        /**
         * Creates a LatLng from a JSON map.
         */
        fun fromJson(json: Map<String, Any>): LatLng {
            return LatLng(
                latitude = (json["latitude"] as Number).toDouble(),
                longitude = (json["longitude"] as Number).toDouble()
            )
        }
    }

    /**
     * Converts this LatLng to a JSON map.
     */
    fun toJson(): Map<String, Any> {
        return mapOf(
            "latitude" to latitude,
            "longitude" to longitude
        )
    }
}

/**
 * Represents the current state of a dynamic marker.
 */
enum class DynamicMarkerState {
    /** Marker is actively receiving position updates. */
    TRACKING,

    /** Marker is currently animating between positions. */
    ANIMATING,

    /** Entity has stopped moving (speed below threshold). */
    STATIONARY,

    /** No update received within the stale threshold. */
    STALE,

    /** No update received for an extended period. */
    OFFLINE,

    /** Marker is about to be automatically removed due to expiration. */
    EXPIRED;

    companion object {
        /**
         * Creates a DynamicMarkerState from a string value.
         * Falls back to TRACKING if the value is not recognized.
         */
        fun fromString(value: String): DynamicMarkerState {
            return try {
                valueOf(value.uppercase())
            } catch (e: IllegalArgumentException) {
                TRACKING
            }
        }
    }

    /**
     * Returns the lowercase name for JSON serialization.
     */
    fun toJsonString(): String = name.lowercase()
}

/**
 * Represents a marker that can move and animate across the map.
 *
 * Dynamic markers are used for tracking real-time entities like vehicles,
 * drones, or other moving objects. The marker's position can be smoothly
 * animated between updates.
 */
data class DynamicMarker(
    /** Unique identifier for this marker. */
    val id: String,

    /** Current latitude coordinate. */
    val latitude: Double,

    /** Current longitude coordinate. */
    val longitude: Double,

    /** Display title for the marker. */
    val title: String,

    /** Category string for grouping and default styling. */
    val category: String,

    /** Previous latitude coordinate (used for interpolation). */
    val previousLatitude: Double? = null,

    /** Previous longitude coordinate (used for interpolation). */
    val previousLongitude: Double? = null,

    /** Current heading/bearing in degrees (0-360, where 0 = north). */
    val heading: Double? = null,

    /** Current speed in meters per second. */
    val speed: Double? = null,

    /** Timestamp of the last position update (ISO8601 string). */
    val lastUpdated: String? = null,

    /** Icon identifier from the standard marker icon set. */
    val iconId: String? = null,

    /** Custom color for the marker (ARGB integer). */
    val customColor: Int? = null,

    /** Arbitrary metadata associated with this marker. */
    val metadata: Map<String, Any>? = null,

    /** Current state of the marker. */
    val state: DynamicMarkerState = DynamicMarkerState.TRACKING,

    /** Whether to render a trail/breadcrumb behind this marker. */
    val showTrail: Boolean = false,

    /** Maximum number of trail points to retain. */
    val trailLength: Int = 50,

    /** Historical positions for trail rendering. */
    val positionHistory: List<LatLng>? = null
) {
    companion object {
        /**
         * Creates a DynamicMarker from a JSON map.
         */
        @Suppress("UNCHECKED_CAST")
        fun fromJson(json: Map<String, Any>): DynamicMarker {
            val positionHistoryList = (json["positionHistory"] as? List<Map<String, Any>>)
                ?.map { LatLng.fromJson(it) }

            return DynamicMarker(
                id = json["id"] as String,
                latitude = (json["latitude"] as Number).toDouble(),
                longitude = (json["longitude"] as Number).toDouble(),
                title = json["title"] as String,
                category = json["category"] as String,
                previousLatitude = (json["previousLatitude"] as? Number)?.toDouble(),
                previousLongitude = (json["previousLongitude"] as? Number)?.toDouble(),
                heading = (json["heading"] as? Number)?.toDouble(),
                speed = (json["speed"] as? Number)?.toDouble(),
                lastUpdated = json["lastUpdated"] as? String,
                iconId = json["iconId"] as? String,
                customColor = json["customColor"] as? Int,
                metadata = json["metadata"] as? Map<String, Any>,
                state = (json["state"] as? String)?.let { DynamicMarkerState.fromString(it) }
                    ?: DynamicMarkerState.TRACKING,
                showTrail = json["showTrail"] as? Boolean ?: false,
                trailLength = json["trailLength"] as? Int ?: 50,
                positionHistory = positionHistoryList
            )
        }
    }

    /**
     * Returns the current position as a LatLng.
     */
    val position: LatLng
        get() = LatLng(latitude, longitude)

    /**
     * Returns the previous position as a LatLng, or null if not set.
     */
    val previousPosition: LatLng?
        get() = if (previousLatitude != null && previousLongitude != null) {
            LatLng(previousLatitude, previousLongitude)
        } else {
            null
        }

    /**
     * Converts this DynamicMarker to a JSON map.
     */
    fun toJson(): Map<String, Any?> {
        return mapOf(
            "id" to id,
            "latitude" to latitude,
            "longitude" to longitude,
            "title" to title,
            "category" to category,
            "previousLatitude" to previousLatitude,
            "previousLongitude" to previousLongitude,
            "heading" to heading,
            "speed" to speed,
            "lastUpdated" to lastUpdated,
            "iconId" to iconId,
            "customColor" to customColor,
            "metadata" to metadata,
            "state" to state.toJsonString(),
            "showTrail" to showTrail,
            "trailLength" to trailLength,
            "positionHistory" to positionHistory?.map { it.toJson() }
        )
    }

    /**
     * Creates a copy with an updated position.
     */
    fun withPosition(
        newLatitude: Double,
        newLongitude: Double,
        newHeading: Double? = null,
        newSpeed: Double? = null,
        timestamp: String? = null
    ): DynamicMarker {
        // Build new position history
        val newHistory = mutableListOf<LatLng>()
        positionHistory?.let { newHistory.addAll(it) }
        newHistory.add(LatLng(latitude, longitude))

        // Trim to max trail length
        while (newHistory.size > trailLength) {
            newHistory.removeAt(0)
        }

        return copy(
            latitude = newLatitude,
            longitude = newLongitude,
            previousLatitude = latitude,
            previousLongitude = longitude,
            heading = newHeading ?: heading,
            speed = newSpeed ?: speed,
            lastUpdated = timestamp ?: lastUpdated,
            positionHistory = if (showTrail) newHistory else null
        )
    }

    /**
     * Gets the marker color, using custom color if available.
     */
    fun getMarkerColor(): Int {
        return customColor ?: getDefaultColorForCategory()
    }

    /**
     * Gets the default color for the marker category.
     */
    private fun getDefaultColorForCategory(): Int {
        return when (category.lowercase()) {
            "vehicle", "car", "truck", "bus" -> Color.parseColor("#2196F3") // Blue
            "drone", "aircraft", "plane", "helicopter" -> Color.parseColor("#9C27B0") // Purple
            "person", "pedestrian", "runner", "cyclist" -> Color.parseColor("#4CAF50") // Green
            "delivery", "courier", "package" -> Color.parseColor("#FF9800") // Orange
            "emergency", "ambulance", "police", "fire" -> Color.parseColor("#F44336") // Red
            "transit", "train", "subway", "tram" -> Color.parseColor("#00BCD4") // Cyan
            "boat", "ship", "vessel" -> Color.parseColor("#3F51B5") // Indigo
            else -> Color.parseColor("#2E6578") // Primary teal (default)
        }
    }

    /**
     * Gets the icon resource name for the marker.
     */
    fun getIconResourceName(): String {
        return iconId ?: getDefaultIconForCategory()
    }

    /**
     * Gets the default icon for the marker category.
     */
    private fun getDefaultIconForCategory(): String {
        return when (category.lowercase()) {
            "vehicle", "car" -> "ic_vehicle"
            "truck" -> "ic_truck"
            "bus" -> "ic_bus"
            "drone" -> "ic_drone"
            "aircraft", "plane" -> "ic_aircraft"
            "helicopter" -> "ic_helicopter"
            "person", "pedestrian" -> "ic_person"
            "runner" -> "ic_runner"
            "cyclist" -> "ic_cyclist"
            "delivery", "courier" -> "ic_delivery"
            "emergency", "ambulance" -> "ic_ambulance"
            "police" -> "ic_police"
            "fire" -> "ic_fire_station"
            "transit", "train" -> "ic_train"
            "subway" -> "ic_subway"
            "boat", "ship" -> "ic_boat"
            else -> "ic_marker_dynamic"
        }
    }

    override fun equals(other: Any?): Boolean {
        if (this === other) return true
        if (javaClass != other?.javaClass) return false
        other as DynamicMarker
        return id == other.id
    }

    override fun hashCode(): Int {
        return id.hashCode()
    }

    override fun toString(): String {
        return "DynamicMarker(id='$id', title='$title', category='$category', " +
                "lat=$latitude, lng=$longitude, state=${state.toJsonString()})"
    }
}
