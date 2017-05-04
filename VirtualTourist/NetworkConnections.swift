//
//  NetworkConnections.swift
//  VirtualTourist
//
//  Created by Jonathan Withams on 06/04/2017.
//  Copyright © 2017 iCOM Works Ltd. All rights reserved.
//

import Foundation
import UIKit

class NetworkConnections: NSObject {
    
    // MARK: Properties
    
    var session = URLSession.shared
    
    let stack = (UIApplication.shared.delegate as! AppDelegate).stack
    
    // MARK: Initializers
    
    override init() {
        super.init()
    }
    
    func getPhotosForLocation(location: Location, _ completionHandlerForFlickr: @escaping (_ result: Bool?, _ error: String?) -> Void) {
        
        var parameters = [
            Constants.FlickrParameterKeys.Method: Constants.FlickrParameterValues.SearchMethod as AnyObject,
            Constants.FlickrParameterKeys.APIKey: Constants.FlickrParameterValues.APIKey as AnyObject,
            Constants.FlickrParameterKeys.BoundingBox: bboxString(latitude: location.latitude, longitude: location.longitude) as AnyObject,
            Constants.FlickrParameterKeys.SafeSearch: Constants.FlickrParameterValues.UseSafeSearch as AnyObject,
            Constants.FlickrParameterKeys.Extras: Constants.FlickrParameterValues.MediumURL as AnyObject,
            Constants.FlickrParameterKeys.Format: Constants.FlickrParameterValues.ResponseFormat as AnyObject,
            Constants.FlickrParameterKeys.NoJSONCallback: Constants.FlickrParameterValues.DisableJSONCallback as AnyObject,
            Constants.FlickrParameterKeys.PerPage: 40 as AnyObject
        ] as [String:AnyObject]
        
        let request = URLRequest(url: flickrURLFromParameters(parameters))
        
        let task = session.dataTask(with: request as URLRequest) { (data, response, error) in
            
            func sendError(_ error: String) {
                completionHandlerForFlickr(false, error)
            }
            
            /* GUARD: Was there an error? */
            guard (error == nil) else {
                sendError("There was an error with your request: \(error)")
                return
            }
            
            /* GUARD: Did we get a successful 2XX response? */
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode >= 200 && statusCode <= 299 else {
                sendError("A network error has occurred, please try again later")
                return
            }
            
            /* GUARD: Was there any data returned? */
            guard let data = data else {
                sendError("No data was returned by the request!")
                return
            }
            
            /* 5/6. Parse the data and use the data (happens in completion handler) */
            guard let parsedResult = self.convertData(data) as? [String:AnyObject] else {
                sendError("Could not parse the data as JSON")
                return
            }
            
            /* GUARD: Did Flickr return an error (stat != ok)? */
            guard let stat = parsedResult[Constants.FlickrResponseKeys.Status] as? String, stat == Constants.FlickrResponseValues.OKStatus else {
                sendError("Flickr API returned an error. See error code and message in \(parsedResult)")
                return
            }
            
            /* GUARD: Is "photos" key in our result? */
            guard let photosDictionary = parsedResult[Constants.FlickrResponseKeys.Photos] as? [String:AnyObject] else {
                sendError("Cannot find keys '\(Constants.FlickrResponseKeys.Photos)' in \(parsedResult)")
                return
            }
            
            /* GUARD: Is "pages" key in the photosDictionary? */
            guard let totalPages = photosDictionary[Constants.FlickrResponseKeys.Pages] as? Int else {
                sendError("Cannot find key '\(Constants.FlickrResponseKeys.Pages)' in \(photosDictionary)")
                return
            }
            
            let pageLimit = min(totalPages, 40)
            
            let chosenPage = Int(arc4random_uniform(UInt32(pageLimit))) + 1
            
            parameters[Constants.FlickrParameterKeys.Page] = chosenPage as AnyObject?
            
            self.getPhotosForLocationWithPage(parameters, location, completionHandlerForFlickr)
            
        }
        
        /* 7. Start the request */
        task.resume()
    }
    
