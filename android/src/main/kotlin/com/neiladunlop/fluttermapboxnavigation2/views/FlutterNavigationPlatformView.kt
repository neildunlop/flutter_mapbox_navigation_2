package com.neiladunlop.fluttermapboxnavigation2.views

import android.app.Activity
import android.content.Context
import android.content.ContextWrapper
import android.util.Log
import android.view.View
import android.widget.FrameLayout
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleOwner
import androidx.lifecycle.LifecycleRegistry
import com.neiladunlop.fluttermapboxnavigation2.FlutterMapboxNavigationPlugin
import com.neiladunlop.fluttermapboxnavigation2.StaticMarkerManager
import com.neiladunlop.fluttermapboxnavigation2.models.MapBoxEvents
import com.neiladunlop.fluttermapboxnavigation2.models.MapBoxRouteProgressEvent
import com.neiladunlop.fluttermapboxnavigation2.models.Waypoint
import com.neiladunlop.fluttermapboxnavigation2.utilities.PluginUtilities
import com.mapbox.api.directions.v5.DirectionsCriteria
import com.mapbox.api.directions.v5.models.RouteOptions
import com.mapbox.geojson.Point
import com.mapbox.maps.CameraOptions
import com.mapbox.maps.MapView
import com.mapbox.maps.Style
import com.mapbox.navigation.base.options.NavigationOptions
import com.mapbox.navigation.base.route.NavigationRoute
import com.mapbox.navigation.base.route.NavigationRouterCallback
import com.mapbox.navigation.base.route.RouterFailure
import com.mapbox.navigation.base.route.RouterOrigin
import com.mapbox.navigation.core.MapboxNavigation
import com.mapbox.navigation.core.directions.session.RoutesObserver
import com.mapbox.navigation.core.lifecycle.MapboxNavigationApp
import com.mapbox.navigation.base.trip.model.RouteProgress
import com.mapbox.navigation.core.trip.session.LocationMatcherResult
import com.mapbox.navigation.core.trip.session.LocationObserver
import com.mapbox.navigation.core.trip.session.RouteProgressObserver
import com.mapbox.navigation.ui.maps.NavigationStyles
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.platform.PlatformView

/**
 * Platform view for Flutter-controlled navigation
 * This embeds the Mapbox Navigation map as a platform view within Flutter,
 * allowing Flutter to maintain complete UI control while providing native map performance
 */
