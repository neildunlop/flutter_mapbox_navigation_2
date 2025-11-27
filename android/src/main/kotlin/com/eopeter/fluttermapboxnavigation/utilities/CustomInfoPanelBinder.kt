package com.eopeter.fluttermapboxnavigation.utilities

import android.app.Activity
import android.content.Context
import android.graphics.drawable.ClipDrawable
import android.graphics.drawable.GradientDrawable
import android.graphics.drawable.LayerDrawable
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
import com.eopeter.fluttermapboxnavigation.models.TripProgressConfig
import com.eopeter.fluttermapboxnavigation.models.TripProgressData
import com.eopeter.fluttermapboxnavigation.models.TripProgressTheme
import com.mapbox.navigation.dropin.infopanel.InfoPanelBinder

/**
 * Custom InfoPanelBinder that replaces the ENTIRE info panel in the Mapbox navigation view.
 *
 * This provides full control over the layout and includes:
 * - Trip progress with prev/next waypoint buttons (configurable)
 * - End navigation button (configurable)
 *
 * The appearance and behavior can be customized via [TripProgressConfig] and [TripProgressTheme].
 *
 * Layout:
 * ```
 * ┌──────────────────────────────────────────────────────────┐
 * │  [◀]   [icon] Waypoint Name                      [▶]    │
 * │              2.3 mi • ~4 min                             │
 * │  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━   │
 * │  Waypoint 3/8                      45 mi remaining      │
 * │                    ETA 2:45pm                           │
 * │                                                         │
 * │                   [End Navigation]                      │
 * └──────────────────────────────────────────────────────────┘
 * ```
 *
 * @param activity The parent activity
 * @param config Configuration for what elements to show (optional, uses defaults if null)
 * @param iconProvider Custom icon provider (optional, uses [DefaultIconProvider] if null)
 * @param onSkipPrevious Callback when previous button is clicked
 * @param onSkipNext Callback when next button is clicked
 * @param onEndNavigation Callback when end navigation button is clicked
 */
