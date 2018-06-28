import Foundation

/**
The walking speed of the user.

Only used for pedestrian itineraries.
*/
public enum MappyWalkSpeed: String
{
	case slow = "slow"
	case normal = "normal"
	case fast = "fast"
}

/**
The cycling speed of the user.

Only used for bike itineraries.
*/
public enum MappyBikeSpeed: String
{
	case slow = "slow"
	case normal = "normal"
	case fast = "fast"
}

/**
A `MappyRouteType` indentifies the type of a route object returned by the Mappy Directions API.
*/
public enum MappyRouteType: String
{
	/**
	The route is an updated version (durations, traffic, etc) of a previous route following a given itinerary.
	*/
	case current = "current"
	/**
	The route is a faster alternative to a route of type `current` returned in the same Directions response.

	The route starts and ends at the same waypoints than the `current` route returned along in the same response.
	*/
	case best = "best"
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
		fatalError("init(waypoints:profileIdentifier:) has not been implemented")
	}

	// MARK: - NSCoding

	public required init?(coder decoder: NSCoder)
	{
		self.provider = decoder.decodeObject(of: NSString.self, forKey: "provider") as String? ?? ""
		self.qid = decoder.decodeObject(of: NSString.self, forKey: "qid") as String? ?? ""
		self.routeCalculationType = decoder.decodeObject(of: NSString.self, forKey: "routeCalculationType") as String? ?? ""
		self.userBearing = decoder.decodeDouble(forKey: "userBearing") as CLLocationDegrees?
		self.vehicle = decoder.decodeObject(of: NSString.self, forKey: "vehicle") as String?
		self.walkSpeed = MappyWalkSpeed(rawValue: decoder.decodeObject(of: NSString.self, forKey: "walkSpeed") as String? ?? "")
		self.bikeSpeed = MappyBikeSpeed(rawValue: decoder.decodeObject(of: NSString.self, forKey: "bikeSpeed") as String? ?? "")

		super.init(coder: decoder)
	}

	public override func encode(with coder: NSCoder)
	{
		super.encode(with: coder)
		coder.encode(provider, forKey: "provider")
		coder.encode(qid, forKey: "qid")
		coder.encode(routeCalculationType, forKey: "routeCalculationType")
		coder.encode(userBearing, forKey: "userBearing")
		coder.encode(vehicle, forKey: "vehicle")
		coder.encode(walkSpeed?.rawValue, forKey: "walkSpeed")
		coder.encode(bikeSpeed?.rawValue, forKey: "bikeSpeed")
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
	Bearing of the user in degrees from north.
	*/
	open var userBearing: CLLocationDirection?

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
			URLQueryItem(name: "lang", value: locale.identifier)
		]

		params.append(URLQueryItem(name: "qid", value: qid))
		params.append(URLQueryItem(name: "alternatives", value: String(includesAlternativeRoutes)))

		if let routeCalculationType = routeCalculationType
		{
			params.append(URLQueryItem(name: "gps_route_type", value: routeCalculationType))
		}
		if let bearing = userBearing
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
		copy.userBearing = userBearing
		copy.vehicle = vehicle
		copy.walkSpeed = walkSpeed
		copy.bikeSpeed = bikeSpeed
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
			userBearing == other.userBearing,
			vehicle == other.vehicle,
			walkSpeed == other.walkSpeed,
			bikeSpeed == other.bikeSpeed
			else { return false }
		return true
	}
}
