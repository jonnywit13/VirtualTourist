//
//  Photos+CoreDataClass.swift
//  VirtualTourist
//
//  Created by Jonathan Withams on 05/04/2017.
//  Copyright © 2017 iCOM Works Ltd. All rights reserved.
//

import Foundation
import CoreData


public class Photo: NSManagedObject {
    
    convenience init(imageName: String, url: String, context: NSManagedObjectContext) {
        if let entity = NSEntityDescription.entity(forEntityName: "Photo", in: context) {
            self.init(entity: entity, insertInto: context)
            self.name = imageName
            self.url = url
        } else {
            fatalError("Could not find entity")
        }
    }

}
