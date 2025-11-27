package com.eopeter.fluttermapboxnavigation.utilities

import android.graphics.Color
import android.graphics.drawable.GradientDrawable
import android.util.Log
import android.util.TypedValue
import android.view.Gravity
import android.view.View
import android.view.ViewGroup
import android.view.animation.AccelerateDecelerateInterpolator
import android.widget.FrameLayout
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.ProgressBar
import android.widget.TextView
import androidx.cardview.widget.CardView
import com.eopeter.fluttermapboxnavigation.R
import com.eopeter.fluttermapboxnavigation.activity.NavigationActivity
import com.eopeter.fluttermapboxnavigation.models.TripProgressData

/**
 * Displays a compact trip progress overlay above the navigation info panel.
 *
 * Shows:
 * - Line 1: Icon + Next waypoint name + Distance to it
 * - Line 2: Progress bar + "Stop X/Y" + Time remaining
 */
class TripProgressOverlay(private val activity: NavigationActivity) {

    private var progressCard: CardView? = null
    private var isVisible = false

    // UI elements for updating
    private var iconView: ImageView? = null
    private var waypointNameView: TextView? = null
    private var distanceView: TextView? = null
    private var progressBar: ProgressBar? = null
    private var progressTextView: TextView? = null
    private var timeRemainingView: TextView? = null

    // Bottom margin to position above the info panel
    private val bottomMarginDp = 160

    /**
     * Show the trip progress overlay.
     */
    fun show() {
        if (isVisible) return

        val rootView = activity.findViewById<FrameLayout>(android.R.id.content)
            ?: activity.window.decorView.findViewById<ViewGroup>(android.R.id.content)

        if (rootView == null) {
            Log.e("TripProgressOverlay", "Could not find root view")
            return
        }

        // Create the progress card
        progressCard = createProgressCard()

        // Position at bottom, above the info panel
        val layoutParams = FrameLayout.LayoutParams(
            FrameLayout.LayoutParams.MATCH_PARENT,
            FrameLayout.LayoutParams.WRAP_CONTENT
        ).apply {
            gravity = Gravity.BOTTOM
            setMargins(dpToPx(12), 0, dpToPx(12), dpToPx(bottomMarginDp))
        }

        // Add to root view
        rootView.addView(progressCard, layoutParams)

        // Animate in
        progressCard?.let { card ->
            card.alpha = 0f
            card.translationY = dpToPx(30).toFloat()
            card.animate()
                .alpha(1f)
                .translationY(0f)
                .setDuration(300)
                .setInterpolator(AccelerateDecelerateInterpolator())
                .start()
        }

        isVisible = true
        Log.d("TripProgressOverlay", "Trip progress overlay shown")
    }

    /**
     * Hide the trip progress overlay.
     */
    fun hide() {
        progressCard?.let { card ->
            card.animate()
                .alpha(0f)
                .translationY(dpToPx(30).toFloat())
                .setDuration(200)
                .setInterpolator(AccelerateDecelerateInterpolator())
                .withEndAction {
                    (card.parent as? ViewGroup)?.removeView(card)
                    progressCard = null
                    isVisible = false
                }
                .start()
        } ?: run {
            progressCard = null
            isVisible = false
        }
    }

    /**
     * Update the overlay with new progress data.
     */
    fun updateProgress(data: TripProgressData) {
        Log.d("TripProgressOverlay", "updateProgress called: ${data.nextWaypointName}, ${data.progressString}")
        activity.runOnUiThread {
            Log.d("TripProgressOverlay", "Updating UI on main thread, waypointNameView=$waypointNameView")
            // Update icon
            iconView?.setImageResource(getIconResource(data.nextWaypointIconId, data.nextWaypointCategory))
            iconView?.background = createCircleDrawable(getCategoryColor(data.nextWaypointCategory))

            // Update waypoint name (truncate if too long)
            val displayName = if (data.nextWaypointName.length > 25) {
                data.nextWaypointName.take(22) + "..."
            } else {
                data.nextWaypointName
            }
            waypointNameView?.text = "Next: $displayName"

            // Update distance
            distanceView?.text = data.getFormattedDistanceToNext()

            // Update progress bar
            progressBar?.max = 100
            progressBar?.progress = (data.progressFraction * 100).toInt()

            // Update progress text
            progressTextView?.text = data.progressString

            // Update time remaining
            timeRemainingView?.text = data.getFormattedDurationRemaining()
        }
    }

