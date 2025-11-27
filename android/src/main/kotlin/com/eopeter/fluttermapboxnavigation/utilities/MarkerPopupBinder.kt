package com.eopeter.fluttermapboxnavigation.utilities

import android.animation.ValueAnimator
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
import com.eopeter.fluttermapboxnavigation.R
import com.eopeter.fluttermapboxnavigation.StaticMarkerManager
import com.eopeter.fluttermapboxnavigation.activity.NavigationActivity
import com.eopeter.fluttermapboxnavigation.models.StaticMarker
import com.eopeter.fluttermapboxnavigation.models.MapBoxEvents
import com.mapbox.navigation.ui.base.lifecycle.UIBinder
import com.mapbox.navigation.ui.base.lifecycle.UIComponent
import com.mapbox.navigation.core.lifecycle.MapboxNavigationObserver
import com.mapbox.navigation.core.MapboxNavigation
import org.json.JSONObject

/**
 * UIBinder for showing marker info in the Drop-in UI's info panel.
 *
 * This binder adds marker details as content within the navigation info panel,
 * providing a native, integrated experience that works alongside ETA and
 * distance information.
 */
class MarkerPopupBinder(private val activity: NavigationActivity) : UIBinder {

    private var currentMarker: StaticMarker? = null
    private var markerInfoCard: CardView? = null
    private var parentViewGroup: ViewGroup? = null
    private var isVisible = false

    override fun bind(viewGroup: ViewGroup): MapboxNavigationObserver {
        parentViewGroup = viewGroup

        return object : UIComponent() {
            override fun onAttached(mapboxNavigation: MapboxNavigation) {
                super.onAttached(mapboxNavigation)

                // Listen for marker tap events
                StaticMarkerManager.getInstance().setMarkerTapListener { marker ->
                    activity.runOnUiThread {
                        handleMarkerTap(marker)
                    }
                }
            }

            override fun onDetached(mapboxNavigation: MapboxNavigation) {
                super.onDetached(mapboxNavigation)
                StaticMarkerManager.getInstance().setMarkerTapListener(null)
                hideMarkerInfo()
            }
        }
    }

    private fun handleMarkerTap(marker: StaticMarker) {
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
        val parent = parentViewGroup ?: return

        // Remove existing card if any
        markerInfoCard?.let { card ->
            parent.removeView(card)
        }

        // Create the marker info card
        markerInfoCard = createMarkerInfoCard(marker)

        // Add to the info panel content area
        val layoutParams = LinearLayout.LayoutParams(
            LinearLayout.LayoutParams.MATCH_PARENT,
            LinearLayout.LayoutParams.WRAP_CONTENT
        ).apply {
            setMargins(0, dpToPx(8), 0, dpToPx(8))
        }

        // Try to add at the top of the content area
        if (parent is LinearLayout) {
            parent.addView(markerInfoCard, 0, layoutParams)
        } else {
            parent.addView(markerInfoCard, layoutParams)
        }

        // Animate in
        markerInfoCard?.let { card ->
            card.alpha = 0f
            card.translationY = -dpToPx(20).toFloat()
            card.animate()
                .alpha(1f)
                .translationY(0f)
                .setDuration(200)
                .setInterpolator(AccelerateDecelerateInterpolator())
                .start()
        }

        isVisible = true
    }

    private fun hideMarkerInfo() {
        markerInfoCard?.let { card ->
            card.animate()
                .alpha(0f)
                .translationY(-dpToPx(20).toFloat())
                .setDuration(150)
                .setInterpolator(AccelerateDecelerateInterpolator())
                .withEndAction {
                    parentViewGroup?.removeView(card)
                    markerInfoCard = null
                    currentMarker = null
                    isVisible = false
                }
                .start()
        }
    }

