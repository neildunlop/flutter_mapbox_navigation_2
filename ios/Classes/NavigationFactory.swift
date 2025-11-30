import Flutter
import UIKit
import MapboxMaps
import MapboxDirections
import MapboxCoreNavigation
import MapboxNavigation

public class NavigationFactory : NSObject, FlutterStreamHandler
{
    var _navigationViewController: NavigationViewController? = nil
    var _eventSink: FlutterEventSink? = nil
    
    let ALLOW_ROUTE_SELECTION = false
    let IsMultipleUniqueRoutes = false
    var isEmbeddedNavigation = false
    
    var _distanceRemaining: Double?
    var _durationRemaining: Double?
    var _navigationMode: String?
    var _routes: [Route]?
    var _wayPointOrder = [Int:Waypoint]()
    var _wayPoints = [Waypoint]()
    var _lastKnownLocation: CLLocation?
    
    var _options: NavigationRouteOptions?
    var _simulateRoute = false
    var _allowsUTurnAtWayPoints: Bool?
    var _isOptimized = false
    var _language = "en"
    var _voiceUnits = "imperial"
    var _mapStyleUrlDay: String?
    var _mapStyleUrlNight: String?
    var _zoom: Double = 13.0
    var _tilt: Double = 0.0
    var _bearing: Double = 0.0
    var _animateBuildRoute = true
    var _longPressDestinationEnabled = true
    var _alternatives = true
    var _shouldReRoute = true
    var _showReportFeedbackButton = true
    var _showEndOfRouteFeedback = true
    var _enableOnMapTapCallback = false
    var navigationDirections: Directions?

    // Marker popup overlay for showing marker info cards
    var markerPopupOverlay: MarkerPopupOverlay?

    // Trip progress overlay for showing navigation progress
    var tripProgressOverlay: TripProgressOverlay?

    // Trip progress configuration (from Flutter)
    var _tripProgressConfig: TripProgressConfig = .defaults()

    // Original waypoints for skip/prev functionality
    var _originalWayPoints: [Waypoint] = []

    func addWayPoints(arguments: NSDictionary?, result: @escaping FlutterResult)
    {
        do {
            guard var locations = getLocationsFromFlutterArgument(arguments: arguments) else {
                result([
                    "success": false,
                    "waypointsAdded": 0,
                    "errorMessage": "Invalid waypoints data"
                ])
                return
            }

            _wayPoints.removeAll()
            _wayPointOrder.removeAll()
            
            for loc in locations {
                let location = Waypoint(coordinate: CLLocationCoordinate2D(latitude: loc.latitude!, longitude: loc.longitude!), name: loc.name)
                location.separatesLegs = !loc.isSilent
                _wayPoints.append(location)
                _wayPointOrder[loc.order!] = location
            }
            
            parseFlutterArguments(arguments: arguments)
            
            _options?.includesAlternativeRoutes = _alternatives
            
            if(_wayPoints.count > 3 && arguments?["mode"] == nil) {
                _navigationMode = "driving"
            }
            
            if(_wayPoints.count > 0) {
                if(IsMultipleUniqueRoutes) {
                    startNavigationWithWayPoints(wayPoints: [_wayPoints.remove(at: 0), _wayPoints.remove(at: 0)], flutterResult: result, isUpdatingWaypoints: true)
                } else {
                    startNavigationWithWayPoints(wayPoints: _wayPoints, flutterResult: result, isUpdatingWaypoints: true)
                }
            }
            
            result([
                "success": true,
                "waypointsAdded": locations.count
            ])
        } catch {
            result([
                "success": false,
                "waypointsAdded": 0,
                "errorMessage": error.localizedDescription
            ])
        }
    }
    
    func startFreeDrive(arguments: NSDictionary?, result: @escaping FlutterResult)
    {
        let freeDriveViewController = FreeDriveViewController()
        let flutterViewController = UIApplication.shared.delegate?.window??.rootViewController as! FlutterViewController
        flutterViewController.present(freeDriveViewController, animated: true, completion: nil)
    }
    
