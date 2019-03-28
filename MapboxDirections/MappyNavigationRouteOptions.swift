import Foundation

/**
 The walking speed of the user.

 Only used for pedestrian itineraries.
 */
public enum MappyWalkSpeed: String
{
    case slow, normal, fast
}

/**
 The cycling speed of the user.

 Only used for bike itineraries.
 */
public enum MappyBikeSpeed: String
{
    case slow, normal, fast
}

public class MappyNavigationRouteOptions: RouteOptions
{
    // MARK: - Initializers

    /**
     Initializes a navigation route options object for routes between the given waypoints

     The calculated route will be optimized for the given provider and respect the route calculation type.
     */
    public init(waypoints: [Waypoint], provider: String, routeCalculationType: String, qid: String)
    {
        self.provider = provider
        self.routeCalculationType = routeCalculationType
        self.qid = qid
        self.additionalQueryParams = [String:String]()

        super.init(waypoints: waypoints.map {
            $0.coordinateAccuracy = -1
            return $0
        }, profileIdentifier: .automobileAvoidingTraffic)

        self.commonInit()
    }

    /**
     Initializes a navigation route options object for routes between the given waypoints.

     Known options will be pulled from additionalQueryParams and assigned to their respective properties,
     other keys present in the dictionnary will be sent to the API as URL query parameters.
     */
    public init(waypoints: [Waypoint], provider: String, additionalQueryParams params: [String:String])
    {
        self.provider = provider

        self.routeCalculationType = params["route_type"] ?? ""
        self.qid = params["qid"] ?? ""
        self.carVehicle = params["vehicle"]
        self.motorbikeVehicule = params["motorbike_vehicle"]
        if let walkSpeed = params["walk_speed"] {
            self.walkSpeed = MappyWalkSpeed(rawValue: walkSpeed)
        }
        if let bikeSpeed = params["bike_speed"] {
            self.bikeSpeed = MappyBikeSpeed(rawValue: bikeSpeed)
        }

        var cleanedParams = params
        cleanedParams["route_type"] = nil
        cleanedParams["qid"] = nil
        cleanedParams["vehicle"] = nil
        cleanedParams["motorbike_vehicle"] = nil
        cleanedParams["walk_speed"] = nil
        cleanedParams["bike_speed"] = nil

        self.additionalQueryParams = cleanedParams

        super.init(waypoints: waypoints.map {
            $0.coordinateAccuracy = -1
            return $0
        }, profileIdentifier: .automobileAvoidingTraffic)

        self.commonInit()
    }

    /**
     Initializes a navigation route options object for routes between the given locations and an optional profile identifier optimized for navigation.
     */
    public convenience init(locations: [CLLocation], provider: String, routeCalculationType: String, qid: String)
    {
        self.init(waypoints: locations.map { Waypoint(location: $0) }, provider: provider, routeCalculationType: routeCalculationType, qid: qid)
    }

    /**
     Initializes a route options object for routes between the given geographic coordinates and an optional profile identifier optimized for navigation.
     */
    public convenience init(coordinates: [CLLocationCoordinate2D], provider: String, routeCalculationType: String, qid: String)
    {
        self.init(waypoints: coordinates.map { Waypoint(coordinate: $0) }, provider: provider, routeCalculationType: routeCalculationType, qid: qid)
    }

    public required init(waypoints: [Waypoint], profileIdentifier: MBDirectionsProfileIdentifier?)
    {
        self.provider = ""
        self.routeCalculationType = ""
        self.qid = ""
        self.additionalQueryParams = [String:String]()
        super.init(waypoints: waypoints, profileIdentifier: profileIdentifier)
    }

    private func commonInit()
    {
        includesSteps = true
        shapeFormat = .polyline
        routeShapeResolution = .full
        attributeOptions = []
        locale = Locale.current
        distanceMeasurementSystem = .metric
        includesSpokenInstructions = true
        includesVisualInstructions = true
        allowsUTurnAtWaypoint = false
        includesAlternativeRoutes = true
        includesExitRoundaboutManeuver = false
        roadClassesToAvoid = []
    }

    // MARK: - NSCoding

