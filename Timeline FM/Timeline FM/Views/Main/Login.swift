//
//  LoginViewController.swift
//  Timeline Software, LLC
//
//  Created by Timeline Software, LLC on 1/29/16.
//  Copyright © 2016 Timeline Software, LLC. All rights reserved.
//

import LocalAuthentication
import Material
import PKHUD
import UIKit
import CoreLocation

class Login: UIViewController, UITextFieldDelegate, ThemeSupportedProtocol, SidebarSectionProtocol {
    static var section: String = "Sign Out"

    fileprivate enum LoginState {
        case PhoneNumberEntry
        case ConfirmationCodeEntry
    }

    @IBOutlet var phoneNumberView: UIView!
    @IBOutlet var businessButton: UIButton!
    @IBOutlet var employeeButton: UIButton!

    @IBOutlet var launchLogoCenteryY: NSLayoutConstraint!
    @IBOutlet var phoneNumberField: UITextField!
    @IBOutlet var footerText: UILabel!
    @IBOutlet var greetingLabel: UILabel!
    @IBOutlet var noCodeButton: UIButton!
    @IBOutlet var notYouButton: UIButton!
    @IBOutlet var loginView: UIView!
    @IBOutlet var loginButton: UIButton!
    @IBOutlet var createAccountViewHeightConstraint: NSLayoutConstraint!
    fileprivate var createAccoutViewHeightOriginal: CGFloat!
    fileprivate var state: LoginState = .PhoneNumberEntry
    @IBOutlet var createAccountButton: FlatButton!
    @IBOutlet var loginButtonHeightConstraint: NSLayoutConstraint!
    @IBOutlet var createAccountView: UIView!
    fileprivate var phoneNumber: String?
    fileprivate var loginButtonHeightConstraintOriginal: CGFloat!
    fileprivate var loginViewHeightConstraintOriginal: CGFloat!

    @IBOutlet var loginViewHeightConstraint: NSLayoutConstraint!
    
    /// An authentication context stored at class scope so it's available for use during UI updates.
    //var context = LAContext()

    /// The available states of being logged in or not.
    enum AuthenticationState {
        case indeterminant, loggedin, loggedout_preAuthed, loggedOut_notAuthed
    }

    /// The current authentication state.
    var bioState: AuthenticationState = AuthenticationState.indeterminant {
        // Update the UI on a change.
        didSet {
            if self.bioState == .loggedOut_notAuthed {
                self.loginButton.alpha = 0.0
                self.loginButton.height = 0.0
                self.createAccountViewHeightConstraint.constant = 0.0
                self.createAccountButton.title = "Click Here to Create Account"
                self.view.layoutIfNeeded()
                
                let otherCenter = -(self.view.height / 2) + (175.0 / 2.0) + 65.0
                let iPhone5Center = -(self.view.height / 2) + (175.0 / 2.0) - 12.5
                let newLaunchLogoCenter = Device.phoneType != .iPhone5 ? otherCenter : iPhone5Center
                self.launchLogoCenteryY.constant = newLaunchLogoCenter
                
                self.createAccountView.alpha = 0.0
                UIView.animate(withDuration: 1.0) {
                    self.loginView.alpha = 1.0
                    self.loginViewHeightConstraint.constant = self.loginViewHeightConstraintOriginal
                    self.greetingLabel.text = ""
                    self.phoneNumberField.placeholder = "Phone Number"
                    self.phoneNumberField.isUserInteractionEnabled = true
                    self.view.layoutIfNeeded()

                    /* Delete Me */// self.createAccountButton.alpha = 1.0
                    self.businessButton.alpha = 1.0
                    self.employeeButton.alpha = 1.0
                }
            } else if self.bioState == .loggedout_preAuthed {
                self.launchLogoCenteryY.constant = 0
                
                if self.createAccountView.alpha == 1.0 {
                    self.createAccountViewHeightConstraint.constant = 0.0
                }
                
                self.createAccountView.alpha = 0.0
                UIView.animate(withDuration: 1.0) {
                    self.greetingLabel.text = nil
                    self.phoneNumberField.text = Auth.shared.phonenumber
                    self.phoneNumberField.placeholder = nil
                    self.phoneNumberField.isUserInteractionEnabled = false
                    self.loginView.alpha = 0.0
                    self.loginViewHeightConstraint.constant = 0.0
                    self.createAccountButton.alpha = 0.0
                    self.businessButton.alpha = 0.0
                    self.employeeButton.alpha = 0.0
                    self.createAccountView.alpha = 0.0

                    if App.shared.isLoaded == true {
                        App.shared.isLoaded = false
                        self.loginButton.alpha = 1.0
                        self.loginButtonHeightConstraint.constant = self.loginButtonHeightConstraintOriginal
                    }

                    self.view.layoutIfNeeded()
                }

                if App.shared.isLoaded == false {
                    delay(1.5) {
                        self.attemptLocalAuthorization()
                    }
                }
            } else if self.bioState == .loggedin {
                self.createAccountView.alpha = 0.0
                UIView.animate(withDuration: 0.2) {
                    self.greetingLabel.alpha = 0.0
                    self.loginView.alpha = 0.0
                    self.noCodeButton.alpha = 0.0
                    self.notYouButton.alpha = 0.0
                    self.loginButton.alpha = 0.0
                    self.footerText.alpha = 0.0
                    self.createAccountViewHeightConstraint.constant = 0.0
                }

                self.loginButtonHeightConstraint.constant = 0.0
                self.loginViewHeightConstraint.constant = 0.0
                self.launchLogoCenteryY.constant = 0
                UIView.animate(withDuration: 1.0) {
                    self.view.layoutIfNeeded()
                }

                self.authorizationComplete()
            }
        }
    }

