package com.neiladunlop.fluttermapboxnavigation2

import android.animation.ValueAnimator
import android.content.Context
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.drawable.Drawable
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.view.animation.LinearInterpolator
import androidx.core.content.ContextCompat
import com.mapbox.geojson.LineString
import com.mapbox.geojson.Point
import com.mapbox.maps.MapView
import com.mapbox.maps.extension.style.layers.addLayer
import com.mapbox.maps.extension.style.layers.generated.lineLayer
import com.mapbox.maps.extension.style.layers.properties.generated.IconAnchor
import com.mapbox.maps.extension.style.sources.addSource
import com.mapbox.maps.extension.style.sources.generated.geoJsonSource
import com.mapbox.maps.extension.style.sources.getSourceAs
import com.mapbox.maps.extension.style.sources.generated.GeoJsonSource
import com.mapbox.maps.extension.style.layers.getLayerAs
import com.mapbox.maps.extension.style.layers.generated.LineLayer
import com.mapbox.maps.plugin.annotation.annotations
import com.mapbox.maps.plugin.annotation.generated.PointAnnotation
import com.mapbox.maps.plugin.annotation.generated.PointAnnotationManager
import com.mapbox.maps.plugin.annotation.generated.PointAnnotationOptions
import com.mapbox.maps.plugin.annotation.generated.createPointAnnotationManager
import com.neiladunlop.fluttermapboxnavigation2.models.DynamicMarker
import com.neiladunlop.fluttermapboxnavigation2.models.DynamicMarkerConfiguration
import com.neiladunlop.fluttermapboxnavigation2.models.DynamicMarkerPositionUpdate
import com.neiladunlop.fluttermapboxnavigation2.models.DynamicMarkerState
import com.neiladunlop.fluttermapboxnavigation2.models.LatLng
import io.flutter.plugin.common.EventChannel
import java.time.Instant
import kotlin.math.abs

/**
 * Manages dynamic markers for the Mapbox Navigation plugin.
 *
 * Dynamic markers differ from static markers in that they:
 * - Animate smoothly between position updates
 * - Have state management (tracking, stale, offline, etc.)
 * - Support trail/breadcrumb rendering
 * - Support heading-based rotation
 * - Implement dead-reckoning prediction
 *
 * Based on official Mapbox documentation:
 * - Maps SDK v11 Annotations: https://docs.mapbox.com/android/maps/guides/annotations/annotations/
 * - Point Annotations: https://docs.mapbox.com/android/maps/guides/annotations/point-annotations/
 */
class DynamicMarkerManager {
    private val markers = mutableMapOf<String, DynamicMarker>()
    private var configuration: DynamicMarkerConfiguration = DynamicMarkerConfiguration.DEFAULT
    private var eventSink: EventChannel.EventSink? = null
    private var context: Context? = null
    private var mapView: MapView? = null
    private var pointAnnotationManager: PointAnnotationManager? = null
    private val pointAnnotations = mutableMapOf<String, PointAnnotation>()
    private val activeAnimators = mutableMapOf<String, ValueAnimator>()
    private var markerTapListener: ((DynamicMarker) -> Unit)? = null

    // Handler for state checking timer
    private val mainHandler = Handler(Looper.getMainLooper())
    private var stateCheckRunnable: Runnable? = null
    private val STATE_CHECK_INTERVAL_MS = 1000L

    // Trail sources and layers
    private val trailSourceIds = mutableMapOf<String, String>()
    private val trailLayerIds = mutableMapOf<String, String>()

    companion object {
        private const val TAG = "DynamicMarkerManager"

        @Volatile
        private var INSTANCE: DynamicMarkerManager? = null

        fun getInstance(): DynamicMarkerManager {
            return INSTANCE ?: synchronized(this) {
                INSTANCE ?: DynamicMarkerManager().also { INSTANCE = it }
            }
        }
    }

    // ---------------------------------------------------------------------------
    // Initialization
    // ---------------------------------------------------------------------------

    /**
     * Sets the context for resource access.
     */
    fun setContext(context: Context?) {
        this.context = context
    }

