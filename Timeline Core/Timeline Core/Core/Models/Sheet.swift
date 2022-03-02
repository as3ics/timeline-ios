//
//  Sheet.swift
//  Timeline Software, LLC
//
//  Created by Timeline Software, LLC on 3/1/16.
//  Copyright © 2016 Timeline Software, LLC. All rights reserved.
//

import Foundation
import MapKit
import CoreLocation
import CoreData

// MARK: - Sheets

@objcMembers class Sheets: APIContainer<Sheet> {

    // MARK: - Descriptors
    
    override var modelType: ModelType {
        return ModelType.Sheets
    }
    
    override var descriptor: String {
        return "Sheets"
    }
    
    // MARK: - Other Properties
    
    var user: String?
    var start: Date?
    var end: Date?

    
    // MARK: - API Protocol Values
    
    override var retrieveUrl: String? {
        guard let orgId = Auth.shared.orgId else {
            return nil
        }
        
        return String(format: "/organizations/%@/timesheets", arguments: [orgId])
    }
    
    override var retrieveParams: JSON? {
        guard let userId = self.user, let begin = self.start, let end = self.end else {
            return nil
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd/YY"
        
        let params: JSON = [
            "startDate": formatter.string(from: begin) as JSONObject,
            "endDate": formatter.string(from: end) as JSONObject,
            "user": userId as JSONObject,
            ]
        
        return params
    }
    
    // MARK: - API Protocol Methods
    
    override func process(_ callback: @escaping (_ err: Error?, _ newResult: Any?) -> Void, _ initialValue: Any?) {
        
        guard let data = initialValue as? [JSON] else {
            callback(nil, nil)
            return
        }
        
        items.removeAll()
        
        for value in data {
            let item = Item(attrs: value)
            items.append(item)
        }
        
        callback(nil, nil)
    }
}

// MARK: - Sheet

@objcMembers class Sheet: APIModel, RegionProtocol {
    
    // MARK: - Descriptors
    
    override var descriptor: String {
        return "Sheet"
    }
    
    override var modelType: ModelType {
        return ModelType.Sheet
    }
    
    override var keys: [String] {
        return [ "id", "date", "submissionDate", "submitted", "approved" ]
    }
    
    // MARK: Initializers
    
    required init() {
        super.init()
    }
    
    required init(attrs: JSON) {
        super.init(attrs: attrs)
        
        if let statistics = attrs["statistics"] as? JSON {
            self.statistics = SheetStatistics(attrs: statistics)
        }
        
        if let userAttrs = attrs["user"] as? JSON, let userId = userAttrs["id"] as? String {
            self.user = userId
        } else if let userId = attrs["user"] as? String {
            self.user = userId
        }
    }
    
    required public init(object: NSManagedObject) {
        super.init(object: object)
    }
    
    override func commonInit() {
        super.commonInit()
        
        entries = Entries(sheet: self)
    }

    // MARK: Other Properties
    
    var user: String?
    var hours: String?
    
    var date: Date?
    var submissionDate: Date?
    
    var submitted: Bool = false
    var approved: Bool = false
    
    var time: AnyObject?

    var statistics: SheetStatistics?
    var entries: Entries!
    var location: Location? {
        
        if let entry = self.entries.latest, let location = Locations.shared[entry.location?.id] { return location } else { return nil }
    }
    
    // MARK: - API Protocol Values
    
    override var createUrl: String? {
        guard let orgId = Auth.shared.orgId else {
            return nil
        }
        
        return String(format: "/organizations/%@/timesheets", arguments: [orgId])
    }
    
    override var createParams: JSON? {
        
        guard let userId = self.user ?? Auth.shared.id, let createdBy = Auth.shared.id else {
            return nil
        }
        
        let params: JSON = [
            "date": APIClient.shared.formatter.string(from: self.date ?? Date()) as JSONObject,
            "user": userId as JSONObject,
            "timeZone": TimeZone.current.identifier as JSONObject,
            "createdBy": createdBy as JSONObject
            ]
        
        return params
    }
    
    override func processCreate(data: JSON) -> Bool {
        guard let id = data["id"] as? String, let date = data["date"] as? String else {
            return false
        }
        
        self.id = id
        self.date = APIClient.shared.formatter.date(from: date)
    
        return true
    }
    
    override var retrieveUrl: String? {
        
        guard let orgId = Auth.shared.orgId, let sheetId = self.id else {
            return nil
        }
        
        return String(format: "/organizations/%@/timesheets/%@", arguments: [orgId, sheetId])
    }
    
    override func processRetrieve(data: JSON) -> JSON? {
        let sheet = Sheet(attrs: data)
        
        let container: JSON = [
            "model": sheet as JSONObject,
            ]
        
        return container
    }
    
    override var deleteUrl: String? {
        guard let orgId = Auth.shared.orgId, let id = self.id else {
            return nil
        }
        
        return String(format: "/organizations/%@/timesheets/%@", arguments: [orgId, id])
    }
    
