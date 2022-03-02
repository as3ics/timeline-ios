//
//  Message.swift
//  Timesheets
//
//  Created by Zachary DeGeorge on 5/21/18.
//  Copyright © 2018 Next Day Project. All rights reserved.
//

import Foundation
import CoreLocation
import CoreData

enum MessageKind: String {
    case Text = "TEXT"
    case Photo = "PHOTO"
    case Video = "VIDEO"
    case System = "SYSTEM"
}

@objcMembers class Messages: APIContainer<Message> {

    override var modelType: ModelType {
        return ModelType.Messages
    }
    
    override var descriptor: String {
        return "Messages"
    }

    static let defaultLimit: Int = 50

    weak var chatroom: Chatroom?
    var startDate: Date?
    var endDate: Date?

    convenience init(_ chatroom: Chatroom) {
        self.init()

        self.chatroom = chatroom
    }

    subscript(date: Date?) -> Item? {
        guard let date = date else {
            return nil
        }

        let matches = items.filter({ (item) -> Bool in
            return item.timestamp == date
        })

        return matches.first
    }
    
    // MARK: - API Protocol Constructors
    
    override var retrieveUrl: String? {
        guard let orgId = Auth.shared.orgId, let chatroomId = self.chatroom?.id else {
            return nil
        }
        
        return String(format: "/organizations/%@/chatrooms/%@/messages", arguments: [orgId, chatroomId])
    }
    
    override var retrieveParams: JSON? {
        var params: JSON = [
            "limit": type(of: self).defaultLimit as JSONObject,
            ]
        
        if let startDate = self.startDate { params["startDate"] = APIClient.shared.formatter.string(from: startDate) as JSONObject }
        if let endDate = self.endDate { params["endDate"] = APIClient.shared.formatter.string(from: endDate) as JSONObject }
        
        return params
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
        
        self.chatroom?.latestMessage = items.first
        
        callback(nil, nil)
    }

    func retrieveMore(_ callback: @escaping (_ err: Error?, _ newResult: Any?) -> Void, _ initialValue: Any?) {
        let function: String = "retrieveMore"

        let start = Date()

        guard let fromDate = self.items.last?.timestamp, let orgId = Auth.shared.orgId, let chatId = self.chatroom?.id else {
            APIDiagnostics.shared.ERROR(_classDescription: self.descriptor,
                                        _functionDescriptor: function,
                                        _url: "nil",
                                        _params: EMPTY_JSON,
                                        _start: start,
                                        _error: APIClientErrors.InputError)
            callback(APIClientErrors.InputError, initialValue)
            return
        }

        let url = String(format: "/organizations/%@/chatrooms/%@/messages", arguments: [orgId, chatId])

        let params: JSON = [
            "limit": type(of: self).defaultLimit as JSONObject,
            "endDate": APIClient.shared.formatter.string(from: fromDate) as JSONObject,
        ]

        APIClient.shared.GET(url: url, parameters: params) { _, response, body in

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

            var messages = [Message]()

            for value in data {
                let message = Message(attrs: value)
                messages.append(message)
                self.items.append(message)
            }

            let container: JSON = [
                "messages": messages as JSONObject,
            ]

            APIDiagnostics.shared.SUCCESS(_classDescription: self.descriptor,
                                          _functionDescriptor: function,
                                          _url: url,
                                          _params: params,
                                          _start: start,
                                          _body: body,
                                          _response: response)

            callback(nil, container)
        }
    }

