//
//  Macros.swift
//  Timeline FM
//
//  Created by Zachary DeGeorge on 8/12/18.
//  Copyright © 2018 Next Day Project. All rights reserved.
//

import Foundation
import CoreLocation
import MapKit

// Execute a block after a delay on the main thread
func delay(_ delay: Double, closure: @escaping () -> Void) {
    DispatchQueue.main.asyncAfter(
    deadline: DispatchTime.now() + Double(Int64(delay * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)) { () -> Void in
        DispatchQueue.main.async(execute: closure)
    }
}

// E-mail Validation

/// Validate email string
///
/// - parameter email: A String that rappresent an email address
///
/// - returns: A Boolean value indicating whether an email is valid.

func isValid(email: String?) -> Bool {
    guard let email = email else {
        return false
    }
    
    let emailRegEx = "(?:[a-zA-Z0-9!#$%\\&‘*+/=?\\^_`{|}~-]+(?:\\.[a-zA-Z0-9!#$%\\&'*+/=?\\^_`{|}" + "~-]+)*|\"(?:[\\x01-\\x08\\x0b\\x0c\\x0e-\\x1f\\x21\\x23-\\x5b\\x5d-\\" + "x7f]|\\\\[\\x01-\\x09\\x0b\\x0c\\x0e-\\x7f])*\")@(?:(?:[a-z0-9](?:[a-" + "z0-9-]*[a-z0-9])?\\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?|\\[(?:(?:25[0-5" + "]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-" + "9][0-9]?|[a-z0-9-]*[a-z0-9]:(?:[\\x01-\\x08\\x0b\\x0c\\x0e-\\x1f\\x21" + "-\\x5a\\x53-\\x7f]|\\\\[\\x01-\\x09\\x0b\\x0c\\x0e-\\x7f])+)\\])"
    
    let emailTest = NSPredicate(format:"SELF MATCHES[c] %@", emailRegEx)
    return emailTest.evaluate(with: email)
}



// Find meters per given lat/lon

func meterPerLat(_ coordinate: CLLocationCoordinate2D) -> Double {
    let point1 = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
    let point2 = CLLocation(latitude: coordinate.latitude + 1.0, longitude: coordinate.longitude)
    
    let distance = point1.distance(from: point2)
    
    return distance
}

func metersPerLon(_ coordinate: CLLocationCoordinate2D) -> Double {
    let point1 = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
    let point2 = CLLocation(latitude: coordinate.latitude + 1.0, longitude: coordinate.longitude)
    
    let distance = point1.distance(from: point2)
    
    return distance
}

// Region Generation

class Region {
    
   
    class func generate(coordinates: [CLLocationCoordinate2D]?) -> MKCoordinateRegion? {
        
        guard let coordinates = coordinates else {
            return nil
        }
        
        var maxNorth = MAX_NORTH_START
        var maxSouth = MAX_SOUTH_START
        var maxEast = MAX_EAST_START
        var maxWest = MAX_WEST_START
        
        for point in coordinates {
            if point.latitude > maxNorth { maxNorth = point.latitude }
            if point.latitude < maxSouth { maxSouth = point.latitude }
            if point.longitude > maxEast { maxEast = point.longitude }
            if point.longitude < maxWest { maxWest = point.longitude }
        }
        
        return calculate(maxNorth: maxNorth, maxSouth: maxSouth, maxEast: maxEast, maxWest: maxWest)
    }
    
    
    class func generate(center: CLLocationCoordinate2D?, radius: Double?) -> MKCoordinateRegion?  {
        
        guard let center = center, let radius = radius else {
            return nil
        }
        
        let lat = center.latitude
        let lon = center.longitude
        
        var maxNorth = MAX_NORTH_START
        var maxSouth = MAX_SOUTH_START
        var maxEast = MAX_EAST_START
        var maxWest = MAX_WEST_START
        
        let coordinate1 = CLLocation(latitude: lat, longitude: 0)
        let coordinate2 = CLLocation(latitude: lat, longitude: 1)
        let coordinate3 = CLLocation(latitude: 0, longitude: lon)
        let coordinate4 = CLLocation(latitude: 1, longitude: lon)
        
        let distanceLat = coordinate1.distance(from: coordinate2)
        let distanceLon = coordinate3.distance(from: coordinate4)
        
        maxNorth = lat + (radius / distanceLat)
        maxSouth = lat - (radius / distanceLat)
        maxEast = lon + (radius / distanceLon)
        maxWest = lon - (radius / distanceLon)
        
        return calculate(maxNorth: maxNorth, maxSouth: maxSouth, maxEast: maxEast, maxWest: maxWest)
    }
    
    
    class func generate(regions: [MKCoordinateRegion]?) -> MKCoordinateRegion?  {
        guard let regions = regions else {
            return nil
        }
        
        var maxNorth = MAX_NORTH_START
        var maxSouth = MAX_SOUTH_START
        var maxEast = MAX_EAST_START
        var maxWest = MAX_WEST_START
        
        for region in regions {
            
            let north = region.center.latitude + (region.span.latitudeDelta / 2.0)
            let south = region.center.latitude - (region.span.latitudeDelta / 2.0)
            let east = region.center.longitude + (region.span.longitudeDelta / 2.0)
            let west = region.center.longitude - (region.span.longitudeDelta / 2.0)
            
            if north > maxNorth { maxNorth = north }
            if south < maxSouth { maxSouth = south }
            if east > maxEast { maxEast = east }
            if west < maxWest { maxWest = west }
        }
        
        return calculate(maxNorth: maxNorth, maxSouth: maxSouth, maxEast: maxEast, maxWest: maxWest)
    }
    
    class func calculate(maxNorth: Double, maxSouth: Double, maxEast: Double, maxWest: Double) -> MKCoordinateRegion? {
        
        let centerLon = (maxWest + maxEast) / 2.0
        let centerLat = (maxNorth + maxSouth) / 2.0
        
        let center = CLLocationCoordinate2D(latitude: centerLat, longitude: centerLon)
    
        let regionSpanLat = min(max(abs(maxNorth - maxSouth), MIN_DELTA_REGION_LAT) * 1.5, ABSOLUTE_MAX_DELTA_LAT)
        let regionSpanLon = min(max(abs(maxWest - maxEast), MIN_DELTA_REGION_LON) * 1.5, ABSOLUTE_MAX_DELTA_LON)
        
        let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: regionSpanLat, longitudeDelta: regionSpanLon))
        
        // check for valid values
        guard fabs(region.span.latitudeDelta) > ABSOLUTE_MIN_DELTA_LAT || fabs(region.span.longitudeDelta) > ABSOLUTE_MIN_DELTA_LON || fabs(region.center.latitude) > ABSOLUTE_MAX_LAT || fabs(region.center.longitude) > ABSOLUTE_MAX_LON else {
            return nil
        }
        
        return region
    }
    
}