    public required init?(coder decoder: NSCoder)
    {
        self.provider = decoder.decodeObject(of: NSString.self, forKey: "provider") as String? ?? ""
        self.qid = decoder.decodeObject(of: NSString.self, forKey: "qid") as String? ?? ""
        self.routeCalculationType = decoder.decodeObject(of: NSString.self, forKey: "routeCalculationType") as String? ?? ""
        self.additionalQueryParams = decoder.decodeObject(of: [NSDictionary.self, NSString.self, NSString.self], forKey: "additionalQueryParams") as? [String: String] ?? [String:String]()
        self.routeSignature = decoder.decodeObject(of: NSString.self, forKey: "routeSignature") as String?
        self.carVehicle = decoder.decodeObject(of: NSString.self, forKey: "carVehicle") as String?
        self.motorbikeVehicule = decoder.decodeObject(of: NSString.self, forKey: "motorbikeVehicule") as String?
        self.walkSpeed = MappyWalkSpeed(rawValue: decoder.decodeObject(of: NSString.self, forKey: "walkSpeed") as String? ?? "")
        self.bikeSpeed = MappyBikeSpeed(rawValue: decoder.decodeObject(of: NSString.self, forKey: "bikeSpeed") as String? ?? "")
        self.forceBetterRoute = decoder.decodeBool(forKey: "forceBetterRoute")

        super.init(coder: decoder)
    }

    public override func encode(with coder: NSCoder)
    {
        super.encode(with: coder)
        coder.encode(provider, forKey: "provider")
        coder.encode(qid, forKey: "qid")
        coder.encode(routeCalculationType, forKey: "routeCalculationType")
        coder.encode(additionalQueryParams, forKey: "additionalQueryParams")
        coder.encode(routeSignature, forKey: "routeSignature")
        coder.encode(carVehicle, forKey: "carVehicle")
        coder.encode(motorbikeVehicule, forKey: "motorbikeVehicule")
        coder.encode(walkSpeed?.rawValue, forKey: "walkSpeed")
        coder.encode(bikeSpeed?.rawValue, forKey: "bikeSpeed")
        coder.encode(forceBetterRoute, forKey: "forceBetterRoute")
    }

    // MARK: - Properties

    public let apiVersion: String = "1.0"

    /**
     Route provider.
     */
    open private(set) var provider: String

    /**
     Type of metric to use to calculate the itineary.
     */
    open private(set) var routeCalculationType: String

    /**
     QID used in initial transport/routes requests.
     */
    open private(set) var qid: String

    /**
     Additional params to be passed in request URL.

     Known params are removed from this array and set to the corresponding property.
     */
    open private(set) var additionalQueryParams: [String:String]

    /**
     Opaque `Route` signature if requesting the server an updated version of an existing route.
     */
    open var routeSignature: String?

    /**
     Vehicle used for car transportation by the user.
     */
    open var carVehicle: String?

    /**
     Vehicle used for motorbike transportation by the user.
     */
    open var motorbikeVehicule: String?

    /**
     Walking speed of the user (only for pedestrian itineraries).
     */
    open var walkSpeed: MappyWalkSpeed?

    /**
     Cycling speed of the user (only for bike itineraries).
     */
    open var bikeSpeed: MappyBikeSpeed?

    /**
     Debug parameter to force the service to respond with an arbitrary alternative route that will be marked as better.
     */
    open var forceBetterRoute: Bool = false

    // MARK: - Overrides

    /**
     The path of the request URL, not including the hostname or any parameters.
     */
    internal override var path: String
    {
        return super.path.replacingOccurrences(of: ".json", with: "")
    }
    
    internal override var abridgedPath: String {
        return "gps/\(apiVersion)/\(provider)"
    }

    /**
     An array of URL parameters to include in the request URL.
     */
    override open var urlQueryItems: [URLQueryItem]
    {
        var params: [URLQueryItem] = [
            URLQueryItem(name: "geometries", value: String(describing: shapeFormat)),
            URLQueryItem(name: "lang", value: locale.identifier),
            URLQueryItem(name: "qid", value: qid),
            URLQueryItem(name: "route_type", value: self.routeCalculationType)
        ]

        if self.routeSignature != nil
        {
            params.append(URLQueryItem(name: "alternatives", value: String(includesAlternativeRoutes)))
            if self.forceBetterRoute == true && self.includesAlternativeRoutes == true
            {
                params.append(URLQueryItem(name: "dev_better_route_threshold", value: "-1"))
            }
        }

        if let bearing = self.waypoints.first?.heading,
            bearing >= 0
        {
            params.append(URLQueryItem(name: "bearing", value: "\(Int(bearing.truncatingRemainder(dividingBy: 360)))"))
        }
        if let carVehicle = carVehicle
        {
            params.append(URLQueryItem(name: "vehicle", value: carVehicle))
        }
        if let motorbikeVehicule = motorbikeVehicule
        {
            params.append(URLQueryItem(name: "motorbike_vehicle", value: motorbikeVehicule))
        }
        if let walkSpeed = walkSpeed
        {
            params.append(URLQueryItem(name: "walk_speed", value: walkSpeed.rawValue))
        }
        if let bikeSpeed = bikeSpeed
        {
            params.append(URLQueryItem(name: "bike_speed", value: bikeSpeed.rawValue))
        }

        if !waypoints.compactMap({ $0.name }).isEmpty
        {
            let names = waypoints.map { $0.name ?? "" }.joined(separator: ";")
            params.append(URLQueryItem(name: "waypoint_names", value: names))
        }

        let additionalItems = self.additionalQueryParams.map { return URLQueryItem(name: $0.key, value: $0.value) }
        params.append(contentsOf: additionalItems)

        return params
    }

