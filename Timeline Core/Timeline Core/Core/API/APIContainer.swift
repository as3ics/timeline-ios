//
//  APIContainer.swift
//  Timeline FM
//
//  Created by Zachary DeGeorge on 8/28/18.
//  Copyright © 2018 Next Day Project. All rights reserved.
//

import Foundation
import CoreData

// MARK: - APIContainer

@objcMembers class APIContainer<T: APIModelProtocol>: NSObject, APIContainerProtocol {
    
    // MARK: - Typealias
    
    typealias Item = T
    
    // MARK: - Descriptors
    
    open var descriptor: String {
        assert(false, "You must override this value")
        return "APIContainer"
    }
    open var modelType: ModelType {
        assert(false, "You must override this value")
        return ModelType.Anonymous
    }
    open var entityName: String {
        assert(false, "You must override this value")
        return "APIEntity"
    }
    
    // MARK: - Arrays
    
    var items: [T] = [T]()
    var entities: [NSManagedObject] = [NSManagedObject]()
    
    
    // MARK: - Subscripts
    
    final subscript(index: Int?) -> Item? {
        guard let index = index, index < self.count else {
            return nil
        }
        
        return items[index]
    }
    
    final subscript(id: String?) -> Item? {
        guard let id = id, self.count > 0 else {
            return nil
        }
        
        let matches = items.filter { (item) -> Bool in
            return item.id == id
        }
        
        return matches.first
    }
    
    final func index(name: String?) -> Int? {
        guard let name = name, self.count > 0 else {
            return nil
        }
        
        for (index, item) in items.enumerated() {
            if item.name == name {
                return index
            }
        }
        
        return nil
    }
    
    final func index(id: String?) -> Int? {
        guard let id = id, self.count > 0 else {
            return nil
        }
        
        for (index, item) in items.enumerated() {
            if item.id == id {
                return index
            }
        }
        
        return nil
    }
    
    final func get(name: String?) -> Item? {
        guard let name = name, self.count > 0 else {
            return nil
        }
        
        let matches = items.filter { (item) -> Bool in
            return item.name == name
        }
        
        return matches.first
    }
    
    
    final func get(tag: Int) -> Item? {
        
        let matches = items.filter { (item) -> Bool in
            return item.tag == tag
        }
        
        return matches.first
    }
    
    
    final func entity(id: String?) -> NSManagedObject? {
        guard let id = id, self.count > 0 else {
            return nil
        }
        
        let matches = entities.filter { (entity) -> Bool in
            guard let entityId = entity.value(forKey: "id") as? String else {
                return false
            }
            
            return entityId == id
        }
        
        return matches.first
    }
    
    final func item(id: String?) -> Item? {
        guard let id = id, self.count > 0 else {
            return nil
        }
        
        let matches = items.filter { (item) -> Bool in
            return item.id == id
        }
        
        return matches.first
    }
    
    final var count: Int {
        return items.count
    }
    
    // MARK: - Timestamps
    
    final var latestTimestamp: Date! {
        var latest: Date! = Date(timeIntervalSince1970: 0.0)
        
        for item in self.items {
            if let time = item.timestamp, time > latest {
                latest = time
            }
        }
        
        return latest
    }
    
    // MARK: - API Protocol Values
    
    open var retrieveUrl: String? { return nil }
    open var retrieveParams: JSON? { return EMPTY_JSON }
    
    // MARK: - API Protocol Handlers
    
    open func process(_ callback: @escaping (_ err: Error?, _ newResult: Any?) -> Void, _ initialValue: Any?) { callback(nil, initialValue) }
    
    // MARK: - Update Methods
    
    final func add(_ value: Any?, sort: Bool = true, insert: Bool = false) {
        guard var item = value as? Item, item.id != Auth.shared.id else {
            return
        }
        
        item.tag = count + 1
        
        if let index = self.index(id: item.id) {
            items.remove(at: index)
        }
        
        if insert == true {
            items.insert(item, at: 0)
        } else {
            items.append(item)
        }
        
        
        if sort == true {
            self.sort()
        }
    }
    
    final func remove(_ value: Any?, sort: Bool = true) {
        guard let item = value as? Item else {
            return
        }
        
        if let index = self.index(id: item.id) {
            item.cleanse()
            item.deleteEntity()
            items.remove(at: index)
        }
        
        if sort == true {
            self.sort()
        }
    }
    
    final func update(_ value: Any?, sort: Bool = true) {
        guard let item = value as? Item else {
            return
        }
        
        if let index = self.index(id: item.id) {
            items.remove(at: index)
            items.insert(item, at: index)
            return
        }
        
        items.append(item)
        
        if sort == true {
            self.sort()
        }
    }
    
