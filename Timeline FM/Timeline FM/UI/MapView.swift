//
//  MapView.swift
//  Timeline FM
//
//  Created by Zachary DeGeorge on 7/26/18.
//  Copyright © 2018 Next Day Project. All rights reserved.
//

import Foundation
import MapKit
import CoreLocation
import Material

class Polyline: MKPolyline {
    
    static var colors: [UIColor] = [Color.blue.darken3, Color.red.darken3, Color.green.darken3]
    
    var color: UIColor?
    var bold: Bool = false
}

protocol MapViewProtocol {
    var mapView: MapView! { get set}
}

class MapView: MKMapView, MKMapViewDelegate {
    
    var crumbEntryCount: Int = 0
    
    override var delegate: MKMapViewDelegate? {
        didSet {
            if self.subviews.count >= 2 {
                self.subviews[1].alpha = 0.0
            }
            
            var region = MKCoordinateRegion()
            region.center = CLLocationCoordinate2D(latitude: 42.0, longitude: -83.0) // Detroit
            region.span = MKCoordinateSpan(latitudeDelta: ABSOLUTE_MAX_DELTA_LAT / DEFAULT_TIMELINE_ANIMATION_SPAN_DIVISOR, longitudeDelta: ABSOLUTE_MAX_DELTA_LON / DEFAULT_TIMELINE_ANIMATION_SPAN_DIVISOR)
            setRegion(region, animated: false)
            
            showsCompass = false
            showsScale = false
        }
    }
    
    func mapView(_: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let tileOverlay = overlay as? MKTileOverlay {
            tileOverlay.canReplaceMapContent = true
            tileOverlay.minimumZ = 0
            return MKTileOverlayRenderer(tileOverlay: tileOverlay)
        } else if overlay is MKCircle {
            let circle = MKCircleRenderer(overlay: overlay)
            circle.fillColor = Theme.shared.active.primaryMapOverlayFillColor
            circle.strokeColor = Theme.shared.active.primaryMapOverlayStrokeColor
            circle.lineWidth = 1
            circle.alpha = 0.65
            return circle
        } else if overlay is Polyline {
            let line = MKPolylineRenderer(overlay: overlay)
            line.strokeColor = (overlay as! Polyline).color ?? Color.blue.darken3
            line.lineWidth = self.mapType != .standard ? 4.5 : 2.0
            line.alpha = 0.95
            
            if (overlay as! Polyline).bold == true {
                line.lineWidth *= 2.75
                line.strokeColor = UIColor(hex: "39FF14")!
            }
            
            return line
        } else if overlay is MKPolygon {
            let polygon = MKPolygonRenderer(overlay: overlay)
            polygon.fillColor = Theme.shared.active.primaryMapOverlayFillColor
            polygon.strokeColor = Theme.shared.active.primaryMapOverlayStrokeColor
            polygon.lineWidth = 1
            polygon.alpha = 0.65
            return polygon
        } else {
            return MKOverlayRenderer(overlay: overlay)
        }
    }
    
    
    func mapView(_ mapView: MKMapView, clusterAnnotationForMemberAnnotations memberAnnotations: [MKAnnotation]) -> MKClusterAnnotation {
        if memberAnnotations[0] is EntryAnnotation {
            let annotation = EntryClusterAnnotation(memberAnnotations: memberAnnotations)
            return annotation
        } else if memberAnnotations[0] is LocationAnnotation {
            return LocationClusterAnnotation(memberAnnotations: memberAnnotations)
        } else if memberAnnotations[0] is UserAnnotation {
            return UserClusterAnnotation(memberAnnotations: memberAnnotations)
        }else {
            return MKClusterAnnotation(memberAnnotations: memberAnnotations)
        }
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard annotation is MKUserLocation == false else {
            (annotation as! MKUserLocation).title = nil
            return nil
        }
        
        if let annotation = annotation as? LocationAnnotation {
            
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: annotation.reusableIdentifier)
            
            if annotationView == nil {
                annotationView = LocationAnnotationView(annotation: annotation, reuseIdentifier: annotation.reusableIdentifier)
            } else {
                annotationView!.annotation = annotation
            }
            return annotationView
        } else if let annotation = annotation as? UserAnnotation {
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: annotation.reusableIdentifier)
            
            if annotationView == nil {
                annotationView = UserAnnotationView(annotation: annotation, reuseIdentifier: annotation.reusableIdentifier)
            } else {
                annotationView!.annotation = annotation
            }
            
