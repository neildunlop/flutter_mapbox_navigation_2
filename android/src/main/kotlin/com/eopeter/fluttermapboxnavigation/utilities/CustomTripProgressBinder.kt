package com.eopeter.fluttermapboxnavigation.utilities

import android.content.Context
import android.graphics.Color
import android.graphics.drawable.GradientDrawable
import android.media.AudioManager
import android.media.ToneGenerator
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.util.TypedValue
import android.view.Gravity
import android.view.View
import android.view.ViewGroup
import android.widget.FrameLayout
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.ProgressBar
import android.widget.TextView
import androidx.cardview.widget.CardView
import com.eopeter.fluttermapboxnavigation.FlutterMapboxNavigationPlugin
import com.eopeter.fluttermapboxnavigation.R
import com.eopeter.fluttermapboxnavigation.models.TripProgressConfig
import com.eopeter.fluttermapboxnavigation.models.TripProgressData
import com.eopeter.fluttermapboxnavigation.models.TripProgressTheme
import com.mapbox.navigation.core.MapboxNavigation
import com.mapbox.navigation.core.lifecycle.MapboxNavigationObserver
import com.mapbox.navigation.ui.base.lifecycle.UIBinder
import com.mapbox.navigation.ui.base.lifecycle.UIComponent

/**
 * Custom UIBinder that replaces the default trip progress display in the Mapbox info panel.
 *
 * Shows a 5-line compact layout:
 * - Line 1: [◀] [icon] Waypoint Name [▶]
 * - Line 2: Distance • Time to next
 * - Line 3: Progress bar
 * - Line 4: "Waypoint 3/8" + Total distance remaining
 * - Line 5: ETA
 *
 * Provides prev/next buttons for skipping waypoints.
 *
 * The appearance can be customized via the [TripProgressConfig] from [FlutterMapboxNavigationPlugin].
 */
