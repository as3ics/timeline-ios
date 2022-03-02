//
//  BackgroundManager.swift
//  Timeline SDK
//
//  Created by Zachary DeGeorge on 6/24/18.
//  Copyright © 2018 Timeline Software LLC. All rights reserved.
//

import Foundation
import UserNotifications
import SocketIO
import CoreLocation

class BackgroundManager {
    
    static let shared = BackgroundManager()

    func initialize() {

        timer_1000ms()
        widget_updater()
        command_processor()
        lock_screen()
        location_watchdog()
        // automatic_scheduling()
        
        startAllBackgroundTasks()
    }

    @objc func stopAllBackgroundTasks() {
        for task in Daemon.shared.tasks {
            Daemon.shared.stopTask(name: task.name)
        }
    }

    @objc func startAllBackgroundTasks() {
        for task in Daemon.shared.tasks {
            Daemon.shared.startTask(name: task.name)
        }
        
        Daemon.shared.fire()
    }

    func timer_1000ms() {
        let task = DaemonTask()
        task.interval = 1
        task.offset = 0
        task.name = "Timer1000ms"
        task.description = "Global 1000ms timer. Triggers a notfication that can be observed in the application instead of using a local timer."

        task.executable = {
            Notifications.shared.timer_1000ms.post()
        }

        Daemon.shared.addTask(task: task)
    }
    
    func location_watchdog() {
        let task = DaemonTask()
        task.interval = 1
        task.offset = 0
        task.name = "LocationWatchdog"
        task.description = "Watchdog for location state changes"
        
        task.executable = {
            guard App.shared.isLoaded == true else {
                return
            }
            
            LocationManager.shared.updateGPSSensitivity()
            LocationManager.shared.stateMachine()
        }
        
        Daemon.shared.addTask(task: task)
        
    }
    
    
    func lock_screen() {
        let task = DaemonTask()
        task.interval = 5
        task.offset = 2
        task.name = "LockScreen"
        task.description = "Locks screen if in background."
        
        task.executable = {
            guard App.shared.isLoaded == true, let timer = AppDelegate.backgroundTimer else {
                return
            }
            
            if Date().timeIntervalSince(timer) > 15.0 {
                App.shared.lockScreen(disconnect: false)
            }
        }
        
        Daemon.shared.addTask(task: task)
    }
    
    
    func socket_watchdog() {
        let task = DaemonTask()
        task.interval = 1
        task.offset = 0
        task.name = "SocketWatchdog"
        task.description = "Make sure socket stays connected"
        
        task.executable = {
            
            guard App.shared.isLoaded == true else { return }
            
            DispatchQueue.main.async {
                if Socket.shared.socket.status != SocketIOClientStatus.connected {
                    Socket.shared.socket.reconnect()
                }
            }
        }
        
        Daemon.shared.addTask(task: task)
    }
    
