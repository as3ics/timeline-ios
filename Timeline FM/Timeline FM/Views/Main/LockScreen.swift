//
//  LockScreen.swift
//  Timeline FM
//
//  Created by Zachary DeGeorge on 8/12/18.
//  Copyright © 2018 Next Day Project. All rights reserved.
//

import UIKit
import LocalAuthentication
import Material

class LockScreen: UIViewController {

    var context = LAContext()
    
    @IBOutlet var button: FlatButton!
    @IBOutlet var icon: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        button.styleCard(Color.blue.darken3, image: nil, title: "Unlock")
        button.addTarget(self, action: #selector(self.attemptLocalAuthorization), for: .touchUpInside)
        button.corner = 5.0
        button.titleLabel?.font = UIFont(name: DEFAULT_SYSTEM_FONT_NAME, size: button.titleLabel!.font.pointSize)

        icon.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(attemptLocalAuthorization)))
        icon.isUserInteractionEnabled = true
        
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @objc func attemptLocalAuthorization(_ sender: Any?) {
        // Get a fresh context for each login. If you use the same context on multiple attempts
        //  (by commenting out the next line), then a previously successful authentication
        //  causes the next policy evaluation to succeed without testing biometry again.
        //  That's usually not what you want.
        
        if let tap = sender as? UITapGestureRecognizer {
            tap.view?.touchAnimation()
        }
        
        guard DeviceSettings.shared.authenticate == true else {
            
            delay(0.5) {
                DispatchQueue.main.async {
                    if App.shared.isLoaded == true {
                        Shortcuts.goUnlockScreen()
                    } else {
                        Shortcuts.goLogin()
                    }
                }
            }
           
            return
        }
        
        delay(0.3) {
            self.context = LAContext()
            
            self.context.localizedCancelTitle = "Cancel"
            
            App.shared.isAuthenticating = true
            
            // First check if we have the needed hardware support.
            var error: NSError?
            if self.context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
                let reason = "Log in to your account"
                self.context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) { success, error in
                    
                    if success {
                        delay(0.5) {
                            DispatchQueue.main.async {
                                if App.shared.isLoaded == true {
                                    Shortcuts.goUnlockScreen()
                                } else {
                                    Shortcuts.goLogin()
                                }
                            }
                        }
                    } else {
                        print(error?.localizedDescription ?? "Failed to authenticate")
                        
                        delay(1.5) {
                            DispatchQueue.main.async {
                                Shortcuts.goLogin()
                            }
                        }
                    }
                }
            } else {
                print(error?.localizedDescription ?? "Can't evaluate policy")
                
                delay(1.5) {
                    DispatchQueue.main.async {
                        Shortcuts.goLogin()
                    }
                }
            }
        }
    }
}
