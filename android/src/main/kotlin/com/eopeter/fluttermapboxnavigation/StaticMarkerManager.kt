package com.eopeter.fluttermapboxnavigation

import com.eopeter.fluttermapboxnavigation.models.MarkerConfiguration
import com.eopeter.fluttermapboxnavigation.models.StaticMarker
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
import com.eopeter.fluttermapboxnavigation.models.MapBoxEvents
import com.eopeter.fluttermapboxnavigation.utilities.PluginUtilities
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
        val tapThreshold = 0.01
        return markers.values.find { marker ->
            val latDiff = abs(marker.latitude - latitude)
            val lonDiff = abs(marker.longitude - longitude)
            latDiff < tapThreshold && lonDiff < tapThreshold
        }
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
                        .withIconAnchor(IconAnchor.BOTTOM)
                        .withIconSize(2.5)
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
     * Gets the appropriate marker icon bitmap for a marker
     */
    private fun getMarkerIconBitmap(marker: StaticMarker): Bitmap {
        val context = this.context ?: return getDefaultMarkerBitmap()
        
        // Get the drawable resource ID based on the marker's iconId or category
        val drawableId = getDrawableIdForMarker(marker)
        
        // Get the drawable and convert it to bitmap
        val drawable = ContextCompat.getDrawable(context, drawableId)
        return if (drawable != null) {
            drawableToBitmap(drawable)
        } else {
            getDefaultMarkerBitmap()
        }
    }
    
    /**
     * Gets the drawable resource ID for a marker based on its iconId or category
     */
    private fun getDrawableIdForMarker(marker: StaticMarker): Int {
        // First try to match by iconId if available
        marker.iconId?.let { iconId ->
            when (iconId.lowercase()) {
                "scenic" -> return R.drawable.ic_scenic
                "petrol_station", "petrol", "gas" -> return R.drawable.ic_petrol_station
                "restaurant", "food" -> return R.drawable.ic_restaurant
                "hotel", "accommodation" -> return R.drawable.ic_hotel
                "parking" -> return R.drawable.ic_parking
                "hospital", "medical" -> return R.drawable.ic_hospital
                "police" -> return R.drawable.ic_police
                "charging_station", "charging" -> return R.drawable.ic_charging_station
                "construction" -> return R.drawable.ic_construction
                "accident" -> return R.drawable.ic_accident
                "speed_camera" -> return R.drawable.ic_speed_camera
                "star" -> return R.drawable.ic_pin // Use pin as fallback for star
                "flag" -> return R.drawable.ic_flag
                "pin" -> return R.drawable.ic_pin
                else -> {
                    // Unknown iconId, fall through to category matching
                }
            }
        }
        
        // Fallback to category matching
        return when (marker.category.lowercase()) {
            "checkpoint" -> R.drawable.ic_flag  // Checkpoints use flag icon
            "waypoint" -> R.drawable.ic_pin     // Regular waypoints use pin
            "scenic" -> R.drawable.ic_scenic
            "petrol_station", "fuel" -> R.drawable.ic_petrol_station
            "restaurant", "food" -> R.drawable.ic_restaurant
            "hotel", "accommodation" -> R.drawable.ic_hotel
            "parking" -> R.drawable.ic_parking
            "hospital", "medical" -> R.drawable.ic_hospital
            "police", "safety" -> R.drawable.ic_police
            "charging_station" -> R.drawable.ic_charging_station
            "construction" -> R.drawable.ic_construction
            "accident" -> R.drawable.ic_accident
            "speed_camera" -> R.drawable.ic_speed_camera
            else -> R.drawable.ic_pin // Default pin icon
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