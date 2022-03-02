//
//  Main.swift
//  Timeline FM
//
//  Created by Zachary DeGeorge on 10/15/18.
//  Copyright © 2018 Next Day Project. All rights reserved.
//

import UIKit
import PKHUD
import Material
import Floaty
import ActionSheetPicker_3_0
import SwiftReorder
import WaterDrops
import AssetsLibrary
import Photos
import TTGSnackbar
import IQKeyboardManagerSwift

// MARK: - Main

class Main: ViewController, UITableViewDelegate, UITableViewDataSource, SidebarSectionProtocol, FloatyDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    static var section: String { return "Shift" }
    
    @IBOutlet var tableView: UITableView!
    fileprivate var fabState: SystemState?
    @IBOutlet var fab: Floaty!
    @IBOutlet var tabViewHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet var tabAllIcon: UIImageView!
    @IBOutlet var tabAllLabel: UILabel!
    @IBOutlet var tabAllButton: FlatButton!
    @IBOutlet var tabZonesIcon: UIImageView!
    @IBOutlet var tabZonesLabel: UILabel!
    @IBOutlet var tabZonesButton: FlatButton!
    @IBOutlet var tabContainerView: UIView!
    @IBOutlet var emptyImage: UIImageView!
    
    enum MainTabs: Int {
        case Shift = 1
        case Tasks = 2
    }
    
    var currentTab: MainTabs = .Shift
    
    var initialLoad: Bool = true
    static var order: [MainSectionStyle] = [.User, .Location, .Entry, .Sheet]
    static var sections: [MainSectionContainer] = []
    
    var cursor: Cursor?
    
    // MARK: - UIViewController Overrides
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        fab.fabDelegate = self
        
        tableView.backgroundColor = UIColor.clear
        
        
        let refreshControl = UIRefreshControl()
        refreshControl.alpha = 0.5
        refreshControl.backgroundColor = UIColor.clear
        refreshControl.addTarget(self, action: #selector(resetRefreshControl), for: UIControlEvents.valueChanged)
        tableView.refreshControl = refreshControl
        
        tabViewHeightConstraint.constant = 0 // Device.hasNotch == true ? tabViewHeightConstraint.constant : tabViewHeightConstraint.constant - TIMELINE_STATUS_VIEW_HEIGHT_DIFFERENCE
        
        tableView.contentInset = UIEdgeInsetsMake(15.0, 0, tabViewHeightConstraint.constant, 0)
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false
        tableView.isScrollEnabled = true
        tableView.masksToBounds = false
        tableView.clipsToBounds = false
        
        tabAllIcon.image = AssetManager.shared.history
        tabZonesIcon.image = AssetManager.shared.activity
        
        tabAllButton.tag = MainTabs.Shift.rawValue
        tabZonesButton.tag = MainTabs.Tasks.rawValue
        
        //tabAllButton.animateTouch()
        //tabZonesButton.animateTouch()
        
        tabAllButton.addTarget(self, action: #selector(setTabs), for: .touchUpInside)
        tabZonesButton.addTarget(self, action: #selector(setTabs), for: .touchUpInside)
        
        fab.buttonImage = AssetManager.shared.compose
        fab.tintColor = UIColor.white
        fab.plusColor = UIColor.white
        fab.itemImageColor = UIColor.white
        fab.buttonColor = Color.blue.darken3
        fab.openAnimationType = .pop
        fab.isUserInteractionEnabled = true
        fab.hasShadow = true
        fab.alpha = 1.0
        fab.fabDelegate = self
        
        fab.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(toggleFab)))
        fab.isUserInteractionEnabled = true
        
        setTabs(tabAllButton, silent: true)
        
        prepareFab()
        
        EntriesCell.register(tableView)
        EntriesHeaderCell.register(tableView)
        MainSectionContainer.register(tableView)
        
        Notifications.shared.model_updated.observe(self, selector: #selector(modelUpdated))
        
        emptyImage.addGestureRecognizer(UITapGestureRecognizer(target: self, action: System.shared.state == .Empty ? #selector(manualEntryCreate) : #selector(createTimesheet)))
        emptyImage.isUserInteractionEnabled = true
        emptyImage.tintColor = UIColor.black
        
        self.view.alpha = 0.0
        self.tableView.alpha = System.shared.active || System.shared.state == .Empty ? 1.0 : 0.0
        self.emptyImage.alpha = System.shared.active ? 0.0 : 1.0
        self.tableView.isScrollEnabled = System.shared.active
        self.emptyImage.image = System.shared.state == .Empty || System.shared.active == true ? AssetManager.shared.emptyTimesheet : AssetManager.shared.noTimesheet
        
        
        //self.cursor = Cursor(parent: self)
        
        //self.view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.touch)))
        
        delay(0.5) {
            UIView.animate(withDuration: 0.5, animations: {
                self.view.alpha = 1.0
            }, completion: { (complete) in
                //self.cursor?.show()
            })
        }
 
    }
    
    @objc func touch(sender: UIGestureRecognizer) {
        if sender.state == .ended {
            let point = sender.location(in: self.view)
            self.cursor?.move(point: point)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        LocationManager.shared.updateHold(false)
        
        IQKeyboardManager.shared.enable = false
        
        if initialLoad {
            initialLoad = false
        } else {
            tableView.reloadData()
        }
        
        self.styleNavBar()
        self.view.bringSubview(toFront: self.fab)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        tableView.sizeThatFits(UIScreen.main.bounds.size)
        
        
        DispatchQueue.main.async {
            self.fab.setNeedsUpdateConstraints()
            self.fab.setNeedsLayout()
            
            self.fab.close()
            self.view.bringSubview(toFront: self.fab)
        }
        
        delay(2.0) {
            self.cursor?.move(point: self.fab.center)
            
            delay(1.0, closure: {
                self.cursor?.press()
                
                delay(1.0, closure: {
                    self.cursor?.move(point: CGPoint(x: 30, y: 120))
                    
                    
                    delay(1.0, closure: {
                        self.cursor?.move(point: CGPoint(x: 30, y: 120))
                        
                        delay(1.0, closure: {
                            self.cursor?.press()
                        })
                    })
                })
            })
            
            
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        
        if let tableView = tableView {
            for cell in tableView.visibleCells {
                if let value = cell as? MainSectionContainer {
                    value.updates = false
                    
                    for object in value.objects {
                        object.update = false
                    }
                } else if let value = cell as? EntriesHeaderCell {
                    value.updates = false
                } else if let value = cell as? EntriesCell {
                    value.updates = false
                }
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
    
    func styleNavBar(_ sender: Any? = nil) {
        
        let isBreak: Bool = System.shared.state == .Break ? true : false
        let isTraveling: Bool = System.shared.state == .Traveling ? true : false
        
        //setBubbleAnimation(on: false)
        //setBubbleAnimation(on: isActive ? true : false)
        
        if isBreak || isTraveling {
            
            UIView.animate(withDuration: 0.0, animations: {
                self.fab.alpha = 0.0
            })
            
            UIView.transition(with: self.tabContainerView, duration: 0.66, options: .curveLinear, animations: {
                if isBreak {
                    self.navBar?.background = Color.orange.darken4.withAlphaComponent(0.95)
                    self.tabContainerView.backgroundColor = Color.orange.darken4.withAlphaComponent(0.95)
                    
                } else if isTraveling {
                    self.navBar?.background = Color.blue.darken4.withAlphaComponent(0.95)
                    self.tabContainerView.backgroundColor = Color.blue.darken4.withAlphaComponent(0.95)
                }
                
                self.navBar?.leftButton.tintColor = UIColor.white
                self.navBar?.rightButton.tintColor = UIColor.white
                self.navBar?.titleLabel.textColor = UIColor.white
                
                self.setTabs(self.tabAllButton /* self.currentTab == .Shift ? self.tabAllButton : self.tabUsersButton*/, silent: true)
                
            }, completion: { (success) in
                guard success == true else {
                    return
                }
                
                UIView.animate(withDuration: 0.25, animations: {
                    self.fab.alpha = 1.0
                })
            })
            
        } else {
            
            UIView.animate(withDuration: 0.0, animations: {
                self.fab.alpha = 0.0
            })
            
            UIView.transition(with: self.tabContainerView, duration: 0.66, options: .curveLinear, animations: {
                
                super.applyTheme()
                
                self.navBar?.background = System.shared.state == .LoggedIn ? Color.green.darken4.withAlphaComponent(0.95) : Theme.shared.active.primaryBackgroundColor.withAlphaComponent(0.95)
                self.tabContainerView.backgroundColor = System.shared.state == .LoggedIn ? Color.green.darken4.withAlphaComponent(0.95) : Theme.shared.active.primaryBackgroundColor.withAlphaComponent(0.95)
                self.setTabs(self.tabAllButton /*self.currentTab == .Shift ? self.tabAllButton : self.tabUsersButton*/, silent: true)
                
                self.navBar?.leftButton.tintColor = System.shared.state == .LoggedIn ? UIColor.white : self.navBar?.leftButton.tintColor
                self.navBar?.rightButton.tintColor = System.shared.state == .LoggedIn ? UIColor.white : self.navBar?.leftButton.tintColor
                self.navBar?.titleLabel.textColor = System.shared.state == .LoggedIn ? UIColor.white : self.navBar?.leftButton.tintColor
                
            }, completion: { (success) in
                guard success == true else {
                    return
                }
                
                UIView.animate(withDuration: 0.25, animations: {
                    self.fab.alpha = 1.0
                })
            })
        }
    }
    
    override func setupNavBar() {
        navBar?.title = currentTab == .Shift ? "Shift" : "Tasks"
        
        navBar?.leftImage = AssetManager.shared.menu
        navBar?.leftEnclosure = { self.menuPressed() }
        
        navBar?.rightImage = AssetManager.shared.camera
        navBar?.rightEnclosure = {
            
            let camera = Camera(source: self)
            
            camera.PresentPhotoInput(target: self)
        }
    }
    
    override func prepareForDeinit() {
        super.prepareForDeinit()
        
        for cell in tableView?.visibleCells ?? [] {
            if let value = cell as? MainSectionContainer {
                value.updates = false
            } else if let value = cell as? EntriesHeaderCell {
                value.updates = false
            } else if let value = cell as? EntriesCell {
                value.updates = false
            }
        }
        
        for item in fab?.items ?? [] {
            fab.removeItem(item: item)
        }
        
        fab?.removeFromSuperview()
    }
    
    @objc func modelUpdated(_ notification: NSNotification) {
        
        guard App.shared.isLoaded == true else {
            return
        }
        
        guard let data = notification.userInfo, let update = data["update"] as? ModelUpdate, App.shared.isLoaded == true else {
            return
        }
        
        if update.type == ModelType.Sheet {
            
            prepareFab()
            
            if update.action != .Update {
                PKHUD.success()
            }
            
            self.styleNavBar()
            self.tableView.reloadData()
            
            for gesture in self.emptyImage.gestureRecognizers ?? [] {
                emptyImage.removeGestureRecognizer(gesture)
            }
            
            emptyImage.addGestureRecognizer(UITapGestureRecognizer(target: self, action: System.shared.state == .Empty ? #selector(manualEntryCreate) : #selector(createTimesheet)))
            emptyImage.isUserInteractionEnabled = true
            UIView.animate(withDuration: 0.5, animations: {
                self.emptyImage.image = System.shared.state == .Empty || System.shared.active == true ? AssetManager.shared.emptyTimesheet : AssetManager.shared.noTimesheet
                self.tableView.alpha = System.shared.active || System.shared.state == .Empty ? 1.0 : 0.0
                self.emptyImage.alpha = System.shared.active ? 0.0 : 1.0
                self.tableView.isScrollEnabled = System.shared.active
            }, completion: nil)
        }
        
        if update.model is Entry, let _entry = update.model as? Entry, _entry.sheet?.id == DeviceUser.shared.sheet?.id {
            
            prepareFab()
            
            self.styleNavBar()
            self.tableView.reloadData()
            
            
            for gesture in self.emptyImage.gestureRecognizers ?? [] {
                emptyImage.removeGestureRecognizer(gesture)
            }
            
            emptyImage.addGestureRecognizer(UITapGestureRecognizer(target: self, action: System.shared.state == .Empty ? #selector(manualEntryCreate) : #selector(createTimesheet)))
            emptyImage.isUserInteractionEnabled = true
            UIView.animate(withDuration: 0.5, animations: {
                self.emptyImage.image = System.shared.state == .Empty ? AssetManager.shared.emptyTimesheet : AssetManager.shared.noTimesheet
                self.tableView.alpha = System.shared.active || System.shared.state == .Empty ? 1.0 : 0.0
                self.emptyImage.alpha = System.shared.active ? 0.0 : 1.0
                self.tableView.isScrollEnabled = System.shared.active
            }, completion: nil)
            
            /*
            delay(0.3) {
                self.styleNavBar()
            }
            
            if currentTab == .Status {
                UIView.animateAndChain(withDuration: 0.3, delay: 0.0, options: [], animations: {
                    for section in Main.sections {
                        section.reload(collapse: false)
                    }
                }, completion: nil).animate(withDuration: 0.3, animations: {
                    self.setTabs(self.tabUsersButton, silent: true)
                }, completion: nil)
            } else {
                self.tableView.reloadData()
            }
             */
        }
        
        if update.model is Photo {
            
            self.styleNavBar()
            self.tableView.reloadData()
            
            /*
            if currentTab == .Shift {
                self.tableView.reloadData()
            } else if currentTab == .Status {
                UIView.animateAndChain(withDuration: 0.3, delay: 0.0, options: [], animations: {
                    for section in Main.sections {
                        section.reload(collapse: false)
                    }
                }, completion: nil).animate(withDuration: 0.3, animations: {
                    self.setTabs(self.tabUsersButton, silent: true)
                }, completion: nil)
            }
            */
        }
    }
    
    // MARK: - UITableView Delegate and DataSource
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch currentTab {
        case .Shift:
            switch indexPath.section {
            case 0:
                return EntriesHeaderCell.cellHeight
            default:
                return EntriesCell.cellHeight
            }
        case .Tasks:
            return 0
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        
        switch currentTab {
        case .Shift:
            return 2
        case .Tasks:
            return 1
        }
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0
    }

    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

        switch currentTab {
        case .Shift:
            switch section {
            case 0:
                return 1
            default:
                return DeviceUser.shared.sheet?.entries.count ?? 0
            }
        case .Tasks:
            return 1
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let spacer = tableView.reorder.spacerCell(for: indexPath) {
            return spacer
        }
        
        switch currentTab {
        case .Shift:
            switch indexPath.section {
            case 0:
                let cell = EntriesHeaderCell.loadNib(self.tableView)
                
                cell.populate(DeviceUser.shared.sheet)
                
                let tap = UITapGestureRecognizer(target: self, action: #selector(goBack))
                cell.arrowDownView!.addGestureRecognizer(tap)
                cell.arrowDownView!.isUserInteractionEnabled = true
                
                cell.selectionStyle = .none
                
                return cell
            default:
                if indexPath.row < DeviceUser.shared.sheet?.entries.count ?? 0 {
                    let cell = EntriesCell.loadNib(tableView)
                    
                    cell.threeDTouchAvailable = false // self.is3DTouchAvailable()
                    cell.populate(DeviceUser.shared.sheet, index: indexPath.row)
                
                    return cell
                } else {
                    return UITableViewCell.defaultCell()
                }
            }
        case .Tasks:
            return UITableViewCell.defaultCell()
        }
    }
    
    // MARK: - Other Functions
    
    @objc func setTabs(_ sender: FlatButton, silent: Bool = false) {
        
        if !silent {
            Generator.bump()
        }
        
        currentTab = MainTabs(rawValue: sender.tag) ?? .Shift
        self.prepareFab()
        
        tabAllIcon.alpha = DeviceUser.shared.sheet != nil ? 1.0 : 0.5
        if DeviceUser.shared.sheet != nil {
            tabAllButton.addTarget(self, action: #selector(setTabs), for: .touchUpInside)
        } else {
            tabAllButton.removeTargets()
        }
        
        let highlightColor = System.shared.state == .Break || System.shared.state == .Traveling || System.shared.state == .LoggedIn ? UIColor.white : Theme.shared.active.alternateIconColor
        let placeholderColor = System.shared.state == .Break ? UIColor.darkGray : Theme.shared.active.placeholderColor
        
        tabAllIcon.tintColor = currentTab == .Shift ? highlightColor : placeholderColor
        tabAllLabel.textColor = currentTab == .Shift ? highlightColor : placeholderColor
        
        tabZonesIcon.tintColor = currentTab == .Tasks ? highlightColor : placeholderColor
        tabZonesLabel.textColor = currentTab == .Tasks ? highlightColor : placeholderColor
        
        switch currentTab {
        case .Shift:
            navBar?.title = "Shift"
            break
        case .Tasks:
            navBar?.title = "Tasks"
            break
        }
        
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
    func tableView(_: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return indexPath.section == 1 && currentTab == .Shift
    }
    
    func tableView(_: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        
        guard indexPath.section == 1 && currentTab == .Shift else {
            return []
        }
        
        let deleteRowAction = UITableViewRowAction(style: UITableViewRowActionStyle.destructive, title: "Delete", handler: { _, _ in
            
            Generator.bump()
            
            PKHUD.loading()
            
            DeviceUser.shared.sheet?.entries.items[indexPath.row].delete({ success in
                guard success == true else {
                    PKHUD.failure()
                    return
                }
                
                PKHUD.success()
            })
        })
        
        let editRowAction = UITableViewRowAction(style: UITableViewRowActionStyle.default, title: "Edit", handler: { _, _ in
            
            Generator.bump()
            
            let destination = UIStoryboard.Main(identifier: "EntryEdit") as? EntryEdit
            
            destination?.sheet = DeviceUser.shared.sheet
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
        
        delay(0.25) {
            UIView.animate(withDuration: 0.25, animations: {
                self.fab.alpha = 1.0
            })
        }
    }
    
    @objc func resetRefreshControl() {
        let previous = LocationManager.shared.getStateHoldValue()
        LocationManager.shared.holdState(true)
        Commander.shared.quickLoad { (success) in
            LocationManager.shared.holdState(previous)
            self.tableView.refreshControl?.endRefreshing()
            self.tableView.reloadData()
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

    
    // MARK: - Image Picker Delegate Function
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String: Any]) {
        

        if picker.sourceType == .photoLibrary {
            
            if let image = info[UIImagePickerControllerEditedImage] as? UIImage, let user = DeviceUser.shared.user {
                
                PKHUD.loading()
                
                user.photo = UIImage.resizeImage(image: image, targetSize: CGSize(width: 200.0, height: 200.0)).base64String()
                
                user.update { success in
                    guard success == true else {
                        PKHUD.failure()
                        picker.dismiss(animated: true, completion: nil)
                        return
                    }
                    
                    let sections = Main.sections.filter({ (section) -> Bool in
                        return section.style == MainSectionStyle.User
                    })
                    
                    sections.first?.reload()
                    
                    Sidebar.refresh()
                    PKHUD.success()
                    Generator.confirm()
                    
                    picker.dismiss(animated: true, completion: nil)
                    return
                }
            } else if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
                
                let destination = UIStoryboard.Main(identifier: "PhotoCreate") as! PhotoCreate
                
                destination.editingMode = ViewingMode.Creating
                
                let imageView = UIImageView(image: image)
                imageView.contentMode = .scaleAspectFit
                
                let height: CGFloat = 1000.0
                let width: CGFloat = image.width * (1000.0 / image.height)
                
                destination.image = imageView.image?.af_imageAspectScaled(toFill: CGSize(width: width, height: height))
                destination.source = "PhotoLibrary"
                
                if let coordinate = LocationManager.shared.currentLocation?.coordinate {
                    destination.latitude = coordinate.latitude
                    destination.longitude = coordinate.longitude
                }
                
                if let sheet = DeviceUser.shared.sheet, let entry = sheet.entries.latest {
                    destination.sheet = sheet
                    destination.entry = entry
                    
                    picker.dismiss(animated: true) {
                        Presenter.push(destination, animated: true, completion: nil)
                    }
                } else {
                    LocationManager.shared.isInKnownLocation { (location) in
                        guard let location = location else {
                            picker.dismiss(animated: true) {
                                Presenter.push(destination, animated: true, completion: nil)
                            }
                            return
                        }
                        
                        destination.location = location
                        picker.dismiss(animated: true) {
                            Presenter.push(destination, animated: true, completion: nil)
                        }
                    }
                }
            } else {
                PKHUD.failure()
                picker.dismiss(animated: true, completion: nil)
            }
        } else if picker.sourceType == .camera {
        
            let destination = UIStoryboard.Main(identifier: "PhotoCreate") as! PhotoCreate
            
            destination.editingMode = ViewingMode.Creating
            guard let image = info[UIImagePickerControllerOriginalImage] as? UIImage else {
                PKHUD.failure()
                return
            }
            
            let imageView = UIImageView(image: image)
            imageView.contentMode = .scaleAspectFit
            
            let height: CGFloat = 1000.0
            let width: CGFloat = image.width * (1000.0 / image.height)
            
            destination.image = imageView.image?.af_imageAspectScaled(toFill: CGSize(width: width, height: height))
            destination.source = "Camera"
            
            if let coordinate = LocationManager.shared.currentLocation?.coordinate {
                destination.latitude = coordinate.latitude
                destination.longitude = coordinate.longitude
            }
            
            if let sheet = DeviceUser.shared.sheet, let entry = sheet.entries.latest {
                destination.sheet = sheet
                destination.entry = entry
                
                picker.dismiss(animated: true) {
                    Presenter.push(destination, animated: true, completion: nil)
                }
            } else {
                LocationManager.shared.isInKnownLocation { (location) in
                    guard let location = location else {
                        picker.dismiss(animated: true) {
                            Presenter.push(destination, animated: true, completion: nil)
                        }
                        return
                    }
                    
                    destination.location = location
                    picker.dismiss(animated: true) {
                        Presenter.push(destination, animated: true, completion: nil)
                    }
                }
            }
        }
    }
    
    // MARK: - Fab
    
    @objc func prepareFab() {
        switch System.shared.state {
        case .Off:
            prepareFabOff()
            fabState = .Off
            break
        case .Break:
            prepareFabBreak()
            fabState = .Break
            break
        case .LoggedIn:
            prepareFabLoggedIn()
            fabState = .LoggedIn
            break
        case .Traveling:
            prepareFabTraveling()
            fabState = .Traveling
            break
        case .Empty:
            prepareFabEmpty()
            fabState = .Empty
            break
        default:
            prepareFabOff()
            fabState = .Error
            break
        }
        
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
    
    func prepareFabOff() {
        fab.clear()
        
        fab.addItem(item: FloatyItem.timesheetItem(target: self, action: #selector(createTimesheet), addShortcut: true))
    }
    
    func prepareFabBreak() {
        fab.clear()
        
        fab.addItem(item: FloatyItem.entryItem(target: self, action: #selector(manualEntryCreate), addShortcut: true))
        fab.addItem(item: FloatyItem.travelItem(target: self, action: #selector(createTravelingEntry), addShortcut: true))
        fab.addItem(item: FloatyItem.endBreakItem(target: self, action: #selector(endBreakEntry), addShortcut: true))
        fab.addItem(item: FloatyItem.submitItem(target: self, action: #selector(submitTimeSheet), addShortcut: true))
    }
    
    func prepareFabLoggedIn() {
        fab.clear()
        
        fab.addItem(item: FloatyItem.entryItem(target: self, action: #selector(manualEntryCreate), addShortcut: true))
        fab.addItem(item: FloatyItem.travelItem(target: self, action: #selector(createTravelingEntry), addShortcut: true))
        fab.addItem(item: FloatyItem.breakItem(target: self, action: #selector(createBreakEntry), addShortcut: true))
        fab.addItem(item: FloatyItem.submitItem(target: self, action: #selector(submitTimeSheet), addShortcut: true))
    }
    
    func prepareFabTraveling() {
        fab.clear()
        
        fab.addItem(item: FloatyItem.entryItem(target: self, action: #selector(manualEntryCreate), addShortcut: true))
        fab.addItem(item: FloatyItem.breakItem(target: self, action: #selector(createBreakEntry), addShortcut: true))
        fab.addItem(item: FloatyItem.submitItem(target: self, action: #selector(submitTimeSheet), addShortcut: true))
    }
    
    func prepareFabEmpty() {
        fab.clear()
        
        fab.addItem(item: FloatyItem.entryItem(target: self, action: #selector(manualEntryCreate), addShortcut: true))
        fab.addItem(item: FloatyItem.travelItem(target: self, action: #selector(createTravelingEntry), addShortcut: true))
        fab.addItem(item: FloatyItem.deleteItem(target: self, action: #selector(submitTimeSheet), addShortcut: true))
    }
    
    
    @objc override func applyTheme() {
        super.applyTheme()
        
        self.view.backgroundColor = Theme.shared.active.primaryBackgroundColor
        tableView.backgroundColor = UIColor.clear
        tableView.separatorStyle = .none
        
        tableView.reorder.cellScale = 1.02
        tableView.reorder.shadowOpacity = 0.5
        tableView.reorder.shadowRadius = 20
        tableView.reorder.shadowColor = UIColor.black
        
        self.navBar?.shadowColor = UIColor.black
        self.navBar?.shadowOffset = CGSize(width: 1, height: 5)
        self.navBar?.shadowRadius = 10
        self.navBar?.shadowOpacity = 0.3
    }
    
    // MARK: - Timesheet Functions
    
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
        
        let sheet: Sheet = Sheet()
        sheet.user = Auth.shared.id
        sheet.date = date
        
        PKHUD.loading()
        
        Async.waterfall(nil, [sheet.create], end: { (error, _) in
            guard error == nil else {
                PKHUD.failure()
                return
            }
            
            PKHUD.success()
            DeviceUser.shared.sheet = sheet
            
            self.fab.close()
        })
    }
    
    
    @objc func submitTimeSheet(_ sender: UITapGestureRecognizer) {
        sender.view?.touchAnimation()
        
        delay(0.2) {
            self.fab.close()
            
            guard let sheet = DeviceUser.shared.sheet else {
                self.prepareFab()
                return
            }
            
            if sheet.entries.count == 0 {
                PKHUD.loading()
                
                sheet.delete({ success in
                    guard success == true else {
                        PKHUD.failure()
                        return
                    }
                    
                    PKHUD.success()
                })
            } else {
                let minimum = sheet.entries.latest!.start!
                let maximum = Date()
                
                let picker = ActionSheetDatePicker(title: NSLocalizedString("TimelineViewController_SelectTimesheetEndTime", comment: ""), datePickerMode: UIDatePickerMode.dateAndTime, selectedDate: maximum, minimumDate: minimum, maximumDate: maximum, target: self, action: #selector(self.commitTimesheet), cancelAction: nil, origin: self.fab)
                
                picker?.maximumDate = maximum
                picker?.minimumDate = minimum
                
                self.styleActionSheetDatePicker(picker)
                
                picker?.show()
            }
        }
    }
    
    @objc func commitTimesheet(_ date: Date) {
        let userInfo: [AnyHashable: Any] = ["end": date as Any]
        
        NotificationManager.shared.submit_timesheet.post(userInfo)
    }
    
    @objc func manualEntryCreate(_ sender: UITapGestureRecognizer) {
        sender.view?.touchAnimation()
        
        delay(0.2) {
            self.fab.close()
            
            guard System.shared.state != .Off else { return }
            
            let destination = UIStoryboard.Main(identifier: "EntryCreate") as! EntryCreate
            destination.sheet = DeviceUser.shared.sheet
            
            let navigation = UINavigationController(rootViewController: destination)
            navigation.navigationBar.isHidden = true
            
            Presenter.present(navigation, animated: true, completion: nil)
        }
    }
    
    @objc func createNewEntry(_ sender: UITapGestureRecognizer) {
        sender.view?.touchAnimation()
        
        delay(0.2) {
            self.fab.close()
            
            NotificationManager.shared.create_entry.post()
        }
    }
    
    @objc func createTravelingEntry(_ sender: UITapGestureRecognizer) {
        sender.view?.touchAnimation()
        
        delay(0.2) {
            self.fab.close()
            
            NotificationManager.shared.create_traveling_entry.post()
        }
    }
    
    @objc func createBreakEntry(_ sender: UITapGestureRecognizer) {
        sender.view?.touchAnimation()
        
        delay(0.2) {
            self.fab.close()
            
            NotificationManager.shared.create_break_entry.post()
        }
    }
    
    @objc func endBreakEntry(_ sender: UITapGestureRecognizer) {
        sender.view?.touchAnimation()
        
        PKHUD.loading()
        
        delay(0.2) {
            self.fab.close()
            
            LocationManager.shared.isInKnownLocation({ (location) in
                
                PKHUD.hide()
                
                var alert: UIAlertController?
                
                if let location = location, let name = location.name {
                    alert = UIAlertController(title: "Timeline", message: "You are coming off a break and are in the viscinity of a known location. Would you like to clock into \(name)?", preferredStyle: .actionSheet)
                    alert?.addAction(UIAlertAction(title: "Clock In", style: .default) { _ in
                        Generator.bump()
                        
                        let userInfo: JSON = [
                            "location": location as JSONObject
                        ]
                        
                        NotificationManager.shared.create_entry.post(userInfo) })
                    alert?.addAction(UIAlertAction(title: "Traveling Mode", style: .default) { _ in
                        Generator.bump()
                        NotificationManager.shared.create_traveling_entry.post() })
                    alert?.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel) { _ in
                        Generator.bump()
                        LocationManager.shared.currentLocation = nil
                        /* foo */ })
                } else {
                    alert = UIAlertController(title: "Timeline", message: "You are either not in a known location or your location can not be verified at this time. Enter Traveling Mode or manual create entry?", preferredStyle: .actionSheet)
                    
                    alert?.addAction(UIAlertAction(title: "Traveling Mode", style: .default) { _ in
                        Generator.bump()
                        NotificationManager.shared.create_traveling_entry.post() })
                    alert?.addAction(UIAlertAction(title: "Add Entry", style: .default) { _ in
                        Generator.bump()
                        self.fab.close()
                        
                        guard System.shared.state != .Off else { return }
                        
                        let destination = UIStoryboard.Main(identifier: "EntryCreate") as! EntryCreate
                        destination.sheet = DeviceUser.shared.sheet
                        
                        let navigation = UINavigationController(rootViewController: destination)
                        navigation.navigationBar.isHidden = true
                        
                        Presenter.present(navigation, animated: true, completion: nil) })
                    alert!.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel) { _ in
                        Generator.bump()
                        LocationManager.shared.currentLocation = nil
                        /* foo */ })
                }
                
                guard let _alert = alert else { return }
                
                Presenter.present(_alert, animated: true)
            })
            
            
        }
    }
    
}