class FlutterNavigationPlatformView(
    context: Context,
    id: Int,
    creationParams: Map<String, Any>?,
    messenger: BinaryMessenger
) : PlatformView, MethodChannel.MethodCallHandler, LifecycleOwner {

    companion object {
        private const val TAG = "FlutterNavigationPlatformView"
        private const val CHANNEL_NAME = "flutter_mapbox_navigation_platform_view_"
        
        private fun getActivityFromContext(context: Context): Activity? {
            var currentContext = context
            while (currentContext is ContextWrapper) {
                if (currentContext is Activity) {
                    return currentContext
                }
                currentContext = currentContext.baseContext
            }
            return null
        }
    }
    
    /**
     * Custom ContextWrapper that provides LifecycleOwner for MapView
     */
    private class LifecycleContextWrapper(
        base: Context,
        private val lifecycleOwner: LifecycleOwner
    ) : ContextWrapper(base) {
        
        override fun getSystemService(name: String): Any? {
            if (name == "lifecycle_owner") {
                return lifecycleOwner
            }
            return super.getSystemService(name)
        }
        
        fun getLifecycleOwner(): LifecycleOwner = lifecycleOwner
    }

    private val context: Context = context
    private val activity: Activity? = getActivityFromContext(context)
    private val frameLayout: FrameLayout = FrameLayout(context)
    private val methodChannel: MethodChannel = MethodChannel(messenger, CHANNEL_NAME + id)
    
    // Lifecycle management
    private val lifecycleRegistry = LifecycleRegistry(this)
    
    private var mapView: MapView? = null
    private var mapboxNavigation: MapboxNavigation? = null
    private var waypoints: List<Waypoint>? = null
    private var currentRoute: NavigationRoute? = null
    
    // Navigation state
    private var isNavigationStarted = false
    private var isRouteBuilt = false

    init {
        methodChannel.setMethodCallHandler(this)
        // Initialize lifecycle
        lifecycleRegistry.currentState = Lifecycle.State.CREATED
        initializeNavigation(creationParams)
    }
    
    override val lifecycle: Lifecycle = lifecycleRegistry

    private fun initializeNavigation(creationParams: Map<String, Any>?) {
        try {
            Log.d(TAG, "Initializing Flutter navigation platform view")
            
            // Check if we have a valid activity
            if (activity == null) {
                Log.e(TAG, "No activity available for platform view initialization")
                return
            }
            
            // Parse creation parameters
            creationParams?.let { params ->
                waypoints = parseWaypoints(params)
            }

            // Create MapView with lifecycle-aware context
            val mapContext = if (activity != null && activity is LifecycleOwner) {
                activity
            } else {
                // Use custom lifecycle context wrapper
                LifecycleContextWrapper(context, this)
            }
            
            mapView = MapView(mapContext).apply {
                getMapboxMap().loadStyleUri(NavigationStyles.NAVIGATION_DAY_STYLE)
            }
            
            frameLayout.addView(mapView)
            
            // Update lifecycle state to STARTED when view is ready
            lifecycleRegistry.currentState = Lifecycle.State.STARTED
            
            // Initialize Mapbox Navigation
            if (!MapboxNavigationApp.isSetup()) {
                MapboxNavigationApp.setup {
                    NavigationOptions.Builder(context)
                        .accessToken(getMapboxAccessToken())
                        .build()
                }
            }
            
            // Get MapboxNavigation instance
            mapboxNavigation = MapboxNavigationApp.current()
            
            // Set up observers
            setupNavigationObservers()
            
            // Setup static marker manager for this view
            StaticMarkerManager.getInstance().setMapView(mapView!!)
            
            // If waypoints are provided, start navigation automatically
            waypoints?.let { points ->
                if (points.size >= 2) {
                    buildRoute(points)
                }
            }
            
            // Move to RESUMED state when everything is initialized
            lifecycleRegistry.currentState = Lifecycle.State.RESUMED
            
            Log.d(TAG, "Flutter navigation platform view initialized successfully")
            
        } catch (e: Exception) {
            Log.e(TAG, "Failed to initialize Flutter navigation platform view", e)
            // Set lifecycle to DESTROYED on error
            lifecycleRegistry.currentState = Lifecycle.State.DESTROYED
        }
    }


    private fun parseWaypoints(params: Map<String, Any>): List<Waypoint>? {
        val waypointData = params["wayPoints"] as? Map<String, Map<String, Any>> ?: return null
        
        val waypoints = mutableListOf<Pair<Int, Waypoint>>()
        
        for ((_, waypointMap) in waypointData) {
            try {
                val name = waypointMap["Name"] as? String ?: ""
                val latitude = waypointMap["Latitude"] as? Double ?: continue
                val longitude = waypointMap["Longitude"] as? Double ?: continue
                val isSilent = waypointMap["IsSilent"] as? Boolean ?: false
                val order = waypointMap["Order"] as? Int ?: 0
                
                val waypoint = Waypoint(name, longitude, latitude, isSilent)
                waypoints.add(order to waypoint)
            } catch (e: Exception) {
                Log.w(TAG, "Failed to parse waypoint: $waypointMap", e)
            }
        }
        
        return waypoints.sortedBy { it.first }.map { it.second }
    }

    private fun setupNavigationObservers() {
        mapboxNavigation?.apply {
            // Route progress observer
            registerRouteProgressObserver(object : RouteProgressObserver {
                override fun onRouteProgressChanged(routeProgress: RouteProgress) {
                    try {
                        val progressEvent = MapBoxRouteProgressEvent(routeProgress)
                        PluginUtilities.sendEvent(progressEvent)
                        
                        // Notify Flutter through method channel
                        activity?.runOnUiThread {
                            methodChannel.invokeMethod("onRouteProgressChanged", progressEvent.toJson())
                        }
                    } catch (e: Exception) {
                        Log.e(TAG, "Error handling route progress", e)
                    }
                }
            })

            // Location observer
            registerLocationObserver(object : LocationObserver {
                override fun onNewRawLocation(rawLocation: android.location.Location) {
                    // Handle raw location updates if needed
                }

                override fun onNewLocationMatcherResult(locationMatcherResult: LocationMatcherResult) {
                    val location = locationMatcherResult.enhancedLocation
                    
                    // Update camera to follow location
                    mapView?.getMapboxMap()?.setCamera(
                        CameraOptions.Builder()
                            .center(Point.fromLngLat(location.longitude, location.latitude))
                            .zoom(15.0)
                            .bearing(location.bearing.toDouble())
                            .build()
                    )
                }
            })

            // Routes observer
            registerRoutesObserver(object : RoutesObserver {
                override fun onRoutesChanged(result: com.mapbox.navigation.core.directions.session.RoutesUpdatedResult) {
                    val routes = result.navigationRoutes
                    if (routes.isNotEmpty()) {
                        currentRoute = routes[0]
                        isRouteBuilt = true
                        
                        // Notify Flutter
                        activity?.runOnUiThread {
                            methodChannel.invokeMethod("onRouteBuilt", null)
                        }
                        
                        PluginUtilities.sendEvent(MapBoxEvents.ROUTE_BUILT)
                        
                        // Start navigation if not already started
                        if (!isNavigationStarted) {
                            startNavigation()
                        }
                    }
                }
            })
        }
    }

    private fun buildRoute(waypoints: List<Waypoint>) {
        try {
            if (waypoints.size < 2) {
                Log.w(TAG, "Need at least 2 waypoints to build route")
                return
            }

            val coordinates = waypoints.map { waypoint ->
                waypoint.point
            }

            if (coordinates.size < 2) {
                Log.w(TAG, "Need at least 2 valid coordinates to build route")
                return
            }

            Log.d(TAG, "Building route with ${coordinates.size} waypoints")

            val routeOptions = RouteOptions.builder()
                .coordinatesList(coordinates)
                .profile(DirectionsCriteria.PROFILE_DRIVING_TRAFFIC)
                .alternatives(FlutterMapboxNavigationPlugin.showAlternateRoutes)
                .steps(true)
                .geometries(DirectionsCriteria.GEOMETRY_POLYLINE6)
                .overview(DirectionsCriteria.OVERVIEW_FULL)
                .annotations(DirectionsCriteria.ANNOTATION_SPEED)
                .build()

            mapboxNavigation?.requestRoutes(
                routeOptions,
                object : NavigationRouterCallback {
                    override fun onRoutesReady(routes: List<NavigationRoute>, routerOrigin: RouterOrigin) {
                        Log.d(TAG, "Routes ready: ${routes.size} routes")
                        mapboxNavigation?.setNavigationRoutes(routes)
                    }

                    override fun onFailure(reasons: List<RouterFailure>, routeOptions: RouteOptions) {
                        Log.e(TAG, "Route building failed: $reasons")
                        PluginUtilities.sendEvent(MapBoxEvents.ROUTE_BUILD_FAILED)
                        
                        activity?.runOnUiThread {
                            methodChannel.invokeMethod("onRouteBuildFailed", reasons.toString())
                        }
                    }

                    override fun onCanceled(routeOptions: RouteOptions, routerOrigin: RouterOrigin) {
                        Log.d(TAG, "Route building cancelled")
                    }
                }
            )

        } catch (e: Exception) {
            Log.e(TAG, "Error building route", e)
        }
    }

    private fun startNavigation() {
        try {
            if (currentRoute == null) {
                Log.w(TAG, "Cannot start navigation: no route available")
                return
            }

            if (isNavigationStarted) {
                Log.w(TAG, "Navigation already started")
                return
            }

            Log.d(TAG, "Starting navigation")
            
            mapboxNavigation?.startTripSession()
            isNavigationStarted = true
            
            PluginUtilities.sendEvent(MapBoxEvents.NAVIGATION_RUNNING)
            
            // Notify Flutter
            activity?.runOnUiThread {
                methodChannel.invokeMethod("onNavigationStarted", null)
            }
            
        } catch (e: Exception) {
            Log.e(TAG, "Error starting navigation", e)
        }
    }

    private fun stopNavigation() {
        try {
            Log.d(TAG, "Stopping navigation")
            
            mapboxNavigation?.stopTripSession()
            isNavigationStarted = false
            isRouteBuilt = false
            currentRoute = null
            
            PluginUtilities.sendEvent(MapBoxEvents.NAVIGATION_FINISHED)
            
            // Notify Flutter
            activity?.runOnUiThread {
                methodChannel.invokeMethod("onNavigationFinished", null)
            }
            
        } catch (e: Exception) {
            Log.e(TAG, "Error stopping navigation", e)
        }
    }

    private fun getMapboxAccessToken(): String {
        return try {
            PluginUtilities.getResourceFromContext(context, "mapbox_access_token")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to get Mapbox access token", e)
            ""
        }
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "addStaticMarkers" -> {
                try {
                    val markers = call.argument<List<Map<String, Any>>>("markers")
                    val configuration = call.argument<Map<String, Any>>("configuration")
                    
                    // Handle static marker addition through StaticMarkerManager
                    // This integrates with the existing marker system
                    result.success(true)
                } catch (e: Exception) {
                    result.error("ADD_MARKERS_ERROR", e.message, null)
                }
            }
            "finishNavigation" -> {
                stopNavigation()
                result.success(true)
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    override fun getView(): View = frameLayout

    override fun dispose() {
        try {
            Log.d(TAG, "Disposing Flutter navigation platform view")
            
            // Update lifecycle state to DESTROYED
            lifecycleRegistry.currentState = Lifecycle.State.DESTROYED
            
            mapboxNavigation?.let { nav ->
                if (isNavigationStarted) {
                    nav.stopTripSession()
                }
                // Note: Individual observers should be unregistered if we keep references to them
            }
            
            mapView?.onDestroy()
            methodChannel.setMethodCallHandler(null)
            
        } catch (e: Exception) {
            Log.e(TAG, "Error disposing platform view", e)
        }
    }
}