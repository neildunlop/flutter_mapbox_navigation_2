package com.neiladunlop.fluttermapboxnavigation2.utilities

import android.graphics.Color
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.util.Log
import android.util.TypedValue
import android.view.Gravity
import android.view.ViewGroup
import android.view.animation.AccelerateDecelerateInterpolator
import android.widget.FrameLayout
import android.widget.ImageButton
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.TextView
import androidx.cardview.widget.CardView
import com.neiladunlop.fluttermapboxnavigation2.DynamicMarkerManager
import com.neiladunlop.fluttermapboxnavigation2.FlutterMapboxNavigationPlugin
import com.neiladunlop.fluttermapboxnavigation2.activity.NavigationActivity
import com.neiladunlop.fluttermapboxnavigation2.models.DynamicMarker
import com.neiladunlop.fluttermapboxnavigation2.models.MapBoxEvents
import com.neiladunlop.fluttermapboxnavigation2.models.TripProgressTheme
import org.json.JSONObject
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import kotlin.math.roundToInt

/**
 * Manages a floating info card for dynamic markers (e.g., team position markers).
 *
 * Shows team name, speed, and last update time when a dynamic marker is tapped.
 * Uses the same theme as the trip progress panel for visual consistency.
 */
class DynamicMarkerPopupOverlay(private val activity: NavigationActivity) {

    // Use the same theme as trip progress for consistency
    private val theme: TripProgressTheme
        get() = FlutterMapboxNavigationPlugin.tripProgressConfig.theme

    private var currentMarker: DynamicMarker? = null
    private var markerInfoCard: CardView? = null
    private var isVisible = false

    // Bottom margin to position card above the info panel
    private val bottomMarginDp = 180

    /**
     * Initialize the overlay and set up dynamic marker tap listener.
     */
    fun initialize() {
        DynamicMarkerManager.getInstance().setMarkerTapListener { marker ->
            activity.runOnUiThread {
                handleMarkerTap(marker)
            }
        }
        Log.d("DynamicMarkerPopup", "Initialized dynamic marker tap listener")
    }

    /**
     * Clean up resources when navigation ends.
     */
    fun cleanup() {
        DynamicMarkerManager.getInstance().setMarkerTapListener(null)
        hideMarkerInfo()
        Log.d("DynamicMarkerPopup", "Cleaned up")
    }

    private fun handleMarkerTap(marker: DynamicMarker) {
        Log.d("DynamicMarkerPopup", "Dynamic marker tapped: ${marker.title} (${marker.id})")

        // If same marker tapped, toggle visibility
        if (currentMarker?.id == marker.id && isVisible) {
            hideMarkerInfo()
            return
        }

        // Show new marker info
        currentMarker = marker
        showMarkerInfo(marker)

        // Send event to Flutter
        sendEventToFlutter(marker)
    }

    private fun showMarkerInfo(marker: DynamicMarker) {
        // Get the root FrameLayout
        var rootView: ViewGroup? = activity.findViewById<FrameLayout>(android.R.id.content)
        if (rootView == null) {
            rootView = activity.window.decorView.findViewById<ViewGroup>(android.R.id.content)
        }
        if (rootView == null) {
            rootView = activity.window.decorView as? ViewGroup
        }

        if (rootView == null) {
            Log.e("DynamicMarkerPopup", "Could not find root view")
            return
        }

        // Remove existing card if any
        markerInfoCard?.let { card ->
            (card.parent as? ViewGroup)?.removeView(card)
        }

        // Create the marker info card
        markerInfoCard = createMarkerInfoCard(marker)

        // Position at bottom, above the info panel
        val layoutParams = FrameLayout.LayoutParams(
            FrameLayout.LayoutParams.MATCH_PARENT,
            FrameLayout.LayoutParams.WRAP_CONTENT
        ).apply {
            gravity = Gravity.BOTTOM
            setMargins(dpToPx(16), 0, dpToPx(16), dpToPx(bottomMarginDp))
        }

        // Add to root view
        try {
            rootView.addView(markerInfoCard, layoutParams)
        } catch (e: Exception) {
            Log.e("DynamicMarkerPopup", "Failed to add card: ${e.message}")
            return
        }

        // Animate in
        markerInfoCard?.let { card ->
            card.alpha = 0f
            card.translationY = dpToPx(50).toFloat()
            card.animate()
                .alpha(1f)
                .translationY(0f)
                .setDuration(250)
                .setInterpolator(AccelerateDecelerateInterpolator())
                .start()
        }

        isVisible = true
    }

