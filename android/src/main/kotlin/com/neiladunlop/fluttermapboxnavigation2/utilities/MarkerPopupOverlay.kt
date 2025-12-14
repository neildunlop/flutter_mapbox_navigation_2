package com.neiladunlop.fluttermapboxnavigation2.utilities

import android.graphics.Color
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.util.Log
import android.util.TypedValue
import android.view.Gravity
import android.view.View
import android.view.ViewGroup
import android.view.animation.AccelerateDecelerateInterpolator
import android.widget.FrameLayout
import android.widget.ImageButton
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.TextView
import androidx.cardview.widget.CardView
import com.neiladunlop.fluttermapboxnavigation2.FlutterMapboxNavigationPlugin
import com.neiladunlop.fluttermapboxnavigation2.R
import com.neiladunlop.fluttermapboxnavigation2.StaticMarkerManager
import com.neiladunlop.fluttermapboxnavigation2.activity.NavigationActivity
import com.neiladunlop.fluttermapboxnavigation2.models.StaticMarker
import com.neiladunlop.fluttermapboxnavigation2.models.MapBoxEvents
import com.neiladunlop.fluttermapboxnavigation2.models.TripProgressTheme
import org.json.JSONObject

/**
 * Manages a floating marker info card that appears above the navigation info panel.
 *
 * This class creates a CardView overlay that floats above the Mapbox Drop-in UI,
 * showing details when a marker is tapped.
 *
 * The appearance uses the same theme as the trip progress panel for visual consistency.
 */
class MarkerPopupOverlay(private val activity: NavigationActivity) {

    // Use the same theme as trip progress for consistency
    private val theme: TripProgressTheme
        get() = FlutterMapboxNavigationPlugin.tripProgressConfig.theme

    private var currentMarker: StaticMarker? = null
    private var markerInfoCard: CardView? = null
    private var isVisible = false

    // Bottom margin to position card above the info panel (adjust as needed)
    private val bottomMarginDp = 180

    /**
     * Initialize the overlay and set up marker tap listener.
     */
    fun initialize() {
        StaticMarkerManager.getInstance().setMarkerTapListener { marker ->
            activity.runOnUiThread {
                handleMarkerTap(marker)
            }
        }
        Log.d("MarkerPopupOverlay", "Initialized marker tap listener")
    }

    /**
     * Clean up resources when navigation ends.
     */
    fun cleanup() {
        StaticMarkerManager.getInstance().setMarkerTapListener(null)
        hideMarkerInfo()
        Log.d("MarkerPopupOverlay", "Cleaned up")
    }

