//
//  Notifications.swift
//  Timeline FM
//
//  Created by Zachary DeGeorge on 9/24/18.
//  Copyright © 2018 Next Day Project. All rights reserved.
//

import Foundation
import UserNotifications
import UIKit

class Notifications {
    
    static let shared = Notifications()
    
    fileprivate let delegate = NotificationsDelegate()
    
    let system_message = Notification.Name(rawValue: "system_message_notification")
    fileprivate let system_message_notification: Notification
    
    let model_update = Notification.Name(rawValue: "model_update_notification")
    fileprivate let model_update_notification: Notification

    let model_updated = Notification.Name(rawValue: "model_updated_notification")
    fileprivate let model_updated_notification: Notification
    
    let chat_photo_retrieved = Notification.Name(rawValue: "chat_photo_retrieved_notification")
    fileprivate let chat_photo_retrieved_notification: Notification

    let image_placeholder_retrieved = Notification.Name(rawValue: "image_placeholder_retrieved_notification")
    fileprivate let image_placeholder_retrieved_notification: Notification
    
    let socket_reload_rooms = Notification.Name(rawValue: "socket_reload_rooms_notification")
    fileprivate let socket_reload_rooms_notification: Notification
    
    let map_focus_user = Notification.Name(rawValue: "map_focus_user_notification")
    fileprivate let map_focus_user_notification: Notification
    
    let badge_updated = Notification.Name(rawValue: "badge_updated_notification")
    fileprivate let badge_updated_notification: Notification
    
    let timer_1000ms = Notification.Name(rawValue: "timer_1000ms_notification")
    fileprivate let timer_1000ms_notification: Notification
    
    let loaded_true = Notification.Name(rawValue: "loaded_true_notification")
    fileprivate let loaded_true_notification: Notification
    
    let loaded_false = Notification.Name(rawValue: "loaded_false_notification")
    fileprivate let loaded_false_notification: Notification

    init() {
        
        timer_1000ms_notification = Notification(name: timer_1000ms)
        loaded_true_notification = Notification(name: loaded_true)
        loaded_false_notification = Notification(name: loaded_false)
        system_message_notification = Notification(name: system_message)
        model_update_notification = Notification(name: model_update)
        model_updated_notification = Notification(name: model_updated)
        chat_photo_retrieved_notification = Notification(name: chat_photo_retrieved)
        image_placeholder_retrieved_notification = Notification(name: image_placeholder_retrieved)
        socket_reload_rooms_notification = Notification(name: socket_reload_rooms)
        map_focus_user_notification = Notification(name: map_focus_user)
        badge_updated_notification = Notification(name: badge_updated)
        
        let center = UNUserNotificationCenter.current()
        center.delegate = delegate
    }
    
    func registerForPushNotifications() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            print("Notification settings: \(settings)")
            if settings.authorizationStatus != .authorized {
                DispatchQueue.main.async {
                    let center = UNUserNotificationCenter.current()
                    
                    center.requestAuthorization(options: [.alert, .sound, .badge]) {
                        success, error in
                        
                        guard success == true else {
                            return
                        }
                        
                        DispatchQueue.main.async {
                            UIApplication.shared.registerForRemoteNotifications()
                        }
                    }
                }
            }
        }
    }
    
    func updateUserDeviceToken() {
        DispatchQueue.main.async {
            let center = UNUserNotificationCenter.current()
            
            center.requestAuthorization(options: [.alert, .sound, .badge]) {
                success, error in
                
                guard success == true else {
                    return
                }
                
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
        }
    }
    
    class func scheduleSilentNotification(title: String, body: String, identifier: String) {
        let center = UNUserNotificationCenter.current()
        
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = nil
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
        center.add(UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)) { _ in
            // do something
        }
    }
    
    func scheduleNotification(title: String, body: String, identifier: String, _ sound: UNNotificationSound? = nil) {
        let center = UNUserNotificationCenter.current()
        
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = sound ?? UNNotificationSound.default()
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
        center.add(UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)) { _ in
            // do something
        }
    }
    
    func systemMessage(_ message: String) {
        let userInfo: JSON = [
            "system-message": message as JSONObject,
            ]
        
        system_message.post(userInfo)
    }
    
    var systemMessageLabel: UILabel?
    func observeSystemMessage(label: UILabel?) {
        systemMessageLabel = label
        system_message.observe(self, selector: #selector(updateSystemMessage(_:)))
    }
    
    func releaseSystemMessageObserver() {
        systemMessageLabel = nil
    }
    
    @objc func updateSystemMessage(_ notification: NSNotification) {
        guard let label = self.systemMessageLabel, let data = notification.userInfo as? JSON, let message = data["system-message"] as? String else {
            return
        }
        
        DispatchQueue.main.async {
            label.text = message
        }
    }
    
    
    @objc func updateBadge() {
        let value = Chatrooms.shared.unreadMessages
        
        DispatchQueue.main.async {
            UIApplication.shared.applicationIconBadgeNumber = value
            
            let userInfo: JSON = [
                "count": value as JSONObject,
                ]
            
            Notifications.shared.badge_updated.post(userInfo)
        }
    }
}

fileprivate class NotificationsDelegate: NSObject, UNUserNotificationCenterDelegate {
    fileprivate func userNotificationCenter(_: UNUserNotificationCenter,
                                            willPresent _: UNNotification,
                                            withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Play sound and show alert to the user
        completionHandler([.alert, .sound])
    }
    
    fileprivate func userNotificationCenter(_: UNUserNotificationCenter,
                                            didReceive response: UNNotificationResponse,
                                            withCompletionHandler completionHandler: @escaping () -> Void) {
        // Determine the user action
        switch response.actionIdentifier {
        case UNNotificationDismissActionIdentifier:
            print("Dismiss Action")
        case UNNotificationDefaultActionIdentifier:
            print("Default")
        case "Snooze":
            print("Snooze")
        case "Delete":
            print("Delete")
        default:
            print("Unknown action")
        }
        completionHandler()
    }
    
}

extension NSNotification.Name {
    func observe(_ observer: Any, selector: Selector) {
        NotificationCenter.default.addObserver(observer, selector: selector, name: self, object: nil)
    }
    
    func post(_ userInfo: [AnyHashable: Any]? = nil) {
        NotificationCenter.default.post(name: self, object: nil, userInfo: userInfo)
    }
}