    /**
     Data to send in the request body.
     */
    override internal var data: Data?
    {
        if let signature = self.routeSignature
        {
            let json = ["mappy_signature": signature]
            let data = try? JSONSerialization.data(withJSONObject: json, options: [])
            return data
        }
        return nil
    }

    /**
     Content-Type to set for the request if `requestData` is not nil.
     */
    override internal var contentType: String?
    {
        return "application/json"
    }

    /**
     Returns response objects that represent the given JSON dictionary data.

     - parameter json: The API response in JSON dictionary format.
     - returns: A tuple containing an array of waypoints and an array of routes.
     */
    public override func response(from json: [String: Any]) -> ([Waypoint]?, [Route]?)
    {
        var namedWaypoints: [Waypoint]?
        if let jsonWaypoints = (json["waypoints"] as? [JSONDictionary]) {
            namedWaypoints = zip(jsonWaypoints, self.waypoints).map { (api, local) -> Waypoint in
                let location = api["location"] as! [Double]
                let coordinate = CLLocationCoordinate2D(geoJSON: location)
                let possibleAPIName = api["name"] as? String
                let apiName = possibleAPIName?.nonEmptyString
                let waypoint = local.copy() as! Waypoint
                waypoint.coordinate = coordinate
                waypoint.name = waypoint.name ?? apiName
                return waypoint
            }
        }

        let waypoints = namedWaypoints ?? self.waypoints

        var congestionColors = [String: String]()
        (json["mappy_congestion_colors"] as? [[String: String]])?.forEach
            {
                let label = $0["label"] ?? "unknown"
                let color = $0["color"] ?? "#000000"
                congestionColors[label] = color
        }

        let routes = (json["routes"] as? [JSONDictionary])?.map { (jsonRoute) -> MappyRoute in
            let newOptions = self.copy() as! MappyNavigationRouteOptions
            newOptions.forceBetterRoute = false
            return MappyRoute(json: jsonRoute, waypoints: waypoints, congestionColors: congestionColors, options: newOptions)
        }
        return (waypoints, routes)
    }

    override public class var supportsSecureCoding: Bool
    {
        return true
    }

    // MARK: - NSCopying

    override open func copy(with zone: NSZone? = nil) -> Any
    {
        let copy = super.copy(with: zone) as! MappyNavigationRouteOptions
        copy.provider = provider
        copy.qid = qid
        copy.routeCalculationType = routeCalculationType
        copy.additionalQueryParams = additionalQueryParams
        copy.routeSignature = routeSignature
        copy.carVehicle = carVehicle
        copy.motorbikeVehicule = motorbikeVehicule
        copy.walkSpeed = walkSpeed
        copy.bikeSpeed = bikeSpeed
        copy.forceBetterRoute = forceBetterRoute
        return copy
    }

    // MARK: - Objective-C Equality

    open override func isEqual(_ object: Any?) -> Bool
    {
        guard let options = object as? MappyNavigationRouteOptions else { return false }
        return isEqual(to: options)
    }

    @objc(isEqualToMappyNavigationRouteOptions:)
    open func isEqual(to mappyNavigationRouteOptions: MappyNavigationRouteOptions?) -> Bool
    {
        guard let other = mappyNavigationRouteOptions else { return false }
        guard super.isEqual(to: mappyNavigationRouteOptions) else { return false }
        guard provider == other.provider,
            qid == other.qid,
            routeCalculationType == other.routeCalculationType,
            additionalQueryParams == other.additionalQueryParams,
            routeSignature == other.routeSignature,
            carVehicle == other.carVehicle,
            motorbikeVehicule == other.motorbikeVehicule,
            walkSpeed == other.walkSpeed,
            bikeSpeed == other.bikeSpeed,
            forceBetterRoute == other.forceBetterRoute
            else { return false }
        return true
    }
}
