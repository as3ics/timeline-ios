//
//  LocationClusterAnnotationView.swift
//  Timeline FM
//
//  Created by Zachary DeGeorge on 7/25/18.
//  Copyright © 2018 Next Day Project. All rights reserved.
//


import Foundation
import CoreLocation
import MapKit
import Material


class LocationClusterAnnotation: MKClusterAnnotation {
    
    var reusableIdentifier: String = "location-cluster-annotation"
    
    override init(memberAnnotations: [MKAnnotation]) {
        super.init(memberAnnotations: memberAnnotations)
    }
}

class LocationClusterAnnotationView: MKMarkerAnnotationView {
    
    /*
     // Only override draw() if you perform custom drawing.
     // An empty implementation adversely affects performance during animation.
     override func draw(_ rect: CGRect) {
     // Drawing code
     }
     */
    
    var customCalloutView: UIView?
    override var annotation: MKAnnotation? {
        willSet { customCalloutView?.removeFromSuperview() }
    }
    
    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        
        self.canShowCallout = false
        self.glyphTintColor = UIColor.white
        self.markerTintColor = Color.blueGrey.base
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.canShowCallout = false
    }
    
    // MARK: - callout showing and hiding
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    
    override func prepareForReuse() { // 5
        super.prepareForReuse()
        self.customCalloutView?.removeFromSuperview()
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        // if super passed hit test, return the result
        if let parentHitView = super.hitTest(point, with: event) { return parentHitView }
        else { // test in our custom callout.
            if customCalloutView != nil {
                return customCalloutView!.hitTest(convert(point, to: customCalloutView!), with: event)
            } else { return nil }
        }
    }
}