    /**
     * Sets the MapView and initializes the dynamic marker system.
     */
    fun setMapView(mapView: MapView?) {
        Log.d(TAG, "setMapView called. mapView is ${if (mapView != null) "SET" else "NULL"}")
        Log.d(TAG, "  Current markers count: ${markers.size}")
        this.mapView = mapView
        if (mapView != null) {
            Log.d(TAG, "  Initializing marker system and starting state timer")
            initializeMarkerSystem()
            startStateCheckTimer()
        } else {
            Log.d(TAG, "  Stopping state timer and cleaning up marker system")
            stopStateCheckTimer()
            cleanupMarkerSystem()
        }
    }

    /**
     * Sets the event sink for dynamic marker events.
     */
    fun setEventSink(eventSink: EventChannel.EventSink?) {
        this.eventSink = eventSink
    }

    /**
     * Sets the marker tap listener for custom handling.
     */
    fun setMarkerTapListener(listener: ((DynamicMarker) -> Unit)?) {
        this.markerTapListener = listener
    }

    /**
     * Initializes the marker system using Maps SDK v11 Annotations API.
     */
    private fun initializeMarkerSystem() {
        Log.d(TAG, "initializeMarkerSystem called. mapView is ${if (mapView != null) "SET" else "NULL"}")
        mapView?.let { view ->
            Log.d(TAG, "  Posting initialization to UI thread")
            view.post {
                try {
                    Log.d(TAG, "  Creating PointAnnotationManager")
                    pointAnnotationManager = view.annotations.createPointAnnotationManager()
                    Log.d(TAG, "  PointAnnotationManager created: ${pointAnnotationManager != null}")
                    setupMarkerClickListener()
                    Log.d(TAG, "  Calling refreshAllMarkers after initialization")
                    refreshAllMarkers()
                } catch (e: Exception) {
                    Log.e(TAG, "Failed to initialize dynamic marker system: ${e.message}")
                    e.printStackTrace()
                }
            }
        } ?: Log.w(TAG, "  mapView is null - cannot initialize marker system")
    }

    /**
     * Cleans up the marker system.
     */
    private fun cleanupMarkerSystem() {
        // Cancel all animations
        activeAnimators.values.forEach { it.cancel() }
        activeAnimators.clear()

        // Clear annotations
        pointAnnotationManager = null
        pointAnnotations.clear()

        // Clear trail layers and sources
        trailSourceIds.clear()
        trailLayerIds.clear()
    }

    /**
     * Sets up the marker click listener for interactive markers.
     */
    private fun setupMarkerClickListener() {
        pointAnnotationManager?.addClickListener { annotation ->
            val markerId = pointAnnotations.entries.find { it.value == annotation }?.key
            markerId?.let { id ->
                markers[id]?.let { marker ->
                    markerTapListener?.invoke(marker) ?: onMarkerTap(marker)
                }
            }
            true // Consume the click
        }
    }

    // ---------------------------------------------------------------------------
    // State Check Timer
    // ---------------------------------------------------------------------------

    /**
     * Starts the periodic state check timer.
     */
    private fun startStateCheckTimer() {
        stopStateCheckTimer()
        stateCheckRunnable = object : Runnable {
            override fun run() {
                checkMarkerStates()
                mainHandler.postDelayed(this, STATE_CHECK_INTERVAL_MS)
            }
        }
        mainHandler.postDelayed(stateCheckRunnable!!, STATE_CHECK_INTERVAL_MS)
    }

    /**
     * Stops the state check timer.
     */
    private fun stopStateCheckTimer() {
        stateCheckRunnable?.let { mainHandler.removeCallbacks(it) }
        stateCheckRunnable = null
    }

