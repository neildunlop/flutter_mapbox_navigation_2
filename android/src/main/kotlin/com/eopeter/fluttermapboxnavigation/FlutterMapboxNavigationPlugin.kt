package com.eopeter.fluttermapboxnavigation

import android.Manifest
import android.app.Activity
import android.content.Context
import android.os.Handler
import android.os.Looper
import android.content.pm.PackageManager
import androidx.lifecycle.LifecycleOwner
import android.os.Build
import android.util.Log
import com.eopeter.fluttermapboxnavigation.activity.NavigationLauncher
import com.eopeter.fluttermapboxnavigation.activity.FlutterNavigationLauncher
import com.eopeter.fluttermapboxnavigation.factory.EmbeddedNavigationViewFactory
import com.eopeter.fluttermapboxnavigation.utilities.PluginUtilities
import com.eopeter.fluttermapboxnavigation.views.FlutterNavigationPlatformViewFactory
import com.eopeter.fluttermapboxnavigation.models.Waypoint
import com.eopeter.fluttermapboxnavigation.models.StaticMarker
import com.eopeter.fluttermapboxnavigation.models.MarkerConfiguration
import com.eopeter.fluttermapboxnavigation.models.TripProgressConfig
import com.mapbox.api.directions.v5.DirectionsCriteria
import com.mapbox.api.directions.v5.models.DirectionsRoute
import com.mapbox.common.TileRegion
import com.mapbox.common.TileRegionLoadOptions
import com.mapbox.common.TileRegionLoadProgress
import com.mapbox.common.TileStore
import com.mapbox.common.TileStoreOptions
import com.mapbox.geojson.Point
import com.mapbox.geojson.Polygon
import com.mapbox.maps.OfflineManager
import com.mapbox.maps.ResourceOptionsManager
import com.mapbox.maps.TilesetDescriptorOptions
import com.mapbox.maps.Style
import com.mapbox.navigation.base.options.NavigationOptions
import com.mapbox.navigation.base.options.RoutingTilesOptions
import com.mapbox.navigation.core.lifecycle.MapboxNavigationApp
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.platform.PlatformViewRegistry

