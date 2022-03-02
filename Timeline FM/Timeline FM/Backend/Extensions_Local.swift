//
//  Extensions_Local.swift
//  Timeline FM
//
//  Created by Zachary DeGeorge on 9/14/18.
//  Copyright © 2018 Next Day Project. All rights reserved.
//

import Foundation
import Material


extension FlatButton {
    
    func styleCard(_ color: UIColor, image: UIImage?, title: String? = nil) {
        backgroundColor = color
        self.image = image
        self.title = title
        imageEdgeInsets = UIEdgeInsetsMake(7.5, 7.5, 7.5, 7.5)
        imageView?.contentMode = .scaleAspectFit
        tintColor = UIColor.white
        pulseColor = UIColor.white
        titleColor = UIColor.white
        isEnabled = true
        layer.masksToBounds = true
        animateTouch()
    }
    
    func styleTimeline(_ image: UIImage?) {
        backgroundColor = UIColor.clear
        self.image = image?.withRenderingMode(.alwaysTemplate)
        title = nil
        titleColor = UIColor.clear
        imageEdgeInsets = UIEdgeInsetsMake(7.5, 7.5, 7.5, 7.5)
        imageView?.contentMode = .scaleAspectFit
        tintColor = Theme.shared.active.darkIconColor.withAlphaComponent(TIMELINE_VIEW_BUTTON_ALPHA)
        pulseColor = UIColor.white
        isEnabled = true
        layer.masksToBounds = true
        layer.cornerRadius = layer.height / 2
        animateTouch()
    }
}


extension App {
    
    // MARK: - Asset Management Shortcuts
    
    func clearAssetsCoreData() {
        Locations.shared.deleteAllEntities()
        Activities.shared.deleteAllEntities()
        Users.shared.deleteAllEntities()
        
        App.shared.assetsDeleted = true
        DeviceSettings.shared.timestamp = nil
        
        AppDelegate.saveContext()
    }
    
    func clearPhotosCoreData() {
        PhotoAssets.shared.deleteAllEntities()
        PhotoBucket.shared.deleteAllEntities()
        
        AppDelegate.saveContext()
    }
    
    func cleanseData() {
        Users.shared.items.removeAll()
        Locations.shared.items.removeAll()
        Activities.shared.items.removeAll()
        
        DeviceUser.shared.schedule = nil
        DeviceUser.shared.user = nil
        DeviceUser.shared.sheet = nil
    }
    
    func cleanseUI() {
        
        if let drawer = UIApplication.shared.keyWindow?.rootViewController?.navigationDrawerController, let navcontroller = drawer.rootViewController as? UINavigationController {
            
            var children = [UIViewController]()
            
            for vc in navcontroller.childViewControllers {
                children.insert(vc, at: 0)
            }
            
            for child in children {
                if let timeline = child as? Timeline {
                    timeline.prepareForDeinit()
                } else if let main = child as? Main {
                    main.prepareForDeinit()
                } else if let chat = child as? Chat {
                    chat.prepareForDeinit()
                } else if let viewcontroller = child as? ViewChats {
                    viewcontroller.prepareForDeinit()
                } else if let viewcontroller = child as? ViewController {
                    viewcontroller.prepareForDeinit()
                }
                
                child.navigationController?.popViewController(animated: false)
            }
        } else if let vc = UIApplication.shared.keyWindow?.rootViewController {
            vc.removeFromParentViewController()
        }
    }
    
    func lockScreen(disconnect: Bool = true) {
        
        AppDelegate.backgroundTimer = nil
        
        let _ = Chatrooms.connectedChatroom?.leave(Socket.shared.socket)
        
        DispatchQueue.main.async {
            
            if disconnect == true {
                Socket.shared.leaveRooms()
                Socket.shared.socket.disconnect()
                
                if App.shared.assetsDeleted == false {
                    DeviceSettings.shared.timestamp = Date()
                }
            }
            
            App.shared.cleanseUI()
            
            if App.shared.isLoaded == true {
                Shortcuts.goLockScreen()
            } else {
                Shortcuts.goLogin()
            }
        }
    }
}


extension UIStoryboard {
    
    class func History(identifier: String) -> UIViewController {
        return UIStoryboard(name: "History", bundle: Bundle.main).instantiateViewController(withIdentifier: identifier)
    }
    
    class func Location(identifier: String) -> UIViewController {
        return UIStoryboard(name: "Location", bundle: Bundle.main).instantiateViewController(withIdentifier: identifier)
    }
    
    class func Activity(identifier: String) -> UIViewController {
        return UIStoryboard(name: "Activity", bundle: Bundle.main).instantiateViewController(withIdentifier: identifier)
    }
    
    class func Chat(identifier: String) -> UIViewController {
        return UIStoryboard(name: "Chat", bundle: Bundle.main).instantiateViewController(withIdentifier: identifier)
    }
    
    class func Schedule(identifier: String) -> UIViewController {
        return UIStoryboard(name: "Schedule", bundle: Bundle.main).instantiateViewController(withIdentifier: identifier)
    }
    
    class func User(identifier: String) -> UIViewController {
        return UIStoryboard(name: "User", bundle: Bundle.main).instantiateViewController(withIdentifier: identifier)
    }
}
