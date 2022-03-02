//
//  CoordinateAnnotationView.swift
//  Timeline FM
//
//  Created by Zachary DeGeorge on 7/26/18.
//  Copyright © 2018 Next Day Project. All rights reserved.
//

import Foundation
import MapKit
import CoreLocation
import MapKit
import Material

class CoordinateAnnotation: NSObject, MKAnnotation {

    var reusableIdentifier: String {
        return "coordinate-annotation-\(coordinate.latitude)"
    }
    
    var coordinate: CLLocationCoordinate2D
    
    init(coordinate: CLLocationCoordinate2D) {
        self.coordinate = coordinate
        
    }
    
    var title: String? {
        return String(format: "%@ %@", String(format: "%0.6f", arguments: [coordinate.latitude]), String(format: "%0.6f", arguments: [coordinate.latitude]))
    }
    
    var subtitle: String? {
         return nil
    }
}

class CoordinateAnnotationView: MKMarkerAnnotationView {
    
    /*
     // Only override draw() if you perform custom drawing.
     // An empty implementation adversely affects performance during animation.
     override func draw(_ rect: CGRect) {
     // Drawing code
     }
     */
    
    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        
        self.canShowCallout = false
        self.glyphTintColor = UIColor.white
        self.markerTintColor = Color.blue.base
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.canShowCallout = false // 1
        self.glyphTintColor = UIColor.white
        self.markerTintColor = Color.blue.base
    }
    
    // MARK: - callout showing and hiding
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(false, animated: false)
    }
    
    
    override func prepareForReuse() { // 5
        super.prepareForReuse()
    }
}
