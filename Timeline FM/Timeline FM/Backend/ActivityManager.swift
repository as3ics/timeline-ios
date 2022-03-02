//
//  ActivityManager.swift
//  Timeline FM
//
//  Created by Zachary DeGeorge on 9/28/18.
//  Copyright © 2018 Next Day Project. All rights reserved.
//

import Foundation
import CoreMotion

let MAX_DURATION_RECENTLY_DRIVING_SECS: TimeInterval = 45.0

class ActivityManager {
    
    static let shared: ActivityManager = ActivityManager()
    
    let manager = CMMotionActivityManager()
    let motion = CMMotionManager()
    
    var activity: CMMotionActivity? {
        didSet {
            if activity?.automotive == true {
                drivingTimestamp = activity?.startDate
            }
        }
    }
    
    var drivingTimestamp: Date?
    var recentlyDriving: Bool {
        
        guard let timestamp = drivingTimestamp else {
            return false
        }
        
        let time = timestamp.timeSince()
        return time < MAX_DURATION_RECENTLY_DRIVING_SECS
    }
    
    var available: Bool {
        
        guard !Device.iPhoneX, let activity = self.activity else {
            return false
        }
        
        let time = activity.startDate.timeSince()
        if time < MAX_DURATION_RECENTLY_DRIVING_SECS {
            return true
        } else {
            return false
        }
        
        // let value = CMMotionActivityManager.isActivityAvailable() && (CMMotionActivityManager.authorizationStatus() == .authorized
    }
    
    func initialize() {
        
        if Device.iPhoneX {
            manager.stopActivityUpdates()
            manager.startActivityUpdates(to: OperationQueue.main) { (activity) in
                self.activity = activity
                self.process()
            }
        }
        
        NotificationManager.shared.new_current_location.observe(self, selector: #selector(rawLocationUpdated))
    }
    
    
    @objc func rawLocationUpdated(_: NSNotification) {
        
        if let location = LocationManager.shared.currentLocation {
            if location.speed > MIN_LOCATION_DELTA_SPEED * CONVERSION_MPH_TO_MPS_MULTIPLIER {
                self.drivingTimestamp = location.timestamp
                LocationManager.shared.setSensitivityHigh()
            }
        }
    }
    
    
    func process() {
        if System.shared.state == .LoggedIn || System.shared.state == .Empty || System.shared.state == .Traveling {
            
            guard let location = LocationManager.shared.currentLocation, location.timestamp.timeSince() < MAX_DURATION_RECENTLY_DRIVING_SECS else {
                LocationManager.shared.setSensitivityHigh()
                return
            }
            
            if location.speed > MIN_LOCATION_DELTA_SPEED * CONVERSION_MPH_TO_MPS_MULTIPLIER {
                self.drivingTimestamp = location.timestamp
            }
            
            if self.recentlyDriving {
                LocationManager.shared.setSensitivityHigh()
            } else {
                LocationManager.shared.setSensitivityLow()
            }
        }
    }
}