    func getPhotosForLocationWithPage(_ parameters: [String:AnyObject],_ location: Location,_ completionHandlerForFlickr: @escaping (_ result: Bool?, _ error: String?) -> Void) {
        
        let request = URLRequest(url: flickrURLFromParameters(parameters))
        
        let task = session.dataTask(with: request as URLRequest) { (data, response, error) in
            
            func sendError(_ error: String) {
                completionHandlerForFlickr(false, error)
            }
            
            /* GUARD: Was there an error? */
            guard (error == nil) else {
                sendError("There was an error with your request: \(error)")
                return
            }
            
            /* GUARD: Did we get a successful 2XX response? */
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode >= 200 && statusCode <= 299 else {
                sendError("A network error has occurred, please try again later")
                return
            }
            
            /* GUARD: Was there any data returned? */
            guard let data = data else {
                sendError("No data was returned by the request!")
                return
            }
            
            /* 5/6. Parse the data and use the data (happens in completion handler) */
            guard let parsedResult = self.convertData(data) as? [String:AnyObject] else {
                sendError("Could not parse the data as JSON")
                return
            }
            
            /* GUARD: Did Flickr return an error (stat != ok)? */
            guard let stat = parsedResult[Constants.FlickrResponseKeys.Status] as? String, stat == Constants.FlickrResponseValues.OKStatus else {
                sendError("Flickr API returned an error. See error code and message in \(parsedResult)")
                print("Flickr api error 2")
                return
            }
            
            /* GUARD: Is "photos" key in our result? */
            guard let photosDictionary = parsedResult[Constants.FlickrResponseKeys.Photos] as? [String:AnyObject] else {
                sendError("Cannot find keys '\(Constants.FlickrResponseKeys.Photos)' in \(parsedResult)")
                return
            }
            
            guard let photosArray = photosDictionary[Constants.FlickrResponseKeys.Photo] as? [[String:AnyObject]] else{
                sendError("Could not find the key \(Constants.FlickrResponseKeys.Photo)")
                return
            }
            
            if photosArray.count == 0 {
                sendError("There were no photos")
            } else {
                var count = 1
                
                for photo in photosArray {
                    
                    //performUIUpdatesOnMain {
                    self.stack.context.perform {
                        
                    
                    
                        let name = photo[Constants.FlickrResponseKeys.Title] as? String
                        let url = photo[Constants.FlickrResponseKeys.MediumURL] as? String
                    
                        let savedPhoto = Photo(imageName: name!, url: url!, context: self.stack.context)
                        savedPhoto.location = location
                        self.stack.save()
                        
                        count += 1
                    }
                }
                completionHandlerForFlickr(true, nil)
            }
            
        }
        
        task.resume()
    }
    
    func getImageForUrl(url: String,_ completionHandlerForGetImage: @escaping (_ result: Data?, _ error: String?) -> Void) {
    
        let imageUrl = URL(string: url)
        let request = URLRequest(url: imageUrl!)
        
        let task = session.dataTask(with: request) { (results, response, error) in
         
            if error == nil {
                completionHandlerForGetImage(results, nil)
            } else {
                completionHandlerForGetImage(nil, "Failed to download Image")
            }
            
        }
        
        task.resume()
    
    }
    
    private func bboxString(latitude: Double, longitude: Double) -> String {
        // ensure bbox is bounded by minimum and maximums

            let minimumLon = max(longitude - Constants.Flickr.SearchBBoxHalfWidth, Constants.Flickr.SearchLonRange.0)
            let minimumLat = max(latitude - Constants.Flickr.SearchBBoxHalfHeight, Constants.Flickr.SearchLatRange.0)
            let maximumLon = min(longitude + Constants.Flickr.SearchBBoxHalfWidth, Constants.Flickr.SearchLonRange.1)
            let maximumLat = min(latitude + Constants.Flickr.SearchBBoxHalfHeight, Constants.Flickr.SearchLatRange.1)
            return "\(minimumLon),\(minimumLat),\(maximumLon),\(maximumLat)"
    }
    
    private func convertData(_ data: Data) -> AnyObject {
        
        var parsedResult: AnyObject! = nil
        do {
            parsedResult = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as AnyObject
        } catch {
            print("Could not parse the data as JSON: '\(data)'")
            return "" as AnyObject
        }
        
        return parsedResult
    }
    
    private func flickrURLFromParameters(_ parameters: [String:AnyObject]) -> URL {
        
        var components = URLComponents()
        components.scheme = Constants.Flickr.APIScheme
        components.host = Constants.Flickr.APIHost
        components.path = Constants.Flickr.APIPath
        components.queryItems = [URLQueryItem]()
        
        for (key, value) in parameters {
            let queryItem = URLQueryItem(name: key, value: "\(value)")
            components.queryItems!.append(queryItem)
        }
        
        return components.url!
    }
    
    class func sharedInstance() -> NetworkConnections{
        struct Singleton{
            static var sharedInstance = NetworkConnections()
        }
        return Singleton.sharedInstance
    }
}
