//
//  Location.swift
//  Timeline Software, LLC
//
//  Created by Timeline Software, LLC on 3/8/16.
//  Copyright © 2016 Timeline Software, LLC. All rights reserved.
//

import Foundation
import CSV
import MapKit
import CoreLocation
import CoreData

// MARK: - Locations

@objcMembers class Locations: APIContainer<Location>, APIContainerSingletonProtocol {
    
    // MARK: - Properties
    
    typealias Shared = Locations

    static var shared = Shared()

    override var modelType: ModelType {
        return ModelType.Locations
    }
    
    override var descriptor: String {
        return "Locations"
    }
    
    override var entityName: String {
        return "CoreLocation"
    }
    
    var sorted: Bool = false
    
    // MARK: - Methods
    
    override init() {
        super.init()
        
        restoreAllEntities()
        NotificationManager.shared.new_current_location.observe(self, selector: #selector(newLocationNotification))
    }
    
    init(lean: Bool) {
        super.init()
    }
    
    // MARK: - API Protocol Constructors
    
    override var retrieveUrl: String? {
        guard let orgId = Auth.shared.orgId else {
            return nil
        }
        
        return String(format: "/organizations/%@/locations", arguments: [orgId])
    }
    
    override var retrieveParams: JSON? {
        var params: JSON = EMPTY_JSON
        params["photos"] = true as JSONObject
        return params
    }
    
    override func process(_ callback: @escaping (_ err: Error?, _ newResult: Any?) -> Void, _ initialValue: Any?) {
        
        guard let data = initialValue as? [JSON] else {
            callback(nil, nil)
            return
        }
        
        items.removeAll()
        deleteAllEntities()
        
        for (index, value) in data.enumerated() {
            let item = Item(attrs: value)
            item.tag = index + 1
            item.entity = item.createEntity()
            items.append(item)
            
            
        }
        
        self.sort()
        
        callback(nil, nil)
    }
    
    func closest(_ location: CLLocation? = LocationManager.shared.currentLocation) -> Location? {
        guard let location = location else {
            return nil
        }
        
        var closestDistance: Double = Double.greatestFiniteMagnitude
        
        var value: Location?
        for item in items {
            if let latitude = item.lat, let longitude = item.lon {
                let dist: Double = CLLocation(latitude: latitude, longitude: longitude).distance(from: location)
                item.distance = dist
                if dist < closestDistance {
                    closestDistance = dist
                    value = item
                }
            }
        }
    
        return value
    }
    
    func updateDistances(_ location: CLLocation? = LocationManager.shared.currentLocation) {
        guard let location = location else {
            return
        }
        
        for item in items {
            if let latitude = item.lat, let longitude = item.lon {
                item.distance = location.distance(from: CLLocation(latitude: latitude, longitude: longitude))
            } else {
                item.distance = Double.greatestFiniteMagnitude
            }
        }
    }
    
    func sortByDistance(_ location: CLLocation? = LocationManager.shared.currentLocation) {
        
        guard let location = location else {
            sortByName()
            return
        }
        
        updateDistances(location)
        
        items.sort(by: { $0.distance < $1.distance })
    }
    
    func sortByName() {
        items.sort(by: { $0.name! < $1.name! })
    }

    func sort(location: CLLocation? = LocationManager.shared.currentLocation) {
        guard let location = location else {
            sortByName()
            return
        }

        sortByDistance(location)
    }
    
    @objc func newLocationNotification(_ notification: NSNotification) {
        updateDistances()
    }
}

// MARK: - Location

@objcMembers class Location: APIModel, RegionProtocol, AssetsProtocol, LocationProtocol {
    
    // MARK: - Descriptors

    override var entityName: String {
        return "CoreLocation"
    }
    
    override var modelType: ModelType {
        return ModelType.Location
    }
    
    override var descriptor: String {
        return "Location"
    }
    
    override var keys: [String] {
        return [ "id", "organization", "name", "address", "city", "state", "zip", "radius", "latitude", "longitude", "photo", "notes", "boundaryType", "boundary", "zones", "verified" ]
    }
    
    // MARK: - Other Properties
    var organization: String?
    var address: String?
    var city: String?
    var state: String?
    var zip: String?
    var radius: String?
    var photo: String?
    var notes: String?
    var boundaryType: String? /* "Circle" or "Polygon" */
    var boundary: String?
    var latitude: String?
    var longitude: String?
    var verified: Bool = false
    var zones: [String] = [String]()
    