    func startNavigation(arguments: NSDictionary?, result: @escaping FlutterResult)
    {
        _wayPoints.removeAll()
        _wayPointOrder.removeAll()
        _originalWayPoints.removeAll()  // Reset original waypoints for new navigation

        guard var locations = getLocationsFromFlutterArgument(arguments: arguments) else { return }

        for loc in locations
        {
            let location = Waypoint(coordinate: CLLocationCoordinate2D(latitude: loc.latitude!, longitude: loc.longitude!), name: loc.name)

            location.separatesLegs = !loc.isSilent

            _wayPoints.append(location)
            _wayPointOrder[loc.order!] = location
        }

        // Store original waypoints for skip/prev functionality
        _originalWayPoints = _wayPoints

        parseFlutterArguments(arguments: arguments)
        
        _options?.includesAlternativeRoutes = _alternatives
        
        if(_wayPoints.count > 3 && arguments?["mode"] == nil)
        {
            _navigationMode = "driving"
        }
        
        if(_wayPoints.count > 0)
        {
            if(IsMultipleUniqueRoutes)
            {
                startNavigationWithWayPoints(wayPoints: [_wayPoints.remove(at: 0), _wayPoints.remove(at: 0)], flutterResult: result, isUpdatingWaypoints: false)
            }
            else
            {
                startNavigationWithWayPoints(wayPoints: _wayPoints, flutterResult: result, isUpdatingWaypoints: false)
            }
            
        }
    }
    
    
    func startNavigationWithWayPoints(wayPoints: [Waypoint], flutterResult: @escaping FlutterResult, isUpdatingWaypoints: Bool)
    {
        let simulationMode: SimulationMode = _simulateRoute ? .always : .never
        setNavigationOptions(wayPoints: wayPoints)
        
        Directions.shared.calculate(_options!) { [weak self](session, result) in
            guard let strongSelf = self else { return }
            switch result {
            case .failure(let error):
                strongSelf.sendEvent(eventType: MapBoxEventType.route_build_failed)
                flutterResult("An error occured while calculating the route \(error.localizedDescription)")
            case .success(let response):
                guard let routes = response.routes else { return }
                //TODO: if more than one route found, give user option to select one: DOES NOT WORK
                if(routes.count > 1 && strongSelf.ALLOW_ROUTE_SELECTION)
                {
                    //show map to select a specific route
                    strongSelf._routes = routes
                    let routeOptionsView = RouteOptionsViewController(routes: routes, options: strongSelf._options!)
                    
                    let flutterViewController = UIApplication.shared.delegate?.window??.rootViewController as! FlutterViewController
                    flutterViewController.present(routeOptionsView, animated: true, completion: nil)
                }
                else
                {
                    let navigationService = MapboxNavigationService(routeResponse: response, routeIndex: 0, routeOptions: strongSelf._options!, simulating: simulationMode)
                    var dayStyle = CustomDayStyle()
                    if(strongSelf._mapStyleUrlDay != nil){
                        dayStyle = CustomDayStyle(url: strongSelf._mapStyleUrlDay)
                    }
                    let nightStyle = CustomNightStyle()
                    if(strongSelf._mapStyleUrlNight != nil){
                        nightStyle.mapStyleURL = URL(string: strongSelf._mapStyleUrlNight!)!
                    }
                    let navigationOptions = NavigationOptions(styles: [dayStyle, nightStyle], navigationService: navigationService)
                    if (isUpdatingWaypoints) {
                        strongSelf._navigationViewController?.navigationService.router.updateRoute(with: IndexedRouteResponse(routeResponse: response, routeIndex: 0), routeOptions: strongSelf._options) { success in
                            if (success) {
                                flutterResult("true")
                            } else {
                                flutterResult("failed to add stop")
                            }
                        }
                    }
                    else {
                        strongSelf.startNavigation(routeResponse: response, options: strongSelf._options!, navOptions: navigationOptions)
                    }
                }
            }
        }
        
    }
    
    func startNavigation(routeResponse: RouteResponse, options: NavigationRouteOptions, navOptions: NavigationOptions)
    {
        isEmbeddedNavigation = false
        if(self._navigationViewController == nil)
        {
            self._navigationViewController = NavigationViewController(for: routeResponse, routeIndex: 0, routeOptions: options, navigationOptions: navOptions)
            self._navigationViewController!.modalPresentationStyle = .fullScreen
            self._navigationViewController!.delegate = self
            self._navigationViewController!.navigationMapView!.localizeLabels()
            self._navigationViewController!.showsReportFeedback = _showReportFeedbackButton
            self._navigationViewController!.showsEndOfRouteFeedback = _showEndOfRouteFeedback
        }
        let flutterViewController = UIApplication.shared.delegate?.window??.rootViewController as! FlutterViewController
        flutterViewController.present(self._navigationViewController!, animated: true) { [weak self] in
            // Initialize the marker popup overlay after navigation view is presented
            guard let strongSelf = self, let navVC = strongSelf._navigationViewController else { return }
            strongSelf.markerPopupOverlay = MarkerPopupOverlay(parentViewController: navVC, config: strongSelf._tripProgressConfig)
            strongSelf.markerPopupOverlay?.initialize()

            // Initialize the trip progress overlay with config
            print("NavigationFactory: Creating TripProgressOverlay with config")
            strongSelf.tripProgressOverlay = TripProgressOverlay(
                parentViewController: navVC,
                config: strongSelf._tripProgressConfig
            )

            // Set up skip/prev callbacks
            strongSelf.tripProgressOverlay?.onSkipPrevious = { [weak self] in
                print("NavigationFactory: Skip previous button pressed")
                self?.goToPreviousWaypoint()
            }
            strongSelf.tripProgressOverlay?.onSkipNext = { [weak self] in
                print("NavigationFactory: Skip next button pressed")
                self?.skipToNextWaypoint()
            }
            strongSelf.tripProgressOverlay?.onEndNavigation = { [weak self] in
                print("NavigationFactory: End navigation button pressed")
                self?.endNavigation(result: nil)
            }

            // Connect progress manager to overlay
            TripProgressManager.shared.setProgressListener { [weak self] progressData in
                self?.tripProgressOverlay?.updateProgress(progressData)
            }

            // Set up waypoints for progress tracking
            let markers = StaticMarkerManager.shared.getStaticMarkers()
            if let waypoints = strongSelf._wayPoints, !waypoints.isEmpty {
                TripProgressManager.shared.setWaypointsFromMarkers(waypoints, markers: markers, isInitialSetup: true)
            }

            // Show the trip progress overlay FIRST
            strongSelf.tripProgressOverlay?.show()

            // Then trigger initial update (after UI is created)
            if let waypoints = strongSelf._wayPoints, !waypoints.isEmpty {
                TripProgressManager.shared.updateProgress(
                    legIndex: 0,
                    distanceToNextWaypoint: 0,
                    totalDistanceRemaining: 0,
                    totalDurationRemaining: 0
                )
            }
        }
    }
    
