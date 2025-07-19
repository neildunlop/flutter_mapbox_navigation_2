package com.eopeter.fluttermapboxnavigation.models

import android.graphics.Color
import com.google.gson.Gson
import com.google.gson.JsonObject

/**
 * Represents a static marker that can be displayed on the map
 */
data class StaticMarker(
    val id: String,
    val latitude: Double,
    val longitude: Double,
    val title: String,
    val category: String,
    val description: String? = null,
    val iconId: String? = null,
    val customColor: Int? = null,
    val priority: Int? = null,
    val isVisible: Boolean = true,
    val metadata: Map<String, Any>? = null
) {
    companion object {
        /**
         * Creates a StaticMarker from a JSON map
         */
        fun fromJson(json: Map<String, Any>): StaticMarker {
            return StaticMarker(
                id = json["id"] as String,
                latitude = (json["latitude"] as Number).toDouble(),
                longitude = (json["longitude"] as Number).toDouble(),
                title = json["title"] as String,
                category = json["category"] as String,
                description = json["description"] as? String,
                iconId = json["iconId"] as? String,
                customColor = json["customColor"] as? Int,
                priority = json["priority"] as? Int,
                isVisible = json["isVisible"] as? Boolean ?: true,
                metadata = json["metadata"] as? Map<String, Any>
            )
        }
    }

    /**
     * Converts the StaticMarker to a JSON map
     */
    fun toJson(): Map<String, Any> {
        val json = mutableMapOf<String, Any>(
            "id" to id,
            "latitude" to latitude,
            "longitude" to longitude,
            "title" to title,
            "category" to category,
            "isVisible" to isVisible
        )

        description?.let { json["description"] = it }
        iconId?.let { json["iconId"] = it }
        customColor?.let { json["customColor"] = it }
        priority?.let { json["priority"] = it }
        metadata?.let { json["metadata"] = it }

        return json
    }

    /**
     * Gets the color for the marker, using custom color if available
     */
    fun getMarkerColor(): Int {
        return customColor ?: getDefaultColorForCategory()
    }

    /**
     * Gets the default color for the marker category
     */
    private fun getDefaultColorForCategory(): Int {
        return when (category.lowercase()) {
            "scenic", "park", "beach", "mountain", "lake", "waterfall", "viewpoint", "hiking" -> Color.parseColor("#FF9800") // Orange
            "petrol_station", "charging_station", "parking" -> Color.parseColor("#4CAF50") // Green
            "restaurant", "cafe", "hotel", "shop" -> Color.parseColor("#F44336") // Red
            "speed_camera", "accident", "construction", "warning" -> Color.parseColor("#FF5722") // Deep Orange
            "hospital", "police", "fire_station" -> Color.parseColor("#2196F3") // Blue
            else -> Color.parseColor("#9C27B0") // Purple (default)
        }
    }

    /**
     * Gets the icon resource name for the marker
     */
    fun getIconResourceName(): String {
        return iconId ?: getDefaultIconForCategory()
    }

    /**
     * Gets the default icon for the marker category
     */
    private fun getDefaultIconForCategory(): String {
        return when (category.lowercase()) {
            "scenic", "park", "beach", "mountain", "lake", "waterfall", "viewpoint", "hiking" -> "ic_scenic"
            "petrol_station" -> "ic_petrol_station"
            "charging_station" -> "ic_charging_station"
            "parking" -> "ic_parking"
            "restaurant" -> "ic_restaurant"
            "cafe" -> "ic_cafe"
            "hotel" -> "ic_hotel"
            "shop" -> "ic_shop"
            "speed_camera" -> "ic_speed_camera"
            "accident" -> "ic_accident"
            "construction" -> "ic_construction"
            "hospital" -> "ic_hospital"
            "police" -> "ic_police"
            "fire_station" -> "ic_fire_station"
            else -> "ic_pin"
        }
    }

    override fun equals(other: Any?): Boolean {
        if (this === other) return true
        if (javaClass != other?.javaClass) return false
        other as StaticMarker
        return id == other.id
    }

    override fun hashCode(): Int {
        return id.hashCode()
    }

    override fun toString(): String {
        return "StaticMarker(id='$id', title='$title', category='$category', lat=$latitude, lng=$longitude)"
    }
} 