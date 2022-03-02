//
//  Breadcrumb.swift
//  Timeline Software, LLC
//
//  Created by Timeline Software, LLC on 12/29/16.
//  Copyright © 2016 Timeline Software, LLC. All rights reserved.
//

import Foundation
import MapKit
import CoreLocation
import CoreData

// MARK: - Breadcrumbs

@objcMembers class Breadcrumbs: APIContainer<Breadcrumb>, RegionProtocol {

    // MARK: - Descriptors
    
    override var modelType: ModelType {
        return ModelType.Breadcrumbs
    }
    
    override var descriptor: String {
        return "Breadcrumbs"
    }
    
    // MARK: - Other Properties
    
    var sheet: String?
    var entry: String?
    
    var coordinates = [CLLocationCoordinate2D]()
    var fetchedCount: Int = 0

    var newBreadcrumbs: [Breadcrumb] {
        var values = [Breadcrumb]()

        if fetchedCount >= 1 {
            var i: Int = max(fetchedCount - 2, 0)
            while i < count {
                values.append(items[i])
                i = i + 1
            }

            fetchedCount = count
        }

        return values
    }
    
    // MARK: - API Protocol Values
    
    override var retrieveUrl: String? {
        guard let orgId = Auth.shared.orgId, let sheetId = self.sheet, let entryId = self.entry else {
            return nil
        }
        
        return String(format: "/organizations/%@/timesheets/%@/entries/%@/breadcrumbs", arguments: [orgId, sheetId, entryId])
    }
    
    override func process(_ callback: @escaping (_ err: Error?, _ newResult: Any?) -> Void, _ initialValue: Any?) {
        
        guard let data = initialValue as? [JSON] else {
            callback(nil, nil)
            return
        }
        
        fetchedCount = 0
        region = nil
        
        items.removeAll()
        coordinates.removeAll()
        
        for value in data {
            let item = Item(attrs: value)
            append(item)
        }
        
        callback(nil, nil)
    }
    
    // MARK: - Additional Update Methods

    func append(_ breadcrumb: Breadcrumb) {
        guard let location = breadcrumb.coordinate else {
            return
        }

        items.append(breadcrumb)
        coordinates.append(location)

        if location.latitude > maxNorth { maxNorth = location.latitude }
        if location.latitude < maxSouth { maxSouth = location.latitude }
        if location.longitude > maxEast { maxEast = location.longitude }
        if location.longitude < maxWest { maxWest = location.longitude }

        if fetchedCount == 0 { fetchedCount = 1 }
    }
    
    // MARK: - Region Protocol
    
    var maxNorth: Double = MAX_NORTH_START // latitude positive
    var maxSouth: Double = MAX_SOUTH_START // latitude negative
    var maxEast: Double = MAX_EAST_START // longitude positive
    var maxWest: Double = MAX_WEST_START // longitude negative

    var region: MKCoordinateRegion? {
        
        get {
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
        
        set {
            if newValue == nil {
                maxNorth = MAX_NORTH_START
                maxSouth = MAX_SOUTH_START
                maxEast = MAX_EAST_START
                maxWest = MAX_WEST_START
            }
        }
    }
}

// MARK: - Breadcrumb

@objcMembers class Breadcrumb: APIModel, LocationProtocol {

    // MARK: - Descriptors
    
    override var descriptor: String {
        return "Breadcrumb"
    }
    
    override var modelType: ModelType {
        return ModelType.Breadcrumb
    }

    override var keys: [String] {
        return [ "id", "name", "latitude", "longitude", "sheet", "entry", "speed", "altitude", "accuracy", "heading", "timestamp"]
    }
    
    // MARK: - Additional Properties
    
    var sheet: String?
    var entry: String?
    var latitude: String?
    var longitude: String?

    var speed: String?
    var altitude: String?
    var accuracy: String?
    var heading: String?
    
    var distance: Double = 0.0
    
    // MARK: - API Protocol Values
    
    override var createUrl: String? {
        guard let orgId = Auth.shared.orgId, let sheetId = self.sheet, let entryId = self.entry else {
            return nil
        }
        
        return String(format: "/organizations/%@/timesheets/%@/entries/%@/breadcrumbs", arguments: [orgId, sheetId, entryId])
    }
    
    override var createParams: JSON? {
        guard let createdBy = Auth.shared.id else {
            return nil
        }
        
        var params = toJson()
        params["createdBy"] = createdBy as JSONObject
        return params
    }
    
    // MARK: - API Protocol Methods
    
    override func processCreate(data: JSON) -> Bool {
        guard let id = data["id"] as? String else {
            return false
        }
        
        self.id = id
        
        if let totalDistance = data["totalDistance"]?.doubleValue {
            self.distance = totalDistance
        }
        
        return true
    }

    // MARK: - Other Functions

    override func toJson() -> JSON {
        var json = super.toJson()
        
        json["distance"] = "\(distance)" as JSONObject
        
        return json
    }
}
