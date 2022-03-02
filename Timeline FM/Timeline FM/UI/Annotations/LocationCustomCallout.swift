//
//  LocationCustomCallout.swift
//  Timeline FM
//
//  Created by Zachary DeGeorge on 7/21/18.
//  Copyright © 2018 Next Day Project. All rights reserved.
//

import UIKit
import CoreLocation
import MapKit
import Material

class LocationCustomCallout: UIView, NibProtocol {
    typealias Item = LocationCustomCallout
    static var reuseIdentifier: String = "LocationCustomCallout"
    
    var location: Location!
    
    @IBOutlet var image: UIImageView!
    @IBOutlet var name: UILabel!
    @IBOutlet var address: UILabel!
    @IBOutlet var distance: UILabel!
    
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        image.alpha = 1.0
        
        name.textColor = UIColor.white
        address.textColor = Theme.shared.active.placeholderColor
        distance.textColor = Theme.shared.active.placeholderColor
        
        layer.masksToBounds = true
        layer.cornerRadius = 5
        
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(goViewLocation)))
    }
    
    func populate(_ location: Location?) {
        guard let location = location else {
            return
        }
        
        self.location = location
        self.name.text = location.name
        
        if let latitude = location.lat, let longitude = location.lon, let current = LocationManager.shared.currentLocation {
            let _loc = CLLocation(latitude: latitude, longitude: longitude)
            let distance = current.distance(from: _loc)
            self.distance.text = String(format: "%0.1f mi", arguments: [distance * CONVERSION_METERS_TO_MILES_MULTIPLIER])
        } else {
            self.distance.text = "0.0 mi"
        }
        
        guard let city = location.city, let state = location.state else {
            return
        }
        
        self.address.text = String(format: "%@, %@", city, state)
        
    }
    
    @objc func goViewLocation(_ sender: UITapGestureRecognizer) {
        sender.view?.touchAnimation()
        
        delay(0.2) {
            self.location?.view()
        }
    }

}
