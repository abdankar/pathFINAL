//
//  ViewController.swift
//  Path
//
//  Created by Leshya Bracaglia on 4/10/19.
//  Copyright © 2019 nyu.edu. All rights reserved.
//


//APP SHOULD BE LIMITED TO JUST THE STATE OF NEW YORK
import UIKit
import CoreLocation
import GoogleMaps
import GooglePlaces
import SwiftyJSON

class ViewController: UIViewController {
    
    //This is our map
    @IBOutlet weak var mapView: GMSMapView!
    //private let locationManager = CLLocationManager()
    var locationManager = CLLocationManager()
    private let dataProvider = GoogleDataProvider()
    private let searchRadius: Double = 1000
    var geocoder = CLGeocoder()
    var loc1: CLLocationCoordinate2D = (CLLocationCoordinate2DMake(0, 0));
    var loc2: CLLocationCoordinate2D = (CLLocationCoordinate2DMake(0, 0));
    
    
    //This is the cafe button/items
    @IBOutlet weak var cafe: UIView!
    @IBOutlet weak var cafeImage: UIImageView!
    @IBOutlet weak var cafeText: UILabel!
    
    //This is the culture button/items
    @IBOutlet weak var culture: UIView!
    @IBOutlet weak var beerImage: UIImageView!
    @IBOutlet weak var cultureText: UILabel!
    
    //This is the restaurant button/items
    @IBOutlet weak var restaurant: UIView!
    @IBOutlet weak var restaurantText: UILabel!
    @IBOutlet weak var forkImage: UIImageView!
    
    //The start and end text fields, go button
    @IBOutlet weak var endField: UITextField!
    @IBOutlet weak var startField: UITextField!
    @IBOutlet weak var getCoord: UIButton!
    
    @IBOutlet weak var topView: UIView!
    @IBOutlet weak var bottomView: UIView!
    
    let group = DispatchGroup()
    
    //Our orange color
    var myorange = UIColor(red: 249.0/255.0, green: 156.0/255.0, blue: 8.0/255.0, alpha: 1.0)
    
    //our dark grey color
    var mygrey = UIColor(red: 58.0/255.0, green: 58.0/255.0, blue: 60.0/255.0, alpha: 1.0)
    
    var currentSearchType = "restaurant"
    
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        //This is all style***************************
        cafe.layer.borderColor = UIColor.black.cgColor;
        cafe.layer.borderWidth = 2;
        culture.layer.borderColor = UIColor.black.cgColor;
        culture.layer.borderWidth = 2;
        restaurant.layer.borderColor = UIColor.black.cgColor;
        restaurant.layer.borderWidth = 2;
        
        topView.layer.shadowColor = UIColor.black.cgColor
        topView.layer.shadowOpacity = 0.25
        topView.layer.shadowOffset = CGSize(width: 0, height: 5)
        topView.layer.shadowRadius = 4
        
        bottomView.layer.shadowColor = UIColor.black.cgColor
        bottomView.layer.shadowOpacity = 0.25
        bottomView.layer.shadowOffset = CGSize(width: 0, height: -5)
        bottomView.layer.shadowRadius = 4
        
        startField.placeholder = "Current Location"
        startField.layer.borderColor = mygrey.cgColor
        startField.layer.cornerRadius = 5.0
        startField.layer.borderWidth = 2
        endField.placeholder = "Where are you going?"
        endField.layer.borderColor = mygrey.cgColor
        endField.layer.cornerRadius = 5.0
        endField.layer.borderWidth = 2
        //**********************************************
        
