import Foundation
import CoreLocation
import MapboxDirections

public protocol NavigationServiceDebugDelegate: class {
    func navigationServiceDebug(_ service: NavigationService, didUpdateLocations locations: [CLLocation])
}