    /**
     * Checks and updates marker states based on last update time.
     */
    private fun checkMarkerStates() {
        val now = Instant.now().toEpochMilli()

        markers.values.toList().forEach { marker ->
            val lastUpdateTime = marker.lastUpdated?.let {
                try {
                    Instant.parse(it).toEpochMilli()
                } catch (e: Exception) {
                    now
                }
            } ?: now

            val timeSinceUpdate = now - lastUpdateTime
            val oldState = marker.state

            val newState = when {
                configuration.expiredThresholdMs != null &&
                        timeSinceUpdate > configuration.expiredThresholdMs!! -> {
                    DynamicMarkerState.EXPIRED
                }
                timeSinceUpdate > configuration.offlineThresholdMs -> {
                    DynamicMarkerState.OFFLINE
                }
                timeSinceUpdate > configuration.staleThresholdMs -> {
                    DynamicMarkerState.STALE
                }
                marker.speed != null && marker.speed < configuration.stationarySpeedThreshold -> {
                    DynamicMarkerState.STATIONARY
                }
                else -> marker.state
            }

            if (newState != oldState) {
                val updatedMarker = marker.copy(state = newState)
                markers[marker.id] = updatedMarker

                // Send state change event
                sendStateChangedEvent(updatedMarker, oldState)

                // Handle expiration
                if (newState == DynamicMarkerState.EXPIRED) {
                    sendMarkerExpiredEvent(updatedMarker)
                    removeDynamicMarker(marker.id)
                } else {
                    updateMarkerAnnotation(updatedMarker)
                }
            }
        }
    }

    // ---------------------------------------------------------------------------
    // Public API - CRUD Operations
    // ---------------------------------------------------------------------------

    /**
     * Adds a single dynamic marker to the map.
     */
    fun addDynamicMarker(marker: DynamicMarker): Boolean {
        return try {
            markers[marker.id] = marker
            createMarkerAnnotation(marker)
            if (marker.showTrail) {
                setupTrailForMarker(marker)
            }
            true
        } catch (e: Exception) {
            Log.e(TAG, "Failed to add dynamic marker: ${e.message}")
            false
        }
    }

    /**
     * Adds multiple dynamic markers to the map.
     */
    fun addDynamicMarkers(markerList: List<DynamicMarker>): Boolean {
        return try {
            Log.d(TAG, "addDynamicMarkers called with ${markerList.size} markers")
            markerList.forEach { marker ->
                Log.d(TAG, "  Adding marker: ${marker.id} at (${marker.latitude}, ${marker.longitude})")
                markers[marker.id] = marker
            }
            Log.d(TAG, "  Stored markers count: ${markers.size}")
            Log.d(TAG, "  pointAnnotationManager is ${if (pointAnnotationManager != null) "SET" else "NULL"}")
            refreshAllMarkers()
            true
        } catch (e: Exception) {
            Log.e(TAG, "Failed to add dynamic markers: ${e.message}")
            false
        }
    }

    /**
     * Updates the position of a dynamic marker with animation.
     */
    fun updateDynamicMarkerPosition(update: DynamicMarkerPositionUpdate): Boolean {
        return try {
            Log.d(TAG, "updateDynamicMarkerPosition called for marker: ${update.markerId}")
            val existingMarker = markers[update.markerId]
            if (existingMarker == null) {
                Log.w(TAG, "  Marker ${update.markerId} not found in markers map! Available: ${markers.keys}")
                return false
            }

            val updatedMarker = existingMarker.withPosition(
                newLatitude = update.latitude,
                newLongitude = update.longitude,
                newHeading = update.heading,
                newSpeed = update.speed,
                timestamp = update.timestamp
            ).copy(state = DynamicMarkerState.TRACKING)

            markers[update.markerId] = updatedMarker
            Log.d(TAG, "  Updated marker position to (${update.latitude}, ${update.longitude})")

            if (configuration.enableAnimation) {
                Log.d(TAG, "  Animating marker position")
                animateMarkerPosition(existingMarker, updatedMarker)
            } else {
                Log.d(TAG, "  Updating marker annotation directly")
                updateMarkerAnnotation(updatedMarker)
            }

            // Update trail if enabled
            if (updatedMarker.showTrail) {
                updateTrailForMarker(updatedMarker)
            }

            // Send position updated event
            sendPositionUpdatedEvent(updatedMarker)

            true
        } catch (e: Exception) {
            Log.e(TAG, "Failed to update dynamic marker position: ${e.message}")
            false
        }
    }

    /**
     * Applies multiple position updates in batch.
     */
    fun batchUpdateDynamicMarkerPositions(updates: List<DynamicMarkerPositionUpdate>): Boolean {
        return try {
            updates.forEach { update ->
                updateDynamicMarkerPosition(update)
            }
            true
        } catch (e: Exception) {
            Log.e(TAG, "Failed to batch update positions: ${e.message}")
            false
        }
    }

