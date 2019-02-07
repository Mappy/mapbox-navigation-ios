import Foundation

/**
 Object representing max speeds along a route.
*/

@objc(MBMaxSpeed)
open class MaxSpeed: NSObject, NSSecureCoding {
    
    // MARK: Creating a Leg
    
    /**
     Initializes a new maxSpeed object with the given JSON dictionary representation.
     */
    @objc(initWithJSON:)
    public init(json: [String: Any]) {
        speed = json["speed"] as? NSNumber
        unit = json["unit"] as? String
    }
    
    public required init?(coder decoder: NSCoder) {
        speed = decoder.decodeObject(forKey: "speed") as? NSNumber
        unit = decoder.decodeObject(forKey: "unit") as? String
    }
    
    @objc public static var supportsSecureCoding = true
    
    public func encode(with coder: NSCoder) {
        coder.encode(speed, forKey: "speed")
        coder.encode(unit, forKey: "unit")
    }
    
    // MARK: Getting the MaxSpeed content
    
    /**
     Number indicating the posted speed limit.
     */
    @objc public let speed: NSNumber?
    
    /**
     String indicating the unit of speed, either as `km/h` or `mph`.
     */
    @objc public let unit: String?
}
