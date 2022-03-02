//
//  CreateOrganizationAccount.swift
//  Timeline FM
//
//  Created by Zachary DeGeorge on 7/20/18.
//  Copyright © 2018 Next Day Project. All rights reserved.
//

import UIKit

import Foundation
import IQKeyboardManagerSwift
import PKHUD
import Material
import CoreLocation

// MARK: - CreateOrganizationAccount

class CreateOrganizationAccount: ViewController, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, TextFieldDelegate {
    
    @IBOutlet var tableView: UITableView!
    
    override var usesIQKeyboard: Bool {
        return true
    }
    
    enum LoginState {
        case Page1
        case Page2
        case Completed
    }
    
    var state: LoginState = .Page1
    
    var firstName: String?
    var lastName: String?
    var organization: String?
    var phonenumber: String?
    var password: String?
    var email: String?
    
    var firstNameValidated: Bool = false
    var lastNameValidated: Bool = false
    var organizationValidated: Bool = false
    var phonenumberValidated: Bool = false
    var passwordValidated: Bool = false
    var emailValidated: Bool = false
    
    // MARK: - UIViewController Overrides
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.separatorStyle = .none
        
        let refreshControl = UIRefreshControl()
        refreshControl.alpha = 0.0
        refreshControl.backgroundColor = UIColor.clear
        refreshControl.addTarget(self, action: #selector(goBack), for: UIControlEvents.valueChanged)
        tableView.refreshControl = refreshControl
        
        AccountHeaderCell.register(self.tableView)
        AccountFieldCell.register(self.tableView)
        AccountButtonCell.register(self.tableView)
    }
    
    override func setupNavBar() {
        self.navBar?.title = "app.timelinefm.com"
        self.navBar?.titleLabel.autoResize()
        
        self.navBar?.leftImage = AssetManager.shared.arrowLeft
        self.navBar?.leftButton.tintColor = Theme.shared.active.alternateIconColor
        self.navBar?.leftEnclosure = { self.goBack() }
        
        self.navBar?.rightImage = nil
    }
    
    override func goBack() {
        
        tableView.refreshControl?.endRefreshing()
        
        if self.state == .Page2 {
            
            email = nil
            phonenumber = nil
            password = nil
            
            emailValidated = false
            phonenumberValidated = false
            passwordValidated = false
            
            self.state = .Page1
            self.tableView.reloadSections([1], with: .right)
        } else {
            super.goBack()
        }
    }
    
