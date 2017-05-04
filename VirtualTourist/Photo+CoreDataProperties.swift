//
//  Photos+CoreDataProperties.swift
//  VirtualTourist
//
//  Created by Jonathan Withams on 05/04/2017.
//  Copyright © 2017 iCOM Works Ltd. All rights reserved.
//

import Foundation
import CoreData


extension Photo {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Photo> {
        return NSFetchRequest<Photo>(entityName: "Photo");
    }

    @NSManaged public var imageData: NSData?
    @NSManaged public var name: String?
    @NSManaged public var url: String?
    @NSManaged public var location: Location?

}
