//
//  LocationManager.swift
//  Timeline SDK
//
//  Created by Zachary DeGeorge on 6/25/18.
//  Copyright © 2018 Timeline Software LLC. All rights reserved.
//

import CoreLocation
import Darwin
import Foundation
import MapKit
import UIKit
import SwiftLocation

let CONVERSION_MPH_TO_MPS_MULTIPLIER: Double = 0.44704

let DEBOUNCE_COUNT_SPEED_TRAVELING: Int = 2
let MIN_ACCURACY_FOR_SPEED_TRAVELING: Double = 121.0
let MIN_SPEED_FOR_CREATING_TRAVELING: Double = 6.0
let MAX_LOCATION_DELTA_METERS: Double = 1000.0
let MIN_LOCATION_DELTA_SPEED: Double = 5.0
let MAX_DEGREE_DELTA_HEADING: Double = 5.0
let MAX_ACCURACY_DELTA: Double = 121.0
let GPS_DEFERMENT_DISTANCE_METERS: CLLocationDistance = 850.0
let GPS_DEFERMENT_TIME_SECONDS: TimeInterval = 120.0
let FILTER_NEW_LOCATION_METERS: CLLocationDistance = 29.0
let FILTER_NEW_LOCATION_SECONDS: TimeInterval = 120.0
let UPDATE_CURRENT_LOCATION_TIMEOUT: TimeInterval = 45.0
let TIMEOUT_UPDATE_LOCATION: TimeInterval = 5.0
let MIN_MPH_TRAVELING_LOCATION_UPDATE: Double = 5.0

let DEBOUNCE_TIME_ALERT_SECONDS: TimeInterval = 2.5
let DEBOUNCE_TIME_CREATE_AUTO_ENTRIES: TimeInterval = 60.0

@objc class LocationManager: NSObject, CLLocationManagerDelegate {
    static let shared = LocationManager()
    
    var newLocation: Bool = true
    fileprivate var debounceTime: Date?
    fileprivate var debounceType: DebounceType?
    fileprivate var speedDebounce: Int = 0
    
    /* Debounce variables to prevent multiple entries from being created */
    fileprivate var isCreatingNewEntry: Bool = false
    fileprivate var isCreatingTravelingEntry: Bool = false
    fileprivate var updateHold: Bool = false
    fileprivate var stateHold: Bool = false
    