    private fun createProgressCard(): CardView {
        val context = activity

        return CardView(context).apply {
            radius = dpToPx(12).toFloat()
            cardElevation = dpToPx(6).toFloat()
            setCardBackgroundColor(Color.WHITE)
            useCompatPadding = false

            // Main content container
            val contentLayout = LinearLayout(context).apply {
                orientation = LinearLayout.VERTICAL
                setPadding(dpToPx(12), dpToPx(10), dpToPx(12), dpToPx(10))
            }

            // === Line 1: Icon + Waypoint Name + Distance ===
            val line1 = LinearLayout(context).apply {
                orientation = LinearLayout.HORIZONTAL
                gravity = Gravity.CENTER_VERTICAL
            }

            // Icon container
            val iconContainer = FrameLayout(context).apply {
                val size = dpToPx(28)
                layoutParams = LinearLayout.LayoutParams(size, size)
                background = createCircleDrawable(Color.parseColor("#2196F3"))
            }

            iconView = ImageView(context).apply {
                val iconSize = dpToPx(16)
                layoutParams = FrameLayout.LayoutParams(iconSize, iconSize).apply {
                    gravity = Gravity.CENTER
                }
                setImageResource(R.drawable.ic_flag)
                setColorFilter(Color.WHITE)
            }
            iconContainer.addView(iconView)
            line1.addView(iconContainer)

            // Waypoint name
            waypointNameView = TextView(context).apply {
                text = "Next: Loading..."
                setTextSize(TypedValue.COMPLEX_UNIT_SP, 14f)
                setTextColor(Color.parseColor("#1a1a1a"))
                setPadding(dpToPx(8), 0, 0, 0)
                layoutParams = LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f)
                maxLines = 1
            }
            line1.addView(waypointNameView)

            // Distance to next
            distanceView = TextView(context).apply {
                text = "-- mi"
                setTextSize(TypedValue.COMPLEX_UNIT_SP, 14f)
                setTextColor(Color.parseColor("#2196F3"))
                setPadding(dpToPx(8), 0, 0, 0)
            }
            line1.addView(distanceView)

            contentLayout.addView(line1)

            // === Line 2: Progress bar + Stop X/Y + Time remaining ===
            val line2 = LinearLayout(context).apply {
                orientation = LinearLayout.HORIZONTAL
                gravity = Gravity.CENTER_VERTICAL
                setPadding(0, dpToPx(8), 0, 0)
            }

            // Progress bar
            progressBar = ProgressBar(context, null, android.R.attr.progressBarStyleHorizontal).apply {
                layoutParams = LinearLayout.LayoutParams(0, dpToPx(6), 1f)
                max = 100
                progress = 0
                progressDrawable = createProgressDrawable()
            }
            line2.addView(progressBar)

            // Stop counter
            progressTextView = TextView(context).apply {
                text = "Stop 1/1"
                setTextSize(TypedValue.COMPLEX_UNIT_SP, 12f)
                setTextColor(Color.parseColor("#666666"))
                setPadding(dpToPx(10), 0, 0, 0)
            }
            line2.addView(progressTextView)

            // Bullet separator
            val separator = TextView(context).apply {
                text = "•"
                setTextSize(TypedValue.COMPLEX_UNIT_SP, 12f)
                setTextColor(Color.parseColor("#cccccc"))
                setPadding(dpToPx(6), 0, dpToPx(6), 0)
            }
            line2.addView(separator)

            // Time remaining
            timeRemainingView = TextView(context).apply {
                text = "-- min"
                setTextSize(TypedValue.COMPLEX_UNIT_SP, 12f)
                setTextColor(Color.parseColor("#666666"))
            }
            line2.addView(timeRemainingView)

            contentLayout.addView(line2)
            addView(contentLayout)
        }
    }

    private fun createProgressDrawable(): GradientDrawable {
        return GradientDrawable().apply {
            shape = GradientDrawable.RECTANGLE
            cornerRadius = dpToPx(3).toFloat()
            setColor(Color.parseColor("#E3F2FD")) // Light blue background
        }
    }

    private fun createCircleDrawable(color: Int): GradientDrawable {
        return GradientDrawable().apply {
            shape = GradientDrawable.OVAL
            setColor(color)
        }
    }

    private fun getCategoryColor(category: String): Int {
        return when (category.lowercase()) {
            "checkpoint" -> Color.parseColor("#FF5722") // Deep Orange
            "waypoint" -> Color.parseColor("#2196F3") // Blue
            "poi" -> Color.parseColor("#4CAF50") // Green
            "scenic" -> Color.parseColor("#8BC34A") // Light Green
            "restaurant", "food" -> Color.parseColor("#FF9800") // Orange
            "hotel", "accommodation" -> Color.parseColor("#9C27B0") // Purple
            "petrol_station", "fuel" -> Color.parseColor("#607D8B") // Blue Grey
            else -> Color.parseColor("#2196F3") // Default blue
        }
    }

    private fun getIconResource(iconId: String?, category: String): Int {
        val id = iconId?.lowercase() ?: category.lowercase()

        return when (id) {
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

    private fun dpToPx(dp: Int): Int {
        return TypedValue.applyDimension(
            TypedValue.COMPLEX_UNIT_DIP,
            dp.toFloat(),
            activity.resources.displayMetrics
        ).toInt()
    }
}
