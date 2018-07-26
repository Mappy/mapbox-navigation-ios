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
	Initializes a navigation route options object for routes between the given waypoints and an optional profile identifier optimized for navigation.
	*/
	public init(waypoints: [Waypoint], provider: String, qid: String)
	{
		self.provider = provider
		self.qid = qid

		super.init(waypoints: waypoints.map {
			$0.coordinateAccuracy = -1
			return $0
		}, profileIdentifier: .automobileAvoidingTraffic)

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

	/**
	Initializes a navigation route options object for routes between the given locations and an optional profile identifier optimized for navigation.
	*/
	public convenience init(locations: [CLLocation], provider: String, qid: String)
	{
		self.init(waypoints: locations.map { Waypoint(location: $0) }, provider: provider, qid: qid)
	}

	/**
	Initializes a route options object for routes between the given geographic coordinates and an optional profile identifier optimized for navigation.
	*/
	public convenience init(coordinates: [CLLocationCoordinate2D], provider: String, qid: String)
	{
		self.init(waypoints: coordinates.map { Waypoint(coordinate: $0) }, provider: provider, qid: qid)
	}

	public required init(waypoints: [Waypoint], profileIdentifier: MBDirectionsProfileIdentifier?)
	{
		self.provider = ""
		self.qid = ""
		super.init(waypoints: waypoints, profileIdentifier: profileIdentifier)
	}

	// MARK: - NSCoding

	public required init?(coder decoder: NSCoder)
	{
		self.provider = decoder.decodeObject(of: NSString.self, forKey: "provider") as String? ?? ""
		self.qid = decoder.decodeObject(of: NSString.self, forKey: "qid") as String? ?? ""
		self.routeCalculationType = decoder.decodeObject(of: NSString.self, forKey: "routeCalculationType") as String? ?? ""
		self.routeSignature = decoder.decodeObject(of: NSString.self, forKey: "routeSignature") as String?
		self.vehicle = decoder.decodeObject(of: NSString.self, forKey: "vehicle") as String?
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
		coder.encode(routeSignature, forKey: "routeSignature")
		coder.encode(vehicle, forKey: "vehicle")
		coder.encode(walkSpeed?.rawValue, forKey: "walkSpeed")
		coder.encode(bikeSpeed?.rawValue, forKey: "bikeSpeed")
		coder.encode(forceBetterRoute, forKey: "forceBetterRoute")
	}

	// MARK: - Properties

	open let apiVersion: String = "1.0"

	/**
	Route provider.
	*/
	open var provider: String

	/**
	QID used in initial transport/routes requests.
	*/
	open var qid: String

	/**
	Type of metric to use to calculate the itineary.
	*/
	open var routeCalculationType: String?

	/**
	Opaque `Route` signature if requesting the server an updated version of an existing route.
	*/
	open var routeSignature: String?

	/**
	Vehicle used for transport by the user (only for car and motorbike itineraries).
	*/
	open var vehicle: String?

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
		assert(!queries.isEmpty, "No query")

		let queryComponent = queries.joined(separator: ";")
		return "gps/\(apiVersion)/\(provider)/\(queryComponent)"
	}

	/**
	An array of URL parameters to include in the request URL.
	*/
	internal override var params: [URLQueryItem]
	{
		var params: [URLQueryItem] = [
			URLQueryItem(name: "geometries", value: String(describing: shapeFormat)),
			URLQueryItem(name: "lang", value: locale.identifier),
			URLQueryItem(name: "qid", value: qid)
		]

		if self.routeSignature != nil
		{
			params.append(URLQueryItem(name: "alternatives", value: String(includesAlternativeRoutes)))
			if self.forceBetterRoute == true && self.includesAlternativeRoutes == true
			{
				params.append(URLQueryItem(name: "dev_better_route_threshold", value: "-1"))
			}
		}
		if let routeCalculationType = routeCalculationType
		{
			params.append(URLQueryItem(name: "route_type", value: routeCalculationType))
		}
		if let bearing = self.waypoints.first?.heading,
			bearing >= 0
		{
			params.append(URLQueryItem(name: "bearing", value: "\(Int(bearing.truncatingRemainder(dividingBy: 360)))"))
		}
		if let vehicle = vehicle
		{
			params.append(URLQueryItem(name: "vehicle", value: vehicle))
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
	public override func response(from json: JSONDictionary) -> ([Waypoint]?, [Route]?)
	{
		var namedWaypoints: [Waypoint]?
		if let jsonWaypoints = (json["waypoints"] as? [JSONDictionary]) {
			namedWaypoints = zip(jsonWaypoints, self.waypoints).map { (api, local) -> Waypoint in
				let location = api["location"] as! [Double]
				let coordinate = CLLocationCoordinate2D(geoJSON: location)
				let possibleAPIName = api["name"] as? String
				let apiName = possibleAPIName?.nonEmptyString
				return Waypoint(coordinate: coordinate, name: local.name ?? apiName)
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

		let routes = (json["routes"] as? [JSONDictionary])?.map {
			MappyRoute(json: $0, waypoints: waypoints, congestionColors: congestionColors, options: self.copy() as! MappyNavigationRouteOptions)
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
		copy.routeSignature = routeSignature
		copy.vehicle = vehicle
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
			routeSignature == other.routeSignature,
			vehicle == other.vehicle,
			walkSpeed == other.walkSpeed,
			bikeSpeed == other.bikeSpeed,
			forceBetterRoute == other.forceBetterRoute
			else { return false }
		return true
	}
}