    private fun createMarkerInfoCard(marker: StaticMarker): CardView {
        val context = activity

        return CardView(context).apply {
            radius = dpToPx(12).toFloat()
            cardElevation = dpToPx(4).toFloat()
            setCardBackgroundColor(Color.WHITE)
            useCompatPadding = true

            // Main content container
            val contentLayout = LinearLayout(context).apply {
                orientation = LinearLayout.VERTICAL
                setPadding(dpToPx(16), dpToPx(12), dpToPx(16), dpToPx(12))
            }

            // Header row with icon, title, and close button
            val headerLayout = LinearLayout(context).apply {
                orientation = LinearLayout.HORIZONTAL
                gravity = Gravity.CENTER_VERTICAL
            }

            // Icon circle
            val iconContainer = FrameLayout(context).apply {
                val size = dpToPx(40)
                layoutParams = LinearLayout.LayoutParams(size, size)
                background = createCircleDrawable(getMarkerColor(marker))
            }

            val iconView = ImageView(context).apply {
                val iconSize = dpToPx(20)
                layoutParams = FrameLayout.LayoutParams(iconSize, iconSize).apply {
                    gravity = Gravity.CENTER
                }
                setImageResource(getMarkerIconResource(marker))
                setColorFilter(Color.WHITE)
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
                    marginStart = dpToPx(12)
                }
            }

            // Title
            val titleView = TextView(context).apply {
                text = marker.title
                setTextSize(TypedValue.COMPLEX_UNIT_SP, 16f)
                setTextColor(Color.parseColor("#1a1a1a"))
                typeface = Typeface.DEFAULT_BOLD
                maxLines = 1
            }
            titleContainer.addView(titleView)

            // Category
            if (marker.category.isNotEmpty()) {
                val categoryView = TextView(context).apply {
                    text = formatCategory(marker.category)
                    setTextSize(TypedValue.COMPLEX_UNIT_SP, 12f)
                    setTextColor(getMarkerColor(marker))
                }
                titleContainer.addView(categoryView)
            }

            headerLayout.addView(titleContainer)

            // Close button
            val closeButton = ImageButton(context).apply {
                val size = dpToPx(32)
                layoutParams = LinearLayout.LayoutParams(size, size)
                setImageResource(android.R.drawable.ic_menu_close_clear_cancel)
                setColorFilter(Color.parseColor("#888888"))
                background = createCircleDrawable(Color.parseColor("#f0f0f0"))
                setOnClickListener { hideMarkerInfo() }
            }
            headerLayout.addView(closeButton)

            contentLayout.addView(headerLayout)

            // Description if available
            val description = marker.description ?: marker.metadata?.get("description")?.toString()
            if (!description.isNullOrEmpty()) {
                val descriptionView = TextView(context).apply {
                    text = description
                    setTextSize(TypedValue.COMPLEX_UNIT_SP, 13f)
                    setTextColor(Color.parseColor("#555555"))
                    setPadding(0, dpToPx(8), 0, 0)
                    maxLines = 2
                }
                contentLayout.addView(descriptionView)
            }

            // ETA row if available
            val eta = marker.metadata?.get("eta")?.toString()
            if (!eta.isNullOrEmpty() && eta != "null") {
                val etaLayout = LinearLayout(context).apply {
                    orientation = LinearLayout.HORIZONTAL
                    gravity = Gravity.CENTER_VERTICAL
                    setPadding(0, dpToPx(8), 0, 0)
                }

                val clockIcon = ImageView(context).apply {
                    val iconSize = dpToPx(14)
                    layoutParams = LinearLayout.LayoutParams(iconSize, iconSize)
                    setImageResource(android.R.drawable.ic_menu_recent_history)
                    setColorFilter(Color.parseColor("#888888"))
                }
                etaLayout.addView(clockIcon)

                val etaView = TextView(context).apply {
                    text = "ETA: $eta"
                    setTextSize(TypedValue.COMPLEX_UNIT_SP, 12f)
                    setTextColor(Color.parseColor("#666666"))
                    setPadding(dpToPx(4), 0, 0, 0)
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

    private fun getMarkerColor(marker: StaticMarker): Int {
        marker.customColor?.let { return it }

        // Colors aligned with app's design system:
        // Primary: #2E6578 (teal), Tertiary: #5D5D70 (muted purple-gray)
        return when (marker.category.lowercase()) {
            "checkpoint" -> Color.parseColor("#5D5D70") // Tertiary - muted purple-gray (matches app tertiary)
            "waypoint" -> Color.parseColor("#2E6578")   // Primary teal (matches app primary)
            "poi" -> Color.parseColor("#4CAF50")        // Green
            "scenic" -> Color.parseColor("#8BC34A")     // Light Green
            "restaurant", "food" -> Color.parseColor("#FF9800") // Orange
            "hotel", "accommodation" -> Color.parseColor("#5D5D70") // Tertiary
            "petrol_station", "fuel" -> Color.parseColor("#607D8B") // Blue Grey
            else -> Color.parseColor("#2E6578")         // Default primary teal
        }
    }

    private fun getMarkerIconResource(marker: StaticMarker): Int {
        val iconId = marker.iconId?.lowercase() ?: marker.category.lowercase()

        return when (iconId) {
            "flag", "checkpoint" -> R.drawable.ic_flag
            "pin", "waypoint" -> R.drawable.ic_pin
            "scenic" -> R.drawable.ic_scenic
            "petrol_station", "petrol", "gas", "fuel" -> R.drawable.ic_petrol_station
            "restaurant", "food" -> R.drawable.ic_restaurant
            "hotel", "accommodation" -> R.drawable.ic_hotel
            "parking" -> R.drawable.ic_parking
            "hospital", "medical" -> R.drawable.ic_hospital
            "police" -> R.drawable.ic_police
            "charging_station", "charging" -> R.drawable.ic_charging_station
            else -> R.drawable.ic_pin
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
            Log.e("MarkerPopupBinder", "Error sending event to Flutter: ${e.message}")
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
