package com.neiladunlop.fluttermapboxnavigation2

import com.neiladunlop.fluttermapboxnavigation2.models.MarkerConfiguration
import com.neiladunlop.fluttermapboxnavigation2.models.StaticMarker
import io.flutter.plugin.common.EventChannel
import kotlin.math.abs
import android.content.Context
import android.util.Log
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.Drawable
import androidx.core.content.ContextCompat
import com.mapbox.maps.MapView
import com.mapbox.maps.Style
import com.mapbox.geojson.Point
import com.mapbox.maps.plugin.annotation.annotations
import com.mapbox.maps.plugin.annotation.generated.PointAnnotationManager
import com.mapbox.maps.plugin.annotation.generated.PointAnnotationOptions
import com.mapbox.maps.plugin.annotation.generated.createPointAnnotationManager
import com.mapbox.maps.plugin.annotation.generated.PointAnnotation
import com.mapbox.maps.extension.style.layers.properties.generated.IconAnchor
import com.neiladunlop.fluttermapboxnavigation2.models.MapBoxEvents
import com.neiladunlop.fluttermapboxnavigation2.utilities.PluginUtilities
import com.google.gson.Gson
import org.json.JSONObject

/**
 * Manages static markers for the Mapbox Navigation plugin
 * Implements the Mapbox Maps SDK v10 Annotations API for marker rendering
 * 
 * Based on official Mapbox documentation:
 * - Maps SDK v11 Annotations: https://docs.mapbox.com/android/maps/guides/annotations/annotations/
 * - Point Annotations: https://docs.mapbox.com/android/maps/guides/annotations/point-annotations/
 * 
 * Current Status: Maps SDK v11 Annotations API implementation
 * - ✅ Maps SDK v11.13.3 with Annotations API
 * - ✅ Visual marker rendering on map
 * - ✅ Interactive tap handling
 * - ✅ Custom marker icons with drawable resources
 * - ✅ Production ready with official APIs
 */
class StaticMarkerManager {
    private val markers = mutableMapOf<String, StaticMarker>()
    private var configuration: MarkerConfiguration = MarkerConfiguration()
    private var eventSink: EventChannel.EventSink? = null
    private var context: Context? = null
    private var mapView: MapView? = null
    private var style: Style? = null
    private var pointAnnotationManager: PointAnnotationManager? = null
    private val pointAnnotations = mutableMapOf<String, PointAnnotation>()
    private var markerTapListener: ((StaticMarker) -> Unit)? = null

    companion object {
        @Volatile
        private var INSTANCE: StaticMarkerManager? = null

        fun getInstance(): StaticMarkerManager {
            return INSTANCE ?: synchronized(this) {
                INSTANCE ?: StaticMarkerManager().also { INSTANCE = it }
            }
        }
    }

    /**
     * Sets the context for resource access
     */
    fun setContext(context: Context?) {
        this.context = context
    }

    /**
     * Sets the marker tap listener for custom handling
     */
    fun setMarkerTapListener(listener: ((StaticMarker) -> Unit)?) {
        this.markerTapListener = listener
    }

    /**
     * Manually trigger marker tap listener for external callers
     */
    fun triggerMarkerTapListener(marker: StaticMarker) {
        markerTapListener?.invoke(marker)
    }

    /**
     * Returns a copy of all currently registered markers
     */
    fun getMarkers(): List<StaticMarker> {
        return markers.values.toList()
    }

    /**
     * Sets the MapView and initializes the marker system
     */
    fun setMapView(mapView: MapView?) {
        this.mapView = mapView
        if (mapView != null) {
            // Initialize the marker system when the map is ready
            initializeMarkerSystem()
        } else {
            style = null
            pointAnnotationManager = null
            pointAnnotations.clear()
        }
    }

    /**
     * Initializes the marker system using Maps SDK v10 Annotations API
     */
    private fun initializeMarkerSystem() {
        mapView?.let { view ->
            // Delay initialization to ensure it happens after navigation UI is fully loaded
            view.post {
                try {
                    pointAnnotationManager = view.annotations.createPointAnnotationManager()
                    setupMarkerClickListener()
                    applyMarkersToMap()
                } catch (e: Exception) {
                    Log.e("StaticMarkerManager", "Failed to initialize marker system: ${e.message}")
                }
            }
        }
    }
    
