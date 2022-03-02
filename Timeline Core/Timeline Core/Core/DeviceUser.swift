//
//  DeviceUser.swift
//  Timeline SDK
//
//  Created by Zachary DeGeorge on 6/25/18.
//  Copyright © 2018 Timeline Software LLC. All rights reserved.
//

import Foundation

@objcMembers final class DeviceUser: NSObject {

    static let shared = DeviceUser()
    
    var user: User?
    var sheet: Sheet? {
        willSet {
            if newValue == nil {
                sheet?.cleanse()
            }
        }
    }
    var schedule: Schedule?
}
