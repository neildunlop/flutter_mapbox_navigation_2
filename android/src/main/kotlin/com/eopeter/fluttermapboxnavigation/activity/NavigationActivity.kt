package com.eopeter.fluttermapboxnavigation.activity

import android.Manifest
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.location.Location
import android.os.Build
import android.os.Bundle
import android.util.Log
import androidx.appcompat.app.AppCompatActivity
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import com.eopeter.fluttermapboxnavigation.FlutterMapboxNavigationPlugin
import com.eopeter.fluttermapboxnavigation.R
import com.eopeter.fluttermapboxnavigation.TurnByTurn
import com.eopeter.fluttermapboxnavigation.databinding.NavigationActivityBinding
import com.eopeter.fluttermapboxnavigation.models.MapBoxEvents
import com.eopeter.fluttermapboxnavigation.models.MapBoxRouteProgressEvent
import com.eopeter.fluttermapboxnavigation.models.Waypoint
import com.eopeter.fluttermapboxnavigation.models.WaypointSet
import com.eopeter.fluttermapboxnavigation.utilities.CustomInfoPanelBinder
import com.eopeter.fluttermapboxnavigation.utilities.CustomInfoPanelEndNavButtonBinder
import com.eopeter.fluttermapboxnavigation.utilities.CustomTripProgressBinder
import com.eopeter.fluttermapboxnavigation.utilities.MarkerPopupOverlay
import com.eopeter.fluttermapboxnavigation.utilities.PluginUtilities
import com.eopeter.fluttermapboxnavigation.utilities.TripProgressManager
import com.eopeter.fluttermapboxnavigation.utilities.TripProgressOverlay
import com.eopeter.fluttermapboxnavigation.utilities.PluginUtilities.Companion.sendEvent
import com.eopeter.fluttermapboxnavigation.StaticMarkerManager
import com.google.gson.Gson
import com.mapbox.api.directions.v5.DirectionsCriteria
import com.mapbox.api.directions.v5.models.DirectionsRoute
import com.mapbox.api.directions.v5.models.RouteOptions
import com.mapbox.geojson.Point
import com.mapbox.maps.MapView
import com.mapbox.maps.Style
import com.mapbox.maps.plugin.gestures.OnMapLongClickListener
import com.mapbox.maps.plugin.gestures.OnMapClickListener
import com.mapbox.maps.plugin.gestures.gestures
import com.mapbox.navigation.base.extensions.applyDefaultNavigationOptions
import com.mapbox.navigation.base.extensions.applyLanguageAndVoiceUnitOptions
import com.mapbox.navigation.base.options.NavigationOptions
import com.mapbox.navigation.base.route.NavigationRoute
import com.mapbox.navigation.base.route.NavigationRouterCallback
import com.mapbox.navigation.base.route.RouterFailure
import com.mapbox.navigation.base.route.RouterOrigin
import com.mapbox.navigation.base.trip.model.RouteLegProgress
import com.mapbox.navigation.base.trip.model.RouteProgress
import com.mapbox.navigation.core.arrival.ArrivalObserver
import com.mapbox.navigation.core.directions.session.RoutesObserver
import com.mapbox.navigation.core.lifecycle.MapboxNavigationApp
import com.mapbox.navigation.core.trip.session.BannerInstructionsObserver
import com.mapbox.navigation.core.trip.session.LocationMatcherResult
import com.mapbox.navigation.core.trip.session.LocationObserver
import com.mapbox.navigation.core.trip.session.OffRouteObserver
import com.mapbox.navigation.core.trip.session.RouteProgressObserver
import com.mapbox.navigation.core.trip.session.VoiceInstructionsObserver
import com.mapbox.navigation.dropin.map.MapViewObserver
import com.mapbox.navigation.dropin.navigationview.NavigationViewListener
import com.mapbox.navigation.utils.internal.ifNonNull
import com.mapbox.navigation.base.formatter.DistanceFormatterOptions
import com.mapbox.navigation.base.formatter.DistanceFormatter
import com.mapbox.navigation.base.formatter.UnitType
import org.json.JSONObject
import androidx.appcompat.app.AlertDialog
import com.eopeter.fluttermapboxnavigation.models.StaticMarker

class NavigationActivity : AppCompatActivity() {
    private var finishBroadcastReceiver: BroadcastReceiver? = null
    private var addWayPointsBroadcastReceiver: BroadcastReceiver? = null
    private var points: MutableList<Waypoint> = mutableListOf()
    private var originalPoints: MutableList<Waypoint> = mutableListOf() // Keep original for prev functionality
    private var waypointSet: WaypointSet = WaypointSet()
    private var canResetRoute: Boolean = false
    private var accessToken: String? = null
    private var lastLocation: Location? = null
    private var lastRouteProgressLocation: Point? = null // Cache location from route progress for accurate rerouting
    private var isNavigationInProgress = false
    private var currentTargetWaypointIndex = 0 // Track which waypoint we're heading to
    private lateinit var binding: NavigationActivityBinding
    private lateinit var turnByTurn: TurnByTurn
    private lateinit var markerPopupOverlay: MarkerPopupOverlay
    private lateinit var tripProgressOverlay: TripProgressOverlay
    private lateinit var customInfoPanelBinder: CustomInfoPanelBinder
    private val tripProgressManager = TripProgressManager.getInstance()
    