            if let user = Users.shared[annotation.subscription.user] {
                (annotationView as! UserAnnotationView).populate(user)
                return annotationView
            } else {
                return nil
            }
        } else if let annotation = annotation as? EntryAnnotation {
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: annotation.reusableIdentifier)
            
            if annotationView == nil {
                annotationView = EntryAnnotationView(annotation: annotation, reuseIdentifier: annotation.reusableIdentifier)
            } else {
                annotationView!.annotation = annotation
            }
            
            (annotationView as! EntryAnnotationView).populate(annotation.entry)
            return annotationView
        } else if let annotation = annotation as? EntryClusterAnnotation {
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: annotation.reusableIdentifier)
            
            if annotationView ==  nil {
                annotationView = EntryClusterAnnotationView(annotation: annotation, reuseIdentifier: annotation.reusableIdentifier)
            } else {
                annotationView!.annotation = annotation
            }
            
            (annotationView as! EntryClusterAnnotationView).populate(annotation: annotation)
            
            for member in annotation.memberAnnotations {
                (member as! EntryAnnotation).entry.annotation = annotation
            }
            
            return annotationView
        } else if let annotation = annotation as? UserClusterAnnotation {
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: annotation.reusableIdentifier)
            
            if annotationView ==  nil {
                annotationView = UserClusterAnnotationView(annotation: annotation, reuseIdentifier: annotation.reusableIdentifier)
            } else {
                annotationView!.annotation = annotation
            }
            
            (annotationView as! UserClusterAnnotationView).populate(annotation: annotation)
            
            return annotationView
        } else if let annotation = annotation as? LocationClusterAnnotation {
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: annotation.reusableIdentifier)
            
            if annotationView ==  nil {
                annotationView = LocationClusterAnnotationView(annotation: annotation, reuseIdentifier: annotation.reusableIdentifier)
            } else {
                annotationView!.annotation = annotation
            }
            
            return annotationView
        } else if let annotation = annotation as? CustomAnnotation {
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: CustomAnnotation.reusableIdentifier) as? MKMarkerAnnotationView
            
            if annotationView ==  nil {
               annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: CustomAnnotation.reusableIdentifier)
            } else {
                annotationView!.annotation = annotation
            }
            
            annotationView!.displayPriority = .required
            annotationView!.glyphImage = annotation.image
            annotationView!.markerTintColor = annotation.color
            
            return annotationView
        } else if let annotation = annotation as? CoordinateAnnotation {
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: annotation.reusableIdentifier)
            
            if annotationView ==  nil {
                annotationView = CoordinateAnnotationView(annotation: annotation, reuseIdentifier: annotation.reusableIdentifier)
            } else {
                annotationView!.annotation = annotation
            }
            
            return annotationView
        } else if let annotation = annotation as? MKPointAnnotation {
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: "marker-point-annotation")
            
            if annotationView ==  nil {
                annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: "marker-point-annotation")
            } else {
                annotationView!.annotation = annotation
            }
            
            (annotationView as! MKMarkerAnnotationView).markerTintColor = Color.blue.base
            (annotationView as! MKMarkerAnnotationView).glyphTintColor = UIColor.white
            
            return annotationView
        } else {
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: "marker-annotation")
            
            if annotationView ==  nil {
                annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: "marker-annotation")
            } else {
                annotationView!.annotation = annotation
            }
            
            (annotationView as! MKMarkerAnnotationView).markerTintColor = Color.blue.base
            (annotationView as! MKMarkerAnnotationView).glyphTintColor = UIColor.white
            
            return annotationView
        }
    }
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated _: Bool) {
        NotificationManager.shared.map_view_region_changed.post()
    }
    
    func mapView(_ mapView: MKMapView, didAdd views: [MKAnnotationView]) {
        for view in views {
            mapView.bringSubview(toFront: view)
        }
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        /*
        if view.annotation is MKClusterAnnotation {
            let count = (view.annotation as! MKClusterAnnotation).memberAnnotations.count
            let index = count > 1 ? count - 1 : 0
            self.showAnnotations([(view.annotation as! MKClusterAnnotation).memberAnnotations[index]], animated: true)
        } else {
            self.showAnnotations([view.annotation!], animated: true)
        }
        */
    }
}

extension MapViewProtocol {
    
    // MARK: - Map Cleanup Functions
    
    func clearMap(all: Bool = true) {
        removeOverlays()
        
        if all == true {
            removeAllAnnotations()
        } else {
            removeStaticAnnotations()
        }
    }
    
    func removeOverlays() {
        let overlays = mapView.overlays
        self.mapView.removeOverlays(overlays)
        
        /*
        if ThemeManager.shared.darkMode == true {
            self.mapView.insert(ThemeManager.shared.darkMapOverlay!, at: 0)
        }
        */
    }
    
