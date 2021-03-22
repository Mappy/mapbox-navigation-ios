import Foundation
import CoreLocation


public class MappyReplayLocationManager: NavigationLocationManager {

    public var speedMultiplier: TimeInterval = 1

    var currentIndex: Int = 0

    private var lastKnownLocation: CLLocation?

    public var locations: [CLLocation]! {
        didSet {
            currentIndex = 0
            lastKnownLocation = nil
        }
    }

    override public var location: CLLocation? {
        get {
            return lastKnownLocation
        }
    }

    public init(locations: [CLLocation]) {
        self.locations = locations
        super.init()
    }

    deinit {
        stopUpdatingLocation()
    }

    override open func startUpdatingLocation() {
        tick()
    }

    override open func stopUpdatingLocation() {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(tick), object: nil)
    }

    public func moveToLocation(at index: Int) {
        guard index < locations.count - 1 else {
            return
        }

        if index > 0 {
            let previousLocation = locations[index - 1]
            lastKnownLocation = previousLocation
        }
        else {
            lastKnownLocation = nil
        }
        currentIndex = index
    }

    @objc fileprivate func tick() {
        let location = locations[currentIndex]
        lastKnownLocation = location
        delegate?.locationManager?(self, didUpdateLocations: [location])
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(tick), object: nil)

        if currentIndex < locations.count - 1 {
            let nextLocation = locations[currentIndex+1]
            let interval = nextLocation.timestamp.timeIntervalSince(location.timestamp) / TimeInterval(speedMultiplier)
            currentIndex += 1
            perform(#selector(tick), with: nil, afterDelay: interval)
        }
    }
}