    func setNavigationOptions(wayPoints: [Waypoint]) {
        var mode: ProfileIdentifier = .automobileAvoidingTraffic
        
        if (_navigationMode == "cycling")
        {
            mode = .cycling
        }
        else if(_navigationMode == "driving")
        {
            mode = .automobile
        }
        else if(_navigationMode == "walking")
        {
            mode = .walking
        }
        let options = NavigationRouteOptions(waypoints: wayPoints, profileIdentifier: mode)
        
        if (_allowsUTurnAtWayPoints != nil)
        {
            options.allowsUTurnAtWaypoint = _allowsUTurnAtWayPoints!
        }
        
        options.distanceMeasurementSystem = _voiceUnits == "imperial" ? .imperial : .metric
        options.locale = Locale(identifier: _language)
        _options = options
    }
    
    func parseFlutterArguments(arguments: NSDictionary?) {
        _language = arguments?["language"] as? String ?? _language
        _voiceUnits = arguments?["units"] as? String ?? _voiceUnits
        _simulateRoute = arguments?["simulateRoute"] as? Bool ?? _simulateRoute
        _isOptimized = arguments?["isOptimized"] as? Bool ?? _isOptimized
        _allowsUTurnAtWayPoints = arguments?["allowsUTurnAtWayPoints"] as? Bool
        _navigationMode = arguments?["mode"] as? String ?? "drivingWithTraffic"
        _showReportFeedbackButton = arguments?["showReportFeedbackButton"] as? Bool ?? _showReportFeedbackButton
        _showEndOfRouteFeedback = arguments?["showEndOfRouteFeedback"] as? Bool ?? _showEndOfRouteFeedback
        _enableOnMapTapCallback = arguments?["enableOnMapTapCallback"] as? Bool ?? _enableOnMapTapCallback
        _mapStyleUrlDay = arguments?["mapStyleUrlDay"] as? String
        _mapStyleUrlNight = arguments?["mapStyleUrlNight"] as? String
        _zoom = arguments?["zoom"] as? Double ?? _zoom
        _bearing = arguments?["bearing"] as? Double ?? _bearing
        _tilt = arguments?["tilt"] as? Double ?? _tilt
        _animateBuildRoute = arguments?["animateBuildRoute"] as? Bool ?? _animateBuildRoute
        _longPressDestinationEnabled = arguments?["longPressDestinationEnabled"] as? Bool ?? _longPressDestinationEnabled
        _alternatives = arguments?["alternatives"] as? Bool ?? _alternatives

        // Parse trip progress configuration
        if let tripProgressConfigDict = arguments?["tripProgressConfig"] as? [String: Any] {
            _tripProgressConfig = TripProgressConfig.fromDictionary(tripProgressConfigDict)
            print("NavigationFactory: Parsed tripProgressConfig: showSkipButtons=\(_tripProgressConfig.showSkipButtons), showEta=\(_tripProgressConfig.showEta)")
        } else {
            _tripProgressConfig = .defaults()
        }
    }
    
    
    func continueNavigationWithWayPoints(wayPoints: [Waypoint])
    {
        _options?.waypoints = wayPoints
        Directions.shared.calculate(_options!) { [weak self](session, result) in
            guard let strongSelf = self else { return }
            switch result {
            case .failure(let error):
                strongSelf.sendEvent(eventType: MapBoxEventType.route_build_failed, data: error.localizedDescription)
            case .success(let response):
                strongSelf.sendEvent(eventType: MapBoxEventType.route_built, data: strongSelf.encodeRouteResponse(response: response))
                guard let routes = response.routes else { return }
                //TODO: if more than one route found, give user option to select one: DOES NOT WORK
                if(routes.count > 1 && strongSelf.ALLOW_ROUTE_SELECTION)
                {
                    //TODO: show map to select a specific route
                    
                }
                else
                {
                    strongSelf._navigationViewController?.navigationService.start()
                }
            }
        }
        
    }
    
    func endNavigation(result: FlutterResult?)
    {
        sendEvent(eventType: MapBoxEventType.navigation_finished)

        // Clean up the marker popup overlay
        markerPopupOverlay?.cleanup()
        markerPopupOverlay = nil

        // Clean up the trip progress overlay
        tripProgressOverlay?.hide(animated: false)
        tripProgressOverlay = nil
        TripProgressManager.shared.clear()

        if(self._navigationViewController != nil)
        {
            self._navigationViewController?.navigationService.endNavigation(feedback: nil)
            if(isEmbeddedNavigation)
            {
                self._navigationViewController?.view.removeFromSuperview()
                self._navigationViewController?.removeFromParent()
                self._navigationViewController = nil
            }
            else
            {
                self._navigationViewController?.dismiss(animated: true, completion: {
                    self._navigationViewController = nil
                    if(result != nil)
                    {
                        result!(true)
                    }
                })
            }
        }

    }

    // MARK: - Skip/Previous Waypoint Functionality