    /**
     * Sets up the marker click listener for interactive markers
     */
    private fun setupMarkerClickListener() {
        pointAnnotationManager?.addClickListener { annotation ->
            val markerId = pointAnnotations.entries.find { it.value == annotation }?.key
            markerId?.let { id ->
                markers[id]?.let { marker ->
                    val flutterOverlaysEnabled = try {
                        FlutterMapboxNavigationPlugin.enableFlutterStyleOverlays
                    } catch (e: Exception) {
                        false
                    }

                    if (markerTapListener != null) {
                        markerTapListener?.invoke(marker)
                    } else if (!flutterOverlaysEnabled) {
                        onMarkerTap(marker)
                    }
                    Unit
                }
            }
            false
        }
    }
    
    /**
     * Converts a drawable resource to a bitmap for use as marker icon
     */
    private fun drawableToBitmap(drawable: Drawable): Bitmap {
        val bitmap = Bitmap.createBitmap(
            drawable.intrinsicWidth,
            drawable.intrinsicHeight,
            Bitmap.Config.ARGB_8888
        )
        val canvas = Canvas(bitmap)
        drawable.setBounds(0, 0, canvas.width, canvas.height)
        drawable.draw(canvas)
        return bitmap
    }

    /**
     * Sets the event sink for marker tap events
     */
    fun setEventSink(eventSink: EventChannel.EventSink?) {
        this.eventSink = eventSink
    }

    /**
     * Adds static markers to the map
     */
    fun addStaticMarkers(markers: List<StaticMarker>, config: MarkerConfiguration): Boolean {
        try {
            // Store configuration
            this.configuration = config

            // Clear existing markers
            clearAllStaticMarkers()

            // Add new markers
            markers.forEach { marker ->
                this.markers[marker.id] = marker
            }

            applyMarkersToMap()
            return true
        } catch (e: Exception) {
            Log.e("StaticMarkerManager", "Failed to add static markers: ${e.message}")
            return false
        }
    }

    /**
     * Updates existing static markers
     */
    fun updateStaticMarkers(markers: List<StaticMarker>): Boolean {
        try {
            markers.forEach { marker ->
                this.markers[marker.id] = marker
            }
            applyMarkersToMap()
            return true
        } catch (e: Exception) {
            Log.e("StaticMarkerManager", "Failed to update static markers: ${e.message}")
            return false
        }
    }

    /**
     * Removes specific static markers
     */
    fun removeStaticMarkers(markerIds: List<String>): Boolean {
        try {
            markerIds.forEach { id ->
                markers.remove(id)
            }
            applyMarkersToMap()
            return true
        } catch (e: Exception) {
            Log.e("StaticMarkerManager", "Failed to remove static markers: ${e.message}")
            return false
        }
    }

    /**
     * Clears all static markers
     */
    fun clearAllStaticMarkers(): Boolean {
        try {
            markers.clear()
            return true
        } catch (e: Exception) {
            Log.e("StaticMarkerManager", "Failed to clear static markers: ${e.message}")
            return false
        }
    }

    /**
     * Gets the current list of static markers
     */
    fun getStaticMarkers(): List<StaticMarker> {
        return markers.values.toList()
    }

    /**
     * Updates the marker configuration
     */
    fun updateMarkerConfiguration(config: MarkerConfiguration): Boolean {
        try {
            this.configuration = config
            applyMarkersToMap()
            return true
        } catch (e: Exception) {
            Log.e("StaticMarkerManager", "Failed to update marker configuration: ${e.message}")
            return false
        }
    }

    /**
     * Handles marker tap events
     */
    fun onMarkerTap(marker: StaticMarker) {
        try {
            val markerData = marker.toJson()
            eventSink?.success(markerData)
        } catch (e: Exception) {
            Log.e("StaticMarkerManager", "Failed to handle marker tap: ${e.message}")
        }
    }
    
    /**
     * Handles marker tap events for full-screen navigation
     * Routes events to Flutter instead of showing native dialogs
     */
    fun onMarkerTapFullScreen(marker: StaticMarker) {
        try {
            val eventData = mutableMapOf<String, Any>(
                "type" to "marker_tap",
                "mode" to "fullscreen"
            )
            val markerData = marker.toJson()
            markerData.forEach { (key, value) ->
                if (value != null) {
                    eventData["marker_$key"] = value
                }
            }
            sendFullScreenEvent(MapBoxEvents.MARKER_TAP_FULLSCREEN, eventData)
        } catch (e: Exception) {
            Log.e("StaticMarkerManager", "Failed to handle full-screen marker tap: ${e.message}")
        }
    }

