//
//  MapTableViewCell.swift
//  Timesheets
//
//  Created by Zachary DeGeorge on 3/25/18.
//  Copyright © 2018 Timeline Software, LLC. All rights reserved.
//

import CoreLocation
import MapKit
import MapKitGoogleStyler
import Material
import CoreLocation
import UIKit

class StandardMapCell: UITableViewCell, NibProtocol, MapViewProtocol, MKMapViewDelegate {
    typealias Item = StandardMapCell
    static var reuseIdentifier: String = "StandardMapCell"

    @IBOutlet var mapView: MapView!
    @IBOutlet var plusButton: UIButton!
    @IBOutlet var minusButton: UIButton!
    
    let DEFUALT_ZOOM_IN_MULTIPLIER: Double = 0.75
    let DEFUALT_ZOOM_OUT_MULTIPLIER: Double = 1.25

    //static var darkMapOverlay: MKTileOverlay?
    
    var pinAnnotationView: MKAnnotationView!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code

        mapView.delegate = mapView
        
        //plusButton.addTarget(self, action: #selector(zoomIn), for: UIControlEvents.touchUpInside)
        //minusButton.addTarget(self, action: #selector(zoomOut), for: UIControlEvents.touchUpInside)

        applyTheme()

        Theme.shared.theme_changed.observe(self, selector: #selector(applyTheme))
    }

    @objc func zoomOut() {
        let center = mapView.region.center
        let span = mapView.region.span

        let latDelta = min(span.latitudeDelta * DEFUALT_ZOOM_OUT_MULTIPLIER, ABSOLUTE_MAX_DELTA_LAT)
        let lonDelta = min(span.longitudeDelta * DEFUALT_ZOOM_OUT_MULTIPLIER, ABSOLUTE_MAX_DELTA_LON)

        mapView.setRegion(MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lonDelta)), animated: true)
    }

    @objc func zoomIn() {
        let center = mapView.region.center
        let span = mapView.region.span

        let latDelta = max(span.latitudeDelta * DEFUALT_ZOOM_IN_MULTIPLIER, ABSOLUTE_MIN_DELTA_LAT)
        let lonDelta = max(span.longitudeDelta * DEFUALT_ZOOM_IN_MULTIPLIER, ABSOLUTE_MIN_DELTA_LON)

        mapView.setRegion(MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lonDelta)), animated: true)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    func populateMap(entry: Entry?, sheet: Sheet?) {
        clearMap(all: false)

        if let region = entry?.region {
            mapView.setRegion(region, animated: false)
        } else if let region = sheet?.region {
            mapView.setRegion(region, animated: true)
        }

        populate(entry: entry)
        
        if entry?.activity?.traveling == true {
            
            if let start = entry?.breadcrumbs.items.first, let end = entry?.breadcrumbs.items.last {
                let startAnnotation = CustomAnnotation(image: AssetManager.shared.start, color: entry!.overlayColor, coordinate: start.location!.coordinate)
                
                let endAnnotation = CustomAnnotation(image: AssetManager.shared.end, color: entry!.overlayColor, coordinate: end.location!.coordinate)
                
                self.mapView.addAnnotations([startAnnotation, endAnnotation])
            }
        }
    }
    
    func populateMap(sheet: Sheet?) {
        
        clearMap(all: false)
        
        guard let sheet = sheet else {
            return
        }
        
        populate(sheet: sheet)
        
        if let region = sheet.region {
            mapView.setRegion(region, animated: false)
        }
        
    }

    func populateMap(location: Location?) {
        
        clearMap(all: false)
        
        guard let location = location else {
            return
        }

        if let region = location.region {
            mapView.setRegion(region, animated: false)
        }

        populate(location: location)
    }

    func populateMap(coordinate: CLLocationCoordinate2D, title: String, subtitle: String) {
        clearMap(all: false)

        mapView.alpha = 0.0
        let region = MKCoordinateRegion(center: coordinate, span: MKCoordinateSpan(latitudeDelta: 0.002, longitudeDelta: 0.002))
        mapView.setRegion(region, animated: true)

        let dropPin = MKPointAnnotation()
        dropPin.coordinate = coordinate
        dropPin.title = title
        dropPin.subtitle = subtitle

        let marker = MKMarkerAnnotationView(annotation: dropPin, reuseIdentifier: "point-annotation")
        mapView.addAnnotation(marker.annotation!)

        UIView.animate(withDuration: 0.2) {
            self.mapView.alpha = 1.0
        }
    }
}


extension StandardMapCell: ThemeSupportedProtocol {
    @objc func applyTheme() {
        mapView.isUserInteractionEnabled = false
    }
}
