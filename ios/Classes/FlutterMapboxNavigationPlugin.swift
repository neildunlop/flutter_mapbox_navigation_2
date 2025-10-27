import Flutter
import UIKit
import MapboxMaps
import MapboxDirections
import MapboxCoreNavigation
import MapboxNavigation

class MarkerEventStreamHandler: NSObject, FlutterStreamHandler {
    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        StaticMarkerManager.shared.setEventSink(events)
        return nil
    }
    
    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        StaticMarkerManager.shared.setEventSink(nil)
        return nil
    }
}

public class FlutterMapboxNavigationPlugin: NavigationFactory, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "flutter_mapbox_navigation", binaryMessenger: registrar.messenger())
    let eventChannel = FlutterEventChannel(name: "flutter_mapbox_navigation/events", binaryMessenger: registrar.messenger())
    let markerEventChannel = FlutterEventChannel(name: "flutter_mapbox_navigation/marker_events", binaryMessenger: registrar.messenger())
    let instance = FlutterMapboxNavigationPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)

    // Set up StaticMarkerManager to use this NavigationFactory for sending route events
    StaticMarkerManager.shared.setNavigationFactory(instance)

    eventChannel.setStreamHandler(instance)
    markerEventChannel.setStreamHandler(MarkerEventStreamHandler())

    let viewFactory = FlutterMapboxNavigationViewFactory(messenger: registrar.messenger())
    registrar.register(viewFactory, withId: "FlutterMapboxNavigationView")

  }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {

        let arguments = call.arguments as? NSDictionary

        if(call.method == "getPlatformVersion")
        {
            result("iOS " + UIDevice.current.systemVersion)
        }
        else if(call.method == "getDistanceRemaining")
        {
            result(_distanceRemaining)
        }
        else if(call.method == "getDurationRemaining")
        {
            result(_durationRemaining)
        }
        else if(call.method == "startFreeDrive")
        {
            startFreeDrive(arguments: arguments, result: result)
        }
        else if(call.method == "startNavigation")
        {
            startNavigation(arguments: arguments, result: result)
        }
        else if(call.method == "addWayPoints")
        {
            addWayPoints(arguments: arguments, result: result)
        }
        else if(call.method == "finishNavigation")
        {
            endNavigation(result: result)
        }
        else if(call.method == "enableOfflineRouting")
        {
            downloadOfflineRoute(arguments: arguments, flutterResult: result)
        }
        else if(call.method == "addStaticMarkers")
        {
            addStaticMarkers(arguments: arguments, result: result)
        }
        else if(call.method == "removeStaticMarkers")
        {
            removeStaticMarkers(arguments: arguments, result: result)
        }
        else if(call.method == "clearAllStaticMarkers")
        {
            clearAllStaticMarkers(result: result)
        }
        else if(call.method == "updateMarkerConfiguration")
        {
            updateMarkerConfiguration(arguments: arguments, result: result)
        }
        else if(call.method == "getStaticMarkers")
        {
            getStaticMarkers(result: result)
        }
        else
        {
            result("Method is Not Implemented");
        }

    }
    
    // MARK: - Static Marker Methods
    
    private func addStaticMarkers(arguments: NSDictionary?, result: @escaping FlutterResult) {
        do {
            guard let args = arguments as? [String: Any],
                  let markersList = args["markers"] as? [[String: Any]] else {
                result(FlutterError(code: "INVALID_ARGUMENTS", message: "Markers list is required", details: nil))
                return
            }
            
            let configJson = args["configuration"] as? [String: Any]
            
            let markers = markersList.compactMap { markerJson in
                StaticMarker.fromJson(markerJson)
            }
            
            let config = configJson.map { MarkerConfiguration.fromJson($0) } ?? MarkerConfiguration()
            let success = StaticMarkerManager.shared.addStaticMarkers(markers, config: config)
            
            result(success)
        } catch {
            result(FlutterError(code: "ADD_MARKERS_ERROR", message: "Failed to add static markers: \(error.localizedDescription)", details: nil))
        }
    }
    
    private func removeStaticMarkers(arguments: NSDictionary?, result: @escaping FlutterResult) {
        do {
            guard let args = arguments as? [String: Any],
                  let markerIds = args["markerIds"] as? [String] else {
                result(FlutterError(code: "INVALID_ARGUMENTS", message: "Marker IDs list is required", details: nil))
                return
            }
            
            let success = StaticMarkerManager.shared.removeStaticMarkers(markerIds)
            result(success)
        } catch {
            result(FlutterError(code: "REMOVE_MARKERS_ERROR", message: "Failed to remove static markers: \(error.localizedDescription)", details: nil))
        }
    }
    
    private func clearAllStaticMarkers(result: @escaping FlutterResult) {
        do {
            let success = StaticMarkerManager.shared.clearAllStaticMarkers()
            result(success)
        } catch {
            result(FlutterError(code: "CLEAR_MARKERS_ERROR", message: "Failed to clear static markers: \(error.localizedDescription)", details: nil))
        }
    }
    
    private func updateMarkerConfiguration(arguments: NSDictionary?, result: @escaping FlutterResult) {
        do {
            guard let args = arguments as? [String: Any],
                  let configJson = args["configuration"] as? [String: Any] else {
                result(FlutterError(code: "INVALID_ARGUMENTS", message: "Configuration is required", details: nil))
                return
            }
            
            let config = MarkerConfiguration.fromJson(configJson)
            let success = StaticMarkerManager.shared.updateMarkerConfiguration(config)
            
            result(success)
        } catch {
            result(FlutterError(code: "UPDATE_CONFIG_ERROR", message: "Failed to update marker configuration: \(error.localizedDescription)", details: nil))
        }
    }
    
    private func getStaticMarkers(result: @escaping FlutterResult) {
        do {
            let markers = StaticMarkerManager.shared.getStaticMarkers()
            let markersJson = markers.map { $0.toJson() }
            result(markersJson)
        } catch {
            result(FlutterError(code: "GET_MARKERS_ERROR", message: "Failed to get static markers: \(error.localizedDescription)", details: nil))
        }
    }

}