    func removeAllAnnotations() {
        let annotations = self.mapView.annotations
        self.mapView.removeAnnotations(annotations)
        
        for item in Subscriptions.shared.items {
            item.annotation = nil
        }
    }
    
    func removeStaticAnnotations() {
        let annotations = self.mapView.annotations.filter({(annotation) -> Bool in
            if annotation is UserAnnotation || annotation is UserClusterAnnotation {
                return false
            }
            
            if let entryAnnotation = annotation as? EntryAnnotation {
                entryAnnotation.entry.annotation = nil
            }
            
            if let entryClusterAnnotation = annotation as? EntryClusterAnnotation {
                for member in entryClusterAnnotation.memberAnnotations {
                    if let entryAnnotation = member as? EntryAnnotation {
                        entryAnnotation.entry.annotation = nil
                    }
                }
            }
            
            return true
        })
        
        
        self.mapView.removeAnnotations(annotations)
    }
    
    // MARK: - Map Populate Functions
    
    func populate(sheet: Sheet?) {
        guard let sheet = sheet else {
            return
        }
        
        mapView.crumbEntryCount = 0
        sheet.entries.sort()
        for entry in sheet.entries.items {
            if entry.activity?.traveling == true {
                entry.overlayColor = Polyline.colors[mapView.crumbEntryCount % Polyline.colors.count]
                mapView.crumbEntryCount += 1
            }
            populate(entry: entry, overlay: false)
        }
    }
    
    func populate(location: Location?) {
        guard let location = location else {
            return
        }

        populateOverlay(location: location)
        populateAnnotation(location: location)
    }
    
    func populate(locations: [Location]) {
        for location in locations {
            populate(location: location)
        }
    }
    
    func populate(entry: Entry?, overlay: Bool = true) {
        guard let entry = entry, let activity = entry.activity else {
            return
        }
        
        if activity.breaking {
            return
        }
        
        if activity.traveling {
            populateBreadcrumbs(entry: entry)
            return
        }
        
        if overlay == true {
            populateOverlay(entry: entry)
        }
        
        populateBreadcrumbs(entry: entry)
        populateAnnotation(entry: entry)
    }
    
    
    func populate(photo: Photo?) {
        
        self.mapView.showsUserLocation = false
        self.mapView.isUserInteractionEnabled = true
        self.mapView.mapType = .satellite
        
        if let latitude = photo?.lat, let longitude = photo?.lon {
            
            let region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: latitude, longitude: longitude), span: MKCoordinateSpan(latitudeDelta: DEFAULT_DELTA_REGION_LAT, longitudeDelta: DEFAULT_DELTA_REGION_LON))
            self.mapView.setRegion(region, animated: false)
            
