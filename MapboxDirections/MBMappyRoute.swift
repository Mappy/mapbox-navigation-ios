import Foundation

/**
 A `MappyRouteType` indentifies the type of a route object returned by the Mappy Directions API.
 */
@objc(MBMappyRouteType)
public enum MappyRouteType: Int, CustomStringConvertible
{
    /**
     The route is an updated version (durations, traffic, etc) of a previous route following a given itinerary.
     */
    case current
    /**
     The route is a faster alternative to a route of type `current` returned in the same Directions response.
     
     The route starts and ends at the same waypoints than the `current` route returned along in the same response.
     */
    case best

    public init?(description: String) {
        let type: MappyRouteType
        switch description {
        case "current":
            type = .current
        case "best":
            type = .best
        default:
            return nil
        }
        self.init(rawValue: type.rawValue)
    }

    public var description: String {
        switch self {
        case .current:
            return "current"
        case .best:
            return "best"
        }
    }
}

/**
 A `MapppyRoute` object is a normal `Route` object with additionnal data specific to Mappy API.
 */
@objc(MBMappyRoute)
public class MappyRoute: Route
{
    public let routeType: MappyRouteType
    public let signature: String
    public let congestionColors: [String: String]?
    
    init(json: JSONDictionary, waypoints: [Waypoint], congestionColors: [String: String]?, options: MappyNavigationRouteOptions)
    {
        self.routeType = MappyRouteType(description: json["mappy_designation"] as? String ?? "") ?? .current
        let routeSignature = json["mappy_signature"] as? String ?? ""
        self.signature = routeSignature
        options.routeSignature = routeSignature
        self.congestionColors = congestionColors
        
        super.init(json: json, waypoints: waypoints, options: options)
    }
    
    public required init?(coder decoder: NSCoder)
    {
        self.routeType = MappyRouteType(description: decoder.decodeObject(of: NSString.self, forKey: "routeType") as String? ?? "") ?? .current
        self.signature = decoder.decodeObject(of: NSString.self, forKey: "signature") as String? ?? ""
        self.congestionColors = decoder.decodeObject(of: [NSDictionary.self, NSString.self, NSString.self], forKey: "congestionColors") as? [String: String]
        
        super.init(coder: decoder)
    }
    
    @objc public override func encode(with coder: NSCoder)
    {
        coder.encode(routeType.description, forKey: "routeType")
        coder.encode(signature, forKey: "signature")
        coder.encode(congestionColors, forKey: "congestionColors")
        
        super.encode(with: coder)
    }
}
