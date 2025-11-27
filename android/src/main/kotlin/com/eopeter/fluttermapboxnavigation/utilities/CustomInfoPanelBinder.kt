package com.eopeter.fluttermapboxnavigation.utilities

import android.app.Activity
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
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.FrameLayout
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.ProgressBar
import android.widget.TextView
import com.eopeter.fluttermapboxnavigation.R
import com.eopeter.fluttermapboxnavigation.models.MapBoxEvents
import com.eopeter.fluttermapboxnavigation.models.TripProgressData
import com.mapbox.navigation.dropin.infopanel.InfoPanelBinder

/**
 * Custom InfoPanelBinder that replaces the ENTIRE info panel in the Mapbox navigation view.
 *
 * This provides full control over the layout and includes:
 * - Trip progress with prev/next waypoint buttons
 * - End navigation button
 *
 * Layout:
 * ┌──────────────────────────────────────────────────────────┐
 * │  [◀]   [icon] Waypoint Name                      [▶]    │
 * │              2.3 mi • ~4 min                             │
 * │  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━   │
 * │  Waypoint 3/8                      45 mi remaining      │
 * │                    ETA 2:45pm                           │
 * │                                                         │
 * │                   [End Navigation]                      │
 * └──────────────────────────────────────────────────────────┘
 */