    private fun handleMarkerTap(marker: StaticMarker) {
        Log.d("MarkerPopupOverlay", "Marker tapped: ${marker.title}")

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

    private fun showMarkerInfo(marker: StaticMarker) {
        // Get the root FrameLayout - try multiple approaches
        var rootView: ViewGroup? = activity.findViewById<FrameLayout>(android.R.id.content)
        if (rootView == null) {
            rootView = activity.window.decorView.findViewById<ViewGroup>(android.R.id.content)
        }
        if (rootView == null) {
            rootView = activity.window.decorView as? ViewGroup
        }

        if (rootView == null) {
            Log.e("MarkerPopupOverlay", "Could not find root view")
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
            Log.e("MarkerPopupOverlay", "Failed to add card: ${e.message}")
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

    private fun createMarkerInfoCard(marker: StaticMarker): CardView {
        val context = activity

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

            // Header row with icon, title, and close button
            val headerLayout = LinearLayout(context).apply {
                orientation = LinearLayout.HORIZONTAL
                gravity = Gravity.CENTER_VERTICAL
            }

            // Icon circle - use marker's own color method for consistency with map markers
            val iconContainerSize = dpToPx(40)  // Match the trip progress panel icon size
            val iconContainer = FrameLayout(context).apply {
                layoutParams = LinearLayout.LayoutParams(iconContainerSize, iconContainerSize)
                background = createCircleDrawable(marker.getMarkerColor())
            }

            val iconView = ImageView(context).apply {
                val innerIconSize = dpToPx(24)  // Match the trip progress panel inner icon size
                layoutParams = FrameLayout.LayoutParams(innerIconSize, innerIconSize).apply {
                    gravity = Gravity.CENTER
                }
                // Use StaticMarkerManager's icon mapping for consistency with map markers
                setImageResource(StaticMarkerManager.getInstance().getDrawableIdForMarker(marker))
                // Use SRC_IN mode to properly tint the icon white
                setColorFilter(Color.WHITE, android.graphics.PorterDuff.Mode.SRC_IN)
            }
            iconContainer.addView(iconView)
            headerLayout.addView(iconContainer)

            // Title and category container
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

            // Title - use theme text color
            val titleView = TextView(context).apply {
                text = marker.title
                setTextSize(TypedValue.COMPLEX_UNIT_SP, 17f)
                setTextColor(theme.textPrimaryColor)
                typeface = Typeface.DEFAULT_BOLD
                maxLines = 2
            }
            titleContainer.addView(titleView)

            // Category - use marker's own color for consistency
            if (marker.category.isNotEmpty()) {
                val categoryView = TextView(context).apply {
                    text = formatCategory(marker.category)
                    setTextSize(TypedValue.COMPLEX_UNIT_SP, 13f)
                    setTextColor(marker.getMarkerColor())
                    setPadding(0, dpToPx(2), 0, 0)
                }
                titleContainer.addView(categoryView)
            }

            headerLayout.addView(titleContainer)

            // Close button - use theme button background
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

            // Description if available - use theme secondary text color
            val description = marker.description ?: marker.metadata?.get("description")?.toString()
            if (!description.isNullOrEmpty()) {
                val descriptionView = TextView(context).apply {
                    text = description
                    setTextSize(TypedValue.COMPLEX_UNIT_SP, 14f)
                    setTextColor(theme.textSecondaryColor)
                    setPadding(0, dpToPx(10), 0, 0)
                    maxLines = 3
                    lineHeight = dpToPx(20)
                }
                contentLayout.addView(descriptionView)
            }

            // ETA row if available - use theme primary color
            val eta = marker.metadata?.get("eta")?.toString()
            if (!eta.isNullOrEmpty() && eta != "null") {
                val etaLayout = LinearLayout(context).apply {
                    orientation = LinearLayout.HORIZONTAL
                    gravity = Gravity.CENTER_VERTICAL
                    setPadding(0, dpToPx(10), 0, 0)
                }

                val clockIcon = ImageView(context).apply {
                    val iconSize = dpToPx(16)
                    layoutParams = LinearLayout.LayoutParams(iconSize, iconSize)
                    setImageResource(android.R.drawable.ic_menu_recent_history)
                    setColorFilter(theme.primaryColor)
                }
                etaLayout.addView(clockIcon)

                val etaView = TextView(context).apply {
                    text = "ETA: $eta"
                    setTextSize(TypedValue.COMPLEX_UNIT_SP, 13f)
                    setTextColor(theme.primaryColor)
                    setPadding(dpToPx(6), 0, 0, 0)
                }
                etaLayout.addView(etaView)

                contentLayout.addView(etaLayout)
            }

            addView(contentLayout)
        }
    }

    private fun createCircleDrawable(color: Int): GradientDrawable {
        return GradientDrawable().apply {
            shape = GradientDrawable.OVAL
            setColor(color)
        }
    }

    private fun formatCategory(category: String): String {
        return category.replace("_", " ")
            .split(" ")
            .joinToString(" ") { it.replaceFirstChar { c -> c.uppercase() } }
    }

    private fun sendEventToFlutter(marker: StaticMarker) {
        try {
            val eventData = mutableMapOf<String, Any>(
                "type" to "marker_tap",
                "mode" to "fullscreen",
                "marker_id" to marker.id,
                "marker_title" to marker.title,
                "marker_category" to marker.category,
                "marker_latitude" to marker.latitude,
                "marker_longitude" to marker.longitude
            )

            marker.description?.let { eventData["marker_description"] = it }
            marker.iconId?.let { eventData["marker_iconId"] = it }
            marker.metadata?.let { metadata ->
                metadata.forEach { (key, value) ->
                    eventData["marker_metadata_$key"] = value
                }
            }

            val jsonObject = JSONObject(eventData as Map<String, Any?>)
            PluginUtilities.sendEvent(MapBoxEvents.MARKER_TAP_FULLSCREEN, jsonObject.toString())

        } catch (e: Exception) {
            Log.e("MarkerPopupOverlay", "Error sending event to Flutter: ${e.message}")
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
