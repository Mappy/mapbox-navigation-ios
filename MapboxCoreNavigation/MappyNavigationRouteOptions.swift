import Foundation
import MapboxDirections

/**
 A `MappyNavigationRouteOptions` object specifies turn-by-turn-optimized criteria for results returned by the Mappy navigation API.

 `MappyNavigationRouteOptions` is a subclass of `MappyRouteOptions` that has ensure correct settings are set to request direction from Mappy API.
 */
open class MappyNavigationRouteOptions: MappyRouteOptions, OptimizedForNavigation {
    /**
     Initializes a navigation route options object for routes from Mappy API between the given waypoints

     The calculated route will be optimized for the given provider and respect the route calculation type.

     - seealso: `MappyRouteOptions`
     */
    public override init(waypoints: [Waypoint], provider: String, routeCalculationType: String, qid: String) {
        super.init(waypoints: waypoints.map {
            $0.coordinateAccuracy = -1
            return $0
        }, provider: provider, routeCalculationType: routeCalculationType, qid: qid)

        optimizeForNavigation()
    }

    /**
     Initializes a navigation route options object for routes from Mappy API between the given locations and an optional profile identifier optimized for navigation.

     - seealso: `MappyRouteOptions`
     */
    public override init(waypoints: [Waypoint], provider: String, additionalQueryParams params: [String:String]) {
        super.init(waypoints: waypoints.map {
            $0.coordinateAccuracy = -1
            return $0
        }, provider: provider, additionalQueryParams: params)

        optimizeForNavigation()
    }

    required public init(waypoints: [Waypoint], profileIdentifier: DirectionsProfileIdentifier?) {
        fatalError("Please use either init(waypoints:provider:routeCalculationType:qid:) or init(waypoints:provider:additionalQueryParams:) to create a MappyNavigationRouteOptions")
    }
    /**
     Initializes a navigation route options object for routes from Mappy API between the given locations.

     - seealso: `MappyRouteOptions`
     */
    public convenience init(locations: [CLLocation], provider: String, routeCalculationType: String, qid: String) {
        let waypoints = locations.map { Waypoint(location: $0) }
        self.init(waypoints: waypoints, provider: provider, routeCalculationType: routeCalculationType, qid: qid)
    }

    /**
     Initializes a navigation route options object for routes from Mappy API between the given locations.

     - seealso: `MappyRouteOptions`
     */
    public convenience init(coordinates: [CLLocationCoordinate2D], provider: String, routeCalculationType: String, qid: String) {
        let waypoints = coordinates.map { Waypoint(coordinate: $0) }
        self.init(waypoints: waypoints, provider: provider, routeCalculationType: routeCalculationType, qid: qid)
    }

    required public init(from decoder: Decoder) throws {
        try super.init(from: decoder)
    }
}
