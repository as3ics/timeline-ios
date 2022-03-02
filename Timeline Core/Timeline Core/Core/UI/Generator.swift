//
//  Generator.swift
//  Timeline FM
//
//  Created by Zachary DeGeorge on 9/24/18.
//  Copyright © 2018 Next Day Project. All rights reserved.
//

import Foundation
import UIKit

class Generator {
    
    fileprivate static var generator = UIImpactFeedbackGenerator(style: .light)
    fileprivate static var generatorNotify = UINotificationFeedbackGenerator()
    
    class func bump() {
        DispatchQueue.main.async {
            self.generator.impactOccurred()
        }
    }
    
    class func confirm() {
        DispatchQueue.main.async {
            self.generatorNotify.notificationOccurred(.success)
        }
    }
    
    class func failure() {
        DispatchQueue.main.async {
            self.generatorNotify.notificationOccurred(.error)
        }
    }
}