    /**
     * Updates properties of a dynamic marker.
     */
    fun updateDynamicMarker(
        markerId: String,
        title: String? = null,
        snippet: String? = null,
        iconId: String? = null,
        showTrail: Boolean? = null,
        metadata: Map<String, Any>? = null
    ): Boolean {
        return try {
            val existingMarker = markers[markerId] ?: return false

            val updatedMarker = existingMarker.copy(
                title = title ?: existingMarker.title,
                iconId = iconId ?: existingMarker.iconId,
                showTrail = showTrail ?: existingMarker.showTrail,
                metadata = metadata ?: existingMarker.metadata
            )

            markers[markerId] = updatedMarker
            updateMarkerAnnotation(updatedMarker)

            // Handle trail toggle
            if (showTrail == true && !existingMarker.showTrail) {
                setupTrailForMarker(updatedMarker)
            } else if (showTrail == false && existingMarker.showTrail) {
                removeTrailForMarker(markerId)
            }

            true
        } catch (e: Exception) {
            Log.e(TAG, "Failed to update dynamic marker: ${e.message}")
            false
        }
    }

    /**
     * Removes a dynamic marker by ID.
     */
    fun removeDynamicMarker(markerId: String): Boolean {
        return try {
            markers.remove(markerId)

            // Cancel any active animation
            activeAnimators[markerId]?.cancel()
            activeAnimators.remove(markerId)

            // Remove annotation
            pointAnnotations[markerId]?.let { annotation ->
                pointAnnotationManager?.delete(annotation)
            }
            pointAnnotations.remove(markerId)

            // Remove trail
            removeTrailForMarker(markerId)

            true
        } catch (e: Exception) {
            Log.e(TAG, "Failed to remove dynamic marker: ${e.message}")
            false
        }
    }

    /**
     * Removes multiple dynamic markers by ID.
     */
    fun removeDynamicMarkers(markerIds: List<String>): Boolean {
        return try {
            markerIds.forEach { removeDynamicMarker(it) }
            true
        } catch (e: Exception) {
            Log.e(TAG, "Failed to remove dynamic markers: ${e.message}")
            false
        }
    }

    /**
     * Removes all dynamic markers from the map.
     */
    fun clearAllDynamicMarkers(): Boolean {
        return try {
            // Cancel all animations
            activeAnimators.values.forEach { it.cancel() }
            activeAnimators.clear()

            // Clear markers
            markers.clear()

            // Clear annotations
            pointAnnotationManager?.deleteAll()
            pointAnnotations.clear()

            // Clear all trails
            clearAllTrails()

            true
        } catch (e: Exception) {
            Log.e(TAG, "Failed to clear all dynamic markers: ${e.message}")
            false
        }
    }

    /**
     * Gets a dynamic marker by ID.
     */
    fun getDynamicMarker(markerId: String): DynamicMarker? {
        return markers[markerId]
    }

    /**
     * Gets all current dynamic markers.
     */
    fun getDynamicMarkers(): List<DynamicMarker> {
        return markers.values.toList()
    }

    /**
     * Updates the global dynamic marker configuration.
     */
    fun updateDynamicMarkerConfiguration(config: DynamicMarkerConfiguration): Boolean {
        return try {
            this.configuration = config
            refreshAllMarkers()
            true
        } catch (e: Exception) {
            Log.e(TAG, "Failed to update configuration: ${e.message}")
            false
        }
    }

    /**
     * Clears the trail for a specific marker.
     */
    fun clearDynamicMarkerTrail(markerId: String): Boolean {
        return try {
            markers[markerId]?.let { marker ->
                markers[markerId] = marker.copy(positionHistory = null)
                updateTrailForMarker(markers[markerId]!!)
            }
            true
        } catch (e: Exception) {
            Log.e(TAG, "Failed to clear marker trail: ${e.message}")
            false
        }
    }

