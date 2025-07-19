package com.eopeter.fluttermapboxnavigation

import android.Manifest
import android.app.Activity
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import com.eopeter.fluttermapboxnavigation.activity.NavigationLauncher
import com.eopeter.fluttermapboxnavigation.factory.EmbeddedNavigationViewFactory
import com.eopeter.fluttermapboxnavigation.models.Waypoint
import com.eopeter.fluttermapboxnavigation.models.StaticMarker
import com.eopeter.fluttermapboxnavigation.models.MarkerConfiguration
import com.mapbox.api.directions.v5.DirectionsCriteria
import com.mapbox.api.directions.v5.models.DirectionsRoute
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
                checkPermissionAndBeginNavigation(call)
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
            else -> result.notImplemented()
        }
    }

    private fun downloadRegionForOfflineRouting(
        call: MethodCall,
        result: Result
    ) {
        // Offline routing is not currently supported in this version
        result.error("NOT_IMPLEMENTED", "Offline routing is not supported", "This feature will be implemented in a future version")
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
}

private const val MAPBOX_ACCESS_TOKEN_PLACEHOLDER = "YOUR_MAPBOX_ACCESS_TOKEN_GOES_HERE"