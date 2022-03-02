//
//  Stream.swift
//  Timeline FM
//
//  Created by Zachary DeGeorge on 7/23/18.
//  Copyright © 2018 Next Day Project. All rights reserved.
//

import Foundation
import CoreLocation

class UserStream: NSObject {
    var user: User
    
    var sheet: Sheet? {
        set {
            if let previous = user.sheet {
                if previous.entries.loaded == false || previous.id != newValue?.id {
                    user.sheet = newValue
                }
            } else {
                user.sheet = newValue
                
                if newValue == nil {
                    self.entry = nil
                    self.breadcrumb = nil
                }
            }
        } get {
            return user.sheet
        }
    }
    
    var entry: Entry?
    var breadcrumb: Breadcrumb?
    
    init(user: User) {
        self.user = user
    }
}

class Stream: NSObject {
    static var description: String = "Stream"
    static var modelType: ModelType = ModelType.Stream
    
    typealias Item = UserStream
    
    static let shared: Stream = Stream()
    
    var items: [Item] = [Item]()
    
    func initialize() {
        Notifications.shared.loaded_true.observe(self, selector: #selector(isLoaded))
    }
    
    subscript(id: String?) -> Item? {
        guard let id = id else {
            return nil
        }
        
        let matches = self.items.filter({(item) -> Bool in
            return item.user.id == id
        })
        
        if matches.count > 0 {
            return matches[0]
        }
        
        return nil
    }
    
    func retrieve(_ callback: @escaping (_ err: Error?, _ newResult: Any?) -> Void, _ initialValue: Any?) {
        let function: String = "retrieve"
        
        let start = Date()
        
        guard Users.shared.count > 0 else {
            callback(nil, initialValue)
            return
        }
        
        guard let orgId = Auth.shared.orgId else {
            APIDiagnostics.shared.ERROR(_classDescription: type(of: self).description,
                                        _functionDescriptor: function,
                                        _url: "nil",
                                        _params: [:],
                                        _start: start,
                                        _error: APIClientErrors.InternalError)
            callback(nil, initialValue)
            return
        }
        
        let url = String(format: "/organizations/%@/active", arguments: [orgId])
        let params = EMPTY_JSON
        
        APIClient.shared.POST(url: url, parameters: params) { (error, response, body) in
            guard response?.statusCode == 200 else {
                APIDiagnostics.shared.ERROR(_classDescription: type(of: self).description,
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
                APIDiagnostics.shared.ERROR(_classDescription: type(of: self).description,
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
            
            var returnedUsers: [User] = [User]()
            
            for datum in data {
                
                if let userData = datum["user"] as? JSON, let userId = userData["id"] as? String, let user = userId == Auth.shared.id ? DeviceUser.shared.user : Users.shared[userId] {
                    
                    returnedUsers.append(user)
                    
                    let previous: Bool = self[userId] != nil
                    
                    let userStream = previous == false ? UserStream(user: user) : self[userId]!
                    
                    if let sheetAttrs = datum["sheet"] as? JSON {
                        userStream.sheet = Sheet(attrs: sheetAttrs)
                    }
                    
                    if let entryAttrs = datum["entry"] as? JSON {
                        userStream.entry = Entry(attrs: entryAttrs)
                    }
                    
                    if let crumbAttrs = datum["breadcrumb"] as? JSON {
                        userStream.breadcrumb = Breadcrumb(attrs: crumbAttrs)
                    }
                    
                    if previous == false {
                        self.items.append(userStream)
                    }
                    
                    let userInfo: JSON = [
                        "userStream" : userStream as JSONObject
                    ]
                    
                    if let subscription = Subscriptions.shared.get(userId: user.id) {
                        subscription.sheet = userStream.sheet
                        subscription.entry = userStream.entry
                        subscription.breadcrumb = userStream.breadcrumb
                    }
                    
                    NotificationManager.shared.user_stream_updated.post(userInfo)
                }
            }
            
            let matches = self.items.filter({ (item) -> Bool in
                for user in returnedUsers {
                    if user.id == item.user.id {
                        return true
                    }
                }
                
                return false
            })
            
            self.items.removeAll()
            self.items = matches
            
            APIDiagnostics.shared.SUCCESS(_classDescription: type(of: self).description,
                                          _functionDescriptor: function,
                                          _url: url,
                                          _params: params,
                                          _start: start,
                                          _body: body,
                                          _response: response)
             
            callback(nil, initialValue)
        }
    }
    
    @objc func isLoaded(_ notification: NSNotification) {
        DispatchQueue.main.async {
            Async.waterfall(nil, [Stream.shared.retrieve], end: { _, _ in })
        }
    }
}