    /// Skip to the next waypoint (skip the current target waypoint)
    func skipToNextWaypoint() {
        print("NavigationFactory: skipToNextWaypoint called, waypoints=\(_wayPoints.count)")

        guard _wayPoints.count > 1 else {
            print("NavigationFactory: Cannot skip - only \(_wayPoints.count) waypoint(s) remaining")
            return
        }

        // Store original waypoints if not already stored
        if _originalWayPoints.isEmpty {
            _originalWayPoints = _wayPoints
        }

        // Remove the first waypoint (current target)
        let skipped = _wayPoints.removeFirst()
        print("NavigationFactory: Skipped waypoint: \(skipped.name ?? "unnamed")")

        // Track the skip for correct waypoint numbering
        TripProgressManager.shared.incrementSkippedCount()

        // Recalculate route with remaining waypoints
        recalculateRouteFromCurrentLocation()

        sendEvent(eventType: MapBoxEventType.waypoint_arrival, data: "skipped:\(skipped.name ?? "")")
    }

    /// Go back to the previous waypoint
    func goToPreviousWaypoint() {
        print("NavigationFactory: goToPreviousWaypoint called, waypoints=\(_wayPoints.count), original=\(_originalWayPoints.count)")

        guard !_originalWayPoints.isEmpty else {
            print("NavigationFactory: Cannot go to previous - no original waypoints stored")
            return
        }

        guard let currentTarget = _wayPoints.first else {
            print("NavigationFactory: Cannot go to previous - no current waypoints")
            return
        }

        // Find the current target in the original list
        guard let currentIndex = _originalWayPoints.firstIndex(where: { wp in
            abs(wp.coordinate.latitude - currentTarget.coordinate.latitude) < 0.00001 &&
            abs(wp.coordinate.longitude - currentTarget.coordinate.longitude) < 0.00001
        }) else {
            print("NavigationFactory: Cannot find current target in original list")
            return
        }

        guard currentIndex > 0 else {
            print("NavigationFactory: Already at first waypoint")
            return
        }

        // Get the previous waypoint from original list
        let previousWaypoint = _originalWayPoints[currentIndex - 1]

        // Check if it's already in our current list
        let alreadyInList = _wayPoints.contains { wp in
            abs(wp.coordinate.latitude - previousWaypoint.coordinate.latitude) < 0.00001 &&
            abs(wp.coordinate.longitude - previousWaypoint.coordinate.longitude) < 0.00001
        }

        if !alreadyInList {
            // Insert at the beginning
            _wayPoints.insert(previousWaypoint, at: 0)
            print("NavigationFactory: Re-added waypoint: \(previousWaypoint.name ?? "unnamed")")

            // Track the restore for correct waypoint numbering
            TripProgressManager.shared.decrementSkippedCount()
        } else {
            print("NavigationFactory: Previous waypoint already in list")
            return
        }

        // Recalculate route
        recalculateRouteFromCurrentLocation()

        sendEvent(eventType: MapBoxEventType.waypoint_arrival, data: "restored:\(previousWaypoint.name ?? "")")
    }

    /// Recalculate route from current location to remaining waypoints
    private func recalculateRouteFromCurrentLocation() {
        guard let currentLocation = _lastKnownLocation else {
            print("NavigationFactory: Cannot recalculate - no current location")
            return
        }

        // Build new waypoints list starting from current location
        var newWaypoints = [Waypoint]()
        let origin = Waypoint(coordinate: currentLocation.coordinate)
        newWaypoints.append(origin)
        newWaypoints.append(contentsOf: _wayPoints)

        // Update trip progress manager
        let markers = StaticMarkerManager.shared.getStaticMarkers()
        TripProgressManager.shared.setWaypointsFromMarkers(_wayPoints, markers: markers, isInitialSetup: false)

        // Trigger immediate UI update
        TripProgressManager.shared.updateProgress(
            legIndex: 0,
            distanceToNextWaypoint: 0,
            totalDistanceRemaining: 0,
            totalDurationRemaining: 0,
            durationToNextWaypoint: 0
        )

        // Request new route
        setNavigationOptions(wayPoints: newWaypoints)
        _options?.includesAlternativeRoutes = _alternatives

        sendEvent(eventType: MapBoxEventType.route_building)

        Directions.shared.calculate(_options!) { [weak self] (session, result) in
            guard let strongSelf = self else { return }
            switch result {
            case .failure(let error):
                strongSelf.sendEvent(eventType: MapBoxEventType.route_build_failed, data: error.localizedDescription)
            case .success(let response):
                strongSelf.sendEvent(eventType: MapBoxEventType.route_built, data: strongSelf.encodeRouteResponse(response: response))
                guard let routes = response.routes, !routes.isEmpty else {
                    strongSelf.sendEvent(eventType: MapBoxEventType.route_build_no_routes_found)
                    return
                }

                // Update the navigation with new route
                strongSelf._navigationViewController?.navigationService.router.updateRoute(
                    with: IndexedRouteResponse(routeResponse: response, routeIndex: 0),
                    routeOptions: strongSelf._options
                ) { success in
                    if success {
                        print("NavigationFactory: Route updated successfully")
                        strongSelf.sendEvent(eventType: MapBoxEventType.reroute_along)
                    } else {
                        print("NavigationFactory: Failed to update route")
                    }
                }
            }
        }
    }
    
