//
//  ProfileViewController.swift
//  Timesheets
//
//  Created by Zachary DeGeorge on 11/16/17.
//  Copyright © 2017 Timeline Software, LLC. All rights reserved.
//

import ActionSheetPicker_3_0
import Alamofire
import PKHUD
import UIKit
import CoreLocation
import Material
import Floaty
import SnapKit

// MARK: - ScheduleViewOverrideController

class Profile: ViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITableViewDelegate, UITableViewDataSource, FloatyDelegate, UIScrollViewDelegate {
    
    @IBOutlet var tableView: UITableView!
    @IBOutlet var fab: Floaty!

    fileprivate var fabState: SystemState?
    
    weak var user: User?
    
    var userStream: UserStream? {
        return Stream.shared[user?.id]
    }
    
    var sheet: Sheet? {
        return user?.sheet
    }
    
    var loaded: Bool {
        return self.sheet?.entries.loaded == true
    }
    
    var alphaHold: Bool = false
    var editAccess: Bool = false {
        didSet {
            if editAccess == true {
                if self.fab.alpha == 0.0 {
                    alphaHold = true
                    fab.alpha = 0.0
                    System.shared.alert(title: "Alert", message: String(format: "You are about to enable editing of %@'s time sheet. Do you wish to continue?", self.user?.fullName ?? "John Doe"), handler: { (action) in
                        UIView.animate(withDuration: 0.5, animations: {
                            self.fab.alpha = 1.0
                        }, completion: { (complete) in
                            self.alphaHold = false
                        })
                    }, cancel: {(action) in
                        self.editAccess = false
                    })
                }
            } else {
                UIView.animate(withDuration: 0.5, animations: {
                    self.fab.alpha = 0.0
                }, completion: { (action) in
                    self.fab.close()
                })
            }
        }
    }
    
    var active: Bool {
        if self.sheet != nil {
            return true
        } else {
            return false
        }
    }
    
    // MARK: - UIViewController Overrides
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.separatorStyle = .none