    func authorizationComplete() {
        Commander.shared.initialize()

        delay(1.0) {
            DispatchQueue.main.async {
                Shortcuts.goLoading()
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationDrawerController?.isEnabled = false
        createAccoutViewHeightOriginal = createAccountViewHeightConstraint.constant
        loginButtonHeightConstraintOriginal = loginButtonHeightConstraint.constant
        loginViewHeightConstraintOriginal = loginViewHeightConstraint.constant

        hideKeyboardWhenTappedAround()

        
        phoneNumberField.placeholder = NSLocalizedString("LoginViewController_PhoneNumber", comment: "")
        phoneNumberField.text = Auth.shared.phonenumber
        
        notYouButton.addTarget(self, action: #selector(reset), for: .touchUpInside)
        notYouButton.isUserInteractionEnabled = true
        
        noCodeButton.setTitle(NSLocalizedString("LoginViewController_NoConfirmationCode", comment: ""), for: UIControlState())
        phoneNumberField.addTarget(self, action: #selector(Login.textFieldDidChange(_:)), for: UIControlEvents.editingChanged)
        loginView.alpha = 0.0
        loginViewHeightConstraint.constant = 0.0
        noCodeButton.alpha = 0.0
        notYouButton.alpha = 0.0
        greetingLabel.alpha = 0.0
        businessButton.alpha = 0.0
        employeeButton.alpha = 0.0
        loginButton.alpha = 0.0
        loginButtonHeightConstraint.constant = App.shared.isLoaded == true ? loginButtonHeightConstraintOriginal : 0.0
        createAccountButton.alpha = 0.0
        createAccountView.alpha = 0.0
        createAccountViewHeightConstraint.constant = 0.0

        // add done button to keyboard

        let keyboardToolBar = UIToolbar()
        keyboardToolBar.sizeToFit()

        let flexibleSpace = UIBarButtonItem(barButtonSystemItem:
            UIBarButtonSystemItem.flexibleSpace, target: nil, action: nil)
        let doneButton = UIBarButtonItem(barButtonSystemItem:
            UIBarButtonSystemItem.done, target: self, action: #selector(continueButtonTapped))
        doneButton.setTitleTextAttributes([NSAttributedStringKey.font: UIFont(name: DEFAULT_SYSTEM_FONT_NAME, size: 16)!], for: [.normal])

        keyboardToolBar.setItems([flexibleSpace, doneButton], animated: true)

        phoneNumberField.inputAccessoryView = keyboardToolBar

        let tap = UITapGestureRecognizer(target: self, action: #selector(openPrivacyPolicy))
        footerText.addGestureRecognizer(tap)
        footerText.isUserInteractionEnabled = true

        createAccountButton.addTarget(self, action: #selector(showCreateAccounts), for: .touchUpInside)
        employeeButton.animateTouch()
        employeeButton.addTarget(self, action: #selector(goCreateEmployeeAccount), for: .touchUpInside)
        businessButton.animateTouch()
        businessButton.addTarget(self, action: #selector(goCreateOrganizationAccount), for: .touchUpInside)
        
        applyTheme()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if App.shared.isLoaded == true {
            App.shared.isLoaded = false
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if Auth.shared.authed == true {
            if DeviceSettings.shared.developerMode == true {
                bioState = .loggedin
            } else {
                bioState = .loggedout_preAuthed
            }
        } else {
            bioState = .loggedOut_notAuthed
            
            delay(1.0) {
                self.showCreateAccounts()
            }
        }
    }

    @objc func showCreateAccounts() {
        delay(createAccountViewHeightConstraint.constant == 0 ? 0.0 : 0.25) {
            self.createAccountViewHeightConstraint.constant = self.createAccountViewHeightConstraint.constant == 0 ? self.createAccoutViewHeightOriginal : 0
            UIView.animate(withDuration: 0.75) {
                self.view.layoutIfNeeded()
            }
        }

        self.createAccountButton.title = self.createAccountView.alpha == 0.0 ? "Create New Account" : "Click Here to Create Account"
        self.view.layoutIfNeeded()
        
        UIView.animate(withDuration: 0.25, delay: createAccountViewHeightConstraint.constant == 0 ? 0.75 : 0.0, options: [], animations: {
            /* Delete Me */// self.createAccountView.alpha = self.createAccountViewHeightConstraint.constant == 0 ? 1.0 : 0.0
        }, completion: nil)
    }

    @objc func openPrivacyPolicy(_: Any) {
        if let url = URL(string: "https://timelinefm.com/privacy-iOS") {
            Generator.bump()

            UIApplication.shared.open(url, options: EMPTY_JSON, completionHandler: nil)
        }
    }

    @IBAction func unwindToLoginFromOrganization(segue _: UIStoryboardSegue) {
    }

    var previousCount = 0
    @objc func textFieldDidChange(_ textField: UITextField) {
        if state == .PhoneNumberEntry {
            // if added a character
            if previousCount < textField.text!.characters.count {
                if textField.text!.characters.count == 3 {
                    if textField.text!.characters.first != "(" {
                        let text = "(" + textField.text! + ") "
                        textField.text = text
                    }
                } else if textField.text!.characters.count == 5 {
                    if textField.text![4] != ")" {
                        let index: String.Index = textField.text!.characters.index(textField.text!.startIndex, offsetBy: 4)
                        let text: String = textField.text!.substring(to: index) + ") " + textField.text![4]
                        textField.text = text
                    }

                } else if textField.text!.characters.count == 10 {
                    if textField.text![9] != "-" {
                        let index: String.Index = textField.text!.characters.index(textField.text!.startIndex, offsetBy: 9)
                        let text: String = textField.text!.substring(to: index) + "-" + textField.text![9]
                        textField.text = text
                    }

                } else if textField.text!.characters.count == 9 {
                    let text = textField.text! + "-"
                    textField.text = text
                } else if textField.text!.characters.count == 15 {
                    let index: String.Index = textField.text!.characters.index(textField.text!.startIndex, offsetBy: 14)
                    let text: String = textField.text!.substring(to: index) // "Stack"
                    textField.text = text
                }

            } else { // removed character
            }

            previousCount = textField.text!.characters.count
        }
    }

    @IBAction func continueButtonTapped() {
        phoneNumberField.resignFirstResponder()
        // self.adjustRootViewForKeyboard(false)

        guard bioState == .loggedout_preAuthed else {
            if state == .PhoneNumberEntry {
                Generator.bump()

                if phoneNumberField.text?.characters.count == 14 {
                    
                    Auth.shared.phonenumber = phoneNumberField.text
                    
                    PKHUD.loading()

                    Async.waterfall(nil, [Auth.shared.beginAuthentication]) { error, _ in
                        guard error == nil else {
                            PKHUD.failure()
                            return
                        }

                        PKHUD.success()

                        self.phoneNumberField.text = nil
                        self.phoneNumberField.placeholder = "Confirmation Code"
                        self.state = .ConfirmationCodeEntry

                        if let firstName = Auth.shared.firstName, let lastName = Auth.shared.lastName {
                            self.greetingLabel.text = String(format: NSLocalizedString("LoginViewController_Greeting", comment: ""), arguments: [firstName, lastName])

                            UIView.animate(withDuration: 0.3, animations: { () -> Void in
                                self.footerText.alpha = 0
                                self.noCodeButton.alpha = 1
                                self.notYouButton.alpha = 1
                                self.greetingLabel.alpha = 1

                                self.createAccountButton.alpha = 0.0
                                self.businessButton.alpha = 0.0
                                self.employeeButton.alpha = 0.0
                            })
                        }
                    }
                }
            } else if state == .ConfirmationCodeEntry {
                if let smsCode = self.phoneNumberField.text, smsCode.characters.count == 6 {
                    PKHUD.loading()

                    Auth.shared.smsCode = smsCode

                    Async.waterfall(nil, [Auth.shared.finishAuthentication]) { error, _ in
                        guard error == nil else {
                            PKHUD.failure()

                            Generator.failure()
                            return
                        }

                        PKHUD.success()

                        Generator.confirm()

                        self.bioState = .loggedin
                    }
                }
            }

            return
        }

        attemptLocalAuthorization()
    }

    func attemptLocalAuthorization() {
        // Get a fresh context for each login. If you use the same context on multiple attempts
        //  (by commenting out the next line), then a previously successful authentication
        //  causes the next policy evaluation to succeed without testing biometry again.
        //  That's usually not what you want.
        
        guard DeviceSettings.shared.authenticate == true else {
            DispatchQueue.main.async { [weak self] in
                self?.bioState = .loggedin
            }
            return
        }
        
        
        let context = LAContext()
        context.canEvaluatePolicy(.deviceOwnerAuthentication, error: nil)

        context.localizedCancelTitle = "Cancel"
        
        App.shared.isAuthenticating = true
        
        // First check if we have the needed hardware support.
        var error: NSError?
        if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
            let reason = "Log in to your account"
            context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) { success, error in

                if success {
                    // Move to the main thread because a state update triggers UI changes.
                    DispatchQueue.main.async { [weak self] in
                        self?.bioState = .loggedin
                    }

                } else {
                    print(error?.localizedDescription ?? "Failed to authenticate")

                    DispatchQueue.main.async { [weak self] in
                        self?.bioState = .loggedOut_notAuthed
                    }
                }
            }
        } else {
            print(error?.localizedDescription ?? "Can't evaluate policy")

            DispatchQueue.main.async {
                self.bioState = .loggedOut_notAuthed
            }
        }
    }

    @objc func reset() {
        Generator.bump()

        state = .PhoneNumberEntry

        phoneNumberField.text = Auth.shared.phonenumber
        phoneNumberField.placeholder = NSLocalizedString("LoginViewController_PhoneNumber", comment: "")
        phoneNumber = nil

        UIView.animate(withDuration: 0.3, animations: { () -> Void in
            self.footerText.alpha = 1
            self.greetingLabel.alpha = 0
            self.noCodeButton.alpha = 0
            self.notYouButton.alpha = 0
        })
    }

    @IBAction func wrongPersonButtonTapped() {
        reset()
    }

    @IBAction func noConfirmationCodeButtonTapped() {
        if state == .ConfirmationCodeEntry {
            
            Notifications.shared.registerForPushNotifications()
            
            Async.waterfall(["push" : true as JSONObject] as JSON, [Auth.shared.beginAuthentication]) { error, _ in
                guard error == nil else {
                    PKHUD.failure()
                    return
                }
                
                PKHUD.success()
            }
        }
    }

    func keyboardReturnButtonTapped(_: UIBarButtonItem) {
        phoneNumberField.resignFirstResponder()
    }

    func textFieldShouldReturn(_: UITextField) -> Bool {
        view.endEditing(true)
        return false
    }
    
    @objc func goCreateEmployeeAccount(_ sender: UIButton) {
        delay(0.2) {
            Shortcuts.goCreateEmployee()
        }
        
    }
    
    @objc func goCreateOrganizationAccount(_ sender: UIButton) {
        delay(0.2) {
            Shortcuts.goCreateOrganization()
        }
    }

    func applyTheme() {
        view.backgroundColor = Theme.shared.active.primaryBackgroundColor
        greetingLabel.textColor = Theme.shared.active.primaryFontColor
        createAccountButton.titleLabel?.textColor = Theme.shared.active.alternativeFontColor
        createAccountButton.pulseColor = Theme.shared.active.primaryBackgroundColor
        createAccountButton.pulseOpacity = 0.5
        createAccountButton.corner = createAccountButton.layer.height / 2
        createAccountButton.titleLabel?.font = footerText.font
        phoneNumberField.keyboardAppearance = .dark
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