    /**
     * Clears trails for all dynamic markers.
     */
    fun clearAllDynamicMarkerTrails(): Boolean {
        return try {
            markers.keys.toList().forEach { markerId ->
                clearDynamicMarkerTrail(markerId)
            }
            true
        } catch (e: Exception) {
            Log.e(TAG, "Failed to clear all trails: ${e.message}")
            false
        }
    }

    // ---------------------------------------------------------------------------
    // Animation
    // ---------------------------------------------------------------------------

    /**
     * Animates a marker from its old position to a new position.
     */
    private fun animateMarkerPosition(oldMarker: DynamicMarker, newMarker: DynamicMarker) {
        // Cancel existing animation for this marker
        activeAnimators[oldMarker.id]?.cancel()

        val animator = ValueAnimator.ofFloat(0f, 1f).apply {
            duration = configuration.animationDurationMs.toLong()
            interpolator = LinearInterpolator()

            addUpdateListener { animation ->
                val fraction = animation.animatedValue as Float

                // Interpolate position
                val lat = lerp(oldMarker.latitude, newMarker.latitude, fraction)
                val lng = lerp(oldMarker.longitude, newMarker.longitude, fraction)

                // Interpolate heading if enabled
                val heading = if (configuration.animateHeading && oldMarker.heading != null && newMarker.heading != null) {
                    lerpAngle(oldMarker.heading, newMarker.heading, fraction)
                } else {
                    newMarker.heading
                }

                // Update annotation position
                val interpolatedMarker = newMarker.copy(
                    latitude = lat,
                    longitude = lng,
                    heading = heading
                )
                updateMarkerAnnotation(interpolatedMarker)
            }
        }

        animator.start()
        activeAnimators[oldMarker.id] = animator
    }

    /**
     * Linear interpolation between two values.
     */
    private fun lerp(start: Double, end: Double, fraction: Float): Double {
        return start + (end - start) * fraction
    }

    /**
     * Interpolates between two angles, handling wrap-around.
     */
    private fun lerpAngle(start: Double, end: Double, fraction: Float): Double {
        var diff = end - start
        while (diff > 180) diff -= 360
        while (diff < -180) diff += 360
        return start + diff * fraction
    }

    // ---------------------------------------------------------------------------
    // Annotation Management
    // ---------------------------------------------------------------------------

    /**
     * Creates a marker annotation on the map.
     */
    private fun createMarkerAnnotation(marker: DynamicMarker) {
        val annotationManager = pointAnnotationManager
        if (annotationManager == null) {
            Log.w(TAG, "createMarkerAnnotation: pointAnnotationManager is NULL for marker ${marker.id}")
            return
        }

        try {
            Log.d(TAG, "createMarkerAnnotation: Creating annotation for ${marker.id} at (${marker.latitude}, ${marker.longitude})")
            val iconBitmap = getMarkerIconBitmap(marker)
            Log.d(TAG, "  Got icon bitmap: ${iconBitmap.width}x${iconBitmap.height}")
            val options = PointAnnotationOptions()
                .withPoint(Point.fromLngLat(marker.longitude, marker.latitude))
                .withIconImage(iconBitmap)
                .withIconAnchor(IconAnchor.CENTER)
                .withIconSize(1.5)
                .withIconOpacity(getOpacityForState(marker.state))

            // Apply rotation if heading is available
            marker.heading?.let { heading ->
                options.withIconRotate(heading)
            }

            // Add text label if enabled in configuration
            if (configuration.showLabels) {
                val labelText = marker.title.ifEmpty { marker.category }
                options.withTextField(labelText)
                options.withTextSize(configuration.labelTextSize)
                options.withTextColor(configuration.labelTextColor)
                options.withTextHaloColor(configuration.labelHaloColor)
                options.withTextHaloWidth(configuration.labelHaloWidth)
                options.withTextOffset(listOf(0.0, configuration.labelOffsetY))
                options.withTextAnchor(com.mapbox.maps.extension.style.layers.properties.generated.TextAnchor.TOP)
            }

            val annotation = annotationManager.create(options)
            pointAnnotations[marker.id] = annotation
            Log.d(TAG, "  Annotation created successfully for ${marker.id}")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to create marker annotation: ${e.message}")
            e.printStackTrace()
        }
    }

