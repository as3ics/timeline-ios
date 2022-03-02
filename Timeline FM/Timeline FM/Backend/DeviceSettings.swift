//
//  DeviceSettings.swift
//  Timeline SDK
//
//  Created by Zachary DeGeorge on 6/24/18.
//  Copyright © 2018 Timeline Software LLC. All rights reserved.
//

import Foundation
import KeychainAccess
import MapKit
import CoreLocation

enum MapProgram: String {
    case apple = "Apple Maps"
    case google = "Google Maps"
}

enum BooleanSetting: String {
    case on = "on"
    case off = "off"
}

class DeviceSettings: KeychainAccessProtocol {
    
    static let shared = DeviceSettings()
    
    var timestamp: Date? {
        get {
            guard let value = self.getFromKeychain("timestamp") else {
                return nil
            }
            
            return APIClient.shared.formatter.date(from: value)
        }
        set {
            guard let value = newValue else {
                storeInKeychain("timestamp", value: nil)
                return
            }
            
            storeInKeychain("timestamp", value: APIClient.shared.formatter.string(from: value))
        }
        
    }
    
    var accuracyBoost: Double {
        get {
            guard let value = self.getFromKeychain("accuracyBoost") else {
                return 0.0
            }

            return Double(value)!
        }
        set {
            storeInKeychain("accuracyBoost", value: String(format: "%0.8f", arguments: [newValue]))
        }
    }

    var autoMode: Bool {
        get {
            let value: String? = getFromKeychain("autoMode")
            if value == nil {
                let defaultValue = BooleanSetting.on.rawValue
                storeInKeychain("autoMode", value: defaultValue)
                return true
            }
            
            let returnValue = value == BooleanSetting.on.rawValue ? true : false
            return returnValue
        }
        set {
            storeInKeychain("autoMode", value: newValue == true ? BooleanSetting.on.rawValue : BooleanSetting.off.rawValue)
        }
    }

    var mapType: MKMapType {
        get {
            var value: String? = getFromKeychain("mapType")
            if value == nil {
                value = "\(MKMapType.standard.rawValue)"
                storeInKeychain("mapType", value: value)
                return MKMapType(rawValue: UInt(value!)!)!
            }
            return MKMapType(rawValue: UInt(value!)!)!
        }
        set {
            let value = "\(newValue.rawValue)"
            storeInKeychain("mapType", value: value)
        }
    }

    var breadcrumbMode: Bool {
        get {
            let value: String? = getFromKeychain("breadcrumbMode")
            if value == nil {
                let defaultValue = BooleanSetting.off.rawValue
                storeInKeychain("breadcrumbMode", value: defaultValue)
                return false
            }
            
            let returnValue = value == BooleanSetting.on.rawValue ? true : false
            return returnValue
        }
        set {
            storeInKeychain("breadcrumbMode", value: newValue == true ? BooleanSetting.on.rawValue : BooleanSetting.off.rawValue)
        }
    }
    
    var userAnnotationMode: Bool {
        get {
            let value: String? = getFromKeychain("userAnnotationMode")
            if value == nil {
                let defaultValue = BooleanSetting.off.rawValue
                storeInKeychain("userAnnotationMode", value: defaultValue)
                return false
            }
            
            let returnValue = value == BooleanSetting.on.rawValue ? true : false
            return returnValue
        }
        set {
            storeInKeychain("userAnnotationMode", value: newValue == true ? BooleanSetting.on.rawValue : BooleanSetting.off.rawValue)
        }
    }
    
    var mapTrafficEnabled: Bool {
        get {
            let value: String? = getFromKeychain("mapTrafficEnabled")
            if value == nil {
                let defaultValue = BooleanSetting.on.rawValue
                storeInKeychain("mapTrafficEnabled", value: defaultValue)
                return true
            }
            
            let returnValue = value == BooleanSetting.on.rawValue ? true : false
            return returnValue
        }
        set {
            storeInKeychain("mapTrafficEnabled", value: newValue == true ? BooleanSetting.on.rawValue : BooleanSetting.off.rawValue)
        }
    }
    
    var mapAnnotations: Bool {
        get {
            let value: String? = getFromKeychain("mapAnnotations")
            if value == nil {
                let defaultValue = BooleanSetting.on.rawValue
                storeInKeychain("mapAnnotations", value: defaultValue)
                return true
            }
            
            let returnValue = value == BooleanSetting.on.rawValue ? true : false
            return returnValue
        }
        set {
            storeInKeychain("mapAnnotations", value: newValue == true ? BooleanSetting.on.rawValue : BooleanSetting.off.rawValue)
        }
    }

    /* Disabled */
    var developerMode: Bool {
        get {
            return false
            
            /*
            let value: String? = getFromKeychain("developerMode")
            if value == nil {
                let defaultValue = BooleanSetting.off.rawValue
                storeInKeychain("developerMode", value: defaultValue)
                return false
            }
            
            let returnValue = value == BooleanSetting.on.rawValue ? true : false
            return returnValue
            */
        }
        set {
            storeInKeychain("developerMode", value: newValue == true ? BooleanSetting.on.rawValue : BooleanSetting.off.rawValue)
        }
    }

    var schedulingMode: Bool {
        get {
            let value: String? = getFromKeychain("schedulingMode")
            if value == nil {
                let defaultValue = BooleanSetting.off.rawValue
                storeInKeychain("schedulingMode", value: defaultValue)
                return false
            }
            
            let returnValue = value == BooleanSetting.on.rawValue ? true : false
            return returnValue
        }
        set {
            storeInKeychain("schedulingMode", value: newValue == true ? BooleanSetting.on.rawValue : BooleanSetting.off.rawValue)
        }
    }