    override var deleteParams: JSON? {
        let params: JSON = [
            "hard": "false" as JSONObject,
            ]
        
        return params
    }
    
    override var updateUrl: String? {
        guard let orgId = Auth.shared.orgId, let id = self.id else {
            return nil
        }
        
        let url = String(format: "/organizations/%@/timesheets/%@", arguments: [orgId, id])
        return url
    }
    
    override var updateParams: JSON? {
        var params = toJson()
        params["timeZone"] = TimeZone.current.identifier as JSONObject
        params["updatedBy"] = (Auth.shared.id ?? "") as JSONObject
        return params
    }
    
    // MARK: - Other Methods

    func submit(_ callback: @escaping (_ err: Error?, _ newResult: Any?) -> Void, _ initialValue: Any?) {
        let function: String = "submit"

        let start = Date()

        guard let orgId = Auth.shared.orgId, let id = self.id, let submissionDate = self.submissionDate else {
            APIDiagnostics.shared.ERROR(_classDescription: self.descriptor,
                                        _functionDescriptor: function,
                                        _url: "nil",
                                        _params: ["initialValues": initialValue.debugDescription as JSONObject],
                                        _start: start,
                                        _error: APIClientErrors.InputError)
            callback(APIClientErrors.InputError, initialValue)
            return
        }

        let url = String(format: "/organizations/%@/timesheets/%@", arguments: [orgId, id])

        let params: JSON = [
            "submissionDate": APIClient.shared.formatter.string(from: submissionDate) as JSONObject,
            "submitted": true as JSONObject,
            "approved": false as JSONObject,
            "timeZone": TimeZone.current.identifier as JSONObject,
        ]

        APIClient.shared.PUT(url: url, parameters: params) { (_, response, body) -> Void in

            guard response?.statusCode == 200 else {
                APIDiagnostics.shared.ERROR(_classDescription: self.descriptor,
                                            _functionDescriptor: function,
                                            _url: url,
                                            _params: params,
                                            _start: start,
                                            _error: APIClientErrors.StatusError,
                                            _response: response,
                                            _body: body)
                callback(APIClientErrors.StatusError, initialValue)
                return
            }

            APIDiagnostics.shared.SUCCESS(_classDescription: self.descriptor,
                                          _functionDescriptor: function,
                                          _url: url,
                                          _params: params,
                                          _start: start,
                                          _body: body,
                                          _response: response)

            APIUpdater.shared.post(type: self.modelType, action: .Submit, model: self)
            callback(nil, initialValue)
        }
    }
    
    // MARK: - Region Protocol

    var maxNorth: Double = MAX_NORTH_START // latitude positive
    var maxSouth: Double = MAX_SOUTH_START // latitude negative
    var maxEast: Double = MAX_EAST_START // longitude positive
    var maxWest: Double = MAX_WEST_START // longitude negative

