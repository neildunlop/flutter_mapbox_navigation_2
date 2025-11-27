package com.eopeter.fluttermapboxnavigation.models

import android.graphics.Color
import android.util.Log

/**
 * Configuration for the trip progress panel display.
 *
 * Controls what elements are shown in the navigation info panel and how they behave.
 * This is passed from the Dart layer via method channel arguments.
 */
data class TripProgressConfig(
    /** Whether to show skip previous/next waypoint buttons. */
    val showSkipButtons: Boolean = true,

    /** Whether to show the overall trip progress bar. */
    val showProgressBar: Boolean = true,

    /** Whether to show the estimated time of arrival. */
    val showEta: Boolean = true,

    /** Whether to show the total distance remaining to destination. */
    val showTotalDistance: Boolean = true,

    /** Whether to show the end navigation button in the panel. */
    val showEndNavigationButton: Boolean = true,

    /** Whether to show the waypoint count (e.g., "Waypoint 3/8"). */
    val showWaypointCount: Boolean = true,

    /** Whether to show distance to the next waypoint. */
    val showDistanceToNext: Boolean = true,

    /** Whether to show duration to the next waypoint. */
    val showDurationToNext: Boolean = true,

    /** Whether to play audio feedback when buttons are pressed. */
    val enableAudioFeedback: Boolean = true,

    /** Custom panel height in dp. If null, uses default height. */
    val panelHeight: Int? = null,

    /** Theme configuration for colors, typography, etc. */
    val theme: TripProgressTheme = TripProgressTheme.light()
) {
    companion object {
        /** Default configuration with all features enabled. */
        fun defaults() = TripProgressConfig()

        /** Minimal configuration showing only essential info. */
        fun minimal() = TripProgressConfig(
            showSkipButtons = false,
            showProgressBar = false,
            showEta = false,
            showTotalDistance = false,
            showWaypointCount = false,
            enableAudioFeedback = false
        )

        /**
         * Creates a config from a map (parsed from Dart arguments).
         */
        fun fromMap(map: Map<*, *>?): TripProgressConfig {
            if (map == null) {
                Log.d("TripProgressConfig", "🎨 fromMap: map is null, using defaults()")
                return defaults()
            }

            Log.d("TripProgressConfig", "🎨 fromMap: received map with keys=${map.keys}")
            val themeMap = map["theme"] as? Map<*, *>
            Log.d("TripProgressConfig", "🎨 fromMap: themeMap=${if (themeMap == null) "null" else "present with keys=${themeMap.keys}"}")

            return TripProgressConfig(
                showSkipButtons = map["showSkipButtons"] as? Boolean ?: true,
                showProgressBar = map["showProgressBar"] as? Boolean ?: true,
                showEta = map["showEta"] as? Boolean ?: true,
                showTotalDistance = map["showTotalDistance"] as? Boolean ?: true,
                showEndNavigationButton = map["showEndNavigationButton"] as? Boolean ?: true,
                showWaypointCount = map["showWaypointCount"] as? Boolean ?: true,
                showDistanceToNext = map["showDistanceToNext"] as? Boolean ?: true,
                showDurationToNext = map["showDurationToNext"] as? Boolean ?: true,
                enableAudioFeedback = map["enableAudioFeedback"] as? Boolean ?: true,
                panelHeight = (map["panelHeight"] as? Number)?.toInt(),
                theme = TripProgressTheme.fromMap(themeMap)
            )
        }
    }
}

/**
 * Theme configuration for the trip progress panel.
 *
 * Customize colors, typography, and dimensions to match your app's design.
 */