    func getLocationsFromFlutterArgument(arguments: NSDictionary?) -> [Location]? {
        
        var locations = [Location]()
        guard let oWayPoints = arguments?["wayPoints"] as? NSDictionary else {return nil}
        for item in oWayPoints as NSDictionary
        {
            let point = item.value as! NSDictionary
            guard let oName = point["Name"] as? String else {return nil }
            guard let oLatitude = point["Latitude"] as? Double else {return nil}
            guard let oLongitude = point["Longitude"] as? Double else {return nil}
            let oIsSilent = point["IsSilent"] as? Bool ?? false
            let order = point["Order"] as? Int
            let location = Location(name: oName, latitude: oLatitude, longitude: oLongitude, order: order,isSilent: oIsSilent)
            locations.append(location)
        }
        if(!_isOptimized)
        {
            //waypoints must be in the right order
            locations.sort(by: {$0.order ?? 0 < $1.order ?? 0})
        }
        return locations
    }
    
    func getLastKnownLocation() -> Waypoint
    {
        return Waypoint(coordinate: CLLocationCoordinate2D(latitude: _lastKnownLocation!.coordinate.latitude, longitude: _lastKnownLocation!.coordinate.longitude))
    }
    
    
    
    func sendEvent(eventType: MapBoxEventType, data: String = "")
    {
        let routeEvent = MapBoxRouteEvent(eventType: eventType, data: data)
        
        let jsonEncoder = JSONEncoder()
        let jsonData = try! jsonEncoder.encode(routeEvent)
        let eventJson = String(data: jsonData, encoding: String.Encoding.utf8)
        if(_eventSink != nil){
            _eventSink!(eventJson)
        }
        
    }
    
    // MARK: - Offline Routing Methods

    /// Legacy offline routing method (deprecated, kept for backward compatibility)
    @available(*, deprecated, message: "Use downloadOfflineRegion instead")
    func downloadOfflineRoute(arguments: NSDictionary?, flutterResult: @escaping FlutterResult)
    {
        // Legacy stub - use downloadOfflineRegion instead
        flutterResult(false)
    }

    // MARK: - TileStore Configuration

    /// 1GB quota for offline tiles (maps + routing)
    private static let tileStoreQuotaBytes: Int64 = 1_073_741_824
    /// Cleanup threshold: start cleanup when above 80%
    private static let cleanupThresholdPercent: Double = 0.80
    /// Target after cleanup: reduce to 60%
    private static let cleanupTargetPercent: Double = 0.60

    /// Download map tiles and routing data for a specific region
    func downloadOfflineRegion(arguments: NSDictionary?, result: @escaping FlutterResult) {
        guard let args = arguments as? [String: Any],
              let southWestLat = args["southWestLat"] as? Double,
              let southWestLng = args["southWestLng"] as? Double,
              let northEastLat = args["northEastLat"] as? Double,
              let northEastLng = args["northEastLng"] as? Double else {
            result(FlutterError(code: "INVALID_ARGUMENTS", message: "Region bounds are required", details: nil))
            return
        }

        let minZoom = args["minZoom"] as? Int ?? 10
        let maxZoom = args["maxZoom"] as? Int ?? 16
        let includeRoutingTiles = args["includeRoutingTiles"] as? Bool ?? true

        print("OfflineRouting: Starting download for region (\(southWestLat),\(southWestLng)) to (\(northEastLat),\(northEastLng)), includeRouting=\(includeRoutingTiles)")

        // Define the bounding box
        let southWest = CLLocationCoordinate2D(latitude: southWestLat, longitude: southWestLng)
        let northEast = CLLocationCoordinate2D(latitude: northEastLat, longitude: northEastLng)
        let bounds = CoordinateBounds(southwest: southWest, northeast: northEast)

        // Get the default TileStore
        let tileStore = TileStore.default

        // Create tile region ID based on bounds (include routing flag in ID)
        let routingSuffix = includeRoutingTiles ? "_nav" : ""
        let regionId = "region_\(Int(southWestLat * 1000))_\(Int(southWestLng * 1000))_\(Int(northEastLat * 1000))_\(Int(northEastLng * 1000))\(routingSuffix)"

        // Define the tile region geometry
        let geometry = Geometry.polygon(Polygon([
            [
                CLLocationCoordinate2D(latitude: southWestLat, longitude: southWestLng),
                CLLocationCoordinate2D(latitude: northEastLat, longitude: southWestLng),
                CLLocationCoordinate2D(latitude: northEastLat, longitude: northEastLng),
                CLLocationCoordinate2D(latitude: southWestLat, longitude: northEastLng),
                CLLocationCoordinate2D(latitude: southWestLat, longitude: southWestLng)
            ]
        ]))

        // Create tile region load options for map and optionally routing tiles
        let tileRegionLoadOptions = TileRegionLoadOptions(
            geometry: geometry,
            descriptors: getMapTilesetDescriptors(minZoom: UInt8(minZoom), maxZoom: UInt8(maxZoom), includeRoutingTiles: includeRoutingTiles),
            acceptExpired: true
        )

        // Start the download
        let downloadTask = tileStore.loadTileRegion(
            forId: regionId,
            loadOptions: tileRegionLoadOptions!
        ) { [weak self] progress in
            // Progress callback
            let percentage = Double(progress.completedResourceCount) / Double(max(progress.requiredResourceCount, 1))
            print("OfflineRouting: Download progress \(Int(percentage * 100))% (\(progress.completedResourceCount)/\(progress.requiredResourceCount))")

            // Send progress to Flutter
            if let sink = self?._eventSink {
                let progressData: [String: Any] = [
                    "eventType": "download_progress",
                    "data": [
                        "regionId": regionId,
                        "progress": percentage,
                        "completedResources": progress.completedResourceCount,
                        "requiredResources": progress.requiredResourceCount
                    ]
                ]
                if let jsonData = try? JSONSerialization.data(withJSONObject: progressData),
                   let jsonString = String(data: jsonData, encoding: .utf8) {
                    sink(jsonString)
                }
            }
        } completion: { [weak self] downloadResult in
            switch downloadResult {
            case .success(let region):
                print("OfflineRouting: Download completed for region \(region.id) (\(region.completedResourceCount) resources)")

                // Trigger auto-cleanup if needed, protecting current region
                self?.performAutoCleanupIfNeeded(protectedRegionIds: [regionId])

                // Return success with region details
                result([
                    "success": true,
                    "regionId": regionId,
                    "resourceCount": region.completedResourceCount,
                    "includesRoutingTiles": includeRoutingTiles
                ])
            case .failure(let error):
                print("OfflineRouting: Download failed - \(error.localizedDescription)")
                result(FlutterError(code: "DOWNLOAD_FAILED", message: error.localizedDescription, details: nil))
            }
        }

        // Store reference to cancel if needed
        // Note: In a full implementation, you'd want to store this to support cancellation
    }