    var assets: JSON = JSON()
    
    static var assetKeys: [String] = [ "Card", "Cell", "Snapshot" ]
    
    var distance: Double = Double.greatestFiniteMagnitude
    
    var boundaryCoordinates: [CLLocationCoordinate2D] {
        get {
            var array = [CLLocationCoordinate2D]()
            
            if let boundaryString = boundary {
                if boundaryString.characters.count > 5 {
                    let csv = try! CSVReader(string: boundaryString, hasHeaderRow: true) // It must be true.
                    
                    while csv.next() != nil {
                        if let lat = csv["latitude"], let lon = csv["longitude"] {
                            if let latitude = Double(lat), let longitude = Double(lon) {
                                array.append(CLLocationCoordinate2D(latitude: latitude, longitude: longitude))
                            }
                        }
                    }
                }
            }
            
            return array
        } set {
            let stream = OutputStream(toMemory: ())
            let csv = try! CSVWriter(stream: stream)
            
            try! csv.write(row: ["latitude", "longitude"])
            for vertex in newValue {
                csv.beginNewRow()
                try! csv.write(field: String(describing: vertex.latitude))
                try! csv.write(field: String(describing: vertex.longitude))
            }
            
            csv.stream.close()
            
            let csvData = stream.property(forKey: .dataWrittenToMemoryStreamKey) as! NSData
            let csvString = String(data: Data(referencing: csvData), encoding: .utf8)
            self.boundary = csvString
        }
    }
    
    var addressString: String? {
        guard let city = self.city, let state = self.state else {
            return nil
        }
        
        return String(format: "%@, %@", city, state)
    }
    
    var addressStringZip: String? {
        guard let city = self.city, let state = self.state, let zip = self.zip else {
            return nil
        }
        
        return String(format: "%@, %@ %@", city, state, zip)
    }
    
    // MARK: - Deviant Initializer
    
    required init() {
        super.init()
    }
    
    required public init(attrs: JSON) {
        super.init(attrs: attrs)
        
        if let coordinates = attrs["coordinates"] as? JSON {
            latitude = coordinates["latitude"] as? String
            longitude = coordinates["longitude"] as? String
        }
        
        if let zones = attrs["zones"] as? [String] {
            for zone in zones {
                self.zones.append(zone)
            }
        }
    }
    
    required public init(object: NSManagedObject) {
        super.init(object: object)
        
    }
    
    // MARK: - Assets Protocol
    
    func dequeSnapshot() -> UIImage? {
        guard let snapshot = asset(named: "Snapshot") as? UIImage else {
            if let snapshot = self.photo?.base64Image() {
                self.addAsset(named: "Snapshot", snapshot)
                return snapshot
            }
            
            return nil
        }
        
        return snapshot
    }
    
    
    // MARK: - Asset Regeneration Methods
    
    func reprocessAssets(_ callback: @escaping(_ success: Bool) -> Void) {
        
        var queries = [(@escaping (Error?, Any?) -> (), Any?) -> ()]()
        
        queries.append(self.updateAssets)
        queries.append(self.update)
        
        Async.waterfall(0, queries, end: { error, _ in
            guard error == nil else {
                callback(false)
                return
            }
            
            self.saveEntity()
            
            callback(true)
        })
    }
    
