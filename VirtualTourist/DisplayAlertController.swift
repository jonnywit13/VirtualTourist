//
//  DisplayAlertController.swift
//  VirtualTourist
//
//  Created by Jonathan Withams on 25/04/2017.
//  Copyright © 2017 iCOM Works Ltd. All rights reserved.
//

import Foundation
import UIKit

class DisplayAlertController: UIAlertController {
    
    func displayAlert(controller: UIViewController, title: String, message: String) {
        
        let alertController = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        alertController.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
        controller.present(alertController, animated: true, completion: nil)
    }
}
