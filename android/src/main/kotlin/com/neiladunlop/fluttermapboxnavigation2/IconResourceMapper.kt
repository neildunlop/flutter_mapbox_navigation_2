package com.neiladunlop.fluttermapboxnavigation2

import android.content.Context

/**
 * Maps icon IDs to Android drawable resources
 */
object IconResourceMapper {
    
    /**
     * Gets the drawable resource ID for a given icon ID
     */
    fun getIconResourceId(context: Context, iconId: String): Int {
        val resourceName = "ic_${iconId.lowercase().replace(" ", "_")}"
        return context.resources.getIdentifier(resourceName, "drawable", context.packageName)
    }

    /**
     * Gets the default icon resource ID
     */
    fun getDefaultIconResourceId(context: Context): Int {
        return context.resources.getIdentifier("ic_pin", "drawable", context.packageName)
    }

    /**
     * Checks if an icon resource exists
     */
    fun iconExists(context: Context, iconId: String): Boolean {
        val resourceId = getIconResourceId(context, iconId)
        return resourceId != 0
    }

    /**
     * Gets all available icon IDs
     */
    fun getAvailableIcons(): List<String> {
        return listOf(
            // Basic icons
            "pin",
            "star",
            "heart",
            "flag",
            "warning",
            "info",
            "question",
            
            // Transportation
            "petrol_station",
            "charging_station",
            "parking",
            "bus_stop",
            "train_station",
            "airport",
            "port",
            
            // Food & Services
            "restaurant",
            "cafe",
            "hotel",
            "shop",
            "pharmacy",
            "hospital",
            "police",
            "fire_station",
            
            // Scenic & Recreation
            "scenic",
            "park",
            "beach",
            "mountain",
            "lake",
            "waterfall",
            "viewpoint",
            "hiking",
            
            // Safety & Traffic
            "speed_camera",
            "accident",
            "construction",
            "traffic_light",
            "speed_bump",
            "school_zone",
            
            // Additional services
            "school",
            "church",
            "shopping",
            "bank",
            "atm",
            "gas_station",
            "car_wash",
            "toll",
            "border",
            "custom"
        )
    }
} 