class CustomInfoPanelBinder(
    private val activity: Activity,
    private val onSkipPrevious: (() -> Unit)? = null,
    private val onSkipNext: (() -> Unit)? = null,
    private val onEndNavigation: (() -> Unit)? = null
) : InfoPanelBinder() {

    companion object {
        private const val TAG = "CustomInfoPanelBinder"
    }

    // UI elements for trip progress
    private var iconView: ImageView? = null
    private var waypointNameView: TextView? = null
    private var distanceTimeView: TextView? = null
    private var progressBar: ProgressBar? = null
    private var progressTextView: TextView? = null
    private var totalDistanceView: TextView? = null
    private var etaView: TextView? = null
    private var prevButton: ImageView? = null
    private var nextButton: ImageView? = null
    private var endNavButton: TextView? = null
    private var rootLayout: ViewGroup? = null

    // Current state for button enable/disable
    private var currentWaypointIndex = 0
    private var totalWaypoints = 0

    // Tone generator for button feedback
    private var toneGenerator: ToneGenerator? = null

    // Main thread handler for UI updates
    private val mainHandler = Handler(Looper.getMainLooper())

    override fun onCreateLayout(
        layoutInflater: LayoutInflater,
        root: ViewGroup
    ): ViewGroup {
        Log.d(TAG, "🎯 onCreateLayout - Creating custom info panel")

        // Initialize tone generator for audio feedback
        try {
            toneGenerator = ToneGenerator(AudioManager.STREAM_NOTIFICATION, 50)
        } catch (e: Exception) {
            Log.w(TAG, "Could not create ToneGenerator: ${e.message}")
        }

        // Create the custom panel layout programmatically
        rootLayout = createInfoPanelView(root.context)

        // Set up the progress listener
        TripProgressManager.getInstance().setProgressListener { data ->
            updateProgress(data)
        }

        // Set up end navigation button click handler
        endNavButton?.setOnClickListener {
            Log.d(TAG, "🔴 END NAVIGATION button clicked")
            playButtonSound()
            // Stop navigation via MapboxNavigationApp
            com.mapbox.navigation.core.lifecycle.MapboxNavigationApp.current()?.stopTripSession()
            PluginUtilities.sendEvent(MapBoxEvents.NAVIGATION_CANCELLED)
            onEndNavigation?.invoke()
            activity.finish()
        }

        Log.d(TAG, "🎯 Custom info panel layout created")
        return rootLayout!!
    }

    override fun getHeaderLayout(layout: ViewGroup): ViewGroup? {
        // We don't use the standard header/content split
        return null
    }

    override fun getContentLayout(layout: ViewGroup): ViewGroup? {
        // We don't use the standard header/content split
        return null
    }

    /**
     * Update the display with new progress data.
     */
    fun updateProgress(data: TripProgressData) {
        Log.d(TAG, "📊 updateProgress called: ${data.nextWaypointName}, waypoint ${data.currentWaypointIndex + 1}/${data.totalWaypoints}")

        mainHandler.post {
            currentWaypointIndex = data.currentWaypointIndex
            totalWaypoints = data.totalWaypoints

            // Update icon
            iconView?.setImageResource(getIconResource(data.nextWaypointIconId, data.nextWaypointCategory))
            iconView?.background = createCircleDrawable(getCategoryColor(data.nextWaypointCategory))

            // Update waypoint name
            val displayName = if (data.nextWaypointName.length > 22) {
                data.nextWaypointName.take(19) + "..."
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

    private fun createInfoPanelView(context: Context): ViewGroup {
        // Main container - fills the info panel area
        return LinearLayout(context).apply {
            orientation = LinearLayout.VERTICAL
            setBackgroundColor(Color.WHITE)
            layoutParams = ViewGroup.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.WRAP_CONTENT
            )

            // Add rounded top corners
            val bgDrawable = GradientDrawable().apply {
                setColor(Color.WHITE)
                cornerRadii = floatArrayOf(
                    dpToPx(context, 16).toFloat(), dpToPx(context, 16).toFloat(), // top-left
                    dpToPx(context, 16).toFloat(), dpToPx(context, 16).toFloat(), // top-right
                    0f, 0f, // bottom-right
                    0f, 0f  // bottom-left
                )
            }
            background = bgDrawable

            // Content padding - increased for better visibility
            setPadding(dpToPx(context, 16), dpToPx(context, 24), dpToPx(context, 16), dpToPx(context, 28))

            // === Line 1: [◀] [icon] Waypoint Name [▶] ===
            val line1 = LinearLayout(context).apply {
                orientation = LinearLayout.HORIZONTAL
                gravity = Gravity.CENTER_VERTICAL
                layoutParams = LinearLayout.LayoutParams(
                    LinearLayout.LayoutParams.MATCH_PARENT,
                    LinearLayout.LayoutParams.WRAP_CONTENT
                )
            }

            // Prev button
            prevButton = ImageView(context).apply {
                val size = dpToPx(context, 36)
                layoutParams = LinearLayout.LayoutParams(size, size).apply {
                    marginEnd = dpToPx(context, 12)
                }
                setImageResource(R.drawable.ic_chevron_left)
                setColorFilter(Color.parseColor("#2196F3"))
                background = createRoundedRectDrawable(Color.parseColor("#E3F2FD"), dpToPx(context, 8).toFloat())
                setPadding(dpToPx(context, 6), dpToPx(context, 6), dpToPx(context, 6), dpToPx(context, 6))
                setOnClickListener {
                    if (isEnabled) {
                        playButtonSound()
                        onSkipPrevious?.invoke()
                    }
                }
            }
            line1.addView(prevButton)

            // Icon container
            val iconContainer = FrameLayout(context).apply {
                val size = dpToPx(context, 32)
                layoutParams = LinearLayout.LayoutParams(size, size)
                background = createCircleDrawable(Color.parseColor("#2196F3"))
            }

            iconView = ImageView(context).apply {
                val iconSize = dpToPx(context, 18)
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
                setTextSize(TypedValue.COMPLEX_UNIT_SP, 16f)
                setTextColor(Color.parseColor("#1a1a1a"))
                setPadding(dpToPx(context, 12), 0, dpToPx(context, 12), 0)
                layoutParams = LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f)
                maxLines = 1
                gravity = Gravity.CENTER
            }
            line1.addView(waypointNameView)

            // Next button
            nextButton = ImageView(context).apply {
                val size = dpToPx(context, 36)
                layoutParams = LinearLayout.LayoutParams(size, size).apply {
                    marginStart = dpToPx(context, 12)
                }
                setImageResource(R.drawable.ic_chevron_right)
                setColorFilter(Color.parseColor("#2196F3"))
                background = createRoundedRectDrawable(Color.parseColor("#E3F2FD"), dpToPx(context, 8).toFloat())
                setPadding(dpToPx(context, 6), dpToPx(context, 6), dpToPx(context, 6), dpToPx(context, 6))
                setOnClickListener {
                    if (isEnabled) {
                        playButtonSound()
                        onSkipNext?.invoke()
                    }
                }
            }
            line1.addView(nextButton)

            addView(line1)

            // === Line 2: Distance • Time to next ===
            distanceTimeView = TextView(context).apply {
                text = "-- • --"
                setTextSize(TypedValue.COMPLEX_UNIT_SP, 14f)
                setTextColor(Color.parseColor("#666666"))
                gravity = Gravity.CENTER
                layoutParams = LinearLayout.LayoutParams(
                    LinearLayout.LayoutParams.MATCH_PARENT,
                    LinearLayout.LayoutParams.WRAP_CONTENT
                ).apply {
                    topMargin = dpToPx(context, 8)
                }
            }
            addView(distanceTimeView)

            // === Line 3: Progress bar ===
            progressBar = ProgressBar(context, null, android.R.attr.progressBarStyleHorizontal).apply {
                layoutParams = LinearLayout.LayoutParams(
                    LinearLayout.LayoutParams.MATCH_PARENT,
                    dpToPx(context, 8)
                ).apply {
                    topMargin = dpToPx(context, 14)
                }
                max = 100
                progress = 0
                progressDrawable = createProgressDrawable(context)
            }
            addView(progressBar)

            // === Line 4: Progress text + Total distance ===
            val line4 = LinearLayout(context).apply {
                orientation = LinearLayout.HORIZONTAL
                gravity = Gravity.CENTER_VERTICAL
                layoutParams = LinearLayout.LayoutParams(
                    LinearLayout.LayoutParams.MATCH_PARENT,
                    LinearLayout.LayoutParams.WRAP_CONTENT
                ).apply {
                    topMargin = dpToPx(context, 10)
                }
            }

            progressTextView = TextView(context).apply {
                text = "Waypoint 1/1"
                setTextSize(TypedValue.COMPLEX_UNIT_SP, 13f)
                setTextColor(Color.parseColor("#666666"))
                layoutParams = LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f)
            }
            line4.addView(progressTextView)

            totalDistanceView = TextView(context).apply {
                text = "-- remaining"
                setTextSize(TypedValue.COMPLEX_UNIT_SP, 13f)
                setTextColor(Color.parseColor("#666666"))
                gravity = Gravity.END
            }
            line4.addView(totalDistanceView)

            addView(line4)

            // === Line 5: ETA ===
            etaView = TextView(context).apply {
                text = "ETA --:--"
                setTextSize(TypedValue.COMPLEX_UNIT_SP, 15f)
                setTextColor(Color.parseColor("#2196F3"))
                gravity = Gravity.CENTER
                layoutParams = LinearLayout.LayoutParams(
                    LinearLayout.LayoutParams.MATCH_PARENT,
                    LinearLayout.LayoutParams.WRAP_CONTENT
                ).apply {
                    topMargin = dpToPx(context, 10)
                }
            }
            addView(etaView)

            // === End Navigation Button ===
            endNavButton = TextView(context).apply {
                text = "End Navigation"
                setTextSize(TypedValue.COMPLEX_UNIT_SP, 14f)
                setTextColor(Color.WHITE)
                gravity = Gravity.CENTER
                background = createRoundedRectDrawable(Color.parseColor("#E53935"), dpToPx(context, 8).toFloat())
                setPadding(dpToPx(context, 16), dpToPx(context, 12), dpToPx(context, 16), dpToPx(context, 12))
                layoutParams = LinearLayout.LayoutParams(
                    LinearLayout.LayoutParams.MATCH_PARENT,
                    LinearLayout.LayoutParams.WRAP_CONTENT
                ).apply {
                    topMargin = dpToPx(context, 16)
                }
            }
            addView(endNavButton)
        }
    }

    private fun createProgressDrawable(context: Context): GradientDrawable {
        return GradientDrawable().apply {
            shape = GradientDrawable.RECTANGLE
            cornerRadius = dpToPx(context, 4).toFloat()
            setColor(Color.parseColor("#2196F3"))
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

    private fun dpToPx(context: Context, dp: Int): Int {
        return TypedValue.applyDimension(
            TypedValue.COMPLEX_UNIT_DIP,
            dp.toFloat(),
            context.resources.displayMetrics
        ).toInt()
    }
}
