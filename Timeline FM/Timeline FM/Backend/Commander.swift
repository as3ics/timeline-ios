//
//  Commander.swift
//  Timeline SDK
//
//  Created by Zachary DeGeorge on 6/25/18.
//  Copyright © 2018 Timeline Software LLC. All rights reserved.
//

import Foundation
import PKHUD

class Commander {
    
    static let shared = Commander()

    var commands = [ShortcutIdentifier]()

    init() {
        NotificationManager.shared.create_entry.observe(self, selector: #selector(createEntry))
        NotificationManager.shared.create_break_entry.observe(self, selector: #selector(createBreakEntry))
        NotificationManager.shared.create_timesheet.observe(self, selector: #selector(createSheet))
        NotificationManager.shared.come_off_break.observe(self, selector: #selector(comeOffBreak))
        NotificationManager.shared.submit_timesheet.observe(self, selector: #selector(submitTimesheet))
        NotificationManager.shared.create_traveling_entry.observe(self, selector: #selector(createTravelingEntry))
    }

    func initialize() {
        APIClient.shared.authToken = Auth.shared.authToken

        ActivityManager.shared.initialize()
        ModelUpdater.shared.initialize()
        Navigator.shared.initialize()
        LocationManager.shared.initialize()
        BackgroundManager.shared.initialize()
        Socket.shared.initialize()
        Stream.shared.initialize()
    }
    
    func slimInit() {
        APIClient.shared.authToken = Auth.shared.authToken
        
        ModelUpdater.shared.initialize()
    }

    func addCommand(_ command: ShortcutIdentifier) {
        commands.insert(command, at: 0)
    }

    func process() {
        
        guard App.shared.isLoaded == true, commands.count > 0 else {
            return
        }
        
        if let command = Commander.shared.commands.popLast() {
            
            switch command {
            case ShortcutIdentifier.AddEntry:
                NotificationManager.shared.create_entry.post()
                break
            case ShortcutIdentifier.Break:
                NotificationManager.shared.create_break_entry.post()
                break
            case ShortcutIdentifier.CreateTimeSheet:
                NotificationManager.shared.create_timesheet.post()
                break
            case ShortcutIdentifier.EndBreak:
                NotificationManager.shared.come_off_break.post()
                break
            case ShortcutIdentifier.SubmitTimeSheet:
                NotificationManager.shared.submit_timesheet.post()
                break
            case ShortcutIdentifier.Travel:
                NotificationManager.shared.create_traveling_entry.post()
                break
            default:
                break
            }
        }
    }

    @objc func comeOffBreak(_: NSNotification) {
        var alert: UIAlertController?
        
        PKHUD.loading()
        
        LocationManager.shared.isInKnownLocation({ (location) in
            
            PKHUD.hide()
            
            if let location = location {
                alert = UIAlertController(title: "Timeline", message: "You are coming off a break and are in the viscinity of a known location. Would you like to clock into \(location.name!)?", preferredStyle: .actionSheet)
                
                alert!.addAction(UIAlertAction(title: "Clock In", style: .default) { _ in
                    Generator.bump()
                    NotificationManager.shared.come_off_break.post()
                })
                
                alert!.addAction(UIAlertAction(title: "Traveling Mode", style: .default) { _ in
                    Generator.bump()
                    NotificationManager.shared.create_traveling_entry.post()
                })
                
                alert!.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel) { _ in
                    // Do nothing
                    Generator.bump()
                })
            } else {
                alert = UIAlertController(title: "Timeline", message: "You are coming off break and are not in the viscinity of a known location. Enter Traveling Mode?", preferredStyle: .actionSheet)
                
                alert!.addAction(UIAlertAction(title: "Traveling Mode", style: .default) { _ in
                    Generator.bump()
                    NotificationManager.shared.create_traveling_entry.post()
                })
                
                alert!.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel) { _ in
                    // Do nothing
                    Generator.bump()
                })
            }
            
            UIApplication.shared.keyWindow?.rootViewController?.present(alert!, animated: true)
        })
    }

    @objc func createTravelingEntry(_ notification: NSNotification) {
        guard let sheet = DeviceUser.shared.sheet, let activity = Activities.shared.travelingActivity else {
            return
        }

        let previous = LocationManager.shared.getStateHoldValue()
        LocationManager.shared.holdState(true)

        let auto = notification.userInfo?["auto"] as? Bool ?? false
        let start = notification.userInfo?["start"] as? Date ?? Date()

        let shouldShowPKUD = !auto
        let shouldShowAlert = auto

        let entry = Entry()
        entry.activity = activity
        entry.sheet = sheet
        entry.start = start
        entry.autoGenerated = auto
        entry.user = DeviceUser.shared.user
        entry.paidTime = true
        
        DispatchQueue.main.async {
            
            if shouldShowPKUD == true { PKHUD.loading() }
            
            Async.waterfall(nil, [entry.create]) { error, _ in
                
                LocationManager.shared.resetDebounce()
                LocationManager.shared.holdState(previous)
                LocationManager.shared.postLocationToAPI(true)
                
                guard error == nil else {
                    if shouldShowPKUD == true { PKHUD.failure() }
                    return
                }
                
                if shouldShowPKUD == true { PKHUD.success() }
                
                if shouldShowAlert == true { NotificationManager.shared.alertAutoTravelEntryMade() }
            }
        }
    }

    @objc func createEntry(_ notification: NSNotification) {
        guard let sheet = DeviceUser.shared.sheet, let location = notification.userInfo?["location"] as? Location ?? Locations.shared.closest(LocationManager.shared.currentLocation), let activity = notification.userInfo?["activity"] as? Activity ?? Activities.shared.defaultActivity else {
            return
        }

        let auto = notification.userInfo?["auto"] as? Bool ?? false
        let start = notification.userInfo?["start"] as? Date ?? Date()

        let shouldShowPKUD = !auto
        let shouldShowAlert = auto

        let entry = Entry()
        entry.activity = activity
        entry.location = location
        entry.start = start
        entry.autoGenerated = auto
        entry.user = DeviceUser.shared.user
        entry.sheet = sheet
        entry.paidTime = true
        entry.userEdited = false
        
        DispatchQueue.main.async {
            
            if shouldShowPKUD == true { PKHUD.loading() }
            
            Async.waterfall(nil, [entry.create]) { error, _ in
                
                LocationManager.shared.resetDebounce()
                LocationManager.shared.updateHold(false)
                
                guard error == nil else {
                    if shouldShowPKUD == true { PKHUD.failure() }
                    return
                }
                
                if shouldShowPKUD == true { PKHUD.success() }
                
                if shouldShowAlert == true { NotificationManager.shared.alertAutoEntryMade() }
            }
        }
    }

    @objc func createBreakEntry(_ notification: NSNotification) {
        guard System.shared.state != .Break, let activity = Activities.shared.breakActivity else {
            return
        }

        let start = notification.userInfo?["start"] as? Date ?? Date()

        let entry = Entry()
        entry.activity = activity
        entry.paidTime = false
        entry.autoGenerated = false
        entry.start = start
        entry.user = DeviceUser.shared.user
        entry.sheet = DeviceUser.shared.sheet

        DispatchQueue.main.async {
            PKHUD.loading()
            
            Async.waterfall(nil, [entry.create]) { error, _ in
                
                LocationManager.shared.resetDebounce()
                LocationManager.shared.updateHold(false)
                
                guard error == nil else {
                    PKHUD.failure()
                    return
                }
                
                PKHUD.success()
            }
        }
    }

    @objc func submitTimesheet(_ notification: NSNotification) {
        guard let sheet = DeviceUser.shared.sheet else {
            return
        }

        sheet.submissionDate = notification.userInfo?["end"] as? Date ?? Date()

        DispatchQueue.main.async {
            
            Async.waterfall(nil, [sheet.submit]) { error, _ in
                
                LocationManager.shared.resetDebounce()
                LocationManager.shared.updateHold(false)
                
                guard error == nil else {
                    PKHUD.failure()
                    return
                }
                
                LocationManager.shared.isTrackingLocation = false
            }
        }
    }

    @objc func createSheet(_: NSNotification) {

        DispatchQueue.main.async {
            PKHUD.loading()
            
            Async.waterfall(nil, [Sheet().create]) { error, _ in
                guard error == nil else {
                    PKHUD.failure()
                    return
                }
                
                PKHUD.success()
                LocationManager.shared.isTrackingLocation = true
            }
        }
    }
    
    func quickLoad(_ callback: @escaping (_ success: Bool) -> Void) {
        guard let user = DeviceUser.shared.user else {
            callback(false)
            return
        }
        
        Async.waterfall(nil, [user.retrieveTimesheet], end: { error, _ in
            guard error == nil else {
                callback(false)
                return
            }
            
            guard let sheet = user.sheet else {
                DeviceUser.shared.sheet = nil
                let update = ModelUpdate(type: ModelType.Sheet, action: ModelAction.Update, model: nil, parent: nil)
                Notifications.shared.model_update.post(["update": update])
                callback(true)
                return
            }
            
            DeviceUser.shared.sheet = sheet
            Async.waterfall(nil, [DeviceUser.shared.sheet!.entries.retrieve], end: { error, _ in
                guard error == nil else {
                    callback(false)
                    return
                }
                
                callback(true)
            })
        })
    }

    func load(_ callback: @escaping (_ success: Bool) -> Void) {
        Async.waterfall(nil, [self.retrieveDeviceUser, self.retrieveDeviceUserStatistics]) { error, _ in
            guard error == nil else {
                Auth.shared.flush()
                callback(false)
                return
            }

            Async.waterfall(nil, [self.retrieveUsers, self.retrieveUsersPhotos, self.retrieveLocations, self.retrieveActivities, self.retrieveChatrooms, Stream.shared.retrieve], end: { error, _ in
                guard error == nil else {
                    callback(false)
                    return
                }

                // Update the message counts
                Notifications.shared.updateBadge()
                
                guard let user = DeviceUser.shared.user else {
                    Notifications.shared.systemMessage("Error Initializing")
                    callback(false)
                    return
                }

                Notifications.shared.systemMessage("Retrieving Timesheet")
                Async.waterfall(nil, [user.retrieveTimesheet], end: { error, _ in
                    guard error == nil else {
                        Notifications.shared.systemMessage("Error Retrieving for Timesheet")
                        callback(false)
                        return
                    }
                    
                    
                    guard let sheet = user.sheet else {
                        DeviceUser.shared.sheet = nil
                        Notifications.shared.systemMessage("No Active Timesheet")
                        let update = ModelUpdate(type: ModelType.Sheet, action: ModelAction.Update, model: nil, parent: nil)
                        Notifications.shared.model_update.post(["update": update])
                        callback(true)
                        return
                    }
                    
                    DeviceUser.shared.sheet = sheet
                    
                    Async.waterfall(nil, [DeviceUser.shared.sheet!.entries.retrieve], end: { error, _ in
                        guard error == nil else {
                            Notifications.shared.systemMessage("Error Loading Timesheet")
                            callback(false)
                            return
                        }
                        
                        Notifications.shared.systemMessage("Timesheet Loaded")
                        callback(true)
                    })
                })
            })
        }
    }

    func retrieveUsers(_ callback: @escaping (_ err: Error?, _ newResult: Any?) -> Void, _ initialValue: Any?) {
        
        var inputDate: String? = nil
        if let date = DeviceSettings.shared.timestamp {
            inputDate = APIClient.shared.formatter.string(from: date)
        }
        
        Async.waterfall(inputDate, [Users.shared.synchronize, Users.shared.prune]) { error, _ in
            guard error == nil else {
                Notifications.shared.systemMessage("Error Retrieving Users")
                callback(SystemErrors.APIError, initialValue)
                return
            }
            
            callback(nil, initialValue)
        }
    }
    
    func retrieveUsersPhotos(_ callback: @escaping (_ err: Error?, _ newResult: Any?) -> Void, _ initialValue: Any?) {
        
        var queries = [(@escaping (Error?, Any?) -> (), Any?) -> ()]()
        
        for user in Users.shared.items {
            queries.append(user.retrievePhotos)
        }
        
        Notifications.shared.systemMessage("Synchronizing Photos")
        Async.waterfall(nil, queries) { error, _ in
            guard error == nil else {
                Notifications.shared.systemMessage("Error Synchronizing Photos")
                callback(nil, initialValue)
                return
            }
            
            Notifications.shared.systemMessage("Photos Synchronized")
            callback(nil, initialValue)
        }
        
    }

    func retrieveChatrooms(_ callback: @escaping (_ err: Error?, _ newResult: Any?) -> Void, _ initialValue: Any?) {
        Notifications.shared.systemMessage("Retrieving Chatrooms")

        Async.waterfall(nil, [Chatrooms.shared.retrieve]) { error, _ in
            guard error == nil else {
                Notifications.shared.systemMessage("Error Retrieving Chatrooms")
                callback(SystemErrors.APIError, initialValue)
                return
            }
            
            Notifications.shared.systemMessage("Chatrooms Retrieved")
            callback(nil, initialValue)
        }
    }

    func retrieveLocations(_ callback: @escaping (_ err: Error?, _ newResult: Any?) -> Void, _ initialValue: Any?) {
        
        var inputDate: String? = nil
        if let date = DeviceSettings.shared.timestamp {
            inputDate = APIClient.shared.formatter.string(from: date)
        }
        
        Async.waterfall(inputDate, [Locations.shared.synchronize, Locations.shared.prune]) { error, _ in
            guard error == nil else {
                Notifications.shared.systemMessage("Error Retrieving Locations")
                callback(SystemErrors.APIError, initialValue)
                return
            }
            
            if let location = LocationManager.shared.currentLocation {
                Locations.shared.sort(location: location)
            }
            
            var queries = [(@escaping (Error?, Any?) -> (), Any?) -> ()]()
            
            for location in Locations.shared.items {
                queries.append(location.retrievePhotos)
            }
            
            Async.waterfall(nil, queries) { error, _ in
                // foo
            }
            
            callback(nil, initialValue)
        }
    }

    func retrieveActivities(_ callback: @escaping (_ err: Error?, _ newResult: Any?) -> Void, _ initialValue: Any?) {
        
        var inputDate: String? = nil
        if let date = DeviceSettings.shared.timestamp {
            inputDate = APIClient.shared.formatter.string(from: date)
        }
        
        Async.waterfall(inputDate, [Activities.shared.synchronize, Activities.shared.prune]) { error, _ in
            guard error == nil else {
                Notifications.shared.systemMessage("Error Retrieving Activities")
                callback(SystemErrors.AuthError, initialValue)
                return
            }

            callback(nil, initialValue)
        }
    }

    func retrieveSchedule(_ callback: @escaping (_ err: Error?, _ newResult: Any?) -> Void, _ initialValue: Any?) {
        Async.waterfall(nil, [Schedule().retrieve]) { _, response in
            guard let data = response as? JSON, let schedule = data["model"] as? Schedule else {
                Notifications.shared.systemMessage("Error Retrieving Schedule")
                callback(nil, initialValue)
                return
            }
            DeviceUser.shared.schedule = schedule

            callback(nil, initialValue)
        }
    }

    func retrieveOverrides(_ callback: @escaping (_ err: Error?, _ newResult: Any?) -> Void, _ initialValue: Any?) {
        Async.waterfall(nil, [Overrides.shared.retrieve]) { error, _ in
            guard error == nil else {
                Notifications.shared.systemMessage("Error Retrieving Overrides")
                callback(nil, initialValue)
                return
            }

            callback(nil, initialValue)
        }
    }

    func retrieveDeviceUser(_ callback: @escaping (_ err: Error?, _ newResult: Any?) -> Void, _ initialValue: Any?) {
        guard let id = Auth.shared.id else {
            Notifications.shared.systemMessage("User Needs Authentication")
            callback(SystemErrors.AuthError, initialValue)
            return
        }

        let _user = User()
        _user.id = id

        Async.waterfall(nil, [_user.retrieve]) { error, response in
            guard error == nil, let data = response as? JSON, let user = data["model"] as? User else {
                Notifications.shared.systemMessage("Error Retrieving Device User")
                callback(SystemErrors.APIError, initialValue)
                return
            }

            var queries = [(@escaping (Error?, Any?) -> (), Any?) -> ()]()
            
            DeviceUser.shared.user = user
            queries.append(user.retrievePhotos)
            
            if let token = Auth.shared.deviceToken, user.deviceToken == nil || user.deviceToken != token {
                user.deviceToken = token
                queries.append(user.update)
            }
        
            Async.waterfall(APIClient.shared.downloadSession, queries, end: {_, _ in
                callback(nil, initialValue)
            })
        }
    }

    func retrieveDeviceUserStatistics(_ callback: @escaping (_ err: Error?, _ newResult: Any?) -> Void, _ initialValue: Any?) {
        guard let user = DeviceUser.shared.user else {
            callback(SystemErrors.PretenseError, initialValue)
            return
        }
        
        Notifications.shared.updateUserDeviceToken()
        
        var queries = [(@escaping (Error?, Any?) -> (), Any?) -> ()]()
        
        queries.append(user.retrieveStatistics)

        Async.waterfall(nil, queries) { error, _ in
            guard error == nil else {
                callback(SystemErrors.APIError, initialValue)
                return
            }

            callback(nil, initialValue)
        }
    }
}
