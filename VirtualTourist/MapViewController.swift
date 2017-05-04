//
//  MapViewController.swift
//  VirtualTourist
//
//  Created by Jonathan Withams on 28/03/2017.
//  Copyright © 2017 iCOM Works Ltd. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import CoreData

class MapViewController: UIViewController, MKMapViewDelegate, NSFetchedResultsControllerDelegate {

    @IBOutlet weak var map: MKMapView!
    let stack = (UIApplication.shared.delegate as! AppDelegate).stack
    
    let displayAlert = DisplayAlertController()
    
    var savedPins = [Location]()
    
    var fetchedResultsController : NSFetchedResultsController<NSFetchRequestResult>? {
        didSet {
            fetchedResultsController?.delegate = self
            let fr = NSFetchRequest<NSFetchRequestResult>(entityName: "Location")
            fr.sortDescriptors = [NSSortDescriptor(key: "latitude", ascending: true),
                                  NSSortDescriptor(key: "longitude", ascending: true)]

            fetchedResultsController = NSFetchedResultsController(fetchRequest: fr, managedObjectContext: stack.context, sectionNameKeyPath: nil, cacheName: nil)
            
            if let fc = fetchedResultsController{
                do{
                    try fc.performFetch()
                }
                catch let e as NSError{
                    print("Error while performing a search: \n \(e) \n \(fetchedResultsController)")
                    performUIUpdatesOnMain {
                        print("Error happened")
                    }
                }
            }

            
            self.addPins()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Virtual Tourist"
        
        map.delegate = self
        
        let longPressGesture = UILongPressGestureRecognizer(target: self,action:#selector(addPinToMap(gestureRecognizer:)))
        longPressGesture.minimumPressDuration = 0.5
        map.addGestureRecognizer(longPressGesture)
        
        let fr = NSFetchRequest<NSFetchRequestResult>(entityName: "Location")
        fr.sortDescriptors = [NSSortDescriptor(key: "latitude", ascending: true),
                              NSSortDescriptor(key: "longitude", ascending: true)]
        
        fetchedResultsController?.delegate = self
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fr, managedObjectContext: stack.context, sectionNameKeyPath: nil, cacheName: nil)
        
        moveToLastLocation()
        
        // Do any additional setup after loading the view, typically from a nib.
    }

    func addPins(){
         performUIUpdatesOnMain {
            self.map.removeAnnotations(self.map.annotations)
            let fetchedResultAnnotations = self.fetchedResultsController?.fetchedObjects as! [Location]
            self.map.addAnnotations(fetchedResultAnnotations)
            self.savedPins = fetchedResultAnnotations
        }
    }
    
    func moveToLastLocation() {
        
        let savedLat = UserDefaults.standard.value(forKey: "latitude")
        
        if savedLat != nil {
            
            let savedLong = UserDefaults.standard.value(forKey: "longitude") as! Double
            
            let centrePoint = CLLocationCoordinate2D(latitude: savedLat as! Double, longitude: savedLong)
            
            let savedLatDelta = UserDefaults.standard.value(forKey: "latitudeDelta") as! Double
            let savedLongDelta = UserDefaults.standard.value(forKey: "longitudeDelta") as! Double
            let savedSpan = MKCoordinateSpan(latitudeDelta: savedLatDelta, longitudeDelta: savedLongDelta)
            
            let savedArea = MKCoordinateRegion(center: centrePoint, span: savedSpan)
            map.setRegion(savedArea, animated: true)
            
        }
        
    }

    func addPinToMap(gestureRecognizer: UILongPressGestureRecognizer){
        
        let touchPoint:CGPoint = gestureRecognizer.location(in: map)
        let annotationCoordinate : CLLocationCoordinate2D = map.convert(touchPoint, toCoordinateFrom: map)
        
        performUIUpdatesOnMain {
            
            switch gestureRecognizer.state {
            case .began:
                let annotation = Location(latitude: annotationCoordinate.latitude, longitude: annotationCoordinate.longitude,context: self.stack.context)
                
                performUIUpdatesOnMain {
                    self.map.addAnnotation(annotation)
                    //self.savedPin = annotation
                    self.savedPins.append(annotation)
                    self.stack.save()
                    self.getPhotosForLocation(annotation)
                }
            default:
                return
            }
        }
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let reuseId = "VirtualTouristPin"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.canShowCallout = false
            pinView!.pinTintColor = .red
            pinView?.animatesDrop = true
            pinView!.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
        }
        else {
            pinView!.annotation = annotation
        }
        
        return pinView
    }
    
    //Save the region so that if the user exits the app, they come back to the same region on the map
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        
        UserDefaults.standard.set(map.region.center.latitude, forKey: "latitude")
        UserDefaults.standard.set(map.region.center.longitude, forKey: "longitude")
        UserDefaults.standard.set(map.region.span.latitudeDelta, forKey: "latitudeDelta")
        UserDefaults.standard.set(map.region.span.longitudeDelta, forKey: "longitudeDelta")
        
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {

        let location = view.annotation as! Location
        
        let photoCollectionViewController = self.storyboard?.instantiateViewController(withIdentifier: "PhotoCollectionViewController") as! PhotoCollectionViewController
        
        photoCollectionViewController.location = location
        
        self.navigationController?.pushViewController(photoCollectionViewController, animated: true)
    
    }
    
    func getPhotosForLocation(_ location: Location) {
        
        NetworkConnections.sharedInstance().getPhotosForLocation(location: location) { (success, error) in
            
            performUIUpdatesOnMain {
                
                if !success! {
                    self.displayAlert.displayAlert(controller: self, title: "Error", message: "Could not find photos for this location, please try again")
                    return
                } 
            }
        }
    }
    
}

