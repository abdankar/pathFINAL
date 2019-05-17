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

class ViewController: UIViewController, UITextFieldDelegate{
    
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
    
    @IBOutlet weak var topView: UIView!
    @IBOutlet weak var bottomView: UIView!
    
    @IBOutlet weak var viewResultsButton: UIButton!
    
    let group = DispatchGroup()
    
    //Our orange color
    var myorange = UIColor(red: 249.0/255.0, green: 156.0/255.0, blue: 8.0/255.0, alpha: 1.0)
    
    //our dark grey color
    var mygrey = UIColor(red: 58.0/255.0, green: 58.0/255.0, blue: 60.0/255.0, alpha: 1.0)
    
    var currentSearchType = "restaurant"
    
    var searchResults : [GooglePlace] = []
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        //This is all style***************************
        cafe.layer.borderColor = UIColor.black.cgColor;
        cafe.layer.borderWidth = 2;
        culture.layer.borderColor = UIColor.black.cgColor;
        culture.layer.borderWidth = 2;
        
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
        
        //For map
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        
        locationManager.startUpdatingLocation()

        self.startField.delegate = self;
        self.endField.delegate = self;
        
        //Starting location
        //let location:CLLocationCoordinate2D = locationManager.location!.coordinate
        //lat = String(location.latitude)
        //long = String(location.longitude)
        //self.reverseGeocodeCoordinate(location)
        
        viewResultsButton.isHidden = true;
        
        //TODO: remove
        startField.text = "190 E 7th St, New York, NY 10009"
        endField.text = "647 E 11th St, New York, NY 10009"
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    //Supposed to use the coordinates on onCoord method to display a route on the map with markers on the startAddress and endAddress coordinates
    @IBAction func onGo(_ sender: Any) {
        performSearch()
    }
    
    func performSearch() {
        mapView.clear()
        
        // This currying closure allows us to make a generic functin for creating coordinates
        // but also provide an additional completion handler for setting setting coordinate variables and errors
        let geocodeHandlerFactory : (_ completionHandler: @escaping (CLLocationCoordinate2D?, Error?) -> Void) -> CLGeocodeCompletionHandler = { completionHandler in
            let geocodeHandler : CLGeocodeCompletionHandler = { placemarks, geocodeError in
                guard let placemark = placemarks?.first else {
                    completionHandler(nil, geocodeError)
                    return
                }
                //let placemark = placemarks.first
                let lat = placemark.location!.coordinate.latitude
                let lon = placemark.location!.coordinate.longitude
                let newCoord = CLLocationCoordinate2DMake(lat, lon)
                completionHandler(newCoord, geocodeError)
            }
            return geocodeHandler
        }
        
        let startingAddress = startField.text!
        let endingAddress = endField.text!
        
        DispatchQueue.global().async {
            let dispatchGroup = DispatchGroup()
            var startLocationSearchError : Error?
            var endLocationSearchError : Error?
            let geocoder = CLGeocoder()
            
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
            
            dispatchGroup.notify(queue: .main) {
                if startLocationSearchError != nil || endLocationSearchError != nil {
                    print("ERROR: unable to find one or both of the locations")
                }
                else {
                    print("FOUND IT!")
                    
                    let camera = GMSCameraPosition.camera(withLatitude: self.loc1.latitude, longitude: self.loc1.longitude, zoom: 14)
                    self.mapView?.camera = camera
                    self.mapView?.animate(to: camera)
                    self.fetchRoute(from: self.loc1, to: self.loc2)
                }
            }
        }
    }
    
    //get the startAddress coordinates
    // TODO: remove?
    func getStart(startAddress: String) -> CLLocationCoordinate2D{
        var coordinate1a: Double = 0;
        var coordinate1b: Double = 0;
        var geocoder = CLGeocoder()
        geocoder.geocodeAddressString(startAddress) {
            placemarks, error in
            let placemark2 = placemarks?.first
            let lat1 = placemark2!.location!.coordinate.latitude
            let lon1 = placemark2!.location!.coordinate.longitude
            coordinate1a = lat1;
            coordinate1b = lon1;
            self.loc1 = (CLLocationCoordinate2DMake(coordinate1a, coordinate1b))
        }
        return self.loc1;
    }
    
