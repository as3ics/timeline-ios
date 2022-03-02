//
//  Login.swift
//  Timeline CMMS
//
//  Created by Zachary DeGeorge on 9/23/18.
//  Copyright © 2018 Timeline Software LLC. All rights reserved.
//

import UIKit
import Material
import EasyAnimation
import IQKeyboardManagerSwift
import PKHUD

class CMMSLogin: UIViewController, TextFieldDelegate {
    
    @IBOutlet var username: TextField!
    @IBOutlet var password: TextField!
    @IBOutlet var button: FlatButton!
    @IBOutlet var logoCenterY: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        username.tag = 1
        username.delegate = self
        username.text = nil
        username.detailColor = username.placeholderNormalColor
        username.placeholder = "Username"
        username.detail = "Enter username"
        username.isPlaceholderAnimated = true
        username.isClearIconButtonEnabled = true
        username.isEnabled = true
        username.placeholderAnimation = .default
        username.leftView = nil
        
        password.tag = 2
        password.delegate = self
        password.text = nil
        password.detailColor = username.placeholderNormalColor
        password.placeholder = "Password"
        password.detail = "Enter password"
        password.isPlaceholderAnimated = true
        password.isClearIconButtonEnabled = true
        password.isEnabled = true
        password.placeholderAnimation = .default
        password.leftView = nil
        password.isSecureTextEntry = true
        
        button.style(Color.blue.darken1, image: nil, title: "Login")
        button.addTarget(self, action: #selector(buttonPressed), for: .touchUpInside)
        
        IQKeyboardManager.shared.enable = true
    }
    
    @objc func buttonPressed() {
        
        PKHUD.loading()
        
        delay(1.0) {
            PKHUD.success()
            self.loadedAnimation()
        }
    }
    
    func loadedAnimation() {
        
        UIView.animateAndChain(withDuration: 0.5, delay: 0.0, options: [], animations: {
            self.username.alpha = 0.0
            self.password.alpha = 0.0
            self.button.alpha = 0.0
        }, completion: nil).animate(withDuration: 0.5) {
            self.logoCenterY.constant = 0.0
            self.view.layoutIfNeeded()
            }.animate(withDuration: 0.0) {
            
                let destination = UIStoryboard.Main(identifier: "CMMSLoading")
                var options = UIWindow.TransitionOptions(direction: .fade, style: .linear)
                options.duration = 0.0
                UIApplication.shared.keyWindow?.setRootViewController(destination, options: options )
        }
        
        
    }
    
    
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