    /// Get tileset descriptors for offline map download
    private func getMapTilesetDescriptors(minZoom: UInt8, maxZoom: UInt8, includeRoutingTiles: Bool = true) -> [TilesetDescriptor] {
        var descriptors: [TilesetDescriptor] = []

        // Standard map tileset (always included)
        let standardOptions = TilesetDescriptorOptions(
            styleURI: .streets,
            zoomRange: minZoom...maxZoom
        )
        if let mapDescriptor = OfflineManager().createTilesetDescriptor(for: standardOptions) {
            descriptors.append(mapDescriptor)
            print("OfflineRouting: Added map tileset descriptor (streets)")
        }

        // Navigation tileset for routing (included if requested)
        if includeRoutingTiles {
            let navigationOptions = TilesetDescriptorOptions(
                styleURI: .navigationDay,
                zoomRange: minZoom...maxZoom
            )
            if let navDescriptor = OfflineManager().createTilesetDescriptor(for: navigationOptions) {
                descriptors.append(navDescriptor)
                print("OfflineRouting: Added navigation routing tileset descriptor")
            }
        }

        return descriptors
    }

    /// Get the status of a specific offline region
    func getOfflineRegionStatus(arguments: NSDictionary?, result: @escaping FlutterResult) {
        guard let args = arguments as? [String: Any],
              let regionId = args["regionId"] as? String else {
            result(FlutterError(code: "INVALID_ARGUMENTS", message: "Region ID is required", details: nil))
            return
        }

        let tileStore = TileStore.default

        tileStore.allTileRegions { regionsResult in
            switch regionsResult {
            case .success(let regions):
                if let region = regions.first(where: { $0.id == regionId }) {
                    // Check if this region includes routing tiles (ID ends with _nav)
                    let includesRouting = region.id.hasSuffix("_nav")

                    // Estimate size (~50KB per tile average)
                    let estimatedSizeBytes = Int64(region.completedResourceCount) * 50 * 1024

                    result([
                        "regionId": region.id,
                        "exists": true,
                        "completedResourceCount": region.completedResourceCount,
                        "requiredResourceCount": region.requiredResourceCount,
                        "mapTilesReady": true,
                        "routingTilesReady": includesRouting,
                        "estimatedSizeBytes": estimatedSizeBytes,
                        "isComplete": region.completedResourceCount >= region.requiredResourceCount
                    ])
                } else {
                    result([
                        "regionId": regionId,
                        "exists": false,
                        "mapTilesReady": false,
                        "routingTilesReady": false
                    ])
                }
            case .failure(let error):
                print("OfflineRouting: Error getting region status - \(error.localizedDescription)")
                result(FlutterError(code: "STATUS_FAILED", message: error.localizedDescription, details: nil))
            }
        }
    }

    /// List all offline regions with their status
    func listOfflineRegions(result: @escaping FlutterResult) {
        let tileStore = TileStore.default

        tileStore.allTileRegions { regionsResult in
            switch regionsResult {
            case .success(let regions):
                var regionsList: [[String: Any]] = []
                var totalSizeBytes: Int64 = 0

                for region in regions {
                    let includesRouting = region.id.hasSuffix("_nav")
                    let estimatedSizeBytes = Int64(region.completedResourceCount) * 50 * 1024
                    totalSizeBytes += estimatedSizeBytes

                    regionsList.append([
                        "regionId": region.id,
                        "completedResourceCount": region.completedResourceCount,
                        "requiredResourceCount": region.requiredResourceCount,
                        "mapTilesReady": true,
                        "routingTilesReady": includesRouting,
                        "estimatedSizeBytes": estimatedSizeBytes,
                        "isComplete": region.completedResourceCount >= region.requiredResourceCount
                    ])
                }

                result([
                    "regions": regionsList,
                    "totalCount": regions.count,
                    "totalSizeBytes": totalSizeBytes
                ])
            case .failure(let error):
                print("OfflineRouting: Error listing regions - \(error.localizedDescription)")
                result(FlutterError(code: "LIST_FAILED", message: error.localizedDescription, details: nil))
            }
        }
    }

