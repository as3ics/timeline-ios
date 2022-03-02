//
//  APICoreDataProtocol.swift
//  Timeline FM
//
//  Created by Zachary DeGeorge on 8/27/18.
//  Copyright © 2018 Next Day Project. All rights reserved.
//

import Foundation
import CoreData


// MARK: - APICoreDataProtocol

protocol APICoreDataProtocol {
    static var descriptor: APIClassDescriptor { get }
    
    static var entityName: String { get }
    
    init(json: JSON)
    
    var id: String? { get }
    func retrieve(_ callback: @escaping (_ err: Error?, _ newResult: Any?) -> Void, _ initialValue: Any?)
    var keys: [String] { get }
    var entity: NSManagedObject? { get set }
    var shallBeRemoved: Bool { get set }
}

extension APICoreDataProtocol {
    
    func createEntity() -> NSManagedObject? {
        
        guard let context = AppDelegate.managedContext, let _self = self as? NSObject, let entity = NSEntityDescription.entity(forEntityName: type(of: self).entityName, in: context) else {
            return nil
        }
        
        let object = NSManagedObject(entity: entity, insertInto: context)
        
        for key in self.keys {
            if let value = _self.value(forKey: key) {
                object.setValue(value, forKey: key)
            }
        }
        
        if object.value(forKey: "timestamp") == nil {
            object.setValue(Date(), forKey: "timestamp")
        }
        
        
        AppDelegate.saveContext()
        
        return object
    }
    
    func saveEntity() {
        guard let _self = self as? NSObject, let entity = self.entity else {
            return
        }
        
        for key in self.keys {
            if let value = _self.value(forKey: key) {
                entity.setValue(value, forKey: key)
            }
        }
        
        if entity.value(forKey: "timestamp") == nil {
            entity.setValue(Date(), forKey: "timestamp")
        }
        
        AppDelegate.saveContext()
    }
    
    func json() -> JSON {
        
        guard let _self = self as? NSObject else {
            return JSON()
        }
        
        var json = JSON()
        
        for key in self.keys {
            if let value = _self.value(forKey: key) {
                if let date = value as? Date {
                    json[key] = APIClient.shared.formatter.string(from: date) as JSONObject
                } else {
                    json[key] = value as JSONObject
                }
            }
        }
        
        return json
    }
}