    // MARK: - UITableView Delegate and DataSource
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 1
        case 1:
            let rows:Int = self.state == .Page1 ? 3 : 3
            return rows
        case 2:
            return 1
        default:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.section {
        case 0:
            return AccountHeaderCell.cellHeight
        case 1:
            return AccountFieldCell.cellHeight
        case 2:
            return AccountButtonCell.cellHeight
        default:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.01
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            let cell = AccountHeaderCell.loadNib(tableView)
            cell.typeLabel.text = "Organization Account"
            
            cell.selectionStyle = .none
            return cell
        case 1:
            switch indexPath.row {
            case 0:
                let cell = AccountFieldCell.loadNib(tableView)
                
                cell.field.tag = 1
                cell.field.delegate = self
                cell.field.text = self.state == .Page1 ? organization : nil
                cell.field.detailColor = cell.field.placeholderNormalColor
                cell.field.placeholder = self.state == .Page1 ?  "Organization Name" : "E-Mail"
                cell.field.detail = self.state == .Page1 ? "Enter your organizations name" : "Enter your e-mail"
                cell.field.keyboardType = self.state == .Page1 ? .default : .emailAddress
                cell.field.autocapitalizationType = self.state == .Page1 ? .words : .none
                cell.field.autocorrectionType = .no
                cell.field.isSecureTextEntry = false
                cell.field.isPlaceholderAnimated = true
                cell.field.isClearIconButtonEnabled = true
                cell.field.isEnabled = true
                cell.field.placeholderAnimation = .default
                cell.field.leftView = nil
                cell.selectionStyle = .none
                
                return cell
            case 1:
                let cell = AccountFieldCell.loadNib(tableView)
                
                cell.field.tag = 2
                cell.field.delegate = self
                cell.field.text = self.state == .Page1 ? firstName : nil
                cell.field.detailColor = cell.field.placeholderNormalColor
                cell.field.placeholder = self.state == .Page1 ? "First Name" : "Phone Number"
                cell.field.detail = self.state == .Page1 ? "Enter your first name" : "Enter your phone number"
                cell.field.keyboardType = self.state == .Page1 ? .default : .numberPad
                cell.field.autocapitalizationType = self.state == .Page1 ? .words : .none
                cell.field.autocorrectionType = .no
                cell.field.isSecureTextEntry = false
                cell.field.isPlaceholderAnimated = true
                cell.field.isClearIconButtonEnabled = true
                cell.field.isEnabled = true
                cell.field.placeholderAnimation = .default
                cell.field.leftView = nil
                cell.selectionStyle = .none
                
                return cell
            case 2:
                let cell = AccountFieldCell.loadNib(tableView)
                
                cell.field.tag = 3
                cell.field.text = self.state == .Page1 ? lastName : nil
                cell.field.delegate = self
                cell.field.detailColor = cell.field.placeholderNormalColor
                cell.field.placeholder =  self.state == .Page1 ? "Last Name" : "Password"
                cell.field.detail = self.state == .Page1 ? "Enter your last name" : "Create a password"
                cell.field.keyboardType = self.state == .Page1 ? .default : .default
                cell.field.autocapitalizationType = self.state == .Page1 ? .words : .none
                cell.field.isSecureTextEntry = self.state == .Page1 ? false : true
                cell.field.autocorrectionType = .no
                cell.field.font = self.state == .Page1 ? cell.field.font : UIFont.systemFont(ofSize: 15.0)
                cell.field.isPlaceholderAnimated = true
                cell.field.isClearIconButtonEnabled = true
                cell.field.isEnabled = true
                cell.field.placeholderAnimation = .default
                cell.field.leftView = nil
                cell.selectionStyle = .none
                
                return cell
            default:
                return UITableViewCell()
            }
        case 2:
            let cell = AccountButtonCell.loadNib(tableView)
            
            cell.button.addTarget(self, action: #selector(self.nextPressed), for: .touchUpInside)
            
            cell.selectionStyle = .none
            return cell
        default:
            return UITableViewCell()
        }
    }
    
    // MARK: - UIText Delegate
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        
        if let field = textField as? TextField {
            if self.state == .Page1 {
                if field.tag == 1 {
                    self.organizationValidated = validate(field)
                } else if field.tag == 2 {
                    self.firstNameValidated = validate(field)
                } else if field.tag == 3 {
                    self.lastNameValidated = validate(field)
                }
            } else if self.state == .Page2 {
                if field.tag == 1 {
                    self.emailValidated = validate(field)
                } else if field.tag == 2 {
                    self.phonenumberValidated = validate(field)
                } else if field.tag == 3 {
                    self.passwordValidated = validate(field)
                }
            }
        }
        