        let refreshControl = UIRefreshControl()
        refreshControl.alpha = 0.5
        refreshControl.backgroundColor = UIColor.clear
        refreshControl.addTarget(self, action: #selector(resetRefreshControl), for: UIControlEvents.valueChanged)
        tableView.refreshControl = refreshControl

        ProfileHeader.register(tableView)
        ProfileCell.register(tableView)
        StandardHeaderCell.register(tableView)
        SettingsSwitchCell.register(tableView)
        SettingsSelectionCell.register(tableView)
        SettingsBasicCell.register(tableView)
        StandardTextFieldCell.register(tableView)
        
        EntriesCell.register(tableView)
        EntriesHeaderCell.register(tableView)
        StandardTwoButtonCell.register(tableView)
        
        fab.buttonImage = AssetManager.shared.compose
        fab.tintColor = UIColor.white
        fab.plusColor = UIColor.white
        fab.itemImageColor = UIColor.white
        fab.buttonColor = Color.red.base
        fab.openAnimationType = .pop
        fab.isUserInteractionEnabled = true
        fab.hasShadow = true
        fab.alpha = 0
        fab.fabDelegate = self
        
        if user == nil {
            self.user = DeviceUser.shared.user
        } else {
            self.user?.sheet = self.userStream?.sheet
        }
    
        prepareFab()
        
        fab.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(toggleFab)))
        fab.isUserInteractionEnabled = true
        
        Notifications.shared.model_updated.observe(self, selector: #selector(modelUpdated))
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        prepareFab()
        
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        DispatchQueue.main.async {
            self.fab.setNeedsUpdateConstraints()
            self.fab.setNeedsLayout()
            
            self.fab.close()
            self.view.bringSubview(toFront: self.fab)
        }
    }
    
    @objc func modelUpdated(_ notification: NSNotification) {
        guard let data = notification.userInfo, let update = data["update"] as? ModelUpdate, App.shared.isLoaded == true else {
            return
        }
        
        if update.model is Sheet {
            self.tableView.reloadData()
        }
    }
    
    
    override func setupNavBar() {
        
        if let name = self.user?.fullName {
            navBar?.title = name
        } else {
            navBar?.title = "Profile"
        }
        
        navBar?.leftImage = AssetManager.shared.arrowLeft
        navBar?.leftEnclosure = { self.goBack() }
        
        if user !== DeviceUser.shared.user {
            navBar?.rightImage = AssetManager.shared.compose
            
            self.navBar?.rightEnclosure = {
                self.editAccess = !self.editAccess
            }
        }
    }
    
    @objc func toggleFab(_ sender: UITapGestureRecognizer) {
        if fab.closed == true {
            sender.view?.touchAnimation()
        } else {
            Generator.bump()
        }
        
        delay(fab.closed == true ? 0.2 : 0.0) {
            self.fab.toggle()
        }
    }
    
    /*
    func floatyWillClose(_ floaty: Floaty) {
        Generator.bump()
    }
    */
    
    @objc func loadTimesheet(_ sender: UIGestureRecognizer?) {
        Generator.bump()
        
        delay(0.2) {
            if let sheet = self.sheet {
                PKHUD.loading()
                Async.waterfall(nil, [sheet.entries.retrieve], end: { error, _ in
                    guard error == nil else {
                        PKHUD.failure()
                        return
                    }
                    
                    PKHUD.success()
                    self.fab.close()
                    self.prepareFab()
                    
                    DispatchQueue.main.async {
                        self.tableView.reloadData()
                    }
                })
            }
        }
    }
    
    @objc func resetRefreshControl() {
        guard self.active, let sheet = self.sheet, self.loaded, self.user !== DeviceUser.shared.user else {
            self.tableView.refreshControl?.endRefreshing()
            self.goBack()
            return
        }
        
        Async.waterfall(nil, [sheet.entries.retrieve]) { (error, _) in
            self.tableView.refreshControl?.endRefreshing()
            
            guard error == nil else {
                PKHUD.failure()
                return
            }
            
            self.tableView.reloadData()
            self.prepareFab()
        }
    }

    // MARK: - UITableView Delegate and DataSource

    func numberOfSections(in _: UITableView) -> Int {
        if user?.id == Auth.shared.id {
            return 2
        } else {
            return 5
        }
    }

    func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 1
        case 1:
            return 3
        case 2:
            if self.loaded {
                return 2
            } else {
                if self.active, let entry = self.userStream?.entry {
                    if entry.activity?.breaking == true {
                        return 5
                    } else {
                        return 6
                    }
                } else {
                    return self.active == true ? 6 : 2
                }
            }
        case 3:
            return self.sheet?.entries.count ?? 0
        case 4:
            return 2
        default:
            return 0
        }
    }

    func tableView(_: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.section {
        case 0:
            return self.user === DeviceUser.shared.user ? 235 : 275
        case 1:
            return 40
        case 2:
            switch indexPath.row {
            case 0:
                return 40
            default:
                return self.active && self.loaded ? EntriesHeaderCell.cellHeight : 40
            }
        case 3:
            return EntriesCell.cellHeight
        case 4:
            return indexPath.row == 0 ? 40 : 60
        default:
            return 0
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            let cell = ProfileHeader.loadNib(tableView)

            cell.populate(user ?? DeviceUser.shared.user)

            if user === DeviceUser.shared.user {
                cell.profilePicture.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(openPhotoLibrary)))
                cell.profilePicture.isUserInteractionEnabled = true

                cell.cameraButton.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(openPhotoLibrary)))
                cell.cameraButton.isUserInteractionEnabled = true
            } else {
                cell.profilePicture.animateTouch()
            }

            cell.selectionStyle = .none
            return cell
        case 1:
            switch indexPath.row {
            case 0:
                let cell = StandardHeaderCell.loadNib(tableView)

                cell.title.text = "Info"
                cell.footer.text = ""

                cell.title.textColor = Theme.shared.active.placeholderColor
                cell.selectionStyle = .none
                return cell
            case 1:
                let cell = StandardTextFieldCell.loadNib(tableView)
                
                cell.label.text = "Phone"
                cell.contents.text = user?.readablePhoneNumber
                cell.contents.isUserInteractionEnabled = false
                
                cell.carrot.alpha = 1.0
                cell.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(call)))
                cell.isUserInteractionEnabled = true
                
                cell.selectionStyle = .none
                return cell
            case 2:
                let cell = StandardTextFieldCell.loadNib(tableView)
                
                let count: Int = user?.photos.count ?? 0
                cell.label.text = "Photos"
                cell.contents.text = String(format: "%i", arguments: [count])
                
                cell.contents.isUserInteractionEnabled = false
                
                if count > 0 {
                    cell.carrot.alpha = 1.0
                    cell.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(goToPhotos)))
                    cell.isUserInteractionEnabled = true
                } else {
                    cell.carrot.alpha = 0.0
                }
                
                cell.selectionStyle = .none
                return cell
            default:
                return UITableViewCell.defaultCell()
            }
        case 2:
            if self.active && self.loaded {
                switch indexPath.row {
                case 0:
                    let cell = StandardHeaderCell.loadNib(tableView)
                    
                    cell.title.text = "Timesheet"
                    cell.footer.text = ""
                    
                    cell.title.textColor = Theme.shared.active.placeholderColor
                    cell.selectionStyle = .none
                    return cell
                default:
                    let cell = EntriesHeaderCell.loadNib(self.tableView)
                    
                    cell.populate(self.sheet)
                    cell.contentView.backgroundColor = UIColor.white
                    
                    cell.selectionStyle = .none
                    return cell
                }
            } else {
                switch indexPath.row {
                case 0:
                    let cell = StandardHeaderCell.loadNib(tableView)
                    
                    cell.title.text = "Status"
                    cell.footer.text = ""
                    
                    cell.title.textColor = Theme.shared.active.placeholderColor
                    cell.selectionStyle = .none
                    return cell
                case 1:
                    let cell = StandardTextFieldCell.loadNib(tableView)
                    
                    cell.label.text = "Timesheet"
                    cell.contents.text = self.active ? "Clocked-In" : "Clocked-Out"
                    cell.contents.isUserInteractionEnabled = false
                    cell.carrot.alpha = 0.0
                    
                    cell.selectionStyle = .none
                    return cell
                case 2:
                    let cell = StandardTextFieldCell.loadNib(tableView)
                    
                    cell.label.text = "Total Duration"
                    let start = self.sheet?.date ?? Date()
                    let seconds = -start.timeIntervalSinceNow
                    
                    cell.contents.text = String(format: "%1.0fh %1.0fm", clockHours(seconds), clockMinutes(seconds))
                    cell.contents.isUserInteractionEnabled = false
                    
                    cell.carrot.alpha = 0.0
                    
                    cell.selectionStyle = .none
                    return cell
                    
                case 3:
                    let cell = StandardTextFieldCell.loadNib(tableView)
                    
                    cell.label.text = "Activity"
                    cell.contents.text = self.loaded ? self.sheet?.entries.latest?.activity?.name : self.userStream?.entry?.activity?.name ?? "Empty"
                    cell.contents.isUserInteractionEnabled = false
                    cell.carrot.alpha = 0.0
                    
                    cell.selectionStyle = .none
                    return cell
                case 4:
                    let cell = StandardTextFieldCell.loadNib(tableView)
                    
                    if self.userStream?.entry?.activity?.breaking == true {
                        cell.label.text = ""
                        cell.contents.text = "Load Timesheet"
                        cell.contents.isUserInteractionEnabled = false
                        cell.carrot.alpha = 1.0
                        cell.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(loadTimesheet)))
                        cell.isUserInteractionEnabled = true
                    } else if self.userStream?.entry?.activity?.traveling == false {
                        cell.label.text = "Location"
                        cell.contents.text = self.userStream?.entry?.location?.name ?? "Empty"
                        cell.contents.isUserInteractionEnabled = false
                        cell.carrot.alpha = self.userStream?.entry?.location?.name != nil ? 1.0 : 0.0
                        cell.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(viewLocation)))
                        cell.isUserInteractionEnabled = true
                    } else {
                        cell.label.text = "Distance"
                        let meters = self.userStream?.entry?.meters ?? 0
                        
                        cell.contents.text = String(format: "%0.1f mi", CONVERSION_METERS_TO_MILES_MULTIPLIER * meters)
                        cell.contents.isUserInteractionEnabled = false
                        cell.carrot.alpha = 0.0
                    }
                    
                    
                    cell.selectionStyle = .none
                    return cell
                case 5:
                    let cell = StandardTextFieldCell.loadNib(tableView)
                    
                    cell.label.text = ""
                    cell.contents.text = "Load Timesheet"
                    cell.contents.isUserInteractionEnabled = false
                    cell.carrot.alpha = 1.0
                    cell.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(loadTimesheet)))
                    cell.isUserInteractionEnabled = true
                    cell.selectionStyle = .none
                    return cell
                default:
                    return UITableViewCell.defaultCell()
                }
            }
        case 3:
            let cell = EntriesCell.loadNib(tableView)
            
            cell.threeDTouchAvailable = false // self.is3DTouchAvailable()
            cell.populate(self.sheet, index: indexPath.row)
            cell.contentView.backgroundColor = UIColor.white
            
            return cell
        case 4:
            switch indexPath.row {
            case 0:
                let cell = StandardHeaderCell.loadNib(tableView)
                
                cell.title.text = "More"
                cell.footer.text = ""
                
                cell.title.textColor = Theme.shared.active.placeholderColor
                cell.selectionStyle = .none
                return cell
            case 1:
                let cell = StandardTwoButtonCell.loadNib(tableView)
                
                cell.leftButton.style(Color.blue.base, image: nil, title: "History")
                cell.rightButton.style(Color.blue.base, image: nil, title: "Create Sheet")
                cell.rightButton.alpha = self.active ? 0.0 : 1.0
                
                cell.leftButton.addTarget(self, action: #selector(viewHistory), for: .touchUpInside)
                cell.rightButton.addTarget(self, action: #selector(createTimesheet), for: .touchUpInside)
                
                cell.selectionStyle = .none
                return cell
            default:
                return UITableViewCell.defaultCell()
            }
        default:
            return UITableViewCell.defaultCell()
        }
    }
    
    func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let value = cell as? EntriesHeaderCell {
            value.updates = false
        } else if let value = cell as? EntriesCell {
            value.updates = false
        }
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let value = cell as? EntriesHeaderCell {
            value.updates = true
        } else if let value = cell as? EntriesCell {
            value.updates = indexPath.row == 0
        }
    }
    
    
    func tableView(_: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return indexPath.section == 3
    }
    
    func tableView(_: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        
        guard indexPath.section == 3 else {
            return []
        }
        
        let deleteRowAction = UITableViewRowAction(style: UITableViewRowActionStyle.destructive, title: "Delete", handler: { _, _ in
            
            Generator.bump()
            
            PKHUD.loading()
            
            self.sheet?.entries.items[indexPath.row].delete({ success in
                guard success == true else {
                    PKHUD.failure()
                    return
                }
                
                PKHUD.success()
                self.tableView.reloadData()
                self.fab.close()
                self.prepareFab()
            })
        })
        
        let editRowAction = UITableViewRowAction(style: UITableViewRowActionStyle.default, title: "Edit", handler: { _, _ in
            
            Generator.bump()
            
            let destination = UIStoryboard.Main(identifier: "EntryEdit") as? EntryEdit
            
            destination?.sheet = self.sheet
            destination?.index = indexPath.row
            destination?.mode = ViewingMode.Editing
            
            Presenter.push(destination!, animated: true, completion: nil)
            
        })
        
        editRowAction.backgroundColor = UIColor.gray.withAlphaComponent(0.75)
        deleteRowAction.backgroundColor = UIColor.red.withAlphaComponent(0.75)
        
        return [editRowAction, deleteRowAction]
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        UIView.animate(withDuration: 0.25, animations: {
            self.fab.alpha = 0.0
        })
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        guard alphaHold == false else {
            return
        }
        
        delay(0.5) {
            UIView.animate(withDuration: 0.25, animations: {
                self.fab.alpha = self.editAccess ? 1.0 : 0.0
            })
        }
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        guard alphaHold == false else {
            return
        }
        
        delay(0.5) {
            UIView.animate(withDuration: 0.25, animations: {
                self.fab.alpha = self.editAccess ? 1.0 : 0.0
            })
        }
    }
        
        
        /*
         switch indexPath.row {
         case 0:
         let cell = StandardHeaderCell.loadNib(tableView)
         
         cell.title.text = "Notifications"
         cell.footer.text = ""
         
         cell.title.textColor = Theme.shared.active.placeholderColor
         cell.selectionStyle = .none
         return cell
         case 1:
         let cell = SettingsSwitchCell.loadNib(tableView)
         
         cell.label.text = "Clock In/Out Alerts"
         cell.onSwitch.setOn(DeviceSettings.shared.getUserSheetAlerts(self.user!.id!), animated: false)
         cell.onSwitch.addTarget(self, action: #selector(switchValueChanged), for: .valueChanged)
         cell.onSwitch.tag = 1
         cell.onSwitch.tintColor = Theme.shared.active.primaryBackgroundColor
         cell.onSwitch.thumbTintColor = Theme.shared.active.primaryBackgroundColor
         cell.icon.image = AssetManager.shared.timesheetGlyph
         cell.icon.tintColor = Theme.shared.active.alternativeFontColor
         cell.backgroundColor = UIColor.white
         
         cell.selectionStyle = .none
         return cell
         case 2:
         let cell = SettingsSwitchCell.loadNib(tableView)
         
         cell.label.text = "Time Entry Alerts"
         cell.onSwitch.setOn(DeviceSettings.shared.getUserEntryAlerts(self.user!.id!), animated: false)
         cell.onSwitch.addTarget(self, action: #selector(switchValueChanged), for: .valueChanged)
         cell.onSwitch.tag = 2
         cell.onSwitch.tintColor = Theme.shared.active.primaryBackgroundColor
         cell.onSwitch.thumbTintColor = Theme.shared.active.primaryBackgroundColor
         cell.icon.image = AssetManager.shared.date?.withRenderingMode(.alwaysTemplate)
         cell.icon.tintColor = Theme.shared.active.alternativeFontColor
         cell.backgroundColor = UIColor.white
         
         cell.selectionStyle = .none
         return cell
         case 3:
         let cell = SettingsSwitchCell.loadNib(tableView)
         
         cell.label.text = "Photo Alerts"
         cell.onSwitch.setOn(DeviceSettings.shared.getUserPhotoAlerts(self.user!.id!), animated: false)
         cell.onSwitch.addTarget(self, action: #selector(switchValueChanged), for: .valueChanged)
         cell.onSwitch.tag = 3
         cell.onSwitch.tintColor = Theme.shared.active.primaryBackgroundColor
         cell.onSwitch.thumbTintColor = Theme.shared.active.primaryBackgroundColor
         cell.icon.image = AssetManager.shared.camera?.withRenderingMode(.alwaysTemplate)
         cell.icon.tintColor = Theme.shared.active.alternativeFontColor
         cell.backgroundColor = UIColor.white
         
         cell.selectionStyle = .none
         return cell
         default:
         return UITableViewCell.defaultCell()
         }
         */

    // MARK: - Other Functions
    
    @objc func viewLocation() {
        Generator.bump()
        
        if let location = userStream?.entry?.location {
            location.view()
        }
    }
    
    @objc func viewHistory() {
        self.user?.history()
    }
    
    @objc func call() {
        Generator.bump()
        
        delay(0.2) {
            External.shared.dial(self.user?.phoneNumber)
        }
    }
    
    @objc func switchValueChanged(_ sender: UISwitch) {
        Generator.bump()
        
        switch sender.tag {
        case 1:
            DeviceSettings.shared.setUserSheetAlerts(self.user!.id!, value: sender.isOn)
            break
        case 2:
            DeviceSettings.shared.setUserEntryAlerts(self.user!.id!, value: sender.isOn)
            break
        case 3:
            DeviceSettings.shared.setUserPhotoAlerts(self.user!.id!, value: sender.isOn)
            break
        default:
            break
        }
    }

    @objc func openPhotoLibrary(_ sender: Any?) {
        
        (sender as? UITapGestureRecognizer)?.view?.touchAnimation()

        guard UIImagePickerController.isSourceTypeAvailable(.photoLibrary) else {
            PKHUD.failure()
            return
        }
        
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .photoLibrary
        imagePicker.allowsEditing = true

        delay(0.2) {
            Presenter.present(imagePicker, animated: true, completion: {
                
            })
        }
        
    }

    @objc func updateFavorited(_ sender: Any?) {
        
        (sender as? UITapGestureRecognizer)?.view?.touchAnimation()
        
        guard let user = self.user else {
            return
        }

        self.setFavorite(!user.favorite)
    }
    
    func setFavorite(_ bool: Bool) {
        
        Generator.bump()
        
        switch bool {
        case true:
            self.user!.favorite = bool
            if let cell = self.tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? ProfileHeader {
                cell.setFavorite(bool)
            }
            PKHUD.sharedHUD.contentView = PKHUDTextView(text: "Added to Favorites")
            PKHUD.sharedHUD.show()
            PKHUD.sharedHUD.hide(afterDelay: DEFAULT_PKHUD_TEXT_TIMEOUT / 2)
            break
        case false:
            self.user!.favorite = bool
            if let cell = self.tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? ProfileHeader {
                cell.setFavorite(bool)
            }
            PKHUD.sharedHUD.contentView = PKHUDTextView(text: "Removed from Favorites")
            PKHUD.sharedHUD.show()
            PKHUD.sharedHUD.hide(afterDelay: DEFAULT_PKHUD_TEXT_TIMEOUT / 2)
        }
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String: Any]) {
        PKHUD.loading()

        guard let image = info[UIImagePickerControllerEditedImage] as? UIImage, let user = self.user else {
            PKHUD.failure()
            picker.dismiss(animated: true, completion: nil)
            return
        }
        
        user.photo = UIImage.resizeImage(image: image, targetSize: CGSize(width: 200.0, height: 200.0)).base64String()
        
        user.update { success in
            guard success == true else {
                PKHUD.failure()
                picker.dismiss(animated: true, completion: nil)
                return
            }
            
            // Update Photo in TableView
            let indexPath = IndexPath(row: 0, section: 0)
            let header = self.tableView.cellForRow(at: indexPath) as! ProfileHeader
            
            header.profilePicture.image = image
            Sidebar.refresh()
            
            PKHUD.success()
            picker.dismiss(animated: true, completion: nil)
        }
    }
    
    @objc func goToPhotos() {
        
        Generator.bump()
        
        user?.photos.view(title: user?.fullName)
    }
    
    override func prepareForDeinit() {
        super.prepareForDeinit()
        
        for cell in tableView.visibleCells {
            if let value = cell as? EntriesCell {
                value.updates = false
            } else if let value = cell as? EntriesHeaderCell {
                value.updates = false
            }
        }
        
        for item in fab.items {
            fab.removeItem(item: item)
        }
        
        fab.removeFromSuperview()
    }

    @objc override func applyTheme() {
        super.applyTheme()
        
        navBar?.backgroundColor = Theme.shared.active.primaryBackgroundColor
        view.backgroundColor = Theme.shared.active.primaryBackgroundColor
        tableView.backgroundColor = Theme.shared.active.primaryBackgroundColor
    }
    
    
    @objc func toggleFab(_ sender: Any?, silent: Bool = false) {
        if fab.closed == true {
            (sender as? UITapGestureRecognizer)?.view?.touchAnimation(silent)
        } else {
            if !silent {
                Generator.bump()
            }
        }
        
        delay(fab.closed == true ? 0.2 : 0.0) {
            self.fab.toggle()
        }
    }
    
    @objc func prepareFab() {
        
        populateFab()
        
        DispatchQueue.main.async { [weak self] in
            guard let _self = self else {
                return
            }
            
            for item in _self.fab.items {
                let font = UIFont(name: DEFAULT_SYSTEM_FONT_NAME, size: 13.5)
                item.titleLabel.font = font
                item.titleLabel.textAlignment = .right
                item.isUserInteractionEnabled = true
            }
        }
    }
    
    func populateFab() {
        fab.clear(shortcuts: false)
        
        if self.active {
            if self.loaded == false {
                fab.addItem(item: FloatyItem.downloadTimesheet(target: self, action: #selector(loadTimesheet)))
            } else {
                fab.addItem(item: FloatyItem.entryItem(target: self, action: #selector(manualEntryCreate), addShortcut: false))
                
                if self.sheet?.entries.latest?.activity?.breaking == true {
                    fab.addItem(item: FloatyItem.endBreakItem(target: self, action: #selector(manualEntryCreate), addShortcut: false))
                } else if let _ = self.sheet?.entries.latest?.activity?.name {
                    fab.addItem(item: FloatyItem.breakItem(target: self, action: #selector(createBreakEntry), addShortcut: false))
                }
                
                if self.sheet?.entries.count == 0 {
                    fab.addItem(item: FloatyItem.deleteItem(target: self, action: #selector(submitTimeSheet), addShortcut: false))
                } else {
                    fab.addItem(item: FloatyItem.submitItem(target: self, action: #selector(submitTimeSheet), addShortcut: false))
                }
            }
        } else {
            fab.addItem(item: FloatyItem.timesheetItem(target: self, action: #selector(createTimesheet), addShortcut: false))
        }
    }
    
    @objc func createBreakEntry(_ sender: Any?) {
        (sender as? UITapGestureRecognizer)?.view?.touchAnimation()
        
        delay(0.2) {
            self.fab.close()
            
            let entry = Entry()
            entry.activity = Activities.shared.breakActivity
            entry.paidTime = false
            entry.autoGenerated = false
            entry.start = Date()
            entry.user = self.user
            entry.sheet = self.sheet
            
            DispatchQueue.main.async {
                PKHUD.loading()
                
                Async.waterfall(nil, [entry.create]) { error, _ in
                    
                    guard error == nil else {
                        PKHUD.failure()
                        return
                    }
                    
                    PKHUD.success()
                    self.tableView.reloadData()
                    self.fab.close()
                    self.prepareFab()
                }
            }
        }
    }
    
    
    
    @objc func createTimesheet(_ sender: Any?) {
        (sender as? UITapGestureRecognizer)?.view?.touchAnimation()
        
        self.fab.close()
        delay(0.2) {
            
            let minimum = Date(timeIntervalSince1970: 0)
            let maximum = Date()
            
            let picker = ActionSheetDatePicker(title: "Select Start Time", datePickerMode: UIDatePickerMode.dateAndTime, selectedDate: maximum, minimumDate: minimum, maximumDate: maximum, target: self, action: #selector(self.commitCreateTimesheet), cancelAction: nil, origin: self.view)
            
            picker?.maximumDate = maximum
            picker?.minimumDate = minimum
            
            self.styleActionSheetDatePicker(picker)
            
            picker?.show()
        }
    }
    
    
    @objc func commitCreateTimesheet(_ date: Date) {
        if let user = self.user {
            let sheet: Sheet = Sheet()
            sheet.user = user.id
            sheet.date = date
            
            PKHUD.loading()
            Async.waterfall(nil, [sheet.create,sheet.entries.retrieve], end: { (error, _) in
                guard error == nil else {
                    PKHUD.failure()
                    return
                }
                
                PKHUD.success()
                self.user?.sheet = sheet
                self.fab.close()
                
                delay(0.3) {
                    DispatchQueue.main.async {
                        self.tableView.reloadData()
                        self.prepareFab()
                        
                        UIView.animate(withDuration: 0.5, animations: {
                            self.fab.alpha = 1.0
                        }, completion: { (complete) in
                            self.editAccess = true
                        })
                    }
                }
                
                Async.waterfall(nil, [Stream.shared.retrieve], end: { (_, _) in })
            })
        }
    }
    
    
    @objc func manualEntryCreate(_ sender: Any?) {
        (sender as? UITapGestureRecognizer)?.view?.touchAnimation()
        
        delay(0.2) {
            self.fab.close()
            
            let destination = UIStoryboard.Main(identifier: "EntryCreate") as! EntryCreate
            destination.sheet = self.sheet
            
            let navigation = UINavigationController(rootViewController: destination)
            navigation.navigationBar.isHidden = true
            
            Presenter.present(navigation, animated: true, completion: nil)
        }
    }
    
    @objc func submitTimeSheet(sender: Any?) {
        (sender as? UITapGestureRecognizer)?.view?.touchAnimation()
        
        guard let sheet = self.sheet else {
            return
        }
        
        if let minimum = sheet.entries.latest?.start {
            let maximum = Date()
            
            let picker = ActionSheetDatePicker(title: "Select End Time", datePickerMode: UIDatePickerMode.dateAndTime, selectedDate: maximum, minimumDate: minimum, maximumDate: maximum, target: self, action: #selector(self.commitTimesheet), cancelAction: nil, origin: self.view)
            
            picker?.maximumDate = maximum
            picker?.minimumDate = minimum
            
            self.styleActionSheetDatePicker(picker)
            
            picker?.show()
        } else {
            PKHUD.loading()
            sheet.delete({ success in
                guard success == true else {
                    PKHUD.failure()
                    return
                }
                
                PKHUD.success()
                self.user?.sheet = nil
                self.userStream?.sheet = nil
                self.fab.close()
                
                delay(0.3) {
                    DispatchQueue.main.async {
                        self.editAccess = false
                        self.tableView.reloadData()
                        self.prepareFab()
                    }
                }
            })
        }
        
    }

    @objc func commitTimesheet(_ date: Date) {
        
        guard let sheet = self.sheet, let user = Users.shared[sheet.user] else {
            return
        }
        
        sheet.submissionDate = date
        
        PKHUD.loading()
        Async.waterfall(nil, [sheet.submit, user.retrieveStatistics, Stream.shared.retrieve]) { error, _ in
            guard error == nil else {
                PKHUD.failure()
                return
            }
            
            PKHUD.success()
            
            self.user?.sheet = nil
            self.userStream?.sheet = nil
            self.fab.close()
            
            delay(0.3) {
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                    self.prepareFab()
                }
            }
        }
    }
}
