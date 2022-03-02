//
//  LocationAnnotationView.swift
//  Timeline FM
//
//  Created by Zachary DeGeorge on 7/21/18.
//  Copyright © 2018 Next Day Project. All rights reserved.
//

import UIKit
import CoreLocation
import MapKit
import Material

@objc class LocationAnnotation: NSObject, MKAnnotation {
    
    var reusableIdentifier: String {
        return "location-annotation-\(location.id!)"
    }
    
    var location: Location
    @objc dynamic var coordinate: CLLocationCoordinate2D
    
    init(location: Location) {
        self.location = location
        self.coordinate = location.coordinate!
    }
    
    var title: String? {
        return location.name
    }
    
    var subtitle: String? {
        guard let city = location.city, let state = location.state else {
            return nil
        }
        
        return String(format: "%@, %@", city, state)
    }
}

class LocationAnnotationView: MKMarkerAnnotationView {

    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */
    var location: Location?
    
    var customCalloutView: LocationCustomCallout?
    override var annotation: MKAnnotation? {
        willSet {
            self.location = (annotation as? LocationAnnotation)?.location
        }
    }
    
    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        
        
        
        self.customCalloutView?.removeFromSuperview()
        
        self.canShowCallout = false
        self.glyphImage = AssetManager.shared.building
        self.glyphTintColor = UIColor.white
        self.markerTintColor = Color.blueGrey.base
        self.clusteringIdentifier = "location-cluster"
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.canShowCallout = false // 1
        self.image = AssetManager.shared.annotation
    }
    
    // MARK: - callout showing and hiding
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        
        if self.customCalloutView == nil {
            self.customCalloutView = LocationCustomCallout.loadNib()
            self.customCalloutView!.populate(location)
            self.customCalloutView!.frame.origin.x -= self.customCalloutView!.frame.width / 2.0 - (self.frame.width / 2.0)
            self.customCalloutView!.frame.origin.y -= self.customCalloutView!.frame.height + 52
            self.addSubview(self.customCalloutView!)
            
        }
        
        if selected {
            if animated {
                self.customCalloutView?.alpha = 0.0
                UIView.animate(withDuration: 0.3, animations: {
                    self.customCalloutView?.alpha = 1.0
                })
            } else {
                self.customCalloutView?.alpha = 1.0
            }
            
        } else {
            if animated { // fade out animation, then remove it.
                UIView.animate(withDuration: 0.3, animations: {
                    self.customCalloutView?.alpha = 0.0
                }, completion: nil)
            } else {
                self.customCalloutView?.alpha = 0.0
            }
        }
    }
    
    
    override func prepareForReuse() { // 5
        super.prepareForReuse()
        self.customCalloutView?.removeFromSuperview()
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard self.customCalloutView?.alpha != 0.0 else { return nil }
        
        if let parentHitView = super.hitTest(point, with: event) {
            return parentHitView
            
        } else {
            return customCalloutView?.hitTest(convert(point, to: customCalloutView!), with: event)
        }
    }

}
