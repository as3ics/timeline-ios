//
//  LocationAddZone.swift
//  Timeline FM
//
//  Created by Zachary DeGeorge on 9/28/18.
//  Copyright © 2018 Next Day Project. All rights reserved.
//

import PKHUD
import UIKit

// MARK: - LocationAddZone

class LocationAddZone: ViewController, UITableViewDelegate, UITableViewDataSource, UITextViewDelegate, UITextFieldDelegate {
    
    @IBOutlet var tableView: UITableView!
    
    override var usesIQKeyboard: Bool {
        return true
    }
    
    var location: Location!
    var zone: String = ""
    
    // MARK: - UIViewController Overrides
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.separatorStyle = .none
        
        let refreshControl = UIRefreshControl()
        refreshControl.alpha = 0.0
        refreshControl.backgroundColor = UIColor.clear
        refreshControl.addTarget(self, action: #selector(goBack), for: UIControlEvents.valueChanged)
        tableView.refreshControl = refreshControl
        
        hideKeyboardWhenTappedAround()
        
        StandardTextFieldCell.register(tableView)
        StandardHeaderCell.register(tableView)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        tableView.reloadData()
    }
    
    override func setupNavBar() {
        
        navBar?.title = "Create Zone"
        
        navBar?.leftImage = AssetManager.shared.arrowLeft
        navBar?.leftEnclosure = { self.goBack() }
        
        navBar?.rightImage = AssetManager.shared.add
        navBar?.rightEnclosure = { self.create() }
    }
    
    // MARK: - UITableView Delegate and DataSource
    
    func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 2
        } else {
            return 0
        }
    }
    
    func numberOfSections(in _: UITableView) -> Int {
        return 1
    }
    
    func tableView(_: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.row == 0 {
            return 70
        } else {
            return 60
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            if indexPath.row == 0 {
                let cell = StandardHeaderCell.loadNib(tableView)
                
                cell.footer.text = ""
                cell.title.text = "Zone Name"
                
                cell.selectionStyle = .none
                
                return cell
            } else if indexPath.row == 1 {
                let cell = StandardTextFieldCell.loadNib(tableView)
                
                cell.label.text = "Zone"
                cell.contents.text = zone
                cell.placeholder = "Enter Name"
                
                cell.carrot.alpha = 1.0
                cell.contents.isEnabled = true
                
                cell.contents.tag = 1
                cell.contents.delegate = self
                
                cell.selectionStyle = .none
                return cell
            }
        }
        
        return UITableViewCell.defaultCell()
    }
    
    // MARK: - UIText Delegate
    
    func textFieldDidEndEditing(_ textField: UITextField, reason _: UITextFieldDidEndEditingReason) {
        if textField.tag == 1 {
            zone = textField.text ?? ""
        }
    }
    
    func textFieldShouldReturn(_: UITextField) -> Bool {
        view.endEditing(true)
        return false
    }
    
    // MARK: - Other Functions
    
    @objc func create() {
        view.endEditing(true)
        
        guard zone != "" else {
            PKHUD.sharedHUD.contentView = PKHUDTextView(text: "Please enter a name")
            PKHUD.sharedHUD.show()
            PKHUD.sharedHUD.hide(afterDelay: DEFAULT_PKHUD_TEXT_TIMEOUT)
            return
        }
        
        PKHUD.loading()
        
        Async.waterfall(zone, [location.addZone]) { (error, response) in
            guard error == nil else {
                PKHUD.failure()
                return
            }
            
            PKHUD.success()
            
            self.goBack()
        }
    }
    
    @objc override func applyTheme() {
        super.applyTheme()
        
        view.backgroundColor = Theme.shared.active.subHeaderBackgroundColor
        tableView.backgroundColor = Theme.shared.active.subHeaderBackgroundColor
        navBar?.rightButton.tintColor = UIColor.red
    }
}
