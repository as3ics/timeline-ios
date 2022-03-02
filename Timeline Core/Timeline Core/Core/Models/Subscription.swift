//
//  Subscription.swift
//  Timeline FM
//
//  Created by Zachary DeGeorge on 7/21/18.
//  Copyright © 2018 Next Day Project. All rights reserved.
//

import Foundation
import SocketIO
import MapKit
import CoreLocation
import UIKit

class Subscriptions: NSObject {
    static var descriptor: String = "Subscriptions"
    static var modelType: ModelType = ModelType.Subscriptions
    
    static let shared = Subscriptions()
    
    typealias Item = Subscription
    
    var items: [Item] = [Item]()
    
    func get(userId: String?) -> Item? {
        guard let id = userId else { return nil}
        
        let matches = self.items.filter({ (item) -> Bool in
            return item.user == id
        })
        
        guard matches.count <= 1 else {
            for (index, item) in self.items.enumerated() {
                if matches.contains(item) {
                    item.coordinate = nil
                    items.remove(at: index)
                }
            }
            
            return nil
        }
        
        return matches.first
    }
    
    func isSubscribed(_ user: User?) -> Bool {
        guard let user = user else {
            return false
        }
        
        let matches = self.items.filter({ (subscription) -> Bool in
            return subscription.user == user.id
        })
        
        return matches.count > 0
    }
    
    func subscribe(_ users: [String]?, _ callback: @escaping(_ success: Bool) -> ()) {
        
        let function: String = "subscribe"
        
        let start = Date()
        
        guard let orgId = Auth.shared.orgId, let userId = Auth.shared.id, let users = users else {
            APIDiagnostics.shared.ERROR(_classDescription: type(of: self).descriptor,
                                        _functionDescriptor: function,
                                        _url: "nil",
                                        _params: EMPTY_JSON,
                                        _start: start,
                                        _error: APIClientErrors.InputError)
            callback(false)
            return
        }
        
        let url = String(format: "/organizations/%@/users/%@/subscribe", arguments: [orgId, userId])
        
        let params: JSON = [
            "users": users as JSONObject
        ]
        
        APIClient.shared.POST(url: url, parameters: params) { (error, response, body) in
            guard response?.statusCode == 200 else {
                APIDiagnostics.shared.ERROR(_classDescription: type(of: self).descriptor,
                                            _functionDescriptor: function,
                                            _url: url,
                                            _params: params,
                                            _start: start,
                                            _error: APIClientErrors.StatusError,
                                            _response: response,
                                            _body: body)
                callback(false)
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
                callback(false)
                return
            }
            
            for value in data {
                let subscription = Subscription()
                
                subscription.following = true
                
                if let userData = value["user"] as? JSON, let id = userData["id"] as? String {
                    subscription.user = id
                } else {
                    continue
                }
                
                if let sheetData = value["sheet"] as? JSON {
                    subscription.sheet = Sheet(attrs: sheetData)
                }
                
                if let entryData = value["entry"] as? JSON {
                    subscription.entry = Entry(attrs: entryData)
                }
                
                if let breadcrumbData = value["breadcrumb"] as? JSON {
                    subscription.breadcrumb = Breadcrumb(attrs: breadcrumbData)
                }
                
                self.items.append(subscription)
            }
            
            APIDiagnostics.shared.SUCCESS(_classDescription: type(of: self).descriptor,
                                          _functionDescriptor: function,
                                          _url: url,
                                          _params: params,
                                          _start: start,
                                          _body: body,
                                          _response: response)
            
            for userId in users {
                if let user = Users.shared[userId] {
                    user.focus()
                }
            }
            
            callback(true)
        }
    }
    
