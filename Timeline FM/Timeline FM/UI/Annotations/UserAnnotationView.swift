//
//  UserAnnotationView.swift
//  Timeline FM
//
//  Created by Zachary DeGeorge on 7/23/18.
//  Copyright © 2018 Next Day Project. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import Material

@objc class UserAnnotation: NSObject, MKAnnotation {
    
    var reusableIdentifier: String {
        return "user-annotation-\(subscription.user!)-\(Date().description)"
    }
    
    @objc dynamic var coordinate: CLLocationCoordinate2D
    @objc dynamic var subscription: Subscription
    
    //@objc dynamic var coordinate: CLLocationCoordinate2D
    
    init(subscription: Subscription, coordinate: CLLocationCoordinate2D) {
        self.subscription = subscription
        self.coordinate = coordinate
    }
    
    @objc func setCoordinate(newCoordinate: CLLocationCoordinate2D) {
        let key = #keyPath(coordinate)
        self.willChangeValue(forKey: key)
    
        coordinate = newCoordinate
    
        self.didChangeValue(forKey: key)
    }
    
    @objc var title: String? {
        return nil //String(format: "%@ %@", user.firstName!, user.lastName!)
    }
    
    @objc var subtitle: String? {
        return nil
    }
}

class UserAnnotationView: MKMarkerAnnotationView {
    
    /*
     // Only override draw() if you perform custom drawing.
     // An empty implementation adversely affects performance during animation.
     override func draw(_ rect: CGRect) {
     // Drawing code
     }
     */
    var user: User!
    
    var customCalloutView: UserCustomCallout?
    
    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        self.canShowCallout = false
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.canShowCallout = false // 1
        self.image = AssetManager.shared.annotation
    }
    
    func populate(_ user: User) {
        
        prepareForReuse()
        
        self.user = user
    
        self.markerTintColor = Color.green.base
        self.glyphText = String(format: "%@%@", String(user.firstName!.first!), String(user.lastName!.first!))
        self.glyphTintColor = UIColor.white
        self.clusteringIdentifier = "user-annotation"
        self.displayPriority = .required
    }
    
    // MARK: - callout showing and hiding
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        if self.customCalloutView == nil {
            PeopleObject.controlEvent = .touchDown
            self.customCalloutView = UserCustomCallout.loadNib()
            self.customCalloutView!.populate(self.user)
            self.customCalloutView!.zPosition = 1
            self.customCalloutView!.frame.origin.x -= self.customCalloutView!.frame.width / 2.0 - (self.frame.width / 2.0)
            self.customCalloutView!.frame.origin.y -= self.customCalloutView!.frame.height + 45.0
            self.customCalloutView!.alpha = 0.0
            self.addSubview(self.customCalloutView!)
        }
        
        if selected {
            if animated {
                self.customCalloutView!.alpha = 0.0
                UIView.animate(withDuration: 0.3, animations: {
                    self.customCalloutView!.alpha = 1.0
                })
            } else {
                self.customCalloutView!.alpha = 1.0
            }
        } else { // 3
            if animated {
                UIView.animate(withDuration: 0.3, animations: {
                    self.customCalloutView!.alpha = 0.0
                }, completion: nil)
            } else {
                self.customCalloutView!.alpha = 0.0
            }
        }
    }
    
    override func prepareForReuse() {
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
