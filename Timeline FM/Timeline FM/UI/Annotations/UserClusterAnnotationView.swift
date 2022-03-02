//
//  UserClusterAnnotationView.swift
//  Timeline FM
//
//  Created by Zachary DeGeorge on 9/2/18.
//  Copyright © 2018 Next Day Project. All rights reserved.
//

import Foundation
import CoreLocation
import MapKit
import Material


class UserClusterAnnotation: MKClusterAnnotation {
    
    var reusableIdentifier: String {
        return "user-annotation"
    }
    
    var subscriptions = [Subscription]()
    
    override init(memberAnnotations: [MKAnnotation]) {
        super.init(memberAnnotations: memberAnnotations)
        
        for annotation in memberAnnotations {
            if let annote = annotation as? UserAnnotation {
                subscriptions.append(annote.subscription)
            }
        }
    }
}

class UserClusterAnnotationView: MKMarkerAnnotationView {
    
    /*
     // Only override draw() if you perform custom drawing.
     // An empty implementation adversely affects performance during animation.
     override func draw(_ rect: CGRect) {
     // Drawing code
     }
     */
    
    var subscriptions: [Subscription] = [Subscription]()
    
    var customCalloutView: UserClusterCustomCallout?
    
    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
    }
    
    func populate(annotation: MKAnnotation?) {
        self.prepareForReuse()
        
        self.subscriptions.removeAll()
        
        for item in (annotation as! UserClusterAnnotation).memberAnnotations {
            self.subscriptions.append((item as! UserAnnotation).subscription)
        }
        
        self.canShowCallout = false
        self.glyphTintColor = UIColor.white
        self.markerTintColor = Color.green.base
        self.clusteringIdentifier = "user-annotation"
        self.displayPriority = .required
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.canShowCallout = false
    }
    
    // MARK: - callout showing and hiding
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        if self.customCalloutView == nil {
            self.customCalloutView = UserClusterCustomCallout.loadNib()
            self.customCalloutView?.populate(self.subscriptions)
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
        } else {
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
        self.subscriptions.removeAll()
        self.customCalloutView?.cleanse()
        self.customCalloutView?.removeFromSuperview()
        self.customCalloutView = nil
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        // if super passed hit test, return the result
        
        guard self.customCalloutView?.alpha != 0.0 else { return nil }
        
        if let parentHitView = super.hitTest(point, with: event) { return parentHitView }
        else { // test in our custom callout.
            if customCalloutView != nil {
                return customCalloutView!.hitTest(convert(point, to: customCalloutView!), with: event)
            } else { return nil }
        }
    }
    
}
