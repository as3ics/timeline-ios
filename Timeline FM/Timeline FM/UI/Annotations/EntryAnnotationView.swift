
//
//  EntryAnnotationView.swift
//  Timeline FM
//
//  Created by Zachary DeGeorge on 7/23/18.
//  Copyright © 2018 Next Day Project. All rights reserved.
//

import UIKit
import CoreLocation
import MapKit
import Material

@objc class EntryAnnotation: NSObject, MKAnnotation {
    
    var reusableIdentifier: String {
        return "entry-annotation-\(entry.id!)"
    }
    
    weak var entry: Entry!
    var location: Location! {
        return entry.location!
    }
    
    @objc dynamic var coordinate: CLLocationCoordinate2D
    
    init(entry: Entry) {
        self.entry = entry
        self.coordinate = entry.location!.coordinate!
    }
    
    var title: String? {
        return location.name
    }
    
    var subtitle: String? {
        return entry.activity?.name
    }
}

class EntryAnnotationView: MKMarkerAnnotationView {
    
    weak var entry: Entry!
    var customCalloutView: EntryCustomCallout?
    
    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        
        self.canShowCallout = false
        self.glyphImage = AssetManager.shared.annotation
        self.glyphTintColor = UIColor.white
        self.markerTintColor = Color.lightBlue.base
        self.clusteringIdentifier = entry?.location?.id
        self.displayPriority = .required
    }
    
    func populate(_ entry: Entry) {
        self.entry = entry
        
        self.clusteringIdentifier = entry.location?.id
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.canShowCallout = false // 1
        self.image = AssetManager.shared.annotation
    }
    
    override var annotation: MKAnnotation? {
        didSet {
            self.entry = (annotation as? EntryAnnotation)?.entry
        }
    }
    
    // MARK: - callout showing anxd hiding
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        if self.customCalloutView?.entry !== entry {
            self.customCalloutView?.removeFromSuperview()
            self.customCalloutView = EntryCustomCallout.loadNib()
            self.customCalloutView!.populate(entry)
            self.customCalloutView!.frame.origin.x -= self.customCalloutView!.frame.width / 2.0 - (self.frame.width / 2.0)
            self.customCalloutView!.frame.origin.y -= self.customCalloutView!.frame.height + EntryCustomCallout.size.height / 2.0
            self.customCalloutView!.alpha = 0.0
            self.addSubview(self.customCalloutView!)
            self.layoutIfNeeded()
        }
        
        if selected {
            self.customCalloutView!.observeUpdates()
            if animated {
                UIView.animate(withDuration: 0.3, animations: {
                    self.customCalloutView!.alpha = 1.0
                })
            } else {
                self.customCalloutView!.alpha = 1.0
            }
        } else {
            self.customCalloutView!.unobserveUpdates()
            if animated {
                UIView.animate(withDuration: 0.3, animations: {
                    self.customCalloutView!.alpha = 0.0
                }, completion: nil)
            } else {
                self.customCalloutView!.alpha = 0.0
            }
        }
    }
    
    
    override func prepareForReuse() { // 5
        super.prepareForReuse()
        self.entry = nil
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
