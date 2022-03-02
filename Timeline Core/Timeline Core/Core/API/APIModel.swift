//
//  APIModel.swift
//  Timeline FM
//
//  Created by Zachary DeGeorge on 8/27/18.
//  Copyright © 2018 Next Day Project. All rights reserved.
//

import Foundation
import CoreData

public enum ModelType: String {
    
    case Anonymous = "ANONYMOUS"
    case Location = "LOCATION"
    case Locations = "LOCATIONS"
    case Activity = "ACTIVITY"
    case Activities = "ACTIVITIES"
    case User = "USER"
    case Users = "USERS"
    case Entry = "ENTRY"
    case Entries = "ENTRIES"
    case Sheet = "SHEET"
    case Sheets = "SHEETS"
    case Chatroom = "CHATROOM"
    case Chatrooms = "CHATROOMS"
    case Photo = "PHOTO"
    case Photos = "PHOTOS"
    case PhotoBucket = "PHOTOBUCKET"
    case Organization = "ORGANIZATION"
    case Organizations = "ORGANIZATIONS"
    case Schedule = "SCHEDULE"
    case Message = "MESSAGE"
    case Messages = "MESSAGES"
    case Breadcrumb = "BREADCRUMB"
    case Breadcrumbs = "BREADCRUMBS"
    case Override = "OVERRIDE"
    case Overrides = "OVERRIDES"
    case DeviceUser = "DEVICEUSER"
    case Statistics = "STATISTICS"
    case Subscription = "SUBSCRIPTION"
    case Subscriptions = "SUBSCRIPTIONS"
    case Stream = "STREAM"
    
}

// MARK: - APIModel

@objcMembers open class APIModel: NSObject, APIModelProtocol {
    
    // MARK: - Descriptors
    
    open var descriptor: String {
        assert(false, "You must override this value")
        return "APIModel"
    }
    open var modelType: ModelType {
        assert(false, "You must override this value")
        return ModelType.Anonymous
    }
    
    open var entityName: String {
        assert(false, "You must override this value")
        return "CoreEntityName"
    }
    
    open var keys: [String] {
        assert(false, "You must override this value")
        return [ "id", "name", "timestamp" ]
    }
    
    // MARK: - Initializers
    
    required public override init() {
        super.init()
        
        commonInit()
    }
    
    required public init(attrs: JSON) {
        super.init()
        
        for key in self.keys {
            if let value = attrs[key] {
                
                if key == "timestamp" || key == "start" || key == "lastMessageRead" || key == "submissionDate" || key == "date" || key == "end" {
                    setValue(APIClient.shared.formatter.date(from: value as! String), forKey: key)
                    continue
                } else if let double = value as? Double {
                    setValue(String(double), forKey: key)
                    continue
                } else if key == "zones" {
                    continue
                } else if let string = value as? String {
                    setValue(string, forKey: key)
                }
                
            }
        }
        
        commonInit()
    }
    
    required public init(object: NSManagedObject) {
        super.init()
        
        for key in self.keys {
            if let value = object.value(forKey: key) {
                self.setValue(value, forKey: key)
            }
        }
        
        entity = object
        
        commonInit()
    }
    
    open func commonInit() { }
    
    // MARK: - Common Properties
    
    var id: String?
    var name: String?
    var timestamp: Date?
    
    var tag: Int = -1
    var shallBeRemoved: Bool = false
    
    var photos: Photos = Photos()
    
    weak var entity: NSManagedObject?
    
    // MARK: - API Protocol Values
    
    open var createUrl: String? { return nil }
    open var createParams: JSON? { return EMPTY_JSON }
    open var retrieveUrl: String? { return nil }
    open var retrieveParams: JSON? { return EMPTY_JSON }
    open var updateUrl: String? { return nil }
    open var updateParams: JSON? { return toJson() }
    open var deleteUrl: String? { return nil }
    open var deleteParams: JSON? { return EMPTY_JSON }
    
    // MARK: - API Protocol Handlers
    
    open func processCreate(data: JSON) -> Bool { return false }
    open func processRetrieve(data: JSON) -> JSON? { return nil }
    
    // MARK: - API Protocol Methods
    