    var region: MKCoordinateRegion? {
        get {
            guard entries.count > 0 else {
                return nil
            }

            calcMapRegion()

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
    
    fileprivate func calcMapRegion() {
        region = nil
        
        // Calculate the max/min going through each time entry
        for entry in entries.items {
            // If it's a traveling activity go through the breadcrumbs
            if entry.activity!.traveling {
                if entry.breadcrumbs.count > 0 {
                    if entry.breadcrumbs.maxNorth > maxNorth { maxNorth = entry.breadcrumbs.maxNorth }
                    if entry.breadcrumbs.maxSouth < maxSouth { maxSouth = entry.breadcrumbs.maxSouth }
                    if entry.breadcrumbs.maxEast > maxEast { maxEast = entry.breadcrumbs.maxEast }
                    if entry.breadcrumbs.maxWest < maxWest { maxWest = entry.breadcrumbs.maxWest }
                }
            } else if let location = entry.location {
               
                let _ = location.region // needed to calculate region values
                
                if location.maxNorth > maxNorth { maxNorth = location.maxNorth }
                if location.maxSouth < maxSouth { maxSouth = location.maxSouth }
                if location.maxEast > maxEast { maxEast = location.maxEast }
                if location.maxWest < maxWest { maxWest = location.maxWest }
                
                if entry.breadcrumbs.count != 0 {
                    if entry.breadcrumbs.maxNorth > maxNorth { maxNorth = entry.breadcrumbs.maxNorth }
                    if entry.breadcrumbs.maxSouth < maxSouth { maxSouth = entry.breadcrumbs.maxSouth }
                    if entry.breadcrumbs.maxEast > maxEast { maxEast = entry.breadcrumbs.maxEast }
                    if entry.breadcrumbs.maxWest < maxWest { maxWest = entry.breadcrumbs.maxWest }
                }
            }
        }
    }
    
    override func cleanse() {
        super.cleanse()
        
        for item in entries.items {
            item.cleanse()
        }
        
        entries.items.removeAll()
        statistics = nil
    }
}

// MARK: - Sheet Extension

extension Sheet {
    
    func updateTimes() {
        if let entries = entries, entries.count > 0 {
            if submissionDate != nil {
                for i in 0 ... entries.count - 1 {
                    if i == 0 {
                        entries[i]!.seconds = submissionDate!.timeIntervalSince1970 - entries[i]!.start!.timeIntervalSince1970

                        if entries[i]!.seconds < 0 {
                            entries[i]!.seconds = 0
                        }
                    } else {
                        entries[i]!.seconds = entries[i - 1]!.start!.timeIntervalSince1970 - entries[i]!.start!.timeIntervalSince1970
                    }
                }
            } else {
                for i in 0 ... entries.count - 1 {
                    if i == 0 {
                        entries[i]!.seconds = Date().timeIntervalSince1970 - (entries.latest?.start!.timeIntervalSince1970)!
                    } else {
                        entries[i]!.seconds = entries[i - 1]!.start!.timeIntervalSince1970 - entries[i]!.start!.timeIntervalSince1970
                    }
                }
            }
        }
    }

    var totalSeconds: Double {
        var seconds: Double = 0

        if entries.count > 0 {
            for i in 0 ... entries.count - 1 {
                seconds = seconds + duration(index: i)!
            }
        }

        return seconds
    }

    var paidSeconds: Double {
        var seconds: Double = 0
        
        updateTimes()
        
        for (index, entry) in entries.items.enumerated() {
            if entry.paidTime == true {
                seconds = seconds + duration(index: index)!
            }
        }

        return seconds
    }

    var unpaidSeconds: Double {
        var seconds: Double = 0

        updateTimes()

        for (index, entry) in entries.items.enumerated() {
            if entry.paidTime == false {
                seconds = seconds + duration(index: index)!
            }
        }

        return seconds
    }

    var travelingSeconds: Double {
        var seconds: Double = 0

        updateTimes()

        for (index, entry) in entries.items.enumerated() {
            if entry.activity?.traveling == true {
                seconds = seconds + duration(index: index)!
            }
        }

        return seconds
    }

    func duration(index: Int) -> Double? {
        guard entries.count > 0, index < entries.count, let entry = self.entries[index] else {
            return nil
        }

        let start = entry.start
        var end: Date?

        if index == 0 && submissionDate == nil {
            end = Date()
        } else if index == 0 && submissionDate != nil {
            end = submissionDate!
        } else {
            end = entries[index - 1]?.start
        }

        guard start != nil, end != nil else {
            return nil
        }

        return end!.timeIntervalSince1970 - start!.timeIntervalSince1970
    }

    var distance: Double {
        var value: Double = 0.0

        for entry in entries.items {
            if entry.activity?.traveling == true {
                value = value + entry.meters
            }
        }

        return value
    }

    func indexes(location: Location?) -> [Int] {
        guard let location = location, self.entries.count > 0 else {
            return []
        }

        var array = [Int]()

        for (index, entry) in entries.items.enumerated() {
            if let loc = entry.location {
                if location.id == loc.id {
                    array.append(index)
                }
            }
        }

        return array
    }
}


class SheetStatistics {
    var summary: JSON = EMPTY_JSON
    
    var time: [String: JSON] = [
        "activities": EMPTY_JSON,
        "locations": EMPTY_JSON,
        ]
    
    var distance: [String: JSON] = [
        "activities": EMPTY_JSON,
        "locations": EMPTY_JSON,
        ]
    
    var totalActivites: Int = 0
    var totalLocations: Int = 0
    
    convenience init(attrs: JSON) {
        self.init()
        
        totalActivites = 0
        totalLocations = 0
        
        summary.removeAll()
        time["activities"]!.removeAll()
        time["locations"]!.removeAll()
        distance["activities"]!.removeAll()
        distance["locations"]!.removeAll()
        
        if let summary = attrs["summary"] as? JSON {
            for (key, value) in summary {
                self.summary[key] = value
            }
        }
        
        if let distance = attrs["distance"] as? JSON {
            if let activities = distance["activities"] as? JSON {
                for (key, value) in activities {
                    self.distance["activities"]![key] = value
                    totalActivites = totalActivites + 1
                }
            }
            
            if let locations = distance["locations"] as? JSON {
                for (key, value) in locations {
                    self.distance["locations"]![key] = value
                    totalLocations = totalLocations + 1
                }
            }
        }
        
        if let time = attrs["time"] as? JSON {
            if let activities = time["activities"] as? JSON {
                for (key, value) in activities {
                    self.time["activities"]![key] = value
                }
            }
            
            if let locations = time["locations"] as? JSON {
                for (key, value) in locations {
                    self.time["locations"]![key] = value
                }
            }
        }
    }
}
