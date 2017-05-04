//
//  Location+CoreDataClass.swift
//  VirtualTourist
//
//  Created by Jonathan Withams on 05/04/2017.
//  Copyright © 2017 iCOM Works Ltd. All rights reserved.
//

import Foundation
import CoreData
import MapKit


public class Location: NSManagedObject, MKAnnotation {

    convenience init(latitude: Double, longitude: Double, context: NSManagedObjectContext) {
        if let entity = NSEntityDescription.entity(forEntityName: "Location", in: context) {
            self.init(entity: entity, insertInto: context)
            self.latitude = latitude
            self.longitude = longitude
        } else {
            fatalError("Could not find entity")
        }
    }
    
    
    public var coordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2DMake(self.latitude, self.longitude)
    }
}
