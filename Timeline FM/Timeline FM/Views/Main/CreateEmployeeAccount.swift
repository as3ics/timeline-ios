//
//  CreateEmployeeAccount.swift
//  Timeline FM
//
//  Created by Zachary DeGeorge on 7/16/18.
//  Copyright © 2018 Next Day Project. All rights reserved.
//

import Foundation
import PKHUD
import Material
import CoreLocation
import ActionSheetPicker_3_0

// MARK: - CreateEmployeeAccount

class CreateEmployeeAccount: ViewController, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, TextFieldDelegate {
    
    @IBOutlet var tableView: UITableView!
    
    override var usesIQKeyboard: Bool {
        return true
    }
    
    enum LoginState {
        case Name
        case Organization
        case Completed
    }
    
    var state: LoginState = .Name
    
    var firstName: String?
    var lastName: String?
    var organization: String?
    var phonenumber: String?
    var email: String?
    var accountType: UserRole = .User
    
    var firstNameValidated: Bool = false
    var lastNameValidated: Bool = false
    var organizationValidated: Bool = false
    var phonenumberValidated: Bool = false
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
        SettingsSelectionCell.register(self.tableView)
    }
    
    override func setupNavBar() {
        self.navBar?.title = "Create User"
        self.navBar?.titleLabel.autoResize()
        
        self.navBar?.leftImage = AssetManager.shared.arrowLeft
        self.navBar?.leftButton.tintColor = Theme.shared.active.alternateIconColor
        self.navBar?.leftEnclosure = { self.goBack() }
        
        self.navBar?.rightImage = nil
    }
    
    override func goBack() {
        
        tableView.refreshControl?.endRefreshing()
        
        if self.state == .Organization {
            
            self.state = .Name
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
            let rows:Int = self.state == .Name ? 3 : 3
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
            cell.typeLabel.text = "Employee Account"
            
            cell.selectionStyle = .none
            return cell
        case 1:
            switch indexPath.row {
            case 0:
                let cell = AccountFieldCell.loadNib(tableView)
                
                cell.field.tag = 1
                cell.field.delegate = self
                cell.field.text = self.state == .Name ? firstName : DeviceUser.shared.user?.registrationCode ?? nil
                cell.field.detailColor = cell.field.placeholderNormalColor
                cell.field.placeholder = self.state == .Name ?  "First Name" : "Organization Code"
                cell.field.detail = self.state == .Name ? "A first name is required" : "Enter your organization's short code"
                cell.field.isPlaceholderAnimated = true
                cell.field.isClearIconButtonEnabled = true
                cell.field.isEnabled = true
                cell.field.placeholderAnimation = .default
                cell.field.leftView = nil
                cell.selectionStyle = .none
                
                if cell.field.text != "" {
                    textFieldDidEndEditing(cell.field)
                }
                
                return cell
            case 1:
                let cell = AccountFieldCell.loadNib(tableView)
                
                cell.field.tag = 2
                cell.field.delegate = self
                cell.field.text = self.state == .Name ? lastName : email
                cell.field.detailColor = cell.field.placeholderNormalColor
                cell.field.placeholder = self.state == .Name ? "Last Name" : "E-Mail"
                cell.field.detail = self.state == .Name ? "A last name is required" : "An email account is not required"
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
                cell.field.delegate = self
                cell.field.text = self.state == .Name ? phonenumber : accountType == .User ? "User" : "Supervisor"
                cell.field.detailColor = cell.field.placeholderNormalColor
                cell.field.placeholder =  self.state == .Name ? "Phone Number" : "Account Type"
                cell.field.detail = self.state == .Name ? "A phone number is required" : "Select Account Type"
                cell.field.isPlaceholderAnimated = true
                cell.field.isClearIconButtonEnabled = self.state == .Name ? true : false
                cell.field.isEnabled = self.state == .Name ? true : false
                cell.field.placeholderAnimation = .default
                cell.field.leftView = nil
                cell.field.keyboardType = .numberPad
                cell.selectionStyle = .none
                
                if self.state == .Name {
                    for gesture in cell.gestureRecognizers ?? [] {
                        cell.removeGestureRecognizer(gesture)
                    }
                } else {
                    cell.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(accountTypeTapped)))
                }
                
                return cell
            default:
                return UITableViewCell()
            }
        case 2:
            let cell = AccountButtonCell.loadNib(tableView)
            
            cell.button.title = state == .Name ? "Next" : "Create"
            
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
            if self.state == .Name {
                if field.tag == 1 {
                    self.firstNameValidated = validate(field)
                } else if field.tag == 2 {
                    self.lastNameValidated = validate(field)
                } else if field.tag == 3 {
                    self.phonenumberValidated = validate(field)
                }
            } else if self.state == .Organization {
                if field.tag == 1 {
                    self.organizationValidated = validate(field)
                } else if field.tag == 2 {
                    self.emailValidated = validate(field)
                }
            }
        }
        
        if self.state == .Name {
            if textField.tag == 1 {
                self.firstName = textField.text
            } else if textField.tag == 2 {
                self.lastName = textField.text
            } else if textField.tag == 3 {
                self.phonenumber = textField.text
            }
        } else if self.state == .Organization {
            if textField.tag == 1 {
                self.organization = textField.text
            } else if textField.tag == 2 {
                self.email = textField.text
            }
        }
    }
    
    var previousCount = 0
    func textField(textField: UITextField, didChange text: String?) {
        if textField.tag == 3 {
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
        if field.tag == 3 {
            if field.text?.characters.count == 14 {
                field.detailColor = UIColor.clear
                return true
            } else {
                field.detailColor = Color.red.base
                field.leftView = nil
                return false
            }
        } else if state == .Organization && field.tag == 2 {
            return isValid(email: field.text)
        } else if field.text == nil || field.text == "" {
            field.detailColor = Color.red.base
            return false
        } else {
            field.detailColor = UIColor.clear
            field.leftView = nil
            return true
        }
    }
    
    func createAccount(_ callback: @escaping(_ success: Bool) -> ()) {
        
        guard phonenumber != nil else {
            callback(false)
            return
        }
        
        let phone = "1" + phonenumber!.replacingOccurrences(
            of: "\\D", with: "", options: .regularExpression,
            range: phonenumber!.startIndex ..< phonenumber!.endIndex)
        
        let user = User()
        
        user.phoneNumber = phone
        user.firstName = firstName
        user.lastName = lastName
        user.organization = organization
        user.userRole = accountType
        user.email = emailValidated == true ? email : " "
        
        Async.waterfall(nil, [user.registerUser]) { (error, response) in
            guard error == nil else {
                callback(false)
                return
            }
            
            if App.shared.isLoaded == true {
                Async.waterfall(nil, [Commander.shared.retrieveUsers]) { (error, response) in
                    callback(true)
                    return
                }
            } else {
                callback(true)
                return
            }
        }
    }
    
    @objc func accountTypeTapped(_: UITapGestureRecognizer) {
        Generator.bump()
        
        let picker = ActionSheetStringPicker(title: "Account Type:", rows: ["User", "Supervisor"], initialSelection: self.accountType == .User ? 0 : 1, doneBlock: {
            picker, index, value in
            
            Generator.bump()
            
            self.accountType = index == 0 ? .User : .Supervisor
            
            self.tableView.reloadSections([1], with: .automatic)
            
        }, cancel: { _ in
            Generator.bump()
        }, origin: self.tableView)
        
        styleActionSheetStringPicker(picker!)
        
        picker!.show()
    }
    
    @objc func nextPressed(_ sender: FlatButton) {
        view.endEditing(true)
        switch self.state {
        case .Name:
            guard firstNameValidated == true, lastNameValidated == true, phonenumberValidated == true else {
                Generator.confirm()
                return
            }
            
            self.state = .Organization
            self.tableView.reloadSections([1, 2], with: .left)
            break
        case .Organization:
            guard organizationValidated == true else {
                Generator.confirm()
                return
            }
            
            PKHUD.loading()
            self.createAccount { (success) in
                guard success == true else {
                    PKHUD.failure()
                    return
                }
                
                PKHUD.success()
                self.state = .Completed
                self.goBack()
            }
            
            break
        default:
            break
        }
    }
}
