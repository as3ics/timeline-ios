//
//  Socket.swift
//  Timeline FM
//
//  Created by Zachary DeGeorge on 7/7/18.
//  Copyright © 2018 Next Day Project. All rights reserved.
//

import Foundation
import SocketIO
import CoreLocation
import MapKit

class Socket {
    static var shared = Socket()
    
    var socket: SocketIOClient!
    
    var connections: [JSON] = [JSON]()
    var debounce: Date = Date()
    
    init() {
        Notifications.shared.loaded_false.observe(self, selector: #selector(notLoaded))
        Notifications.shared.loaded_true.observe(self, selector: #selector(isLoaded))
        Notifications.shared.model_updated.observe(self, selector: #selector(modelUpdated))
        Notifications.shared.socket_reload_rooms.observe(self, selector: #selector(reloadRoomsNotification))
    }
    
    func initialize() {
        
        guard socket == nil || socket?.status != .connected else {
            return
        }
        
        socket = SocketIOClient(socketURL: URL(string: APIClient.shared.baseURL)!, config: [.log(true), .forceNew(false), .reconnects(true), .reconnectWait(1000), .reconnectAttempts(9999)])
        
        initializeHandlers()
        
        socket.connect()
    }
    
    func initializeHandlers() {
        socket.on(clientEvent: .connect) { data, ack in
            print("socket connected")
            
            self.joinRooms()
        }
        
        socket.on("ModelUpdate", callback: { data, ack in
            
            print("ModelUpdate - Socket Update Recieved")
            
            guard let data = data[0] as? JSON, let _action = data["action"] as? String, let action = ModelAction(rawValue: _action), let _type = data["type"] as? String, let type = ModelType(rawValue: _type), let _model = data["model"] as? JSON, let modelId = _model["id"] as? String, let createdBy = data["createdBy"] as? JSON else {
                print("Socket - Invalid Data recieved from Server")
                return
            }
            
            let user = User(attrs: createdBy)
            
            let model = Model(id: modelId, user: user, type: type, action: action)
            
            print("Socket - New Data From Server")
            
            model.process()
        })
        
        socket.on("UserUpdate", callback: { data, ack in
            
            print("UserUpdate - Socket Update Recieved")
            
            guard let payload = data[0] as? JSON else {
                print("Socket - Invalid Data From Server")
                return
            }
            
            ModelUpdater.shared.processPayload(payload: payload)
            
            print("Socket - New Data From Server")
        })
        
        socket.on("Chatroom-chatUsersReload", callback: { data, ack in
            guard let data = data[0] as? JSON, let chatId = data["chatroom"] as? String, let chatroom = Chatrooms.shared[chatId] else {
                return
            }
            
            Async.waterfall(nil, [chatroom.reloadUsers], end: { _, _ in
                NotificationManager.shared.chat_users_reloaded.post(data)
            })
        })
        
        socket.on("Chatroom-newMessage", callback: { data, ack in
            
            guard let messageData = data[0] as? JSON else {
                return
            }
            
            let message = Message(attrs: messageData)
            
            guard let chatroomId = message.chatroom, let chatroom = Chatrooms.shared[chatroomId], let userId = message.user, let user = Users.shared[userId] ?? DeviceUser.shared.user, let firstName = user.firstName, let lastName = user.lastName else {
                return
            }
            
            let incoming = Auth.shared.id == userId ? false : true
            
            guard incoming == true, (message.messageKind == MessageKind.Photo || message.messageKind == MessageKind.Text) else {
                return
            }
            
            let previous = chatroom.messages.items.filter({ (msg) -> Bool in
                return message.timestamp == msg.timestamp
            })
            
            guard previous.count == 0 else { return }
            
            chatroom.messages.insert(message)
            
            let userInfo: JSON = [
                "chatroom": chatroom as JSONObject,
                "message": message as JSONObject,
                ]
            
            NotificationManager.shared.chat_new_message.post(userInfo)
            Notifications.shared.updateBadge()
            
            if self.shouldAlert(chatroom) {
                Notifications.shared.scheduleNotification(title: "\(firstName) \(lastName)", body: message.content ?? "Photo", identifier: "chatroom-newMessage")
            }
        })
        
        socket.on(clientEvent: .disconnect) { data, ack in
            print("socket disconnected")
        }
        
        socket.on(clientEvent: .reconnect) { data,ack in
            print("socket reconnected")
        }
        
        socket.on(clientEvent: .error) { (data, ack) in
            print("ERROR -- ")
            print(data.debugDescription)
            print("-- ERROR")
            
            if Date().timeIntervalSince(self.debounce) < -5.0 {
                self.debounce = Date()
                
                self.socket.connect()
            }
        }
    }
    
    func listening(_ roomid: String) -> Bool {
        let matches = connections.filter( {(room) -> Bool in
            if let _roomid = room["roomid"] as? String, roomid == _roomid {
                return true
            }
            
            return false
        })
        
        return matches.count > 0
    }
    
    func index(_ roomid: String) -> Int {
        for i in 0...self.connections.count - 1 {
            if let _roomid = connections[i]["roomid"] as? String, roomid == _roomid {
                return i
            }
        }
        
        return -1
    }
    
    @objc fileprivate func isLoaded() {
        reloadRooms()
    }

    @objc fileprivate func notLoaded() {
        socket.disconnect()
    }
    
    @objc func leaveRooms() {
        
        guard self.socket?.status == .connected else {
            return
        }
        
        for value in connections {
            self.socket.emit("socket-leave", value)
        }
    }
    
    @objc func joinRooms() {
        
        for value in self.connections {
            self.socket.emit("socket-join", value)
        }
    }
    
    @objc func reloadRooms() {
        
        leaveRooms()
        connections.removeAll()
        
        // connect to org room
        let orgData: JSON = [
            "room": "org" as JSONObject,
            "user": Auth.shared.id! as JSONObject,
            "roomid": Auth.shared.orgId! as JSONObject,
            ]
        
        socket.emit("socket-join", orgData)
        connections.append(orgData)
        
        let userData: JSON = [
            "room": "user" as JSONObject,
            "user": Auth.shared.id! as JSONObject,
            "roomid": Auth.shared.id! as JSONObject
        ]
        
        socket.emit("socket-join", userData)
        connections.append(userData)
        
        // connect to chatrooms
        for room in Chatrooms.shared.items {
            if let data = room.listen(self.socket) {
                connections.append(data)
            }
        }
        
        // connect to subscriptions
        for item in Subscriptions.shared.items {
            if let data = item.join(self.socket) {
                connections.append(data)
            }
        }
    }
    
    @objc func reloadRoomsNotification(_ notification: NSNotification) {
        
        Socket.shared.reloadRooms()
        
    }
    
    @objc func modelUpdated(_ notification: NSNotification) {
        guard let data = notification.userInfo, let update = data["update"] as? ModelUpdate, App.shared.isLoaded == true else {
            return
        }
        
        if update.type == .Chatroom, update.action == .Retrieve {
            // connect to chatrooms
            
            if let chatroom = update.model as? Chatroom, listening(chatroom.id!) == false, let data = chatroom.listen(self.socket) {
                connections.append(data)
            }
        }
        
        if update.type == .Chatroom, update.action == .Delete {
            // connect to chatrooms
            if let chatroom = update.model as? Chatroom {
                let index = self.index(chatroom.id!)
                
                guard index >= 0 else {
                    return
                }
                
                let _ = chatroom.leave(self.socket)
                connections.remove(at: index)
            }
        }
            
        else if update.type == .Subscription, update.action == .Create || update.action == .Retrieve {
            if let subscription = update.model as? Subscription, listening(subscription.user!) == false, let data = subscription.join(self.socket) {
                connections.append(data)
            }
        }
        
        else if update.type == .Subscription, update.action == .Delete {
            if let subscription = update.model as? Subscription {
                let index = self.index(subscription.user!)
                
                guard index >= 0 else {
                    return
                }
                
                let _ = subscription.leave(self.socket)
                connections.remove(at: index)
            }
        }
    }
    
    func shouldAlert(_ chatroom: Chatroom?) -> Bool {
        guard let chatroom = chatroom else { return false }
        
        let value = chatroom.id == Chatrooms.connectedChatroom?.id ? false : true
        
        return value
    }
}