    /**
     * Sends full-screen navigation events to Flutter
     */
    private fun sendFullScreenEvent(eventType: MapBoxEvents, data: Map<String, Any>) {
        try {
            val jsonData = JSONObject(data).toString()
            PluginUtilities.sendEvent(eventType, jsonData)
        } catch (e: Exception) {
            Log.e("StaticMarkerManager", "Failed to send full-screen event: ${e.message}")
        }
    }

    /**
     * Checks if a point is near any existing marker
     */
    fun isPointNearAnyMarker(latitude: Double, longitude: Double): Boolean {
        val tapThreshold = 0.001
        return markers.values.any { marker ->
            val latDiff = abs(marker.latitude - latitude)
            val lonDiff = abs(marker.longitude - longitude)
            latDiff < tapThreshold && lonDiff < tapThreshold
        }
    }

    /**
     * Returns the marker near a given point, or null if no marker is found
     */
    fun getMarkerNearPoint(latitude: Double, longitude: Double): StaticMarker? {
        // Threshold of 0.005 degrees (~500m) - tight enough for accuracy
        // but allows for some tap offset on marker icons
        val tapThreshold = 0.005

        // Find the closest marker within threshold
        var closestMarker: StaticMarker? = null
        var closestDistance = Double.MAX_VALUE

        markers.values.forEach { marker ->
            val latDiff = abs(marker.latitude - latitude)
            val lonDiff = abs(marker.longitude - longitude)

            // Calculate simple distance (not accounting for Earth curvature, but fine for small distances)
            val distance = latDiff + lonDiff

            if (latDiff < tapThreshold && lonDiff < tapThreshold && distance < closestDistance) {
                closestDistance = distance
                closestMarker = marker
            }
        }

        return closestMarker
    }

    /**
     * Applies markers to the map based on current configuration
     */
    private fun applyMarkersToMap() {
        try {
            // Filter markers based on configuration
            val visibleMarkers = markers.values.filter { marker ->
                marker.isVisible && shouldShowMarker(marker)
            }

            // Apply clustering if enabled
            val finalMarkers = if (configuration.enableClustering) {
                applyClustering(visibleMarkers)
            } else {
                visibleMarkers
            }

            // Limit markers if maxMarkersToShow is set
            val limitedMarkers = configuration.maxMarkersToShow?.let { max ->
                finalMarkers.take(max)
            } ?: finalMarkers

            // Add markers to the map using Annotations API
            addMarkersWithAnnotationsAPI(limitedMarkers)

        } catch (e: Exception) {
            Log.e("StaticMarkerManager", "Failed to apply markers to map: ${e.message}")
        }
    }

    /**
     * Determines if a marker should be shown based on configuration
     */
    private fun shouldShowMarker(marker: StaticMarker): Boolean {
        // Check if marker is within distance from route
        configuration.maxDistanceFromRoute?.let { maxDistance ->
            // This would need to be implemented with actual route data
            // For now, we'll show all markers
            return true
        }

        return true
    }

    /**
     * Applies clustering to markers
     */
    private fun applyClustering(markers: List<StaticMarker>): List<StaticMarker> {
        if (!configuration.enableClustering) {
            return markers
        }

        // Simple clustering implementation
        // In a real implementation, this would use Mapbox's clustering features
        val clusteredMarkers = mutableListOf<StaticMarker>()
        val clusterRadius = 0.01 // Approximately 1km at equator

        markers.forEach { marker ->
            val nearbyMarker = clusteredMarkers.find { existing ->
                val latDiff = abs(existing.latitude - marker.latitude)
                val lngDiff = abs(existing.longitude - marker.longitude)
                latDiff < clusterRadius && lngDiff < clusterRadius
            }

            if (nearbyMarker == null) {
                clusteredMarkers.add(marker)
            }
            // If nearby marker exists, we could merge them or prioritize based on priority
        }

        return clusteredMarkers
    }

    /**
     * Adds markers to the map using Maps SDK v11 Annotations API
     */
    private fun addMarkersWithAnnotationsAPI(markers: List<StaticMarker>) {
        if (markers.isEmpty()) return

        val annotationManager = pointAnnotationManager ?: return

        try {
            annotationManager.deleteAll()
            pointAnnotations.clear()

            markers.forEach { marker ->
                try {
                    val iconBitmap = getMarkerIconBitmap(marker)
                    val pointAnnotationOptions = PointAnnotationOptions()
                        .withPoint(Point.fromLngLat(marker.longitude, marker.latitude))
                        .withIconImage(iconBitmap)
                        .withIconAnchor(IconAnchor.CENTER) // Center anchor for circular markers
                        .withIconSize(1.5) // Larger size for better visibility
                        .withIconOpacity(1.0)

                    val annotation = annotationManager.create(pointAnnotationOptions)
                    pointAnnotations[marker.id] = annotation
                } catch (e: Exception) {
                    Log.e("StaticMarkerManager", "Failed to add marker ${marker.id}: ${e.message}")
                }
            }
        } catch (e: Exception) {
            Log.e("StaticMarkerManager", "Failed to render markers: ${e.message}")
        }
    }

