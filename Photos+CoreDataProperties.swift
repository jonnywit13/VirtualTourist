//
//  Photos+CoreDataProperties.swift
//  VirtualTourist
//
//  Created by Jonathan Withams on 05/04/2017.
//  Copyright © 2017 iCOM Works Ltd. All rights reserved.
//  This file was automatically generated and should not be edited.
//

import Foundation
import CoreData


extension Photos {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Photos> {
        return NSFetchRequest<Photos>(entityName: "Photos");
    }

    @NSManaged public var imageData: NSData?
    @NSManaged public var name: String?
    @NSManaged public var url: String?
    @NSManaged public var location: Location?

}
