//
//  PhotoCollectionViewController.swift
//  VirtualTourist
//
//  Created by Jonathan Withams on 12/04/2017.
//  Copyright © 2017 iCOM Works Ltd. All rights reserved.
//

import Foundation
import UIKit
import MapKit
import CoreData

class PhotoCollectionViewController: UIViewController, NSFetchedResultsControllerDelegate, MKMapViewDelegate, UICollectionViewDelegate,UICollectionViewDataSource {
    
    @IBOutlet weak var map: MKMapView!
    @IBOutlet weak var photoCollectionView: UICollectionView!
    @IBOutlet weak var noImagesLabel: UILabel!
    
    let stack = (UIApplication.shared.delegate as! AppDelegate).stack
    
    let displayAlert = DisplayAlertController()
    
    var location: Location?
    
    var photosForLocation: [Photo]!
    
    @IBOutlet weak var newCollectionButton: UIButton!
    
    
    var fetchedResultsController : NSFetchedResultsController<NSFetchRequestResult>? {
        didSet {
            fetchedResultsController?.delegate = self
            let fr = NSFetchRequest<NSFetchRequestResult>(entityName: "Photo")
            fr.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
            
            
            fr.predicate = NSPredicate(format: "location = %@", argumentArray: [location!])
            
            fetchedResultsController = NSFetchedResultsController(fetchRequest: fr, managedObjectContext: stack.context, sectionNameKeyPath: nil, cacheName: nil)
            
            if let fc = fetchedResultsController{
                do{
                    try fc.performFetch()
                    photosForLocation = fc.fetchedObjects as! [Photo]!
                }
                catch let e as NSError{
                    print("Error while performing a search: \n \(e) \n \(fetchedResultsController)")
                    performUIUpdatesOnMain {
                        print("Error happened")
                    }
                }
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        noImagesLabel.isHidden = true
        fetchedResultsController?.delegate = self
        map.delegate = self
        photoCollectionView.delegate = self
        photoCollectionView.dataSource = self
        
        let fr = NSFetchRequest<NSFetchRequestResult>(entityName: "Photo")
        fr.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        
        
        fr.predicate = NSPredicate(format: "location = %@", argumentArray: [location!])
        
        fetchedResultsController?.delegate = self
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fr, managedObjectContext: stack.context, sectionNameKeyPath: nil, cacheName: nil)
        

        
        loadMap()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let fc = fetchedResultsController{
            do{
                try fc.performFetch()
            }
            catch let e as NSError{
                print("Error while performing a search: \n \(e) \n \(fetchedResultsController)")
                
            }
        }
        
        photoCollectionView.reloadData()
    }
    
    func loadMap() {
        
        let pin = location
        
        let annotation = MKPointAnnotation()
        let coordinate = CLLocationCoordinate2D(latitude: pin!.latitude, longitude: pin!.longitude)
        
        annotation.coordinate = coordinate
        
        map.addAnnotation(annotation)
        map.centerCoordinate = coordinate
        map.camera.altitude = 5000
        
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        if let fc = fetchedResultsController{
            return (fc.sections?.count)!
        }
        else{
            return 0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if let fc = fetchedResultsController{
            noImagesLabel.isHidden = true
            return fc.sections![section].numberOfObjects
        }
        else{
            noImagesLabel.isHidden = false
            return 0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoCell", for: indexPath) as! PhotoCollectionViewCell
        
        cell.placeholderActivityIndicator.hidesWhenStopped = true
        
        let photo = fetchedResultsController?.object(at: indexPath) as! Photo

        cell.placeholderActivityIndicator.startAnimating()
        
        
        if photo.imageData != nil {
            cell.image.image = UIImage(data: photo.imageData as! Data)
            cell.placeholderActivityIndicator.stopAnimating()
            print("sorted image")
        } else {
            if photo.url != nil {
                NetworkConnections.sharedInstance().getImageForUrl(url: photo.url!) { (result, error) in
                    
                    performUIUpdatesOnMain {
                        if error == nil {
                            cell.image.image = UIImage(data: result!)
                            cell.placeholderActivityIndicator.stopAnimating()
                            print("sorted image after getting image data")
                            photo.imageData = result! as NSData?
                            self.stack.save()
                            
                            self.photoCollectionView.reloadItems(at: [indexPath])
                            
                        } else {
                            self.displayAlert.displayAlert(controller: self, title: "Error", message: error!)
                        }
                    }
                }
            } else {
                self.displayAlert.displayAlert(controller: self, title: "Error", message: "Could not find image")
                cell.placeholderActivityIndicator.stopAnimating()
            }
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        let photo = fetchedResultsController?.object(at: indexPath) as! Photo
        
        performUIUpdatesOnMain {
            
            self.stack.context.delete(photo)
            self.stack.save()
            self.photoCollectionView.deleteItems(at: [indexPath])
            
        
        
        }
    }
    
    @IBAction func fetchNewCollection(_ sender: Any) {
        
        for photo in (fetchedResultsController?.fetchedObjects)! {
            stack.context.delete(photo as! Photo)
            stack.save()
        }
        
        newCollectionButton.isEnabled = false
        
        NetworkConnections.sharedInstance().getPhotosForLocation(location: location!) { (success, error) in
            
            performUIUpdatesOnMain {
                
                if !success! {
                    self.displayAlert.displayAlert(controller: self, title: "Error", message: "Could not find photos for this location, please try again")
                    return
                } else {
                    if let fc = self.fetchedResultsController {
                        do{
                            try fc.performFetch()
                        }
                        catch let e as NSError{
                            print("Error while performing a search: \n \(e) \n \(self.fetchedResultsController)")
                            
                        }
                        
                        self.photoCollectionView.reloadData()
                        self.newCollectionButton.isEnabled = true
                    }
                }
            }
        }
    }
    
}