    /**
     * Gets the appropriate marker icon bitmap for a marker.
     * Creates a circular marker with a colored background and white icon.
     */
    private fun getMarkerIconBitmap(marker: StaticMarker): Bitmap {
        val context = this.context ?: return getDefaultMarkerBitmap()

        // Get the marker color based on category
        val markerColor = marker.getMarkerColor()

        // Get the drawable resource ID based on the marker's iconId or category
        val drawableId = getDrawableIdForMarker(marker)

        // Create a circular marker with the icon
        return createCircularMarkerBitmap(context, drawableId, markerColor)
    }

    /**
     * Creates a circular marker bitmap with a colored background and white icon.
     * Similar to the destination marker style for visual consistency.
     */
    private fun createCircularMarkerBitmap(context: Context, drawableId: Int, backgroundColor: Int): Bitmap {
        val size = 80 // Size of the marker in pixels
        val bitmap = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)

        // Draw circle background
        val backgroundPaint = android.graphics.Paint().apply {
            color = backgroundColor
            isAntiAlias = true
            style = android.graphics.Paint.Style.FILL
        }
        canvas.drawCircle(size / 2f, size / 2f, size / 2f - 2f, backgroundPaint)

        // Draw white border for visibility
        val borderPaint = android.graphics.Paint().apply {
            color = android.graphics.Color.WHITE
            isAntiAlias = true
            style = android.graphics.Paint.Style.STROKE
            strokeWidth = 3f
        }
        canvas.drawCircle(size / 2f, size / 2f, size / 2f - 2f, borderPaint)

        // Draw the icon on top
        try {
            val drawable: Drawable? = ContextCompat.getDrawable(context, drawableId)
            drawable?.let { originalIcon ->
                // Create a mutable copy to avoid modifying the cached drawable
                val icon = originalIcon.mutate()
                // Center the icon within the circle
                val iconSize = (size * 0.5).toInt() // Icon is 50% of the circle size
                val left = (size - iconSize) / 2
                val top = (size - iconSize) / 2
                icon.setBounds(left, top, left + iconSize, top + iconSize)
                icon.setTint(android.graphics.Color.WHITE) // White icon on colored background
                icon.draw(canvas)
            }
        } catch (e: Exception) {
            Log.e("StaticMarkerManager", "Failed to draw icon: ${e.message}")
        }

