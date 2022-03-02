//
//  LocationHeaderCell.swift
//  Timeline FM
//
//  Created by Zachary DeGeorge on 7/3/18.
//  Copyright © 2018 Next Day Project. All rights reserved.
//

import CoreLocation
import MapKit
import Material
import UIKit

class LocationHeaderCell: UITableViewCell, ThemeSupportedProtocol, NibProtocol, MapViewProtocol, MKMapViewDelegate {
    typealias Item = LocationHeaderCell
    static var reuseIdentifier: String = "LocationHeaderCell"
    static var cellHeight: CGFloat = 95.0

    @IBOutlet var mapView: MapView!
    @IBOutlet var button: Button!
    @IBOutlet var nameLine: UILabel!
    @IBOutlet var addressLine1: UILabel!
    @IBOutlet var addressLine2: UILabel!

    var location: Location?

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        

        mapView.delegate = mapView
        
        applyTheme()
        
        Theme.shared.theme_changed.observe(self, selector: #selector(applyTheme))
        NotificationManager.shared.new_latest_placemark.observe(self, selector: #selector(updateObservationView))
    }
    
    func populate(_ location: Location? = nil) {
        
        self.location = location
        button.alpha = 0.0

        self.updateObservationView()
    }

    @objc func updateObservationView() {
        if let placemark = LocationManager.shared.latestPlacemark, let location = LocationManager.shared.currentLocation {
            var number: String = ""
            if let subThoroughfare = placemark.subThoroughfare {
                number = String(format: "%@ ", subThoroughfare)
            }

            let addr1 = String(format: "%@%@", number, placemark.thoroughfare ?? "")
            let addr2 = String(format: "%@, %@ %@", placemark.locality ?? "", placemark.administrativeArea ?? "", placemark.postalCode ?? "")

            nameLine.text = placemark.name != addr1 ? placemark.name : nil
            addressLine1.text = addr1
            addressLine2.text = addr2
            button.alpha = 1.0
            
            DispatchQueue.global(qos: .background).async {
                if let displaceLat = placemark.location?.coordinate.latitude, let displaceLon = placemark.location?.coordinate.longitude {
                    let objective = CLLocationCoordinate2D(latitude: displaceLat * 0.999965, longitude: displaceLon * 0.999965)

                    let camera = MKMapCamera(lookingAtCenter: location.coordinate, fromEyeCoordinate: objective, eyeAltitude: 150.0)
                    self.mapView.setCamera(camera, animated: false)
                }
            }
        } else {
            nameLine.text = nil
            addressLine1.text = nil
            addressLine2.text = nil
            button.alpha = 0.0
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc func applyTheme() {
        backgroundColor = UIColor.clear
        
        nameLine.autoResize()
        
        button.title = "Quick Create"
        button.backgroundColor = Color.blue.base.withAlphaComponent(0.5)
        button.titleColor = UIColor.white
        button.pulseColor = UIColor.white
        button.isUserInteractionEnabled = true
        
        button.isUserInteractionEnabled = true
    }
}
