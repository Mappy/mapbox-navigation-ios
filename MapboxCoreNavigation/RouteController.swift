import Foundation
import CoreLocation
import MapboxDirections
import Polyline
import MapboxMobileEvents
import Turf


protocol RouteControllerDataSource: class {
    var location: CLLocation? { get }
    var locationProvider: NavigationLocationManager.Type { get }
}


/**
 A `RouteController` tracks the user’s progress along a route, posting notifications as the user reaches significant points along the route. On every location update, the route controller evaluates the user’s location, determining whether the user remains on the route. If not, the route controller calculates a new route.

 `RouteController` is responsible for the core navigation logic whereas
 `NavigationViewController` is responsible for displaying a default drop-in navigation UI.
 */
@objc(MBRouteController)
open class RouteController: NSObject, Router {
    

    public enum DefaultBehavior {
        public static let shouldRerouteFromLocation: Bool = true
        public static let shouldDiscardLocation: Bool = true
        public static let didArriveAtWaypoint: Bool = true
        public static let shouldPreventReroutesWhenArrivingAtWaypoint: Bool = true
        public static let shouldDisableBatteryMonitoring: Bool = true
        
    }
    
    /**
     The route controller’s delegate.
     */
    @objc public weak var delegate: RouterDelegate?

    /**
     The route controller’s associated location manager.
     */
    @objc public unowned var dataSource: RouterDataSource
    
    /**
     The Directions object used to create the route.
     */
    @objc public var directions: Directions


    /**
     If true, the `RouteController` attempts to calculate a more optimal route for the user on an interval defined by `RouteControllerProactiveReroutingInterval`.
     */
    @objc public var reroutesProactively = false

    /**
    Force the `RouteController` to request a route update from the server when receiving next location update.

    This is a Mappy debug feature. This works by bypassing all usual checks that determine if a proactive rerouting should occur.
    `reroutesProactively` must be set to true otherwise this parameter is ignored.
	This property reverts to false once forced request has been sent.
    */
    @objc public var forceProactiveReroutingAtNextUpdate = false
	
    var didFindFasterRoute = false

    /**
     Details about the user’s progress along the current route, leg, and step.
     */
    @objc public var routeProgress: RouteProgress {
        get {
            return _routeProgress
        }
        set {
            if let location = self.location {
                delegate?.router?(self, willRerouteFrom: location)
            }
            _routeProgress = newValue
            announce(reroute: routeProgress.route, at: dataSource.location, proactive: didFindFasterRoute)
        }

    }
    private var _routeProgress: RouteProgress {
        didSet {
            movementsAwayFromRoute = 0
        }
    }
    
    public var route: Route {
        get {
            return routeProgress.route
        }
        set {
            routeProgress = RouteProgress(route: newValue)
        }
    }

    var isRerouting = false
    var lastRerouteLocation: CLLocation?

    var routeTask: URLSessionDataTask?
    var lastLocationDate: Date?

    var hasFoundOneQualifiedLocation = false

    var movementsAwayFromRoute = 0

    var previousArrivalWaypoint: Waypoint?

    public var userSnapToStepDistanceFromManeuver: CLLocationDistance?
    
    /**
     Intializes a new `RouteController`.

     - parameter route: The route to follow.
     - parameter directions: The Directions object that created `route`.
     - parameter source: The data source for the RouteController.
     */
    required public init(along route: Route, directions: Directions = Directions.shared, dataSource source: RouterDataSource) {
        self.directions = directions
        self._routeProgress = RouteProgress(route: route)
        self.dataSource = source
        UIDevice.current.isBatteryMonitoringEnabled = true

        super.init()
        
        checkForUpdates()
        checkForLocationUsageDescription()
    }

    deinit {
        if delegate?.routerShouldDisableBatteryMonitoring?(self) ?? DefaultBehavior.shouldDisableBatteryMonitoring {
            UIDevice.current.isBatteryMonitoringEnabled = false
        }
  
    }