        return bitmap
    }
    
    /**
     * Gets the drawable resource ID for a marker based on its iconId or category.
     * This is public so it can be reused by MarkerPopupOverlay for consistent icons.
     */
    fun getDrawableIdForMarker(marker: StaticMarker): Int {
        // First try to match by iconId if available
        marker.iconId?.let { iconId ->
            getDrawableIdForIconId(iconId)?.let { return it }
        }

        // Fallback to category matching
        return getDrawableIdForIconId(marker.category) ?: R.drawable.ic_pin
    }

    /**
     * Maps an icon ID or category string to a drawable resource ID.
     * Returns null if no matching icon is found.
     */
    private fun getDrawableIdForIconId(iconId: String): Int? {
        return when (iconId.lowercase()) {
            // Transportation
            "petrol_station", "petrol", "gas", "fuel" -> R.drawable.ic_petrol_station
            "charging_station", "charging", "ev" -> R.drawable.ic_charging_station
            "parking" -> R.drawable.ic_parking
            "bus_stop", "bus" -> R.drawable.ic_bus_stop
            "train_station", "train", "rail" -> R.drawable.ic_train_station
            "airport", "flight", "plane" -> R.drawable.ic_airport
            "port", "harbor", "ferry" -> R.drawable.ic_port

            // Food & Services
            "restaurant", "food", "dining" -> R.drawable.ic_restaurant
            "cafe", "coffee" -> R.drawable.ic_cafe
            "hotel", "accommodation", "lodging" -> R.drawable.ic_hotel
            "shop", "store", "shopping" -> R.drawable.ic_shop
            "pharmacy", "drugstore" -> R.drawable.ic_pharmacy
            "hospital", "medical", "emergency" -> R.drawable.ic_hospital
            "police", "safety" -> R.drawable.ic_police
            "fire_station", "fire" -> R.drawable.ic_fire_station

            // Scenic & Recreation
            "scenic" -> R.drawable.ic_scenic
            "viewpoint", "overlook" -> R.drawable.ic_viewpoint
            "park", "garden" -> R.drawable.ic_park
            "beach", "coast" -> R.drawable.ic_beach
            "mountain", "peak", "summit" -> R.drawable.ic_mountain
            "lake", "pond" -> R.drawable.ic_lake
            "waterfall", "falls" -> R.drawable.ic_waterfall
            "hiking", "trail", "walk" -> R.drawable.ic_hiking

            // Safety & Traffic
            "speed_camera", "camera" -> R.drawable.ic_speed_camera
            "accident", "crash" -> R.drawable.ic_accident
            "construction", "roadwork" -> R.drawable.ic_construction
            "traffic_light", "signal" -> R.drawable.ic_traffic_light
            "speed_bump", "bump" -> R.drawable.ic_speed_bump
            "school_zone", "school" -> R.drawable.ic_school_zone

            // General
            "pin", "marker", "location" -> R.drawable.ic_pin
            "star", "favorite" -> R.drawable.ic_star
            "heart", "like" -> R.drawable.ic_heart
            "flag", "checkpoint" -> R.drawable.ic_flag
            "warning", "alert", "caution" -> R.drawable.ic_warning
            "info", "information" -> R.drawable.ic_info
            "question", "help" -> R.drawable.ic_question

            // Legacy category names
            "waypoint" -> R.drawable.ic_pin

            else -> null
        }
    }
    
    /**
     * Creates a default marker bitmap when context is not available
     */
    private fun getDefaultMarkerBitmap(): Bitmap {
        return createSimpleColoredMarker(android.graphics.Color.RED)
    }
    
    /**
     * Creates a large, highly visible colored circle bitmap for testing
     */
    private fun createSimpleColoredMarker(color: Int): Bitmap {
        // Create a large, very visible colored circle
        val size = 100 // Much larger for visibility
        val bitmap = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        
        // Draw a bright colored circle with border
        val paint = android.graphics.Paint().apply {
            this.color = color
            isAntiAlias = true
        }
        
        val borderPaint = android.graphics.Paint().apply {
            this.color = android.graphics.Color.WHITE
            isAntiAlias = true
            style = android.graphics.Paint.Style.STROKE
            strokeWidth = 6f
        }
        
        // Draw filled circle
        canvas.drawCircle(size / 2f, size / 2f, size / 2f - 4f, paint)
        // Draw white border
        canvas.drawCircle(size / 2f, size / 2f, size / 2f - 4f, borderPaint)
        
        return bitmap
    }

    /**
     * Converts geographic coordinates to screen position
     * Returns null if MapView is not available or coordinates cannot be projected
     */
    fun getScreenPosition(latitude: Double, longitude: Double): Pair<Double, Double>? {
        return try {
            val mapView = this.mapView ?: return null
            val mapboxMap = mapView.getMapboxMap()
            
            val point = Point.fromLngLat(longitude, latitude)
            val screenCoordinate = mapboxMap.pixelForCoordinate(point)
            
            Pair(screenCoordinate.x, screenCoordinate.y)
        } catch (e: Exception) {
            Log.e("StaticMarkerManager", "Failed to get screen position: ${e.message}")
            null
        }
    }

    /**
     * Gets current map viewport information
     * Returns viewport data as a Map for Flutter consumption
     */
    fun getMapViewport(): Map<String, Any>? {
        return try {
            val mapView = this.mapView ?: return null
            val mapboxMap = mapView.getMapboxMap()
            val cameraState = mapboxMap.cameraState
            
            mapOf(
                "center" to mapOf(
                    "latitude" to cameraState.center.latitude(),
                    "longitude" to cameraState.center.longitude()
                ),
                "zoom" to cameraState.zoom,
                "bearing" to cameraState.bearing,
                "pitch" to cameraState.pitch,
                "size" to mapOf(
                    "width" to mapView.width,
                    "height" to mapView.height
                )
            )
        } catch (e: Exception) {
            Log.e("StaticMarkerManager", "Failed to get map viewport: ${e.message}")
            null
        }
    }
} 