    private fun hideMarkerInfo() {
        markerInfoCard?.let { card ->
            card.animate()
                .alpha(0f)
                .translationY(dpToPx(50).toFloat())
                .setDuration(200)
                .setInterpolator(AccelerateDecelerateInterpolator())
                .withEndAction {
                    (card.parent as? ViewGroup)?.removeView(card)
                    markerInfoCard = null
                    currentMarker = null
                    isVisible = false
                }
                .start()
        } ?: run {
            markerInfoCard = null
            currentMarker = null
            isVisible = false
        }
    }

    private fun createMarkerInfoCard(marker: DynamicMarker): CardView {
        val context = activity

        // Extract metadata
        val metadata = marker.metadata ?: emptyMap()
        val teamName = metadata["teamName"] as? String ?: marker.title
        val carNumber = (metadata["carNumber"] as? Number)?.toInt()
        val speedKmh = (metadata["speedKmh"] as? Number)?.toDouble()
        val timestampStr = metadata["timestamp"] as? String
        val colorValue = (metadata["colorValue"] as? Number)?.toInt()

        // Get marker color
        val markerColor = when {
            colorValue != null -> colorValue
            marker.customColor != null -> marker.customColor!!
            else -> Color.BLUE
        }

        // Format display name
        val displayName = if (carNumber != null) "Car $carNumber" else teamName

        return CardView(context).apply {
            radius = theme.cornerRadius
            cardElevation = dpToPx(8).toFloat()
            setCardBackgroundColor(theme.backgroundColor)
            useCompatPadding = false

            // Main content container
            val contentLayout = LinearLayout(context).apply {
                orientation = LinearLayout.VERTICAL
                setPadding(dpToPx(16), dpToPx(14), dpToPx(16), dpToPx(14))
            }

            // Header row with color indicator, name, and close button
            val headerLayout = LinearLayout(context).apply {
                orientation = LinearLayout.HORIZONTAL
                gravity = Gravity.CENTER_VERTICAL
            }

            // Color indicator circle
            val colorIndicatorSize = dpToPx(40)
            val colorIndicator = FrameLayout(context).apply {
                layoutParams = LinearLayout.LayoutParams(colorIndicatorSize, colorIndicatorSize)
                background = createCircleDrawable(markerColor)
            }

            // Car icon inside the circle
            val iconView = ImageView(context).apply {
                val innerIconSize = dpToPx(24)
                layoutParams = FrameLayout.LayoutParams(innerIconSize, innerIconSize).apply {
                    gravity = Gravity.CENTER
                }
                setImageResource(android.R.drawable.ic_menu_directions)
                setColorFilter(Color.WHITE, android.graphics.PorterDuff.Mode.SRC_IN)
            }
            colorIndicator.addView(iconView)
            headerLayout.addView(colorIndicator)

            // Name and category container
            val titleContainer = LinearLayout(context).apply {
                orientation = LinearLayout.VERTICAL
                layoutParams = LinearLayout.LayoutParams(
                    0,
                    LinearLayout.LayoutParams.WRAP_CONTENT,
                    1f
                ).apply {
                    marginStart = dpToPx(14)
                }
            }

            // Display name (Car number or team name)
            val titleView = TextView(context).apply {
                text = displayName
                setTextSize(TypedValue.COMPLEX_UNIT_SP, 17f)
                setTextColor(theme.textPrimaryColor)
                typeface = Typeface.DEFAULT_BOLD
                maxLines = 1
            }
            titleContainer.addView(titleView)

            // Team name (if showing car number)
            if (carNumber != null && teamName.isNotEmpty()) {
                val teamNameView = TextView(context).apply {
                    text = teamName
                    setTextSize(TypedValue.COMPLEX_UNIT_SP, 13f)
                    setTextColor(markerColor)
                    setPadding(0, dpToPx(2), 0, 0)
                }
                titleContainer.addView(teamNameView)
            }

            headerLayout.addView(titleContainer)

            // Close button
            val closeButton = ImageButton(context).apply {
                val size = dpToPx(36)
                layoutParams = LinearLayout.LayoutParams(size, size)
                setImageResource(android.R.drawable.ic_menu_close_clear_cancel)
                setColorFilter(theme.textSecondaryColor)
                background = createCircleDrawable(theme.buttonBackgroundColor)
                setOnClickListener { hideMarkerInfo() }
            }
            headerLayout.addView(closeButton)

            contentLayout.addView(headerLayout)

            // Info rows container
            val infoLayout = LinearLayout(context).apply {
                orientation = LinearLayout.HORIZONTAL
                setPadding(0, dpToPx(12), 0, 0)
            }

            // Speed info
            val speedLayout = createInfoColumn(
                iconRes = android.R.drawable.ic_menu_compass,
                label = "Speed",
                value = if (speedKmh != null) "${speedKmh.roundToInt()} km/h" else "Unknown",
                color = theme.primaryColor
            )
            infoLayout.addView(speedLayout)

            // Last update info
            val lastUpdateText = formatTimestamp(timestampStr)
            val updateLayout = createInfoColumn(
                iconRes = android.R.drawable.ic_menu_recent_history,
                label = "Updated",
                value = lastUpdateText,
                color = theme.textSecondaryColor
            )
            infoLayout.addView(updateLayout)

            contentLayout.addView(infoLayout)

            addView(contentLayout)
        }
    }