    /**
     * Updates an existing marker annotation.
     * Note: Some properties like textColor and textHaloColor cannot be updated on existing
     * annotations in Mapbox SDK v10+. For full updates, we delete and recreate the annotation.
     */
    private fun updateMarkerAnnotation(marker: DynamicMarker) {
        val annotation = pointAnnotations[marker.id]
        val annotationManager = pointAnnotationManager

        if (annotation != null && annotationManager != null) {
            try {
                // Delete the existing annotation and recreate it with updated properties
                // This is necessary because PointAnnotation doesn't support updating
                // text color properties directly in Mapbox SDK v10+
                annotationManager.delete(annotation)
                pointAnnotations.remove(marker.id)
                createMarkerAnnotation(marker)
                Log.d(TAG, "updateMarkerAnnotation: Recreated ${marker.id} at (${marker.latitude}, ${marker.longitude})")
            } catch (e: Exception) {
                Log.e(TAG, "Failed to update marker annotation: ${e.message}")
            }
        } else {
            Log.d(TAG, "updateMarkerAnnotation: No existing annotation for ${marker.id}, creating new one")
            createMarkerAnnotation(marker)
        }
    }

    /**
     * Refreshes all marker annotations.
     */
    private fun refreshAllMarkers() {
        Log.d(TAG, "refreshAllMarkers called. Markers count: ${markers.size}")
        val annotationManager = pointAnnotationManager
        if (annotationManager == null) {
            Log.w(TAG, "  pointAnnotationManager is NULL - skipping refresh")
            return
        }

        try {
            Log.d(TAG, "  Deleting all existing annotations")
            annotationManager.deleteAll()
            pointAnnotations.clear()

            Log.d(TAG, "  Creating annotations for ${markers.size} markers")
            markers.values.forEach { marker ->
                Log.d(TAG, "    Creating annotation for: ${marker.id}")
                createMarkerAnnotation(marker)
                if (marker.showTrail) {
                    setupTrailForMarker(marker)
                }
            }
            Log.d(TAG, "  Refresh complete. pointAnnotations count: ${pointAnnotations.size}")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to refresh all markers: ${e.message}")
        }
    }

    /**
     * Gets the opacity for a marker based on its state.
     */
    private fun getOpacityForState(state: DynamicMarkerState): Double {
        return when (state) {
            DynamicMarkerState.TRACKING, DynamicMarkerState.ANIMATING -> 1.0
            DynamicMarkerState.STATIONARY -> 0.9
            DynamicMarkerState.STALE -> 0.6
            DynamicMarkerState.OFFLINE -> 0.4
            DynamicMarkerState.EXPIRED -> 0.2
        }
    }

    // ---------------------------------------------------------------------------
    // Trail Management
    // ---------------------------------------------------------------------------