    //Get the endAddress Coordinates
    // TODO: remove?
    func getEnd(endAddress: String) -> CLLocationCoordinate2D{
        var coordinate2a: Double = 0;
        var coordinate2b: Double = 0;
        var geocoder = CLGeocoder()
        geocoder.geocodeAddressString(endAddress) {
            placemarks, error in
            let placemark2 = placemarks?.first
            let lat2 = placemark2!.location!.coordinate.latitude
            let lon2 = placemark2!.location!.coordinate.longitude
            coordinate2a = lat2;
            coordinate2b = lon2;
            self.loc2 = (CLLocationCoordinate2DMake(coordinate2a, coordinate2b))
        }
        return self.loc2;
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
        currentSearchType = "culture"
        culture.layer.backgroundColor = myorange.cgColor;
        beerImage.image = UIImage(named: "beer");
        culture.layer.borderColor = myorange.cgColor;
        culture.layer.borderWidth = 0;
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
        restaurant.layer.borderColor = myorange.cgColor;
        restaurant.layer.borderWidth = 0;
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
        cafe.layer.borderColor = myorange.cgColor;
        cafe.layer.borderWidth = 0;
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
    
    //Address to CLLocationCoordinate2D object
    func getLocation(from address: String, completion: @escaping (_ location:
        CLLocationCoordinate2D?)-> Void) {
        NSLog("yellow")
        NSLog(address)
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(address) { (placemarks, error) in
            guard let placemarks = placemarks,
                let location = placemarks.first?.location?.coordinate else {
                    return
            }
            completion(location)
        }
    }
    
    //Gets Route
    func fetchRoute(from source: CLLocationCoordinate2D, to destination: CLLocationCoordinate2D) {
        let session = URLSession.shared
        
        let urlString = "https://maps.googleapis.com/maps/api/directions/json?origin=\(source.latitude),\(source.longitude)&destination=\(destination.latitude),\(destination.longitude)&sensor=false&mode=driving&key=\(GoogleKey)"
        
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
            
            
            DispatchQueue.main.async {
                if let path = GMSPath(fromEncodedPath: polyLineString) {
                    var locations : [CLLocation] = []
                    for i in 0...path.count() - 1 {
                        let coordinate = path.coordinate(at: i)
                        
                        locations.append(CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude))
                    }
                    self.findNearbyPlaces(for: locations)
                    self.drawPath(from: path)
                }

            }
            
        })
        task.resume()
    }
    
    //Draws path on map... Used in the fetchRoute method.
    func drawPath(from path: GMSPath) {
        let polyline = GMSPolyline(path: path)
        polyline.strokeWidth = 10.0
        polyline.strokeColor = myorange
        polyline.map = mapView // Google MapView
    }
    
    func findNearbyPlaces(for locations: [CLLocation]) {
        // We need to limit the amount of times we call the Places API,
        // so we devise a strategy to eliminate some coordinates
        if locations.count > 2 {
            var searchLocations : [CLLocation] = []
            var currentReferenceLocation = locations.first!
            searchLocations.append(currentReferenceLocation)
            for i in 1...locations.count - 1 {
                let candidate = locations[i]
                let distance = candidate.distance(from: currentReferenceLocation)
                // We want to skip coordinates that are too close to the last one
                // but always include the last coordinate
                if distance > DistanceFilter || candidate == locations.last! {
                    print("Difference of ==> \(candidate.distance(from: currentReferenceLocation)) meters")
                    // NOTE**: This block is optional, I am disabling it by default via the global variable
                    // You can enable this and you will have less "gaps". However, if you do, you will make
                    // more requests to the Google API; ideally it will still be less than the total
                    // number of coordinates
                    if FillInGaps && distance > (2 * DistanceFilter) {
                        // When there are long straight lines, we may have differences much larger
                        // than "DistanceFilter". This is because the polyline will only have
                        // two points in the case of a straight line, even if it is 1km long.
                        // We can determine a midpoint and add it to our searchLocations
                        let midpointLocation = ViewController.midpointLocation(for: currentReferenceLocation, and: candidate)
                        searchLocations.append(midpointLocation)
                        // Note that, even this may not be enough for very long straight lines.
                        // For example, you may have a straight line of 800m. You could add logic here
                        // that will keep filling in the gaps between the new midpoint and the "candidate"
                        // point, just be careful to preserve the ordering or the other logic in this block will fail
                        
                    }
                    searchLocations.append(candidate)
                    currentReferenceLocation = candidate
                }
            }
            
            print("locations = \(locations.count), searchLocations = \(searchLocations.count)")
            
            DispatchQueue.global().async {
                let dispatchGroup  = DispatchGroup()
                self.searchResults.removeAll()
                var uniquePlaces = Set<String>()
                for location in searchLocations {
                    dispatchGroup.enter()
                    self.dataProvider.fetchPlacesNearCoordinate(location.coordinate, radius: DistanceFilter, type: self.currentSearchType) { places in
                        places.forEach {
                            // Ignore places that have already been added
                            if !uniquePlaces.contains($0.placeId) {
                                self.searchResults.append($0)
                                // Create and place marker for each unique place
                                uniquePlaces.insert($0.placeId)
                                let marker = PlaceMarker(place: $0)
                                marker.title = $0.name
                                marker.snippet = $0.address
                                marker.map = self.mapView
                            }
                        }
                        dispatchGroup.leave()
                    }
                    dispatchGroup.wait()
                }
                DispatchQueue.main.async {
                    self.viewResultsButton.isHidden = false
                }
            }
        }
    }
    
    
    private func reverseGeocodeCoordinate(_ coordinate: CLLocationCoordinate2D) {
        
        NSLog("1")
        // 1
        let geocoder = GMSGeocoder()
        
        NSLog("2")
        
        geocoder.reverseGeocodeCoordinate(coordinate) { response, error in
            guard let address = response?.firstResult(), let lines = address.lines else {
                return
            }
            
        NSLog("3")
            // 3
            self.startField.text = lines.joined(separator: "\n")
            
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "searchResultsSegue" {
            var resultController = segue.destination as! SearchResultsController
            resultController.searchResults = self.searchResults
        }
    }
    
}
//end of class