        if self.state == .Page1 {
            if textField.tag == 1 {
                self.organization = textField.text
            } else if textField.tag == 2 {
                self.firstName = textField.text
            } else if textField.tag == 3 {
                self.lastName = textField.text
            }
        } else if self.state == .Page2 {
            if textField.tag == 1 {
                self.email = textField.text
            } else if textField.tag == 2 {
                self.phonenumber = textField.text
            } else if textField.tag == 3 {
                self.password = textField.text
            } else if textField.tag == 5 {
                // foo
            }
        }
    }
    
    var previousCount = 0
    func textField(textField: UITextField, didChange text: String?) {
        if self.state == .Page2, textField.tag == 2 {
            if self.previousCount < textField.text!.characters.count {
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
            }
            
            self.previousCount = textField.text!.characters.count
        }
    }
    
    // MARK: - Other Functions
    
    func validate(_ field: TextField) -> Bool {
        if self.state == .Page2, field.tag == 2 {
            if field.text?.characters.count == 14 {
                field.detailColor = Color.blue.base
                return true
            } else {
                field.detailColor = Color.red.base
                field.leftView = nil
                return false
            }
        } else if field.text == nil || field.text == "" {
            field.detailColor = Color.red.base
            return false
        } else {
            field.detailColor = Color.blue.base
            field.leftView = nil
            return true
        }
    }
    
    var confirmationField: UITextField?
    @objc func nextPressed(_ sender: FlatButton) {
        
        view.endEditing(true)
        
        switch self.state {
        case .Page1:
            guard firstNameValidated == true, lastNameValidated == true, organizationValidated == true else {
                Generator.confirm()
                return
            }
            
            self.state = .Page2
            self.tableView.reloadSections([1], with: .left)
            break
        case .Page2:
            guard emailValidated == true, phonenumberValidated == true, passwordValidated == true else {
                Generator.confirm()
                return
            }
            
            IQKeyboardManager.shared.enable = false
            
            let alert = NYAlertViewController()
            
            alert.title = "Timeline"
            alert.message = "Confirm your password"
            
            alert.titleFont = UIFont(name: DEFAULT_SYSTEM_FONT_NAME, size: 17.0)
            alert.messageFont = UIFont(name: DEFAULT_SYSTEM_FONT_NAME, size: 15.0)
            
            alert.swipeDismissalGestureEnabled = false
            alert.backgroundTapDismissalGestureEnabled = false
            
            alert.buttonTitleFont = UIFont(name: DEFAULT_SYSTEM_FONT_NAME, size: 17.0)
            alert.buttonColor = Color.blue.base
            alert.destructiveButtonTitleFont = UIFont(name: DEFAULT_SYSTEM_FONT_NAME, size: 17.0)
            
            self.confirmationField = UITextField(frame: CGRect(x: 0, y: 0, width: alert.view.bounds.width, height: 60.0))
            self.confirmationField?.tag = 5
            self.confirmationField?.isSecureTextEntry = true
            self.confirmationField?.borderStyle = .none
            self.confirmationField?.keyboardType = .default
            self.confirmationField?.font = UIFont.systemFont(ofSize: 15.0)
            self.confirmationField?.placeholder = "Confirm Password"
            self.confirmationField?.setLeftPadding(12.5)
            
            alert.alertViewContentView = self.confirmationField
            alert.alertViewContentView.height = 60.0
            alert.view.layoutIfNeeded()
            
            alert.addAction(NYAlertAction(title: "OK", style: .default, handler: { _ in
                
                self.view.endEditing(true)
                
                PKHUD.loading()
                
                guard let text = self.confirmationField?.text, text == self.password else {
                    PKHUD.failure()
                    IQKeyboardManager.shared.enable = true
                    self.confirmationField?.text = nil
                    return
                }
                
                self.dismiss(animated: true, completion: nil)
                
                let phone = "1" + self.phonenumber!.replacingOccurrences(
                    of: "\\D", with: "", options: .regularExpression,
                    range: self.phonenumber!.startIndex ..< self.phonenumber!.endIndex)
                
                let user = User()
                user.phoneNumber = phone
                user.firstName = self.firstName
                user.lastName = self.lastName
                user.organization = self.organization
                user.email = self.email
                user.password = self.password
                
                Async.waterfall(nil, [user.registerOrganization], end: { (error, response) in
                    guard error == nil else {
                        IQKeyboardManager.shared.enable = true
                        PKHUD.failure()
                        return
                    }
                    
                    self.state = .Completed
                    PKHUD.success()
                    self.goBack()
                })
            }))
            
            alert.addAction(NYAlertAction(title: "Cancel", style: .destructive, handler: { _ in
                self.dismiss(animated: true, completion: nil)
            }))
            
            Presenter.present(alert, animated: true)
            self.confirmationField?.becomeFirstResponder()
            
            break
        default:
            break
        }
    }
}
