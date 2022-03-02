//
//  Override.swift
//  Timesheets
//
//  Created by Zachary DeGeorge on 4/29/18.
//  Copyright © 2018 Timeline Software, LLC. All rights reserved.
//

import Foundation
import CoreLocation
import CoreData

class Overrides: APIContainer<Override>, APIContainerSingletonProtocol {
    
    typealias Shared = Overrides

    static var shared = Shared()

    override var modelType: ModelType {
        return ModelType.Overrides
    }
    
    override var descriptor: String {
        return "Overrides"
    }
    
    // MARK: - API Protocol Constructors
    
    override var retrieveUrl: String? {
        guard let orgId = Auth.shared.orgId, let userId = Auth.shared.id else {
            return nil
        }
        
        return String(format: "/organizations/%@/overrides/user/%@/active", arguments: [orgId, userId])
    }
    
    override var retrieveParams: JSON? {
        return EMPTY_JSON
    }
    
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
        
        sort()
        
        callback(nil, nil)
    }

    var active: Override? {
        guard items.count > 0 else {
            return nil
        }

        let day = Calendar.current.component(Calendar.Component.day, from: Date())
        let month = Calendar.current.component(Calendar.Component.month, from: Date())
        let year = Calendar.current.component(Calendar.Component.year, from: Date())

        var todayComponents = DateComponents()
        todayComponents.day = day
        todayComponents.month = month
        todayComponents.year = year

        let today = Calendar.current.date(from: todayComponents)

        var value: Override?
        for override in items {
            if let start = override.start {
                let overrideStartDay = Calendar.current.component(Calendar.Component.day, from: start)
                let overrideStartMonth = Calendar.current.component(Calendar.Component.month, from: start)
                let overrideStartYear = Calendar.current.component(Calendar.Component.year, from: start)

                var overrideStartComponents = DateComponents()
                overrideStartComponents.day = overrideStartDay
                overrideStartComponents.month = overrideStartMonth
                overrideStartComponents.year = overrideStartYear

                let overrideStart = Calendar.current.date(from: overrideStartComponents)

                if override.multiDay == false {
                    if let today = today, let overrideStart = overrideStart {
                        if today == overrideStart {
                            value = override
                            break
                        }
                    }
                } else {
                    if let end = override.end {
                        let overrideEndDay = Calendar.current.component(Calendar.Component.day, from: end)
                        let overrideEndMonth = Calendar.current.component(Calendar.Component.month, from: end)
                        let overrideEndYear = Calendar.current.component(Calendar.Component.year, from: end)

                        var overrideEndComponents = DateComponents()
                        overrideEndComponents.day = overrideEndDay
                        overrideEndComponents.month = overrideEndMonth
                        overrideEndComponents.year = overrideEndYear

                        let overrideEnd = Calendar.current.date(from: overrideEndComponents)

                        if let today = today, let overrideStart = overrideStart, let overrideEnd = overrideEnd {
                            if today >= overrideStart && today <= overrideEnd {
                                value = override
                                break
                            }
                        }
                    }
                }
            }
        }

        return value
    }

    override func sort() {
        items.sort(by: { $1.end ?? Date() > $0.end ?? Date() })
    }
}

@objcMembers class Override: APIModel
{
    override var descriptor: String {
        return "Override"
    }
    override var modelType: ModelType {
        return ModelType.Override
    }
    
    override var keys: [String] {
        return [ "id", "name", "timestamp", "user", "doNotTrack", "multiDay", "start", "end", "title", "notes", "heading" ]
    }

    var user: String?
    var start: Date?
    var end: Date?
    var title: String?
    var notes: String?
    
    var doNotTrack: Bool = false
    var multiDay: Bool = false
    
    override var createUrl: String? {
        guard let orgId = Auth.shared.orgId, let userId = Auth.shared.id else {
            return nil
        }
        
        return String(format: "/organizations/%@/overrides/user/%@", arguments: [orgId, userId])
    }
    
    override var createParams: JSON? {
        guard let userId = Auth.shared.id else {
            return nil
        }
        
        self.user = userId
        
        return toJson()
    }
    
    override func processCreate(data: JSON) -> Bool {
        guard let id = data["id"] as? String else {
            return false
        }
        
        self.id = id
        
        return true
    }
    
    override var retrieveUrl: String? {
        guard let orgId = Auth.shared.orgId, let id = self.id else {
            return nil
        }
        
        return String(format: "/organizations/%@/overrides/%@", arguments: [orgId, id])
    }
    
    override var retrieveParams: JSON? {
        return EMPTY_JSON
    }
    
    override func processRetrieve(data: JSON) -> JSON? {
        let override = Override(attrs: data)
        
        let container: JSON = [
            "model": override as JSONObject,
            ]
        
        return container
    }
    
    override var updateUrl: String? {
        guard let orgId = Auth.shared.orgId, let id = self.id else {
            return nil
        }
        
        return String(format: "/organizations/%@/overrides/%@", arguments: [orgId, id])
    }
    
    override var updateParams: JSON? {
        var params: JSON = toJson()
        params["updatedBy"] = (Auth.shared.id ?? "") as JSONObject
        return params
    }
    
    override var deleteUrl: String? {
        guard let orgId = Auth.shared.orgId, let id = self.id else {
            return nil
        }
        
        return String(format: "/organizations/%@/overrides/%@", arguments: [orgId, id])
    }
    
    override var deleteParams: JSON? {
        let params: JSON = [
            "hard": true as JSONObject,
            ]
        
        return params
    }

    override func toJson() -> JSON {
        var json = JSON()

        if let user = self.user { json["user"] = user as JSONObject }
        json["doNotTrack"] = doNotTrack as JSONObject
        json["multiDay"] = multiDay as JSONObject
        if let start = self.start { json["start"] = APIClient.shared.formatter.string(from: start) as JSONObject }
        if let end = self.end { json["end"] = APIClient.shared.formatter.string(from: end) as JSONObject }
        if let title = self.title { json["title"] = title as JSONObject }
        if let notes = self.notes { json["notes"] = notes as JSONObject }

        return json
    }
}
