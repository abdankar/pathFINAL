//
//  GoogleDataProvider.swift
//  TestProject
//
//  Created by Leshya Bracaglia on 5/1/19.
//  Copyright © 2019 nyu.edu. All rights reserved.
//


import UIKit
import Foundation
import CoreLocation
import SwiftyJSON

//Creates a new name for the GooglePlace object
typealias PlacesCompletion = ([GooglePlace]) -> Void

//This class allows us to create a GoogleDataProvider object that will be used to make api calls and fetch desired data
//This utilizes the GooglePlace class to create an array that holds GooglePlace objects for each business/restaurant
//that comes out of the search from fetchPlacesNearCoordinates
class GoogleDataProvider {
    //placesTask returns downloaded data directly to app in memory
    private var placesTask: URLSessionDataTask?
    //session allows us to download data from URL
    private var session: URLSession {
        return URLSession.shared
    }
    
    //this function gets places/restaurants/businesses (from Google API) near a specified coordinate. It is run for every
    //location object in the location array in ViewController.swift to return a list of places.
    func fetchPlacesNearCoordinate(_ coordinate: CLLocationCoordinate2D, radius: Double, type: String, completion: @escaping PlacesCompletion) -> Void {
        var urlString = "https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=\(coordinate.latitude),\(coordinate.longitude)&radius=\(radius)&rankby=prominence&sensor=true&type=\(type)&key=\(GoogleKey)"
        
        //changes urlString to handle characters not in set with percent encoded characters
        urlString = urlString.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed) ?? urlString
        
        print(urlString)
        guard let url = URL(string: urlString) else {
            completion([])
            return
        }
        
        if let task = placesTask, task.taskIdentifier > 0 && task.state == .running {
            task.cancel()
        }
        
        //Retrieve contents of URL
        placesTask = session.dataTask(with: url) { data, response, error in
            //holds places
            var placesArray: [GooglePlace] = []
            defer {
                DispatchQueue.main.async {
                    completion(placesArray)
                }
            }
            guard let data = data else {
                return
            }
            guard let json = try? JSON(data: data) else {
                return
            }
            
            //results holds result of the API search in json with each element inside referring to a single restaurant
            guard let results = json["results"].arrayObject as? [[String: Any]] else {
                return
            }
            
            //iterates over results array to create a GooglePlace object for each restuarant/business given by api call.
            results.forEach {
                let place = GooglePlace(dictionary: $0, acceptedTypes: [type])
                placesArray.append(place)
            }
        }
        
        placesTask?.resume()
    }
    
    
}
