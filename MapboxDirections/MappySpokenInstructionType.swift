import Foundation

/**
 A `MappySpokenInstructionType` indentifies the type of a SpokenInstruction instruction returned by the Mappy Directions API.
 */
@objc(MBMappySpokenInstructionType)
public enum MappySpokenInstructionType: Int, CustomStringConvertible
{
    /**
     The spoken instruction announces an upcoming maneuver.
     */
    case maneuver
    
    /**
     The spoken instruction announces the entering into a zone where controls of the user driving can occur.
     */
    case controlZoneEnter
    
    /**
     The spoken instruction announces the exiting of a zone where controls of the user driving can occur.
     */
    case controlZoneExit
    
    public init?(description: String) {
        let type: MappySpokenInstructionType
        switch description {
        case "maneuver":
            type = .maneuver
        case "controlZoneEnter":
            type = .controlZoneEnter
        case "controlZoneExit":
            type = .controlZoneExit
        default:
            return nil
        }
        self.init(rawValue: type.rawValue)
    }
    
    public var description: String {
        switch self {
        case .maneuver:
            return "maneuver"
        case .controlZoneEnter:
            return "controlZoneEnter"
        case .controlZoneExit:
            return "controlZoneExit"
        }
    }
}
