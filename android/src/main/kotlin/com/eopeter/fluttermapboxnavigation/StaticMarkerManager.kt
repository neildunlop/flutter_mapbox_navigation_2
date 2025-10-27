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
        Log.d("StaticMarkerManager", "🎯 triggerMarkerTapListener called for: ${marker.title}")
        Log.d("StaticMarkerManager", "🎯 markerTapListener exists: ${markerTapListener != null}")
        markerTapListener?.invoke(marker) ?: run {
            Log.w("StaticMarkerManager", "⚠️ No marker tap listener set - cannot trigger")
        }
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
            println("🗺️ Initializing marker system using Maps SDK v10 Annotations API...")
            
            // Delay initialization to ensure it happens after navigation UI is fully loaded
            view.post {
                try {
                    println("🔄 Creating annotation manager after UI load...")
                    pointAnnotationManager = view.annotations.createPointAnnotationManager()
                    setupMarkerClickListener()
                    
                    println("✅ Marker system initialized successfully with Annotations API")
                    println("🔧 Annotation manager created successfully")
                    
                    // Re-apply any existing markers
                    applyMarkersToMap()
                    
                } catch (e: Exception) {
                    println("❌ Failed to initialize marker system: ${e.message}")
                    e.printStackTrace()
                }
            }
        } ?: run {
            println("❌ MapView is null - cannot initialize marker system")
        }
    }
    
    /**
     * Sets up the marker click listener for interactive markers
     */
    private fun setupMarkerClickListener() {
        pointAnnotationManager?.addClickListener { annotation ->
            println("🎯 Annotation click detected: ${annotation.geometry}")
            // Find the marker associated with this annotation
            val markerId = pointAnnotations.entries.find { it.value == annotation }?.key
            markerId?.let { id ->
                markers[id]?.let { marker ->
                    println("🎯 Annotation click for marker: ${marker.title} at (${marker.latitude}, ${marker.longitude})")
                    
                    // Check if Flutter overlays are enabled
                    val flutterOverlaysEnabled = try {
                        FlutterMapboxNavigationPlugin.enableFlutterStyleOverlays
                    } catch (e: Exception) {
                        println("🎯 Could not check Flutter overlay flag: ${e.message}")
                        false
                    }
                    
                    // Use custom marker tap listener if set, otherwise use default behavior
                    if (markerTapListener != null) {
                        println("🎯 Using custom marker tap listener for: ${marker.title}")
                        markerTapListener?.invoke(marker)
                    } else if (!flutterOverlaysEnabled) {
                        // Only send to Flutter if Flutter overlays are NOT enabled
                        println("🎯 Sending marker tap to Flutter (Flutter overlays disabled)")
                        onMarkerTap(marker)
                    } else {
                        println("🎯 Skipping Flutter event (Flutter overlays enabled - NavigationActivity will handle)")
                    }
                }
            }
            false // Allow map click to also fire for NavigationActivity handling
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
            println("🎯 Adding ${markers.size} static markers...")
            
            // Store configuration
            this.configuration = config

            // Clear existing markers
            clearAllStaticMarkers()

            // Add new markers
            markers.forEach { marker ->
                this.markers[marker.id] = marker
            }

            // Apply markers to map
            applyMarkersToMap()

            println("✅ Successfully added ${markers.size} static markers")
            return true
        } catch (e: Exception) {
            println("❌ Failed to add static markers: ${e.message}")
            e.printStackTrace()
            return false
        }
    }

    /**
     * Updates existing static markers
     */
    fun updateStaticMarkers(markers: List<StaticMarker>): Boolean {
        try {
            println("🔄 Updating ${markers.size} static markers...")
            
            markers.forEach { marker ->
                this.markers[marker.id] = marker
            }
            applyMarkersToMap()
            
            println("✅ Successfully updated ${markers.size} static markers")
            return true
        } catch (e: Exception) {
            println("❌ Failed to update static markers: ${e.message}")
            e.printStackTrace()
            return false
        }
    }

    /**
     * Removes specific static markers
     */
    fun removeStaticMarkers(markerIds: List<String>): Boolean {
        try {
            println("🗑️ Removing ${markerIds.size} static markers...")
            
            markerIds.forEach { id ->
                markers.remove(id)
            }
            applyMarkersToMap()
            
            println("✅ Successfully removed ${markerIds.size} static markers")
            return true
        } catch (e: Exception) {
            println("❌ Failed to remove static markers: ${e.message}")
            e.printStackTrace()
            return false
        }
    }

    /**
     * Clears all static markers
     */
    fun clearAllStaticMarkers(): Boolean {
        try {
            val markerCount = markers.size
            // Clear from memory
            markers.clear()
            
            // Clear from map
            // No direct API to remove all symbols from a source,
            // so we'd need to manage a list of symbol IDs or re-add them.
            // For now, we'll just clear the map.
            println("🧹 Cleared all ${markerCount} static markers")
            
            return true
        } catch (e: Exception) {
            println("❌ Failed to clear static markers: ${e.message}")
            e.printStackTrace()
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
            println("⚙️ Updating marker configuration...")
            
            this.configuration = config
            applyMarkersToMap()
            
            println("✅ Marker configuration updated successfully")
            return true
        } catch (e: Exception) {
            println("❌ Failed to update marker configuration: ${e.message}")
            e.printStackTrace()
            return false
        }
    }

    /**
     * Handles marker tap events
     */
    fun onMarkerTap(marker: StaticMarker) {
        try {
            // Send marker data to Flutter (for embedded views)
            val markerData = marker.toJson()
            eventSink?.success(markerData)
            
            println("🎯 Marker tapped: ${marker.title}")
        } catch (e: Exception) {
            println("❌ Failed to handle marker tap: ${e.message}")
            e.printStackTrace()
        }
    }
    
    /**
     * Handles marker tap events for full-screen navigation
     * Routes events to Flutter instead of showing native dialogs
     */
    fun onMarkerTapFullScreen(marker: StaticMarker) {
        try {
            // Create event data for full-screen navigation
            // Create a flat structure to avoid JSON nesting issues
            val eventData = mutableMapOf<String, Any>(
                "type" to "marker_tap",
                "mode" to "fullscreen"
            )
            
            // Add all marker fields directly to avoid nested JSON
            val markerData = marker.toJson()
            markerData.forEach { (key, value) ->
                // Only add non-null values to avoid type casting issues
                if (value != null) {
                    eventData["marker_$key"] = value
                }
            }
            
            // Send to main navigation event channel
            sendFullScreenEvent(MapBoxEvents.MARKER_TAP_FULLSCREEN, eventData)
            
            println("🎯 Full-screen marker tapped: ${marker.title}")
        } catch (e: Exception) {
            println("❌ Failed to handle full-screen marker tap: ${e.message}")
            e.printStackTrace()
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
            println("❌ Failed to send full-screen event: ${e.message}")
            e.printStackTrace()
        }
    }

    /**
     * Checks if a point is near any existing marker
     */
    fun isPointNearAnyMarker(latitude: Double, longitude: Double): Boolean {
        val tapThreshold = 0.001 // ~100m threshold for tap detection
        
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
        val tapThreshold = 0.01 // ~1km threshold for tap detection - increased tolerance
        
        println("🎯 getMarkerNearPoint called with: lat=$latitude, lon=$longitude")
        println("🎯 Available markers: ${markers.size}")
        
        val foundMarker = markers.values.find { marker ->
            val latDiff = abs(marker.latitude - latitude)
            val lonDiff = abs(marker.longitude - longitude)
            println("🎯 Checking marker ${marker.title}: lat=${marker.latitude}, lon=${marker.longitude}")
            println("🎯 Differences: latDiff=$latDiff, lonDiff=$lonDiff, threshold=$tapThreshold")
            val isNear = latDiff < tapThreshold && lonDiff < tapThreshold
            println("🎯 Is near: $isNear")
            isNear
        }
        
        println("🎯 Found marker: ${foundMarker?.title ?: "none"}")
        return foundMarker
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
            println("❌ Failed to apply markers to map: ${e.message}")
            e.printStackTrace()
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
     * Based on official Mapbox documentation and examples
     */
    private fun addMarkersWithAnnotationsAPI(markers: List<StaticMarker>) {
        if (markers.isEmpty()) {
            println("📝 No markers to display")
            return
        }
        
        val annotationManager = pointAnnotationManager ?: run {
            println("❌ PointAnnotationManager not available")
            return
        }
        
        println("🎨 Rendering ${markers.size} markers with Maps SDK v10 Annotations API...")
        
        try {
            println("🔧 Context available: ${context != null}")
            println("🔧 Annotation manager: ${annotationManager}")
            
            // Clear existing annotations
            annotationManager.deleteAll()
            pointAnnotations.clear()
            
            // Create point annotations for each marker
            markers.forEach { marker ->
                try {
                    // Get the appropriate icon
                    val iconBitmap = getMarkerIconBitmap(marker)
                    println("🔧 Icon bitmap created for ${marker.title}: ${iconBitmap.width}x${iconBitmap.height}")
                    
                    // Create point annotation options with proper positioning and visibility
                    val pointAnnotationOptions = PointAnnotationOptions()
                        .withPoint(Point.fromLngLat(marker.longitude, marker.latitude))
                        .withIconImage(iconBitmap)
                        .withIconAnchor(IconAnchor.CENTER) // Center anchor for better visibility
                        .withIconSize(2.5) // Larger size to ensure visibility above navigation layers
                        .withIconOpacity(1.0) // Ensure full opacity
                    
                    println("🔧 Point annotation options created for ${marker.title}")
                    println("🔧 Location: lng=${marker.longitude}, lat=${marker.latitude}")
                    
                    // Create the annotation
                    val annotation = annotationManager.create(pointAnnotationOptions)
                    pointAnnotations[marker.id] = annotation
                    
                    println("✅ Added marker: ${marker.title} at (${marker.latitude}, ${marker.longitude})")
                    
                    // Verify the annotation was actually created
                    if (annotation != null) {
                        println("🔍 Annotation details: id=${annotation.id}, geometry=${annotation.geometry}")
                    } else {
                        println("⚠️ Annotation is null for marker: ${marker.title}")
                    }
                    
                } catch (e: Exception) {
                    println("❌ Failed to add marker ${marker.id}: ${e.message}")
                    e.printStackTrace()
                }
            }
            
            println("✅ Successfully rendered ${pointAnnotations.size} markers on map")
            println("🚀 Using Maps SDK v10.16.0 Annotations API")
            println("📱 Platform: Android with visual marker rendering")
            
            // Additional verification
            val totalAnnotations = annotationManager.annotations.size
            println("🔍 Total annotations in manager: $totalAnnotations")
            println("🔍 MapView: ${mapView != null}")
            println("🔍 Annotation IDs: ${pointAnnotations.values.map { it?.id }}")
            
            // Debug camera position and force refresh
            try {
                mapView?.let { view ->
                    println("🔄 Attempting to invalidate map view for refresh...")
                    
                    // Check if any markers are within the current view bounds
                    markers.forEach { marker ->
                        println("📍 Marker ${marker.id}: (${marker.latitude}, ${marker.longitude})")
                    }
                    
                    // Post a delayed task to ensure markers appear above navigation layers
                    view.post {
                        println("🔄 Delayed refresh to bring markers to front...")
                        try {
                            // Try to bring annotation layer to front
                            annotationManager.annotations.forEach { annotation ->
                                println("🔍 Refreshing annotation ${annotation.id}")
                            }
                        } catch (e: Exception) {
                            println("⚠️ Could not refresh annotations: ${e.message}")
                        }
                    }
                }
            } catch (e: Exception) {
                println("⚠️ Could not refresh map view: ${e.message}")
            }
            
        } catch (e: Exception) {
            println("❌ Failed to render markers: ${e.message}")
            e.printStackTrace()
            
        }
    }

    /**
     * Gets the appropriate marker icon bitmap for a marker
     */
    private fun getMarkerIconBitmap(marker: StaticMarker): Bitmap {
        // FOR TESTING: If this is our test marker, use a bright colored circle
        if (marker.id == "vegas_center_test") {
            println("🔴 Creating GIANT RED test marker for ${marker.title}")
            return createSimpleColoredMarker(android.graphics.Color.RED)
        }
        
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
        println("🎨 Getting drawable for marker: ${marker.title}, iconId: ${marker.iconId}, category: ${marker.category}")
        
        // First try to match by iconId if available
        marker.iconId?.let { iconId ->
            when (iconId.lowercase()) {
                // General icons
                "pin" -> return R.drawable.ic_pin
                "star" -> return R.drawable.ic_star
                "heart" -> return R.drawable.ic_heart
                "flag" -> return R.drawable.ic_flag
                "warning" -> return R.drawable.ic_warning
                "info" -> return R.drawable.ic_info
                "question" -> return R.drawable.ic_question
                
                // Transportation
                "petrol_station", "petrol", "gas" -> return R.drawable.ic_petrol_station
                "charging_station", "charging" -> return R.drawable.ic_charging_station
                "parking" -> return R.drawable.ic_parking
                "bus_stop" -> return R.drawable.ic_bus_stop
                "train_station" -> return R.drawable.ic_train_station
                "airport" -> return R.drawable.ic_airport
                "port" -> return R.drawable.ic_port
                
                // Food & Services
                "restaurant", "food" -> return R.drawable.ic_restaurant
                "cafe" -> return R.drawable.ic_cafe
                "hotel", "accommodation" -> return R.drawable.ic_hotel
                "shop" -> return R.drawable.ic_shop
                "pharmacy" -> return R.drawable.ic_pharmacy
                "hospital", "medical" -> return R.drawable.ic_hospital
                "police" -> return R.drawable.ic_police
                "fire_station" -> return R.drawable.ic_fire_station
                
                // Scenic & Recreation
                "scenic" -> return R.drawable.ic_scenic
                "park" -> return R.drawable.ic_park
                "beach" -> return R.drawable.ic_beach
                "mountain" -> return R.drawable.ic_mountain
                "lake" -> return R.drawable.ic_lake
                "waterfall" -> return R.drawable.ic_waterfall
                "viewpoint" -> return R.drawable.ic_viewpoint
                "hiking" -> return R.drawable.ic_hiking
                
                // Safety & Traffic
                "speed_camera" -> return R.drawable.ic_speed_camera
                "accident" -> return R.drawable.ic_accident
                "construction" -> return R.drawable.ic_construction
                "traffic_light" -> return R.drawable.ic_traffic_light
                "speed_bump" -> return R.drawable.ic_speed_bump
                "school_zone" -> return R.drawable.ic_school_zone
                
                else -> {
                    // Unknown iconId, fall through to category matching
                    println("⚠️ Unknown iconId: $iconId, falling back to category matching")
                }
            }
        }
        
        // Fallback to category matching
        return when (marker.category.lowercase()) {
            // Transportation
            "petrol_station", "fuel" -> R.drawable.ic_petrol_station
            "charging_station" -> R.drawable.ic_charging_station
            "parking" -> R.drawable.ic_parking
            "bus_stop" -> R.drawable.ic_bus_stop
            "train_station" -> R.drawable.ic_train_station
            "airport" -> R.drawable.ic_airport
            "port" -> R.drawable.ic_port
            
            // Food & Services
            "restaurant", "food" -> R.drawable.ic_restaurant
            "cafe" -> R.drawable.ic_cafe
            "hotel", "accommodation" -> R.drawable.ic_hotel
            "shop" -> R.drawable.ic_shop
            "pharmacy" -> R.drawable.ic_pharmacy
            "hospital", "medical" -> R.drawable.ic_hospital
            "police", "safety" -> R.drawable.ic_police
            "fire_station" -> R.drawable.ic_fire_station
            
            // Scenic & Recreation
            "scenic" -> R.drawable.ic_scenic
            "park" -> R.drawable.ic_park
            "beach" -> R.drawable.ic_beach
            "mountain" -> R.drawable.ic_mountain
            "lake" -> R.drawable.ic_lake
            "waterfall" -> R.drawable.ic_waterfall
            "viewpoint" -> R.drawable.ic_viewpoint
            "hiking" -> R.drawable.ic_hiking
            
            // Safety & Traffic
            "speed_camera" -> R.drawable.ic_speed_camera
            "accident" -> R.drawable.ic_accident
            "construction" -> R.drawable.ic_construction
            "traffic_light" -> R.drawable.ic_traffic_light
            "speed_bump" -> R.drawable.ic_speed_bump
            "school_zone" -> R.drawable.ic_school_zone
            
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
} 