    /**
     * Sets up trail rendering for a marker.
     */
    private fun setupTrailForMarker(marker: DynamicMarker) {
        val mapView = this.mapView ?: return
        val sourceId = "trail_source_${marker.id}"
        val layerId = "trail_layer_${marker.id}"

        try {
            mapView.getMapboxMap().getStyle { style ->
                // Create GeoJSON source for trail with empty line
                val source = geoJsonSource(sourceId) {
                    geometry(LineString.fromLngLats(emptyList()))
                }

                // Add source if not exists
                if (style.getSourceAs<GeoJsonSource>(sourceId) == null) {
                    style.addSource(source)
                }

                // Create line layer for trail
                if (style.getLayerAs<LineLayer>(layerId) == null) {
                    val layer = lineLayer(layerId, sourceId) {
                        lineColor(configuration.trailColor)
                        lineWidth(configuration.trailWidth)
                        lineOpacity(if (configuration.trailGradient) 0.7 else 1.0)
                    }
                    style.addLayer(layer)
                }

                trailSourceIds[marker.id] = sourceId
                trailLayerIds[marker.id] = layerId

                // Update with initial positions
                updateTrailForMarker(marker)
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to setup trail for marker: ${e.message}")
        }
    }

    /**
     * Updates the trail for a marker with new position history.
     */
    private fun updateTrailForMarker(marker: DynamicMarker) {
        val mapView = this.mapView ?: return
        val sourceId = trailSourceIds[marker.id] ?: return

        try {
            val points = mutableListOf<Point>()

            // Add position history
            marker.positionHistory?.forEach { latLng ->
                points.add(Point.fromLngLat(latLng.longitude, latLng.latitude))
            }

            // Add current position
            points.add(Point.fromLngLat(marker.longitude, marker.latitude))

            if (points.size >= 2) {
                mapView.getMapboxMap().getStyle { style ->
                    style.getSourceAs<GeoJsonSource>(sourceId)?.let { source ->
                        source.geometry(LineString.fromLngLats(points))
                    }
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to update trail: ${e.message}")
        }
    }

    /**
     * Removes the trail for a marker.
     */
    private fun removeTrailForMarker(markerId: String) {
        val mapView = this.mapView ?: return
        val sourceId = trailSourceIds[markerId]
        val layerId = trailLayerIds[markerId]

        try {
            mapView.getMapboxMap().getStyle { style ->
                layerId?.let { style.removeStyleLayer(it) }
                sourceId?.let { style.removeStyleSource(it) }
            }

            trailSourceIds.remove(markerId)
            trailLayerIds.remove(markerId)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to remove trail: ${e.message}")
        }
    }

    /**
     * Clears all trails.
     */
    private fun clearAllTrails() {
        val mapView = this.mapView ?: return

        try {
            mapView.getMapboxMap().getStyle { style ->
                trailLayerIds.values.forEach { layerId ->
                    style.removeStyleLayer(layerId)
                }
                trailSourceIds.values.forEach { sourceId ->
                    style.removeStyleSource(sourceId)
                }
            }

            trailSourceIds.clear()
            trailLayerIds.clear()
        } catch (e: Exception) {
            Log.e(TAG, "Failed to clear all trails: ${e.message}")
        }
    }

    // ---------------------------------------------------------------------------
    // Icon Generation
    // ---------------------------------------------------------------------------

    /**
     * Gets the appropriate marker icon bitmap for a marker.
     */
    private fun getMarkerIconBitmap(marker: DynamicMarker): Bitmap {
        val context = this.context ?: return getDefaultMarkerBitmap()
        val markerColor = marker.getMarkerColor()
        val drawableId = getDrawableIdForMarker(marker)
        return createCircularMarkerBitmap(context, drawableId, markerColor, marker.state)
    }

    /**
     * Creates a circular marker bitmap with state-based styling.
     */
    private fun createCircularMarkerBitmap(
        context: Context,
        drawableId: Int,
        backgroundColor: Int,
        state: DynamicMarkerState
    ): Bitmap {
        val size = 80
        val bitmap = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)

        // Draw circle background
        val backgroundPaint = android.graphics.Paint().apply {
            color = backgroundColor
            isAntiAlias = true
            style = android.graphics.Paint.Style.FILL
        }
        canvas.drawCircle(size / 2f, size / 2f, size / 2f - 2f, backgroundPaint)

        // Draw border - color varies by state
        val borderColor = when (state) {
            DynamicMarkerState.TRACKING, DynamicMarkerState.ANIMATING -> Color.WHITE
            DynamicMarkerState.STATIONARY -> Color.LTGRAY
            DynamicMarkerState.STALE -> Color.YELLOW
            DynamicMarkerState.OFFLINE -> Color.RED
            DynamicMarkerState.EXPIRED -> Color.DKGRAY
        }

        val borderPaint = android.graphics.Paint().apply {
            color = borderColor
            isAntiAlias = true
            style = android.graphics.Paint.Style.STROKE
            strokeWidth = 3f
        }
        canvas.drawCircle(size / 2f, size / 2f, size / 2f - 2f, borderPaint)

        // Draw the icon
        try {
            val drawable: Drawable? = ContextCompat.getDrawable(context, drawableId)
            drawable?.let { originalIcon ->
                val icon = originalIcon.mutate()
                val iconSize = (size * 0.5).toInt()
                val left = (size - iconSize) / 2
                val top = (size - iconSize) / 2
                icon.setBounds(left, top, left + iconSize, top + iconSize)
                icon.setTint(Color.WHITE)
                icon.draw(canvas)
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to draw icon: ${e.message}")
        }

        return bitmap
    }

    /**
     * Gets the drawable resource ID for a marker.
     */
    private fun getDrawableIdForMarker(marker: DynamicMarker): Int {
        // First try iconId
        marker.iconId?.let { iconId ->
            getDrawableIdForIconId(iconId)?.let { return it }
        }

        // Fallback to category
        return getDrawableIdForIconId(marker.category) ?: R.drawable.ic_pin
    }

    /**
     * Maps an icon ID or category to a drawable resource.
     */
    private fun getDrawableIdForIconId(iconId: String): Int? {
        return when (iconId.lowercase()) {
            // Vehicles
            "vehicle", "car" -> R.drawable.ic_pin
            "truck" -> R.drawable.ic_pin
            "bus" -> R.drawable.ic_bus_stop
            "drone" -> R.drawable.ic_pin
            "aircraft", "plane" -> R.drawable.ic_airport
            "helicopter" -> R.drawable.ic_pin

            // People
            "person", "pedestrian" -> R.drawable.ic_pin
            "runner" -> R.drawable.ic_hiking
            "cyclist" -> R.drawable.ic_pin

            // Delivery
            "delivery", "courier" -> R.drawable.ic_pin
            "package" -> R.drawable.ic_pin

            // Emergency
            "emergency", "ambulance" -> R.drawable.ic_hospital
            "police" -> R.drawable.ic_police
            "fire" -> R.drawable.ic_fire_station

            // Transit
            "transit", "train" -> R.drawable.ic_train_station
            "subway" -> R.drawable.ic_train_station

            // Maritime
            "boat", "ship", "vessel" -> R.drawable.ic_port

            // Default
            "marker_dynamic", "dynamic" -> R.drawable.ic_pin

            else -> null
        }
    }

    /**
     * Creates a default marker bitmap.
     */
    private fun getDefaultMarkerBitmap(): Bitmap {
        val size = 80
        val bitmap = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)

        val paint = android.graphics.Paint().apply {
            color = Color.parseColor("#2196F3")
            isAntiAlias = true
        }
        canvas.drawCircle(size / 2f, size / 2f, size / 2f - 2f, paint)

        val borderPaint = android.graphics.Paint().apply {
            color = Color.WHITE
            isAntiAlias = true
            style = android.graphics.Paint.Style.STROKE
            strokeWidth = 3f
        }
        canvas.drawCircle(size / 2f, size / 2f, size / 2f - 2f, borderPaint)

        return bitmap
    }

    // ---------------------------------------------------------------------------
    // Events
    // ---------------------------------------------------------------------------

    /**
     * Handles marker tap events.
     */
    private fun onMarkerTap(marker: DynamicMarker) {
        try {
            val eventData = mutableMapOf<String, Any?>(
                "eventType" to "dynamic_marker_tapped",
                "marker" to marker.toJson()
            )
            eventSink?.success(eventData)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to handle marker tap: ${e.message}")
        }
    }

    /**
     * Sends a state changed event.
     */
    private fun sendStateChangedEvent(marker: DynamicMarker, oldState: DynamicMarkerState) {
        try {
            val eventData = mutableMapOf<String, Any?>(
                "eventType" to "dynamic_marker_state_changed",
                "marker" to marker.toJson(),
                "oldState" to oldState.toJsonString(),
                "newState" to marker.state.toJsonString()
            )
            eventSink?.success(eventData)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to send state changed event: ${e.message}")
        }
    }

    /**
     * Sends a position updated event.
     */
    private fun sendPositionUpdatedEvent(marker: DynamicMarker) {
        try {
            val eventData = mutableMapOf<String, Any?>(
                "eventType" to "dynamic_marker_position_updated",
                "marker" to marker.toJson()
            )
            eventSink?.success(eventData)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to send position updated event: ${e.message}")
        }
    }

    /**
     * Sends a marker expired event.
     */
    private fun sendMarkerExpiredEvent(marker: DynamicMarker) {
        try {
            val eventData = mutableMapOf<String, Any?>(
                "eventType" to "dynamic_marker_expired",
                "marker" to marker.toJson()
            )
            eventSink?.success(eventData)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to send marker expired event: ${e.message}")
        }
    }
}