    /* Disabled */
    var nightMode: Bool {
        get {
            return false
            
            /*
            let value: String? = getFromKeychain("nightMode")
            if value == nil {
                let defaultValue = BooleanSetting.off.rawValue
                storeInKeychain("nightMode", value: defaultValue)
                return false
            }
            
            let returnValue = value == BooleanSetting.on.rawValue ? true : false
            return returnValue
            */
        }
        set {
            storeInKeychain("nightMode", value: newValue == true ? BooleanSetting.on.rawValue : BooleanSetting.off.rawValue)
        }
    }

    /* Values:
     "on" - Schedling Active Mode
     "off" - Scheduling Passive Mode
     */
    var schedulingAwaitLocation: Bool {
        get {
            let value: String? = getFromKeychain("schedulingAwaitLocation")
            if value == nil {
                let defaultValue = BooleanSetting.off.rawValue
                storeInKeychain("schedulingAwaitLocation", value: defaultValue)
                return false
            }
            
            let returnValue = value == BooleanSetting.on.rawValue ? true : false
            return returnValue
        }
        set {
            storeInKeychain("schedulingAwaitLocation", value: newValue == true ? BooleanSetting.on.rawValue : BooleanSetting.off.rawValue)
        }
    }
    
    var onboarded: Bool {
        get {
            let value: String? = getFromKeychain("onboarded")
            if value == nil {
                let defaultValue = BooleanSetting.off.rawValue
                storeInKeychain("onboarded", value: defaultValue)
                return false
            }
            
            let returnValue = value == BooleanSetting.on.rawValue ? true : false
            return returnValue
        }
        set {
            storeInKeychain("onboarded", value: newValue == true ? BooleanSetting.on.rawValue : BooleanSetting.off.rawValue)
        }
    }
    
    var authenticate: Bool {
        get {
            let value: String? = getFromKeychain("authenticate")
            if value == nil {
                let defaultValue = BooleanSetting.on.rawValue
                storeInKeychain("authenticate", value: defaultValue)
                return true
            }
            
            let returnValue = value == BooleanSetting.on.rawValue ? true : false
            return returnValue
        }
        set {
            storeInKeychain("authenticate", value: newValue == true ? BooleanSetting.on.rawValue : BooleanSetting.off.rawValue)
        }
    }
    
    var mapProgram: MapProgram {
        get {
            let value: String? = getFromKeychain("mapProgram")
            if value == nil {
                let defaultValue = MapProgram.apple
                storeInKeychain("mapProgram", value: defaultValue.rawValue)
                return defaultValue
            }
            
            return MapProgram(rawValue: value!)!
        } set {
            storeInKeychain("mapProgram", value: newValue.rawValue)
        }
    }
    
    /* Get/Set Alerts for chatroom */

    func getChatAlertSetting(_ id: String) -> Bool {
        let value = getFromKeychain("chat-alert" + id)
        if value == "hide" {
            return true
        } else {
            return false
        }
    }

    func setChatAlertSetting(_ id: String, value: Bool) {
        if value == true {
            storeInKeychain("chat-alert" + id, value: "hide")
        } else {
            storeInKeychain("chat-alert" + id, value: "show")
        }
    }
    
    /* Get/Set User Favorited Settings */

    func getUserFavoritedSetting(_ id: String) -> Bool {
        let value = getFromKeychain("user-favorite" + id)
        if value == "true" {
            return true
        } else {
            return false
        }
    }

    func setUserFavoritedSetting(_ id: String, value: Bool) {
        if value == true {
            storeInKeychain("user-favorite" + id, value: "true")
        } else {
            storeInKeychain("user-favorite" + id, value: "false")
        }
    }
    
    /* Get/Set User Alerts Sheet */
    
    func getUserSheetAlerts(_ id: String) -> Bool {
        let value = getFromKeychain("user-sheet-alert-" + id)
        if value == "true" {
            return true
        } else {
            return false
        }
    }
    
    func setUserSheetAlerts(_ id: String, value: Bool) {
        if value == true {
            storeInKeychain("user-sheet-alert-" + id, value: "true")
        } else {
            storeInKeychain("user-sheet-alert-" + id, value: "false")
        }
    }
    
    /* Get/Set User Alerts Entry */
    
    func getUserEntryAlerts(_ id: String) -> Bool {
        let value = getFromKeychain("user-entry-alert-" + id)
        if value == "true" {
            return true
        } else {
            return false
        }
    }
    
    func setUserEntryAlerts(_ id: String, value: Bool) {
        if value == true {
            storeInKeychain("user-entry-alert-" + id, value: "true")
        } else {
            storeInKeychain("user-entry-alert-" + id, value: "false")
        }
    }
    
    /* Get/Set User Alerts Photo  */
    
    func getUserPhotoAlerts(_ id: String) -> Bool {
        let value = getFromKeychain("user-photo-alert-" + id)
        if value == "true" {
            return true
        } else {
            return false
        }
    }
    
    func setUserPhotoAlerts(_ id: String, value: Bool) {
        if value == true {
            storeInKeychain("user-photo-alert-" + id, value: "true")
        } else {
            storeInKeychain("user-photo-alert-" + id, value: "false")
        }
    }
    
    static func reset() {
        
        let keychain = Keychain(service: App.shared.keychainId)
        
        do {
            try keychain.removeAll()
        } catch let error {
            print("Keychain Error: \(error)")
        }
    }
}
