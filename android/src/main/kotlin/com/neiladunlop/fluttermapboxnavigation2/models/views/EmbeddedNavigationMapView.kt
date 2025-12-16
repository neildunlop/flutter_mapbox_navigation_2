package com.neiladunlop.fluttermapboxnavigation2.models.views

import android.app.Activity
import android.content.Context
import android.view.View
import com.neiladunlop.fluttermapboxnavigation2.TurnByTurn
import com.neiladunlop.fluttermapboxnavigation2.databinding.NavigationActivityBinding
import com.neiladunlop.fluttermapboxnavigation2.models.MapBoxEvents
import com.neiladunlop.fluttermapboxnavigation2.utilities.PluginUtilities
import com.neiladunlop.fluttermapboxnavigation2.StaticMarkerManager
import com.neiladunlop.fluttermapboxnavigation2.DynamicMarkerManager
import com.mapbox.geojson.Point
import com.mapbox.maps.MapView
import com.mapbox.maps.plugin.gestures.OnMapClickListener
import com.mapbox.maps.plugin.gestures.gestures
import com.mapbox.navigation.dropin.map.MapViewObserver
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.platform.PlatformView
import org.json.JSONObject

class EmbeddedNavigationMapView(
    context: Context,
    activity: Activity,
    binding: NavigationActivityBinding,
    binaryMessenger: BinaryMessenger,
    vId: Int,
    args: Any?,
    accessToken: String
) : PlatformView, TurnByTurn(context, activity, binding, accessToken) {
    private val viewId: Int = vId
    private val messenger: BinaryMessenger = binaryMessenger
    private val arguments = args as Map<*, *>

    override fun initFlutterChannelHandlers() {
        methodChannel = MethodChannel(messenger, "flutter_mapbox_navigation/${viewId}")
        eventChannel = EventChannel(messenger, "flutter_mapbox_navigation/${viewId}/events")
        super.initFlutterChannelHandlers()
    }

    open fun initialize() {
        initFlutterChannelHandlers()
        initNavigation()

        val longPressEnabled = this.arguments?.get("longPressDestinationEnabled") as? Boolean ?: true
        if (!longPressEnabled) {
            this.binding.navigationView.customizeViewOptions {
                enableMapLongClickIntercept = false;
            }
        }

        val enableOnMapTap = this.arguments?.get("enableOnMapTapCallback") as? Boolean ?: false
        if (enableOnMapTap) {
            this.binding.navigationView.registerMapObserver(onMapClick)
        }

        // Register MapView observer for static markers
        this.binding.navigationView.registerMapObserver(staticMarkerMapObserver)
    }

    override fun getView(): View {
        return binding.root
    }

    override fun dispose() {
        val enableOnMapTap = this.arguments?.get("enableOnMapTapCallback") as? Boolean ?: false
        if (enableOnMapTap) {
            this.binding.navigationView.unregisterMapObserver(onMapClick)
        }
        
        // Unregister static marker map observer
        this.binding.navigationView.unregisterMapObserver(staticMarkerMapObserver)
        
        unregisterObservers()
    }

    /**
     * Notifies with attach and detach events on [MapView]
     */
    private val onMapClick = object : MapViewObserver(), OnMapClickListener {

        override fun onAttached(mapView: MapView) {
            mapView.gestures.addOnMapClickListener(this)
        }

        override fun onDetached(mapView: MapView) {
            mapView.gestures.removeOnMapClickListener(this)
        }

        override fun onMapClick(point: Point): Boolean {
            var waypoint = mapOf<String, String>(
                Pair("latitude", point.latitude().toString()),
                Pair("longitude", point.longitude().toString())
            )
            PluginUtilities.sendEvent(MapBoxEvents.ON_MAP_TAP, JSONObject(waypoint).toString())
            return false
        }
    }

    /**
     * MapView observer for static markers
     */
    private val staticMarkerMapObserver = object : MapViewObserver() {
        override fun onAttached(mapView: MapView) {
            println("🗺️ MapView attached in EmbeddedNavigationMapView")
            println("🔧 About to call StaticMarkerManager.getInstance().setMapView()")
            try {
                // Set the MapView in the StaticMarkerManager
                val manager = StaticMarkerManager.getInstance()
                println("🔧 StaticMarkerManager instance obtained: ${manager != null}")
                
                // Call the setMapView method
                manager.setMapView(mapView)
                println("🔧 setMapView() call completed")

                // Also set MapView for DynamicMarkerManager
                val dynamicManager = DynamicMarkerManager.getInstance()
                dynamicManager.setContext(mapView.context)
                dynamicManager.setMapView(mapView)
                println("🔧 DynamicMarkerManager.setContext() and setMapView() calls completed")

            } catch (e: Exception) {
                println("❌ Error calling setMapView(): ${e.message}")
                e.printStackTrace()
            }
        }

        override fun onDetached(mapView: MapView) {
            println("🗺️ MapView detached in EmbeddedNavigationMapView")
            try {
                // Clear the MapView in the StaticMarkerManager
                StaticMarkerManager.getInstance().setMapView(null)
                // Clear the MapView in the DynamicMarkerManager
                DynamicMarkerManager.getInstance().setMapView(null)
            } catch (e: Exception) {
                println("❌ Error calling setMapView(null): ${e.message}")
            }
        }
    }

}
