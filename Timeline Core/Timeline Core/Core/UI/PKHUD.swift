//
//  PKHUD.swift
//  Timeline FM
//
//  Created by Zachary DeGeorge on 8/25/18.
//  Copyright © 2018 Next Day Project. All rights reserved.
//

import Foundation
import PKHUD


extension PKHUD {
    static func loading() {
        DispatchQueue.main.async {
            PKHUD.sharedHUD.contentView = PKHUDProgressView()
            PKHUD.sharedHUD.show()
        }
    }
    
    static func success() {
        DispatchQueue.main.async {
            PKHUD.sharedHUD.contentView = PKHUDSuccessView()
            PKHUD.sharedHUD.show()
            PKHUD.sharedHUD.hide(true)
        }
    }
    
    static func failure() {
        DispatchQueue.main.async {
            PKHUD.sharedHUD.contentView = PKHUDErrorView()
            PKHUD.sharedHUD.show()
            PKHUD.sharedHUD.hide(true)
        }
    }
    
    static func message(text: String) {
        DispatchQueue.main.async {
            PKHUD.sharedHUD.contentView = PKHUDTextView(text: text)
            PKHUD.sharedHUD.show()
        }
    }
    
    static func hide(animated: Bool = true) {
        DispatchQueue.main.async {
            PKHUD.sharedHUD.hide(animated)
        }
    }
    
    static func hide(delay: TimeInterval) {
        DispatchQueue.main.async {
            PKHUD.sharedHUD.hide(afterDelay: delay)
        }
    }
}