    private val navigationStateListener = object : NavigationViewListener() {
        override fun onFreeDrive() {

        }

        override fun onDestinationPreview() {

        }

        override fun onRoutePreview() {

        }

        override fun onActiveNavigation() {
            isNavigationInProgress = true
        }

        override fun onArrival() {

        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        Log.d("NavigationActivity", "🚀 NavigationActivity onCreate() called")
        super.onCreate(savedInstanceState)
        Log.d("NavigationActivity", "🚀 super.onCreate() completed")
        Log.d("NavigationActivity", "🎨 Setting theme and inflating layout...")
        setTheme(R.style.AppTheme)
        binding = NavigationActivityBinding.inflate(layoutInflater)
        setContentView(binding.root)
        Log.d("NavigationActivity", "🎨 Layout inflated and content view set")
        Log.d("NavigationActivity", "🗺️ Registering navigation listeners...")
        binding.navigationView.addListener(navigationStateListener)
        binding.navigationView.registerMapObserver(onMapClick)
        binding.navigationView.registerMapObserver(staticMarkerMapObserver)
        Log.d("NavigationActivity", "🗺️ Navigation listeners registered successfully")
        accessToken =
            PluginUtilities.getResourceFromContext(this.applicationContext, "mapbox_access_token")

        val navigationOptions = NavigationOptions.Builder(this.applicationContext)
            .accessToken(accessToken)
            .build()

        MapboxNavigationApp
            .setup(navigationOptions)
            .attach(this)

        if (FlutterMapboxNavigationPlugin.longPressDestinationEnabled) {
            binding.navigationView.registerMapObserver(onMapLongClick)
            binding.navigationView.customizeViewOptions {
                enableMapLongClickIntercept = false
            }
        }

        if (FlutterMapboxNavigationPlugin.enableOnMapTapCallback) {
            binding.navigationView.registerMapObserver(onMapClick)
        }
        val act = this
        // Add custom view binders
        binding.navigationView.customizeViewBinders {
            infoPanelEndNavigationButtonBinder =
                CustomInfoPanelEndNavButtonBinder(act)
        }

        MapboxNavigationApp.current()?.registerBannerInstructionsObserver(this.bannerInstructionObserver)
        MapboxNavigationApp.current()?.registerVoiceInstructionsObserver(this.voiceInstructionObserver)
        MapboxNavigationApp.current()?.registerOffRouteObserver(this.offRouteObserver)
        MapboxNavigationApp.current()?.registerRoutesObserver(this.routesObserver)
        MapboxNavigationApp.current()?.registerLocationObserver(locationObserver)
        MapboxNavigationApp.current()?.registerRouteProgressObserver(routeProgressObserver)
        MapboxNavigationApp.current()?.registerArrivalObserver(arrivalObserver)

        finishBroadcastReceiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context, intent: Intent) {
                finish()
            }
        }

        addWayPointsBroadcastReceiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context, intent: Intent) {
                //get waypoints
                val stops = intent.getSerializableExtra("waypoints") as? MutableList<Waypoint>
                val nextIndex = 1
                if (stops != null) {
                    //append to points
                    if (points.count() >= nextIndex)
                        points.addAll(nextIndex, stops)
                    else
                        points.addAll(stops)
                }
            }
        }

        // Register receivers using the manifest-declared receivers
        val finishIntentFilter = IntentFilter(NavigationLauncher.KEY_STOP_NAVIGATION)
        val addWayPointsIntentFilter = IntentFilter(NavigationLauncher.KEY_ADD_WAYPOINTS)
        
        registerReceiver(
            finishBroadcastReceiver,
            finishIntentFilter,
            Context.RECEIVER_NOT_EXPORTED
        )

        registerReceiver(
            addWayPointsBroadcastReceiver,
            addWayPointsIntentFilter,
            Context.RECEIVER_NOT_EXPORTED
        )

        // Set map styles
        val styleUrlDay = FlutterMapboxNavigationPlugin.mapStyleUrlDay ?: Style.MAPBOX_STREETS
        val styleUrlNight = FlutterMapboxNavigationPlugin.mapStyleUrlNight ?: Style.DARK
        
        binding.navigationView.customizeViewStyles {
            // Set info panel peek height to accommodate our custom content
            // Our layout needs ~280dp for: header row, distance/time, progress bar,
            // waypoint count, ETA, and end navigation button
            infoPanelPeekHeight = resources.getDimensionPixelSize(R.dimen.custom_info_panel_peek_height)
        }
        binding.navigationView.customizeViewOptions {
            mapStyleUriDay = styleUrlDay
            mapStyleUriNight = styleUrlNight
            // Configure units for UI display
            distanceFormatterOptions = DistanceFormatterOptions.Builder(this@NavigationActivity)
                .unitType(if (FlutterMapboxNavigationPlugin.navigationVoiceUnits == DirectionsCriteria.IMPERIAL) 
                    UnitType.IMPERIAL 
                else 
                    UnitType.METRIC)
                .build()
        }

        if (FlutterMapboxNavigationPlugin.enableFreeDriveMode) {
            binding.navigationView.api.routeReplayEnabled(FlutterMapboxNavigationPlugin.simulateRoute)
            binding.navigationView.api.startFreeDrive()
            return
        }

        // Handle waypoints - populate waypointSet but don't request routes yet
        // Routes will be requested in beginNavigation() after TurnByTurn is initialized
        val p = intent.getSerializableExtra("waypoints") as? MutableList<Waypoint>
        if (p != null) points = p
        // Store original points for prev functionality (deep copy)
        originalPoints = points.map { Waypoint(it.name ?: "", it.point, it.isSilent) }.toMutableList()
        points.forEach { waypointSet.add(it) }

        turnByTurn = TurnByTurn(
            this,
            this,
            binding,
            accessToken ?: ""
        )

        Log.d("NavigationActivity", "📱 Initializing turn-by-turn navigation...")
        turnByTurn.initFlutterChannelHandlers()
        turnByTurn.initNavigation()
        Log.d("NavigationActivity", "📱 Turn-by-turn initialization completed")
        
        // Use Mapbox Drop-in UI customization instead of separate Flutter overlays
        Log.d("NavigationActivity", "🎯 Setting up Mapbox Drop-in UI customization for marker interactions")
        setupDropInUICustomization()

        // Check for location permissions
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            if (ContextCompat.checkSelfPermission(
                    this,
                    Manifest.permission.ACCESS_FINE_LOCATION
                ) != PackageManager.PERMISSION_GRANTED
            ) {
                ActivityCompat.requestPermissions(
                    this,
                    arrayOf(Manifest.permission.ACCESS_FINE_LOCATION),
                    LOCATION_PERMISSION_REQUEST_CODE
                )
            } else {
                beginNavigation()
            }
        } else {
            beginNavigation()
        }
    }

    override fun onDestroy() {
        super.onDestroy()

        Log.d("NavigationActivity", "🧹 NavigationActivity onDestroy - cleaning up overlays")

        // Clean up the marker popup overlay
        if (::markerPopupOverlay.isInitialized) {
            markerPopupOverlay.cleanup()
        }

        // Clean up the trip progress overlay
        if (::tripProgressOverlay.isInitialized) {
            tripProgressOverlay.hide()
        }
        tripProgressManager.clear()

        Log.d("NavigationActivity", "🧹 NavigationActivity cleanup completed")
        
        if (FlutterMapboxNavigationPlugin.longPressDestinationEnabled) {
            binding.navigationView.unregisterMapObserver(onMapLongClick)
        }
        if (FlutterMapboxNavigationPlugin.enableOnMapTapCallback) {
            binding.navigationView.unregisterMapObserver(onMapClick)
        }
        binding.navigationView.unregisterMapObserver(staticMarkerMapObserver)
        binding.navigationView.removeListener(navigationStateListener)

        MapboxNavigationApp.current()?.unregisterBannerInstructionsObserver(this.bannerInstructionObserver)
        MapboxNavigationApp.current()?.unregisterVoiceInstructionsObserver(this.voiceInstructionObserver)
        MapboxNavigationApp.current()?.unregisterOffRouteObserver(this.offRouteObserver)
        MapboxNavigationApp.current()?.unregisterRoutesObserver(this.routesObserver)
        MapboxNavigationApp.current()?.unregisterLocationObserver(locationObserver)
        MapboxNavigationApp.current()?.unregisterRouteProgressObserver(routeProgressObserver)
        MapboxNavigationApp.current()?.unregisterArrivalObserver(arrivalObserver)
    }

    fun tryCancelNavigation() {
        if (isNavigationInProgress) {
            isNavigationInProgress = false
            sendEvent(MapBoxEvents.NAVIGATION_CANCELLED)
        }
    }

    private fun requestRoutes(waypointSet: WaypointSet) {
        sendEvent(MapBoxEvents.ROUTE_BUILDING)
        MapboxNavigationApp.current()!!.requestRoutes(
            routeOptions = RouteOptions
                .builder()
                .applyDefaultNavigationOptions()
                .applyLanguageAndVoiceUnitOptions(this)
                .coordinatesList(waypointSet.coordinatesList())
                .waypointIndicesList(waypointSet.waypointsIndices())
                .waypointNamesList(waypointSet.waypointsNames())
                .language(FlutterMapboxNavigationPlugin.navigationLanguage)
                .alternatives(FlutterMapboxNavigationPlugin.showAlternateRoutes)
                .voiceUnits(FlutterMapboxNavigationPlugin.navigationVoiceUnits)
                .bannerInstructions(FlutterMapboxNavigationPlugin.bannerInstructionsEnabled)
                .voiceInstructions(FlutterMapboxNavigationPlugin.voiceInstructionsEnabled)
                .steps(true)
                .build(),
            callback = object : NavigationRouterCallback {
                override fun onCanceled(routeOptions: RouteOptions, routerOrigin: RouterOrigin) {
                    sendEvent(MapBoxEvents.ROUTE_BUILD_CANCELLED)
                }

                override fun onFailure(reasons: List<RouterFailure>, routeOptions: RouteOptions) {
                    sendEvent(MapBoxEvents.ROUTE_BUILD_FAILED)
                }

                override fun onRoutesReady(
                    routes: List<NavigationRoute>,
                    routerOrigin: RouterOrigin
                ) {
                    sendEvent(
                        MapBoxEvents.ROUTE_BUILT,
                        Gson().toJson(routes.map { it.directionsRoute.toJson() })
                    )
                    if (routes.isEmpty()) {
                        sendEvent(MapBoxEvents.ROUTE_BUILD_NO_ROUTES_FOUND)
                        return
                    }
                    binding.navigationView.api.routeReplayEnabled(FlutterMapboxNavigationPlugin.simulateRoute)
                    binding.navigationView.api.startActiveGuidance(routes)
                }
            }
        )
    }


    // MultiWaypoint Navigation
    private fun addWaypoint(destination: Point, name: String?) {
        val originLocation = lastLocation
        val originPoint = originLocation?.let {
            Point.fromLngLat(it.longitude, it.latitude)
        } ?: return

        // we always start a route from the current location
        if (addedWaypoints.isEmpty) {
            addedWaypoints.add(Waypoint(originPoint))
        }

        if (!name.isNullOrBlank()) {
            // When you add named waypoints, the string you use here inside "" would be shown in `Maneuver` and played in `Voice` instructions.
            // In this example waypoint names will be visible in the logcat.
            addedWaypoints.add(Waypoint(name, destination))
        } else {
            // When you add silent waypoints, make sure it is followed by a regular or named waypoint, otherwise silent waypoint is treated as a regular waypoint
            addedWaypoints.add(Waypoint(destination, true))
        }

        // execute a route request
        // it's recommended to use the
        // applyDefaultNavigationOptions and applyLanguageAndVoiceUnitOptions
        // that make sure the route request is optimized
        // to allow for support of all of the Navigation SDK features
        MapboxNavigationApp.current()!!.requestRoutes(
            routeOptions = RouteOptions
                .builder()
                .applyDefaultNavigationOptions()
                .applyLanguageAndVoiceUnitOptions(this)
                .coordinatesList(addedWaypoints.coordinatesList())
                .waypointIndicesList(addedWaypoints.waypointsIndices())
                .waypointNamesList(addedWaypoints.waypointsNames())
                .alternatives(FlutterMapboxNavigationPlugin.showAlternateRoutes)
                .build(),
            callback = object : NavigationRouterCallback {
                override fun onRoutesReady(
                    routes: List<NavigationRoute>,
                    routerOrigin: RouterOrigin
                ) {
                    sendEvent(
                        MapBoxEvents.ROUTE_BUILT,
                        Gson().toJson(routes.map { it.directionsRoute.toJson() })
                    )
                    binding.navigationView.api.routeReplayEnabled(true)
                    binding.navigationView.api.startActiveGuidance(routes)
                }

                override fun onFailure(
                    reasons: List<RouterFailure>,
                    routeOptions: RouteOptions
                ) {
                    sendEvent(MapBoxEvents.ROUTE_BUILD_FAILED)
                }

                override fun onCanceled(routeOptions: RouteOptions, routerOrigin: RouterOrigin) {
                    sendEvent(MapBoxEvents.ROUTE_BUILD_CANCELLED)
                }
            }
        )
    }

    // Resets the current route
    private fun resetCurrentRoute() {
        // Implementation will be added when needed
    }

    private fun setRouteAndStartNavigation(routes: List<DirectionsRoute>) {
        // Implementation will be added when needed
    }

    private fun clearRouteAndStopNavigation() {
        // Implementation will be added when needed
    }

    // ==================== WAYPOINT SKIP/PREV FUNCTIONALITY ====================

    /**
     * Skip to the next waypoint (skip the current target waypoint).
     * This removes the current target waypoint and recalculates the route.
     */
    fun skipToNextWaypoint() {
        Log.d("NavigationActivity", "🔀 skipToNextWaypoint called, currentIndex=$currentTargetWaypointIndex, points=${points.size}")

        if (points.size <= 1) {
            Log.w("NavigationActivity", "Cannot skip - only ${points.size} waypoint(s) remaining")
            return
        }

        if (currentTargetWaypointIndex >= points.size) {
            Log.w("NavigationActivity", "Cannot skip - already at last waypoint")
            return
        }

        // Remove the current target waypoint from our points list
        val skippedWaypoint = points.removeAt(currentTargetWaypointIndex)
        Log.d("NavigationActivity", "🔀 Skipped waypoint: ${skippedWaypoint.name}, ${points.size} remaining")

        // Track the skip for correct waypoint numbering
        tripProgressManager.incrementSkippedCount()

        // Recalculate route from current location to remaining waypoints
        recalculateRouteFromCurrentLocation()

        // Send event to Flutter
        sendEvent(MapBoxEvents.WAYPOINT_SKIPPED, skippedWaypoint.name)
    }

    /**
     * Go back to the previous waypoint.
     * This inserts the previous waypoint from the original list back into the route.
     */
    fun goToPreviousWaypoint() {
        Log.d("NavigationActivity", "🔀 goToPreviousWaypoint called, currentIndex=$currentTargetWaypointIndex, points=${points.size}, originalPoints=${originalPoints.size}")

        if (points.isEmpty()) {
            Log.w("NavigationActivity", "Cannot go to previous - no waypoints")
            return
        }

        // Get the first waypoint in our current list (what we're heading to)
        val currentTarget = points.firstOrNull()
        if (currentTarget == null) {
            Log.w("NavigationActivity", "Cannot go to previous - no current target")
            return
        }

        Log.d("NavigationActivity", "🔀 Current target: ${currentTarget.name} at ${currentTarget.point.latitude()}, ${currentTarget.point.longitude()}")

        // Find the current target in the original list (using approximate matching for floating point)
        val originalIndex = originalPoints.indexOfFirst { original ->
            val latMatch = kotlin.math.abs(original.point.latitude() - currentTarget.point.latitude()) < 0.00001
            val lngMatch = kotlin.math.abs(original.point.longitude() - currentTarget.point.longitude()) < 0.00001
            latMatch && lngMatch
        }

        Log.d("NavigationActivity", "🔀 Found current target at original index: $originalIndex")

        if (originalIndex < 0) {
            Log.w("NavigationActivity", "Cannot go to previous - current target not found in original list")
            // List all original points for debugging
            originalPoints.forEachIndexed { i, wp ->
                Log.d("NavigationActivity", "  Original[$i]: ${wp.name} at ${wp.point.latitude()}, ${wp.point.longitude()}")
            }
            return
        }

        if (originalIndex == 0) {
            Log.w("NavigationActivity", "Cannot go to previous - already at first waypoint")
            return
        }

        // Get the previous waypoint from the original list
        val previousWaypoint = originalPoints[originalIndex - 1]
        Log.d("NavigationActivity", "🔀 Previous waypoint: ${previousWaypoint.name}")

        // Check if this waypoint is already in our current list
        val alreadyInList = points.any { wp ->
            val latMatch = kotlin.math.abs(wp.point.latitude() - previousWaypoint.point.latitude()) < 0.00001
            val lngMatch = kotlin.math.abs(wp.point.longitude() - previousWaypoint.point.longitude()) < 0.00001
            latMatch && lngMatch
        }

        if (!alreadyInList) {
            // Insert the previous waypoint at the beginning of our current list
            points.add(0, previousWaypoint)
            Log.d("NavigationActivity", "🔀 Re-added previous waypoint: ${previousWaypoint.name}, now ${points.size} points")

            // Track the restore for correct waypoint numbering
            tripProgressManager.decrementSkippedCount()
        } else {
            Log.d("NavigationActivity", "🔀 Previous waypoint already in route: ${previousWaypoint.name}")
            return  // Nothing to do if already in list
        }

        // Recalculate route
        recalculateRouteFromCurrentLocation()

        // Send event to Flutter
        sendEvent(MapBoxEvents.WAYPOINT_RESTORED, previousWaypoint.name ?: "")
    }

    /**
     * Recalculate route from current location to all remaining waypoints.
     */
    private fun recalculateRouteFromCurrentLocation() {
        // Try to get location from multiple sources - prioritize the most accurate
        var originPoint: Point? = null

        // Source 1: Get location from TurnByTurn's locationObserver (most accurate - it's actually receiving updates!)
        if (::turnByTurn.isInitialized) {
            turnByTurn.getLastLocation()?.let { loc ->
                originPoint = Point.fromLngLat(loc.longitude, loc.latitude)
                Log.w("NAV_REROUTE", "Using TurnByTurn location: ${loc.latitude}, ${loc.longitude}")
            }
        }

        // Source 2: Cached location from our local observer (backup)
        if (originPoint == null) {
            lastRouteProgressLocation?.let { loc ->
                originPoint = loc
                Log.w("NAV_REROUTE", "Using cached progress location: ${loc.latitude()}, ${loc.longitude()}")
            }
        }

        // Source 3: Last known location from our location observer
        if (originPoint == null) {
            lastLocation?.let { loc ->
                originPoint = Point.fromLngLat(loc.longitude, loc.latitude)
                Log.w("NAV_REROUTE", "Using lastLocation: ${loc.latitude}, ${loc.longitude}")
            }
        }

        // Source 4: Get from current navigation routes - maneuver location (less accurate)
        if (originPoint == null) {
            MapboxNavigationApp.current()?.getNavigationRoutes()?.firstOrNull()?.let { route ->
                route.directionsRoute.legs()?.firstOrNull()?.steps()?.firstOrNull()?.let { step ->
                    step.maneuver().location()?.let { loc ->
                        originPoint = Point.fromLngLat(loc.longitude(), loc.latitude())
                        Log.w("NAV_REROUTE", "Using route maneuver location (fallback): ${loc.latitude()}, ${loc.longitude()}")
                    }
                }
            }
        }

        // Source 5: Use first remaining waypoint as origin (last resort)
        if (originPoint == null && points.isNotEmpty()) {
            val firstPoint = points.first().point
            originPoint = firstPoint
            Log.w("NAV_REROUTE", "Using first waypoint as fallback origin: ${firstPoint.latitude()}, ${firstPoint.longitude()}")
        }

        val origin = originPoint
        if (origin == null) {
            Log.e("NavigationActivity", "Cannot recalculate route - no location available from any source")
            return
        }

        // Rebuild the waypoint set from current location + remaining waypoints
        waypointSet.clear()
        waypointSet.add(Waypoint(origin)) // Start from current location

        points.forEach { waypoint ->
            if (!waypoint.name.isNullOrBlank()) {
                waypointSet.add(Waypoint(waypoint.name ?: "", waypoint.point))
            } else if (waypoint.isSilent) {
                waypointSet.add(Waypoint(waypoint.point, true))
            } else {
                waypointSet.add(Waypoint(waypoint.point, false))
            }
        }

        Log.w("NAV_REROUTE", "Recalculating with ${points.size} waypoints from: ${origin.latitude()}, ${origin.longitude()}")

        // Update trip progress manager with new waypoint list
        val markers = StaticMarkerManager.getInstance().getMarkers()
        tripProgressManager.setWaypointsFromMarkers(points, markers)

        // Reset target index since we've modified the list
        currentTargetWaypointIndex = 0

        // Immediately update the UI with the new waypoint info
        // Use 0 for distance/duration - will be updated when new route progress arrives
        // This ensures the waypoint name and count update immediately
        tripProgressManager.updateProgress(
            legIndex = 0,  // Starting fresh from first waypoint in updated list
            distanceToNextWaypoint = 0.0,  // Will be updated by route progress observer
            totalDistanceRemaining = 0.0,
            totalDurationRemaining = 0.0,
            durationToNextWaypoint = 0.0
        )
        Log.w("NAV_REROUTE", "Triggered immediate UI update with ${points.size} waypoints")

        // Request new route - use the update method since navigation is already active
        requestRoutesForUpdate(waypointSet)
    }

    /**
     * Request routes and update the active navigation session (for skip/prev waypoint).
     * Uses setNavigationRoutes instead of startActiveGuidance since we're already navigating.
     */
    private fun requestRoutesForUpdate(waypointSet: WaypointSet) {
        sendEvent(MapBoxEvents.ROUTE_BUILDING)
        MapboxNavigationApp.current()!!.requestRoutes(
            routeOptions = RouteOptions
                .builder()
                .applyDefaultNavigationOptions()
                .applyLanguageAndVoiceUnitOptions(this)
                .coordinatesList(waypointSet.coordinatesList())
                .waypointIndicesList(waypointSet.waypointsIndices())
                .waypointNamesList(waypointSet.waypointsNames())
                .language(FlutterMapboxNavigationPlugin.navigationLanguage)
                .alternatives(FlutterMapboxNavigationPlugin.showAlternateRoutes)
                .voiceUnits(FlutterMapboxNavigationPlugin.navigationVoiceUnits)
                .bannerInstructions(FlutterMapboxNavigationPlugin.bannerInstructionsEnabled)
                .voiceInstructions(FlutterMapboxNavigationPlugin.voiceInstructionsEnabled)
                .steps(true)
                .build(),
            callback = object : NavigationRouterCallback {
                override fun onCanceled(routeOptions: RouteOptions, routerOrigin: RouterOrigin) {
                    sendEvent(MapBoxEvents.ROUTE_BUILD_CANCELLED)
                }

                override fun onFailure(reasons: List<RouterFailure>, routeOptions: RouteOptions) {
                    sendEvent(MapBoxEvents.ROUTE_BUILD_FAILED)
                    Log.e("NavigationActivity", "🔀 Route update failed: ${reasons.map { it.message }}")
                }

                override fun onRoutesReady(
                    routes: List<NavigationRoute>,
                    routerOrigin: RouterOrigin
                ) {
                    sendEvent(
                        MapBoxEvents.ROUTE_BUILT,
                        Gson().toJson(routes.map { it.directionsRoute.toJson() })
                    )
                    if (routes.isEmpty()) {
                        sendEvent(MapBoxEvents.ROUTE_BUILD_NO_ROUTES_FOUND)
                        return
                    }

                    Log.d("NavigationActivity", "🔀 Route update ready, setting ${routes.size} routes")
                    Log.d("NavigationActivity", "🔀 New Route ID: ${routes.first().id}")

                    // Set routes on the core navigation first
                    MapboxNavigationApp.current()?.setNavigationRoutes(routes)
                    Log.d("NavigationActivity", "🔀 Routes set on core navigation")

                    // Ensure trip session is running (required for progress updates)
                    MapboxNavigationApp.current()?.startTripSession()
                    Log.d("NavigationActivity", "🔀 Trip session started/restarted")

                    // Update NavigationView to show the new routes
                    binding.navigationView.api.routeReplayEnabled(FlutterMapboxNavigationPlugin.simulateRoute)
                    binding.navigationView.api.startActiveGuidance(routes)

                    Log.d("NavigationActivity", "🔀 startActiveGuidance called with new routes")
                    sendEvent(MapBoxEvents.REROUTE_ALONG)
                }
            }
        )
    }

    // ==================== END WAYPOINT SKIP/PREV ====================

    /**
     * Helper class that keeps added waypoints and transforms them to the [RouteOptions] params.
     */
    private val addedWaypoints = WaypointSet()


    /**
     * Gets notified with progress along the currently active route.
     */
    private val routeProgressObserver = RouteProgressObserver { routeProgress ->
        // Debug: confirm observer is being called
        Log.w("NAV_PROGRESS", "Observer called - distRemaining=${routeProgress.distanceRemaining}")

        try {
            //Notify the client
            val progressEvent = MapBoxRouteProgressEvent(routeProgress)
            FlutterMapboxNavigationPlugin.distanceRemaining = routeProgress.distanceRemaining
            FlutterMapboxNavigationPlugin.durationRemaining = routeProgress.durationRemaining
            sendEvent(progressEvent)

            // Update trip progress overlay
            val legIndex = routeProgress.currentLegProgress?.legIndex ?: 0
            val distanceToNext = routeProgress.currentLegProgress?.distanceRemaining?.toDouble() ?: 0.0
            val durationToNext = routeProgress.currentLegProgress?.durationRemaining ?: 0.0
            val routeId = routeProgress.navigationRoute.id

            // Use Log.w to ensure it appears in logcat
            Log.w("NAV_PROGRESS", "Progress: route=${routeId.takeLast(20)}, leg=$legIndex, dist=${String.format("%.0f", distanceToNext)}m, dur=${String.format("%.0f", durationToNext)}s")

            // Track current target waypoint index for skip/prev functionality
            currentTargetWaypointIndex = legIndex.coerceIn(0, (points.size - 1).coerceAtLeast(0))

            // Update the cached location from the current route position for rerouting
            // Use the enhanced location from the location matcher if available

            tripProgressManager.updateProgress(
                legIndex = legIndex,
                distanceToNextWaypoint = distanceToNext,
                totalDistanceRemaining = routeProgress.distanceRemaining.toDouble(),
                totalDurationRemaining = routeProgress.durationRemaining,
                durationToNextWaypoint = durationToNext
            )
        } catch (e: Exception) {
            Log.e("NAV_PROGRESS", "Error in observer: ${e.message}", e)
        }
    }

    private val arrivalObserver: ArrivalObserver = object : ArrivalObserver {
        override fun onFinalDestinationArrival(routeProgress: RouteProgress) {
            isNavigationInProgress = false
            sendEvent(MapBoxEvents.ON_ARRIVAL)
        }

        override fun onNextRouteLegStart(routeLegProgress: RouteLegProgress) {
            // Not needed for basic navigation
        }

        override fun onWaypointArrival(routeProgress: RouteProgress) {
            // Not needed for basic navigation
        }
    }

    /**
     * Gets notified with location updates.
     *
     * Exposes raw updates coming directly from the location services
     * and the updates enhanced by the Navigation SDK (cleaned up and matched to the road).
     */
    private val locationObserver = object : LocationObserver {
        override fun onNewLocationMatcherResult(locationMatcherResult: LocationMatcherResult) {
            lastLocation = locationMatcherResult.enhancedLocation
            // Also update the route progress location cache with the enhanced location
            lastLocation?.let { loc ->
                lastRouteProgressLocation = Point.fromLngLat(loc.longitude, loc.latitude)
            }
            // Use Log.w to ensure visibility
            Log.w("NAV_LOCATION", "Enhanced: ${lastLocation?.latitude}, ${lastLocation?.longitude}")
        }

        override fun onNewRawLocation(rawLocation: Location) {
            // Also capture raw location as fallback
            if (lastLocation == null) {
                lastLocation = rawLocation
                lastRouteProgressLocation = Point.fromLngLat(rawLocation.longitude, rawLocation.latitude)
                Log.w("NAV_LOCATION", "Raw: ${rawLocation.latitude}, ${rawLocation.longitude}")
            }
        }
    }

    private val bannerInstructionObserver = BannerInstructionsObserver { bannerInstructions ->
        sendEvent(MapBoxEvents.BANNER_INSTRUCTION, bannerInstructions.primary().text())
    }

    private val voiceInstructionObserver = VoiceInstructionsObserver { voiceInstructions ->
        sendEvent(MapBoxEvents.SPEECH_ANNOUNCEMENT, voiceInstructions.announcement().toString())
    }

    private val offRouteObserver = OffRouteObserver { offRoute ->
        if (offRoute) {
            sendEvent(MapBoxEvents.USER_OFF_ROUTE)
        }
    }

    private val routesObserver = RoutesObserver { routeUpdateResult ->
        val routes = routeUpdateResult.navigationRoutes
        Log.i("NavigationActivity", "📍 RoutesObserver: ${routes.size} routes, reason=${routeUpdateResult.reason}")
        if (routes.isNotEmpty()) {
            Log.i("NavigationActivity", "📍 RoutesObserver: route ID=${routes.first().id.takeLast(30)}")
            sendEvent(MapBoxEvents.REROUTE_ALONG)
        }
    }

    /**
     * Notifies with attach and detach events on [MapView]
     */
    private val onMapLongClick = object : MapViewObserver(), OnMapLongClickListener {

        override fun onAttached(mapView: MapView) {
            mapView.gestures.addOnMapLongClickListener(this)
        }

        override fun onDetached(mapView: MapView) {
            mapView.gestures.removeOnMapLongClickListener(this)
        }

        override fun onMapLongClick(point: Point): Boolean {
            ifNonNull(lastLocation) {
                val waypointSet = WaypointSet()
                waypointSet.add(Waypoint(Point.fromLngLat(it.longitude, it.latitude)))
                waypointSet.add(Waypoint(point))
                requestRoutes(waypointSet)
            }
            return false
        }
    }

    /**
     * Notifies with attach and detach events on [MapView]
     */
    /**
     * MapView observer for static markers
     */
    private val staticMarkerMapObserver = object : MapViewObserver() {
        override fun onAttached(mapView: MapView) {
            try {
                val manager = StaticMarkerManager.getInstance()
                manager.setContext(this@NavigationActivity)
                manager.setMapView(mapView)
            } catch (e: Exception) {
                Log.e("NavigationActivity", "Error setting up StaticMarkerManager: ${e.message}")
            }
        }

        override fun onDetached(mapView: MapView) {
            try {
                StaticMarkerManager.getInstance().setMapView(null)
            } catch (e: Exception) {
                Log.e("NavigationActivity", "Error clearing StaticMarkerManager: ${e.message}")
            }
        }
    }

    private val onMapClick = object : MapViewObserver(), OnMapClickListener {

        override fun onAttached(mapView: MapView) {
            mapView.gestures.addOnMapClickListener(this)
        }

        override fun onDetached(mapView: MapView) {
            mapView.gestures.removeOnMapClickListener(this)
        }

        override fun onMapClick(point: Point): Boolean {
            Log.d("NavigationActivity", "🗺️ onMapClick called at (${point.latitude()}, ${point.longitude()})")
            // Check if the tap is near any markers and handle it
            val tappedMarker = StaticMarkerManager.getInstance().getMarkerNearPoint(
                point.latitude(), 
                point.longitude()
            )
            Log.d("NavigationActivity", "🗺️ Marker found near tap: ${tappedMarker?.title ?: "none"}")
            
            if (tappedMarker != null) {
                Log.d("NavigationActivity", "Marker tapped: ${tappedMarker.title}")
                
                // Trigger the marker tap through StaticMarkerManager's listener
                // This will call the MarkerPopupBinder's listener
                Log.d("NavigationActivity", "Triggering marker tap listener for ViewBinder")
                StaticMarkerManager.getInstance().triggerMarkerTapListener(tappedMarker)
                
                return true // Consume the event to prevent navigation interference
            }
            
            // Send map tap event to Flutter for full-screen navigation
            val eventData = mapOf(
                "type" to "map_tap",
                "mode" to "fullscreen",
                "latitude" to point.latitude(),
                "longitude" to point.longitude()
            )
            sendEvent(MapBoxEvents.MAP_TAP_FULLSCREEN, JSONObject(eventData).toString())
            return false
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == LOCATION_PERMISSION_REQUEST_CODE) {
            if (grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
                beginNavigation()
            } else {
                PluginUtilities.sendEvent(MapBoxEvents.NAVIGATION_CANCELLED)
                finish()
            }
        }
    }

    private fun beginNavigation() {
        // Request routes using the waypointSet that was populated in onCreate()
        // This is called after TurnByTurn.initNavigation() and after location permission is granted
        if (!waypointSet.isEmpty) {
            requestRoutes(waypointSet)
        }
    }
    
    private fun setupDropInUICustomization() {
        Log.d("NavigationActivity", "🎯 Setting up Drop-in UI customization - Full panel replacement")

        // Initialize the custom info panel binder that replaces the entire info panel
        customInfoPanelBinder = CustomInfoPanelBinder(
            activity = this,
            onSkipPrevious = {
                Log.d("NavigationActivity", "🔀 Previous button pressed")
                goToPreviousWaypoint()
            },
            onSkipNext = {
                Log.d("NavigationActivity", "🔀 Next/Skip button pressed")
                skipToNextWaypoint()
            },
            onEndNavigation = {
                Log.d("NavigationActivity", "🔴 End navigation callback")
                // Activity finish is handled in the binder
            }
        )

        // Register the full panel binder - this replaces the entire info panel
        binding.navigationView.customizeViewBinders {
            infoPanelBinder = customInfoPanelBinder
        }

        // Initialize the floating marker popup overlay
        markerPopupOverlay = MarkerPopupOverlay(this)
        markerPopupOverlay.initialize()

        // Initialize the legacy trip progress overlay (keep for backward compatibility, but don't show)
        tripProgressOverlay = TripProgressOverlay(this)

        // Set up waypoints for progress tracking
        val markers = StaticMarkerManager.getInstance().getMarkers()
        Log.d("NavigationActivity", "Setting up trip progress: points=${points.size}, markers=${markers.size}")

        // The CustomTripProgressBinder now handles progress updates via TripProgressManager's listener
        // which is set up in the binder's bind() method

        if (points.isNotEmpty()) {
            tripProgressManager.setWaypointsFromMarkers(points, markers, isInitialSetup = true)
            Log.d("NavigationActivity", "Waypoints set in TripProgressManager (initial setup)")
        } else {
            Log.w("NavigationActivity", "No points available for trip progress!")
        }

        // Note: We no longer show the floating tripProgressOverlay as we're using the native panel binder
        // tripProgressOverlay.show() - REMOVED

        // Trigger an initial update (after UI is created)
        if (points.isNotEmpty()) {
            tripProgressManager.updateProgress(
                legIndex = 0,
                distanceToNextWaypoint = 0.0,
                totalDistanceRemaining = 0.0,
                totalDurationRemaining = 0.0
            )
        }

        Log.d("NavigationActivity", "✅ Drop-in UI customization complete with native trip progress binder")
    }
    

    companion object {
        private const val LOCATION_PERMISSION_REQUEST_CODE = 1
    }
}