	/**
	Replaces the currently followed route.
	*/
	@objc public func updateRoute(_ route: Route) {
		self.delegate?.router?(self, willRerouteAlong: route)
        NotificationCenter.default.post(name: .routeControllerWillRerouteAlong, object: self, userInfo: [
            RouteControllerNotificationUserInfoKey.routeKey: route])
		self._routeProgress = RouteProgress(route: route, legIndex: 0)
		self.delegate?.router?(self, didRerouteAlong: route, at: dataSource.location, proactive: didFindFasterRoute)
	}

    /**
     The idealized user location. Snapped to the route line, if applicable, otherwise raw.
     - seeAlso: snappedLocation, rawLocation
     */
    @objc public var location: CLLocation? {

        // If there is no snapped location, and the rawLocation course is unqualified, use the user's heading as long as it is accurate.
        if snappedLocation == nil,
            let heading = heading,
            let loc = rawLocation,
            !loc.course.isQualified,
            heading.trueHeading.isQualified {
            return CLLocation(coordinate: loc.coordinate, altitude: loc.altitude, horizontalAccuracy: loc.horizontalAccuracy, verticalAccuracy: loc.verticalAccuracy, course: heading.trueHeading, speed: loc.speed, timestamp: loc.timestamp)
        }

        return snappedLocation ?? rawLocation
    }

    /**
     The raw location, snapped to the current route.
     - important: If the rawLocation is outside of the route snapping tolerances, this value is nil.
     */
    var snappedLocation: CLLocation? {
        return rawLocation?.snapped(to: routeProgress.currentLegProgress)
    }

    var heading: CLHeading?

    /**
     The most recently received user location.
     - note: This is a raw location received from `locationManager`. To obtain an idealized location, use the `location` property.
     */
    public var rawLocation: CLLocation? {
        didSet {
            updateDistanceToManeuver()
        }
    }

    func updateDistanceToManeuver() {
        guard let coordinates = routeProgress.currentLegProgress.currentStep.coordinates, let coordinate = rawLocation?.coordinate else {
            userSnapToStepDistanceFromManeuver = nil
            return
        }
        userSnapToStepDistanceFromManeuver = Polyline(coordinates).distance(from: coordinate)
    }

    @objc public var reroutingTolerance: CLLocationDistance {
        guard let intersections = routeProgress.currentLegProgress.currentStepProgress.intersectionsIncludingUpcomingManeuverIntersection else { return RouteControllerMaximumDistanceBeforeRecalculating }
        guard let userLocation = rawLocation else { return RouteControllerMaximumDistanceBeforeRecalculating }

        for intersection in intersections {
            let absoluteDistanceToIntersection = userLocation.coordinate.distance(to: intersection.location)

            if absoluteDistanceToIntersection <= RouteControllerManeuverZoneRadius {
                return RouteControllerMaximumDistanceBeforeRecalculating / 2
            }
        }
        return RouteControllerMaximumDistanceBeforeRecalculating
    }
    
    func getDirections(from location: CLLocation, along progress: RouteProgress, completion: @escaping (_ route: Route?, _ mappyRoutes: [MappyRoute]?, _ error: Error?)->Void) {
        routeTask?.cancel()
        let options = progress.reroutingOptions(with: location)
        
        self.lastRerouteLocation = location
        
        let complete = { [weak self] (route: Route?, _ mappyRoutes: [MappyRoute]?, error: NSError?) in
            self?.isRerouting = false
            completion(route, mappyRoutes, error)
        }
        
        routeTask = directions.calculate(options) {(waypoints, potentialRoutes, potentialError) in
            
            guard let routes = potentialRoutes else {
                return complete(nil, nil, potentialError)
            }
			
			if routes.count > 0,
				let mappyRoutes = routes as? [MappyRoute]
			{
				return complete(nil, mappyRoutes, potentialError)
			}
            
            let mostSimilar = routes.mostSimilar(to: progress.route)
            
            return complete(mostSimilar ?? routes.first, nil, potentialError)
            
        }
    }
    
