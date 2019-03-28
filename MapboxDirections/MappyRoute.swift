import Foundation

/**
 A `MappyRouteType` indentifies the type of a route object returned by the Mappy Directions API.
 */
public enum MappyRouteType: String
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
}

/**
 A `MapppyRoute` object is a normal `Route` object with additionnal data specific to Mappy API.
 */
public class MappyRoute: Route
{
    public let routeType: MappyRouteType
    public let signature: String
    public let congestionColors: [String: String]?
    
    init(json: JSONDictionary, waypoints: [Waypoint], congestionColors: [String: String]?, options: MappyNavigationRouteOptions)
    {
        self.routeType = MappyRouteType(rawValue: json["mappy_designation"] as? String ?? "") ?? .current
        let routeSignature = json["mappy_signature"] as? String ?? ""
        self.signature = routeSignature
        options.routeSignature = routeSignature
        self.congestionColors = congestionColors
        
        super.init(json: json, waypoints: waypoints, options: options)
    }
    
    public required init?(coder decoder: NSCoder)
    {
        self.routeType = MappyRouteType(rawValue: decoder.decodeObject(of: NSString.self, forKey: "routeType") as String? ?? "") ?? .current
        self.signature = decoder.decodeObject(of: NSString.self, forKey: "signature") as String? ?? ""
        self.congestionColors = decoder.decodeObject(of: [NSDictionary.self, NSString.self, NSString.self], forKey: "congestionColors") as? [String: String]
        
        super.init(coder: decoder)
    }
    
    @objc public override func encode(with coder: NSCoder)
    {
        coder.encode(routeType.rawValue, forKey: "routeType")
        coder.encode(signature, forKey: "signature")
        coder.encode(congestionColors, forKey: "congestionColors")
        
        super.encode(with: coder)
    }
}
