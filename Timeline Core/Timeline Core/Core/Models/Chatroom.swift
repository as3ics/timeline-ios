//
//  Chatroom.swift
//  Timesheets
//
//  Created by Zachary DeGeorge on 5/17/18.
//  Copyright © 2018 Next Day Project. All rights reserved.
//

import ChattoAdditions
import Foundation
import SocketIO
import CoreLocation
import CoreData
import IQKeyboardManagerSwift

// MARK: - Chatrooms

@objcMembers class Chatrooms: APIContainer<Chatroom>, APIContainerSingletonProtocol {
    
    // MARK: - API Container
    
    typealias Shared = Chatrooms

    static var shared = Shared()
    
    // MARK: - Descriptors

    override var modelType: ModelType {
        return ModelType.Chatrooms
    }
    
    override var descriptor: String {
        return "Chatrooms"
    }
    
    // MARK: Other Properties

    static var connectedChatroom: Chatroom?
    
    var unreadMessages: Int {
        var count: Int = 0
        for chatroom in items {
            count = count + chatroom.unreadMessages
        }
        return count
    }
    
    
    var groups: [Chatroom] {
        sort()
        let chatrooms = items.filter { (chatroom) -> Bool in
            chatroom.chatUsers.count > 1
        }
        
        return chatrooms
    }
    
    var chats: [Chatroom] {
        sort()
        let chats = items.filter { (chatroom) -> Bool in
            chatroom.chatUsers.count == 1
        }
        
        return chats
    }
    
    // MARK: - API Protocol Values
    
    override var retrieveUrl: String? {
        guard let orgId = Auth.shared.orgId else {
            return nil
        }
        
        return String(format: "/organizations/%@/chatrooms", arguments: [orgId])
    }
    
    override var retrieveParams: JSON? {
        guard let userId = Auth.shared.id else {
            return nil
        }
        
        let params: JSON = [
            "user": userId as JSONObject,
            ]
        
        return params
    }
    
    // MARK: - API Protocol Handlers
    
    override func process(_ callback: @escaping (_ err: Error?, _ newResult: Any?) -> Void, _ initialValue: Any?) {
        
        guard let data = initialValue as? [JSON] else {
            callback(nil, nil)
            return
        }
        
        var queries = [(@escaping (Error?, Any?) -> (), Any?) -> ()]()
        
        self.items.removeAll()
        
        for value in data {
            let item = Item(attrs: value)
            queries.append(item.messages.retrieve)
            queries.append(item.retrievePhotos)
            self.items.append(item)
        }
        
        Async.waterfall(nil, queries, end: { (_, _) in
            Notifications.shared.updateBadge()
            callback(nil, nil)
        })
    }
    
    override func synchronize(_ callback: @escaping (Error?, Any?) -> Void, _ initialValue: Any?) {
        
        var queries = [(@escaping (Error?, Any?) -> (), Any?) -> ()]()
        
        
        for chatroom in self.items {
            queries.append(chatroom.messages.retrieveNew)
        }
        
        Async.waterfall(nil, queries, end: {  _, _ in
            // foo
            callback(nil, nil)
        })
    }

    // MARK: - Other Methods
    
    override func sort() {
        items.sort(by: { $1.latestMessage?.timestamp ?? Date() < $0.latestMessage?.timestamp ?? Date() })
    }
}

// MARK: - Chatroom

@objcMembers class Chatroom: APIModel, AssetsProtocol {
    
    // MARK: - Descriptors
    
    override var descriptor: String {
        return "Chatroom"
    }
    
    override var modelType: ModelType {
        return ModelType.Chatroom
    }
    
    override var keys: [String] {
        return [ "id", "name", "timestamp", "organization", "purpose" ]
    }
    
    // MARK: - Asset Properties
    
    static var assetKeys: [String] = [ "Cell" ]
    
    var assets: JSON = JSON()

    // MARK: - Other Properties
    
    var organization: String?
    var purpose: String?
    
    var latestMessage: Message?
    var lastMessageRead: Date?
    var listening: Bool = false

    var messages: Messages!
    var chatUsers = ChatUsers()
    var users = [User]()
    