    /**
     Monitors the user's course to see if it is consistantly moving away from what we expect the course to be at a given point.
     */
    func userCourseIsOnRoute(_ location: CLLocation) -> Bool {
        let nearByCoordinates = routeProgress.currentLegProgress.nearbyCoordinates
        guard let calculatedCourseForLocationOnStep = location.interpolatedCourse(along: nearByCoordinates) else { return true }
        
        let maxUpdatesAwayFromRouteGivenAccuracy = Int(location.horizontalAccuracy / Double(RouteControllerIncorrectCourseMultiplier))
        
        if movementsAwayFromRoute >= max(RouteControllerMinNumberOfInCorrectCourses, maxUpdatesAwayFromRouteGivenAccuracy)  {
            return false
        } else if location.shouldSnap(toRouteWith: calculatedCourseForLocationOnStep) {
            movementsAwayFromRoute = 0
        } else {
            movementsAwayFromRoute += 1
        }
        
        return true
    }
    
    /**
     Given a users current location, returns a Boolean whether they are currently on the route.
     
     If the user is not on the route, they should be rerouted.
     */
    @objc public func userIsOnRoute(_ location: CLLocation) -> Bool {
        
        // If the user has arrived, do not continue monitor reroutes, step progress, etc
        guard !routeProgress.currentLegProgress.userHasArrivedAtWaypoint || (delegate?.router?(self, shouldPreventReroutesWhenArrivingAt: routeProgress.currentLeg.destination) ?? DefaultBehavior.shouldPreventReroutesWhenArrivingAtWaypoint) else {
            return true
        }
        
        let isCloseToCurrentStep = userIsWithinRadiusOfRoute(location: location)
        
        guard !isCloseToCurrentStep || !userCourseIsOnRoute(location) else { return true }
        
        // Check and see if the user is near a future step.
        guard let nearestStep = routeProgress.currentLegProgress.closestStep(to: location.coordinate) else {
            return false
        }
        
        if nearestStep.distance < RouteControllerUserLocationSnappingDistance {
            // Only advance the stepIndex to a future step if the step is new. Otherwise, the user is still on the current step.
            if nearestStep.index != routeProgress.currentLegProgress.stepIndex {
                advanceStepIndex(to: nearestStep.index)
            }
            return true
        }
        
        return false
    }
    
    internal func userIsWithinRadiusOfRoute(location: CLLocation) -> Bool {
        let radius = max(reroutingTolerance, RouteControllerManeuverZoneRadius)
        let isCloseToCurrentStep = location.isWithin(radius, of: routeProgress.currentLegProgress.currentStep)
        return isCloseToCurrentStep
    }
}

extension RouteController: CLLocationManagerDelegate {