    func widget_updater() {
        
        let task = DaemonTask()
        task.interval = 1
        task.offset = 0
        task.name = "WidgetUpdate"
        task.description = "Responsible for updating the user default values that are used in the external widget."
        
        task.executable = {
            let formatter = DateFormatter()
            formatter.dateFormat = "h:mm a"
            
            let footerDateFormatter = DateFormatter()
            footerDateFormatter.dateFormat = "EEEE"
            
            let footerString = String(format: "Last updated on %@ at %@", arguments:[footerDateFormatter.string(from: Date()), formatter.string(from: Date())])
            
            let systemState = System.shared.state
            
            if (systemState == SystemState.LoggedIn || systemState == SystemState.Traveling || systemState == SystemState.Break), let sheet = DeviceUser.shared.sheet, let entry = sheet.entries.latest, let startString = entry.startString, let activityName = entry.activity?.name, let entrySeconds = sheet.duration(index: 0) {
                
                let endTime = formatter.string(from: Date())
                let seconds = sheet.totalSeconds
                let meters = sheet.distance
                let entryMeters = entry.meters!
                
                let totalDurationString = String(format: "%.0fh %0.fm %.0fs", arguments:[clockHours(seconds), clockMinutes(seconds), clockSeconds(seconds)])
                let totalDistanceString = String(format: "%0.1f miles", arguments: [meters * CONVERSION_METERS_TO_MILES_MULTIPLIER])
                let entryDurationString = String(format: "%.0fh %0.fm %.0fs", arguments:[clockHours(entrySeconds), clockMinutes(entrySeconds), clockSeconds(entrySeconds)])
                let entryTimespanString = String(format:"%@ - %@", arguments: [startString, endTime])
                let activityNameString = activityName
                
                var locationNameString: String? = nil
                var locationAddressString: String? = nil
                var entryDistanceString: String? = nil
                
                if systemState == SystemState.LoggedIn, let location = entry.location, let locationName = location.name, let addressString = location.addressString  {
                    locationNameString = locationName
                    locationAddressString = addressString
                } else if systemState == SystemState.Traveling {
                    entryDistanceString = String(format: "%0.1f miles", arguments: [entryMeters * CONVERSION_METERS_TO_MILES_MULTIPLIER])
                }
                
                UserDefaults.init(suiteName: "group.com.timelinefm.iPhone")?.setValue(totalDurationString, forKey: "totalDurationString")
                UserDefaults.init(suiteName: "group.com.timelinefm.iPhone")?.setValue(totalDistanceString, forKey: "totalDistanceString")
                UserDefaults.init(suiteName: "group.com.timelinefm.iPhone")?.setValue(entryDurationString, forKey: "entryDurationString")
                UserDefaults.init(suiteName: "group.com.timelinefm.iPhone")?.setValue(entryTimespanString, forKey: "entryTimespanString")
                UserDefaults.init(suiteName: "group.com.timelinefm.iPhone")?.setValue(activityNameString, forKey: "activityNameString")
                UserDefaults.init(suiteName: "group.com.timelinefm.iPhone")?.setValue(locationNameString, forKey: "locationNameString")
                UserDefaults.init(suiteName: "group.com.timelinefm.iPhone")?.setValue(locationAddressString, forKey: "locationAddressString")
                UserDefaults.init(suiteName: "group.com.timelinefm.iPhone")?.setValue(entryDistanceString, forKey: "entryDistanceString")
                UserDefaults.init(suiteName: "group.com.timelinefm.iPhone")?.setValue(footerString, forKey: "footerText")
            } else if systemState == SystemState.Empty {
                let totalDurationString = String(format: "%.0fh %0.fm %.0fs", arguments:[clockHours(0), clockMinutes(0), clockSeconds(0)])
                let totalDistanceString = String(format: "%0.1f miles", arguments: [0 * CONVERSION_METERS_TO_MILES_MULTIPLIER])
                
                UserDefaults.init(suiteName: "group.com.timelinefm.iPhone")?.setValue(totalDurationString, forKey: "totalDurationString")
                UserDefaults.init(suiteName: "group.com.timelinefm.iPhone")?.setValue(totalDistanceString, forKey: "totalDistanceString")
                UserDefaults.init(suiteName: "group.com.timelinefm.iPhone")?.setValue(nil, forKey: "entryDurationString")
                UserDefaults.init(suiteName: "group.com.timelinefm.iPhone")?.setValue(nil, forKey: "entryTimespanString")
                UserDefaults.init(suiteName: "group.com.timelinefm.iPhone")?.setValue("No Time Entries", forKey: "activityNameString")
                UserDefaults.init(suiteName: "group.com.timelinefm.iPhone")?.setValue(nil, forKey: "locationNameString")
                UserDefaults.init(suiteName: "group.com.timelinefm.iPhone")?.setValue(nil, forKey: "locationAddressString")
                UserDefaults.init(suiteName: "group.com.timelinefm.iPhone")?.setValue(nil, forKey: "entryDistanceString")
                UserDefaults.init(suiteName: "group.com.timelinefm.iPhone")?.setValue(footerString, forKey: "footerText")
            } else {
                UserDefaults.init(suiteName: "group.com.timelinefm.iPhone")?.setValue(nil, forKey: "totalDurationString")
                UserDefaults.init(suiteName: "group.com.timelinefm.iPhone")?.setValue(nil, forKey: "totalDistanceString")
                UserDefaults.init(suiteName: "group.com.timelinefm.iPhone")?.setValue(nil, forKey: "entryDurationString")
                UserDefaults.init(suiteName: "group.com.timelinefm.iPhone")?.setValue(nil, forKey: "entryTimespanString")
                UserDefaults.init(suiteName: "group.com.timelinefm.iPhone")?.setValue("No Active Timesheet", forKey: "activityNameString")
                UserDefaults.init(suiteName: "group.com.timelinefm.iPhone")?.setValue(nil, forKey: "locationNameString")
                UserDefaults.init(suiteName: "group.com.timelinefm.iPhone")?.setValue(nil, forKey: "locationAddressString")
                UserDefaults.init(suiteName: "group.com.timelinefm.iPhone")?.setValue(nil, forKey: "entryDistanceString")
                UserDefaults.init(suiteName: "group.com.timelinefm.iPhone")?.setValue(footerString, forKey: "footerText")
            }
        }
        
         Daemon.shared.addTask(task: task)
    }
    