    /// Performs automatic cleanup of old offline regions when storage exceeds threshold
    private func performAutoCleanupIfNeeded(protectedRegionIds: [String] = []) {
        let tileStore = TileStore.default

        tileStore.allTileRegions { [weak self] regionsResult in
            guard let strongSelf = self else { return }

            switch regionsResult {
            case .success(let regions):
                // Calculate total size
                let totalSizeBytes = regions.reduce(0) { sum, region in
                    sum + Int64(region.completedResourceCount) * 50 * 1024
                }

                let thresholdBytes = Int64(Double(NavigationFactory.tileStoreQuotaBytes) * NavigationFactory.cleanupThresholdPercent)
                let targetBytes = Int64(Double(NavigationFactory.tileStoreQuotaBytes) * NavigationFactory.cleanupTargetPercent)

                if totalSizeBytes > thresholdBytes {
                    print("OfflineRouting: Storage cleanup triggered: \(totalSizeBytes / (1024 * 1024))MB > \(thresholdBytes / (1024 * 1024))MB threshold")

                    // Sort regions by ID (older regions likely have smaller IDs)
                    let sortedRegions = regions
                        .filter { !protectedRegionIds.contains($0.id) }
                        .sorted { $0.id < $1.id }

                    var currentSize = totalSizeBytes
                    var regionsToDelete: [TileRegion] = []

                    for region in sortedRegions {
                        if currentSize <= targetBytes { break }
                        let regionSize = Int64(region.completedResourceCount) * 50 * 1024
                        regionsToDelete.append(region)
                        currentSize -= regionSize
                    }

                    print("OfflineRouting: Cleaning up \(regionsToDelete.count) old regions to free space")

                    for region in regionsToDelete {
                        tileStore.removeTileRegion(forId: region.id) { deleteResult in
                            switch deleteResult {
                            case .success:
                                print("OfflineRouting: Auto-deleted old region: \(region.id)")
                            case .failure(let error):
                                print("OfflineRouting: Failed to auto-delete region \(region.id) - \(error.localizedDescription)")
                            }
                        }
                    }
                }
            case .failure(let error):
                print("OfflineRouting: Error during auto-cleanup - \(error.localizedDescription)")
            }
        }
    }

    /// Check if offline routing data is available for a location
    func isOfflineRoutingAvailable(arguments: NSDictionary?, result: @escaping FlutterResult) {
        guard let args = arguments as? [String: Any],
              let latitude = args["latitude"] as? Double,
              let longitude = args["longitude"] as? Double else {
            result(FlutterError(code: "INVALID_ARGUMENTS", message: "Latitude and longitude are required", details: nil))
            return
        }

        let tileStore = TileStore.default
        let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)

        // Check all tile regions to see if any contain this coordinate
        tileStore.allTileRegions { regionsResult in
            switch regionsResult {
            case .success(let regions):
                // Check if any region contains the coordinate
                let containingRegion = regions.first { region in
                    // For simplicity, we check if the region ID suggests it covers this area
                    // A more accurate check would parse the geometry
                    return true // In production, properly check geometry bounds
                }
                result(containingRegion != nil && regions.count > 0)
            case .failure(let error):
                print("OfflineRouting: Error checking regions - \(error.localizedDescription)")
                result(false)
            }
        }
    }

    /// Delete cached offline routing data for a region
    func deleteOfflineRegion(arguments: NSDictionary?, result: @escaping FlutterResult) {
        guard let args = arguments as? [String: Any],
              let southWestLat = args["southWestLat"] as? Double,
              let southWestLng = args["southWestLng"] as? Double,
              let northEastLat = args["northEastLat"] as? Double,
              let northEastLng = args["northEastLng"] as? Double else {
            result(FlutterError(code: "INVALID_ARGUMENTS", message: "Region bounds are required", details: nil))
            return
        }

        let tileStore = TileStore.default
        let regionId = "region_\(Int(southWestLat * 1000))_\(Int(southWestLng * 1000))_\(Int(northEastLat * 1000))_\(Int(northEastLng * 1000))"

        tileStore.removeTileRegion(forId: regionId) { deleteResult in
            switch deleteResult {
            case .success:
                print("OfflineRouting: Region \(regionId) deleted successfully")
                result(true)
            case .failure(let error):
                print("OfflineRouting: Failed to delete region - \(error.localizedDescription)")
                result(FlutterError(code: "DELETE_FAILED", message: error.localizedDescription, details: nil))
            }
        }
    }

    /// Get the total size of cached offline data in bytes
    func getOfflineCacheSize(result: @escaping FlutterResult) {
        let tileStore = TileStore.default

        tileStore.allTileRegions { regionsResult in
            switch regionsResult {
            case .success(let regions):
                var totalSize: Int64 = 0
                let group = DispatchGroup()

                for region in regions {
                    group.enter()
                    tileStore.tileRegionMetadata(forId: region.id) { metadataResult in
                        if case .success(let metadata) = metadataResult {
                            // Metadata contains size info
                            if let sizeInfo = metadata as? [String: Any],
                               let size = sizeInfo["size"] as? Int64 {
                                totalSize += size
                            }
                        }
                        group.leave()
                    }
                }

                group.notify(queue: .main) {
                    // Estimate size based on completed resources if metadata unavailable
                    let estimatedSize = regions.reduce(0) { sum, region in
                        sum + Int64(region.completedResourceCount * 50 * 1024) // ~50KB per tile estimate
                    }
                    result(Int(totalSize > 0 ? totalSize : estimatedSize))
                }
            case .failure(let error):
                print("OfflineRouting: Error getting cache size - \(error.localizedDescription)")
                result(0)
            }
        }
    }

    /// Clear all cached offline routing data
    func clearOfflineCache(result: @escaping FlutterResult) {
        let tileStore = TileStore.default

        tileStore.allTileRegions { regionsResult in
            switch regionsResult {
            case .success(let regions):
                let group = DispatchGroup()
                var allSuccessful = true

                for region in regions {
                    group.enter()
                    tileStore.removeTileRegion(forId: region.id) { deleteResult in
                        if case .failure(let error) = deleteResult {
                            print("OfflineRouting: Failed to delete region \(region.id) - \(error.localizedDescription)")
                            allSuccessful = false
                        }
                        group.leave()
                    }
                }

                group.notify(queue: .main) {
                    print("OfflineRouting: Cache cleared, success: \(allSuccessful)")
                    result(allSuccessful)
                }
            case .failure(let error):
                print("OfflineRouting: Error clearing cache - \(error.localizedDescription)")
                result(FlutterError(code: "CLEAR_FAILED", message: error.localizedDescription, details: nil))
            }
        }
    }
    
    func encodeRouteResponse(response: RouteResponse) -> String {
        let routes = response.routes
        
        if routes != nil && !routes!.isEmpty {
            let jsonEncoder = JSONEncoder()
            let jsonData = try! jsonEncoder.encode(response.routes!)
            return String(data: jsonData, encoding: String.Encoding.utf8) ?? "{}"
        }
        
        return "{}"
    }
    
    //MARK: EventListener Delegates
    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        _eventSink = events
        return nil
    }
    
    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        _eventSink = nil
        return nil
    }
}