data class TripProgressTheme(
    /** Primary color used for icons, progress bars, and highlights. */
    val primaryColor: Int = Color.parseColor("#2196F3"),

    /** Accent color used for checkpoints and important markers. */
    val accentColor: Int = Color.parseColor("#FF5722"),

    /** Background color of the panel. */
    val backgroundColor: Int = Color.WHITE,

    /** Primary text color for waypoint names and main info. */
    val textPrimaryColor: Int = Color.parseColor("#1A1A1A"),

    /** Secondary text color for distances, times, and labels. */
    val textSecondaryColor: Int = Color.parseColor("#666666"),

    /** Background color for skip/prev buttons. */
    val buttonBackgroundColor: Int = Color.parseColor("#E3F2FD"),

    /** Color for the end navigation button. */
    val endButtonColor: Int = Color.parseColor("#E53935"),

    /** Color for the progress bar fill. */
    val progressBarColor: Int = Color.parseColor("#2196F3"),

    /** Background color for the progress bar track. */
    val progressBarBackgroundColor: Int = Color.parseColor("#E3F2FD"),

    /** Corner radius in dp for the panel and buttons. */
    val cornerRadius: Float = 16f,

    /** Size of the skip/prev buttons in dp. */
    val buttonSize: Int = 36,

    /** Size of waypoint icons in dp. */
    val iconSize: Int = 32,

    /** Custom colors for different waypoint categories. */
    val categoryColors: Map<String, Int> = defaultCategoryColors
) {
    companion object {
        /**
         * Default category colors aligned with app's design system.
         * Primary: #2E6578 (teal), Tertiary: #5D5D70 (muted purple-gray)
         */
        val defaultCategoryColors = mapOf(
            "checkpoint" to Color.parseColor("#5D5D70"),     // Tertiary - muted purple-gray (app tertiary)
            "waypoint" to Color.parseColor("#2E6578"),       // Primary teal (app primary)
            "poi" to Color.parseColor("#4CAF50"),            // Green
            "scenic" to Color.parseColor("#8BC34A"),         // Light Green
            "restaurant" to Color.parseColor("#FF9800"),     // Orange
            "food" to Color.parseColor("#FF9800"),           // Orange
            "hotel" to Color.parseColor("#5D5D70"),          // Tertiary
            "accommodation" to Color.parseColor("#5D5D70"),  // Tertiary
            "petrol_station" to Color.parseColor("#607D8B"), // Blue Grey
            "fuel" to Color.parseColor("#607D8B"),           // Blue Grey
            "parking" to Color.parseColor("#795548"),        // Brown
            "hospital" to Color.parseColor("#F44336"),       // Red
            "medical" to Color.parseColor("#F44336"),        // Red
            "police" to Color.parseColor("#3F51B5"),         // Indigo
            "charging_station" to Color.parseColor("#00BCD4") // Cyan
        )

        /** Light theme preset. */
        fun light() = TripProgressTheme()

        /** Dark theme preset. */
        fun dark() = TripProgressTheme(
            primaryColor = Color.parseColor("#64B5F6"),
            accentColor = Color.parseColor("#FF7043"),
            backgroundColor = Color.parseColor("#1E1E1E"),
            textPrimaryColor = Color.WHITE,
            textSecondaryColor = Color.parseColor("#B0B0B0"),
            buttonBackgroundColor = Color.parseColor("#2D2D2D"),
            endButtonColor = Color.parseColor("#EF5350"),
            progressBarColor = Color.parseColor("#64B5F6"),
            progressBarBackgroundColor = Color.parseColor("#2D2D2D")
        )

        /**
         * Creates a theme from a map (parsed from Dart arguments).
         */
        fun fromMap(map: Map<*, *>?): TripProgressTheme {
            if (map == null) {
                Log.d("TripProgressTheme", "🎨 fromMap: map is null, using light() default")
                return light()
            }

            Log.d("TripProgressTheme", "🎨 fromMap: received map with keys: ${map.keys}")
            Log.d("TripProgressTheme", "🎨 fromMap: backgroundColor raw=${map["backgroundColor"]} (type=${map["backgroundColor"]?.javaClass?.name})")
            Log.d("TripProgressTheme", "🎨 fromMap: primaryColor raw=${map["primaryColor"]} (type=${map["primaryColor"]?.javaClass?.name})")

            @Suppress("UNCHECKED_CAST")
            val categoryColorsMap = (map["categoryColors"] as? Map<String, Number>)?.mapValues {
                it.value.toInt()
            } ?: defaultCategoryColors

            return TripProgressTheme(
                primaryColor = (map["primaryColor"] as? Number)?.toInt() ?: Color.parseColor("#2196F3"),
                accentColor = (map["accentColor"] as? Number)?.toInt() ?: Color.parseColor("#FF5722"),
                backgroundColor = (map["backgroundColor"] as? Number)?.toInt() ?: Color.WHITE,
                textPrimaryColor = (map["textPrimaryColor"] as? Number)?.toInt() ?: Color.parseColor("#1A1A1A"),
                textSecondaryColor = (map["textSecondaryColor"] as? Number)?.toInt() ?: Color.parseColor("#666666"),
                buttonBackgroundColor = (map["buttonBackgroundColor"] as? Number)?.toInt() ?: Color.parseColor("#E3F2FD"),
                endButtonColor = (map["endButtonColor"] as? Number)?.toInt() ?: Color.parseColor("#E53935"),
                progressBarColor = (map["progressBarColor"] as? Number)?.toInt() ?: Color.parseColor("#2196F3"),
                progressBarBackgroundColor = (map["progressBarBackgroundColor"] as? Number)?.toInt() ?: Color.parseColor("#E3F2FD"),
                cornerRadius = (map["cornerRadius"] as? Number)?.toFloat() ?: 16f,
                buttonSize = (map["buttonSize"] as? Number)?.toInt() ?: 36,
                iconSize = (map["iconSize"] as? Number)?.toInt() ?: 32,
                categoryColors = categoryColorsMap
            )
        }
    }

    /**
     * Gets the color for a specific category, falling back to primary color.
     */
    fun getCategoryColor(category: String): Int {
        return categoryColors[category.lowercase()] ?: primaryColor
    }
}