    var unreadMessages: Int {
        guard let lastSeenTime = self.lastMessageRead else {
            return self.messages.count
        }
        
        let messages = self.messages.items.filter({ (message) -> Bool in
            guard let messageTime = message.timestamp, let userId = message.user, userId != Auth.shared.id else {
                return false
            }
            
            return messageTime > lastSeenTime
        })
        
        return messages.count
    }
    
    // MARK: - Initializers
    
    required init() {
        super.init()
    }

    required init(attrs: JSON) {
        super.init(attrs: attrs)
        
        guard let users = attrs["users"] as? [JSON] else {
            return
        }
        
        for user in users {
            let chatUser = ChatUser(attrs: user)
            if let userId = chatUser.user?.id {
                if userId != Auth.shared.id {
                    chatUsers.append(chatUser)
                } else {
                    lastMessageRead = chatUser.lastMessageRead
                }
            }
        }
    }
    
    required public init(object: NSManagedObject) {
        super.init(object: object)
    }
    
    override func commonInit() {
        super.commonInit()
        
        messages = Messages(self)
    }
    
    
    // MARK: - API Protocol Values
    
    override var createUrl: String? {
        guard self.users.count >= 2, let orgId = Auth.shared.orgId else {
            return nil
        }
        
        return String(format: "/organizations/%@/chatrooms", arguments: [orgId])
    }
    
    override var createParams: JSON? {
        guard self.users.count >= 2, let name = self.name, let createdBy = Auth.shared.id else {
            return nil
        }
        
        var userIds = [String]()
        for user in users {
            if let id = user.id {
                userIds.append(id)
            }
        }
        
        var params: JSON = [
            "name": name as JSONObject,
            "users": userIds as JSONObject,
            "createdBy": createdBy as JSONObject
            ]
        
        if let purpose = self.purpose {
            params["purpose"] = purpose as JSONObject
        }
        
        return params
    }
    
    override func processCreate(data: JSON) -> Bool {
        guard let id = data["id"] as? String else {
            return false
        }
        
        self.id = id
        
        Async.waterfall(nil, [self.retrieve], end: { _, _ in })
        
        return true
    }

    override var retrieveUrl: String? {
        guard let orgId = Auth.shared.orgId, let id = self.id else {
            return nil
        }
        
        return String(format: "/organizations/%@/chatrooms/%@", arguments: [orgId, id])
    }
    
    override func processRetrieve(data: JSON) -> JSON? {
        let chatroom = Chatroom(attrs: data)
        
        Async.waterfall(nil, [chatroom.messages.retrieve], end: { _, _ in })
        
        let container: JSON = [
            "model": chatroom as JSONObject,
            ]
        
        return container
    }
    
    override var updateUrl: String? {
        guard users.count >= 2, let orgId = Auth.shared.orgId, let id = self.id else {
            return nil
        }
        
        return String(format: "/organizations/%@/chatrooms/%@", arguments: [orgId, id])
    }
    
    override var updateParams: JSON? {
        guard var params: JSON = createParams, let createdBy = Auth.shared.id else {
            return nil
        }
        
        params["updatedBy"] = createdBy as JSONObject
        return params
    }

    override var deleteUrl: String? {
        guard let orgId = Auth.shared.orgId, let id = self.id else {
            return nil
        }
        
        return String(format: "/organizations/%@/chatrooms/%@", arguments: [orgId, id])
    }
    
    // MARK: - Other Methods

    func leaveChatroom(_ callback: @escaping (_ err: Error?, _ newResult: Any?) -> Void, _ initialValue: Any?) {
        let function: String = "leaveChatroom"

        let start = Date()

        guard let orgId = Auth.shared.orgId, let id = self.id, let userId = Auth.shared.id else {
            APIDiagnostics.shared.ERROR(_classDescription: self.descriptor,
                                        _functionDescriptor: function,
                                        _url: "nil",
                                        _params: EMPTY_JSON,
                                        _start: start,
                                        _error: APIClientErrors.InputError)
            callback(APIClientErrors.InputError, initialValue)
            return
        }

        let url = String(format: "/organizations/%@/chatrooms/%@/users/%@", arguments: [orgId, id, userId])

        let params: JSON = [
            "connected": false as JSONObject,
        ]

        APIClient.shared.PUT(url: url, parameters: params) { _, response, body in

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

            callback(nil, initialValue)
        }
    }