            let dropPin = CoordinateAnnotation(coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude))
            self.mapView.addAnnotation(dropPin)
        }
    }
    
    // MARK: - Map Populate Helpers
    
    func populateOverlay(entry: Entry?) {
        if let location = Locations.shared[entry?.location?.id] {
            populateOverlay(location: location)
        }
    }
    
    func populateOverlay(location: Location?) {
        guard let location = location else {
            return
        }
        
        if location.boundaryType == "Polygon" {
            addBoundary(location: location)
        } else {
            addRadius(location: location)
        }
    }
    
    func populateOverlays(locations: [Location]) {
        for location in locations {
            populateOverlay(location: location)
        }
    }
    
    func populateAnnotation(entry: Entry?) {
        guard let entry = entry, entry.location != nil else {
            return
        }
        
        let annotation = EntryAnnotation(entry: entry)
        entry.annotation = annotation
        mapView.addAnnotation(annotation)
    }
    
    func populateAnnotation(location: Location?) {
        guard let location = location, location.latitude != nil, location.longitude != nil else {
            return
        }
        
        let annotation = LocationAnnotation(location: location)
        mapView.addAnnotation(annotation)
    }
    
    
    func populateBreadcrumbs(entry: Entry?, bold: Bool = false) {
        guard let points = entry?.breadcrumbs.coordinates, points.count > 0 else {
            return
            
        }
        
        let lineOverlay = Polyline(coordinates: points, count: points.count)
        lineOverlay.bold = bold
        lineOverlay.color = entry?.overlayColor ?? Color.blue.base
        self.mapView.add(lineOverlay)
    }
    
    func addBoundary(location: Location) {
        var boundaries = location.boundaryCoordinates
        
        if boundaries.count > 0 {
            boundaries.append(boundaries[0])
            let polyOverlay = MKPolygon(coordinates: boundaries, count: boundaries.count)
            
            self.mapView.add(polyOverlay)
        }
    }
    
    func addRadius(location: Location) {
        guard let latitude = location.lat, let longitude = location.lon, let radiusString = location.radius, let radius = Double(radiusString) else { return }
        
        let center = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        let circle = MKCircle(center: center, radius: radius)
        
        self.mapView.add(circle)
    }
    
    // MARK: - Map Focusing Functions
    
    
    func focusMap(entry: Entry?, animated: Bool = true) {
        guard let entry = entry else {
            return
        }
        
        if entry.activity?.breaking == true {
            focusMap(sheet: entry.sheet)
        } else {
            if let region = entry.region {
                self.mapView.setRegion(region, animated: true)
                /*
                let camera = MKMapCamera()
                camera.centerCoordinate = region.center
                camera.pitch = DEFAULT_TIMELINE_CAMERA_PITCH
                camera.heading = 0.0
                camera.altitude = region.altitude(pitch: DEFAULT_TIMELINE_CAMERA_PITCH)
                mapView.setCamera(camera, animated: animated)
                */
            } else {
                DispatchQueue.main.async {
                    self.focusMap(animated: animated)
                }
            }
        }
    }
    
    func focusMap(sheet: Sheet?, animated: Bool = true, fade: Bool = false) {
        
        if let region = sheet?.region {
            
            if fade == true {
                UIView.animateAndChain(withDuration: DEFAULT_ANIMATION_DURATION, delay: 0.0, options: [], animations: {
                    self.mapView.alpha = 0.0
                }, completion: nil).animate(withDuration: 0.0, animations: {
                    self.mapView.setRegion(region, animated: false)
                }).animate(withDuration: DEFAULT_ANIMATION_DURATION, animations: {
                    self.mapView.alpha = 1.0
                })
            } else {
                self.mapView.setRegion(region, animated: animated)
            }
            
        }
    }
    
    func focusMap(location: Location?, animated: Bool = true) {
        if let region = location?.region {
            mapView.setRegion(region, animated: animated)
        }
    }
    
    func focusMap(delayed: Bool = false, animated: Bool = true) {
        let time = delayed == true ? 0.25 : 0.0
        
        delay(time) {
            let camera = MKMapCamera()
            camera.centerCoordinate = self.mapView.userLocation.coordinate
            camera.pitch = DEFAULT_TIMELINE_CAMERA_PITCH
            camera.heading = 0.0
            camera.altitude = 350.0
            
            self.mapView.setCamera(camera, animated: animated)
        }
    }
    
    // MARK: - Highlight Functions
    
    func highlightMap(entry: Entry?) {
        guard let entry = entry else {
            return
        }
        
        let polylines = mapView.overlays.filter { (overlay) -> Bool in
            return overlay is Polyline
        }
        
        mapView.removeOverlays(polylines)
        
        removeStaticAnnotations()
        
        // highlight selected entry
        
        populateBreadcrumbs(entry: entry, bold: true)
        populate(entry: entry, overlay: false)
        
        if let annotation = entry.annotation {
            mapView.selectAnnotation(annotation, animated: true)
        }
        
        if let start = entry.breadcrumbs.items.first, let end = entry.breadcrumbs.items.last {
            let startAnnotation = CustomAnnotation(image: AssetManager.shared.start, color: entry.overlayColor ?? Color.blue.darken3, coordinate: start.location!.coordinate)
            
            let endAnnotation = CustomAnnotation(image: AssetManager.shared.end, color: entry.overlayColor ?? Color.blue.darken3, coordinate: end.location!.coordinate)
            
            self.mapView.addAnnotations([startAnnotation, endAnnotation])
        }
    }
    
    func unhighlightMap(sheet: Sheet?) {
        
        guard let sheet = sheet else {
            return
        }
        
        let polylines = mapView.overlays.filter { (overlay) -> Bool in
            return overlay is Polyline
        }
        
        mapView.removeOverlays(polylines)
        
        removeStaticAnnotations()
        
        populate(sheet: sheet)
    }
    
    // MARK: - Other Functions
    
    func deselectAllAnnotations(_ animated: Bool = true, _ exception: MKAnnotation? = nil) {
        for annotation in mapView.annotations {
            if mapView.view(for: annotation)?.isSelected == true && annotation.isEqual(exception) == false {
                mapView.deselectAnnotation(annotation, animated: animated)
            }
        }
    }
}

extension MKCoordinateRegion {
    func altitude(pitch _: CGFloat) -> Double {
        let spanX = self.span.longitudeDelta * metersPerLon(center)
        let spanY = self.span.latitudeDelta * metersPerLon(center)
        
        let span = 1.8 * max(spanX, spanY)
        
        return span // max(spanX * boost, spanY * boost)
    }
}