class CustomInfoPanelBinder(
    private val activity: Activity,
    private val config: TripProgressConfig = TripProgressConfig.defaults(),
    private val iconProvider: IconProvider = DefaultIconProvider,
    private val onSkipPrevious: (() -> Unit)? = null,
    private val onSkipNext: (() -> Unit)? = null,
    private val onEndNavigation: (() -> Unit)? = null
) : InfoPanelBinder() {

    companion object {
        private const val TAG = "CustomInfoPanelBinder"
    }

    // Theme shortcut
    private val theme: TripProgressTheme get() = config.theme

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

        // Initialize tone generator for audio feedback if enabled
        if (config.enableAudioFeedback) {
            try {
                toneGenerator = ToneGenerator(AudioManager.STREAM_NOTIFICATION, 50)
            } catch (e: Exception) {
                Log.w(TAG, "Could not create ToneGenerator: ${e.message}")
            }
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
            iconView?.setImageResource(iconProvider.getIconResource(data.nextWaypointIconId, data.nextWaypointCategory))
            // Update the icon container background color (not the iconView itself)
            (iconView?.parent as? android.widget.FrameLayout)?.background = createCircleDrawable(iconProvider.getCategoryColor(data.nextWaypointCategory, theme))

            // Update waypoint name
            val displayName = if (data.nextWaypointName.length > 22) {
                data.nextWaypointName.take(19) + "..."
            } else {
                data.nextWaypointName
            }
            waypointNameView?.text = displayName
            Log.d(TAG, "📊 Updated waypoint name to: $displayName")

            // Update distance and time to next waypoint
            if (config.showDistanceToNext || config.showDurationToNext) {
                val distStr = if (config.showDistanceToNext) data.getFormattedDistanceToNext() else ""
                val timeStr = if (config.showDurationToNext) data.getFormattedDurationToNext() else ""
                val separator = if (config.showDistanceToNext && config.showDurationToNext) " • " else ""
                Log.d(TAG, "📊 Distance: ${data.distanceToNextWaypoint}m -> $distStr, Duration: ${data.durationToNextWaypoint}s -> $timeStr")
                distanceTimeView?.text = "$distStr$separator$timeStr"
                distanceTimeView?.visibility = View.VISIBLE
            } else {
                distanceTimeView?.visibility = View.GONE
            }

            // Update progress bar
            if (config.showProgressBar) {
                progressBar?.max = 100
                progressBar?.progress = (data.progressFraction * 100).toInt()
                progressBar?.visibility = View.VISIBLE
            } else {
                progressBar?.visibility = View.GONE
            }

            // Update progress text
            if (config.showWaypointCount) {
                progressTextView?.text = data.progressString
                progressTextView?.visibility = View.VISIBLE
            } else {
                progressTextView?.visibility = View.GONE
            }

            // Update total distance remaining
            if (config.showTotalDistance) {
                totalDistanceView?.text = "${data.getFormattedTotalDistanceRemaining()} remaining"
                totalDistanceView?.visibility = View.VISIBLE
            } else {
                totalDistanceView?.visibility = View.GONE
            }

            // Update ETA
            if (config.showEta) {
                etaView?.text = "ETA ${data.getFormattedEta()}"
                etaView?.visibility = View.VISIBLE
            } else {
                etaView?.visibility = View.GONE
            }

            // Update button states
            updateButtonStates()
        }
    }

    private fun updateButtonStates() {
        if (!config.showSkipButtons) return

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
        if (!config.enableAudioFeedback) return
        try {
            toneGenerator?.startTone(ToneGenerator.TONE_PROP_BEEP, 100)
        } catch (e: Exception) {
            Log.w(TAG, "Could not play tone: ${e.message}")
        }
    }

    private fun createInfoPanelView(context: Context): ViewGroup {
        Log.d(TAG, "🎨 Creating view with theme: backgroundColor=${String.format("#%08X", theme.backgroundColor)}, primaryColor=${String.format("#%08X", theme.primaryColor)}, textPrimaryColor=${String.format("#%08X", theme.textPrimaryColor)}")

        // Darker button background color
        val darkerButtonBg = android.graphics.Color.parseColor("#E0E0E0")

        // Outer container with gray background for visual separation
        val outerContainer = LinearLayout(context).apply {
            orientation = LinearLayout.VERTICAL
            layoutParams = ViewGroup.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.WRAP_CONTENT
            )

            // Gray background with rounded top corners
            val outerBgDrawable = GradientDrawable().apply {
                setColor(android.graphics.Color.parseColor("#E8E8E8"))  // Light gray surround
                cornerRadii = floatArrayOf(
                    dpToPx(context, theme.cornerRadius.toInt()).toFloat(),
                    dpToPx(context, theme.cornerRadius.toInt()).toFloat(),
                    dpToPx(context, theme.cornerRadius.toInt()).toFloat(),
                    dpToPx(context, theme.cornerRadius.toInt()).toFloat(),
                    0f, 0f,
                    0f, 0f
                )
            }
            background = outerBgDrawable
            elevation = dpToPx(context, 4).toFloat()

            // Outer padding creates the gray surround effect
            setPadding(dpToPx(context, 10), dpToPx(context, 10), dpToPx(context, 10), dpToPx(context, 10))
        }

        // Inner white container for content
        val innerContainer = LinearLayout(context).apply {
            orientation = LinearLayout.VERTICAL
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            )

            // White background with rounded corners
            val innerBgDrawable = GradientDrawable().apply {
                setColor(android.graphics.Color.WHITE)
                cornerRadius = dpToPx(context, 12).toFloat()
            }
            background = innerBgDrawable

            // Content padding
            setPadding(dpToPx(context, 16), dpToPx(context, 12), dpToPx(context, 16), dpToPx(context, 16))
        }

        // === ROW 1: Navigation Controls with Waypoint Name ===
        val headerRow = LinearLayout(context).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            )
        }

        // Prev button
        if (config.showSkipButtons) {
            prevButton = ImageView(context).apply {
                val size = dpToPx(context, 36)
                layoutParams = LinearLayout.LayoutParams(size, size).apply {
                    marginEnd = dpToPx(context, 6)
                }
                setImageResource(R.drawable.ic_chevron_left)
                setColorFilter(theme.primaryColor)
                background = createRoundedRectDrawable(darkerButtonBg, dpToPx(context, 8).toFloat())
                setPadding(dpToPx(context, 8), dpToPx(context, 8), dpToPx(context, 8), dpToPx(context, 8))
                setOnClickListener {
                    if (isEnabled) {
                        playButtonSound()
                        onSkipPrevious?.invoke()
                    }
                }
            }
            headerRow.addView(prevButton)
        }

        // Icon container - larger size for better visibility, with left margin for spacing from prev button
        val iconSize = dpToPx(context, 40)
        val iconContainer = FrameLayout(context).apply {
            layoutParams = LinearLayout.LayoutParams(iconSize, iconSize).apply {
                marginStart = dpToPx(context, 8)  // Add space between prev button and icon
            }
            background = createCircleDrawable(theme.primaryColor)
        }

        iconView = ImageView(context).apply {
            val innerIconSize = dpToPx(context, 24)
            layoutParams = FrameLayout.LayoutParams(innerIconSize, innerIconSize).apply {
                gravity = Gravity.CENTER
            }
            setImageResource(R.drawable.ic_flag)
            setColorFilter(android.graphics.Color.WHITE)
            // Ensure no background on the icon itself
            background = null
        }
        iconContainer.addView(iconView)
        headerRow.addView(iconContainer)

        // Waypoint name - bigger text, closer to icon
        waypointNameView = TextView(context).apply {
            text = "Loading..."
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 18f)  // Bigger headline
            setTextColor(theme.textPrimaryColor)
            setTypeface(android.graphics.Typeface.create("sans-serif-medium", android.graphics.Typeface.NORMAL))
            letterSpacing = -0.01f
            setPadding(dpToPx(context, 6), 0, dpToPx(context, 6), 0)  // Reduced padding to bring closer to icon
            layoutParams = LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f)
            maxLines = 1
            gravity = Gravity.CENTER
        }
        headerRow.addView(waypointNameView)

        // Next button
        if (config.showSkipButtons) {
            nextButton = ImageView(context).apply {
                val size = dpToPx(context, 36)
                layoutParams = LinearLayout.LayoutParams(size, size).apply {
                    marginStart = dpToPx(context, 6)
                }
                setImageResource(R.drawable.ic_chevron_right)
                setColorFilter(theme.primaryColor)
                background = createRoundedRectDrawable(darkerButtonBg, dpToPx(context, 8).toFloat())
                setPadding(dpToPx(context, 8), dpToPx(context, 8), dpToPx(context, 8), dpToPx(context, 8))
                setOnClickListener {
                    if (isEnabled) {
                        playButtonSound()
                        onSkipNext?.invoke()
                    }
                }
            }
            headerRow.addView(nextButton)
        }

        innerContainer.addView(headerRow)

        // === ROW 2: Distance & Duration ===
        if (config.showDistanceToNext || config.showDurationToNext) {
            distanceTimeView = TextView(context).apply {
                text = "-- • --"
                setTextSize(TypedValue.COMPLEX_UNIT_SP, 14f)
                setTextColor(theme.textSecondaryColor)
                setTypeface(android.graphics.Typeface.create("sans-serif", android.graphics.Typeface.NORMAL))
                gravity = Gravity.CENTER
                layoutParams = LinearLayout.LayoutParams(
                    LinearLayout.LayoutParams.MATCH_PARENT,
                    LinearLayout.LayoutParams.WRAP_CONTENT
                ).apply {
                    topMargin = dpToPx(context, 2)
                }
            }
            innerContainer.addView(distanceTimeView)
        }

        // === ROW 3: Progress Bar ===
        if (config.showProgressBar) {
            progressBar = ProgressBar(context, null, android.R.attr.progressBarStyleHorizontal).apply {
                layoutParams = LinearLayout.LayoutParams(
                    LinearLayout.LayoutParams.MATCH_PARENT,
                    dpToPx(context, 5)
                ).apply {
                    topMargin = dpToPx(context, 8)
                }
                max = 100
                progress = 0
                progressDrawable = createProgressDrawable(context)
            }
            innerContainer.addView(progressBar)
        }

        // === ROW 4: Progress Stats ===
        if (config.showWaypointCount || config.showTotalDistance) {
            val statsRow = LinearLayout(context).apply {
                orientation = LinearLayout.HORIZONTAL
                gravity = Gravity.CENTER_VERTICAL
                layoutParams = LinearLayout.LayoutParams(
                    LinearLayout.LayoutParams.MATCH_PARENT,
                    LinearLayout.LayoutParams.WRAP_CONTENT
                ).apply {
                    topMargin = dpToPx(context, 6)
                }
            }

            if (config.showWaypointCount) {
                progressTextView = TextView(context).apply {
                    text = "Waypoint 1/1"
                    setTextSize(TypedValue.COMPLEX_UNIT_SP, 15f)
                    setTextColor(theme.primaryColor)
                    setTypeface(android.graphics.Typeface.create("sans-serif-medium", android.graphics.Typeface.NORMAL))
                    layoutParams = LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f)
                }
                statsRow.addView(progressTextView)
            }

            if (config.showTotalDistance) {
                totalDistanceView = TextView(context).apply {
                    text = "-- remaining"
                    setTextSize(TypedValue.COMPLEX_UNIT_SP, 15f)
                    setTextColor(theme.textSecondaryColor)
                    gravity = Gravity.END
                    if (!config.showWaypointCount) {
                        layoutParams = LinearLayout.LayoutParams(
                            LinearLayout.LayoutParams.MATCH_PARENT,
                            LinearLayout.LayoutParams.WRAP_CONTENT
                        )
                    }
                }
                statsRow.addView(totalDistanceView)
            }

            innerContainer.addView(statsRow)
        }

        // === ROW 5: ETA ===
        if (config.showEta) {
            etaView = TextView(context).apply {
                text = "ETA --:--"
                setTextSize(TypedValue.COMPLEX_UNIT_SP, 16f)
                setTextColor(theme.primaryColor)
                setTypeface(android.graphics.Typeface.create("sans-serif-medium", android.graphics.Typeface.BOLD))
                gravity = Gravity.CENTER
                layoutParams = LinearLayout.LayoutParams(
                    LinearLayout.LayoutParams.MATCH_PARENT,
                    LinearLayout.LayoutParams.WRAP_CONTENT
                ).apply {
                    topMargin = dpToPx(context, 6)
                }
            }
            innerContainer.addView(etaView)
        }

        // === End Navigation Button ===
        if (config.showEndNavigationButton) {
            endNavButton = TextView(context).apply {
                text = "End Navigation"
                setTextSize(TypedValue.COMPLEX_UNIT_SP, 14f)
                setTextColor(android.graphics.Color.WHITE)
                setTypeface(android.graphics.Typeface.create("sans-serif-medium", android.graphics.Typeface.NORMAL))
                gravity = Gravity.CENTER
                background = createRoundedRectDrawable(theme.endButtonColor, dpToPx(context, 8).toFloat())
                setPadding(dpToPx(context, 16), dpToPx(context, 10), dpToPx(context, 16), dpToPx(context, 10))
                layoutParams = LinearLayout.LayoutParams(
                    LinearLayout.LayoutParams.MATCH_PARENT,
                    LinearLayout.LayoutParams.WRAP_CONTENT
                ).apply {
                    topMargin = dpToPx(context, 10)
                }
            }
            innerContainer.addView(endNavButton)
        }

        // Add inner container to outer container
        outerContainer.addView(innerContainer)

        return outerContainer
    }

    private fun createProgressDrawable(context: Context): LayerDrawable {
        val cornerRadius = dpToPx(context, 4).toFloat()

        // Background layer (track)
        val background = GradientDrawable().apply {
            shape = GradientDrawable.RECTANGLE
            this.cornerRadius = cornerRadius
            setColor(theme.progressBarBackgroundColor)
        }

        // Progress layer (fill)
        val progressShape = GradientDrawable().apply {
            shape = GradientDrawable.RECTANGLE
            this.cornerRadius = cornerRadius
            setColor(theme.progressBarColor)
        }

        // Wrap progress in ClipDrawable to enable clipping based on level
        val progress = ClipDrawable(progressShape, Gravity.START, ClipDrawable.HORIZONTAL)

        // Create LayerDrawable with proper IDs
        return LayerDrawable(arrayOf(background, progress)).apply {
            setId(0, android.R.id.background)
            setId(1, android.R.id.progress)
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

    private fun dpToPx(context: Context, dp: Int): Int {
        return TypedValue.applyDimension(
            TypedValue.COMPLEX_UNIT_DIP,
            dp.toFloat(),
            context.resources.displayMetrics
        ).toInt()
    }
}
