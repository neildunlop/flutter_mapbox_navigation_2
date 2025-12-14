package com.neiladunlop.fluttermapboxnavigation2.activity

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.graphics.PixelFormat
import android.os.Bundle
import android.util.Log
import android.view.Gravity
import android.view.WindowManager
import android.widget.FrameLayout
import androidx.appcompat.app.AppCompatActivity
import com.neiladunlop.fluttermapboxnavigation2.models.Waypoint
import com.neiladunlop.fluttermapboxnavigation2.utilities.PluginUtilities
import io.flutter.embedding.android.FlutterFragment
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.plugin.common.MethodChannel
import java.util.ArrayList

/**
 * Flutter-styled Navigation Activity that provides Flutter overlays over native navigation
 * This creates a hybrid approach where native navigation runs with Flutter overlay system
 */
class FlutterStyledNavigationActivity : AppCompatActivity() {
    
    companion object {
        private const val TAG = "FlutterStyledNav"
        private const val FLUTTER_ENGINE_ID = "flutter_navigation_overlay"
        private const val REQUEST_NAVIGATION = 1001
        
        // Intent extras
        const val EXTRA_WAYPOINTS = "waypoints"
        const val EXTRA_OPTIONS = "options"
        const val EXTRA_SHOW_DEBUG = "show_debug"
        
        fun createIntent(
            context: Context,
            waypoints: List<Waypoint>,
            options: Map<String, Any> = emptyMap(),
            showDebug: Boolean = false
        ): Intent {
            return Intent(context, FlutterStyledNavigationActivity::class.java).apply {
                putExtra(EXTRA_WAYPOINTS, ArrayList(waypoints))
                putExtra(EXTRA_OPTIONS, HashMap(options))
                putExtra(EXTRA_SHOW_DEBUG, showDebug)
            }
        }
    }
    
    private var waypoints: List<Waypoint> = emptyList()
    private var options: Map<String, Any> = emptyMap()
    private var showDebugOverlay: Boolean = false
    private var flutterEngine: FlutterEngine? = null
    private var overlayContainer: FrameLayout? = null
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        try {
            Log.d(TAG, "Starting Flutter-styled navigation with overlays")
            
            // Parse intent extras
            parseIntentExtras()
            
            // Setup Flutter overlay engine
            setupFlutterOverlay()
            
            // Launch native navigation in background
            launchNativeNavigation()
            
            Log.d(TAG, "Flutter-styled navigation setup complete")
            
        } catch (e: Exception) {
            Log.e(TAG, "Error creating Flutter-styled navigation", e)
            finish()
        }
    }
    
    private fun setupFlutterOverlay() {
        // Create a transparent overlay container
        overlayContainer = FrameLayout(this).apply {
            setBackgroundColor(android.graphics.Color.TRANSPARENT)
        }
        setContentView(overlayContainer)
        
        // Initialize Flutter engine for overlays
        flutterEngine = FlutterEngine(this)
        
        // Setup method channel for overlay communication
        setupOverlayMethodChannel()
        
        Log.d(TAG, "Flutter overlay system initialized")
    }
    
    private fun setupOverlayMethodChannel() {
        flutterEngine?.let { engine ->
            MethodChannel(engine.dartExecutor.binaryMessenger, "flutter_navigation_overlay").apply {
                setMethodCallHandler { call, result ->
                    when (call.method) {
                        "showMarkerOverlay" -> {
                            // Show Flutter overlay for marker details
                            Log.d(TAG, "Showing marker overlay: ${call.arguments}")
                            result.success(true)
                        }
                        "hideOverlay" -> {
                            // Hide current overlay
                            result.success(true)
                        }
                        "finishNavigation" -> {
                            // Close navigation and return to Flutter
                            finish()
                            result.success(true)
                        }
                        else -> result.notImplemented()
                    }
                }
            }
        }
    }
    
    private fun launchNativeNavigation() {
        // Launch NavigationActivity but don't finish this one
        val intent = Intent(this, NavigationActivity::class.java).apply {
            putExtra("waypoints", ArrayList(waypoints))
        }
        startActivityForResult(intent, REQUEST_NAVIGATION)
    }
    
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == REQUEST_NAVIGATION) {
            // Navigation finished, close this activity too
            finish()
        }
    }
    
    private fun parseIntentExtras() {
        waypoints = PluginUtilities.getSerializable(this, EXTRA_WAYPOINTS, ArrayList::class.java) as? List<Waypoint> ?: emptyList()
        options = intent.getSerializableExtra(EXTRA_OPTIONS) as? Map<String, Any> ?: emptyMap()
        showDebugOverlay = intent.getBooleanExtra(EXTRA_SHOW_DEBUG, false)
        
        Log.d(TAG, "Parsed ${waypoints.size} waypoints, showDebug: $showDebugOverlay")
    }
    
    override fun onDestroy() {
        flutterEngine?.destroy()
        super.onDestroy()
    }
}