        //map
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()

        
    }
    
    //go pressed
    @IBAction func onGo(_ sender: Any) {
        performSearch()
    }
    
    func performSearch() {
        mapView.clear()
        
        // completion handler to build the location object when we have valid coordinate data
        let geocodeHandlerFactory : (_ completionHandler: @escaping (CLLocationCoordinate2D?, Error?) -> Void) -> CLGeocodeCompletionHandler = { completionHandler in
            let geocodeHandler : CLGeocodeCompletionHandler = { placemarks, geocodeError in
                guard let placemark = placemarks?.first else {
                    completionHandler(nil, geocodeError)
                    return
                }
                let lat = placemark.location!.coordinate.latitude
                let lon = placemark.location!.coordinate.longitude
                let newCoord = CLLocationCoordinate2DMake(lat, lon)
                completionHandler(newCoord, geocodeError)
            }
            return geocodeHandler
        }
        
        let startingAddress = startField.text!
        let endingAddress = endField.text!
        
        //dispatch so each geocording of addresses and then drawing of route are scheduled in order
        DispatchQueue.global().async {
            let dispatchGroup = DispatchGroup()
            var startLocationSearchError : Error?
            var endLocationSearchError : Error?
            let geocoder = CLGeocoder()
            
            //geocode start address, then pass to handler to build the object and pass back
            dispatchGroup.enter()
            geocoder.geocodeAddressString(startingAddress, completionHandler: geocodeHandlerFactory() { coord, error in
                defer { dispatchGroup.leave() }
                if error != nil {
                    startLocationSearchError = error
                    print("ERROR: could not find starting location: \(error!)")
                    return
                }
                guard let coord = coord else {
                    print("ERROR: no coordinate data for starting location")
                    return
                }
                self.loc1 = coord
            })
            dispatchGroup.wait()
            
            //geocode end address, pass to handler and pass back
            dispatchGroup.enter()
            geocoder.geocodeAddressString(endingAddress, completionHandler: geocodeHandlerFactory() { coord, error in
                defer { dispatchGroup.leave() }
                if error != nil {
                    endLocationSearchError = error
                    print("ERROR: could not find ending location: \(error!)")
                    return
                }
                guard let coord = coord else {
                    print("ERROR: no coordinate data for ending location")
                    return
                    
                }
                
                self.loc2 = coord
            })
            dispatchGroup.wait()
            
            //we have our coordinates, now print the route and show locations
            dispatchGroup.notify(queue: .main) {
                if startLocationSearchError != nil || endLocationSearchError != nil {
                    print("ERROR: unable to find one or both of the locations")
                }
                else {
                    print("FOUND IT!")
                    //move camera
                    let camera = GMSCameraPosition.camera(withLatitude: self.loc1.latitude, longitude: self.loc1.longitude, zoom: 14)
                    self.mapView?.camera = camera
                    self.mapView?.animate(to: camera)
                    //draw route and display places
                    self.fetchRoute(from: self.loc1, to: self.loc2)
                }
            }
        }
    }
    
    /*When you click button, changes color themes*/
    @IBAction func onCulture(_ sender: Any) {
        //change culture colors to be clicked
        cultureOn();
        //change cafe colors to be unclicked
        cafeOff();
        //change restaurant colors to be unclicked
        restaurantOff()
        // TODO: refactor?
        performSearch()
    }
    
    @IBAction func onCafe(_ sender: Any) {
        //Change culture to be unclicked
        cultureOff();
        //Change cafe to be clicked
        cafeOn();
        //Change restaurant to be unclicked
        restaurantOff();
        
        // TODO: refactor?
        performSearch()
    }
    
    
    @IBAction func onRestaurant(_ sender: Any) {
        //Change culture to be unclicked
        cultureOff();
        //Change cafe to be unclicked
        cafeOff();
        //Change restaurant to be clicked
        restaurantOn();
        
        // TODO: refactor?
        performSearch()
    }
    
    func cultureOn(){
        currentSearchType = "bar"
        culture.layer.backgroundColor = myorange.cgColor;
        beerImage.image = UIImage(named: "beer");
        culture.layer.borderColor = UIColor.black.cgColor;
        culture.layer.borderWidth = 2;
        cultureText.textColor = UIColor.black;
    }
    
    func cultureOff(){
        culture.layer.backgroundColor = mygrey.cgColor;
        beerImage.image = UIImage(named: "beer-orange");
        culture.layer.borderColor = UIColor.black.cgColor;
        culture.layer.borderWidth = 2;
        cultureText.textColor = myorange;
    }
    
    func restaurantOn(){
        currentSearchType = "restaurant"
        restaurant.layer.backgroundColor = myorange.cgColor;
        forkImage.image = UIImage(named: "fork");
        culture.layer.borderColor = UIColor.black.cgColor;
        culture.layer.borderWidth = 2;
        restaurantText.textColor = UIColor.black;
    }
    
    func restaurantOff(){
        restaurant.layer.backgroundColor = mygrey.cgColor;
        forkImage.image = UIImage(named: "fork-orange");
        restaurant.layer.borderColor = UIColor.black.cgColor;
        restaurant.layer.borderWidth = 2;
        restaurantText.textColor = myorange;
    }
    
    func cafeOn(){
        currentSearchType = "cafe"
        cafe.layer.backgroundColor = myorange.cgColor;
        cafeImage.image = UIImage(named: "coffee-cup");
        culture.layer.borderColor = UIColor.black.cgColor;
        culture.layer.borderWidth = 2;
        cafeText.textColor = UIColor.black;
    }
    
    func cafeOff(){
        cafe.layer.backgroundColor = mygrey.cgColor;
        cafeImage.image = UIImage(named: "coffee-cup-orange");
        cafe.layer.borderColor = UIColor.black.cgColor;
        cafe.layer.borderWidth = 2;
        cafeText.textColor = myorange;
    }
    
    //This functions resigns the keyboard when return is clicked
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        self.view.endEditing(true)
        return true
    }
    
    
    //Gets Route
    func fetchRoute(from source: CLLocationCoordinate2D, to destination: CLLocationCoordinate2D) {
        let session = URLSession.shared
        //WALKING
        let urlString = "https://maps.googleapis.com/maps/api/directions/json?origin=\(source.latitude),\(source.longitude)&destination=\(destination.latitude),\(destination.longitude)&sensor=false&mode=walking&key=\(GoogleKey)"
        
        let url = URL(string: urlString)!
        
        let task = session.dataTask(with: url, completionHandler: {
            (data, response, error) in
            
            guard error == nil else {
                print(error!.localizedDescription)
                return
            }
            
            guard let data = data else {
                print("ERROR: data was nil")
                return
            }
            
            guard let json = try? JSON(data: data) else {
                print("ERROR: could not parse JSON")
                return
            }
            
            guard let polyLineString = json["routes"][0]["overview_polyline"]["points"].string else {
                print("ERROR: missing polyline information")
                return
            }
            
            //after we have our route data from google
            DispatchQueue.main.async {
                if let path = GMSPath(fromEncodedPath: polyLineString) {
                    //fill this array with points from the route
                    var locations : [CLLocation] = []
                    for i in 0...path.count() - 1 {
                        let coordinate = path.coordinate(at: i)
                        locations.append(CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude))
                    }
                    //call the method to find/display places and draw our path
                    self.findNearbyPlaces(for: locations)
                    self.drawPath(from: path)
                }
            }
        })
        task.resume()
    }
    
    //draws path on map... used in the fetchRoute method.
    func drawPath(from path: GMSPath) {
        let polyline = GMSPolyline(path: path)
        polyline.strokeWidth = 10.0
        polyline.strokeColor = myorange
        polyline.map = mapView // Google MapView
    }
    
    //turn the coordinates into places
    func findNearbyPlaces(for locations: [CLLocation]) {
        // don't need every coordinate so skip some
        if locations.count > 2 {
            var searchLocations : [CLLocation] = []
            var currentReferenceLocation = locations.first!
            searchLocations.append(currentReferenceLocation)
            for i in 1...locations.count - 1 {
                let candidate = locations[i]
                let distance = candidate.distance(from: currentReferenceLocation)
                //filters which coordinates we want by our constant DistanceFilter, lowering it will increase our API calls but give more businesses, a tradeoff
                if distance > DistanceFilter || candidate == locations.last! {
                    print("Difference of ==> \(candidate.distance(from: currentReferenceLocation)) meters")
                    //filtered array of coords
                    searchLocations.append(candidate)
                    currentReferenceLocation = candidate
                }
            }
            
            print("locations = \(locations.count), searchLocations = \(searchLocations.count)")
            
            DispatchQueue.global().async {
                let dispatchGroup  = DispatchGroup()
                var uniquePlaces = Set<String>()
                for location in searchLocations {
                    dispatchGroup.enter()
                    //use class GoogleDataProvider to search around our coordinates
                    self.dataProvider.fetchPlacesNearCoordinate(location.coordinate, radius: 75.0, type: self.currentSearchType) { places in
                        places.forEach {
                            // ignore places that have already been added
                            if !uniquePlaces.contains($0.placeId) {
                                //create and place marker for each unique place
                                uniquePlaces.insert($0.placeId)
                                let marker = PlaceMarker(place: $0)
                                marker.title = $0.name
                                marker.map = self.mapView
                            }
                        }
                        dispatchGroup.leave()
                    }
                    dispatchGroup.wait()
                }
            }
        }
    }
}
//end of class


//CLLocationManagerDelegate
extension ViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        guard status == .authorizedWhenInUse else {
            NSLog("Path needs permission to access your location")
            return
        }
        locationManager.startUpdatingLocation()
        mapView.isMyLocationEnabled = true
        mapView.settings.myLocationButton = true
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else {
            return
        }
        mapView.camera = GMSCameraPosition(target: location.coordinate, zoom: 15, bearing: 0, viewingAngle: 0)
        locationManager.stopUpdatingLocation()
    }
}





