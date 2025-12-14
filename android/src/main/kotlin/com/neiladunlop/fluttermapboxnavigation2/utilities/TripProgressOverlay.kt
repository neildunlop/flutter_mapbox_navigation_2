package com.neiladunlop.fluttermapboxnavigation2.utilities

import android.graphics.Color
import android.graphics.PorterDuff
import android.graphics.drawable.GradientDrawable
import android.graphics.drawable.LayerDrawable
import android.media.AudioManager
import android.media.ToneGenerator
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
import android.widget.ProgressBar
import android.widget.TextView
import androidx.cardview.widget.CardView
import com.neiladunlop.fluttermapboxnavigation2.R
import com.neiladunlop.fluttermapboxnavigation2.activity.NavigationActivity
import com.neiladunlop.fluttermapboxnavigation2.models.TripProgressConfig
import com.neiladunlop.fluttermapboxnavigation2.models.TripProgressData
import com.neiladunlop.fluttermapboxnavigation2.models.TripProgressTheme

/**
 * Displays a trip progress overlay above the navigation info panel.
 *
 * Shows:
 * - Skip prev/next buttons (configurable)
 * - Icon + Next waypoint name + Distance/time to it
 * - Progress bar + "Waypoint X/Y" + Total distance remaining
 * - ETA
 * - End navigation button (configurable)
 *
 * The appearance can be customized via [TripProgressConfig] and [TripProgressTheme].
 */
