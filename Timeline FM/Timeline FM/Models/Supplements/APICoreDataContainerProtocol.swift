//
//  APICoreDataContainerProtocol.swift
//  Timeline FM
//
//  Created by Zachary DeGeorge on 8/27/18.
//  Copyright © 2018 Next Day Project. All rights reserved.
//

import Foundation
import CoreData


// MARK: - APICoreDataContainerProtocol

protocol APICoreDataContainerProtocol {
    associatedtype Item: APICoreDataProtocol
    associatedtype Shared
    static var descriptor: APIClassDescriptor { get }
    
    static var shared: Shared { get }
    
    var items: [Item] { get set }
    var entities: [NSManagedObject] { get set }
    
    var retrieveUrl: String? { get }
    func restore(_ callback: @escaping (_ err: Error?, _ newResult: Any?) -> Void, _ initialValue: Any?)
    func synchronize(_ callback: @escaping (_ err: Error?, _ newResult: Any?) -> Void, _ initialValue: Any?)
    func deleteAllEntities()
    
}

extension APICoreDataContainerProtocol {
    
    func fetchAllEntities() -> [NSManagedObject] {
        
        guard let context = AppDelegate.managedContext else {
            return []
        }
        
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: Item.entityName)
        
        do {
            let entities = try context.fetch(fetchRequest)
            
            print("\(Item.descriptor) Entity Fetch Success! \(entities.count) items fetched")
            
            return entities
            
        } catch let error as NSError {
            print("\(Item.descriptor) Entity Fetch Error: \(error), \(error.userInfo)")
            
            return []
        }
    }
    
    func deleteAllEntities() {
        guard let context = AppDelegate.managedContext else {
            return
        }
        
        for var item in items {
            item.entity = nil
        }
        
        var objects = self.entities
        objects.removeAll()
        
        let entities = fetchAllEntities()
        for entity in entities {
            context.delete(entity)
        }
        
        AppDelegate.saveContext()
    }
    
    func shouldFetchRemote() -> Bool {
        return entities.count == 0
    }
    
    func entity(id: String?) -> NSManagedObject? {
        guard let id = id else {
            return nil
        }
        
        let entity = entities.filter { (entity) -> Bool in
            guard let entityId = entity.value(forKey: "id") as? String else {
                return false
            }
            
            return entityId == id
        }
        
        guard entity.count >= 1 else {
            return nil
        }
        
        return entity[0]
    }
    
    func item(id: String?) -> Item? {
        guard let id = id else {
            return nil
        }
        
        let item = items.filter { (item) -> Bool in
            guard let itemId = item.id else {
                return false
            }
            
            return itemId == id
        }
        
        guard item.count >= 1 else {
            return nil
        }
        
        return item[0]
    }
    
    func synchronize(_ callback: @escaping (_ err: Error?, _ newResult: Any?) -> Void, _ initialValue: Any?) {
        let function: APIFunctionDescriptor = "synchronize"
        
        let start = Date()
        
        guard let url = retrieveUrl else {
            APIDiagnostics.shared.ERROR(_classDescription: type(of: self).descriptor,
                                        _functionDescriptor: function,
                                        _url: "nil",
                                        _params: ["initialValues": initialValue.debugDescription as JSONObject],
                                        _start: start,
                                        _error: APIClientErrors.InputError)
            callback(APIClientErrors.InputError, initialValue)
            return
        }
        
        let params: JSON = ["timestamps" : true as AnyObject]
        
        APIClient.shared.GET(url: url, parameters: params) { (_, response, body) -> Void in
            
            guard response?.statusCode == 200 else {
                APIDiagnostics.shared.ERROR(_classDescription: type(of: self).descriptor,
                                            _functionDescriptor: function,
                                            _url: url,
                                            _params: params,
                                            _start: start,
                                            _error: APIClientErrors.StatusError,
                                            _response: response,
                                            _body: body)
                callback(APIClientErrors.StatusError, initialValue)
                return
            }
            
            guard let data = body as? [JSON] else {
                APIDiagnostics.shared.ERROR(_classDescription: type(of: self).descriptor,
                                            _functionDescriptor: function,
                                            _url: url,
                                            _params: params,
                                            _start: start,
                                            _error: APIClientErrors.DataError,
                                            _response: response,
                                            _body: body)
                callback(APIClientErrors.DataError, initialValue)
                return
            }
            
            var queries = [(@escaping (Error?, Any?) -> Void, Any?) -> Void]()
            var retrievedItems: [Item] = [Item]()
            
            for value in data {
                guard let id = value["id"] as? String else {
                    continue
                }
                
                let item = Item(json: ["id": id as JSONObject])
                retrievedItems.append(item)
                
                guard let updatedDateStr = value["_updatedDate"] as? String, let updatedDate = APIClient.shared.formatter.date(from: updatedDateStr) else {
                    continue
                }
                
                if let entity = self.entity(id: id), let timestamp = entity.value(forKey: "timestamp") as? Date {
                    if timestamp < updatedDate {
                        queries.append(item.retrieve)
                    }
                } else {
                    queries.append(item.retrieve)
                }
            }
            
            for retrievedItem in retrievedItems {
                if var item = self.item(id: retrievedItem.id) {
                    item.shallBeRemoved = false
                }
            }
            
            if let context = AppDelegate.managedContext {
                var _self = self
                var i: Int = 0
                for var item in self.items {
                    if item.shallBeRemoved == true {
                        if let entity = item.entity {
                            context.delete(entity)
                            item.entity = nil
                        }
                        
                        _self.items.remove(at: i)
                        continue
                    }
                    
                    i += 1
                }
                
                AppDelegate.saveContext()
            }
            
            
            Async.waterfall(nil, queries, end: { _, _ in
                APIDiagnostics.shared.SUCCESS(_classDescription: type(of: self).descriptor,
                                              _functionDescriptor: function,
                                              _url: url,
                                              _params: params,
                                              _start: start,
                                              _body: body,
                                              _response: response)
                
                callback(nil, initialValue)
                
            })
        }
    }
}

