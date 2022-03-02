//
//  Subs.swift
//  Timeline Core
//
//  Created by Zachary DeGeorge on 9/24/18.
//  Copyright © 2018 Timeline Software LLC. All rights reserved.
//

import Foundation
import SocketIO

class NotificationManager {
    
    static let shared: NotificationManager = NotificationManager()

    let user_stream_updated = Notification.Name(rawValue: "user_stream_updated_notification")
    let user_subscription_updated = Notification.Name(rawValue: "user_subscription_updated_notification")
}

@objc class UserAnnotation: NSObject {
    
}

// Global State Machine
enum SystemState {
    case Traveling
    case Empty
    case LoggedIn
    case Break
    case Off
    case Error
}

@objc class DeviceSettings: NSObject {
    
    static let shared: DeviceSettings = DeviceSettings()
    
    /* Get/Set User Favorited Settings */
    
    func getUserFavoritedSetting(_ id: String) -> Bool {
        return true
    }
    
    func setUserFavoritedSetting(_ id: String, value: Bool) {
        
    }
    
    var schedulingMode: Bool!
    var schedulingAwaitLocation: Bool!
}

class Socket {
    
    static let shared: Socket = Socket()
    
    var connections: [JSON] = [JSON]()
    
    var socket: SocketIOClient!
}

class System {
    
    static let shared: System = System()
    
    var state: SystemState = .Off
    
}
