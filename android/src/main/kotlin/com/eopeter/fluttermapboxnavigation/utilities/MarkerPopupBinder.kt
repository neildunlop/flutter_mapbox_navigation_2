package com.eopeter.fluttermapboxnavigation.utilities

import android.content.Context
import android.util.Log
import android.view.ViewGroup
import android.widget.FrameLayout
import com.eopeter.fluttermapboxnavigation.FlutterMapboxNavigationPlugin
import com.eopeter.fluttermapboxnavigation.StaticMarkerManager
import com.eopeter.fluttermapboxnavigation.activity.NavigationActivity
import com.eopeter.fluttermapboxnavigation.models.StaticMarker
import com.eopeter.fluttermapboxnavigation.models.MapBoxEvents
import com.mapbox.navigation.ui.base.lifecycle.UIBinder
import com.mapbox.navigation.ui.base.lifecycle.UIComponent
import com.mapbox.navigation.core.lifecycle.MapboxNavigationObserver
import com.mapbox.navigation.core.MapboxNavigation
import org.json.JSONObject

/**
 * Custom UIBinder for injecting Flutter-rendered marker popups into Mapbox Drop-in UI
 * Uses infoPanelContentBinder to show marker details above the navigation info panel
 */
class MarkerPopupBinder(private val activity: NavigationActivity) : UIBinder {
    
    private var currentMarker: StaticMarker? = null
    private var popupView: android.widget.TextView? = null
    
    override fun bind(viewGroup: ViewGroup): MapboxNavigationObserver {
        Log.d("MarkerPopupBinder", "🎯 MarkerPopupBinder.bind() called")
        
        // Set up Flutter view for marker popups
        setupFlutterView(viewGroup)
        
        return object : UIComponent() {
            override fun onAttached(mapboxNavigation: MapboxNavigation) {
                super.onAttached(mapboxNavigation)
                Log.d("MarkerPopupBinder", "🎯 UIComponent onAttached - setting up marker listener")
                
                // Listen for marker tap events from StaticMarkerManager
                Log.d("MarkerPopupBinder", "📡 Setting marker tap listener")
                StaticMarkerManager.getInstance().setMarkerTapListener { marker ->
                    Log.d("MarkerPopupBinder", "🎯 MARKER TAP LISTENER CALLED: ${marker.title} - showing popup")
                    showMarkerPopup(marker)
                }
            }
            
            override fun onDetached(mapboxNavigation: MapboxNavigation) {
                super.onDetached(mapboxNavigation)
                Log.d("MarkerPopupBinder", "🎯 UIComponent onDetached - cleaning up")
                
                // Clear marker tap listener
                StaticMarkerManager.getInstance().setMarkerTapListener(null)
                cleanupFlutterView(viewGroup)
            }
        }
    }
    
    private fun setupFlutterView(parent: ViewGroup) {
        try {
            Log.d("MarkerPopupBinder", "🎯 Setting up placeholder view for marker popups")
            Log.d("MarkerPopupBinder", "🎯 Parent ViewGroup: ${parent::class.java.simpleName}, children: ${parent.childCount}")
            
            // Create a simple placeholder view to test the ViewBinder structure
            popupView = android.widget.TextView(activity)
            popupView!!.text = "🎯 MARKER POPUP READY"
            popupView!!.visibility = android.view.View.GONE
            popupView!!.setBackgroundColor(android.graphics.Color.YELLOW)
            popupView!!.setPadding(32, 32, 32, 32)
            popupView!!.textSize = 16f
            popupView!!.setTextColor(android.graphics.Color.BLACK)
            
            val layoutParams = FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                FrameLayout.LayoutParams.WRAP_CONTENT
            )
            layoutParams.topMargin = 100 // Add some top margin to make it visible
            
            parent.addView(popupView, layoutParams)
            
            Log.d("MarkerPopupBinder", "✅ Placeholder view added to parent. Parent now has ${parent.childCount} children")
            Log.d("MarkerPopupBinder", "✅ PopupView created: ${popupView != null}")
            
        } catch (e: Exception) {
            Log.e("MarkerPopupBinder", "❌ Error setting up placeholder view", e)
            e.printStackTrace()
        }
    }
    
    private fun cleanupFlutterView(parent: ViewGroup) {
        try {
            popupView?.let { view ->
                parent.removeView(view)
            }
            
            popupView = null
            currentMarker = null
            
            Log.d("MarkerPopupBinder", "🧹 View cleanup complete")
            
        } catch (e: Exception) {
            Log.e("MarkerPopupBinder", "❌ Error cleaning up view", e)
        }
    }
    
    private fun showMarkerPopup(marker: StaticMarker) {
        try {
            Log.d("MarkerPopupBinder", "🎯 SHOWING FLUTTER POPUP for: ${marker.title}")
            
            currentMarker = marker
            
            // Get screen position for the marker
            val screenPosition = StaticMarkerManager.getInstance().getScreenPosition(
                marker.latitude, 
                marker.longitude
            )
            
            // Create event data for Flutter popup system
            val eventData = mutableMapOf<String, Any>(
                "type" to "marker_tap",
                "mode" to "fullscreen",
                "marker_id" to marker.id,
                "marker_title" to marker.title,
                "marker_category" to marker.category,
                "marker_latitude" to marker.latitude,
                "marker_longitude" to marker.longitude
            )
            
            // Add optional fields if available
            marker.description?.let { eventData["marker_description"] = it }
            marker.iconId?.let { eventData["marker_iconId"] = it }
            marker.customColor?.let { eventData["marker_customColor"] = it }
            marker.metadata?.let { metadata ->
                // Convert metadata map to flat structure
                metadata.forEach { (key, value) ->
                    eventData["marker_metadata_$key"] = value
                }
            }
            
            // Add screen position if available
            screenPosition?.let { (x, y) ->
                eventData["screen_x"] = x
                eventData["screen_y"] = y
            }
            
            // Send event to Flutter for popup handling
            val jsonObject = JSONObject(eventData as Map<String, Any?>)
            PluginUtilities.sendEvent(MapBoxEvents.MAP_TAP_FULLSCREEN, jsonObject.toString())
            
            Log.d("MarkerPopupBinder", "✅ Flutter popup event sent: ${jsonObject}")
            
        } catch (e: Exception) {
            Log.e("MarkerPopupBinder", "❌ Error showing Flutter popup", e)
            e.printStackTrace()
        }
    }
    
    fun hideMarkerPopup() {
        try {
            Log.d("MarkerPopupBinder", "🎯 Hiding marker popup")
            
            currentMarker = null
            
            // Hide the popup view
            popupView?.visibility = android.view.View.GONE
            
        } catch (e: Exception) {
            Log.e("MarkerPopupBinder", "❌ Error hiding marker popup", e)
        }
    }
}