    open func create(_ callback: @escaping (_ err: Error?, _ newResult: Any?) -> Void, _ initialValue: Any?) {
        let function: String = "create"
        
        let start = Date()
        
        guard let url = createUrl, let params = createParams else {
            APIDiagnostics.shared.ERROR(_classDescription: self.descriptor,
                                        _functionDescriptor: function,
                                        _url: "nil",
                                        _params: ["initialValues": initialValue.debugDescription as JSONObject],
                                        _start: start,
                                        _error: APIClientErrors.InputError)
            callback(APIClientErrors.InputError, initialValue)
            return
        }
        
        APIClient.shared.POST(url: url, parameters: params) { (_, response, body) -> Void in
            
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
            
            guard let data = body as? JSON, self.processCreate(data: data) == true else {
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
            
            APIDiagnostics.shared.SUCCESS(_classDescription: self.descriptor,
                                          _functionDescriptor: function,
                                          _url: url,
                                          _params: params,
                                          _start: start,
                                          _body: body,
                                          _response: response)
            
            APIUpdater.shared.post(type: self.modelType, action: .Create, model: self)
            callback(nil, initialValue)
        }
    }
    
    open func retrieve(_ callback: @escaping (_ err: Error?, _ newResult: Any?) -> Void, _ initialValue: Any?) {
        let function: String = "retrieve"
        
        let start = Date()
        
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
            
            guard let data = body as? JSON, let container = self.processRetrieve(data: data), let model = container["model"]  else {
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
            
            APIDiagnostics.shared.SUCCESS(_classDescription: self.descriptor,
                                          _functionDescriptor: function,
                                          _url: url,
                                          _params: params,
                                          _start: start,
                                          _body: body,
                                          _response: response)
            
            APIUpdater.shared.post(type: self.modelType, action: .Retrieve, model: model as! APIModelProtocol)
            callback(nil, container)
        }
    }
    
    open func update(_ callback: @escaping (_ err: Error?, _ newResult: Any?) -> Void, _ initialValue: Any?) {
        let function: String = "update"
        
        let start = Date()
        
        guard let url = updateUrl, let params = updateParams else {
            APIDiagnostics.shared.ERROR(_classDescription: self.descriptor,
                                        _functionDescriptor: function,
                                        _url: "nil",
                                        _params: ["initialValues": initialValue.debugDescription as JSONObject],
                                        _start: start,
                                        _error: APIClientErrors.InputError)
            callback(APIClientErrors.InputError, initialValue)
            return
        }
        
        APIClient.shared.PUT(url: url, parameters: params) { (_, response, body) -> Void in
            
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
            
            self.saveEntity()
            
            APIDiagnostics.shared.SUCCESS(_classDescription: self.descriptor,
                                          _functionDescriptor: function,
                                          _url: url,
                                          _params: params,
                                          _start: start,
                                          _body: body,
                                          _response: response)
            
            APIUpdater.shared.post(type: self.modelType, action: .Update, model: self)
            callback(nil, initialValue)
        }
    }
    
    open func delete(_ callback: @escaping (_ err: Error?, _ newResult: Any?) -> Void, _ initialValue: Any?) {
        let function: String = "delete"
        
        let start = Date()
        
        guard let url = deleteUrl, let params = deleteParams else {
            APIDiagnostics.shared.ERROR(_classDescription: self.descriptor,
                                        _functionDescriptor: function,
                                        _url: "nil",
                                        _params: ["initialValues": initialValue.debugDescription as JSONObject],
                                        _start: start,
                                        _error: APIClientErrors.InputError)
            callback(APIClientErrors.InputError, initialValue)
            return
        }
        
        APIClient.shared.DELETE(url: url, parameters: params) { (_, response, body) -> Void in
            
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
            
            APIDiagnostics.shared.SUCCESS(_classDescription: self.descriptor,
                                          _functionDescriptor: function,
                                          _url: url,
                                          _params: params,
                                          _start: start,
                                          _body: body,
                                          _response: response)
            
            APIUpdater.shared.post(type: self.modelType, action: .Delete, model: self)
            callback(nil, initialValue)
        }
    }
    
    final func create(_ callback: @escaping (Bool) -> Void) {
        Async.waterfall(nil, [self.create]) { error, _ in
            guard error == nil else {
                callback(false)
                return
            }
            
            callback(true)
        }
    }
    
    final func update(_ callback: @escaping (Bool) -> Void) {
        Async.waterfall(nil, [self.update]) { error, _ in
            guard error == nil else {
                callback(false)
                return
            }
            
            callback(true)
        }
    }
    
    final func retrieve(_ callback: @escaping (Bool) -> Void) {
        Async.waterfall(nil, [self.retrieve]) { error, _ in
            guard error == nil else {
                callback(false)
                return
            }
            
            callback(true)
        }
    }
    
    final func delete(_ callback: @escaping (Bool) -> Void) {
        Async.waterfall(nil, [self.delete]) { error, _ in
            guard error == nil else {
                callback(false)
                return
            }
            
            callback(true)
        }
    }
    
    // MARK: - Photos Methods
    
    final func retrievePhotos(_ callback: @escaping (_ err: Error?, _ newResult: Any?) -> Void, _ initialValue: Any?) {
        
        let function: String = "retrievePhotos"
        
        let start = Date()
        
        guard let orgId = Auth.shared.orgId, let id = self.id else {
            APIDiagnostics.shared.ERROR(_classDescription: self.descriptor,
                                        _functionDescriptor: function,
                                        _url: "nil",
                                        _params: ["initialValues": initialValue.debugDescription as JSONObject],
                                        _start: start,
                                        _error: APIClientErrors.InputError)
            callback(APIClientErrors.InputError, initialValue)
            return
        }
        
        let url = String(format: "/organizations/%@/photos/retrieve/%@/%@", arguments: [orgId, self.modelType.rawValue, id])
        
        let params: JSON = EMPTY_JSON
        
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
            
            var photos = [Photo]()
            
            for value in data {
                if let photo = PhotoBucket.shared.sharedItem(attrs: value) {
                    photos.append(photo)
                }
            }
            
            self.photos.load(photos)
            
            APIDiagnostics.shared.SUCCESS(_classDescription: self.descriptor,
                                          _functionDescriptor: function,
                                          _url: url,
                                          _params: params,
                                          _start: start,
                                          _body: body,
                                          _response: response)
            
            callback(nil, initialValue)
        }
    }
    
