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

    var state: SystemState {
        guard let sheet = DeviceUser.shared.sheet else {
            return SystemState.Off
        }
        
        guard let entry = sheet.entries.latest else {
            return SystemState.Empty
        }
        
        guard let activity = entry.activity else {
            return SystemState.Error
        }
        
        if activity.traveling {
            return SystemState.Traveling
        } else if activity.breaking {
            return SystemState.Break
        } else {
            return SystemState.LoggedIn
        }
    }
    
    var active: Bool {
        let state = System.shared.state
        
        if state == .LoggedIn || state == .Break || state == .Traveling {
            return true
        } else {
            return false
        }
    }
    
    var adminAccess: Bool {
        guard let role = DeviceUser.shared.user?.userRole else {
            return false
        }
        
        return role == UserRole.Admin
    }
    
    var shouldOnboard: Bool {
        return DeviceSettings.shared.onboarded != true
    }
    
    func alert(title: String?, message: String?, handler: ((UIAlertAction) -> Void)? = nil, cancel: ((UIAlertAction) -> Void)? = nil)  {
        guard let title = title ?? App.shared.appName, let message = message else {
            return
        }
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        
        alert.addAction(UIAlertAction(title: "Continue", style: .default, handler: handler))
        
        if let cancelHandler = cancel {
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: cancelHandler))
        }
        
        Presenter.present(alert)
    }
}