    @objc public func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        heading = newHeading
    }

    @objc public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let filteredLocations = locations.filter {
            return $0.isQualified
        }

        if !filteredLocations.isEmpty, hasFoundOneQualifiedLocation == false {
            hasFoundOneQualifiedLocation = true
        }

        let currentStepProgress = routeProgress.currentLegProgress.currentStepProgress
        
        var potentialLocation: CLLocation?

        // `filteredLocations` contains qualified locations
        if let lastFiltered = filteredLocations.last {
            potentialLocation = lastFiltered
        // `filteredLocations` does not contain good locations and we have found at least one good location previously.
        } else if hasFoundOneQualifiedLocation {
            if let lastLocation = locations.last, delegate?.router?(self, shouldDiscard: lastLocation) ?? DefaultBehavior.shouldDiscardLocation {
                
                // Allow the user puck to advance. A stationary puck is not great.
                self.rawLocation = lastLocation
                
                return
            }
        // This case handles the first location.
        // This location is not a good location, but we need the rest of the UI to update and at least show something.
        } else if let lastLocation = locations.last {
            potentialLocation = lastLocation
        }

        guard let location = potentialLocation else {
            return
        }

        self.rawLocation = location


        updateIntersectionIndex(for: currentStepProgress)
        // Notify observers if the step’s remaining distance has changed.

        update(progress: routeProgress, with: self.location!, rawLocation: location)
        updateDistanceToIntersection(from: location)
        updateRouteStepProgress(for: location)
        updateRouteLegProgress(for: location)
        updateVisualInstructionProgress()

        if !userIsOnRoute(location) && delegate?.router?(self, shouldRerouteFrom: location) ?? DefaultBehavior.shouldRerouteFromLocation {

            reroute(from: location, along: routeProgress)
            return
        }

        updateSpokenInstructionProgress()

        // Check for faster route given users current location
        guard reroutesProactively else { return }
        if forceProactiveReroutingAtNextUpdate {
            checkForFasterRoute(from: location)
            return
        }
        // Only check for faster alternatives if the user has plenty of time left on the route.
        guard routeProgress.durationRemaining > 600 else { return }
        // If the user is approaching a maneuver, don't check for a faster alternatives
        guard routeProgress.currentLegProgress.currentStepProgress.durationRemaining > RouteControllerMediumAlertInterval else { return }
        checkForFasterRoute(from: location)
    }
    
    private func update(progress: RouteProgress, with location: CLLocation, rawLocation: CLLocation) {
        
        let stepProgress = progress.currentLegProgress.currentStepProgress
        let step = stepProgress.step
        
        //Increment the progress model
        let polyline = Polyline(step.coordinates!)
        if let closestCoordinate = polyline.closestCoordinate(to: rawLocation.coordinate) {
            let remainingDistance = polyline.distance(from: closestCoordinate.coordinate)
            let distanceTraveled = step.distance - remainingDistance
            stepProgress.distanceTraveled = distanceTraveled
            
            //Fire the delegate method
            delegate?.router?(self, didUpdate: progress, with: location, rawLocation: rawLocation)
            
            //Fire the notification (for now)
            NotificationCenter.default.post(name: .routeControllerProgressDidChange, object: self, userInfo: [
                RouteControllerNotificationUserInfoKey.routeProgressKey: progress,
                RouteControllerNotificationUserInfoKey.locationKey: location, //guaranteed value
                RouteControllerNotificationUserInfoKey.rawLocationKey: rawLocation //raw
                ])
        }
    }
    
    private func announce(reroute newRoute: Route, at location: CLLocation?, proactive: Bool) {
            var userInfo = [RouteControllerNotificationUserInfoKey: Any]()
            if let location = location {
                userInfo[.locationKey] = location
            }
            userInfo[.isProactiveKey] = didFindFasterRoute
            NotificationCenter.default.post(name: .routeControllerDidReroute, object: self, userInfo: userInfo)
        delegate?.router?(self, didRerouteAlong: routeProgress.route, at: dataSource.location, proactive: didFindFasterRoute)
    }
        
    func updateIntersectionIndex(for currentStepProgress: RouteStepProgress) {
        guard let intersectionDistances = currentStepProgress.intersectionDistances else { return }
        let upcomingIntersectionIndex = intersectionDistances.index { $0 > currentStepProgress.distanceTraveled } ?? intersectionDistances.endIndex
        currentStepProgress.intersectionIndex = upcomingIntersectionIndex > 0 ? intersectionDistances.index(before: upcomingIntersectionIndex) : 0
    }

    func updateRouteLegProgress(for location: CLLocation) {
        let currentDestination = routeProgress.currentLeg.destination
        guard let remainingVoiceInstructions = routeProgress.currentLegProgress.currentStepProgress.remainingSpokenInstructions else { return }

        if routeProgress.currentLegProgress.remainingSteps.count <= 1 && remainingVoiceInstructions.count == 0 && currentDestination != previousArrivalWaypoint {
            previousArrivalWaypoint = currentDestination

            routeProgress.currentLegProgress.userHasArrivedAtWaypoint = true

            let advancesToNextLeg = delegate?.router?(self, didArriveAt: currentDestination) ?? DefaultBehavior.didArriveAtWaypoint

            if !routeProgress.isFinalLeg && advancesToNextLeg {
                routeProgress.legIndex += 1
                updateDistanceToManeuver()
            }
        }
    }

 
    func checkForFasterRoute(from location: CLLocation) {
        guard let currentUpcomingManeuver = routeProgress.currentLegProgress.upComingStep else {
            return
        }

        guard let lastLocationDate = lastLocationDate else {
            self.lastLocationDate = location.timestamp
            return
        }

        // Only check every so often for a faster route.
        guard location.timestamp.timeIntervalSince(lastLocationDate) >= RouteControllerProactiveReroutingInterval
			|| self.forceProactiveReroutingAtNextUpdate == true else {
            return
        }

		var forceApplyReceivedRoute = false
		if self.forceProactiveReroutingAtNextUpdate {
			self.forceProactiveReroutingAtNextUpdate = false
			forceApplyReceivedRoute = true
		}

        let durationRemaining = routeProgress.durationRemaining

        getDirections(from: location, along: routeProgress) { [weak self] (route, mappyRoutes, error) in
            guard let strongSelf = self else {
                return
            }

			if let routes = mappyRoutes
			{
				if let upToDateRoute = routes.first(where: { $0.routeType == .current })
				{
					strongSelf.lastLocationDate = nil

					guard let firstLeg = upToDateRoute.legs.first, let firstStep = firstLeg.steps.first else {
						return
					}
					guard (firstStep.expectedTravelTime >= RouteControllerMediumAlertInterval && currentUpcomingManeuver == firstLeg.steps[1])
						|| forceApplyReceivedRoute else {
						return
					}

					strongSelf.delegate?.router?(strongSelf, willRerouteAlong: upToDateRoute)
					NotificationCenter.default.post(name: .routeControllerWillRerouteAlong, object: strongSelf, userInfo: [
						RouteControllerNotificationUserInfoKey.routeKey: upToDateRoute])

                    strongSelf.didFindFasterRoute = true
					strongSelf._routeProgress = RouteProgress(route: upToDateRoute, legIndex: 0, spokenInstructionIndex: 0)
					strongSelf.announce(reroute: upToDateRoute, at: location, proactive: true)
                    strongSelf.movementsAwayFromRoute = 0
                    strongSelf.didFindFasterRoute = false
				}

				if let fasterRoute = routes.first(where: { $0.routeType == .best })
				{
					strongSelf.delegate?.router?(strongSelf, didReceiveFasterRoute: fasterRoute)
				}

				return
			}

            guard let route = route else {
                return
            }

            strongSelf.lastLocationDate = nil

            guard let firstLeg = route.legs.first, let firstStep = firstLeg.steps.first else {
                return
            }

            let routeIsFaster = firstStep.expectedTravelTime >= RouteControllerMediumAlertInterval &&
                currentUpcomingManeuver == firstLeg.steps[1] && route.expectedTravelTime <= 0.9 * durationRemaining

            if routeIsFaster {
				strongSelf.delegate?.router?(strongSelf, willRerouteAlong: route)
				NotificationCenter.default.post(name: .routeControllerWillRerouteAlong, object: strongSelf, userInfo: [
					RouteControllerNotificationUserInfoKey.routeKey: route])

                strongSelf.didFindFasterRoute = true
                // If the upcoming maneuver in the new route is the same as the current upcoming maneuver, don't announce it
                strongSelf._routeProgress = RouteProgress(route: route, legIndex: 0, spokenInstructionIndex: strongSelf._routeProgress.currentLegProgress.currentStepProgress.spokenInstructionIndex)
                strongSelf.announce(reroute: route, at: location, proactive: true)
                strongSelf.movementsAwayFromRoute = 0
                strongSelf.didFindFasterRoute = false
            }
        }
    }

    public func reroute(from location: CLLocation, along progress: RouteProgress) {
        if let lastRerouteLocation = lastRerouteLocation {
            guard location.distance(from: lastRerouteLocation) >= RouteControllerMaximumDistanceBeforeRecalculating else {
                return
            }
        }

        if isRerouting {
            return
        }

        isRerouting = true

        delegate?.router?(self, willRerouteFrom: location)
        NotificationCenter.default.post(name: .routeControllerWillReroute, object: self, userInfo: [
            RouteControllerNotificationUserInfoKey.locationKey: location
        ])

        self.lastRerouteLocation = location

		let options = progress.route.routeOptions
		if let mappyOptions = options as? MappyNavigationRouteOptions {
			mappyOptions.routeSignature = nil
		}
        getDirections(from: location, along: progress) { [weak self] (route, mappyRoutes, error) in
            guard let strongSelf: RouteController = self else {
                return
            }

            if let error = error {
                strongSelf.delegate?.router?(strongSelf, didFailToRerouteWith: error)
                NotificationCenter.default.post(name: .routeControllerDidFailToReroute, object: self, userInfo: [
                    RouteControllerNotificationUserInfoKey.routingErrorKey: error
                ])
                return
            }

            guard let route = route ?? mappyRoutes?.first else { return }

            strongSelf.delegate?.router?(strongSelf, willRerouteAlong: route)
            NotificationCenter.default.post(name: .routeControllerWillRerouteAlong, object: strongSelf, userInfo: [
                RouteControllerNotificationUserInfoKey.routeKey: route])

            strongSelf.isRerouting = false
            strongSelf._routeProgress = RouteProgress(route: route, legIndex: 0)
            strongSelf._routeProgress.currentLegProgress.stepIndex = 0
            strongSelf.announce(reroute: route, at: location, proactive: false)
        }
    }

    private func checkForUpdates() {
        #if TARGET_IPHONE_SIMULATOR
        guard (NSClassFromString("XCTestCase") == nil) else { return } // Short-circuit when running unit tests
            guard let version = Bundle(for: RouteController.self).object(forInfoDictionaryKey: "CFBundleShortVersionString") else { return }
            let latestVersion = String(describing: version)
            _ = URLSession.shared.dataTask(with: URL(string: "https://www.mapbox.com/mapbox-navigation-ios/latest_version")!, completionHandler: { (data, response, error) in
                if let _ = error { return }
                guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else { return }

                guard let data = data, let currentVersion = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .newlines) else { return }

                if latestVersion != currentVersion {
                    let updateString = NSLocalizedString("UPDATE_AVAILABLE", bundle: .mapboxCoreNavigation, value: "Mapbox Navigation SDK for iOS version %@ is now available.", comment: "Inform developer an update is available")
                    print(String.localizedStringWithFormat(updateString, latestVersion), "https://github.com/mapbox/mapbox-navigation-ios/releases/tag/v\(latestVersion)")
                }
            }).resume()
        #endif
    }

    private func checkForLocationUsageDescription() {
        guard let _ = Bundle.main.bundleIdentifier else {
            return
        }
        if Bundle.main.locationAlwaysUsageDescription == nil && Bundle.main.locationWhenInUseUsageDescription == nil && Bundle.main.locationAlwaysAndWhenInUseUsageDescription == nil {
            preconditionFailure("This application’s Info.plist file must include a NSLocationWhenInUseUsageDescription. See https://developer.apple.com/documentation/corelocation for more information.")
        }
    }

    func updateDistanceToIntersection(from location: CLLocation) {
        guard var intersections = routeProgress.currentLegProgress.currentStepProgress.step.intersections else { return }
        let currentStepProgress = routeProgress.currentLegProgress.currentStepProgress

        // The intersections array does not include the upcoming maneuver intersection.
        if let upcomingStep = routeProgress.currentLegProgress.upComingStep, let upcomingIntersection = upcomingStep.intersections, let firstUpcomingIntersection = upcomingIntersection.first {
            intersections += [firstUpcomingIntersection]
        }

        routeProgress.currentLegProgress.currentStepProgress.intersectionsIncludingUpcomingManeuverIntersection = intersections

        if let upcomingIntersection = routeProgress.currentLegProgress.currentStepProgress.upcomingIntersection {
            routeProgress.currentLegProgress.currentStepProgress.userDistanceToUpcomingIntersection = Polyline(currentStepProgress.step.coordinates!).distance(from: location.coordinate, to: upcomingIntersection.location)
        }
        
        if routeProgress.currentLegProgress.currentStepProgress.intersectionDistances == nil {
            routeProgress.currentLegProgress.currentStepProgress.intersectionDistances = [CLLocationDistance]()
            updateIntersectionDistances()
        }
    }

    func updateRouteStepProgress(for location: CLLocation) {
        guard routeProgress.currentLegProgress.remainingSteps.count > 0 else { return }

        guard let userSnapToStepDistanceFromManeuver = userSnapToStepDistanceFromManeuver else { return }
        var courseMatchesManeuverFinalHeading = false

        // Bearings need to normalized so when the `finalHeading` is 359 and the user heading is 1,
        // we count this as within the `RouteControllerMaximumAllowedDegreeOffsetForTurnCompletion`
        if let upcomingStep = routeProgress.currentLegProgress.upComingStep, let finalHeading = upcomingStep.finalHeading, let initialHeading = upcomingStep.initialHeading {
            let initialHeadingNormalized = initialHeading.wrap(min: 0, max: 360)
            let finalHeadingNormalized = finalHeading.wrap(min: 0, max: 360)
            let expectedTurningAngle = initialHeadingNormalized.difference(from: finalHeadingNormalized)

            // If the upcoming maneuver is fairly straight,
            // do not check if the user is within x degrees of the exit heading.
            // For ramps, their current heading will very close to the exit heading.
            // We need to wait until their moving away from the maneuver location instead.
            // We can do this by looking at their snapped distance from the maneuver.
            // Once this distance is zero, they are at more moving away from the maneuver location
            if expectedTurningAngle <= RouteControllerMaximumAllowedDegreeOffsetForTurnCompletion {
                courseMatchesManeuverFinalHeading = userSnapToStepDistanceFromManeuver == 0
            } else if location.course.isQualified {
				let userHeadingNormalized = location.course.wrap(min: 0, max: 360)
                courseMatchesManeuverFinalHeading = finalHeadingNormalized.difference(from: userHeadingNormalized) <= RouteControllerMaximumAllowedDegreeOffsetForTurnCompletion
            }
        }

        let step = routeProgress.currentLegProgress.upComingStep?.maneuverLocation ?? routeProgress.currentLegProgress.currentStep.maneuverLocation
        let userAbsoluteDistance = step.distance(to: location.coordinate)
        let lastKnownUserAbsoluteDistance = routeProgress.currentLegProgress.currentStepProgress.userDistanceToManeuverLocation

        if userSnapToStepDistanceFromManeuver <= RouteControllerManeuverZoneRadius &&
            (courseMatchesManeuverFinalHeading || (userAbsoluteDistance > lastKnownUserAbsoluteDistance && lastKnownUserAbsoluteDistance > RouteControllerManeuverZoneRadius)) {
            advanceStepIndex()
        }

        routeProgress.currentLegProgress.currentStepProgress.userDistanceToManeuverLocation = userAbsoluteDistance
    }

    func updateSpokenInstructionProgress() {
        guard let userSnapToStepDistanceFromManeuver = userSnapToStepDistanceFromManeuver else { return }
        guard let spokenInstructions = routeProgress.currentLegProgress.currentStepProgress.remainingSpokenInstructions else { return }

        // Always give the first voice announcement when beginning a leg.
        let firstInstructionOnFirstStep = routeProgress.currentLegProgress.stepIndex == 0 && routeProgress.currentLegProgress.currentStepProgress.spokenInstructionIndex == 0

        for voiceInstruction in spokenInstructions {
            if userSnapToStepDistanceFromManeuver <= voiceInstruction.distanceAlongStep || firstInstructionOnFirstStep {

                NotificationCenter.default.post(name: .routeControllerDidPassSpokenInstructionPoint, object: self, userInfo: [
                    RouteControllerNotificationUserInfoKey.routeProgressKey: routeProgress
                ])

                routeProgress.currentLegProgress.currentStepProgress.spokenInstructionIndex += 1
                return
            }
        }
    }
    
    func updateVisualInstructionProgress() {
        guard let userSnapToStepDistanceFromManeuver = userSnapToStepDistanceFromManeuver else { return }
        guard let visualInstructions = routeProgress.currentLegProgress.currentStepProgress.remainingVisualInstructions else { return }
        
        let firstInstructionOnFirstStep = routeProgress.currentLegProgress.stepIndex == 0 && routeProgress.currentLegProgress.currentStepProgress.visualInstructionIndex == 0
        
        for visualInstruction in visualInstructions {
            if userSnapToStepDistanceFromManeuver <= visualInstruction.distanceAlongStep || firstInstructionOnFirstStep {
                
                NotificationCenter.default.post(name: .routeControllerDidPassVisualInstructionPoint, object: self, userInfo: [
                    RouteControllerNotificationUserInfoKey.routeProgressKey: routeProgress
                    ])
                
                routeProgress.currentLegProgress.currentStepProgress.visualInstructionIndex += 1
                return
            }
        }
    }

    public func advanceStepIndex(to: Array<RouteStep>.Index? = nil) {
        if let forcedStepIndex = to {
            guard forcedStepIndex < routeProgress.currentLeg.steps.count else { return }
            routeProgress.currentLegProgress.stepIndex = forcedStepIndex
        } else {
            routeProgress.currentLegProgress.stepIndex += 1
        }

        updateIntersectionDistances()
        updateDistanceToManeuver()
    }

    func updateIntersectionDistances() {
        if let coordinates = routeProgress.currentLegProgress.currentStep.coordinates, let intersections = routeProgress.currentLegProgress.currentStep.intersections {
            let polyline = Polyline(coordinates)
            let distances: [CLLocationDistance] = intersections.map { polyline.distance(from: coordinates.first, to: $0.location) }
            routeProgress.currentLegProgress.currentStepProgress.intersectionDistances = distances
        }
    }
}

