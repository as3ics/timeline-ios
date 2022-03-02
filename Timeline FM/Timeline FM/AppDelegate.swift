//
//  AppDelegate.swift
//  Timesheets
//
//  Created by Timeline Software, LLC on 2/15/17.
//  Copyright © 2017 Timeline Software, LLC. All rights reserved.
//

import CoreData
import CoreLocation
import Crashlytics
import Fabric
import IQKeyboardManagerSwift
import UIKit
import UserNotifications
import SwiftLocation
import PKHUD

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate /* , SINClientDelegate, SINCallClientDelegate, SINManagedPushDelegate, */ {
    
    var window: UIWindow?
    static var backgroundTimer: Date?

    func application(_: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        if let _ = launchOptions?[UIApplicationLaunchOptionsKey.location] {
            return false
        }
        
        App.shared.initialize(window)
        
        resetAppIfFirstRun()
        
        initializeGlobalSettings()
        
        if System.shared.shouldOnboard == true {
            Shortcuts.goOnboarding()
        } else {
            Shortcuts.goLogin()
        }

        return true
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        
        guard App.shared.isLoaded == true else {
            completionHandler(UIBackgroundFetchResult.noData)
            return
        }
        
        if let payload = userInfo["payload"] as? JSON {
            ModelUpdater.shared.processPayload(payload: payload)
            completionHandler(UIBackgroundFetchResult.newData)
            return
        } else if let location = userInfo[UIApplicationLaunchOptionsKey.location] as? JSON {
            print(location.description)
            completionHandler(UIBackgroundFetchResult.newData)
            return
        } else {
            completionHandler(UIBackgroundFetchResult.noData)
            return
        }
        
        
        
    }
    
    func initializeGlobalSettings() {
        
        Fabric.with([Crashlytics.self, Answers.self])
        
        IQKeyboardManager.shared.enable = true
        IQKeyboardManager.shared.placeholderFont = UIFont(name: DEFAULT_SYSTEM_FONT_NAME, size: 12.0)
        
        PKHUD.sharedHUD.dimsBackground = true
        
        //UIApplication.shared.isStatusBarHidden = true
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        UIApplication.shared.isIdleTimerDisabled = false
        
        AssetManager.shared.initialize()
    }
    

    func application(_: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        // self.push.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)

        let tokenParts = deviceToken.map { data -> String in

            let string = String(format: "%02.2hhx", data)

            return string
        }

        let token = tokenParts.joined()
        
        Auth.shared.deviceToken = token
        
        print("Device Token: \(token)")
        
        if let user = DeviceUser.shared.user, user.deviceToken != token {
            user.deviceToken = token
            print("Udating user device token to server")
            Async.waterfall(nil, [user.update], end: {_, _ in })
        } else {
            print("Device token matches current user")
        }

        
        NotificationManager.shared.notifications_registered.post(["success": true as AnyObject])
    }

    func application(_: UIApplication,
                     didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register: \(error)")
        
        NotificationManager.shared.notifications_registered.post(["success": false as AnyObject])
    }

    func application(_: UIApplication, didChangeStatusBarFrame _: CGRect) {
        /*
         if let window = application.keyWindow {
         window.rootViewController?.view.frame = window.frame
         }
         */
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    
        if App.shared.isLoaded == true, App.shared.isAuthenticating == false {
            
            //App.shared.lockScreen()
            
            if LocationManager.shared.gpsSetting == .Off {
                App.shared.lockScreen()
            } else {
                AppDelegate.backgroundTimer = Date()
            }
        }
        
        App.shared.isAuthenticating = false
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        
        AppDelegate.backgroundTimer = Date()
    }

    func applicationWillEnterForeground(_: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
        
        AppDelegate.backgroundTimer = nil
    }

    func applicationDidBecomeActive(_: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        
        AppDelegate.backgroundTimer = nil
    }

    func applicationWillTerminate(_: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
        
        let _ = Chatrooms.connectedChatroom?.leave(Socket.shared.socket)
        
        Socket.shared.leaveRooms()
        Socket.shared.socket.disconnect()
        
        App.shared.isLoaded = false
        LocationManager.shared.isTrackingLocation = false
        
        if !App.shared.assetsDeleted {
            DeviceSettings.shared.timestamp = Date()
        }
        
        AppDelegate.saveContext()
    }

    /* This function collects the command from the 3d touch commands */
    func application(_: UIApplication, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
        
         guard let command = ShortcutIdentifier(rawValue: shortcutItem.type) else {
            completionHandler(false)
            return
         }

        Commander.shared.addCommand(command)

        completionHandler(true)
    }


    lazy var persistentContainer: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
         */
        let container = NSPersistentContainer(name: "TimelineFM")
        container.loadPersistentStores(completionHandler: { _, error in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.

                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()
    
    func resetAppIfFirstRun() {
        
        let defaults = UserDefaults.standard
        
        guard let key = defaults.value(forKey: "initialLoad") as? Bool, key == true else {
            
            self.resetAppActions()
            
            defaults.set(true, forKey: "initialLoad")
            
            return
        }
    }
    
    func resetAppActions() {
        
        DeviceSettings.reset()
        App.shared.clearAssetsCoreData()
        App.shared.clearPhotosCoreData()
        
    }
    
    
}