    func joinChatroom(_ callback: @escaping (_ err: Error?, _ newResult: Any?) -> Void, _ initialValue: Any?) {
        let function: String = "leaveChatroom"

        let start = Date()

        guard let orgId = Auth.shared.orgId, let id = self.id, let userId = Auth.shared.id else {
            APIDiagnostics.shared.ERROR(_classDescription: self.descriptor,
                                        _functionDescriptor: function,
                                        _url: "nil",
                                        _params: EMPTY_JSON,
                                        _start: start,
                                        _error: APIClientErrors.InputError)
            callback(APIClientErrors.InputError, initialValue)
            return
        }

        let url = String(format: "/organizations/%@/chatrooms/%@/users/%@", arguments: [orgId, id, userId])

        let params: JSON = [
            "connected": true as JSONObject,
        ]

        APIClient.shared.PUT(url: url, parameters: params) { _, response, body in

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

            callback(nil, initialValue)
        }
    }

    func reloadUsers(_ callback: @escaping (_ err: Error?, _ newResult: Any?) -> Void, _ initialValue: Any?) {
        let function: String = "reloadUsers"

        let start = Date()

        guard let orgId = Auth.shared.orgId, let id = self.id else {
            APIDiagnostics.shared.ERROR(_classDescription: self.descriptor,
                                        _functionDescriptor: function,
                                        _url: "nil",
                                        _params: EMPTY_JSON,
                                        _start: start,
                                        _error: APIClientErrors.InputError)
            callback(APIClientErrors.InputError, initialValue)
            return
        }

        let url = String(format: "/organizations/%@/chatrooms/%@", arguments: [orgId, id])

        let params: JSON = EMPTY_JSON

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

            guard let data = body as? JSON, let users = data["users"] as? [JSON] else {
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
            
            var chatUsers = [ChatUser]()
            
            for user in users {
                let user = ChatUser(attrs: user)
                if user.user?.id == Auth.shared.id {
                    self.lastMessageRead = user.lastMessageRead
                } else if let chatUser = self.chatUsers[user.user?.id] {
                    user.typing = chatUser.typing
                    user.index = chatUser.index
                    chatUsers.append(user)
                }
            }

            self.chatUsers.chatUsers.removeAll()

            for chatUser in chatUsers {
                self.chatUsers.append(chatUser)
            }

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

    override func toJson() -> JSON {
        return JSON()
    }
}

// MARK: - Chatroom Extension

extension Chatroom {
    
    func updateUserStatus(_ connected: Bool, _ callback: @escaping (_ success: Bool) -> Void) {
        let function: String = "updateUserStatus"

        let start = Date()

        guard let organizationId = Auth.shared.orgId, let chatroomId = self.id, let userId = Auth.shared.id else {
            APIDiagnostics.shared.ERROR(_classDescription: self.descriptor,
                                        _functionDescriptor: function,
                                        _url: "nil",
                                        _params: EMPTY_JSON,
                                        _start: start,
                                        _error: APIClientErrors.InputError)
            callback(false)
            return
        }

        let url = String(format: "/organizations/%@/chatrooms/%@/users/%@", arguments: [organizationId, chatroomId, userId])

        let params: JSON = [
            "connected": connected as AnyObject,
        ]

        APIClient.shared.PUT(url: url, parameters: params) { _, response, body in

            guard response?.statusCode == 200 else {
                APIDiagnostics.shared.ERROR(_classDescription: self.descriptor,
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

            APIDiagnostics.shared.SUCCESS(_classDescription: self.descriptor,
                                          _functionDescriptor: function,
                                          _url: url,
                                          _params: params,
                                          _start: start,
                                          _body: body,
                                          _response: response)
            callback(true)
        }
    }

    func getTypingUsers() -> [User] {
        var typers = [User]()

        for user in chatUsers.chatUsers {
            if user.typing == true {
                typers.append(user.user!)
            }
        }

        return typers
    }

    func resetTypingUsers() {
        for user in chatUsers.chatUsers {
            if user.typing == true {
                user.typing = false
            }
        }
    }

    func listen(_ socket: SocketIOClient) -> JSON? {
        
        let user: JSON = [
            "id": Auth.shared.id as JSONObject,
            "firstName": DeviceUser.shared.user!.firstName as JSONObject,
            "lastName": DeviceUser.shared.user!.lastName as JSONObject,
        ]

        let data: JSON = [
            "room": "chat" as JSONObject,
            "roomid": self.id! as JSONObject,
            "user": user as JSONObject,
        ]

        socket.emit("socket-join", data)
        return data
    }
    
    func endListen(_ socket: SocketIOClient) -> JSON? {
        
        let user: JSON = [
            "id": Auth.shared.id as JSONObject,
            "firstName": DeviceUser.shared.user!.firstName as JSONObject,
            "lastName": DeviceUser.shared.user!.lastName as JSONObject,
            ]
        
        let data: JSON = [
            "room": "chat" as JSONObject,
            "roomid": self.id! as JSONObject,
            "user": user as JSONObject,
            ]
        
        socket.emit("socket-leave", data)
        return data
    }

    func join(_ socket: SocketIOClient) -> JSON? {
        let user: JSON = [
            "id": Auth.shared.id as JSONObject,
            "firstName": DeviceUser.shared.user!.firstName as JSONObject,
            "lastName": DeviceUser.shared.user!.lastName as JSONObject,
        ]

        let data: JSON = [
            "chatroom": self.id! as JSONObject,
            "user": user as JSONObject
        ]

        socket.emit("Chatroom-join", data)
        return data
    }

    func leave(_ socket: SocketIOClient) -> JSON? {
        
        let user: JSON = [
            "id": Auth.shared.id as JSONObject,
            "firstName": DeviceUser.shared.user!.firstName as JSONObject,
            "lastName": DeviceUser.shared.user!.lastName as JSONObject,
        ]

        let data: JSON = [
            "chatroom": self.id! as JSONObject,
            "user": user as JSONObject
        ]

        socket.emit("Chatroom-leave", data)
        return data
    }
}


class ChatUsers {
    var chatUsers = [ChatUser]()
    
    func append(_ chatUser: ChatUser?) {
        guard let chatUser = chatUser else {
            return
        }
        
        chatUser.index = count
        chatUsers.append(chatUser)
    }
    
    var count: Int {
        return chatUsers.count
    }
    
    subscript(index: Int?) -> ChatUser? {
        guard let index = index, index < self.count else {
            return nil
        }
        
        return chatUsers[index]
    }
    
    subscript(id: String?) -> ChatUser? {
        guard let id = id, self.count > 0 else {
            return nil
        }
        
        for chatUser in chatUsers {
            if chatUser.user?.id == id {
                return chatUser
            }
        }
        
        return nil
    }
    
    func index(id: String?) -> Int? {
        guard let id = id, self.count > 0 else {
            return nil
        }
        
        var i = 0
        for chatUser in chatUsers {
            if chatUser.user?.id == id {
                return i
            }
            
            i = i + 1
        }
        
        return nil
    }
    
    var typingUsers: [User] {
        var typers = [User]()
        
        for chatUser in chatUsers {
            if chatUser.typing == true, let user = chatUser.user {
                typers.append(user)
            }
        }
        
        return typers
    }
    
    func resetTypers() {
        for chatUser in chatUsers {
            chatUser.typing = false
        }
    }
}

class ChatUser {
    var user: User?
    var connected: Bool?
    var lastMessageRead: Date?
    var index: Int?
    var updated: Bool = true
    var typing: Bool = false
    
    convenience init(attrs: JSON) {
        self.init()
        
        if let userData = attrs["user"] as? JSON, let userId = userData["id"] as? String {
            if userId == Auth.shared.id {
                user = DeviceUser.shared.user
            } else {
                user = Users.shared[userId]
            }
        }
        
        if let lastReadValue = attrs["lastMessageRead"] as? String {
            lastMessageRead = APIClient.shared.formatter.date(from: lastReadValue)
        }
        
        connected = attrs["connected"] as? Bool
    }
    
    func update(attrs: JSON?) {
        guard let data = attrs else {
            return
        }
        
        if let chatUserData = data["user"] as? JSON, let userData = chatUserData["user"] as? JSON, let userId = userData["id"] as? String {
            if userId != user?.id {
                return
            }
            
            if let lastReadValue = chatUserData["lastMessageRead"] as? String {
                lastMessageRead = APIClient.shared.formatter.date(from: lastReadValue)
            }
            
            connected = chatUserData["connected"] as? Bool
        }
    }
}