class CustomTripProgressBinder(
    private val context: Context,
    private val onSkipPrevious: (() -> Unit)? = null,
    private val onSkipNext: (() -> Unit)? = null
) : UIBinder {

    // Get config and theme from plugin
    private val config: TripProgressConfig get() = FlutterMapboxNavigationPlugin.tripProgressConfig
    private val theme: TripProgressTheme get() = config.theme

    companion object {
        private const val TAG = "CustomTripProgressBinder"
    }

    // UI elements for updating
    private var iconView: ImageView? = null
    private var waypointNameView: TextView? = null
    private var distanceTimeView: TextView? = null
    private var progressBar: ProgressBar? = null
    private var progressTextView: TextView? = null
    private var totalDistanceView: TextView? = null
    private var etaView: TextView? = null
    private var prevButton: ImageView? = null
    private var nextButton: ImageView? = null

    // Current state for button enable/disable
    private var currentWaypointIndex = 0
    private var totalWaypoints = 0

    // Tone generator for button feedback
    private var toneGenerator: ToneGenerator? = null

    // Main thread handler for UI updates
    private val mainHandler = Handler(Looper.getMainLooper())

    override fun bind(viewGroup: ViewGroup): MapboxNavigationObserver {
        Log.d(TAG, "🎯 Binding CustomTripProgressBinder")

        // Initialize tone generator for audio feedback
        try {
            toneGenerator = ToneGenerator(AudioManager.STREAM_NOTIFICATION, 50)
        } catch (e: Exception) {
            Log.w(TAG, "Could not create ToneGenerator: ${e.message}")
        }

        // Create the custom view
        val customView = createTripProgressView(viewGroup.context)
        viewGroup.removeAllViews()
        viewGroup.addView(customView)

        Log.d(TAG, "🎯 CustomTripProgressBinder view added")

        // Set up the progress listener
        TripProgressManager.getInstance().setProgressListener { data ->
            updateProgress(data)
        }

        return object : UIComponent() {
            override fun onAttached(mapboxNavigation: MapboxNavigation) {
                super.onAttached(mapboxNavigation)
                Log.d(TAG, "🎯 CustomTripProgressBinder attached to navigation")
            }

            override fun onDetached(mapboxNavigation: MapboxNavigation) {
                super.onDetached(mapboxNavigation)
                Log.d(TAG, "🎯 CustomTripProgressBinder detached")
                TripProgressManager.getInstance().setProgressListener(null)
                toneGenerator?.release()
                toneGenerator = null
            }
        }
    }

    /**
     * Update the display with new progress data.
     * This method ensures UI updates happen on the main thread.
     */
    fun updateProgress(data: TripProgressData) {
        Log.d(TAG, "📊 updateProgress called: ${data.nextWaypointName}, waypoint ${data.currentWaypointIndex + 1}/${data.totalWaypoints}")

        mainHandler.post {
            currentWaypointIndex = data.currentWaypointIndex
            totalWaypoints = data.totalWaypoints

            // Update icon - use theme category color
            iconView?.setImageResource(getIconResource(data.nextWaypointIconId, data.nextWaypointCategory))
            iconView?.background = createCircleDrawable(theme.getCategoryColor(data.nextWaypointCategory))

            // Update waypoint name (truncate if too long)
            val displayName = if (data.nextWaypointName.length > 20) {
                data.nextWaypointName.take(17) + "..."
            } else {
                data.nextWaypointName
            }
            waypointNameView?.text = displayName
            Log.d(TAG, "📊 Updated waypoint name to: $displayName")

            // Update distance and time to next waypoint
            distanceTimeView?.text = "${data.getFormattedDistanceToNext()} • ${data.getFormattedDurationToNext()}"

            // Update progress bar
            progressBar?.max = 100
            progressBar?.progress = (data.progressFraction * 100).toInt()

            // Update progress text
            progressTextView?.text = data.progressString

            // Update total distance remaining
            totalDistanceView?.text = "${data.getFormattedTotalDistanceRemaining()} remaining"

            // Update ETA
            etaView?.text = "ETA ${data.getFormattedEta()}"

            // Update button states
            updateButtonStates()
        }
    }

    private fun updateButtonStates() {
        // Prev button: disabled if at first waypoint
        val canGoPrev = currentWaypointIndex > 0
        prevButton?.apply {
            alpha = if (canGoPrev) 1.0f else 0.3f
            isEnabled = canGoPrev
            isClickable = canGoPrev
        }

        // Next button: disabled if at last waypoint
        val canGoNext = currentWaypointIndex < totalWaypoints - 1
        nextButton?.apply {
            alpha = if (canGoNext) 1.0f else 0.3f
            isEnabled = canGoNext
            isClickable = canGoNext
        }
    }

    private fun playButtonSound() {
        try {
            toneGenerator?.startTone(ToneGenerator.TONE_PROP_BEEP, 100)
        } catch (e: Exception) {
            Log.w(TAG, "Could not play tone: ${e.message}")
        }
    }

    private fun createTripProgressView(context: Context): View {
        Log.d(TAG, "🎨 Creating view with theme: backgroundColor=${String.format("#%08X", theme.backgroundColor)}, primaryColor=${String.format("#%08X", theme.primaryColor)}, cornerRadius=${theme.cornerRadius}")
        return CardView(context).apply {
            radius = theme.cornerRadius
            cardElevation = dpToPx(context, 4).toFloat()
            setCardBackgroundColor(theme.backgroundColor)
            useCompatPadding = false

            val contentLayout = LinearLayout(context).apply {
                orientation = LinearLayout.VERTICAL
                setPadding(dpToPx(context, 12), dpToPx(context, 10), dpToPx(context, 12), dpToPx(context, 10))
            }

            // === Line 1: [◀] [icon] Waypoint Name [▶] ===
            val line1 = LinearLayout(context).apply {
                orientation = LinearLayout.HORIZONTAL
                gravity = Gravity.CENTER_VERTICAL
            }

            // Prev button (only if enabled)
            if (config.showSkipButtons) {
                prevButton = ImageView(context).apply {
                    val size = theme.buttonSize
                    layoutParams = LinearLayout.LayoutParams(size, size).apply {
                        marginEnd = dpToPx(context, 8)
                    }
                    setImageResource(R.drawable.ic_chevron_left)
                    setColorFilter(theme.primaryColor)
                    background = createRoundedRectDrawable(theme.buttonBackgroundColor, dpToPx(context, 6).toFloat())
                    setPadding(dpToPx(context, 4), dpToPx(context, 4), dpToPx(context, 4), dpToPx(context, 4))
                    setOnClickListener {
                        if (isEnabled) {
                            playButtonSound()
                            onSkipPrevious?.invoke()
                        }
                    }
                }
                line1.addView(prevButton)
            }

            // Icon container
            val iconContainer = FrameLayout(context).apply {
                val size = theme.iconSize
                layoutParams = LinearLayout.LayoutParams(size, size)
                background = createCircleDrawable(theme.primaryColor)
            }

            iconView = ImageView(context).apply {
                val iconSize = dpToPx(context, 16)
                layoutParams = FrameLayout.LayoutParams(iconSize, iconSize).apply {
                    gravity = Gravity.CENTER
                }
                setImageResource(R.drawable.ic_flag)
                setColorFilter(Color.WHITE)
            }
            iconContainer.addView(iconView)
            line1.addView(iconContainer)

            // Waypoint name (takes remaining space)
            waypointNameView = TextView(context).apply {
                text = "Loading..."
                setTextSize(TypedValue.COMPLEX_UNIT_SP, 15f)
                setTextColor(theme.textPrimaryColor)
                setPadding(dpToPx(context, 8), 0, dpToPx(context, 8), 0)
                layoutParams = LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f)
                maxLines = 1
                gravity = Gravity.CENTER
            }
            line1.addView(waypointNameView)

            // Next button (only if enabled)
            if (config.showSkipButtons) {
                nextButton = ImageView(context).apply {
                    val size = theme.buttonSize
                    layoutParams = LinearLayout.LayoutParams(size, size).apply {
                        marginStart = dpToPx(context, 8)
                    }
                    setImageResource(R.drawable.ic_chevron_right)
                    setColorFilter(theme.primaryColor)
                    background = createRoundedRectDrawable(theme.buttonBackgroundColor, dpToPx(context, 6).toFloat())
                    setPadding(dpToPx(context, 4), dpToPx(context, 4), dpToPx(context, 4), dpToPx(context, 4))
                    setOnClickListener {
                        if (isEnabled) {
                            playButtonSound()
                            onSkipNext?.invoke()
                        }
                    }
                }
                line1.addView(nextButton)
            }

            contentLayout.addView(line1)

            // === Line 2: Distance • Time to next ===
            if (config.showDistanceToNext || config.showDurationToNext) {
                distanceTimeView = TextView(context).apply {
                    text = "-- mi • --"
                    setTextSize(TypedValue.COMPLEX_UNIT_SP, 13f)
                    setTextColor(theme.textSecondaryColor)
                    gravity = Gravity.CENTER
                    setPadding(0, dpToPx(context, 4), 0, 0)
                }
                contentLayout.addView(distanceTimeView)
            }

            // === Line 3: Progress bar ===
            if (config.showProgressBar) {
                progressBar = ProgressBar(context, null, android.R.attr.progressBarStyleHorizontal).apply {
                    layoutParams = LinearLayout.LayoutParams(
                        LinearLayout.LayoutParams.MATCH_PARENT,
                        dpToPx(context, 6)
                    ).apply {
                        topMargin = dpToPx(context, 8)
                    }
                    max = 100
                    progress = 0
                    progressDrawable = createProgressDrawable(context)
                }
                contentLayout.addView(progressBar)
            }

            // === Line 4: Progress text + Total distance ===
            if (config.showWaypointCount || config.showTotalDistance) {
                val line4 = LinearLayout(context).apply {
                    orientation = LinearLayout.HORIZONTAL
                    gravity = Gravity.CENTER_VERTICAL
                    setPadding(0, dpToPx(context, 6), 0, 0)
                }

                if (config.showWaypointCount) {
                    progressTextView = TextView(context).apply {
                        text = "Waypoint 1/1"
                        setTextSize(TypedValue.COMPLEX_UNIT_SP, 12f)
                        setTextColor(theme.textSecondaryColor)
                        layoutParams = LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f)
                    }
                    line4.addView(progressTextView)
                }

                if (config.showTotalDistance) {
                    totalDistanceView = TextView(context).apply {
                        text = "-- mi remaining"
                        setTextSize(TypedValue.COMPLEX_UNIT_SP, 12f)
                        setTextColor(theme.textSecondaryColor)
                        gravity = Gravity.END
                        if (!config.showWaypointCount) {
                            layoutParams = LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f)
                        }
                    }
                    line4.addView(totalDistanceView)
                }

                contentLayout.addView(line4)
            }

            // === Line 5: ETA ===
            if (config.showEta) {
                etaView = TextView(context).apply {
                    text = "ETA --:--"
                    setTextSize(TypedValue.COMPLEX_UNIT_SP, 14f)
                    setTextColor(theme.primaryColor)
                    gravity = Gravity.CENTER
                    setPadding(0, dpToPx(context, 4), 0, 0)
                }
                contentLayout.addView(etaView)
            }

            addView(contentLayout)
        }
    }

    private fun createProgressDrawable(context: Context): GradientDrawable {
        return GradientDrawable().apply {
            shape = GradientDrawable.RECTANGLE
            cornerRadius = dpToPx(context, 3).toFloat()
            setColor(theme.progressBarBackgroundColor)
        }
    }

    private fun createCircleDrawable(color: Int): GradientDrawable {
        return GradientDrawable().apply {
            shape = GradientDrawable.OVAL
            setColor(color)
        }
    }

    private fun createRoundedRectDrawable(color: Int, cornerRadius: Float): GradientDrawable {
        return GradientDrawable().apply {
            shape = GradientDrawable.RECTANGLE
            setColor(color)
            this.cornerRadius = cornerRadius
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

    private fun dpToPx(context: Context, dp: Int): Int {
        return TypedValue.applyDimension(
            TypedValue.COMPLEX_UNIT_DIP,
            dp.toFloat(),
            context.resources.displayMetrics
        ).toInt()
    }
}
