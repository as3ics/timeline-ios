//
//  Activity.swift
//  Timeline Software, LLC
//
//  Created by Timeline Software, LLC on 3/8/16.
//  Copyright © 2016 Timeline Software, LLC. All rights reserved.
//

import Foundation
import CoreData

// MARK: - Activities

class Activities: APIContainer<Activity>, APIContainerSingletonProtocol {
    
    // MARK: - API Container
    
    typealias Shared = Activities
    
    static var shared = Shared()
    
    // MARK: - Descriptors
    
    override var modelType: ModelType {
        return ModelType.Activities
    }
    
    override var descriptor: String {
        return "Activities"
    }
    
    override var entityName: String {
        return "CoreActivity"
    }
    
    // MARK: - Initializers
    
    override init() {
        super.init()
        
        restoreAllEntities()
    }
    
    
    // MARK: - API Protocol Values
    
    override var retrieveUrl: String? {
        guard let orgId = Auth.shared.orgId else {
            return nil
        }
        
        return String(format: "/organizations/%@/activities", arguments: [orgId])
    }
    
    override var retrieveParams: JSON? {
        
        return EMPTY_JSON
    }
    
    // MARK: - API Protocol Handlers
    
    override func process(_ callback: @escaping (_ err: Error?, _ newResult: Any?) -> Void, _ initialValue: Any?) {
        
        guard let data = initialValue as? [JSON] else {
            callback(nil, nil)
            return
        }
        
        self.deleteAllEntities()
        self.items.removeAll()
        
        for (index, value) in data.enumerated() {
            let item = Item(attrs: value)
            item.tag = index + 1
            item.entity = item.createEntity()
            self.items.append(item)
            
            if let entity = item.entity {
                self.entities.append(entity)
            }
        }
        
        callback(nil, nil)
    }
    
    // MARK: - Alphabetic Sections
    
    var sectionTitles: [String] {
        
        sort()
        
        var sectionTitles = [String]()
        
        for activity in items {
            if let name = activity.name?.uppercased() {
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
        }
        
        return sectionTitles
    }
    
    func sectionValues(_ section: String) -> [Activity] {
        var values = [Activity]()
        
        let character = section.characters.first
        
        for value in items {
            if value.name?.uppercased().characters.first == character {
                values.append(value)
            }
        }
        
        return values
    }
    
    // MARK: - Other Properties
    
    var defaultActivity: Activity? {
        return get(name: "Working")
    }
    
    var travelingActivity: Activity? {
        return get(name: "Traveling")
    }
    
    var breakActivity: Activity? {
        return get(name: "Break")
    }
    
    // MARK: - Other Functions
    
    override func sort() {
        items.sort(by: { $0.name! < $1.name! })
    }
}

// MARK: - Activity

@objcMembers open class Activity: APIModel {
    
    // MARK: - Descriptors
    
    override open var entityName: String {
        return "CoreActivity"
    }
    
    override open var descriptor: String {
        return "Activity"
    }
    
    override open var modelType: ModelType {
        return ModelType.Activity
    }
    
    override open var keys: [String] {
        return [ "id", "name", "notes", "organization", "timestamp" ]
    }
    
    // MARK: - Additional Properties
    
    var notes: String?
    var organization: String?
    
    var traveling: Bool {
        return name == "Traveling"
    }
    
    var breaking: Bool {
        return name == "Break"
    }
    
    var working: Bool {
        return name == "Working"
    }
    
    var restricted: Bool {
        return traveling || breaking || working
    }
    
    // MARK: - API Protocol Values
    
    override open var createUrl: String? {
        guard let orgId = Auth.shared.orgId else {
            return nil
        }
        
        return String(format: "/organizations/%@/activities", arguments: [orgId])
    }
    
    override open var createParams: JSON? {
        guard let name = self.name, let createdBy = Auth.shared.id else {
            return nil
        }
        
        var params: JSON = [
            "name": name as JSONObject,
            "createdBy": createdBy as JSONObject
            ]
        
        if let notes = self.notes {
            params["notes"] = notes as JSONObject
        }
        
        return params
    }
    
    override open func processCreate(data: JSON) -> Bool {
        guard let id = data["id"] as? String else {
            return false
        }
        
        self.id = id
        self.entity = self.createEntity()
        
        return true
    }

    override open var retrieveUrl: String? {
        guard let orgId = Auth.shared.orgId, let id = self.id else {
            return nil
        }
        
        return String(format: "/organizations/%@/activities/%@", arguments: [orgId, id])
    }
    
    override open func processRetrieve(data: JSON) -> JSON? {
        
        let activity = Activity(attrs: data)
        
        if let entity = Activities.shared.entity(id: activity.id) {
            activity.entity = entity
            activity.saveEntity()
        } else {
            activity.entity = activity.createEntity()
        }
        
        let container: JSON = [
            "model": activity as JSONObject,
            ]
        
        return container
    }
    
    override open var updateUrl: String? {
        guard let orgId = Auth.shared.orgId, let id = self.id else {
            return nil
        }
        
        return String(format: "/organizations/%@/activities/%@", arguments: [orgId, id])
    }
    
    override open var updateParams: JSON? {
        guard let updatedBy = Auth.shared.id else {
            return nil
        }
        
        var params = toJson()
        params["updatedBy"] = updatedBy as JSONObject
        return params
    }
    
    override open var deleteUrl: String? {
        guard let orgId = Auth.shared.orgId, let id = self.id else {
            return nil
        }
        
        return String(format: "/organizations/%@/activities/%@", arguments: [orgId, id])
    }
    
    override open var deleteParams: JSON? {
        let params: JSON = [
            "hard": true as JSONObject,
            ]
        
        return params
    }
}
