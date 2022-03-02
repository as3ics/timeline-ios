//
//  Schedule.swift
//  Timesheets
//
//  Created by Zachary DeGeorge on 4/27/18.
//  Copyright © 2018 Timeline Software, LLC. All rights reserved.
//

import Foundation
import CoreLocation
import CoreData

enum ScheduleState {
    case Disabled           // Take no action
    case AwaitingLocation   // Take action once inside location
    case Start              // Take action to start timesheet now
    case End                // Take action to end timesheet now
    case Imminent           // Action is imminent i.e < 1 hour away
}

// Time Valuess

let HOUR: TimeInterval = 60.0 * 60.0
let MINUTE: TimeInterval = 60.0
let DAY: TimeInterval = 60.0 * 60.0 * 24.0

// MARK: - Schedule

@objcMembers class Schedule: APIModel {
    
    // MARK: - Descriptors

    override var descriptor: String {
        return "Schedule"
    }
    
    override var modelType: ModelType {
        return ModelType.Schedule
    }
    
    override var keys: [String] {
        return [ "id", "name", "timestamp", "user" ]
    }
    
    
    let ScheduleDays: Array<String> = ["sunday", "monday", "tuesday", "wednesday", "thursday", "friday", "saturday"]
    
    // MARK: - Initializers
    
    required init() {
        super.init()
    }
    
    required init(attrs: JSON) {
        super.init(attrs: attrs)
        
        if let sunday = attrs["sunday"] as? [String: AnyObject] { self.sunday = DaySchedule(attrs: sunday) }
        if let monday = attrs["monday"] as? [String: AnyObject] { self.monday = DaySchedule(attrs: monday) }
        if let tuesday = attrs["tuesday"] as? [String: AnyObject] { self.tuesday = DaySchedule(attrs: tuesday) }
        if let wednesday = attrs["wednesday"] as? [String: AnyObject] { self.wednesday = DaySchedule(attrs: wednesday) }
        if let thursday = attrs["thursday"] as? [String: AnyObject] { self.thursday = DaySchedule(attrs: thursday) }
        if let friday = attrs["friday"] as? [String: AnyObject] { self.friday = DaySchedule(attrs: friday) }
        if let saturday = attrs["saturday"] as? [String: AnyObject] { self.saturday = DaySchedule(attrs: saturday) }
        
        if let sunday = self.sunday, let monday = self.monday, let tuesday = self.tuesday, let wednesday = self.wednesday, let thursday = self.thursday, let friday = self.friday, let saturday = self.saturday {
            schedules = [sunday, monday, tuesday, wednesday, thursday, friday, saturday]
        }
    }
    
    required public init(object: NSManagedObject) {
        super.init(object: object)
        
    }
    
    // MARK: - Other Properties

    var user: String?

    var sunday: DaySchedule?
    var monday: DaySchedule?
    var tuesday: DaySchedule?
    var wednesday: DaySchedule?
    var thursday: DaySchedule?
    var friday: DaySchedule?
    var saturday: DaySchedule?

    var schedules: [DaySchedule]?
    
    // MARK: Subscripts
    
    subscript(index: Int) -> DaySchedule? {
        guard index >= 0, index < schedules?.count ?? 0 else {
            return nil
        }

        return schedules![index]
    }
    
    // MARK: - API Protocol Values
    
    override var retrieveUrl: String? {
        guard let orgId = Auth.shared.orgId, let userId = Auth.shared.id else {
            return nil
        }
        
        return String(format: "/organizations/%@/schedules/user/%@", arguments: [orgId, userId])
    }
    
    // MARK: - API Protocol Handlers
    
    override func processRetrieve(data: JSON) -> JSON? {
        let schedule = Schedule(attrs: data)
        
        let container: JSON = [
            "model": schedule as JSONObject,
            ]
        
        return container
    }
    
    override var updateUrl: String? {
         guard let orgId = Auth.shared.orgId, let id = self.id else {
            return nil
        }
        
        return String(format: "/organizations/%@/schedules/%@", arguments: [orgId, id])
    }
    
    override var updateParams: JSON? {
        var params: JSON = toJson()
        params["updatedBy"] = (Auth.shared.id ?? "") as JSONObject
        return params
    }
    
    // MARK: - Other Methods

    override func toJson() -> JSON {
        var json = JSON()

        if let id = self.id { json["id"] = id as JSONObject }
        if let user = self.user { json["user"] = user as JSONObject }

        for i in 0 ... 6 {
            if let day = self[i] {
                if let start = day.start, let end = day.end, let active = day.active {
                    json[ScheduleDays[i]] = [
                        "start": APIClient.shared.formatter.string(from: start) as JSONObject,
                        "end": APIClient.shared.formatter.string(from: end) as JSONObject,
                        "active": active as JSONObject,
                    ] as JSONObject
                }
            }
        }

        return json
    }
}

// MARK: - Schedule Extension

