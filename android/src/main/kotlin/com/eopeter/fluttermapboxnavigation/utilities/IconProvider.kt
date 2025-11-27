package com.eopeter.fluttermapboxnavigation.utilities

import com.eopeter.fluttermapboxnavigation.R
import com.eopeter.fluttermapboxnavigation.models.TripProgressTheme

/**
 * Interface for providing icons and colors based on category/iconId.
 *
 * Implement this interface to customize the icons and colors used in the
 * trip progress panel. This allows for full customization without modifying
 * the core component.
 *
 * Example usage:
 * ```kotlin
 * class MyIconProvider : IconProvider {
 *     override fun getIconResource(iconId: String?, category: String): Int {
 *         return when (iconId?.lowercase() ?: category.lowercase()) {
 *             "custom_icon" -> R.drawable.my_custom_icon
 *             else -> DefaultIconProvider.getIconResource(iconId, category)
 *         }
 *     }
 * }
 * ```
 */
interface IconProvider {
    /**
     * Get the drawable resource ID for an icon.
     *
     * @param iconId Optional specific icon ID (takes precedence over category)
     * @param category The waypoint category (e.g., "checkpoint", "waypoint", "poi")
     * @return Drawable resource ID
     */
    fun getIconResource(iconId: String?, category: String): Int

    /**
     * Get the color for a category.
     *
     * @param category The waypoint category
     * @param theme The current theme configuration
     * @return Color int value
     */
    fun getCategoryColor(category: String, theme: TripProgressTheme): Int
}

/**
 * Default implementation of IconProvider.
 *
 * Provides a standard set of icons for common waypoint types including:
 * - Checkpoints (flag)
 * - Waypoints (pin)
 * - POIs (various types like restaurants, hotels, fuel stations, etc.)
 *
 * Uses Material Design-inspired icons and colors.
 */
object DefaultIconProvider : IconProvider {

    /**
     * Get the drawable resource ID for an icon.
     *
     * Falls back to a pin icon if the iconId/category is not recognized.
     */
    override fun getIconResource(iconId: String?, category: String): Int {
        val id = (iconId ?: category).lowercase()

        return when (id) {
            "flag", "checkpoint" -> R.drawable.ic_flag
            "pin", "waypoint" -> R.drawable.ic_pin
            "scenic", "viewpoint", "photo" -> R.drawable.ic_scenic
            "petrol_station", "petrol", "gas", "fuel" -> R.drawable.ic_petrol_station
            "restaurant", "food", "dining" -> R.drawable.ic_restaurant
            "hotel", "accommodation", "lodging" -> R.drawable.ic_hotel
            "parking", "car_park" -> R.drawable.ic_parking
            "hospital", "medical", "clinic" -> R.drawable.ic_hospital
            "police", "emergency" -> R.drawable.ic_police
            "charging_station", "charging", "ev" -> R.drawable.ic_charging_station
            "attraction", "landmark" -> R.drawable.ic_flag
            "rest_area", "rest_stop" -> R.drawable.ic_parking
            "shop", "shopping" -> R.drawable.ic_pin
            else -> R.drawable.ic_pin
        }
    }

    /**
     * Get the color for a category.
     *
     * Uses the theme's category colors if defined, otherwise falls back to
     * the theme's primary color.
     */
    override fun getCategoryColor(category: String, theme: TripProgressTheme): Int {
        return theme.getCategoryColor(category)
    }
}
