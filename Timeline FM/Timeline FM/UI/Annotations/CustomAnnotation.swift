//
//  CustomAnnotation.swift
//  Timeline FM
//
//  Created by Zachary DeGeorge on 8/2/18.
//  Copyright © 2018 Next Day Project. All rights reserved.
//

import Foundation
import MapKit

@objc class CustomAnnotation: NSObject, MKAnnotation {
    
    static var reusableIdentifier: String {
        return "custom-annotation"
    }
    
    init(image: UIImage?, color: UIColor?, coordinate: CLLocationCoordinate2D) {
        self.coordinate = coordinate
        self.image = image
        self.color = color
    }
    
    var image: UIImage!
    var color: UIColor!
    var coordinate: CLLocationCoordinate2D
    
    var title: String? {
        return nil
    }
    
    var subtitle: String? {
        return nil
    }
}