    /* For checking integrity of automode settings */
    fileprivate var automode: String?
    fileprivate var highSensitivityRequest: Request?
    fileprivate var lowSensitivityRequest: Request?
    fileprivate var keepAliveSensitivityRequest: Request?
    fileprivate var significantChangesRequest: Request?
    
    
    func initialize() {
        
        automode = "nil"
        resetDebounce()
        isTrackingLocation = true
        
        Notifications.shared.loaded_true.observe(self, selector: #selector(isLoaded))
        Notifications.shared.loaded_false.observe(self, selector: #selector(notLoaded))
        
        if available {
            Locator.currentPosition(accuracy: .house, onSuccess: { (location) -> (Void) in
                self.updateLocation(location)
            }) { (error, location) -> (Void) in
                guard let location = location else { return }
                self.updateLocation(location)
            }
        }
    }
    
    var available: Bool {
        return Locator.authorizationStatus == .authorizedAlways || Locator.authorizationStatus == .authorizedWhenInUse
    }
    
    /* Variable for managing the tracking of locations */
    var isTrackingLocation: Bool = false {
        didSet {
            switch isTrackingLocation {
            case true:
                self.updateGPSSensitivity()
                break
            case false:
                self.gpsSetting = GPSSetting.Off
                break
            }
        }
    }

    /* GPS Settings State */
    var gpsSetting: GPSSetting = GPSSetting.Undetermined {
        willSet {
            
            guard newValue != gpsSetting else {
                return
            }
            
            switch newValue {
            case .Off:
                self.clearRequest(&highSensitivityRequest)
                self.clearRequest(&lowSensitivityRequest)
                
                Locator.manager.stopUpdatingLocation()
                Locator.manager.allowsBackgroundLocationUpdates = false
                Locator.manager.pausesLocationUpdatesAutomatically = true
                
                filteredLocation = nil
                
                break
            case .Low:
                
                self.clearRequest(&lowSensitivityRequest)
                self.clearRequest(&highSensitivityRequest)
                
                DispatchQueue.main.async {
                    Locator.backgroundLocationUpdates = true
                    Locator.manager.pausesLocationUpdatesAutomatically = false
                    self.lowSensitivityRequest = Locator.subscribePosition(accuracy: Accuracy.block, onUpdate: { (location) -> (Void) in
                        self.updateLocation(location)
                    }, onFail: { (error, location) -> (Void) in
                        guard let location = location else { return }
                        self.updateLocation(location)
                    })
                    
                    Locator.manager.startUpdatingLocation()
                }
                break
            case .High:
                
                self.clearRequest(&highSensitivityRequest)
                self.clearRequest(&lowSensitivityRequest)
                
                DispatchQueue.main.async {
                    Locator.backgroundLocationUpdates = true
                    Locator.manager.pausesLocationUpdatesAutomatically = false
                    self.highSensitivityRequest = Locator.subscribePosition(accuracy: Accuracy.house, onUpdate: { (location) -> (Void) in
                        self.updateLocation(location)
                    }, onFail: { (error, location) -> (Void) in
                        guard let location = location else {
                            return
                            
                        }
                        self.updateLocation(location)
                    })
                    
                    Locator.manager.startUpdatingLocation()
                }
                break
            default:
                break
            }
            
            NotificationManager.shared.gps_sensitivity_updated.post()
        }
    }

    var currentLocation: CLLocation? {
        didSet {
            
            if currentLocation == nil {
                filteredLocation = nil
            } else if filteredLocation == nil {
                filteredLocation = currentLocation
            }
            
            NotificationManager.shared.new_current_location.post()
        }
    }
    
    fileprivate var latestDistance: CLLocationDistance = 0.0
    fileprivate var latestBearing: Double = 0.0
    fileprivate var previousBreadcrumbLocation: CLLocation?
    fileprivate var latestBreadcrumbLocation: CLLocation? {
        didSet {
            guard let location = latestBreadcrumbLocation else {
                latestDistance = 0.0
                latestBearing = 0.0
                previousBreadcrumbLocation = nil
                return
            }
            
            let distance = previousBreadcrumbLocation?.distance(from: location) ?? 0.0
            latestDistance = distance
            previousBreadcrumbLocation = location
        }
    }
    
    fileprivate var geoCoder = CLGeocoder()
    var filteredLocation: CLLocation? {
        didSet {
            guard let location = filteredLocation else {
                latestPlacemark = nil
                latestBreadcrumbLocation = nil
                filteredLocation = nil
                accuracies.removeAll()
                return
            }
            
            latestBearing = location.course
            newLocation = true
            
            NotificationManager.shared.new_latest_location.post()
            
            geoCoder.reverseGeocodeLocation(location, completionHandler: { (placemarks, error) -> Void in
                if let placemark = placemarks?.last, error == nil {
                    self.latestPlacemark = placemark
                }
            })
        }
    }
    
    var latestPlacemark: CLPlacemark? {
        didSet {
            guard let _ = self.latestPlacemark else { return }
            NotificationManager.shared.new_latest_placemark.post()
        }
    }
    
    fileprivate var fetchingLocation: Bool = false
    func fetchLocation(_ callback: @escaping(_ location: CLLocation?) -> ()) {
        
        guard available, !fetchingLocation else {
            callback(nil)
            return
        }
        
        fetchingLocation = true
        Locator.manager.startUpdatingLocation()
        
        Locator.currentPosition(accuracy: .house, timeout: Timeout.after(TIMEOUT_UPDATE_LOCATION), onSuccess: { (location) -> (Void) in
            callback(location)
            self.fetchingLocation = false
        }) { (error, location) -> (Void) in
            callback(location)
            self.fetchingLocation = false
        }
    }
    
    func updateLocation() {
        
        fetchLocation { (location) in
            guard let location = location else {
                return
            }
            
            self.updateLocation(location)
        }
    }
    
    
    @objc fileprivate func isLoaded() {
        isTrackingLocation = true
    }
    
    @objc fileprivate func notLoaded() {
        isTrackingLocation = false
    }

    func updateLocation(_ location: CLLocation) {
        
        if self.filteredLocation == nil {
            filteredLocation = location
        }
        
        currentLocation = location
        accuracies.append(location.getAccuracy())
        
        guard App.shared.isLoaded == true else {
            return
        }
        
        self.processLocation(location)
    }
    
    var processingLocation: Bool = false
    func processLocation(_ location: CLLocation) {
        // Filter location based on System State
        guard let filtered = filteredLocation, !processingLocation else {
            return
        }
        
        processingLocation = true
        
        let distance = filtered.distance(from: location)
        let accuracy = location.getAccuracy()
        let speed = location.speed / CONVERSION_MPH_TO_MPS_MULTIPLIER
        let time = Date().timeIntervalSince(filtered.timestamp)
        
        switch System.shared.state {
        case .LoggedIn, .Empty:
            
            let distance = filtered.distance(from: location)
            let speed = location.speed
            
            if distance > FILTER_NEW_LOCATION_METERS || time > FILTER_NEW_LOCATION_SECONDS {
                filteredLocation = location
            }
            
            if speed > MIN_SPEED_FOR_CREATING_TRAVELING && stateHold == false, location.getAccuracy() < MIN_ACCURACY_FOR_SPEED_TRAVELING {
                speedDebounce = speedDebounce + 1
                
                if isCreatingTravelingEntry == false && speedDebounce >= DEBOUNCE_COUNT_SPEED_TRAVELING {
                    speedDebounce = 0
                    createTravelingEntry()
                }
            } else if speed < MIN_SPEED_FOR_CREATING_TRAVELING * 0.5 {
                speedDebounce = 0
            }
            break
        case .Traveling:
            
            if distance >= MAX_LOCATION_DELTA_METERS, accuracy < MAX_ACCURACY_DELTA {
                filteredLocation = location
            } else if speed > MIN_MPH_TRAVELING_LOCATION_UPDATE {
                let newBearing = location.course
                let difference = fabs(newBearing - latestBearing)
                
                if difference > MAX_DEGREE_DELTA_HEADING {
                    filteredLocation = location
                }
            }
            break
        case .Break, .Off, .Error:
            isTrackingLocation = false
            break
        }
    
        if speed > MIN_SPEED_FOR_CREATING_TRAVELING, debounceTime != nil {
            resetDebounce()
        }
        
        if shouldUpdateAPIWithLocation {
            postLocationToAPI(false)
        }
        
        stateMachine()
        processingLocation = false
    }
    
    
    @objc func stateMachine() {
        // Temporary hold to prevent the location updater from changing the state of the app
        guard stateHold == false, System.shared.state != .Break, let location = currentLocation else {
            return
        }
        
        switch System.shared.state {
        case .Empty, .Traveling:
            if let closestLandmark = Locations.shared.closest(location) {
                examineLocation(closestLandmark)
            }
            break
        case .LoggedIn:
            if let loggedInLocation = DeviceUser.shared.sheet?.location {
                examineLocation(loggedInLocation)
            }
            break
        default:
            break
        }
    }
    
    
    func clearRequest(_ request: inout Request?) {
        if request != nil {
            Locator.stopRequest(request!)
            request = nil
        }
    }


    /* Commands for changing GPS settings for Battery Management */
    func setSensitivityLow() {
        guard gpsSetting != .Low else { return }
        
        self.gpsSetting = .Low
        
    }
    
    func setSensitivityHigh() {
        guard gpsSetting != .High else { return }

        self.gpsSetting = .High
        
    }

    func getDebounceTime() -> Double? {
        guard let debounce = debounceTime else { return nil }

        let time = DEBOUNCE_TIME_CREATE_AUTO_ENTRIES + debounce.timeIntervalSinceNow
        return max(time, 0.0)
    }

    func getDebounceType() -> DebounceType? {
        return debounceType
    }

    func resetDebounce() {
        debounceType = nil
        debounceTime = nil
        NotificationManager.shared.location_manager_debouncing.post()
    }

    func requestAuthorization() {
        Locator.requestAuthorizationIfNeeded(AuthorizationLevel.whenInUse)
    }
    
    @objc var authorizationStatus: CLAuthorizationStatus {
        return Locator.authorizationStatus
    }
    

    func updateHold(_ value: Bool) {
        updateHold = value

        if updateHold == false {
            isCreatingNewEntry = false
            isCreatingTravelingEntry = false
        }
    }

    func holdState(_ newState: Bool) {
        stateHold = newState
        resetDebounce()
    }

    func getStateHoldValue() -> Bool {
        return stateHold
    }

    fileprivate func hold() -> Bool {
        let value = updateHold

        updateHold(true)

        return value
    }

    var postingLocationToAPI: Bool = false
    func postLocationToAPI(_ override: Bool = false) {
        guard override == false else {
            fetchLocation { (location) in
                self.filteredLocation = location
                self.newLocation = true
                self.postLocationToAPI()
            }
            return
        }

        guard !postingLocationToAPI, newLocation == true, let latestLocation = filteredLocation, let sheet = DeviceUser.shared.sheet, let entry = sheet.entries.latest else {
            return
        }

        postingLocationToAPI = true
        newLocation = false

        latestBreadcrumbLocation = latestLocation

        let breadcrumb = Breadcrumb()
        breadcrumb.entry = entry.id
        breadcrumb.sheet = sheet.id
        breadcrumb.latitude = "\(latestLocation.coordinate.latitude)"
        breadcrumb.longitude = "\(latestLocation.coordinate.longitude)"
        breadcrumb.timestamp = latestLocation.timestamp
        breadcrumb.speed = "\(latestLocation.speed)"
        breadcrumb.altitude = "\(latestLocation.altitude)"
        breadcrumb.accuracy = "\(latestLocation.horizontalAccuracy)"
        breadcrumb.heading = "\(latestLocation.course)"
        breadcrumb.distance = latestDistance

        Async.waterfall(nil, [breadcrumb.create]) { _, _ in
            self.postingLocationToAPI = false
        }
    }

    fileprivate func examineLocation(_ landmark: Location) {

        switch System.shared.state {
        case .Traveling, .Empty:
            guard insideLocation(landmark) == true else {
                resetDebounce()
                return
            }

            if getDebounceTimer(DebounceType.ClockIn) >= DEBOUNCE_TIME_CREATE_AUTO_ENTRIES {
                createNewEntry(landmark)
            }
            break
        case .LoggedIn:
            guard insideLocation(landmark) == false else {
                resetDebounce()
                return
            }
            
            if getDebounceTimer(DebounceType.Travel) >= DEBOUNCE_TIME_CREATE_AUTO_ENTRIES {
                createTravelingEntry()
            }
            break
        default:
            break
        }
    }

    fileprivate func getDebounceTimer(_ type: DebounceType) -> TimeInterval {
        if type != debounceType || debounceTime == nil { setDebounceTimer(Date(), type: type) }

        if type == DebounceType.ClockIn { checkLogInAlertDebounced()
        } else if type == DebounceType.Travel { checkTravelingAlertDebounced() }

        return -debounceTime!.timeIntervalSinceNow
    }

    fileprivate func setDebounceTimer(_ date: Date, type: DebounceType) {
        debounceTime = date
        debounceType = type
    }

    fileprivate func checkLogInAlertDebounced() {
        let time = Date().timeIntervalSince(debounceTime!)
        if time > DEBOUNCE_TIME_ALERT_SECONDS {
            let userInfo: [AnyHashable: Any] = [
                "debounceType": self.debounceType as Any,
                "debounceTime": DEBOUNCE_TIME_CREATE_AUTO_ENTRIES - time as Any,
            ]

            NotificationManager.shared.location_manager_debouncing.post(userInfo)
        }
    }

    fileprivate func checkTravelingAlertDebounced() {
        guard let debounceTime = self.debounceTime else { return }

        let time = -debounceTime.timeIntervalSinceNow

        if time > DEBOUNCE_TIME_ALERT_SECONDS {
            let userInfo: [AnyHashable: Any] = [
                "debounceType": self.debounceType as Any,
                "debounceTime": DEBOUNCE_TIME_CREATE_AUTO_ENTRIES - time as Any,
            ]

            NotificationManager.shared.location_manager_debouncing.post(userInfo)
        }
    }

    fileprivate func getCircleOfCoordinates(_ accuracy: Double) -> [CLLocationCoordinate2D] {
        let center = currentLocation!.coordinate
        let maxRadius = accuracy / metersPerLon(center)

        let cirlceSteps = 6
        let radiusSteps = 3
        let circleStep = 2 * 3.415 / Double(cirlceSteps)
        let radiusStep = maxRadius / Double(radiusSteps)

        var array = [CLLocationCoordinate2D]()

        var i: Int = 0
        var j: Int = 0
        var x, y, theta, radius: Double

        while j < radiusSteps {
            radius = Double(j + 1) * radiusStep

            while i < cirlceSteps {
                theta = circleStep * Double(i)
                x = center.longitude + radius * cos(theta)
                y = center.latitude + radius * sin(theta)

                array.append(CLLocationCoordinate2D(latitude: y, longitude: x))
                i += 1
            }

            i = 0
            j += 1
        }

        return array
    }
    
    let LOCATION_ACCURACY_BUFFER_SIZE: Int = 10
    let LOCATION_ACCURACY_INTEGRAL_VALUE: Double = 0.5
    let LOCATION_ACCURACY_PARTIAL_VALUE: Double = 0.5
    let LOCATION_ACCURACY_COMPARE_SIZE: Double = 5.0

    var accuracies = [Double]()
    var filteredAccuracy: Double? {
        guard accuracies.count > 2 else { return nil }

        if accuracies.count > LOCATION_ACCURACY_BUFFER_SIZE { accuracies.remove(at: 0) }

        var total: Double = 0.0
        for accuracy in accuracies { total = total + accuracy }

        return total / Double(accuracies.count)
    }

    func insideLocation(_ location: Location) -> Bool? {
        
        guard let current = currentLocation else {
            return nil
        }

        let thresholdMode = location.boundaryType

        var compositeAccuracy: Double = current.getAccuracy()
        
        if let filteredAccuracy = self.filteredAccuracy {
            compositeAccuracy = (LOCATION_ACCURACY_INTEGRAL_VALUE * filteredAccuracy) + (LOCATION_ACCURACY_PARTIAL_VALUE * compositeAccuracy)
        }

        let points: [CLLocationCoordinate2D] = getCircleOfCoordinates(max(compositeAccuracy, current.getAccuracy() * (1 + (DeviceSettings.shared.accuracyBoost * 0.01))))

        if thresholdMode == "Polygon" {
            let coordinates = location.boundaryCoordinates
            
            let boundary = MKPolygon(coordinates: coordinates, count: coordinates.count)
            var intersected: Bool = false
            for point in points {
                let point = MKMapPointForCoordinate(point)
                let mapSize = MKMapSize(width: LOCATION_ACCURACY_COMPARE_SIZE, height: LOCATION_ACCURACY_COMPARE_SIZE)
                let mapRect = MKMapRect(origin: point, size: mapSize)

                if boundary.intersects(mapRect) {
                    intersected = true
                    break
                }
            }

            return intersected
        } else {
            let radius = Double(location.radius!)! * (1 + (DeviceSettings.shared.accuracyBoost * 0.01))

            guard let latitude = location.lat, let longitude = location.lon else {
                return false
            }

            let coordinate = CLLocation(latitude: latitude, longitude: longitude)

            var intersected: Bool = false
            for point in points {
                let distance = coordinate.distance(from: CLLocation(latitude: point.latitude, longitude: point.longitude))

                if distance <= radius {
                    intersected = true
                    break
                }
            }

            return intersected
        }
    }

    internal func createNewEntry(_ location: Location?) {
        guard isCreatingNewEntry == false, System.shared.state != .LoggedIn, let location = location else {
            resetDebounce()
            return
        }

        updateHold(true)
        isCreatingNewEntry = true

        let userInfo: [AnyHashable: Any] = [
            "location": location,
            "start": self.debounceTime ?? Date(),
            "auto": true,
        ]

        NotificationManager.shared.create_entry.post(userInfo)
        resetDebounce()
    }

    internal func createTravelingEntry() {
        guard isCreatingTravelingEntry == false, System.shared.state != .Traveling else {
            resetDebounce()
            return
        }
        
        if DeviceUser.shared.schedule?.state == ScheduleState.End {
            let userInfo: [AnyHashable: Any] = ["end": Date() as Any]
            
            NotificationManager.shared.submit_timesheet.post(userInfo)
        } else {

            updateHold(true)
            isCreatingTravelingEntry = true

            let userInfo: [AnyHashable: Any] = [
                "start": self.debounceTime ?? Date(),
                "auto": true,
            ]

            NotificationManager.shared.create_traveling_entry.post(userInfo)
        }
        
        resetDebounce()
    }

    func updateGPSSensitivity() {
        if App.shared.isLoaded == false || DeviceSettings.shared.autoMode == false || System.shared.state == .Off || System.shared.state == .Break {
            isTrackingLocation = false
        } else if getDebounceTime() != nil || DeviceSettings.shared.breadcrumbMode == true {
            setSensitivityHigh()
        } else if System.shared.state == .Empty || System.shared.state == .Traveling {
            if !ActivityManager.shared.available {
                setSensitivityHigh()
            } // else let Activity Monitor Handle It
        } else if System.shared.state == .LoggedIn {
            if stateHold == true {
               setSensitivityLow()
            } else if let location = DeviceUser.shared.sheet?.location, insideLocation(location) == true {
                setSensitivityLow()
            } else {
                setSensitivityHigh()
            }
        } else {
            isTrackingLocation = false
        }
    }

    /* Conditions for when should transmit breaedcrumb to server */
    fileprivate var shouldUpdateAPIWithLocation: Bool {
        guard System.shared.state != .Off, System.shared.state != .Empty, System.shared.state != .Break else {
            return false
        }

        if DeviceSettings.shared.breadcrumbMode == true {
            return true
        }
        
        if System.shared.state == .Traveling {
            if ActivityManager.shared.available {
                return ActivityManager.shared.recentlyDriving
            } else {
                return true
            }
        } else {
            return false
        }
    }

    func isInKnownLocation() -> Location? {
        
        guard let currentLocation = currentLocation, let location = Locations.shared.closest(currentLocation), self.insideLocation(location) == true else { return nil }

        return location
    }
    
    func isInKnownLocation(_ callback: @escaping(Location?) -> ()) {
        fetchLocation { (location) in
            
            self.currentLocation = location
            
            guard let location = location, let closest = Locations.shared.closest(location), self.insideLocation(closest) == true else {
                callback(nil)
                return
            }
            
            callback(closest)
            return
        }
    }

    func resetBreadcrumbLocation() {
        latestBreadcrumbLocation = nil
    }
    
    
    var authorizationChecked: Bool = false
    func checkAuthorizationStatus(_ view: UIViewController) {
        
        guard authorizationChecked == false else {
            return
        }
        
        authorizationChecked = true
        if !available {
            DispatchQueue.main.async(execute: {
                let alert = UIAlertController(title: "Configuration Error!", message: "Location services are currently restricted and Timeline can't function correctly. Please enable Location Services for Timeline functionality.", preferredStyle: UIAlertControllerStyle.alert)
                alert.addAction(UIAlertAction(title: "Go to Settings", style: UIAlertActionStyle.default, handler: { (_: UIAlertAction!) in
                    UIApplication.shared.open(NSURL(string: UIApplicationOpenSettingsURLString)! as URL, options: EMPTY_JSON, completionHandler: nil)
                }))
                alert.addAction(UIAlertAction(title: "Continue", style: UIAlertActionStyle.cancel, handler: nil))
                view.present(alert, animated: true, completion: nil)
            })
        }
    }
}

extension CLLocation {
    func getAccuracy() -> Double {
        let accuracy = sqrt(pow(horizontalAccuracy, 2.0) + pow(verticalAccuracy, 2.0))
        
        return accuracy
    }
}
