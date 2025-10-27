package com.eopeter.fluttermapboxnavigation.utilities

import android.content.Context
import android.util.Log
import android.view.ViewGroup
import android.widget.FrameLayout
import com.eopeter.fluttermapboxnavigation.FlutterMapboxNavigationPlugin
import com.eopeter.fluttermapboxnavigation.StaticMarkerManager
import com.eopeter.fluttermapboxnavigation.activity.NavigationActivity
import com.eopeter.fluttermapboxnavigation.models.StaticMarker
import com.mapbox.navigation.ui.base.lifecycle.UIBinder
import com.mapbox.navigation.ui.base.lifecycle.UIComponent
import com.mapbox.navigation.core.lifecycle.MapboxNavigationObserver
import com.mapbox.navigation.core.MapboxNavigation

/**
 * Custom UIBinder for injecting Flutter-rendered marker popups into Mapbox Drop-in UI
 * Uses infoPanelContentBinder to show marker details above the navigation info panel
 */
class MarkerPopupBinder(private val activity: NavigationActivity) : UIBinder {
    
    override fun bind(viewGroup: ViewGroup): MapboxNavigationObserver {
        Log.d("MarkerPopupBinder", "🎯 MarkerPopupBinder.bind() called")
        
        // Set up Flutter view for marker popups
        setupFlutterView(viewGroup)
        
        return object : UIComponent() {
            override fun onAttached(mapboxNavigation: MapboxNavigation) {
                super.onAttached(mapboxNavigation)
                Log.d("MarkerPopupBinder", "🎯 UIComponent onAttached - setting up marker listener")
                
                // Listen for marker tap events from StaticMarkerManager
                Log.d("MarkerPopupBinder", "📡 Setting marker tap listener to forward to Flutter")
                StaticMarkerManager.getInstance().setMarkerTapListener { marker ->
                    Log.d("MarkerPopupBinder", "🎯 MARKER TAP LISTENER CALLED: ${marker.title} - forwarding to Flutter")
                    forwardMarkerTapToFlutter(marker)
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
        Log.d("MarkerPopupBinder", "🎯 MarkerPopupBinder setup - will forward marker taps to Flutter")
        // No native view setup needed since we're forwarding to Flutter
    }
    
    private fun cleanupFlutterView(parent: ViewGroup) {
        Log.d("MarkerPopupBinder", "🧹 MarkerPopupBinder cleanup complete")
        // No cleanup needed since we're not using native views
    }
    
    private fun forwardMarkerTapToFlutter(marker: StaticMarker) {
        try {
            Log.d("MarkerPopupBinder", "🎯 FORWARDING MARKER TAP TO FLUTTER: ${marker.title}")
            
            // Show immediate native Toast for better UX during full-screen navigation
            showNativeToast(marker)
            
            // Also send the marker tap event to Flutter for consistency
            StaticMarkerManager.getInstance().onMarkerTapFullScreen(marker)
            
            Log.d("MarkerPopupBinder", "✅ Marker tap forwarded to Flutter successfully")
            
        } catch (e: Exception) {
            Log.e("MarkerPopupBinder", "❌ Error forwarding marker tap to Flutter", e)
            e.printStackTrace()
        }
    }
    
    private fun showNativeToast(marker: StaticMarker) {
        try {
            val message = buildString {
                append("📍 ${marker.title}")
                if (!marker.description.isNullOrEmpty()) {
                    append("\n${marker.description}")
                }
                append("\nCategory: ${marker.category}")
            }
            
            // Show Toast notification that appears above navigation UI
            android.widget.Toast.makeText(
                activity,
                message,
                android.widget.Toast.LENGTH_LONG
            ).show()
            
            Log.d("MarkerPopupBinder", "🔔 Native Toast shown for: ${marker.title}")
            
        } catch (e: Exception) {
            Log.e("MarkerPopupBinder", "❌ Error showing native toast", e)
        }
    }
    
}