    private fun createInfoColumn(
        iconRes: Int,
        label: String,
        value: String,
        color: Int
    ): LinearLayout {
        val context = activity
        return LinearLayout(context).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            layoutParams = LinearLayout.LayoutParams(
                0,
                LinearLayout.LayoutParams.WRAP_CONTENT,
                1f
            )

            // Icon
            val iconView = ImageView(context).apply {
                val iconSize = dpToPx(20)
                layoutParams = LinearLayout.LayoutParams(iconSize, iconSize)
                setImageResource(iconRes)
                setColorFilter(color)
            }
            addView(iconView)

            // Value
            val valueView = TextView(context).apply {
                text = value
                setTextSize(TypedValue.COMPLEX_UNIT_SP, 15f)
                setTextColor(theme.textPrimaryColor)
                typeface = Typeface.DEFAULT_BOLD
                gravity = Gravity.CENTER
                setPadding(0, dpToPx(4), 0, 0)
            }
            addView(valueView)

            // Label
            val labelView = TextView(context).apply {
                text = label
                setTextSize(TypedValue.COMPLEX_UNIT_SP, 11f)
                setTextColor(theme.textSecondaryColor)
                gravity = Gravity.CENTER
            }
            addView(labelView)
        }
    }

    private fun formatTimestamp(timestampStr: String?): String {
        if (timestampStr == null) return "Unknown"

        return try {
            val timestamp = java.time.Instant.parse(timestampStr)
            val now = java.time.Instant.now()
            val seconds = java.time.Duration.between(timestamp, now).seconds

            when {
                seconds < 5 -> "Just now"
                seconds < 60 -> "${seconds}s ago"
                seconds < 3600 -> "${seconds / 60}m ago"
                else -> "${seconds / 3600}h ago"
            }
        } catch (e: Exception) {
            "Unknown"
        }
    }

    private fun createCircleDrawable(color: Int): GradientDrawable {
        return GradientDrawable().apply {
            shape = GradientDrawable.OVAL
            setColor(color)
        }
    }

    private fun sendEventToFlutter(marker: DynamicMarker) {
        try {
            val eventData = mutableMapOf<String, Any>(
                "type" to "dynamic_marker_tap",
                "mode" to "fullscreen",
                "marker_id" to marker.id,
                "marker_title" to marker.title,
                "marker_category" to marker.category,
                "marker_latitude" to marker.latitude,
                "marker_longitude" to marker.longitude
            )

            marker.metadata?.let { metadata ->
                metadata.forEach { (key, value) ->
                    eventData["marker_metadata_$key"] = value
                }
            }

            val jsonObject = JSONObject(eventData as Map<String, Any?>)
            PluginUtilities.sendEvent(MapBoxEvents.DYNAMIC_MARKER_TAP, jsonObject.toString())

        } catch (e: Exception) {
            Log.e("DynamicMarkerPopup", "Error sending event to Flutter: ${e.message}")
        }
    }

    private fun dpToPx(dp: Int): Int {
        return TypedValue.applyDimension(
            TypedValue.COMPLEX_UNIT_DIP,
            dp.toFloat(),
            activity.resources.displayMetrics
        ).toInt()
    }
}
