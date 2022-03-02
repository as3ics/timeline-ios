//
//  SettingsViewController.swift
//  Timesheets
//
//  Created by Zachary DeGeorge on 11/3/17.
//  Copyright © 2017 Timeline Software, LLC. All rights reserved.
//

import ActionSheetPicker_3_0
import Material
import PKHUD
import UIKit
import CoreLocation

// MARK: - ScheduleViewOverrideController

class Settings: ViewController, UITableViewDelegate, UITableViewDataSource, SidebarSectionProtocol {
    static var section: String = "Settings"

    @IBOutlet var tableView: UITableView!
    
    // MARK: - UIViewController Overrides
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.separatorStyle = .none

        SettingsBasicCell.register(tableView)
        SettingsSelectionCell.register(tableView)
        StandardDescriptionCell.register(tableView)
        SettingsSwitchCell.register(tableView)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        tableView.reloadData()
    }
    
    override func setupNavBar() {
        navBar?.title = "Settings"
        
        navBar?.leftImage = AssetManager.shared.menu
        navBar?.leftEnclosure = { self.menuPressed() }
        
        navBar?.rightImage = nil
    }

    // MARK: - UITableView Delegate and DataSource

    func numberOfSections(in _: UITableView) -> Int {
        return 1
    }

    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        let value: Int = System.shared.adminAccess == true ? 8 : 8
        return value
    }

    func tableView(_: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.row {
        case 0:
            let cell = SettingsBasicCell.loadNib(tableView)

            cell.icon.image = AssetManager.shared.profile
            cell.label.text = "View Profile"
            
            cell.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(goViewProfile)))

            cell.selectionStyle = .none
            return cell
        case 1:
            let cell = SettingsSelectionCell.loadNib(tableView)

            cell.icon.image = AssetManager.shared.language
            cell.label.text = NSLocalizedString("SettingsViewController_ChooseLanguage", comment: "")
            cell.selectorLabel.text = NSLocalizedString("SettingsViewController_English", comment: "")
            
            cell.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(languageTapped)))
            
            cell.selectionStyle = .none
            return cell
        case 2:
            let cell = SettingsSelectionCell.loadNib(tableView)
            
            cell.icon.image = DeviceSettings.shared.mapProgram == MapProgram.apple ? AssetManager.shared.appleMaps : AssetManager.shared.googleMaps
            
            cell.label.text = "Map Program"
            cell.selectorLabel.text = DeviceSettings.shared.mapProgram.rawValue
            
            cell.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(mapTypeTapped)))
            
            cell.selectionStyle = .none
            return cell
        case 3:
            let cell = SettingsBasicCell.loadNib(tableView)
            
            cell.icon.image = AssetManager.shared.iPhone
            cell.label.text = "System Settings"
            
            cell.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(goPhoneSettings)))
            
            cell.selectionStyle = .none
            return cell
        case 4:
            let cell = SettingsBasicCell.loadNib(tableView)

            cell.icon.image = AssetManager.shared.onboarding
            cell.label.text = NSLocalizedString("SettingsViewController_ResetIntroduction", comment: "")

            cell.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(showOnboardingAlert)))
            
            cell.selectionStyle = .none
            return cell
        case 5:
            let cell = SettingsBasicCell.loadNib(tableView)
            
            cell.icon.image = AssetManager.shared.deleteDatabase
            cell.label.text = "Clear Offline Data"
            
            cell.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(showDeleteCoreDataAlert)))
            
            cell.selectionStyle = .none
            return cell
        case 6:
            let cell = SettingsBasicCell.loadNib(tableView)
            
            cell.icon.image = AssetManager.shared.deleteTrash
            cell.label.text = "Clear Offline Photos"
            
            cell.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(showDeletePhotoCoreDataAlert)))
            
            cell.selectionStyle = .none
            return cell
        case 7:
            let cell = SettingsSwitchCell.loadNib(tableView)
            
            cell.icon.image = AssetManager.shared.password
            cell.label.text = "Password Protection"
            
            cell.onSwitch.setOn(DeviceSettings.shared.authenticate, animated: false)
            cell.onSwitch.addTarget(self, action: #selector(authenticateSwitchValueDidChange), for: .valueChanged)
            
            cell.selectionStyle = .none
            return cell
        case 8:
            let cell = SettingsBasicCell.loadNib(tableView)
            
            cell.icon.image = AssetManager.shared.uploadCloud
            cell.label.text = "Update All Location Images"
            
            cell.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(showLocationAssetUpdateAlert)))
            
            cell.selectionStyle = .none
            return cell
        
        default:
            return UITableViewCell.defaultCell()
        }
    }
    
    // MARK: - Other Functions
    
    @objc func goViewProfile(_ sender: UITapGestureRecognizer) {
        Generator.bump()
        
        Shortcuts.goProfile()
    }

    @objc func languageTapped(_: UITapGestureRecognizer) {
        Generator.bump()

        let picker = ActionSheetStringPicker(title: "Language:", rows: [NSLocalizedString("SettingsViewController_English", comment: "")], initialSelection: 0, doneBlock: {
            _, _, _ in

            Generator.bump()

            return
        }, cancel: { _ in
            Generator.bump()
        }, origin: self.tableView)

        styleActionSheetStringPicker(picker!)

        picker!.show()
    }
    
    @objc func mapTypeTapped(_: UITapGestureRecognizer) {
        Generator.bump()
        
        let picker = ActionSheetStringPicker(title: "Map Program:", rows: [MapProgram.apple.rawValue, MapProgram.google.rawValue], initialSelection: DeviceSettings.shared.mapProgram == MapProgram.apple ? 0 : 1, doneBlock: {
            picker, index, value in
            
            Generator.bump()
            
            DeviceSettings.shared.mapProgram = MapProgram(rawValue: value as! String)!
            
            self.tableView.reloadData()
            
            return
        }, cancel: { _ in
            Generator.bump()
        }, origin: self.tableView)
        
        styleActionSheetStringPicker(picker!)
        
        picker!.show()
    }

    /*
    @objc func darkModeSwitchValueDidChange(_ sender: UISwitch) {
        Generator.bump()

        DeviceSettings.shared.nightMode = sender.isOn

        Theme.shared.theme_changed.post()
    }
    */

    @objc func developerSwitchValueDidChange(_ sender: UISwitch) {
        Generator.bump()

        DeviceSettings.shared.developerMode = sender.isOn
    }
    
    @objc func authenticateSwitchValueDidChange(_ sender: UISwitch) {
        Generator.bump()
        
        DeviceSettings.shared.authenticate = sender.isOn
    }

    @objc fileprivate func goPhoneSettings() {
        Generator.bump()
        
        External.shared.phoneSettings()
        
    }
    
    @objc fileprivate func updateLocationAssets() {
        
        Notifications.shared.system_message.observe(self, selector: #selector(systemMessageObserver))
        
        Notifications.shared.systemMessage("Updating \(Locations.shared.count) Location Assets")
        
        var queries = [(@escaping (Error?, Any?) -> (), Any?) -> ()]()
        
        for item in Locations.shared.items {
            queries.append(item.updateAssets)
            queries.append(item.update)
        }
        
        Async.waterfall(0, queries) { (error, values) in
            
            guard error == nil else {
                PKHUD.message(text: "Error")
                PKHUD.hide(animated: true)
                NotificationCenter.default.removeObserver(self)
                return
            }
            
            PKHUD.message(text: "Location Assets Updated")
            PKHUD.hide(animated: true)
            
            NotificationCenter.default.removeObserver(self)
        }
        
    }
    
    @objc fileprivate func systemMessageObserver(_ notification: Notification) {
        guard let userInfo = notification.userInfo as? JSON, let message = userInfo["system-message"] as? String else {
            return
        }
        
        PKHUD.message(text: message)
    }

    @objc fileprivate func showOnboardingAlert(_ sender: UITapGestureRecognizer) {
        
        Generator.bump()
        
        let alert = UIAlertController(title: "Alert", message: NSLocalizedString("SettingsViewController_OnboardingAlert_Message", comment: ""), preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("SettingsViewController_OnboardingAlert_Cancel", comment: ""), style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: NSLocalizedString("SettingsViewController_OnboardingAlert_Confirm", comment: ""), style: .default, handler: { (_) -> Void in

            DeviceSettings.shared.onboarded = false
            
            PKHUD.success()
        }))
        present(alert, animated: true, completion: nil)
    }
    
    @objc fileprivate func showLocationAssetUpdateAlert(_ sender: UITapGestureRecognizer) {
        
        Generator.bump()
        
        let alert = UIAlertController(title: "Alert", message: "This will use your phone to update the images for every location in your organization. It may take some time depending on the amount of locations and can not be cancelled once started" , preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Proceed", style: .default, handler: { (_) -> Void in
            
            self.updateLocationAssets()
            
        }))
        
        present(alert, animated: true, completion: nil)
    }
    
    @objc fileprivate func showDeleteCoreDataAlert(_ sender: UITapGestureRecognizer) {
        
        Generator.bump()
        
        let alert = UIAlertController(title: "Alert", message: "This will clear your offline data from Timeline, which will cause longer load times the next time you load the app. Cached photos will not be affected" , preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Proceed", style: .default, handler: { (_) -> Void in
            
            PKHUD.success()
            
            App.shared.clearAssetsCoreData()
            
        }))
        
        present(alert, animated: true, completion: nil)
    }
    
    @objc fileprivate func showDeletePhotoCoreDataAlert(_ sender: UITapGestureRecognizer) {
        
        Generator.bump()
        
        let alert = UIAlertController(title: "Alert", message: "This will clear the offline photo cache from Timeline, which will cause longer load times when you go to view photos" , preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Proceed", style: .default, handler: { (_) -> Void in
            
            PKHUD.success()
            
            App.shared.clearPhotosCoreData()
        }))
        
        present(alert, animated: true, completion: nil)
    }

    @objc override func applyTheme() {
        super.applyTheme()
        
        view.backgroundColor = Theme.shared.active.subHeaderBackgroundColor
        tableView.backgroundColor = Theme.shared.active.subHeaderBackgroundColor
        
        navBar?.rightButton.tintColor = UIColor.red
    }
}