    // MARK: - Core Data Methods
    
    final func deleteEntity() {
        DispatchQueue.main.async {
            guard let entity = self.entity, let context = entity.managedObjectContext else {
                return
            }
            
            context.delete(entity)
            self.entity = nil
            
            do {
                try context.save()
            } catch {
                // foo
            }
        }
    }
    
    final func createEntity() -> NSManagedObject? {
        guard let context = AppDelegate.managedContext, let description = NSEntityDescription.entity(forEntityName: self.entityName, in: context) else {
            return nil
        }
        
        let entity = NSManagedObject(entity: description, insertInto: context)
        
        for key in self.keys {
            if let value = self.value(forKey: key) {
                entity.setValue(value, forKey: key)
            }
        }
        
        if entity.value(forKey: "timestamp") == nil {
            entity.setValue(Date(), forKey: "timestamp")
        }
        
        do {
            try entity.managedObjectContext?.save()
            return entity
        } catch {
            return nil
        }
    }
    
    final func saveEntity() {
        DispatchQueue.main.async {
            guard let entity = self.entity else {
                return
            }
            
            for key in self.keys {
                if let value = self.value(forKey: key) {
                    entity.setValue(value, forKey: key)
                }
            }
            
            if entity.value(forKey: "timestamp") == nil {
                entity.setValue(Date(), forKey: "timestamp")
            }
            
            do {
                try entity.managedObjectContext?.save()
            } catch {
                // foo
            }
        }
    }
    
    open func cleanse() {
        self.photos.items.removeAll()
    }
    
    final func json() -> JSON {
        
        var json = JSON()
        
        for key in self.keys {
            if let value = self.value(forKey: key) {
                if let date = value as? Date {
                    json[key] = APIClient.shared.formatter.string(from: date) as JSONObject
                } else if let bool = value as? Bool {
                    json[key] = bool as JSONObject
                } else {
                    json[key] = value as JSONObject
                }
            }
        }
        
        return json
    }
    
    open func toJson() -> JSON {
        return json()
    }
    
    // MARK: - Navigation Shortcuts
    /*
    open func view() { }
    open func edit() { }
    open func create() { }
    */
}
