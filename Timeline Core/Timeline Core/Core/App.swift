//
//  App.swift
//  Timeline SDK
//
//  Created by Zachary DeGeorge on 6/25/18.
//  Copyright © 2018 Timeline Software LLC. All rights reserved.
//

import PKHUD
import UIKit
import Material
import EasyAnimation

class App: NSObject {
    
    static var shared: App = App()
    
    var window: UIWindow?
    
    var info: [String: AnyObject]!
    
    var appName: String!
    var appStoreId: String!
    var apiUrl: String!
    var keychainId: String!

    func initialize(_ window: UIWindow?) {
        
        // Entry Point of App Functionality
        
        self.window = window
        
        guard let path = Bundle.main.path(forResource: "AppInfo", ofType: "plist"), let dict = NSDictionary(contentsOfFile: path) as? [String: AnyObject] else {
            
            fatalError("AppInfo must be included")
        }
        
        info = dict
        
        appName = (dict["AppName"] as! String)
        appStoreId = (dict["AppStoreId"] as! String)
        apiUrl = (dict["APIUrl"] as! String)
        keychainId = (dict["AppKeychainId"] as! String)
    }
    
    var isLoaded: Bool = false {
        didSet {
            if self.isLoaded == true {
                Notifications.shared.loaded_true.post()
                
            } else {
                Notifications.shared.loaded_false.post()
            }
        }
    }
    
    func isUpdateAvailable(completion: @escaping (_ available: Bool) -> Void) {
        guard let info = Bundle.main.infoDictionary,
            let currentVersion = info["CFBundleShortVersionString"] as? String,
            let identifier = info["CFBundleIdentifier"] as? String,
            let url = URL(string: "http://itunes.apple.com/lookup?bundleId=\(identifier)") else {
                completion(false)
                return
        }
        
        let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
            do {
                if let _ = error {
                    completion(false)
                    return
                }
                
                guard let data = data else {
                    completion(false)
                    return
                }
                
                let json = try JSONSerialization.jsonObject(with: data, options: [.allowFragments]) as? [String: Any]
                guard let result = (json?["results"] as? [Any])?.first as? [String: Any], let version = result["version"] as? String else {
                    completion(false)
                    return
                }
                
                completion(version != currentVersion)
                return
            } catch {
                completion(false)
                return
            }
        }
        
        task.resume()
    }
    
    var assetsDeleted: Bool = false
    var isAuthenticating: Bool = false
    var updateMessageShown: Bool = false

}