    // MARK: - Core Data Methods
    
    final func fetchAllEntities() -> [NSManagedObject] {
        
        guard let context = AppDelegate.managedContext else {
            return []
        }
        
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: self.entityName)
        
        do {
            let entities = try context.fetch(fetchRequest)
            
            print("\(self.entityName) Entity Fetch Success! \(entities.count) items fetched")
            
            return entities
            
        } catch let error as NSError {
            print("\(self.entityName) Entity Fetch Error: \(error), \(error.userInfo)")
            
            return []
        }
    }
    
    final func restoreAllEntities() {
        
        items.removeAll()
        entities.removeAll()
        
        entities = fetchAllEntities()
        
        for entity in entities {
            let item = Item(object: entity)
            add(item, sort: false)
        }
        
        sort()
    }
    
    final func deleteAllEntities() {
        
        for item in self.items {
            item.deleteEntity()
        }
        
        self.entities.removeAll()
        
        
        // Double check all entities deleted
        
        let entities = fetchAllEntities()
        
        guard entities.count == 0 else {
            for item in entities {
                if let context = item.managedObjectContext {
                    context.delete(item)
                    
                    do {
                        try context.save()
                    } catch {
                        // foo
                    }
                }
            }
            
            return
        }
    }
    
    final var shouldFetchRemote: Bool {
        return entities.count == 0 || items.count == 0
    }
    
    
    // MARK: - API Methods
    
    func synchronize(_ callback: @escaping (_ err: Error?, _ newResult: Any?) -> Void, _ initialValue: Any?) {
        let function: String = "synchronize"
        
        let start = Date()
        
        Notifications.shared.systemMessage(String(format: " Synchronizing %@", self.descriptor))
        
        guard let url = retrieveUrl else {
            APIDiagnostics.shared.ERROR(_classDescription: self.descriptor,
                                        _functionDescriptor: function,
                                        _url: "nil",
                                        _params: ["initialValues": initialValue.debugDescription as JSONObject],
                                        _start: start,
                                        _error: APIClientErrors.InputError)
            
            callback(nil, initialValue)
            return
        }
        
        var params: JSON = EMPTY_JSON
        params["timestamps"] = APIClient.shared.formatter.string(from: latestTimestamp) as AnyObject

        APIClient.shared.GET(url: url, parameters: params) { (_, response, body) -> Void in
            
            guard response?.statusCode == 200 else {
                APIDiagnostics.shared.ERROR(_classDescription: self.descriptor,
                                            _functionDescriptor: function,
                                            _url: url,
                                            _params: params,
                                            _start: start,
                                            _error: APIClientErrors.StatusError,
                                            _response: response,
                                            _body: body)
                
                callback(nil, initialValue)
                return
            }
            
            guard let data = body as? [JSON] else {
                APIDiagnostics.shared.ERROR(_classDescription: self.descriptor,
                                            _functionDescriptor: function,
                                            _url: url,
                                            _params: params,
                                            _start: start,
                                            _error: APIClientErrors.DataError,
                                            _response: response,
                                            _body: body)
                
                callback(nil, initialValue)
                return
            }
            
            var queries = [(@escaping (Error?, Any?) -> Void, Any?) -> Void]()
            var failures = [(@escaping (Error?, Any?) -> Void, Any?) -> Void]()
            var retrievedItems: [Item] = [Item]()
            var fetchedItems: [Item] = [Item]()
            
            for value in data {
                guard let id = value["id"] as? String, id != Auth.shared.id else {
                    continue
                }
                
                let item = Item(attrs: ["id": id as JSONObject])
                retrievedItems.append(item)
                
                guard let updatedDateStr = value["_updatedDate"] as? String, let updatedDate = APIClient.shared.formatter.date(from: updatedDateStr) else {
                    continue
                }
                
                if let entity = self.entity(id: id), let timestamp = entity.value(forKey: "timestamp") as? Date {
                    if timestamp < updatedDate {
                        queries.append(item.retrieve)
                    }
                } else {
                    fetchedItems.append(item)
                    queries.append(item.retrieve)
                }
            }
            
            guard queries.count > 0 else {
                self.sort()
                callback(nil, initialValue)
                return
            }
            
            for (index, query) in queries.enumerated() {
                DispatchQueue.main.async {
                    Async.waterfall(nil, [query], end: { error, container in
                        
                        guard error == nil else {
                            failures.append(query)
                            return
                        }
                        
                        Notifications.shared.systemMessage(String(format: "%i of %i %@ Synchronized", index + 1, queries.count,  self.descriptor))
                        
                        if index >= queries.count - 1 {
                            
                            guard failures.count == 0 else {
                                
                                for (index, query) in failures.enumerated() {
                                    DispatchQueue.main.async {
                                        Async.waterfall(nil, [query], end: { error, _ in
                                            
                                            Notifications.shared.systemMessage(String(format: "%i of %i %@ Remedied", index + 1, failures.count,  self.descriptor))
                                            
                                            if index >= failures.count - 1 {
                                                self.sort()
                                                callback(nil, initialValue)
                                            }
                                        })
                                    }
                                }
                                
                                self.sort()
                                callback(nil, initialValue)
                                return
                                
                            }
                            
                            self.sort()
                            callback(nil, initialValue)
                            return
                        }
                    })
                }
            }
        }
    }
    
    func prune(_ callback: @escaping (_ err: Error?, _ newResult: Any?) -> Void, _ initialValue: Any?) {
        let function: String = "prune"
        
        let start = Date()
        
        Notifications.shared.systemMessage(String(format: " Verifying %@", self.descriptor))
        
        guard let url = retrieveUrl else {
            APIDiagnostics.shared.ERROR(_classDescription: self.descriptor,
                                        _functionDescriptor: function,
                                        _url: "nil",
                                        _params: ["initialValues": initialValue.debugDescription as JSONObject],
                                        _start: start,
                                        _error: APIClientErrors.InputError)
            
            callback(nil, initialValue)
            return
        }
        
        var params: JSON = EMPTY_JSON
        params["timestamps"] = APIClient.shared.formatter.string(from: Date(timeIntervalSince1970: 0)) as AnyObject
        
        APIClient.shared.GET(url: url, parameters: params) { (_, response, body) -> Void in
            
            guard response?.statusCode == 200 else {
                APIDiagnostics.shared.ERROR(_classDescription: self.descriptor,
                                            _functionDescriptor: function,
                                            _url: url,
                                            _params: params,
                                            _start: start,
                                            _error: APIClientErrors.StatusError,
                                            _response: response,
                                            _body: body)
                
                callback(nil, initialValue)
                return
            }
            
            guard let data = body as? [JSON] else {
                APIDiagnostics.shared.ERROR(_classDescription: self.descriptor,
                                            _functionDescriptor: function,
                                            _url: url,
                                            _params: params,
                                            _start: start,
                                            _error: APIClientErrors.DataError,
                                            _response: response,
                                            _body: body)
                
                callback(nil, initialValue)
                return
            }
            
            var retrieved: [String] = [String]()
            
            for value in data {
                guard let id = value["id"] as? String, id != Auth.shared.id else {
                    continue
                }
                
                retrieved.append(id)
            }
            
            for item in self.items {
                if let id = item.id {
                    let matches = retrieved.filter({ (userId) -> Bool in
                        return userId == id
                    })
                    
                    if matches.count == 0 {
                        self.remove(item, sort: false)
                    }
                }
            }
            
            self.sort()
            callback(nil, initialValue)
        }
    }
    
    
    func retrieve(_ callback: @escaping (_ err: Error?, _ newResult: Any?) -> Void, _ initialValue: Any?) {
        let function: String = "retrieve"
        
        let start = Date()
        
        Notifications.shared.systemMessage(String(format: " Retrieving %@", self.descriptor))
        
        guard let url = retrieveUrl, let params = retrieveParams else {
            APIDiagnostics.shared.ERROR(_classDescription: self.descriptor,
                                        _functionDescriptor: function,
                                        _url: "nil",
                                        _params: ["initialValues": initialValue.debugDescription as JSONObject],
                                        _start: start,
                                        _error: APIClientErrors.InputError)
            callback(APIClientErrors.InputError, initialValue)
            return
        }
        
        APIClient.shared.GET(url: url, parameters: params) { (_, response, body) -> Void in
            
            guard response?.statusCode == 200 else {
                APIDiagnostics.shared.ERROR(_classDescription: self.descriptor,
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
                APIDiagnostics.shared.ERROR(_classDescription: self.descriptor,
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
            
            Async.waterfall(data, [self.process], end: { _, _ in
                
                APIDiagnostics.shared.SUCCESS(_classDescription: self.descriptor,
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
    
    // MARK: - Other Functions
    
    func toJson() -> [JSON] {
        var json = [JSON]()
        
        for item in items {
            json.append(item.toJson())
        }
        
        return json
    }
    
    func sort() { }
}
