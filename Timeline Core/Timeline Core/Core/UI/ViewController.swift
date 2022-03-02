//
//  ViewController.swift
//  Timeline FM
//
//  Created by Zachary DeGeorge on 8/14/18.
//  Copyright © 2018 Next Day Project. All rights reserved.
//

import UIKit
import Material
import IQKeyboardManagerSwift

enum ViewingMode {
    case Creating
    case Editing
    case Viewing
    case Selecting
}

class ViewController: UIViewController, ThemeSupportedProtocol {

    weak var navBar: NavBar?
    
    var mode: ViewingMode?
    
    open var usesIQKeyboard: Bool {
        return false
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        Theme.shared.theme_changed.observe(self, selector: #selector(applyTheme))
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        guard navBar == nil else {
            setupNavBar()
            return
        }
        
        navBar = NavBar(self)
        
        setupNavBar()
        
        applyTheme()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        IQKeyboardManager.shared.enable = usesIQKeyboard
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        IQKeyboardManager.shared.enable = false
    }
    
    open override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        if self.navigationDrawerController?.isOpened == true {
            prepareForDeinit()
            
            if let pageContoller = self.pageTabBarController {
                for controller in pageContoller.viewControllers {
                    if let vc = controller as? ViewController {
                        vc.prepareForDeinit()
                    }
                }
            }
        }
    }
    
    open override func goBack() {
        prepareForDeinit()
        
        super.goBack()
    }
    
    open func setupNavBar() {
        // Do not call super.setupNavBar() in overriden function
        fatalError("You must override this function")
    }
    
    @objc open func applyTheme() {
        navBar?.style = .Sub
    }
    
    open func prepareForDeinit() {
        navBar?.relinquish()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
