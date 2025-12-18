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

class DynamicMarkerEventStreamHandler: NSObject, FlutterStreamHandler {
    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        DynamicMarkerManager.shared.setEventSink(events)
        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        DynamicMarkerManager.shared.setEventSink(nil)
        return nil
    }
}

public class FlutterMapboxNavigationPlugin: NavigationFactory, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "flutter_mapbox_navigation", binaryMessenger: registrar.messenger())
    let eventChannel = FlutterEventChannel(name: "flutter_mapbox_navigation/events", binaryMessenger: registrar.messenger())
    let markerEventChannel = FlutterEventChannel(name: "flutter_mapbox_navigation/marker_events", binaryMessenger: registrar.messenger())
    let dynamicMarkerEventChannel = FlutterEventChannel(name: "flutter_mapbox_navigation/dynamic_marker_events", binaryMessenger: registrar.messenger())
    let instance = FlutterMapboxNavigationPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)

    eventChannel.setStreamHandler(instance)
    markerEventChannel.setStreamHandler(MarkerEventStreamHandler())
    dynamicMarkerEventChannel.setStreamHandler(DynamicMarkerEventStreamHandler())

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
        else if(call.method == "startFlutterNavigation" || call.method == "startFlutterStyledNavigation")
        {
            // Flutter-styled navigation (Drop-in UI) - same implementation as startNavigation
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
        // MARK: - Offline Routing Methods
        else if(call.method == "downloadOfflineRegion")
        {
            downloadOfflineRegion(arguments: arguments, result: result)
        }
        else if(call.method == "isOfflineRoutingAvailable")
        {
            isOfflineRoutingAvailable(arguments: arguments, result: result)
        }
        else if(call.method == "deleteOfflineRegion")
        {
            deleteOfflineRegion(arguments: arguments, result: result)
        }
        else if(call.method == "getOfflineCacheSize")
        {
            getOfflineCacheSize(result: result)
        }
        else if(call.method == "clearOfflineCache")
        {
            clearOfflineCache(result: result)
        }
        else if(call.method == "getOfflineRegionStatus")
        {
            getOfflineRegionStatus(arguments: arguments, result: result)
        }
        else if(call.method == "listOfflineRegions")
        {
            listOfflineRegions(result: result)
        }
        // MARK: - Dynamic Marker Methods
        else if(call.method == "addDynamicMarker")
        {
            addDynamicMarker(arguments: arguments, result: result)
        }
        else if(call.method == "addDynamicMarkers")
        {
            addDynamicMarkers(arguments: arguments, result: result)
        }
        else if(call.method == "updateDynamicMarkerPosition")
        {
            updateDynamicMarkerPosition(arguments: arguments, result: result)
        }
        else if(call.method == "batchUpdateDynamicMarkerPositions")
        {
            batchUpdateDynamicMarkerPositions(arguments: arguments, result: result)
        }
        else if(call.method == "updateDynamicMarker")
        {
            updateDynamicMarker(arguments: arguments, result: result)
        }
        else if(call.method == "removeDynamicMarker")
        {
            removeDynamicMarker(arguments: arguments, result: result)
        }
        else if(call.method == "removeDynamicMarkers")
        {
            removeDynamicMarkers(arguments: arguments, result: result)
        }
        else if(call.method == "clearAllDynamicMarkers")
        {
            clearAllDynamicMarkers(result: result)
        }
        else if(call.method == "getDynamicMarker")
        {
            getDynamicMarker(arguments: arguments, result: result)
        }
        else if(call.method == "getDynamicMarkers")
        {
            getDynamicMarkers(result: result)
        }
        else if(call.method == "updateDynamicMarkerConfiguration")
        {
            updateDynamicMarkerConfiguration(arguments: arguments, result: result)
        }
        else if(call.method == "clearDynamicMarkerTrail")
        {
            clearDynamicMarkerTrail(arguments: arguments, result: result)
        }
        else if(call.method == "clearAllDynamicMarkerTrails")
        {
            clearAllDynamicMarkerTrails(result: result)
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

    // MARK: - Dynamic Marker Methods

    private func addDynamicMarker(arguments: NSDictionary?, result: @escaping FlutterResult) {
        guard let args = arguments as? [String: Any],
              let markerJson = args["marker"] as? [String: Any],
              let marker = DynamicMarker.fromJson(markerJson) else {
            result(FlutterError(code: "INVALID_ARGUMENTS", message: "Marker data is required", details: nil))
            return
        }

        let success = DynamicMarkerManager.shared.addDynamicMarker(marker)
        result(success)
    }

    private func addDynamicMarkers(arguments: NSDictionary?, result: @escaping FlutterResult) {
        guard let args = arguments as? [String: Any],
              let markersList = args["markers"] as? [[String: Any]] else {
            result(FlutterError(code: "INVALID_ARGUMENTS", message: "Markers list is required", details: nil))
            return
        }

        let markers = markersList.compactMap { DynamicMarker.fromJson($0) }
        let success = DynamicMarkerManager.shared.addDynamicMarkers(markers)
        result(success)
    }

    private func updateDynamicMarkerPosition(arguments: NSDictionary?, result: @escaping FlutterResult) {
        guard let args = arguments as? [String: Any],
              let update = DynamicMarkerPositionUpdate.fromJson(args) else {
            result(FlutterError(code: "INVALID_ARGUMENTS", message: "Position update data is required", details: nil))
            return
        }

        let success = DynamicMarkerManager.shared.updateDynamicMarkerPosition(update)
        result(success)
    }

    private func batchUpdateDynamicMarkerPositions(arguments: NSDictionary?, result: @escaping FlutterResult) {
        guard let args = arguments as? [String: Any],
              let updatesList = args["updates"] as? [[String: Any]] else {
            result(FlutterError(code: "INVALID_ARGUMENTS", message: "Updates list is required", details: nil))
            return
        }

        let updates = updatesList.compactMap { DynamicMarkerPositionUpdate.fromJson($0) }
        let success = DynamicMarkerManager.shared.batchUpdateDynamicMarkerPositions(updates)
        result(success)
    }

    private func updateDynamicMarker(arguments: NSDictionary?, result: @escaping FlutterResult) {
        guard let args = arguments as? [String: Any],
              let markerId = args["markerId"] as? String else {
            result(FlutterError(code: "INVALID_ARGUMENTS", message: "Marker ID is required", details: nil))
            return
        }

        let success = DynamicMarkerManager.shared.updateDynamicMarker(
            markerId: markerId,
            title: args["title"] as? String,
            snippet: args["snippet"] as? String,
            iconId: args["iconId"] as? String,
            showTrail: args["showTrail"] as? Bool,
            metadata: args["metadata"] as? [String: Any]
        )
        result(success)
    }

    private func removeDynamicMarker(arguments: NSDictionary?, result: @escaping FlutterResult) {
        guard let args = arguments as? [String: Any],
              let markerId = args["markerId"] as? String else {
            result(FlutterError(code: "INVALID_ARGUMENTS", message: "Marker ID is required", details: nil))
            return
        }

        let success = DynamicMarkerManager.shared.removeDynamicMarker(markerId)
        result(success)
    }

    private func removeDynamicMarkers(arguments: NSDictionary?, result: @escaping FlutterResult) {
        guard let args = arguments as? [String: Any],
              let markerIds = args["markerIds"] as? [String] else {
            result(FlutterError(code: "INVALID_ARGUMENTS", message: "Marker IDs list is required", details: nil))
            return
        }

        let success = DynamicMarkerManager.shared.removeDynamicMarkers(markerIds)
        result(success)
    }

    private func clearAllDynamicMarkers(result: @escaping FlutterResult) {
        let success = DynamicMarkerManager.shared.clearAllDynamicMarkers()
        result(success)
    }

    private func getDynamicMarker(arguments: NSDictionary?, result: @escaping FlutterResult) {
        guard let args = arguments as? [String: Any],
              let markerId = args["markerId"] as? String else {
            result(FlutterError(code: "INVALID_ARGUMENTS", message: "Marker ID is required", details: nil))
            return
        }

        if let marker = DynamicMarkerManager.shared.getDynamicMarker(markerId) {
            result(marker.toJson())
        } else {
            result(nil)
        }
    }

    private func getDynamicMarkers(result: @escaping FlutterResult) {
        let markers = DynamicMarkerManager.shared.getDynamicMarkers()
        let markersJson = markers.map { $0.toJson() }
        result(markersJson)
    }

    private func updateDynamicMarkerConfiguration(arguments: NSDictionary?, result: @escaping FlutterResult) {
        guard let args = arguments as? [String: Any] else {
            result(FlutterError(code: "INVALID_ARGUMENTS", message: "Configuration is required", details: nil))
            return
        }

        let config = DynamicMarkerConfiguration.fromJson(args)
        let success = DynamicMarkerManager.shared.updateDynamicMarkerConfiguration(config)
        result(success)
    }

    private func clearDynamicMarkerTrail(arguments: NSDictionary?, result: @escaping FlutterResult) {
        guard let args = arguments as? [String: Any],
              let markerId = args["markerId"] as? String else {
            result(FlutterError(code: "INVALID_ARGUMENTS", message: "Marker ID is required", details: nil))
            return
        }

        let success = DynamicMarkerManager.shared.clearDynamicMarkerTrail(markerId)
        result(success)
    }

    private func clearAllDynamicMarkerTrails(result: @escaping FlutterResult) {
        let success = DynamicMarkerManager.shared.clearAllDynamicMarkerTrails()
        result(success)
    }

}
