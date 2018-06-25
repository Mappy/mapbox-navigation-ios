import Foundation

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
		provider = decoder.decodeObject(of: NSString.self, forKey: "provider") as String? ?? ""
		qid = decoder.decodeObject(of: NSString.self, forKey: "qid") as String? ?? ""
		routeType = decoder.decodeObject(of: NSString.self, forKey: "routeType") as String?
		vehicle = decoder.decodeObject(of: NSString.self, forKey: "vehicle") as String?
		walkSpeed = decoder.decodeObject(of: NSString.self, forKey: "walkSpeed") as String?
		destinationAddress = decoder.decodeObject(of: NSString.self, forKey: "destinationAddress") as String?
		super.init(coder: decoder)
	}

	public override func encode(with coder: NSCoder)
	{
		super.encode(with: coder)
		coder.encode(provider, forKey: "provider")
		coder.encode(qid, forKey: "qid")
		coder.encode(routeType, forKey: "routeType")
		coder.encode(vehicle, forKey: "vehicle")
		coder.encode(walkSpeed, forKey: "walkSpeed")
		coder.encode(destinationAddress, forKey: "destinationAddress")
	}

	// MARK: - Properties

	open let apiVersion: String = "1.0"

	/**
	Route provider.
	*/
	open var provider: String

	/**
	QID used in initial /routes request.
	*/
	open var qid: String

	/**
	Type of journey.
	*/
	open var routeType: String?

	/**
	Vehicle used for transport (only for car and motorbike).
	*/
	open var vehicle: String?

	/**
	Walk speed profile.
	*/
	open var walkSpeed: String?

	/**
	Stop address reported in GPS instructions.
	*/
	open var destinationAddress: String?


	// MARK: - Overrides

	/**
	An array of directions query strings to include in the request URL.
	*/
	internal override var queries: [String]
	{
		let q = super.queries
		return q
	}

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

		if let waypointAddress = destinationAddress
		{
			params.append(URLQueryItem(name: "address_to", value: waypointAddress))
		}
		if let routeType = routeType
		{
			params.append(URLQueryItem(name: "gps_route_type", value: routeType))
		}
		if let vehicle = vehicle
		{
			params.append(URLQueryItem(name: "vehicle", value: vehicle))
		}
		if let walkSpeed = walkSpeed
		{
			params.append(URLQueryItem(name: "walk_speed", value: walkSpeed))
		}

		// TODO: "bearings", "waypoint_names" ?

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
		copy.routeType = routeType
		copy.vehicle = vehicle
		copy.walkSpeed = walkSpeed
		copy.destinationAddress = destinationAddress
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
			routeType == other.routeType,
			vehicle == other.vehicle,
			walkSpeed == other.walkSpeed,
			destinationAddress == other.destinationAddress else { return false }
		return true
	}
}