/** FlutterMapboxNavigationPlugin */
class FlutterMapboxNavigationPlugin : FlutterPlugin, MethodCallHandler,
    EventChannel.StreamHandler, ActivityAware {

    private lateinit var channel: MethodChannel
    private lateinit var progressEventChannel: EventChannel
    private lateinit var markerEventChannel: EventChannel
    private var currentActivity: Activity? = null
    private lateinit var currentContext: Context
    private val markerManager = StaticMarkerManager.getInstance()

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        val messenger = binding.binaryMessenger
        channel = MethodChannel(messenger, "flutter_mapbox_navigation")
        channel.setMethodCallHandler(this)

        progressEventChannel = EventChannel(messenger, "flutter_mapbox_navigation/events")
        progressEventChannel.setStreamHandler(this)

        markerEventChannel = EventChannel(messenger, "flutter_mapbox_navigation/marker_events")
        markerEventChannel.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                markerManager.setEventSink(events)
            }

            override fun onCancel(arguments: Any?) {
                markerManager.setEventSink(null)
            }
        })

        platformViewRegistry = binding.platformViewRegistry
        binaryMessenger = messenger

        // Register the Flutter navigation platform view factory
        binding.platformViewRegistry.registerViewFactory(
            "flutter_mapbox_navigation_platform_view",
            FlutterNavigationPlatformViewFactory(messenger)
        )


    }

    companion object {

        var eventSink: EventChannel.EventSink? = null

        var PERMISSION_REQUEST_CODE: Int = 367

        lateinit var routes: List<DirectionsRoute>
        private var currentRoute: DirectionsRoute? = null
        val wayPoints: MutableList<Waypoint> = mutableListOf()

        var showAlternateRoutes: Boolean = true
        var longPressDestinationEnabled: Boolean = true
        var allowsUTurnsAtWayPoints: Boolean = false
        var enableOnMapTapCallback: Boolean = false
        var navigationMode = DirectionsCriteria.PROFILE_DRIVING_TRAFFIC
        var simulateRoute = false
        var enableFreeDriveMode = false
        var mapStyleUrlDay: String? = null
        var mapStyleUrlNight: String? = null
        var navigationLanguage = "en"
        /**
         * The voice units to use for navigation.
         * Note: Voice instruction units are locked at first initialization of the navigation session.
         * This means that while display units can be changed at runtime, voice instructions will
         * maintain the units they were initialized with. This is by design in the Mapbox SDK to
         * ensure consistent voice guidance throughout a navigation session.
         */
        var navigationVoiceUnits = DirectionsCriteria.METRIC
        var voiceInstructionsEnabled = true
        var bannerInstructionsEnabled = true
        var zoom = 15.0
        var bearing = 0.0
        var tilt = 0.0
        var distanceRemaining: Float? = null
        var durationRemaining: Double? = null
        var platformViewRegistry: PlatformViewRegistry? = null
        var binaryMessenger: BinaryMessenger? = null

        var viewId = "FlutterMapboxNavigationView"

        var enableFlutterStyleOverlays = false

        /**
         * Trip progress panel configuration passed from Dart.
         * Controls what UI elements to show and their styling.
         */
        var tripProgressConfig: TripProgressConfig = TripProgressConfig.defaults()

        /**
         * Converts string unit type to DirectionsCriteria constant.
         * Note: Voice instruction units are locked at first initialization of the navigation session.
         * This means that while display units can be changed at runtime, voice instructions will
         * maintain the units they were initialized with.
         */
        fun getUnitType(units: String?): String {
            return when (units?.lowercase()) {
                "imperial" -> DirectionsCriteria.IMPERIAL
                else -> DirectionsCriteria.METRIC
            }
        }
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "getPlatformVersion" -> {
                result.success("Android ${Build.VERSION.RELEASE}")
            }
            "getDistanceRemaining" -> {
                result.success(distanceRemaining)
            }
            "getDurationRemaining" -> {
                result.success(durationRemaining)
            }
            "startFreeDrive" -> {
                enableFreeDriveMode = true
                checkPermissionAndBeginNavigation(call)
            }
            "startNavigation" -> {
                enableFreeDriveMode = false
                enableFlutterStyleOverlays = false // Regular navigation uses standard UI
                checkPermissionAndBeginNavigation(call)
            }
            "startFlutterNavigation" -> {
                startFlutterStyledNavigation(call, result)
            }
            "addWayPoints" -> {
                addWayPointsToNavigation(call, result)
            }
            "finishNavigation" -> {
                NavigationLauncher.stopNavigation(currentActivity)
            }
            "enableOfflineRouting" -> {
                downloadRegionForOfflineRouting(call, result)
            }
            // Offline Routing Methods
            "downloadOfflineRegion" -> {
                downloadOfflineRegion(call, result)
            }
            "isOfflineRoutingAvailable" -> {
                isOfflineRoutingAvailable(call, result)
            }
            "deleteOfflineRegion" -> {
                deleteOfflineRegion(call, result)
            }
            "getOfflineCacheSize" -> {
                getOfflineCacheSize(result)
            }
            "clearOfflineCache" -> {
                clearOfflineCache(result)
            }
            "getOfflineRegionStatus" -> {
                getOfflineRegionStatus(call, result)
            }
            "listOfflineRegions" -> {
                listOfflineRegions(result)
            }
            "addStaticMarkers" -> {
                addStaticMarkers(call, result)
            }
            "removeStaticMarkers" -> {
                removeStaticMarkers(call, result)
            }
            "clearAllStaticMarkers" -> {
                clearAllStaticMarkers(result)
            }
            "updateMarkerConfiguration" -> {
                updateMarkerConfiguration(call, result)
            }
            "getStaticMarkers" -> {
                getStaticMarkers(result)
            }
            "getMarkerScreenPosition" -> {
                getMarkerScreenPosition(call, result)
            }
            "getMapViewport" -> {
                getMapViewport(result)
            }
            else -> result.notImplemented()
        }
    }

    @Deprecated("Use downloadOfflineRegion instead")
    private fun downloadRegionForOfflineRouting(
        call: MethodCall,
        result: Result
    ) {
        // Legacy stub - use downloadOfflineRegion instead
        result.success(false)
    }

    // MARK: - Offline Routing Methods

    private var tileStore: TileStore? = null

    // Offline tile storage configuration constants
    private object TileStoreConfig {
        // 1GB quota for offline tiles (maps + routing)
        const val TILE_STORE_QUOTA_BYTES = 1_073_741_824L
        // Cleanup threshold: start cleanup when above 80%
        const val CLEANUP_THRESHOLD_PERCENT = 0.80
        // Target after cleanup: reduce to 60%
        const val CLEANUP_TARGET_PERCENT = 0.60
        // Mapbox SDK limit for tiles per region
        const val MAX_TILES_PER_REGION = 750
        // Default max zoom for offline (lower = fewer tiles, 14 is good for navigation)
        const val DEFAULT_MAX_ZOOM_OFFLINE = 14
    }

    /**
     * Estimate the number of tiles for a region at given zoom levels.
     * Uses the standard Web Mercator tile calculation.
     */
    private fun estimateTileCount(
        southWestLat: Double,
        southWestLng: Double,
        northEastLat: Double,
        northEastLng: Double,
        minZoom: Int,
        maxZoom: Int
    ): Int {
        var total = 0
        for (z in minZoom..maxZoom) {
            val tilesPerDegree = (1 shl z) / 360.0
            val latTiles = kotlin.math.ceil((northEastLat - southWestLat) * tilesPerDegree).toInt()
            val lngTiles = kotlin.math.ceil((northEastLng - southWestLng) * tilesPerDegree).toInt()
            total += maxOf(1, latTiles) * maxOf(1, lngTiles)
        }
        return total
    }

    /**
     * Find the optimal max zoom level that keeps tile count under the limit.
     */
    private fun findOptimalMaxZoom(
        southWestLat: Double,
        southWestLng: Double,
        northEastLat: Double,
        northEastLng: Double,
        minZoom: Int,
        requestedMaxZoom: Int,
        maxTiles: Int = TileStoreConfig.MAX_TILES_PER_REGION
    ): Int {
        var optimalMaxZoom = requestedMaxZoom
        while (optimalMaxZoom > minZoom) {
            val tileCount = estimateTileCount(
                southWestLat, southWestLng,
                northEastLat, northEastLng,
                minZoom, optimalMaxZoom
            )
            if (tileCount <= maxTiles) {
                return optimalMaxZoom
            }
            optimalMaxZoom--
        }
        return minZoom // Fallback to minimum zoom only
    }

    private fun getTileStore(): TileStore {
        if (tileStore == null) {
            tileStore = TileStore.create().also { store ->
                // Set 1GB disk quota for offline tiles using Value wrapper
                try {
                    store.setOption(
                        TileStoreOptions.DISK_QUOTA,
                        com.mapbox.bindgen.Value.valueOf(TileStoreConfig.TILE_STORE_QUOTA_BYTES)
                    )
                    Log.d("OfflineRouting", "TileStore configured with ${TileStoreConfig.TILE_STORE_QUOTA_BYTES / (1024 * 1024)}MB quota")
                } catch (e: Exception) {
                    Log.w("OfflineRouting", "Could not set disk quota: ${e.message}")
                }
            }
        }
        return tileStore!!
    }

    private fun getMapboxAccessToken(): String {
        return try {
            PluginUtilities.getResourceFromContext(currentContext, "mapbox_access_token")
        } catch (e: Exception) {
            Log.w("OfflineRouting", "Could not get Mapbox access token: ${e.message}")
            ""
        }
    }

    private fun downloadOfflineRegion(call: MethodCall, result: Result) {
        try {
            val arguments = call.arguments as? Map<String, Any>
            val southWestLat = arguments?.get("southWestLat") as? Double
            val southWestLng = arguments?.get("southWestLng") as? Double
            val northEastLat = arguments?.get("northEastLat") as? Double
            val northEastLng = arguments?.get("northEastLng") as? Double
            val minZoom = (arguments?.get("minZoom") as? Int) ?: 10
            val maxZoom = (arguments?.get("maxZoom") as? Int) ?: 16
            val includeRoutingTiles = arguments?.get("includeRoutingTiles") as? Boolean ?: true

            if (southWestLat == null || southWestLng == null ||
                northEastLat == null || northEastLng == null) {
                result.error("INVALID_ARGUMENTS", "Region bounds are required", null)
                return
            }

            // Calculate optimal max zoom to stay under tile limit
            val requestedMaxZoom = minOf(maxZoom, TileStoreConfig.DEFAULT_MAX_ZOOM_OFFLINE)
            val optimalMaxZoom = findOptimalMaxZoom(
                southWestLat, southWestLng,
                northEastLat, northEastLng,
                minZoom, requestedMaxZoom
            )

            val estimatedTiles = estimateTileCount(
                southWestLat, southWestLng,
                northEastLat, northEastLng,
                minZoom, optimalMaxZoom
            )

            if (optimalMaxZoom < requestedMaxZoom) {
                Log.w("OfflineRouting", "Reduced max zoom from $requestedMaxZoom to $optimalMaxZoom to fit tile limit (estimated $estimatedTiles tiles)")
            }

            Log.d("OfflineRouting", "Starting download for region ($southWestLat,$southWestLng) to ($northEastLat,$northEastLng)")
            Log.d("OfflineRouting", "Zoom range: $minZoom-$optimalMaxZoom, estimated tiles: $estimatedTiles, includeRouting=$includeRoutingTiles")

            val store = getTileStore()

            // Create region ID based on bounds (include routing flag in ID)
            val routingSuffix = if (includeRoutingTiles) "_nav" else ""
            val regionId = "region_${(southWestLat * 1000).toInt()}_${(southWestLng * 1000).toInt()}_${(northEastLat * 1000).toInt()}_${(northEastLng * 1000).toInt()}$routingSuffix"

            // Define the bounding polygon
            val polygon = Polygon.fromLngLats(listOf(
                listOf(
                    Point.fromLngLat(southWestLng, southWestLat),
                    Point.fromLngLat(northEastLng, southWestLat),
                    Point.fromLngLat(northEastLng, northEastLat),
                    Point.fromLngLat(southWestLng, northEastLat),
                    Point.fromLngLat(southWestLng, southWestLat)
                )
            ))

            // Create tileset descriptors for map styles
            val resourceOptions = ResourceOptionsManager.getDefault(currentContext).resourceOptions
            val offlineManager = OfflineManager(resourceOptions)
            val descriptors = mutableListOf<com.mapbox.common.TilesetDescriptor>()

            // Map tiles (MAPBOX_STREETS for display) - use optimal zoom
            val mapDescriptor = offlineManager.createTilesetDescriptor(
                TilesetDescriptorOptions.Builder()
                    .styleURI(Style.MAPBOX_STREETS)
                    .minZoom(minZoom.toByte())
                    .maxZoom(optimalMaxZoom.toByte())
                    .build()
            )
            descriptors.add(mapDescriptor)
            Log.d("OfflineRouting", "Added map tileset descriptor (MAPBOX_STREETS)")

            // Navigation routing tiles (for offline turn-by-turn routing)
            // We need MapboxNavigationApp to be setup AND attached to get the routing tileset descriptor.
            // If not already setup, we initialize it here so routing tiles can be downloaded
            // before the user starts navigation.
            if (includeRoutingTiles) {
                try {
                    // Setup MapboxNavigationApp if not already setup
                    if (!MapboxNavigationApp.isSetup()) {
                        Log.d("OfflineRouting", "Setting up MapboxNavigationApp for routing tile download")

                        // Use the same TileStore for navigation so tiles are shared
                        val routingTilesOptions = RoutingTilesOptions.Builder()
                            .tileStore(store)
                            .build()

                        val navigationOptions = NavigationOptions.Builder(currentContext)
                            .accessToken(getMapboxAccessToken())
                            .routingTilesOptions(routingTilesOptions)
                            .build()

                        MapboxNavigationApp.setup(navigationOptions)
                        Log.d("OfflineRouting", "MapboxNavigationApp setup complete")
                    }

                    // Attach to activity lifecycle to get an active navigation instance
                    // This is required for MapboxNavigationApp.current() to return non-null
                    val activity = currentActivity
                    if (activity != null && activity is LifecycleOwner) {
                        if (MapboxNavigationApp.current() == null) {
                            MapboxNavigationApp.attach(activity)
                            Log.d("OfflineRouting", "Attached MapboxNavigationApp to activity lifecycle")
                        }
                    }

                    // Now get the routing tileset descriptor
                    val navApp = MapboxNavigationApp.current()
                    if (navApp != null) {
                        val navigationDescriptor = navApp.tilesetDescriptorFactory.getLatest()
                        descriptors.add(navigationDescriptor)
                        Log.d("OfflineRouting", "Added navigation routing tileset descriptor")
                    } else {
                        Log.w("OfflineRouting", "MapboxNavigationApp.current() returned null - routing tiles will not be downloaded")
                        Log.w("OfflineRouting", "Offline navigation may not work. Activity: $activity, isLifecycleOwner: ${activity is LifecycleOwner}")
                    }
                } catch (e: Exception) {
                    Log.w("OfflineRouting", "Could not add navigation tileset descriptor: ${e.message}")
                    e.printStackTrace()
                    // Continue with map tiles only
                }
            }

            // Create tile region load options
            val loadOptions = TileRegionLoadOptions.Builder()
                .geometry(polygon)
                .descriptors(descriptors)
                .acceptExpired(true)
                .build()

            // Start download
            store.loadTileRegion(
                regionId,
                loadOptions,
                { progress ->
                    val percentage = progress.completedResourceCount.toDouble() /
                        maxOf(progress.requiredResourceCount, 1).toDouble()
                    Log.d("OfflineRouting", "Download progress: ${(percentage * 100).toInt()}% (${progress.completedResourceCount}/${progress.requiredResourceCount})")

                    // Send progress to Flutter (must be on main thread)
                    val progressData = mapOf(
                        "regionId" to regionId,
                        "progress" to percentage,
                        "completedResources" to progress.completedResourceCount,
                        "requiredResources" to progress.requiredResourceCount
                    )
                    Handler(Looper.getMainLooper()).post {
                        eventSink?.success(mapOf(
                            "eventType" to "download_progress",
                            "data" to progressData
                        ))
                    }
                },
                { expected ->
                    if (expected.isValue) {
                        val region = expected.value
                        Log.d("OfflineRouting", "Download completed for region $regionId (${region?.completedResourceCount} resources)")

                        // Trigger auto-cleanup if needed, protecting current region
                        performAutoCleanupIfNeeded(listOf(regionId))

                        // Return success with region details
                        result.success(mapOf(
                            "success" to true,
                            "regionId" to regionId,
                            "resourceCount" to (region?.completedResourceCount ?: 0),
                            "includesRoutingTiles" to includeRoutingTiles
                        ))
                    } else {
                        val error = expected.error
                        Log.e("OfflineRouting", "Download failed: ${error?.message}")
                        result.error("DOWNLOAD_FAILED", error?.message ?: "Unknown error", null)
                    }
                }
            )
        } catch (e: Exception) {
            Log.e("OfflineRouting", "Error starting download: ${e.message}")
            result.error("DOWNLOAD_ERROR", e.message, null)
        }
    }

    private fun isOfflineRoutingAvailable(call: MethodCall, result: Result) {
        try {
            val arguments = call.arguments as? Map<String, Any>
            val latitude = arguments?.get("latitude") as? Double
            val longitude = arguments?.get("longitude") as? Double

            if (latitude == null || longitude == null) {
                result.error("INVALID_ARGUMENTS", "Latitude and longitude are required", null)
                return
            }

            val store = getTileStore()

            store.getAllTileRegions { expected ->
                if (expected.isValue) {
                    val regions = expected.value ?: emptyList()
                    // Simple check: if there are any cached regions, consider offline available
                    // A more accurate implementation would check if the coordinate falls within a region
                    result.success(regions.isNotEmpty())
                } else {
                    Log.e("OfflineRouting", "Error checking offline availability: ${expected.error?.message}")
                    result.success(false)
                }
            }
        } catch (e: Exception) {
            Log.e("OfflineRouting", "Error checking offline availability: ${e.message}")
            result.success(false)
        }
    }

    private fun deleteOfflineRegion(call: MethodCall, result: Result) {
        try {
            val arguments = call.arguments as? Map<String, Any>
            val southWestLat = arguments?.get("southWestLat") as? Double
            val southWestLng = arguments?.get("southWestLng") as? Double
            val northEastLat = arguments?.get("northEastLat") as? Double
            val northEastLng = arguments?.get("northEastLng") as? Double

            if (southWestLat == null || southWestLng == null ||
                northEastLat == null || northEastLng == null) {
                result.error("INVALID_ARGUMENTS", "Region bounds are required", null)
                return
            }

            val store = getTileStore()
            val regionId = "region_${(southWestLat * 1000).toInt()}_${(southWestLng * 1000).toInt()}_${(northEastLat * 1000).toInt()}_${(northEastLng * 1000).toInt()}"

            store.removeTileRegion(regionId) { expected ->
                if (expected.isValue) {
                    Log.d("OfflineRouting", "Region $regionId deleted successfully")
                    result.success(true)
                } else {
                    Log.e("OfflineRouting", "Failed to delete region: ${expected.error?.message}")
                    result.error("DELETE_FAILED", expected.error?.message, null)
                }
            }
        } catch (e: Exception) {
            Log.e("OfflineRouting", "Error deleting region: ${e.message}")
            result.error("DELETE_ERROR", e.message, null)
        }
    }

    private fun getOfflineCacheSize(result: Result) {
        try {
            val store = getTileStore()

            store.getAllTileRegions { expected ->
                if (expected.isValue) {
                    val regions = expected.value ?: emptyList()
                    // Estimate size based on completed resources (~50KB per tile average)
                    val estimatedSize = regions.sumOf { region ->
                        region.completedResourceCount * 50 * 1024L
                    }
                    result.success(estimatedSize.toInt())
                } else {
                    Log.e("OfflineRouting", "Error getting cache size: ${expected.error?.message}")
                    result.success(0)
                }
            }
        } catch (e: Exception) {
            Log.e("OfflineRouting", "Error getting cache size: ${e.message}")
            result.success(0)
        }
    }

    private fun clearOfflineCache(result: Result) {
        try {
            val store = getTileStore()

            store.getAllTileRegions { expected ->
                if (expected.isValue) {
                    val regions = expected.value ?: emptyList()
                    if (regions.isEmpty()) {
                        result.success(true)
                        return@getAllTileRegions
                    }

                    var remaining = regions.size
                    var allSuccessful = true

                    for (region in regions) {
                        store.removeTileRegion(region.id) { deleteExpected ->
                            if (deleteExpected.isError) {
                                Log.e("OfflineRouting", "Failed to delete region ${region.id}: ${deleteExpected.error?.message}")
                                allSuccessful = false
                            }

                            remaining--
                            if (remaining == 0) {
                                Log.d("OfflineRouting", "Cache cleared, success: $allSuccessful")
                                result.success(allSuccessful)
                            }
                        }
                    }
                } else {
                    Log.e("OfflineRouting", "Error clearing cache: ${expected.error?.message}")
                    result.error("CLEAR_FAILED", expected.error?.message, null)
                }
            }
        } catch (e: Exception) {
            Log.e("OfflineRouting", "Error clearing cache: ${e.message}")
            result.error("CLEAR_ERROR", e.message, null)
        }
    }

    /**
     * Get the status of a specific offline region.
     * Returns details about map tiles, routing tiles readiness, and size.
     */
    private fun getOfflineRegionStatus(call: MethodCall, result: Result) {
        try {
            val arguments = call.arguments as? Map<String, Any>
            val regionId = arguments?.get("regionId") as? String

            if (regionId == null) {
                result.error("INVALID_ARGUMENTS", "Region ID is required", null)
                return
            }

            val store = getTileStore()

            store.getAllTileRegions { expected ->
                if (expected.isValue) {
                    val regions = expected.value ?: emptyList()
                    val region = regions.find { it.id == regionId }

                    if (region != null) {
                        // Check if this region includes routing tiles (ID ends with _nav)
                        val includesRouting = region.id.endsWith("_nav")

                        // Estimate size (~50KB per tile average, routing tiles ~30% extra)
                        val estimatedSizeBytes = region.completedResourceCount * 50 * 1024L

                        result.success(mapOf(
                            "regionId" to region.id,
                            "exists" to true,
                            "completedResourceCount" to region.completedResourceCount,
                            "requiredResourceCount" to region.requiredResourceCount,
                            "mapTilesReady" to true,
                            "routingTilesReady" to includesRouting,
                            "estimatedSizeBytes" to estimatedSizeBytes,
                            "isComplete" to (region.completedResourceCount >= region.requiredResourceCount)
                        ))
                    } else {
                        result.success(mapOf(
                            "regionId" to regionId,
                            "exists" to false,
                            "mapTilesReady" to false,
                            "routingTilesReady" to false
                        ))
                    }
                } else {
                    Log.e("OfflineRouting", "Error getting region status: ${expected.error?.message}")
                    result.error("STATUS_FAILED", expected.error?.message, null)
                }
            }
        } catch (e: Exception) {
            Log.e("OfflineRouting", "Error getting region status: ${e.message}")
            result.error("STATUS_ERROR", e.message, null)
        }
    }

    /**
     * List all offline regions with their status.
     */
    private fun listOfflineRegions(result: Result) {
        try {
            val store = getTileStore()

            store.getAllTileRegions { expected ->
                if (expected.isValue) {
                    val regions = expected.value ?: emptyList()
                    val regionsList = regions.map { region ->
                        val includesRouting = region.id.endsWith("_nav")
                        val estimatedSizeBytes = region.completedResourceCount * 50 * 1024L

                        mapOf(
                            "regionId" to region.id,
                            "completedResourceCount" to region.completedResourceCount,
                            "requiredResourceCount" to region.requiredResourceCount,
                            "mapTilesReady" to true,
                            "routingTilesReady" to includesRouting,
                            "estimatedSizeBytes" to estimatedSizeBytes,
                            "isComplete" to (region.completedResourceCount >= region.requiredResourceCount)
                        )
                    }

                    result.success(mapOf(
                        "regions" to regionsList,
                        "totalCount" to regions.size,
                        "totalSizeBytes" to regionsList.sumOf { (it["estimatedSizeBytes"] as Long) }
                    ))
                } else {
                    Log.e("OfflineRouting", "Error listing regions: ${expected.error?.message}")
                    result.error("LIST_FAILED", expected.error?.message, null)
                }
            }
        } catch (e: Exception) {
            Log.e("OfflineRouting", "Error listing regions: ${e.message}")
            result.error("LIST_ERROR", e.message, null)
        }
    }

    /**
     * Performs automatic cleanup of old offline regions when storage exceeds threshold.
     * Called internally after successful downloads or when storage is queried.
     * Protects current trip regions from deletion.
     *
     * @param protectedRegionIds List of region IDs that should not be deleted (current trip)
     */
    private fun performAutoCleanupIfNeeded(protectedRegionIds: List<String> = emptyList()) {
        try {
            val store = getTileStore()

            store.getAllTileRegions { expected ->
                if (expected.isValue) {
                    val regions = expected.value ?: emptyList()

                    // Calculate total size
                    val totalSizeBytes = regions.sumOf { it.completedResourceCount * 50 * 1024L }
                    val thresholdBytes = (TileStoreConfig.TILE_STORE_QUOTA_BYTES * TileStoreConfig.CLEANUP_THRESHOLD_PERCENT).toLong()
                    val targetBytes = (TileStoreConfig.TILE_STORE_QUOTA_BYTES * TileStoreConfig.CLEANUP_TARGET_PERCENT).toLong()

                    if (totalSizeBytes > thresholdBytes) {
                        Log.d("OfflineRouting", "Storage cleanup triggered: ${totalSizeBytes / (1024 * 1024)}MB > ${thresholdBytes / (1024 * 1024)}MB threshold")

                        // Sort regions by ID (older regions likely have smaller IDs)
                        // In a real implementation, we'd use creation timestamps
                        val sortedRegions = regions
                            .filter { !protectedRegionIds.contains(it.id) }
                            .sortedBy { it.id }

                        var currentSize = totalSizeBytes
                        val regionsToDelete = mutableListOf<TileRegion>()

                        for (region in sortedRegions) {
                            if (currentSize <= targetBytes) break
                            val regionSize = region.completedResourceCount * 50 * 1024L
                            regionsToDelete.add(region)
                            currentSize -= regionSize
                        }

                        Log.d("OfflineRouting", "Cleaning up ${regionsToDelete.size} old regions to free space")

                        for (region in regionsToDelete) {
                            store.removeTileRegion(region.id) { deleteExpected ->
                                if (deleteExpected.isValue) {
                                    Log.d("OfflineRouting", "Auto-deleted old region: ${region.id}")
                                } else {
                                    Log.w("OfflineRouting", "Failed to auto-delete region ${region.id}: ${deleteExpected.error?.message}")
                                }
                            }
                        }
                    }
                }
            }
        } catch (e: Exception) {
            Log.e("OfflineRouting", "Error during auto-cleanup: ${e.message}")
        }
    }

    private fun checkPermissionAndBeginNavigation(
        call: MethodCall
    ) {
        val arguments = call.arguments as? Map<String, Any>

        val navMode = arguments?.get("mode") as? String
        if (navMode != null) {
            when (navMode) {
                "walking" -> navigationMode = DirectionsCriteria.PROFILE_WALKING
                "cycling" -> navigationMode = DirectionsCriteria.PROFILE_CYCLING
                "driving" -> navigationMode = DirectionsCriteria.PROFILE_DRIVING
            }
        }

        val alternateRoutes = arguments?.get("alternatives") as? Boolean
        if (alternateRoutes != null) {
            showAlternateRoutes = alternateRoutes
        }

        val simulated = arguments?.get("simulateRoute") as? Boolean
        if (simulated != null) {
            simulateRoute = simulated
        }

        val allowsUTurns = arguments?.get("allowsUTurnsAtWayPoints") as? Boolean
        if (allowsUTurns != null) {
            allowsUTurnsAtWayPoints = allowsUTurns
        }

        val onMapTap = arguments?.get("enableOnMapTapCallback") as? Boolean
        if (onMapTap != null) {
            enableOnMapTapCallback = onMapTap
        }

        val language = arguments?.get("language") as? String
        if (language != null) {
            navigationLanguage = language
        }

        val voiceEnabled = arguments?.get("voiceInstructionsEnabled") as? Boolean
        if (voiceEnabled != null) {
            voiceInstructionsEnabled = voiceEnabled
        }

        val bannerEnabled = arguments?.get("bannerInstructionsEnabled") as? Boolean
        if (bannerEnabled != null) {
            bannerInstructionsEnabled = bannerEnabled
        }

        val units = arguments?.get("units") as? String
        if (units != null) {
            navigationVoiceUnits = getUnitType(units)
        }

        mapStyleUrlDay = arguments?.get("mapStyleUrlDay") as? String
        mapStyleUrlNight = arguments?.get("mapStyleUrlNight") as? String

        val longPress = arguments?.get("longPressDestinationEnabled") as? Boolean
        if (longPress != null) {
            longPressDestinationEnabled = longPress
        }

        // Parse trip progress configuration
        @Suppress("UNCHECKED_CAST")
        val tripProgressConfigMap = arguments?.get("tripProgressConfig") as? Map<String, Any>
        tripProgressConfig = TripProgressConfig.fromMap(tripProgressConfigMap)
        Log.d("FlutterMapboxNav", "🎨 Parsed tripProgressConfig: backgroundColor=${String.format("#%08X", tripProgressConfig.theme.backgroundColor)}, primaryColor=${String.format("#%08X", tripProgressConfig.theme.primaryColor)}")

        wayPoints.clear()

        if (enableFreeDriveMode) {
            checkPermissionAndBeginNavigation(wayPoints)
            return
        }

        val points = arguments?.get("wayPoints") as HashMap<Int, Any>
        for (item in points) {
            val point = item.value as HashMap<*, *>
            val name = point["Name"] as String
            val latitude = point["Latitude"] as Double
            val longitude = point["Longitude"] as Double
            val isSilent = point["IsSilent"] as Boolean
            wayPoints.add(Waypoint(name, longitude, latitude, isSilent))
        }
        checkPermissionAndBeginNavigation(wayPoints)
    }

    private fun checkPermissionAndBeginNavigation(wayPoints: List<Waypoint>) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val haspermission =
                currentActivity?.checkSelfPermission(Manifest.permission.ACCESS_FINE_LOCATION)
            if (haspermission != PackageManager.PERMISSION_GRANTED) {
                //_activity.onRequestPermissionsResult((a,b,c) => onRequestPermissionsResult)
                currentActivity?.requestPermissions(
                    arrayOf(Manifest.permission.ACCESS_FINE_LOCATION),
                    PERMISSION_REQUEST_CODE
                )
                beginNavigation(wayPoints)
            } else
                beginNavigation(wayPoints)
        } else
            beginNavigation(wayPoints)
    }

    private fun beginNavigation(wayPoints: List<Waypoint>) {
        NavigationLauncher.startNavigation(currentActivity, wayPoints)
    }

    private fun addWayPointsToNavigation(
        call: MethodCall,
        result: Result
    ) {
        try {
            val arguments = call.arguments as? Map<String, Any>
            val points = arguments?.get("wayPoints") as HashMap<Int, Any>
            val waypoints = mutableListOf<Waypoint>()

            for (item in points) {
                val point = item.value as HashMap<*, *>
                val name = point["Name"] as String
                val latitude = point["Latitude"] as Double
                val longitude = point["Longitude"] as Double
                val isSilent = point["IsSilent"] as Boolean
                waypoints.add(Waypoint(name, latitude, longitude, isSilent))
            }
            NavigationLauncher.addWayPoints(currentActivity, waypoints)
            result.success(mapOf(
                "success" to true,
                "waypointsAdded" to waypoints.size
            ))
        } catch (e: Exception) {
            result.success(mapOf(
                "success" to false,
                "waypointsAdded" to 0,
                "errorMessage" to e.message
            ))
        }
    }

    override fun onListen(args: Any?, events: EventChannel.EventSink?) {
        eventSink = events
    }

    override fun onCancel(args: Any?) {
        eventSink = null
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        currentActivity = null
        channel.setMethodCallHandler(null)
        progressEventChannel.setStreamHandler(null)
    }

    override fun onDetachedFromActivity() {
        currentActivity!!.finish()
        currentActivity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        currentActivity = binding.activity
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        currentActivity = binding.activity
        currentContext = binding.activity.applicationContext
        markerManager.setContext(currentContext)
        if (platformViewRegistry != null && binaryMessenger != null && currentActivity != null) {
            platformViewRegistry?.registerViewFactory(
                viewId,
                EmbeddedNavigationViewFactory(binaryMessenger!!, currentActivity!!)
            )
        }
    }

    override fun onDetachedFromActivityForConfigChanges() {
        // To change body of created functions use File | Settings | File Templates.
    }

    fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        when (requestCode) {
            367 -> {
                for (permission in permissions) {
                    if (permission == Manifest.permission.ACCESS_FINE_LOCATION) {
                        val haspermission = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                            currentActivity?.checkSelfPermission(Manifest.permission.ACCESS_FINE_LOCATION)
                        } else {
                            TODO("VERSION.SDK_INT < M")
                        }
                        if (haspermission == PackageManager.PERMISSION_GRANTED) {
                            if (wayPoints.isNotEmpty())
                                beginNavigation(wayPoints)
                        }
                        // Not all permissions granted. Show some message and return.
                        return
                    }
                }

                // All permissions are granted. Do the work accordingly.
            }
        }
        // super.onRequestPermissionsResult(requestCode, permissions, grantResults)
    }

    // MARK: Static Marker Methods

    private fun addStaticMarkers(call: MethodCall, result: Result) {
        try {
            val arguments = call.arguments as? Map<String, Any>
            val markersList = arguments?.get("markers") as? List<Map<String, Any>>
            val configJson = arguments?.get("configuration") as? Map<String, Any>

            if (markersList == null) {
                result.error("INVALID_ARGUMENTS", "Markers list is required", null)
                return
            }

            val markers = markersList.map { markerJson ->
                StaticMarker.fromJson(markerJson)
            }

            val config = MarkerConfiguration.fromJson(configJson)
            val success = markerManager.addStaticMarkers(markers, config)

            result.success(success)
        } catch (e: Exception) {
            result.error("ADD_MARKERS_ERROR", "Failed to add static markers: ${e.message}", null)
        }
    }

    private fun removeStaticMarkers(call: MethodCall, result: Result) {
        try {
            val arguments = call.arguments as? Map<String, Any>
            val markerIds = arguments?.get("markerIds") as? List<String>

            if (markerIds == null) {
                result.error("INVALID_ARGUMENTS", "Marker IDs list is required", null)
                return
            }

            val success = markerManager.removeStaticMarkers(markerIds)
            result.success(success)
        } catch (e: Exception) {
            result.error("REMOVE_MARKERS_ERROR", "Failed to remove static markers: ${e.message}", null)
        }
    }

    private fun clearAllStaticMarkers(result: Result) {
        try {
            val success = markerManager.clearAllStaticMarkers()
            result.success(success)
        } catch (e: Exception) {
            result.error("CLEAR_MARKERS_ERROR", "Failed to clear static markers: ${e.message}", null)
        }
    }

    private fun updateMarkerConfiguration(call: MethodCall, result: Result) {
        try {
            val arguments = call.arguments as? Map<String, Any>
            val configJson = arguments?.get("configuration") as? Map<String, Any>

            if (configJson == null) {
                result.error("INVALID_ARGUMENTS", "Configuration is required", null)
                return
            }

            val config = MarkerConfiguration.fromJson(configJson)
            val success = markerManager.updateMarkerConfiguration(config)

            result.success(success)
        } catch (e: Exception) {
            result.error("UPDATE_CONFIG_ERROR", "Failed to update marker configuration: ${e.message}", null)
        }
    }

    private fun getStaticMarkers(result: Result) {
        try {
            val markers = markerManager.getStaticMarkers()
            val markersJson = markers.map { it.toJson() }
            result.success(markersJson)
        } catch (e: Exception) {
            result.error("GET_MARKERS_ERROR", "Failed to get static markers: ${e.message}", null)
        }
    }

    private fun getMarkerScreenPosition(call: MethodCall, result: Result) {
        try {
            val arguments = call.arguments as? Map<String, Any>
            val latitude = arguments?.get("latitude") as? Double
            val longitude = arguments?.get("longitude") as? Double

            if (latitude == null || longitude == null) {
                result.error("INVALID_ARGUMENTS", "Latitude and longitude are required", null)
                return
            }

            val screenPosition = markerManager.getScreenPosition(latitude, longitude)
            if (screenPosition != null) {
                result.success(mapOf(
                    "x" to screenPosition.first,
                    "y" to screenPosition.second
                ))
            } else {
                result.error("POSITION_ERROR", "Could not convert coordinates to screen position", null)
            }
        } catch (e: Exception) {
            result.error("SCREEN_POSITION_ERROR", "Failed to get marker screen position: ${e.message}", null)
        }
    }

    private fun getMapViewport(result: Result) {
        try {
            val viewport = markerManager.getMapViewport()
            if (viewport != null) {
                result.success(viewport)
            } else {
                result.error("VIEWPORT_ERROR", "Map viewport not available", null)
            }
        } catch (e: Exception) {
            result.error("VIEWPORT_ERROR", "Failed to get map viewport: ${e.message}", null)
        }
    }

    private fun startFlutterStyledNavigation(call: MethodCall, result: Result) {
        try {
            val arguments = call.arguments as? Map<String, Any>

            // Parse waypoints
            val points = arguments?.get("wayPoints") as? HashMap<Int, Any> ?: run {
                result.error("INVALID_ARGUMENTS", "wayPoints is required", null)
                return
            }

            val waypoints = mutableListOf<Waypoint>()
            for (item in points) {
                val point = item.value as HashMap<*, *>
                val name = point["Name"] as String
                val latitude = point["Latitude"] as Double
                val longitude = point["Longitude"] as Double
                val isSilent = point["IsSilent"] as Boolean
                waypoints.add(Waypoint(name, longitude, latitude, isSilent))
            }

            // Apply options to plugin static variables (same as checkPermissionAndBeginNavigation)
            val navMode = arguments?.get("mode") as? String
            if (navMode != null) {
                when (navMode) {
                    "walking" -> navigationMode = DirectionsCriteria.PROFILE_WALKING
                    "cycling" -> navigationMode = DirectionsCriteria.PROFILE_CYCLING
                    "driving" -> navigationMode = DirectionsCriteria.PROFILE_DRIVING
                }
            }

            val alternateRoutes = arguments?.get("alternatives") as? Boolean
            if (alternateRoutes != null) {
                showAlternateRoutes = alternateRoutes
            }

            val simulated = arguments?.get("simulateRoute") as? Boolean
            if (simulated != null) {
                simulateRoute = simulated
            }

            val allowsUTurns = arguments?.get("allowsUTurnAtWayPoints") as? Boolean
            if (allowsUTurns != null) {
                allowsUTurnsAtWayPoints = allowsUTurns
            }

            val onMapTap = arguments?.get("enableOnMapTapCallback") as? Boolean
            if (onMapTap != null) {
                enableOnMapTapCallback = onMapTap
            }

            val language = arguments?.get("language") as? String
            if (language != null) {
                navigationLanguage = language
            }

            val voiceEnabled = arguments?.get("voiceInstructionsEnabled") as? Boolean
            if (voiceEnabled != null) {
                voiceInstructionsEnabled = voiceEnabled
            }

            val bannerEnabled = arguments?.get("bannerInstructionsEnabled") as? Boolean
            if (bannerEnabled != null) {
                bannerInstructionsEnabled = bannerEnabled
            }

            val units = arguments?.get("units") as? String
            if (units != null) {
                navigationVoiceUnits = getUnitType(units)
            }

            mapStyleUrlDay = arguments?.get("mapStyleUrlDay") as? String
            mapStyleUrlNight = arguments?.get("mapStyleUrlNight") as? String

            val longPress = arguments?.get("longPressDestinationEnabled") as? Boolean
            if (longPress != null) {
                longPressDestinationEnabled = longPress
            }

            // Parse trip progress configuration (CRITICAL for theming)
            @Suppress("UNCHECKED_CAST")
            val tripProgressConfigMap = arguments?.get("tripProgressConfig") as? Map<String, Any>
            Log.d("FlutterMapboxNav", "🎨 startFlutterNavigation: tripProgressConfigMap keys=${tripProgressConfigMap?.keys}")
            Log.d("FlutterMapboxNav", "🎨 startFlutterNavigation: tripProgressConfigMap theme=${tripProgressConfigMap?.get("theme")}")
            tripProgressConfig = TripProgressConfig.fromMap(tripProgressConfigMap)
            Log.d("FlutterMapboxNav", "🎨 startFlutterNavigation: Parsed config - backgroundColor=${String.format("#%08X", tripProgressConfig.theme.backgroundColor)}, primaryColor=${String.format("#%08X", tripProgressConfig.theme.primaryColor)}, textPrimaryColor=${String.format("#%08X", tripProgressConfig.theme.textPrimaryColor)}")

            // Parse debug flag
            val showDebug = arguments?.get("showDebugOverlay") as? Boolean ?: false

            // Set a flag to enable Flutter-style overlays in NavigationActivity
            println("FlutterMapboxNavigationPlugin: Setting enableFlutterStyleOverlays = true")
            enableFlutterStyleOverlays = true
            println("FlutterMapboxNavigationPlugin: Flag set, enableFlutterStyleOverlays = $enableFlutterStyleOverlays")

            // Launch NavigationActivity with Flutter overlay customizations
            println("FlutterMapboxNavigationPlugin: Launching NavigationActivity with waypoints: ${waypoints.size}")
            NavigationLauncher.startNavigation(currentActivity, waypoints)

            result.success(true)

        } catch (e: Exception) {
            result.error("FLUTTER_NAVIGATION_ERROR", "Failed to start Flutter navigation: ${e.message}", null)
        }
    }
}

private const val MAPBOX_ACCESS_TOKEN_PLACEHOLDER = "YOUR_MAPBOX_ACCESS_TOKEN_GOES_HERE"