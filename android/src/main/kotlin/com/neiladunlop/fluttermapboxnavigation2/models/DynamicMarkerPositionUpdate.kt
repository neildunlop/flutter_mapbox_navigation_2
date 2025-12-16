package com.neiladunlop.fluttermapboxnavigation2.models

/**
 * Represents a position update for a dynamic marker.
 *
 * These updates are typically received from an external data source
 * (WebSocket, Firebase, MQTT, etc.) and converted to this format
 * before being passed to the marker manager.
 */
data class DynamicMarkerPositionUpdate(
    /** The marker ID this update applies to. */
    val markerId: String,

    /** New latitude coordinate. */
    val latitude: Double,

    /** New longitude coordinate. */
    val longitude: Double,

    /** Timestamp when this position was recorded (ISO8601 string). */
    val timestamp: String,

    /** New heading in degrees (0-360, north = 0). */
    val heading: Double? = null,

    /** Current speed in meters per second. */
    val speed: Double? = null,

    /** Altitude in meters (for 3D tracking scenarios). */
    val altitude: Double? = null,

    /** GPS accuracy in meters. */
    val accuracy: Double? = null,

    /** Additional data associated with this update. */
    val additionalData: Map<String, Any>? = null
) {
    companion object {
        /**
         * Creates a DynamicMarkerPositionUpdate from a JSON map.
         */
        @Suppress("UNCHECKED_CAST")
        fun fromJson(json: Map<String, Any>): DynamicMarkerPositionUpdate {
            return DynamicMarkerPositionUpdate(
                markerId = json["markerId"] as String,
                latitude = (json["latitude"] as Number).toDouble(),
                longitude = (json["longitude"] as Number).toDouble(),
                timestamp = json["timestamp"] as String,
                heading = (json["heading"] as? Number)?.toDouble(),
                speed = (json["speed"] as? Number)?.toDouble(),
                altitude = (json["altitude"] as? Number)?.toDouble(),
                accuracy = (json["accuracy"] as? Number)?.toDouble(),
                additionalData = json["additionalData"] as? Map<String, Any>
            )
        }

        /**
         * Creates an update from a generic map with flexible key names.
         *
         * Supports various coordinate key names:
         * - latitude/longitude
         * - lat/lng
         * - lat/lon
         */
        @Suppress("UNCHECKED_CAST")
        fun fromMap(map: Map<String, Any>): DynamicMarkerPositionUpdate {
            // Extract latitude - support multiple key names
            val lat = map["latitude"] ?: map["lat"]
            val latitude = when (lat) {
                is Number -> lat.toDouble()
                is String -> lat.toDouble()
                else -> throw IllegalArgumentException("Missing latitude")
            }

            // Extract longitude - support multiple key names
            val lng = map["longitude"] ?: map["lng"] ?: map["lon"]
            val longitude = when (lng) {
                is Number -> lng.toDouble()
                is String -> lng.toDouble()
                else -> throw IllegalArgumentException("Missing longitude")
            }

            // Extract marker ID
            val markerId = (map["markerId"] ?: map["id"]) as String

            // Parse timestamp with fallback to current time
            val timestamp = map["timestamp"] as? String
                ?: java.time.Instant.now().toString()

            return DynamicMarkerPositionUpdate(
                markerId = markerId,
                latitude = latitude,
                longitude = longitude,
                timestamp = timestamp,
                heading = (map["heading"] as? Number)?.toDouble(),
                speed = (map["speed"] as? Number)?.toDouble(),
                altitude = (map["altitude"] as? Number)?.toDouble(),
                accuracy = (map["accuracy"] as? Number)?.toDouble(),
                additionalData = map["data"] as? Map<String, Any>
                    ?: map["additionalData"] as? Map<String, Any>
            )
        }
    }

    /**
     * Returns the position as a LatLng.
     */
    val position: LatLng
        get() = LatLng(latitude, longitude)

    /**
     * Converts this update to a JSON map.
     */
    fun toJson(): Map<String, Any?> {
        return mapOf(
            "markerId" to markerId,
            "latitude" to latitude,
            "longitude" to longitude,
            "timestamp" to timestamp,
            "heading" to heading,
            "speed" to speed,
            "altitude" to altitude,
            "accuracy" to accuracy,
            "additionalData" to additionalData
        )
    }

    override fun equals(other: Any?): Boolean {
        if (this === other) return true
        if (javaClass != other?.javaClass) return false
        other as DynamicMarkerPositionUpdate
        return markerId == other.markerId && timestamp == other.timestamp
    }

    override fun hashCode(): Int {
        return markerId.hashCode() * 31 + timestamp.hashCode()
    }

    override fun toString(): String {
        return "DynamicMarkerPositionUpdate(markerId='$markerId', " +
                "lat=$latitude, lng=$longitude, timestamp=$timestamp)"
    }
}