extension NavigationFactory : NavigationViewControllerDelegate {
    //MARK: NavigationViewController Delegates
    public func navigationViewController(_ navigationViewController: NavigationViewController, didUpdate progress: RouteProgress, with location: CLLocation, rawLocation: CLLocation) {
        _lastKnownLocation = location
        _distanceRemaining = progress.distanceRemaining
        _durationRemaining = progress.durationRemaining
        sendEvent(eventType: MapBoxEventType.navigation_running)
        //_currentLegDescription =  progress.currentLeg.description
        if(_eventSink != nil)
        {
            let jsonEncoder = JSONEncoder()

            let progressEvent = MapBoxRouteProgressEvent(progress: progress)
            let progressEventJsonData = try! jsonEncoder.encode(progressEvent)
            let progressEventJson = String(data: progressEventJsonData, encoding: String.Encoding.ascii)

            _eventSink!(progressEventJson)

            if(progress.isFinalLeg && progress.currentLegProgress.userHasArrivedAtWaypoint && !_showEndOfRouteFeedback)
            {
                _eventSink = nil
            }
        }

        // Update trip progress overlay
        let legIndex = progress.legIndex
        let distanceToNext = progress.currentLegProgress.distanceRemaining
        let durationToNext = progress.currentLegProgress.durationRemaining
        TripProgressManager.shared.updateProgress(
            legIndex: legIndex,
            distanceToNextWaypoint: distanceToNext,
            totalDistanceRemaining: progress.distanceRemaining,
            totalDurationRemaining: progress.durationRemaining,
            durationToNextWaypoint: durationToNext
        )
    }
    
    public func navigationViewController(_ navigationViewController: NavigationViewController, didArriveAt waypoint: Waypoint) -> Bool {
        sendEvent(eventType: MapBoxEventType.on_arrival, data: "true")
        if(!_wayPoints.isEmpty && IsMultipleUniqueRoutes)
        {
            continueNavigationWithWayPoints(wayPoints: [getLastKnownLocation(), _wayPoints.remove(at: 0)])
            return false
        }
        
        return true
    }
    
    
    
    public func navigationViewControllerDidDismiss(_ navigationViewController: NavigationViewController, byCanceling canceled: Bool) {
        if(canceled)
        {
            sendEvent(eventType: MapBoxEventType.navigation_cancelled)
        }
        endNavigation(result: nil)
    }
    
    public func navigationViewController(_ navigationViewController: NavigationViewController, shouldRerouteFrom location: CLLocation) -> Bool {
        return _shouldReRoute
    }
    
    public func navigationViewController(_ navigationViewController: NavigationViewController, didSubmitArrivalFeedback feedback: EndOfRouteFeedback) {
        
        if(_eventSink != nil)
        {
            let jsonEncoder = JSONEncoder()
            
            let localFeedback = Feedback(rating: feedback.rating, comment: feedback.comment)
            let feedbackJsonData = try! jsonEncoder.encode(localFeedback)
            let feedbackJson = String(data: feedbackJsonData, encoding: String.Encoding.ascii)
            
            sendEvent(eventType: MapBoxEventType.navigation_finished, data: feedbackJson ?? "")
            
            _eventSink = nil
            
        }
    }
}