// MARK: - CLLocationManagerDelegate
//1
extension ViewController: CLLocationManagerDelegate {
    // 2
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        // 3
        guard status == .authorizedWhenInUse else {
            NSLog("Path needs permission to access your location")
            return
        }
        // 4
        locationManager.startUpdatingLocation()
        
        //5
        mapView.isMyLocationEnabled = true
        mapView.settings.myLocationButton = true
    }
    
    // 6
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else {
            return
        }
        
        // 7
        mapView.camera = GMSCameraPosition(target: location.coordinate, zoom: 15, bearing: 0, viewingAngle: 0)
        
        // 8
        locationManager.stopUpdatingLocation()
    }
}

extension ViewController {
    // This extension helps find the midpoint between locations,
    // note that this will only be an approximation for short distances
    // TODO: this should probably go into a separate class
    
    //        /** Degrees to Radian **/
    class func degreeToRadian(angle:CLLocationDegrees) -> CGFloat {
        return (  (CGFloat(angle)) / 180.0 * .pi  )
    }
    
    //        /** Radians to Degrees **/
    class func radianToDegree(radian:CGFloat) -> CLLocationDegrees {
        return CLLocationDegrees(  radian * CGFloat(180.0 / .pi)  )
    }
    
    class func midpointLocation(for firstLocation: CLLocation, and secondLocation: CLLocation) -> CLLocation {
        
        var x = 0.0 as CGFloat
        var y = 0.0 as CGFloat
        var z = 0.0 as CGFloat
        
        let listCoords = [
            CLLocationCoordinate2D(latitude: firstLocation.coordinate.latitude, longitude: firstLocation.coordinate.longitude),
            CLLocationCoordinate2D(latitude: secondLocation.coordinate.latitude, longitude: secondLocation.coordinate.longitude)
        ]
        
        for coordinate in listCoords{
            let lat:CGFloat = degreeToRadian(angle: coordinate.latitude)
            let lon:CGFloat = degreeToRadian(angle: coordinate.longitude)
            x = x + cos(lat) * cos(lon)
            y = y + cos(lat) * sin(lon)
            z = z + sin(lat)
        }
        
        x = x/CGFloat(listCoords.count)
        y = y/CGFloat(listCoords.count)
        z = z/CGFloat(listCoords.count)
        
        let resultLon: CGFloat = atan2(y, x)
        let resultHyp: CGFloat = sqrt(x*x+y*y)
        let resultLat:CGFloat = atan2(z, resultHyp)
        
        let newLat = radianToDegree(radian: resultLat)
        let newLon = radianToDegree(radian: resultLon)
        let result : CLLocation = CLLocation(latitude: newLat, longitude: newLon)
        
        return result
        
    }
}