//MARK: - Obsolete Interfaces

public extension RouteController {
    @available(*, obsoleted: 0.1, message: "MapboxNavigationService is now the point-of-entry to MapboxCoreNavigation. Direct use of RouteController is no longer reccomended. See MapboxNavigationService for more information.")
    /// :nodoc: Obsoleted method.
    @objc(initWithRoute:directions:locationManager:eventsManager:)
    public convenience init(along route: Route, directions: Directions = Directions.shared, locationManager: NavigationLocationManager = NavigationLocationManager(), eventsManager: NavigationEventsManager) {
        fatalError()
    }
    
    @available(*, obsoleted: 0.1, message: "RouteController no longer manages a location manager directly. Instead, the Router protocol conforms to CLLocationManagerDelegate, and RouteControllerDataSource provides access to synchronous location requests.")
    /// :nodoc: obsoleted
    @objc public final var locationManager: NavigationLocationManager! {
        get {
            fatalError()
        }
        set {
            fatalError()
        }
    }
    @available(*, obsoleted: 0.1, renamed: "NavigationService.locationManager", message: "NavigationViewController no-longer directly manages an NavigationLocationManager. See MapboxNavigationService, which contains a reference to the locationManager, for more information.")
    /// :nodoc: obsoleted
    @objc public final var tunnelIntersectionManager: Any! {
        get {
            fatalError()
        }
        set {
            fatalError()
        }
    }
    @available(*, obsoleted: 0.1, renamed: "navigationService.eventsManager", message: "NavigationViewController no-longer directly manages a NavigationEventsManager. See MapboxNavigationService, which contains a reference to the eventsManager, for more information.")
    /// :nodoc: obsoleted
    @objc public final var eventsManager: NavigationEventsManager! {
        get {
            fatalError()
        }
        set {
            fatalError()
        }
    }
}