    func updateAssets(_ callback: @escaping (_ err: Error?, _ newResult: Any?) -> Void, _ initialValue: Any?) {
        guard let region = self.region, let count = initialValue as? Int else {
            callback(nil, initialValue)
            return
        }
        
        self.clearAssets()
        
        let options = MKMapSnapshotOptions()
        options.mapType = .mutedStandard
        options.region = region
        options.size = CGSize(width: 50.0, height: 50.0)
        options.showsBuildings = false
        options.showsPointsOfInterest = false
        
        let snapshotter = MKMapSnapshotter(options: options)
        
        snapshotter.start(with: DispatchQueue.main) { snapshot, error in
            guard error == nil, var image = snapshot?.image else {
                callback(nil, count + 1)
                return
            }
            
            if self.boundaryType == "Polygon" {
                let points = self.boundaryCoordinates
                
                UIGraphicsBeginImageContext(image.size)
                let renderer = UIGraphicsImageRenderer(size: image.size)
                let overlay = renderer.image { context in
                    
                    context.cgContext.setLineWidth(1.5)
                    context.cgContext.setStrokeColor(UIColor.blue.withAlphaComponent(0.5).cgColor)
                    context.cgContext.setFillColor(UIColor.blue.withAlphaComponent(0.3).cgColor)
                    
                    if let cgpoint = snapshot?.point(for: points[0]) {
                        context.cgContext.move(to: cgpoint)
                    }
                    
                    for point in points {
                        if let cgpoint = snapshot?.point(for: point) {
                            context.cgContext.addLine(to: cgpoint)
                        }
                    }
                    
                    if let cgpoint = snapshot?.point(for: points[0]) {
                        context.cgContext.move(to: cgpoint)
                    }
                    
                    context.cgContext.fillPath()
                    context.cgContext.strokePath()
                }
                
                UIGraphicsBeginImageContextWithOptions(image.size, true, image.scale)
                
                image.draw(at: CGPoint.zero)
                overlay.draw(at: CGPoint.zero)
                
                image = UIGraphicsGetImageFromCurrentImageContext()!
                
                self.photo = image.base64String()
                
            } else {
                
                UIGraphicsBeginImageContext(image.size)
                let renderer = UIGraphicsImageRenderer(size: image.size)
                let overlay = renderer.image { context in
                    
                    context.cgContext.setLineWidth(1.5)
                    context.cgContext.setStrokeColor(UIColor.blue.withAlphaComponent(0.5).cgColor)
                    context.cgContext.setFillColor(UIColor.blue.withAlphaComponent(0.3).cgColor)
                    
                    if let coordinate = self.coordinate, let cgpoint = snapshot?.point(for: coordinate), let radius = Double(self.radius!) {
                        let scale = options.size.width / (CGFloat(region.span.longitudeDelta) * CGFloat(meterPerLat(coordinate)))
                        
                        context.cgContext.addArc(center: cgpoint, radius: CGFloat(radius) * scale, startAngle: 0, endAngle: CGFloat.pi * 2.0, clockwise: false)
                    }
                    
                    context.cgContext.fillPath()
                    context.cgContext.strokePath()
                }
                
                UIGraphicsBeginImageContextWithOptions(image.size, true, image.scale)
                
                image.draw(at: CGPoint.zero)
                overlay.draw(at: CGPoint.zero)
                
                image = UIGraphicsGetImageFromCurrentImageContext()!
                
                self.photo = image.base64String()
            }
            
            Notifications.shared.systemMessage("\(count + 1) of \(Locations.shared.count) Locations Updated")
            
            callback(nil, count + 1)
        }
    }
    
    // MARK: - Zone Functions
    
    var sectionTitles: [String] {
        
        zones = zones.sorted { $0 < $1 }
        
        var sectionTitles = [String]()
        
        for zone in zones {
            let name = zone.uppercased()
            let character = name.characters.first
            
            var found: Bool = false
            for value in sectionTitles {
                if value.characters.first == character {
                    found = true
                    break
                }
            }
            
            if found == false {
                sectionTitles.append(String(character!))
            }
        }
        
        return sectionTitles
    }
    
    func sectionValues(_ section: String) -> [String] {
        var values = [String]()
        
        let character = section.characters.first
        
        for value in zones {
            if value.uppercased().characters.first == character {
                values.append(value)
            }
        }
        
        return values
    }
    
    func addZone(_ callback: @escaping (_ err: Error?, _ newResult: Any?) -> Void, _ initialValue: Any?) {
        
        guard let zone = initialValue as? String else {
            callback(APIClientErrors.InputError, initialValue)
            return
        }
        
        let matches = zones.filter { (item) -> Bool in
            return item == zone
        }
        
        guard matches.count == 0 else {
            callback(nil, initialValue)
            return
        }
        
        zones.append(zone)
        
        do {
            self.entity?.setValue(self.zones, forKey: "zones")
            try self.entity?.managedObjectContext?.save()
        } catch {
            // foo
        }
        
        
        Async.waterfall(nil, [update]) { (error, returnValue) in
            callback(error, returnValue)
        }
    }
    
