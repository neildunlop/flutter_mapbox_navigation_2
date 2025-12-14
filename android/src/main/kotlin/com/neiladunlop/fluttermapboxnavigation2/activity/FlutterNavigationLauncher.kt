package com.neiladunlop.fluttermapboxnavigation2.activity

import android.app.Activity
import android.util.Log
import com.neiladunlop.fluttermapboxnavigation2.models.Waypoint

/**
 * Launcher utility for Flutter-styled Drop-in Navigation
 * This replaces the complex platform view approach with a simpler, more reliable method
 */
object FlutterNavigationLauncher {
    
    private const val TAG = "FlutterNavigationLauncher"
    
    /**
     * Launch Flutter-styled navigation using Mapbox Drop-in UI
     * This provides native performance with Flutter-consistent UI and perfect overlay support
     */
    fun startFlutterNavigation(
        activity: Activity?,
        waypoints: List<Waypoint>,
        options: Map<String, Any> = emptyMap(),
        showDebugOverlay: Boolean = false
    ) {
        if (activity == null) {
            Log.e(TAG, "Activity is null, cannot start Flutter navigation")
            return
        }
        
        if (waypoints.size < 2) {
            Log.e(TAG, "Need at least 2 waypoints to start navigation, got ${waypoints.size}")
            return
        }
        
        try {
            Log.d(TAG, "Starting Flutter-styled navigation with ${waypoints.size} waypoints")
            
            val intent = FlutterStyledNavigationActivity.createIntent(
                context = activity,
                waypoints = waypoints,
                options = options,
                showDebug = showDebugOverlay
            )
            
            activity.startActivity(intent)
            
            Log.d(TAG, "Flutter-styled navigation launched successfully")
            
        } catch (e: Exception) {
            Log.e(TAG, "Error launching Flutter-styled navigation", e)
        }
    }
    
    /**
     * Start free drive mode with Flutter styling
     */
    fun startFlutterFreeDrive(
        activity: Activity?,
        options: Map<String, Any> = emptyMap(),
        showDebugOverlay: Boolean = false
    ) {
        if (activity == null) {
            Log.e(TAG, "Activity is null, cannot start Flutter free drive")
            return
        }
        
        try {
            Log.d(TAG, "Starting Flutter-styled free drive mode")
            
            // Create a single dummy waypoint for free drive
            val dummyWaypoints = listOf(
                Waypoint("Current Location", 0.0, 0.0, true),
                Waypoint("Free Drive", 0.0, 0.0, true)
            )
            
            val freeDriveOptions = options.toMutableMap().apply {
                put("freeDriveMode", true)
            }
            
            val intent = FlutterStyledNavigationActivity.createIntent(
                context = activity,
                waypoints = dummyWaypoints,
                options = freeDriveOptions,
                showDebug = showDebugOverlay
            )
            
            activity.startActivity(intent)
            
        } catch (e: Exception) {
            Log.e(TAG, "Error launching Flutter-styled free drive", e)
        }
    }
}