    func command_processor() {
        
        let task = DaemonTask()
        task.interval = 1
        task.offset = 0
        task.name = "CommandManager"
        task.description = "Monitors for 3d touch commands sent to the appDelegate and will trigger a response if neccesary."
        
        task.executable = {
            Commander.shared.process()
        }
        
        Daemon.shared.addTask(task: task)
    }
    

    fileprivate var logoutTimer:Date? = nil
    func automatic_scheduling() {
        
        let task = DaemonTask()
        task.interval = 15
        task.offset = 4
        task.name = "AutomaticScheduling"
        task.description = "Responsible for monitoring the users schedule, if active, and will automatically create entries as determined by the local device settings."
        
        task.executable = {
            
            guard DeviceSettings.shared.schedulingMode == true else {
                return
            }
            
            guard let scheduleState = DeviceUser.shared.schedule?.state else {
                return
            }
            
            switch scheduleState {
            case .AwaitingLocation:
                guard let location = LocationManager.shared.isInKnownLocation() else {
                    return
                }
                
                DeviceUser.shared.sheet = Sheet()
                DeviceUser.shared.sheet?.create({ success in
                    guard success == true else {
                        return
                    }
                    
                    let userInfo: [AnyHashable: Any] = ["location": location as Any]
                    NotificationManager.shared.create_entry.post(userInfo)
                    
                    Notifications.shared.scheduleNotification(title: "Timeline", body: "Timeline has automatically started a timesheet for you based on you schedule", identifier: "automatic-schedule-start")
                })
                break
            case .End:
                guard LocationManager.shared.isInKnownLocation() == nil else {
                    return
                }
                
                if DeviceUser.shared.sheet?.entries.count == 0 {
                    
                    DeviceUser.shared.sheet?.delete({ success in
                        guard success == true else {
                            return
                        }
                    })
                } else {
                    let userInfo: [AnyHashable: Any] = ["end": Date() as Any]
                    
                    NotificationManager.shared.submit_timesheet.post(userInfo)
                }
                
                Notifications.shared.scheduleNotification(title: "Timeline", body: "Timeline has automatically ended your timesheet for you based on you schedule", identifier: "automatic-schedule-end")
                break
            case .Start:
                if let location = LocationManager.shared.isInKnownLocation() {
                    DeviceUser.shared.sheet = Sheet()
                    DeviceUser.shared.sheet?.create({ success in
                        guard success == true else {
                            return
                        }
                        
                        let userInfo: [AnyHashable: Any] = ["location": location as Any]
                        NotificationManager.shared.create_entry.post(userInfo)
                    })
                } else {
                    NotificationManager.shared.create_timesheet.post()
                }
                
                Notifications.shared.scheduleNotification(title: "Timeline", body: "Timeline has automatically started a timesheet for you based on you schedule", identifier: "automatic-schedule-start")
                break
            case .Imminent:
                if System.shared.state == .Off {
                    LocationManager.shared.setSensitivityLow()
                }
                break
            default:
                break
            }
        }
        
        Daemon.shared.addTask(task: task)
    }
}