    func retrieveNew(_ callback: @escaping (_ err: Error?, _ newResult: Any?) -> Void, _ initialValue: Any?) {
        let function: String = "retrieveNew"

        let start = Date()
        
        var container: JSON!
        if let _container = initialValue as? JSON {
            container = _container
        } else {
            let messages: [Message] = [Message]()
            
            container = [
                "count": 0 as JSONObject,
                "messages": messages as JSONObject,
            ]
        }

        guard let orgId = Auth.shared.orgId, let chatroomId = self.chatroom?.id, let timestamp = self.chatroom?.latestMessage?.timestamp, var previousMessages = container["messages"] as? [Message] else {
            APIDiagnostics.shared.ERROR(_classDescription: self.descriptor,
                                        _functionDescriptor: function,
                                        _url: "nil",
                                        _params: EMPTY_JSON,
                                        _start: start,
                                        _error: APIClientErrors.InputError)
            callback(nil, initialValue)
            return
        }

        let url = String(format: "/organizations/%@/chatrooms/%@/messages", arguments: [orgId, chatroomId])

        let params: JSON = [
            "startDate": APIClient.shared.formatter.string(from: timestamp) as JSONObject,
        ]

        APIClient.shared.GET(url: url, parameters: params) { _, response, body in

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

            var messages = [Message]()

            for value in data {
                let message = Message(attrs: value)

                if message.incoming == true, message.messageKind != MessageKind.System {
                    messages.append(message)
                    self.add(message, sort: false, insert: true)
                }
            }

            if messages.count > 0 {
                self.chatroom?.latestMessage = messages.first

                for message in messages {
                    previousMessages.append(message)
                }
            }

            let container: JSON = [
                "count": previousMessages.count as JSONObject,
                "messages": previousMessages as JSONObject,
            ]

            APIDiagnostics.shared.SUCCESS(_classDescription: self.descriptor,
                                          _functionDescriptor: function,
                                          _url: url,
                                          _params: params,
                                          _start: start,
                                          _body: body,
                                          _response: response)

            callback(nil, container)
        }
    }

    func retrievePhotos(_ callback: @escaping (_ err: Error?, _ newResult: Any?) -> Void, _ initialValue: Any?) {
        let function: String = "retrievePhotos"

        let start = Date()

        guard let orgId = Auth.shared.orgId, let chatId = self.chatroom?.id else {
            APIDiagnostics.shared.ERROR(_classDescription: self.descriptor,
                                        _functionDescriptor: function,
                                        _url: "nil",
                                        _params: EMPTY_JSON,
                                        _start: start,
                                        _error: APIClientErrors.InputError)
            callback(nil, initialValue)
            return
        }

        let url = String(format: "/organizations/%@/chatrooms/%@/messages/images", arguments: [orgId, chatId])

        let params: JSON = [
            "limit": 20 as JSONObject,
        ]

        APIClient.shared.GET(url: url, parameters: params) { _, response, body in

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

            var messages = [Message]()

            for value in data {
                let message = Message(attrs: value)
                if message.messageKind == MessageKind.Photo {
                    messages.append(message)
                }
            }

            let container: JSON = [
                "messages": messages as JSONObject,
            ]

            APIDiagnostics.shared.SUCCESS(_classDescription: self.descriptor,
                                          _functionDescriptor: function,
                                          _url: url,
                                          _params: params,
                                          _start: start,
                                          _body: body,
                                          _response: response)

            callback(nil, container)
        }
    }

    func retrieveMoreMessages(fromDate: Date?, _ callback: @escaping (_ success: Bool, _ messages: [Message]?) -> Void) {
        let function: String = "retrieveMoreMessages"

        let start = Date()

        guard let organizationId = Auth.shared.orgId, let chatroomId = self.chatroom?.id, let date = fromDate else {
            APIDiagnostics.shared.ERROR(_classDescription: self.descriptor,
                                        _functionDescriptor: function,
                                        _url: "nil",
                                        _params: EMPTY_JSON,
                                        _start: start,
                                        _error: APIClientErrors.InputError)
            callback(false, nil)
            return
        }

        if let last = self.chatroom?.messages.items.last?.timestamp {
            if date < last {
                callback(false, nil)
                return
            }
        }

        let url = String(format: "/organizations/%@/chatrooms/%@/messages", arguments: [organizationId, chatroomId])

        var params: Dictionary<String, AnyObject> = [
            "limit": 50 as AnyObject,
        ]

        if let fromDate = fromDate { params["endDate"] = APIClient.shared.formatter.string(from: fromDate) as AnyObject }

        APIClient.shared.GET(url: url, parameters: params) { _, response, body in

            guard response?.statusCode == 200 else {
                APIDiagnostics.shared.ERROR(_classDescription: self.descriptor,
                                            _functionDescriptor: function,
                                            _url: url,
                                            _params: params,
                                            _start: start,
                                            _error: APIClientErrors.StatusError,
                                            _response: response,
                                            _body: body)
                callback(false, nil)
                return
            }

            guard let resp = body as? [[String: AnyObject]] else {
                APIDiagnostics.shared.ERROR(_classDescription: self.descriptor,
                                            _functionDescriptor: function,
                                            _url: url,
                                            _params: params,
                                            _start: start,
                                            _error: APIClientErrors.DataError,
                                            _response: response,
                                            _body: body)
                callback(false, nil)
                return
            }

            var _messages = [Message]()

            for value in resp {
                let message = Message(attrs: value)
                _messages.append(message)
                self.items.append(message)
            }

            APIDiagnostics.shared.SUCCESS(_classDescription: self.descriptor,
                                          _functionDescriptor: function,
                                          _url: url,
                                          _params: params,
                                          _start: start,
                                          _body: body,
                                          _response: response)
            callback(true, _messages)
        }
    }

