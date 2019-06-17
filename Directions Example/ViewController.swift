import UIKit
import CoreLocation
import MapboxDirections
import Mapbox

// A Mapbox access token is required to use the Directions API.
// https://docs.mapbox.com/help/how-mapbox-works/access-tokens/#creating-and-managing-access-tokens
let MapboxAccessToken = "pk.eyJ1IjoibWFwcHlpb3MiLCJhIjoiY2pqaWh5OGZuMTJ2MzN2cm1heHpmZmVjbCJ9.zT4TP13qJsNthxAUuYMYmg"

class ViewController: UIViewController, MBDrawingViewDelegate {
    @IBOutlet var mapView: MGLMapView!
    var drawingView: MBDrawingView?
    var segmentedControl: UISegmentedControl!
    static let initialMapCenter = CLLocationCoordinate2D(latitude: 37.3300, longitude: -122.0312)
    static let initialZoom: Double = 15
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        assert(MapboxAccessToken != "<# your Mapbox access token #>", "You must set `MapboxAccessToken` to your Mapbox access token.")
        MGLAccountManager.accessToken = MapboxAccessToken
        
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
//        let wp1 = Waypoint(coordinate: CLLocationCoordinate2D(latitude: 38.9131752, longitude: -77.0324047), name: "Mapbox")
//        let wp2 = Waypoint(coordinate: CLLocationCoordinate2D(latitude: 38.8977, longitude: -77.0365), name: "White House")
//        wp1.allowsArrivingOnOppositeSide = false
//        wp2.allowsArrivingOnOppositeSide = false
//        let options = RouteOptions(waypoints: [wp1, wp2])
//        options.includesSteps = true
        
        let makeParisBordeauxWaypoints: (() -> [Waypoint]) = {
            let Paris = Waypoint(coordinate: CLLocationCoordinate2D(latitude: 48.86, longitude: 2.34), name: "Paris")
            Paris.heading = 78.0001
            let Bordeaux = Waypoint(coordinate: CLLocationCoordinate2D(latitude: 44.845177, longitude: -0.471071), name: "Bordeaux")
            return [Paris, Bordeaux]
        }
        let makeRoundaboutWaypoints: (() -> [Waypoint]) = {
            let departure = Waypoint(coordinate: CLLocationCoordinate2D(latitude: 49.013763, longitude: 1.195359))
            let arrival = Waypoint(coordinate: CLLocationCoordinate2D(latitude: 49.015516, longitude: 1.184420))
            return [departure, arrival]
        }
        
        let makeOptionsWithExplicitParams: (() -> MappyNavigationRouteOptions) = {
            let options = MappyNavigationRouteOptions(
                waypoints: makeParisBordeauxWaypoints(),
                provider: "car",
                routeCalculationType: "fastest",
                qid: "1ad02a47-0e87-48f4-d190-a794fbbb6aac")
            options.shapeFormat = .polyline6
            options.carVehicle = "comcar"
            options.motorbikeVehicule = "moto125"
            options.walkSpeed = .slow
            options.bikeSpeed = .fast
//            options.includesAlternativeRoutes = true
//            options.forceBetterRoute = true
            options.routeSignature = nil
            return options
        }
        
        let makeOptionsWithUntypedQueryParams: (() -> MappyNavigationRouteOptions) = {
            let options = MappyNavigationRouteOptions(
                waypoints: makeRoundaboutWaypoints(),
                provider: "car",
                additionalQueryParams: [
                    "route_type": "fastest",
                    "qid": "1ad02a47-0e87-48f4-d190-a794fbbb6aac",
                    "vehicle": "comcar",
                    "motorbike_vehicle": "moto125",
                    "walk_speed": "slow",
                    "bike_speed": "fast",
                    "foo": "bar",
                    ])
            options.shapeFormat = .polyline6
            return options
        }

        let makeRouteUpdateOptions: (() -> MappyNavigationRouteOptions) = {
            let options = MappyNavigationRouteOptions(
                waypoints: [
                    Waypoint(coordinate: CLLocationCoordinate2D(latitude: 48.8502559, longitude: 2.30837619), name: "Paris - Avenue de Ségur"),
                    Waypoint(coordinate: CLLocationCoordinate2D(latitude: 48.8448336, longitude: 2.3193625), name: "Paris - Rue de Vaugirard")
                ],
                provider: "car",
                routeCalculationType: "fastest",
                qid: "1ad02a47-0e87-48f4-d190-a794fbbb6aac")
            options.shapeFormat = .polyline6
            options.carVehicle = "comcar"
            options.motorbikeVehicule = "moto125"
            options.walkSpeed = .slow
            options.bikeSpeed = .fast
            options.includesAlternativeRoutes = true
            options.routeSignature = "{\"legs\":[{\"end_offset\":0.0056163842,\"start_offset\":0.9209722214,\"path\":[12500001662182,12500001554967,12500001284146,12500001824262,12500001292524,12500001601838,12500001601837,12500001369147,12500001494157,12500001500045,12500001546884,12500015399002,12500015398980,12500015384328,12500015385901,12500015384739,12500001472033,12500001472034,12500001805334,12500001131745,12500015384156,12500015386598,12500001600626,12500001407018,12500015398972,12500015399733,12500001613011,12500001808104,12500001095874,12500001112472,12500000982166,12500001002638,12500001731391,12500001048324,12500001048796,12500001395539,12500001498399,12500001099033,12500001181500,12500015385877]}]}"
            return options
        }
        
        let options = [
            makeOptionsWithExplicitParams(),
            makeOptionsWithUntypedQueryParams(),
            makeRouteUpdateOptions()
            ][2]
        
        let useSnap = false
        Directions(accessToken: "", host: (useSnap ? "routemm.mappysnap.net" : "routemm.mappyrecette.net"))
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
                    print("\(step.instructions) [\(step.maneuverType) \(step.maneuverDirection)]")
                    if step.distance > 0 {
                        let formattedDistance = distanceFormatter.string(fromMeters: step.distance)
                        print("— \(step.transportType) for \(formattedDistance) —")
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
