//
//  EntryClusterAnnotation.swift
//  Timeline FM
//
//  Created by Zachary DeGeorge on 7/24/18.
//  Copyright © 2018 Next Day Project. All rights reserved.
//

import Foundation
import CoreLocation
import MapKit
import Material


class EntryClusterAnnotation: MKClusterAnnotation {
    
    var reusableIdentifier: String {
        return "entry-cluster-annotation-\(location.id!)"
    }
    
    var entry: Entry!
    
    var location: Location! {
        return entry.location!
    }
    
    override init(memberAnnotations: [MKAnnotation]) {
        super.init(memberAnnotations: memberAnnotations)
        
        self.entry = (memberAnnotations[0] as! EntryAnnotation).entry
    }
}

class EntryClusterAnnotationView: MKMarkerAnnotationView {
    
    /*
     // Only override draw() if you perform custom drawing.
     // An empty implementation adversely affects performance during animation.
     override func draw(_ rect: CGRect) {
     // Drawing code
     }
     */
    
    var entries: Entries!
    var location: Location! {
        return self.entries.items[0].location!
    }
    
    var customCalloutView: EntryClusterCustomCallout?
    
    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
    }
    
    func populate(annotation: MKAnnotation?) {
        self.prepareForReuse()
        
        entries = Entries(sheet: nil)
        
        for item in (annotation as! EntryClusterAnnotation).memberAnnotations {
            self.entries.add((item as! EntryAnnotation).entry)
        }
        
        self.canShowCallout = false
        self.glyphTintColor = UIColor.white
        self.markerTintColor = Color.lightBlue.base
        self.clusteringIdentifier = self.entries.items[0].location?.id
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
            self.customCalloutView = EntryClusterCustomCallout.loadNib()
            self.customCalloutView?.populate(self.entries.items)
            self.customCalloutView!.frame.origin.x -= self.customCalloutView!.frame.width / 2.0 - (self.frame.width / 2.0)
            self.customCalloutView!.frame.origin.y -= self.customCalloutView!.frame.height + EntryCustomCallout.size.height / 2.0
            self.customCalloutView!.alpha = 0.0
            self.addSubview(self.customCalloutView!)
        }
        
        if selected {
            for callout in self.customCalloutView?.objects ?? [] {
                callout.observeUpdates()
            }
            if animated {
                self.customCalloutView!.alpha = 0.0
                UIView.animate(withDuration: 0.3, animations: {
                    self.customCalloutView!.alpha = 1.0
                })
            } else {
                self.customCalloutView!.alpha = 1.0
            }
        } else {
            for callout in self.customCalloutView?.objects ?? [] {
                callout.unobserveUpdates()
            }
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
        self.entries = nil
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
