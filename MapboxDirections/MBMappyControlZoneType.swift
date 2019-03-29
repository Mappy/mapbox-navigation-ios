import Foundation

/**
 `MappyControlZoneType` describes the type of `MappyControlZoneInstruction`.
 */
@objc(MBMappyControlZoneType)
public enum MappyControlZoneType: Int, CustomStringConvertible
{
    /**
     The controls that can occur in the zone refer to the user driving speed.
     */
    case speed
    
    /**
     The controls that can occur in the zone refer to unknown or undisclosed aspects of the user driving.
     */
    case other
    
    public init?(description: String) {
        let type: MappyControlZoneType
        switch description {
        case "speed":
            type = .speed
        case "miscellanous":
            type = .other
        default:
            return nil
        }
        self.init(rawValue: type.rawValue)
    }
    
    public var description: String {
        switch self {
        case .speed:
            return "speed"
        case .other:
            return "miscellanous"
        }
    }
}
