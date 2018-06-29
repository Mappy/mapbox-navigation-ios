import UIKit
import CoreLocation
import MapboxDirections
import Mapbox

// A Mapbox access token is required to use the Directions API.
// https://www.mapbox.com/help/create-api-access-token/
let MapboxAccessToken = "sk.eyJ1IjoieGF2aWVyY291dGluIiwiYSI6IldfdlRPVlkifQ.Kdk-xoV7zPNAcD_FJtA-UQ"

class ViewController: UIViewController, MBDrawingViewDelegate {
    @IBOutlet var mapView: MGLMapView!
    var drawingView: MBDrawingView?
    var segmentedControl: UISegmentedControl!
    static let initialMapCenter = CLLocationCoordinate2D(latitude: 37.3300, longitude: -122.0312)
    static let initialZoom: Double = 15
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        assert(MapboxAccessToken != "<# your Mapbox access token #>", "You must set `MapboxAccessToken` to your Mapbox access token.")
        MGLAccountManager.setAccessToken(MapboxAccessToken)
        
        mapView = MGLMapView(frame: view.bounds)
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        mapView.setCenter(ViewController.initialMapCenter, animated: false)
        mapView.setZoomLevel(ViewController.initialZoom, animated: false)
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .follow
        view.addSubview(mapView)
        
        setUpSegmentedControls()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    func setUpSegmentedControls() {
        let items = ["Move", "Draw", "Directions"]
        segmentedControl = UISegmentedControl(items: items)
        let frame = UIScreen.main.bounds
        segmentedControl.frame = CGRect(x: frame.minX + 10, y: frame.minY + 50, width: frame.width - 20, height: 30)
        segmentedControl.selectedSegmentIndex = 0
        segmentedControl.backgroundColor = .white
        segmentedControl.addTarget(self, action: #selector(segmentedValueChanged(_:)), for: .valueChanged)
        self.view.addSubview(segmentedControl)
    }
    
    @objc func segmentedValueChanged(_ sender: UISegmentedControl) {
        resetDrawingView()
        
        switch sender.selectedSegmentIndex {
        case 1:
            setupDrawingView()
        case 2:
            setupDirections()
        default:
            return
        }
    }
    
    func resetDrawingView() {
        if let annotations = mapView.annotations {
            mapView.removeAnnotations(annotations)
        }
        drawingView?.reset()
        drawingView?.removeFromSuperview()
        drawingView = nil
        mapView.isUserInteractionEnabled = true
    }
    
    func setupDirections() {
//        let options = RouteOptions(waypoints: [
//            Waypoint(coordinate: CLLocationCoordinate2D(latitude: 48.8502559801871, longitude: 2.30837619054591), name: "Mapbox"),
//            Waypoint(coordinate: CLLocationCoordinate2D(latitude: 48.8448336928138, longitude: 2.3193625185628), name: "White House"),
//            ])
//        options.includesSteps = true

		let departure = Waypoint(coordinate: CLLocationCoordinate2D(latitude: 48.8502559801871, longitude: 2.30837619054591), name: "Mapbox")
		departure.heading = 78.0001
		let arrival = Waypoint(coordinate: CLLocationCoordinate2D(latitude: 48.8448336928138, longitude: 2.3193625185628), name: "Maine - Vaugirard")
		let options = MappyNavigationRouteOptions(waypoints: [departure, arrival],
												  provider: "car",
												  qid: "1ad02a47-0e87-48f4-d190-a794fbbb6aac")
		options.shapeFormat = .geoJSON
		options.routeCalculationType = "fastest"
		options.vehicle = "comcar"
		options.walkSpeed = .normal
		options.bikeSpeed = .fast
		options.includesAlternativeRoutes = false
		options.routeSignature = "{\"legs\":[{\"end_offset\":0.5174573291,\"start_offset\":0.0791643457,\"path\":[12500001662182,12500001605371,12500001793085,12500001409972,12500001554967,12500001284146,12500001824262,12500001292524,12500001601838,12500001601837,12500001369147,12500001494157,12500001500045,12500001546884,12500001027504,12500000981188,12500001472033,12500001472034,12500001805334,12500001131745,12500001021176,12500001600626,12500001407018,12500001082194,12500001613011,12500001808104,12500001095874,12500001112472,12500000982166,12500001002638,12500001731391,12500001048324,12500001048796,12500001395539,12500001498399,12500001099033,12500001181500,12500001158527]}]}"

		Directions(accessToken: "dummy", host: "routemm.mappyrecette.net")
//        Directions(accessToken: MapboxAccessToken)
			.calculate(options) { (waypoints, routes, error) in
            guard error == nil else {
                print("Error calculating directions: \(error!)")
                return
            }
            
            if let route = routes?.first, let leg = route.legs.first {
                print("Route via \(leg):")
                
                let distanceFormatter = LengthFormatter()
                let formattedDistance = distanceFormatter.string(fromMeters: route.distance)
                
                let travelTimeFormatter = DateComponentsFormatter()
                travelTimeFormatter.unitsStyle = .short
                let formattedTravelTime = travelTimeFormatter.string(from: route.expectedTravelTime)
                
                print("Distance: \(formattedDistance); ETA: \(formattedTravelTime!)")
                
                for step in leg.steps {
                    print("\(step.instructions)")
                    if step.distance > 0 {
                        let formattedDistance = distanceFormatter.string(fromMeters: step.distance)
                        print("— \(formattedDistance) —")
                    }
                }
                
                if route.coordinateCount > 0 {
                    // Convert the route’s coordinates into a polyline.
                    var routeCoordinates = route.coordinates!
                    let routeLine = MGLPolyline(coordinates: &routeCoordinates, count: route.coordinateCount)
                    
                    // Add the polyline to the map and fit the viewport to the polyline.
                    self.mapView.addAnnotation(routeLine)
                    self.mapView.setVisibleCoordinates(&routeCoordinates, count: route.coordinateCount, edgePadding: .zero, animated: true)
                }
            }
        }
    }
    
    func setupDrawingView() {
        drawingView = MBDrawingView(frame: view.bounds, strokeColor: .red, lineWidth: 1)
        drawingView!.autoresizingMask = mapView.autoresizingMask
        drawingView!.delegate = self
        view.insertSubview(drawingView!, belowSubview: segmentedControl)
        
        mapView.isUserInteractionEnabled = false
        
        let unpitchedCamera = mapView.camera
        unpitchedCamera.pitch = 0
        mapView.setCamera(unpitchedCamera, animated: true)
    }
    
    func drawingView(drawingView: MBDrawingView, didDrawWithPoints points: [CGPoint]) {
        
        let coordinates = points.map {
            mapView.convert($0, toCoordinateFrom: mapView)
        }
        makeMatchRequest(locations: coordinates)
    }
    
    func makeMatchRequest(locations: [CLLocationCoordinate2D]) {
        let matchOptions = MatchOptions(coordinates: locations)

        Directions(accessToken: MapboxAccessToken).calculate(matchOptions) { (matches, error) in
            if let error = error {
                print(error.localizedDescription)
                return
            }
            
            guard let matches = matches, let match = matches.first else { return }
            
            if let annotations = self.mapView.annotations {
                self.mapView.removeAnnotations(annotations)
            }
            
            var routeCoordinates = match.coordinates!
            let routeLine = MGLPolyline(coordinates: &routeCoordinates, count: match.coordinateCount)
            self.mapView.addAnnotation(routeLine)
            self.drawingView?.reset()
        }
    }
}
