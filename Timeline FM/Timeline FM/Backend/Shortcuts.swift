//
//  Shortcuts.swift
//  Timeline FM
//
//  Created by Zachary DeGeorge on 9/24/18.
//  Copyright © 2018 Next Day Project. All rights reserved.
//

import Foundation
import PKHUD

class Shortcuts {
    
    // MARK: - App Navigation Shortcuts
    
    static func goOnboarding() {
        let destination = UIStoryboard.Main(identifier: "TimelineOnboard")
        
        App.shared.window?.setRootViewController(destination, options: UIWindow.TransitionOptions(direction: .fade, style: .linear))
    }
    
    static func goLogin() {
        App.shared.window?.setRootViewController(UIStoryboard.Main(identifier: "Login"), options: UIWindow.TransitionOptions(direction: .fade, style: .linear))
    }
    
    static func goCreateEmployee() {
        let destination = UIStoryboard.Main(identifier: "CreateEmployeeAccount") as! CreateEmployeeAccount
        
        Presenter.push(destination)
    }
    
    static func goCreateOrganization() {
        let destination = UIStoryboard.Main(identifier: "CreateOrganizationAccount") as! CreateOrganizationAccount
        
        Presenter.push(destination)
    }
    
    static func goLockScreen() {
        App.shared.window?.setRootViewController(UIStoryboard.Main(identifier: "LockScreen"), options: UIWindow.TransitionOptions(direction: .fade, style: .linear))
    }
    
    static func goUnlockScreen() {
        
        guard App.shared.isLoaded == true else {
            Shortcuts.goLogin()
            return
        }
        
        PKHUD.loading()
        if Socket.shared.socket.status != .connected {
            let previous = LocationManager.shared.getStateHoldValue()
            LocationManager.shared.holdState(true)
            Commander.shared.load { (success) in
                LocationManager.shared.holdState(previous)
                Socket.shared.initialize()
                
                PKHUD.success()
                Navigator.shared.goTo(section: Navigator.shared.activeSection ?? Navigator.shared.sections[Navigator.shared.index(title: Timeline.section)!], options: UIWindow.TransitionOptions(direction: .fade, style: .linear))
            }
        } else {
            let previous = LocationManager.shared.getStateHoldValue()
            LocationManager.shared.holdState(true)
            Commander.shared.quickLoad { (success) in
                LocationManager.shared.holdState(previous)
                PKHUD.success()
                Navigator.shared.goTo(section: Navigator.shared.activeSection ?? Navigator.shared.sections[Navigator.shared.index(title: Timeline.section)!], options: UIWindow.TransitionOptions(direction: .fade, style: .linear))
            }
        }
    }
    
    static func goAbout() {
        let destination = UIStoryboard.Main(identifier: "About")
        
        Presenter.push(destination)
    }
    
    static func goProfile() {
        let destination = UIStoryboard.Main(identifier: "Profile")
        
        Presenter.push(destination)
    }
    
    static func goLoading() {
        let transitionView = UIStoryboard.Main(identifier: "TransitionView")
        transitionView.view.layoutIfNeeded()
        var options = UIWindow.TransitionOptions(direction: .fade, style: .linear)
        options.duration = 0.05
        options.background = UIWindow.TransitionOptions.Background.customView(transitionView)
        
        App.shared.cleanseUI()
        
        let destination = UIStoryboard.Main(identifier: "Loading")
        UIApplication.shared.keyWindow?.setRootViewController(destination, options: options)
    }
    
    static func goTimeline() {
        let transitionView = UIStoryboard.Main(identifier: "TransitionView")
        transitionView.view.layoutIfNeeded()
        var options = UIWindow.TransitionOptions(direction: .fade, style: .linear)
        options.duration = 0.05
        options.background = UIWindow.TransitionOptions.Background.customView(transitionView)
        
        Navigator.shared.goTo(section: Navigator.shared.sections[Navigator.shared.index(title: Timeline.section)!], options: options)
    }
}