    func removeZone(_ callback: @escaping (_ err: Error?, _ newResult: Any?) -> Void, _ initialValue: Any?) {
        
        guard let zone = initialValue as? String else {
            callback(APIClientErrors.InputError, initialValue)
            return
        }
        
        for (index, item) in zones.enumerated() {
            if item == zone {
                zones.remove(at: index)
                break
            }
        }
        
        do {
            self.entity?.setValue(self.zones, forKey: "zones")
            try self.entity?.managedObjectContext?.save()
        } catch {
            // foo
        }
        
        Async.waterfall(nil, [update]) { (error, returnValue) in
            callback(error, returnValue)
        }
    }
    
    
    
    // MARK: - APICoreModel CRUD
    
    override var createUrl: String? {
        guard let orgId = Auth.shared.orgId else {
            return nil
        }
        
        return String(format: "/organizations/%@/locations", arguments: [orgId])
    }
    
    override var createParams: JSON? {
        
        guard let createdBy = Auth.shared.id else {
            return nil
        }
        
        var params = toJson()
        params["createdBy"] = createdBy as JSONObject
        
        return params
    }
    
    override func processCreate(data: JSON) -> Bool {
        guard let id = data["id"] as? String else {
            return false
        }
        
        self.id = id
        self.distance = 0.0
        self.entity = self.createEntity()
        
        return true
    }
    
    override var retrieveUrl: String? {
        guard let orgId = Auth.shared.orgId, let id = self.id else {
            return nil
        }
        
        return String(format: "/organizations/%@/locations/%@", arguments: [orgId, id])
    }
    
    override var retrieveParams: JSON? {
        var params: JSON = EMPTY_JSON
        
        if self.photo == nil {
            params["photos"] = true as JSONObject
        }
        
        return params
    }
    
    override func processRetrieve(data: JSON) -> JSON? {
        let location = Location(attrs: data)
        
        if let entity = Locations.shared.entity(id: location.id) {
            location.entity = entity
            location.saveEntity()
        } else {
            location.entity = location.createEntity()
        }
        
        let container: JSON = [
            "model": location as JSONObject,
            ]
        
        return container
    }
    
    override var updateUrl: String? {
        guard let orgId = Auth.shared.orgId, let id = self.id else {
            return nil
        }
        
        return String(format: "/organizations/%@/locations/%@", arguments: [orgId, id])
    }
    
    override var updateParams: JSON? {
        guard let updatedBy = Auth.shared.id else {
            return nil
        }
        
        var params: JSON = toJson()
        params["updatedBy"] = updatedBy as JSONObject
        return params
    }
    
    override var deleteUrl: String? {
        guard let orgId = Auth.shared.orgId, let id = self.id else {
            return nil
        }
        
        return String(format: "/organizations/%@/locations/%@", arguments: [orgId, id])
    }
    
    override var deleteParams: JSON? {
        return EMPTY_JSON
    }
    
    // MARK: - Region Protocol

    var maxNorth: Double = MAX_NORTH_START // latitude positive
    var maxSouth: Double = MAX_SOUTH_START // latitude negative
    var maxEast: Double = MAX_EAST_START // longitude positive
    var maxWest: Double = MAX_WEST_START // longitude negative

    var region: MKCoordinateRegion? {
        get {
            self.region = nil

            if boundaryType == "Polygon" {
                for point in boundaryCoordinates {
                    if point.latitude > maxNorth { maxNorth = point.latitude }
                    if point.latitude < maxSouth { maxSouth = point.latitude }
                    if point.longitude > maxEast { maxEast = point.longitude }
                    if point.longitude < maxWest { maxWest = point.longitude }
                }
            } else { // is radius
                guard let lat = self.lat, let lon = self.lon, let radiusString = self.radius, let radius = Double(radiusString) else {
                    return nil
                }

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
            }

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
    
    // MARK: - Other Functions

    override func toJson() -> JSON {
        var json = self.json()
        
        var coordinates: JSON?
        if let latitude = self.latitude, let longitude = self.longitude {
            coordinates = JSON()
            coordinates!["latitude"] = latitude as JSONObject
            coordinates!["longitude"] = longitude as JSONObject
            json["coordinates"] = coordinates as JSONObject
        }
        
        return json
    }
}

extension Location {
    
    func presentUsers() -> [User] {
        
        let matches = Stream.shared.items.filter { (stream) -> Bool in
            return stream.entry?.location?.id == self.id
        }
        
        var users = [User]()
        
        for match in matches {
            users.append(match.user)
        }
        
        users.sort(by: { $0.userRole.rawValue < $1.userRole.rawValue })
        
        return users
    }
    
}