extension Schedule {
    var state: ScheduleState {
        get {
            
            guard DeviceSettings.shared.schedulingMode == true else {
                return ScheduleState.Disabled
            }
            
            if let override = Overrides.shared.active {
                if(override.doNotTrack == true) {
                    return ScheduleState.Disabled
                } else {
                    guard let start = override.start, let end = override.end else {
                        return ScheduleState.Disabled
                    }
                    
                    let date = Date()
                    
                    switch System.shared.state {
                    case .Off:
                        
                        // If end has past return disabled
                        guard date.timeIntervalSince(end) < 0 else {
                            return ScheduleState.Disabled
                        }
                        
                        // Check if time is up
                        if date.timeIntervalSince(start) > 0 {
                            if DeviceSettings.shared.schedulingAwaitLocation == true {
                                return ScheduleState.AwaitingLocation
                            }else {
                                return ScheduleState.Start
                            }
                            // Check if imminent action
                        } else if -date.timeIntervalSince(start) < HOUR {
                            return ScheduleState.Imminent
                        } else {
                            return ScheduleState.Disabled
                        }
                    default:
                        if date.timeIntervalSince(end) > 0 {
                            return ScheduleState.End
                        } else if -date.timeIntervalSince(end) < HOUR {
                            return ScheduleState.Imminent
                        } else {
                            return ScheduleState.Disabled
                        }
                    }
                }
            } else { // no active override so check day schedule
                
                var calendar = Calendar.current
                calendar.timeZone = TimeZone.current
                
                let date = Date()
                let day = (calendar.component(Calendar.Component.weekday, from: Date())) - 1
                
                let daySchedule = self[day]
                
                guard let start = daySchedule?.startDate, let end = daySchedule?.endDate, let active = daySchedule?.active, active == true else {
                    return ScheduleState.Disabled
                }
                
                switch System.shared.state {
                case .Off:
                    
                    // If end has past return disabled
                    guard date.timeIntervalSince(end) < 0 else {
                        return ScheduleState.Disabled
                    }
                    
                    // Check if time is up
                    if date.timeIntervalSince(start) > 0 {
                        if DeviceSettings.shared.schedulingAwaitLocation == true {
                            return ScheduleState.AwaitingLocation
                        }else {
                            return ScheduleState.Start
                        }
                        // Check if imminent action
                    } else if -date.timeIntervalSince(start) < HOUR {
                        return ScheduleState.Imminent
                    } else {
                        return ScheduleState.Disabled
                    }
                default:
                    if date.timeIntervalSince(end) > 0 {
                        return ScheduleState.End
                    } else if -date.timeIntervalSince(end) < HOUR {
                        return ScheduleState.Imminent
                    } else {
                        return ScheduleState.Disabled
                    }
                }
            }
        }
    }
}


class DaySchedule {
    var start: Date?
    var end: Date?
    var active: Bool?
    
    var startDate: Date? {
        guard start != nil else {
            return nil
        }
        
        var calendar = Calendar.current
        calendar.timeZone = TimeZone.current
        
        let hour = Calendar.current.component(Calendar.Component.hour, from: start!)
        let minute = Calendar.current.component(Calendar.Component.minute, from: start!)
        let day = calendar.component(Calendar.Component.day, from: Date())
        let month = calendar.component(Calendar.Component.month, from: Date())
        let year = calendar.component(Calendar.Component.year, from: Date())
        
        let components = DateComponents(calendar: calendar, timeZone: TimeZone.current, era: nil, year: year, month: month, day: day, hour: hour, minute: minute, second: 0, nanosecond: nil, weekday: nil, weekdayOrdinal: nil, quarter: nil, weekOfMonth: nil, weekOfYear: nil, yearForWeekOfYear: nil)
        
        return calendar.date(from: components)
    }
    
    var endDate: Date? {
        guard end != nil else {
            return nil
        }
        
        var calendar = Calendar.current
        calendar.timeZone = TimeZone.current
        
        let hour = Calendar.current.component(Calendar.Component.hour, from: end!)
        let minute = Calendar.current.component(Calendar.Component.minute, from: end!)
        let day = calendar.component(Calendar.Component.day, from: Date())
        let month = calendar.component(Calendar.Component.month, from: Date())
        let year = calendar.component(Calendar.Component.year, from: Date())
        
        let components = DateComponents(calendar: calendar, timeZone: TimeZone.current, era: nil, year: year, month: month, day: day, hour: hour, minute: minute, second: 0, nanosecond: nil, weekday: nil, weekdayOrdinal: nil, quarter: nil, weekOfMonth: nil, weekOfYear: nil, yearForWeekOfYear: nil)
        
        return calendar.date(from: components)
    }
    
    convenience init(attrs: [String: AnyObject]) {
        self.init()
        
        if let start = attrs["start"] as? String { self.start = APIClient.shared.formatter.date(from: start) }
        if let end = attrs["end"] as? String { self.end = APIClient.shared.formatter.date(from: end) }
        active = attrs["active"] as? Bool
    }
    
    func set(_ day: DaySchedule) {
        start = day.start
        end = day.end
        active = day.active
    }
}