    func unsubscribe(_ users: [String]?, _ callback: @escaping(_ success: Bool) -> ()) {
        
        let function: String = "unsubscribe"
        
        let start = Date()
        
        guard let orgId = Auth.shared.orgId, let userId = Auth.shared.id, let users = users else {
            APIDiagnostics.shared.ERROR(_classDescription: type(of: self).descriptor,
                                        _functionDescriptor: function,
                                        _url: "nil",
                                        _params: EMPTY_JSON,
                                        _start: start,
                                        _error: APIClientErrors.InputError)
            callback(false)
            return
        }
        
        let url = String(format: "/organizations/%@/users/%@/unsubscribe", arguments: [orgId, userId])
        
        let params: JSON = [
            "users": users as JSONObject
        ]
        
        APIClient.shared.POST(url: url, parameters: params) { (error, response, body) in
            guard response?.statusCode == 200 else {
                APIDiagnostics.shared.ERROR(_classDescription: type(of: self).descriptor,
                                            _functionDescriptor: function,
                                            _url: url,
                                            _params: params,
                                            _start: start,
                                            _error: APIClientErrors.StatusError,
                                            _response: response,
                                            _body: body)
                callback(false)
                return
            }
            
            guard let _ = body as? [JSON] else {
                APIDiagnostics.shared.ERROR(_classDescription: type(of: self).descriptor,
                                            _functionDescriptor: function,
                                            _url: url,
                                            _params: params,
                                            _start: start,
                                            _error: APIClientErrors.DataError,
                                            _response: response,
                                            _body: body)
                callback(false)
                return
            }
            
            for i in 1 ... users.count {
                let index = users.count - i
                guard index < users.count else {
                    break
                }
                
                let userId = users[index]
                
                for (index, item) in self.items.enumerated() {
                    if item.user == userId {
                        self.items.remove(at: index)
                        break
                    }
                }
            }
            
            APIDiagnostics.shared.SUCCESS(_classDescription: type(of: self).descriptor,
                                          _functionDescriptor: function,
                                          _url: url,
                                          _params: params,
                                          _start: start,
                                          _body: body,
                                          _response: response)
            
            
            for id in users {
                Notifications.shared.map_focus_user.post(["user": id as JSONObject])
            }
            
            Notifications.shared.socket_reload_rooms.post()
            callback(true)
        }
    }
    
    
    func retrieve(_ user: String?, _ callback: @escaping(_ success: Bool) -> ()) {
        
        let function: String = "retrieve"
        
        let start = Date()
        
        guard let orgId = Auth.shared.orgId, let userId = user else {
            APIDiagnostics.shared.ERROR(_classDescription: type(of: self).descriptor,
                                        _functionDescriptor: function,
                                        _url: "nil",
                                        _params: EMPTY_JSON,
                                        _start: start,
                                        _error: APIClientErrors.InputError)
            callback(false)
            return
        }
        
        let url = String(format: "/organizations/%@/users/%@/subscription", arguments: [orgId, userId])
        
        let params: JSON = EMPTY_JSON
        
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
                callback(false)
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
                callback(false)
                return
            }
            
            for value in data {
                let subscription = Subscriptions.shared.get(userId: userId) ?? Subscription()
                
                if let userData = value["user"] as? JSON, let id = userData["id"] as? String {
                    subscription.user = id
                } else {
                    continue
                }
                
                if let sheetData = value["sheet"] as? JSON {
                    subscription.sheet = Sheet(attrs: sheetData)
                }
                
                if let entryData = value["entry"] as? JSON {
                    subscription.entry = Entry(attrs: entryData)
                }
                
                if let breadcrumbData = value["breadcrumb"] as? JSON {
                    subscription.breadcrumb = Breadcrumb(attrs: breadcrumbData)
                }
                
                if Subscriptions.shared.get(userId: userId) == nil {
                    if let data = subscription.join(Socket.shared.socket) {
                        Socket.shared.connections.append(data)
                        Subscriptions.shared.items.append(subscription)
                    } else {
                        callback(false)
                        return
                    }
                }
                
                delay(0.2) {
                    Notifications.shared.map_focus_user.post(["user": userId as JSONObject])
                }
            }
            