    func insert(_ value: Any?) {
        guard let item = value as? Item, self[item.id] == nil else {
            return
        }

        items.insert(item, at: 0)
        sort()
        
        chatroom?.latestMessage = item
    }

    override func sort() {
        items.sort(by: { $0.timestamp! > $1.timestamp! })
    }
}

@objcMembers class Message: APIModel {
    override var descriptor: String {
        return "Message"
    }
    
    override var modelType: ModelType {
        return ModelType.Location
    }
    
    override var entityName: String {
        return "CoreMessage"
    }
    
    override var keys: [String] {
        return [ "id", "name", "organization", "chatroom", "photo", "content", "kind", "timestamp" ]
    }

    var organization: String?
    var chatroom: String?
    var user: String?
    var photo: String?
    var content: String?
    var kind: String?
    
    var messageKind: MessageKind? {
        get {
            guard let kind = self.kind else {
                return nil
            }
            
            return MessageKind(rawValue: kind)
        } set {
            
            guard let value = newValue else {
                return
            }
            
            self.kind = value.rawValue
        }
    }
    
    var image: Photo?
    
    required init() {
        super.init()
    }
    
    required init(attrs: JSON) {
        super.init(attrs: attrs)
        
        if let userAttrs = attrs["user"] as? JSON, let userId = userAttrs["id"] as? String {
            self.user = userId
        }
    }
    
    required public init(object: NSManagedObject) {
        super.init(object: object)
        
    }
    

    var incoming: Bool {
        guard let id = self.user, let userId = Auth.shared.id else {
            return false
        }

        return userId != id
    }
    
    override var createUrl: String? {
        guard let orgId = Auth.shared.orgId, let chatId = self.chatroom else {
            return nil
        }
        
        return String(format: "/organizations/%@/chatrooms/%@/messages", arguments: [orgId, chatId])
    }
    
    override var createParams: JSON? {
        guard let userId = Auth.shared.id else {
            return nil
        }
        
        var chatUser: JSON = [
            "id": userId as JSONObject,
            ]
        
        if let firstName = DeviceUser.shared.user?.firstName { chatUser["firstName"] = firstName as JSONObject }
        if let lastName = DeviceUser.shared.user?.lastName { chatUser["lastName"] = lastName as JSONObject }
        
        var params: JSON = json()
        
        params["user"] = chatUser as JSONObject
        params["createdBy"] = userId as JSONObject
        
        if let photo = self.photo { params["photo"] = photo as JSONObject }
        return params
    }
    
    override func processCreate(data: JSON) -> Bool {
        guard let id = data["id"] as? String else {
            return false
        }
        
        self.id = id
        self.user = Auth.shared.id
        
        return true
    }

    override func toJson() -> JSON {
        var _json = json()
        
        if let timestamp = self.timestamp {
            _json["timestamp"] = APIClient.shared.formatter.string(from: timestamp) as JSONObject
        }
        
        return _json
    }
}
