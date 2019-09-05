import Foundation
import CoreLocation
import MapboxDirections

@objc public protocol NavigationServiceDebugDelegate {

    @objc(navigationServiceDebug:didUpdateLocations:)
    func navigationServiceDebug(_ service: NavigationService, didUpdateLocations locations: [CLLocation])
}