            APIDiagnostics.shared.SUCCESS(_classDescription: type(of: self).descriptor,
                                          _functionDescriptor: function,
                                          _url: url,
                                          _params: params,
                                          _start: start,
                                          _body: body,
                                          _response: response)
            
            callback(true)
        }
    }
    
    @objc func subscribeAll(_ callback: @escaping(_ success: Bool) -> ()) {
        
        var users: [String] = [String]()
        
        for item in Users.shared.items {
            if let userId = item.id {
                users.append(userId)
            }
        }
        
        subscribe(users) { (success) in
            callback(success)
        }
    }
    
    @objc func unsubscribeAll(_ callback: @escaping(_ success: Bool) -> ()) {
        
        var users: [String] = [String]()
        
        for item in self.items {
            if let userId = item.user {
                users.append(userId)
            }
        }
        
        unsubscribe(users) { (success) in
            callback(success)
        }
    }
}


@objc class Subscription: NSObject {
    
    static var descriptor: String = "Subscription"
    static var modelType: ModelType = ModelType.Subscription
    
    var id: String?
    var name: String?
    var timestamp: Date?
    var tag: Int = -1
    
    var user: String?
    var following: Bool?
    
    var entry: Entry? {
        didSet {
            if let entry = entry {
                if let location = entry.location {
                    coordinate = location.coordinate?.offset(metersX: 15.0, metersY: -15.0)
                } else if entry.activity?.breaking == true {
                    coordinate = nil
                }
            }
        }
    }
    
    var breadcrumb: Breadcrumb? {
        didSet {
            if let breadcrumb = breadcrumb {
                if let entry = entry {
                    if let timestamp = breadcrumb.timestamp, timestamp > entry.start ?? Date() {
                        coordinate = breadcrumb.location?.coordinate
                    }
                } else {
                    coordinate = breadcrumb.location?.coordinate
                }
            }
        }
    }
    
    var sheet: Sheet? {
        willSet {
            if newValue == nil {
                sheet?.cleanse()
            }
        }
    }
    
    convenience init(attrs: JSON) {
        self.init()
        
        self.id = attrs["_id"] as? String
        self.user = attrs["user"] as? String
        self.following = attrs["following"] as? Bool
    }
    
    var coordinate: CLLocationCoordinate2D? {
        didSet {
            NotificationManager.shared.user_subscription_updated.post(["user" : user! as JSONObject])
        }
    }
    
    @objc dynamic var annotation: UserAnnotation?
    
    var status: SystemState {
        if sheet == nil {
            return SystemState.Off
        } else if sheet != nil && entry == nil {
            return SystemState.Empty
        } else if entry?.activity?.traveling == true {
            return SystemState.Traveling
        } else if entry?.activity?.breaking == true {
            return SystemState.Break
        } else if sheet != nil && entry != nil {
            return SystemState.LoggedIn
        } else {
            return SystemState.Error
        }
    }
    
    var location: Location? {
        guard status == .LoggedIn else {
            return nil
        }
        
        return Locations.shared[entry?.location?.id]
    }
    
    func leave(_ socket: SocketIOClient) -> JSON? {
        
        guard let userId = self.user else {
            return nil
        }
        
        let data: JSON = [
            "room": "user" as JSONObject,
            "user": Auth.shared.id! as JSONObject,
            "roomid": userId as JSONObject
        ]
        
        socket.emit("socket-leave", data)
        return data
    }
    
    func join(_ socket: SocketIOClient) -> JSON? {
        
        guard let userId = self.user else {
            return nil
        }
        
        let data: JSON = [
            "room": "user" as JSONObject,
            "user": userId as JSONObject,
            "roomid": userId as JSONObject
        ]
        
        socket.emit("socket-join", data)
        return data
    }
    
    func toJson() -> JSON {
        return EMPTY_JSON
    }
}

