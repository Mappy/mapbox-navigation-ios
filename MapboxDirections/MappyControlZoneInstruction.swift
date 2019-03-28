import Foundation

/**
 The contents of an additional instruction that can be displayed to inform the user about a zone along which controls of his driving can occur.
 */
@objc
open class MappyControlZoneInstruction: VisualInstruction
{
    /**
     The type of controls that can occur in the control zone.
     */
    @objc public let controlZoneType: MappyControlZoneType

    /**
     The distance the user will be navigating inside the control zone if he keeps following the associated Route, measured in meters from the beginning of the control zone.
     */
    @objc public let distanceAlongRoute: CLLocationDistance

    /**
     Initializes a new control zone instruction object.
     */
    @objc public init(text: String?, maneuverType: ManeuverType, maneuverDirection: ManeuverDirection, components: [ComponentRepresentable], controlZoneType: MappyControlZoneType, distanceAlongRoute: CLLocationDistance)
    {
        self.controlZoneType = controlZoneType
        self.distanceAlongRoute = distanceAlongRoute
        super.init(text: text, maneuverType: maneuverType, maneuverDirection: maneuverDirection, components: components)
    }

    /**
     Initializes a new control zone instruction object based on the given JSON dictionary representation.

     - parameter json: A JSON object that conforms to the control zone instruction format returned by the Mappy Directions API.
     */
    @objc(initWithJSON:)
    public override init(json: [String: Any])
    {
        self.controlZoneType = MappyControlZoneType(description: json["controlZoneType"] as? String ?? "") ?? .other
        self.distanceAlongRoute = json["distanceUntilEndOfControlZone"] as! CLLocationDistance

        super.init(json: json)
    }

    @objc public required init?(coder decoder: NSCoder)
    {
        controlZoneType = MappyControlZoneType(description: decoder.decodeObject(of: NSString.self, forKey: "controlZoneType") as String? ?? "") ?? .other
        distanceAlongRoute = decoder.decodeDouble(forKey: "distanceAlongRoute")

        super.init(coder: decoder)
    }

    public override func encode(with coder: NSCoder)
    {
        super.encode(with: coder)

        coder.encode(controlZoneType.description, forKey: "controlZoneType")
        coder.encode(distanceAlongRoute, forKey: "distanceAlongRoute")
    }
}