class TripProgressOverlay(
    private val activity: NavigationActivity,
    private val config: TripProgressConfig = TripProgressConfig.defaults()
) {
    // Theme shortcut
    private val theme: TripProgressTheme get() = config.theme

    private var progressCard: CardView? = null
    private var isVisible = false

    // Callbacks
    var onSkipPrevious: (() -> Unit)? = null
    var onSkipNext: (() -> Unit)? = null
    var onEndNavigation: (() -> Unit)? = null

    // UI elements for updating
    private var iconView: ImageView? = null
    private var iconContainer: FrameLayout? = null
    private var waypointNameView: TextView? = null
    private var distanceTimeView: TextView? = null
    private var progressBar: ProgressBar? = null
    private var progressTextView: TextView? = null
    private var totalDistanceView: TextView? = null
    private var etaView: TextView? = null
    private var prevButton: ImageButton? = null
    private var nextButton: ImageButton? = null
    private var endNavButton: TextView? = null

    // Current state for button enable/disable
    private var currentWaypointIndex = 0
    private var totalWaypoints = 0

    // Bottom margin to position above the info panel
    private val bottomMarginDp = 180

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
    fun hide(animated: Boolean = true) {
        progressCard?.let { card ->
            if (animated) {
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
            } else {
                (card.parent as? ViewGroup)?.removeView(card)
                progressCard = null
                isVisible = false
            }
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

            currentWaypointIndex = data.currentWaypointIndex
            totalWaypoints = data.totalWaypoints

            // Update icon
            iconView?.setImageResource(getIconResource(data.nextWaypointIconId, data.nextWaypointCategory))
            iconContainer?.background = createCircleDrawable(theme.getCategoryColor(data.nextWaypointCategory))

            // Update waypoint name (truncate if too long)
            val displayName = if (data.nextWaypointName.length > 22) {
                data.nextWaypointName.take(19) + "..."
            } else {
                data.nextWaypointName
            }
            waypointNameView?.text = displayName

            // Update distance and time
            if (config.showDistanceToNext || config.showDurationToNext) {
                val distStr = if (config.showDistanceToNext) data.getFormattedDistanceToNext() else ""
                val timeStr = if (config.showDurationToNext) data.getFormattedDurationToNext() else ""
                val separator = if (config.showDistanceToNext && config.showDurationToNext) " • " else ""
                distanceTimeView?.text = "$distStr$separator$timeStr"
            }

            // Update progress bar
            if (config.showProgressBar) {
                progressBar?.max = 100
                progressBar?.progress = (data.progressFraction * 100).toInt()
            }

            // Update progress text
            if (config.showWaypointCount) {
                progressTextView?.text = data.progressString
            }

            // Update total distance
            if (config.showTotalDistance) {
                totalDistanceView?.text = "${data.getFormattedTotalDistanceRemaining()} remaining"
            }

            // Update ETA
            if (config.showEta) {
                etaView?.text = "ETA ${data.getFormattedEta()}"
            }

            // Update button states
            updateButtonStates()
        }
    }

    private fun updateButtonStates() {
        if (!config.showSkipButtons) return

        // Prev button: disabled if at first waypoint
        val canGoPrev = currentWaypointIndex > 0
        prevButton?.alpha = if (canGoPrev) 1.0f else 0.3f
        prevButton?.isEnabled = canGoPrev

        // Next button: disabled if at last waypoint
        val canGoNext = currentWaypointIndex < totalWaypoints - 1
        nextButton?.alpha = if (canGoNext) 1.0f else 0.3f
        nextButton?.isEnabled = canGoNext
    }

    private fun playButtonSound() {
        if (!config.enableAudioFeedback) return
        try {
            val toneGen = ToneGenerator(AudioManager.STREAM_NOTIFICATION, 50)
            toneGen.startTone(ToneGenerator.TONE_PROP_BEEP, 50)
        } catch (e: Exception) {
            Log.w("TripProgressOverlay", "Could not play button sound: ${e.message}")
        }
    }

    private fun createProgressCard(): CardView {
        val context = activity

        return CardView(context).apply {
            radius = theme.cornerRadius
            cardElevation = dpToPx(6).toFloat()
            setCardBackgroundColor(theme.backgroundColor)
            useCompatPadding = false

            // Main content container
            val contentLayout = LinearLayout(context).apply {
                orientation = LinearLayout.VERTICAL
                setPadding(dpToPx(16), dpToPx(16), dpToPx(16), dpToPx(16))
            }

            // === Line 1: [◀] Icon + Waypoint Name [▶] ===
            val line1 = LinearLayout(context).apply {
                orientation = LinearLayout.HORIZONTAL
                gravity = Gravity.CENTER_VERTICAL
            }

            // Prev button (only if enabled)
            if (config.showSkipButtons) {
                prevButton = createSkipButton(android.R.drawable.ic_media_previous).apply {
                    setOnClickListener {
                        playButtonSound()
                        onSkipPrevious?.invoke()
                    }
                }
                line1.addView(prevButton)
            }

            // Icon container
            iconContainer = FrameLayout(context).apply {
                val size = theme.iconSize
                layoutParams = LinearLayout.LayoutParams(size, size).apply {
                    if (config.showSkipButtons) marginStart = dpToPx(12)
                }
                background = createCircleDrawable(theme.primaryColor)
            }

            iconView = ImageView(context).apply {
                val iconSize = dpToPx(16)
                layoutParams = FrameLayout.LayoutParams(iconSize, iconSize).apply {
                    gravity = Gravity.CENTER
                }
                setImageResource(R.drawable.ic_flag)
                setColorFilter(Color.WHITE)
            }
            iconContainer?.addView(iconView)
            line1.addView(iconContainer)

            // Waypoint name (takes remaining space)
            waypointNameView = TextView(context).apply {
                text = "Loading..."
                setTextSize(TypedValue.COMPLEX_UNIT_SP, 16f)
                setTextColor(theme.textPrimaryColor)
                setPadding(dpToPx(12), 0, dpToPx(12), 0)
                layoutParams = LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f)
                maxLines = 1
                gravity = Gravity.CENTER
            }
            line1.addView(waypointNameView)

            // Next button (only if enabled)
            if (config.showSkipButtons) {
                nextButton = createSkipButton(android.R.drawable.ic_media_next).apply {
                    setOnClickListener {
                        playButtonSound()
                        onSkipNext?.invoke()
                    }
                }
                line1.addView(nextButton)
            }

            contentLayout.addView(line1)

            // === Line 2: Distance • Time ===
            if (config.showDistanceToNext || config.showDurationToNext) {
                distanceTimeView = TextView(context).apply {
                    text = "-- • --"
                    setTextSize(TypedValue.COMPLEX_UNIT_SP, 14f)
                    setTextColor(theme.textSecondaryColor)
                    gravity = Gravity.CENTER
                    setPadding(0, dpToPx(10), 0, 0)
                }
                contentLayout.addView(distanceTimeView)
            }

            // === Line 3: Progress bar ===
            if (config.showProgressBar) {
                progressBar = ProgressBar(context, null, android.R.attr.progressBarStyleHorizontal).apply {
                    layoutParams = LinearLayout.LayoutParams(
                        LinearLayout.LayoutParams.MATCH_PARENT,
                        dpToPx(6)
                    ).apply {
                        topMargin = dpToPx(10)
                    }
                    max = 100
                    progress = 0
                    progressDrawable = createProgressDrawable()
                }
                contentLayout.addView(progressBar)
            }

            // === Line 4: Progress text + Total distance ===
            if (config.showWaypointCount || config.showTotalDistance) {
                val line4 = LinearLayout(context).apply {
                    orientation = LinearLayout.HORIZONTAL
                    gravity = Gravity.CENTER_VERTICAL
                    setPadding(0, dpToPx(10), 0, 0)
                }

                if (config.showWaypointCount) {
                    progressTextView = TextView(context).apply {
                        text = "Waypoint 1/1"
                        setTextSize(TypedValue.COMPLEX_UNIT_SP, 13f)
                        setTextColor(theme.textSecondaryColor)
                        layoutParams = LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f)
                    }
                    line4.addView(progressTextView)
                }

                if (config.showTotalDistance) {
                    totalDistanceView = TextView(context).apply {
                        text = "-- remaining"
                        setTextSize(TypedValue.COMPLEX_UNIT_SP, 13f)
                        setTextColor(theme.textSecondaryColor)
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
                    setTextSize(TypedValue.COMPLEX_UNIT_SP, 15f)
                    setTextColor(theme.primaryColor)
                    gravity = Gravity.CENTER
                    setPadding(0, dpToPx(10), 0, 0)
                    setTypeface(typeface, android.graphics.Typeface.BOLD)
                }
                contentLayout.addView(etaView)
            }

            // === End Navigation Button ===
            if (config.showEndNavigationButton) {
                endNavButton = TextView(context).apply {
                    text = "End Navigation"
                    setTextSize(TypedValue.COMPLEX_UNIT_SP, 14f)
                    setTextColor(Color.WHITE)
                    gravity = Gravity.CENTER
                    setTypeface(typeface, android.graphics.Typeface.BOLD)
                    setPadding(dpToPx(16), dpToPx(12), dpToPx(16), dpToPx(12))
                    background = createRoundedDrawable(theme.endButtonColor, 8f)
                    layoutParams = LinearLayout.LayoutParams(
                        LinearLayout.LayoutParams.MATCH_PARENT,
                        LinearLayout.LayoutParams.WRAP_CONTENT
                    ).apply {
                        topMargin = dpToPx(12)
                    }
                    setOnClickListener {
                        playButtonSound()
                        onEndNavigation?.invoke()
                    }
                }
                contentLayout.addView(endNavButton)
            }

            addView(contentLayout)
        }
    }

    private fun createSkipButton(iconRes: Int): ImageButton {
        return ImageButton(activity).apply {
            val size = theme.buttonSize
            layoutParams = LinearLayout.LayoutParams(size, size)
            setImageResource(iconRes)
            setColorFilter(theme.primaryColor, PorterDuff.Mode.SRC_IN)
            background = createRoundedDrawable(theme.buttonBackgroundColor, 8f)
            scaleType = ImageView.ScaleType.CENTER_INSIDE
        }
    }

    private fun createRoundedDrawable(color: Int, radiusDp: Float): GradientDrawable {
        return GradientDrawable().apply {
            shape = GradientDrawable.RECTANGLE
            cornerRadius = dpToPx(radiusDp.toInt()).toFloat()
            setColor(color)
        }
    }

    private fun createProgressDrawable(): GradientDrawable {
        return GradientDrawable().apply {
            shape = GradientDrawable.RECTANGLE
            cornerRadius = dpToPx(3).toFloat()
            setColor(theme.progressBarBackgroundColor)
        }
    }

    private fun createCircleDrawable(color: Int): GradientDrawable {
        return GradientDrawable().apply {
            shape = GradientDrawable.OVAL
            setColor(color)
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
