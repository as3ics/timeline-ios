//
//  SystemState.swift
//  Timeline SDK
//
//  Created by Zachary DeGeorge on 6/25/18.
//  Copyright © 2018 Timeline Software LLC. All rights reserved.
//

import Foundation
import CoreLocation


class System {
    static let shared = System()
    
    fileprivate static var generator = UIImpactFeedbackGenerator(style: .light)
    fileprivate static var generatorNotify = UINotificationFeedbackGenerator()
        
    class func bump() {
        generator.impactOccurred()
    }
    
    class func confirm() {
        generatorNotify.notificationOccurred(.success)
    }
    
    class func failure() {
        generatorNotify.notificationOccurred(.error)
    }
}
