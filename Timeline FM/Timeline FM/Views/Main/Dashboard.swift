//
//  Dashboard.swift
//  Timeline FM
//
//  Created by Zachary DeGeorge on 11/15/18.
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

// MARK: - Main

class Dashboard: ViewController, UITableViewDelegate, UITableViewDataSource, SidebarSectionProtocol, FloatyDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, TableViewReorderDelegate {
    
    static var section: String { return "Dashboard" }
    
    @IBOutlet var tableView: UITableView!
    
    fileprivate var fabState: SystemState?
    @IBOutlet var fab: Floaty!
    
    var waterDropsViewTop: DropsView?
    var waterDropsViewDown: DropsView?
    
    func tableView(_ tableView: UITableView, canReorderRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    var initialLoad: Bool = true
    static var order: [MainSectionStyle] = [.User, .Location, .Entry, .Sheet]
    static var sections: [MainSectionContainer] = []
    
    // MARK: - UIViewController Overrides
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        fab.fabDelegate = self
        
        tableView.backgroundColor = UIColor.clear
        
        
        let refreshControl = UIRefreshControl()
        refreshControl.alpha = 0.0
        refreshControl.backgroundColor = UIColor.clear
        refreshControl.addTarget(self, action: #selector(resetRefreshControl), for: UIControlEvents.valueChanged)
        tableView.refreshControl = refreshControl
        tableView.reorder.delegate = self
        
        tableView.contentInset = UIEdgeInsetsMake(15.0, 0, 15.0, 0)
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false
        tableView.isScrollEnabled = true
        tableView.masksToBounds = false
        tableView.clipsToBounds = false
        
        fab.buttonImage = AssetManager.shared.compose
        fab.tintColor = UIColor.white
        fab.plusColor = UIColor.white
        fab.itemImageColor = UIColor.white
        fab.buttonColor = Color.blue.darken3
        fab.openAnimationType = .pop
        fab.isUserInteractionEnabled = true
        fab.hasShadow = true
        fab.alpha = 1.0
        
        prepareFab()
        
        MainSectionContainer.register(tableView)
        
        Notifications.shared.model_updated.observe(self, selector: #selector(modelUpdated))
        
        self.view.alpha = 0.0
        delay(0.5) {
            UIView.animate(withDuration: 0.5, animations: {
                self.view.alpha = 1.0
            }, completion: nil)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if initialLoad {
            initialLoad = false
            
            DispatchQueue.main.async {
                Dashboard.sections.first?.expanded = true
            }
        } else {
            tableView.reloadData()
        }
        
        self.styleNavBar()
        self.view.bringSubview(toFront: self.fab)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        tableView.sizeThatFits(UIScreen.main.bounds.size)
        
        fab.close()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        
        if let tableView = tableView {
            for cell in tableView.visibleCells {
                if let value = cell as? MainSectionContainer {
                    value.updates = false
                    
                    for object in value.objects {
                        object.update = false
                    }
                }
            }
        }
    }
    
    func styleNavBar(_ sender: Any? = nil) {
        
        let isBreak: Bool = System.shared.state == .Break ? true : false
        let isTraveling: Bool = System.shared.state == .Traveling ? true : false
        let isActive: Bool = System.shared.active
        
        // setBubbleAnimation(on: false)
        // setBubbleAnimation(on: isActive ? true : false)
        
        if isBreak || isTraveling {
            
            UIView.animate(withDuration: 0.0, animations: {
                self.fab.alpha = 0.0
            })
            
            UIView.transition(with: self.view, duration: 0.66, options: .curveLinear, animations: {
                if isBreak {
                    self.navBar?.background = Color.orange.darken4.withAlphaComponent(0.95)
                    
                } else if isTraveling {
                    self.navBar?.background = Color.blue.darken4.withAlphaComponent(0.95)
                }
                
                self.navBar?.leftButton.tintColor = UIColor.white
                self.navBar?.rightButton.tintColor = UIColor.white
                self.navBar?.titleLabel.textColor = UIColor.white
                
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
            
            UIView.transition(with: self.view, duration: 0.66, options: .curveLinear, animations: {
                
                super.applyTheme()
                
                self.navBar?.background = System.shared.state == .LoggedIn ? Color.green.darken4.withAlphaComponent(0.95) : Theme.shared.active.primaryBackgroundColor.withAlphaComponent(0.95)
                
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
        navBar?.title = "Dashboard"
        
        navBar?.leftImage = AssetManager.shared.menu
        navBar?.leftEnclosure = { self.menuPressed() }
        
        navBar?.rightImage = AssetManager.shared.camera
        navBar?.rightEnclosure = {
            
            guard System.shared.active == true else {
                PKHUD.message(text: "Create time sheet to enable pictures")
                PKHUD.sharedHUD.hide(afterDelay: 1.0)
                return
            }
            
            let camera = Camera(source: self)
            
            camera.PresentPhotoInput(target: self)
        }
        
        
    }
    
    func setBubbleAnimation(on: Bool) {
        
        guard on == true else {
            
            waterDropsViewTop?.removeFromSuperview()
            waterDropsViewDown?.removeFromSuperview()
            
            waterDropsViewTop = nil
            waterDropsViewDown = nil
            
            return
        }
        
        var image: UIImage?
        
        switch System.shared.state {
        case .Break:
            image = AssetManager.shared.cafeGlyph
            break
        case .Traveling:
            image = AssetManager.shared.carGlyph
            break
        case .LoggedIn:
            image = AssetManager.shared.coin
        default:
            break
        }
        
        if waterDropsViewDown == nil {
            // custom configuration
            waterDropsViewDown = DropsView(frame: self.view.frame,
                                           direction: .up,
                                           dropNum: 8,
                                           color: UIColor.white.withAlphaComponent(0.7),
                                           minDropSize: 20,
                                           maxDropSize: 30,
                                           minLength: 50.0,
                                           maxLength: 100.0,
                                           minDuration: 8,
                                           maxDuration: 12,
                                           image: image)
            
            // add animation
            waterDropsViewDown?.addAnimation()
            waterDropsViewDown?.isUserInteractionEnabled = false
            waterDropsViewDown?.alpha = 0.7
            
            self.view.addSubview(waterDropsViewDown!)
        }
        
        
        
        if let navBar = navBar, waterDropsViewTop == nil {
            // custom configuration
            waterDropsViewTop = DropsView(frame: navBar.frame,
                                          direction: .down,
                                          dropNum: 8,
                                          color: UIColor.white.withAlphaComponent(0.7),
                                          minDropSize: 20,
                                          maxDropSize: 30,
                                          minLength: navBar.frame.height / 2.0,
                                          maxLength: navBar.frame.height,
                                          minDuration: 8,
                                          maxDuration: 12,
                                          image: image)
            
            
            waterDropsViewTop?.addAnimation()
            waterDropsViewTop?.isUserInteractionEnabled = false
            
            navBar.addSubview(waterDropsViewTop!)
        }
        
        
    }
    
    override func prepareForDeinit() {
        super.prepareForDeinit()
        
        waterDropsViewTop?.removeFromSuperview()
        waterDropsViewDown?.removeFromSuperview()
        
        waterDropsViewTop = nil
        waterDropsViewDown = nil
        
        for cell in tableView?.visibleCells ?? [] {
            if let value = cell as? MainSectionContainer {
                value.updates = false
            } else if let value = cell as? EntriesHeaderCell {
                value.updates = false
            } else if let value = cell as? EntriesCell {
                value.updates = false
            }
        }
        
        for section in Dashboard.sections {
            section.expanded = false
            section.updates = false
        }
        
        Dashboard.sections.removeAll()
    }
    
    @objc func modelUpdated(_ notification: NSNotification) {
        
        guard App.shared.isLoaded == true else {
            return
        }
        
        guard let data = notification.userInfo, let update = data["update"] as? ModelUpdate, App.shared.isLoaded == true else {
            return
        }
        
        prepareFab()
        
        if update.model is Sheet {
            PKHUD.success()
            
            self.styleNavBar()
            
            UIView.animate(withDuration: 0.3, delay: 0.0, options: [], animations: {
                for section in Dashboard.sections {
                    section.reload(collapse: false)
                }
            }, completion: nil)
        }
        
        if update.model is Entry, let _entry = update.model as? Entry, _entry.sheet?.id == DeviceUser.shared.sheet?.id {
            
            delay(0.3) {
                self.styleNavBar()
            }
            
            UIView.animate(withDuration: 0.3, delay: 0.0, options: [], animations: {
                for section in Dashboard.sections {
                    section.reload(collapse: false)
                }
            }, completion: nil)
        }
        
        if update.model is Photo {
            UIView.animate(withDuration: 0.3, delay: 0.0, options: [], animations: {
                for section in Dashboard.sections {
                    section.reload(collapse: false)
                }
            }, completion: nil)
        }
    }
    
    // MARK: - UITableView Delegate and DataSource
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0
    }
    
    @objc func expandSection(_ sender: Any?) {
        if let tap = sender as? UITapGestureRecognizer, let banner = tap.view {
            
            let headers = Dashboard.sections.filter { (section) -> Bool in
                return section.style.rawValue == banner.tag
            }
            
            guard let header = headers.first, header.hasMore == true else {
                Generator.confirm()
                return
            }
            
            Generator.bump()
            
            let previous = header.expanded
            
            self.tableView.beginUpdates()
            header.expanded = previous == true ? false : true
            self.tableView.endUpdates()
            
            for header in Dashboard.sections {
                if header.expanded == false {
                    for object in header.objects {
                        object.update = false
                    }
                }
            }
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Dashboard.order.count
    }
    
    func tableView(_ tableView: UITableView, reorderRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        let item = Dashboard.order[sourceIndexPath.row]
        Dashboard.order.remove(at: sourceIndexPath.row)
        Dashboard.order.insert(item, at: destinationIndexPath.row)
        
        let cell = Dashboard.sections[sourceIndexPath.row]
        Dashboard.sections.remove(at: sourceIndexPath.row)
        Dashboard.sections.insert(cell, at: destinationIndexPath.row)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let spacer = tableView.reorder.spacerCell(for: indexPath) {
            return spacer
        }
        
        if indexPath.row >= Dashboard.sections.count {
            let cell = MainSectionContainer.loadNib(tableView)
            //cell.clipsToBounds = true
            //cell.layer.masksToBounds = true
            cell.selectionStyle = .none
            cell.banner.tag = Main.order[indexPath.row].rawValue
            cell.banner.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.expandSection)))
            cell.banner.isUserInteractionEnabled = true
            cell.expanded = false
            cell.style = Main.order[indexPath.row]
            cell.tableView = tableView
            Dashboard.sections.append(cell)
            
            return cell
        } else {
            let cell = Dashboard.sections[indexPath.row]
            cell.banner.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.expandSection)))
            cell.tableView = tableView
            return cell
        }
    }
    
    // MARK: - Other Functions
    
    func tableView(_: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return false
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        UIView.animate(withDuration: 0.25, animations: {
            self.fab.alpha = 0.0
        })
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        delay(1.0) {
            UIView.animate(withDuration: 0.25, animations: {
                self.fab.alpha = 1.0
            })
        }
    }
    
    @objc func resetRefreshControl() {
        tableView.refreshControl?.endRefreshing()
    }
    
    func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let value = cell as? MainSectionContainer {
            value.updates = false
            
            for object in value.objects {
                object.update = false
            }
        }
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let value = cell as? MainSectionContainer {
            value.updates = true
        }
    }
    
    /*
     func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
     if let target = cell as? MainSectionContainer {
     target.view.roundCorners([.topLeft, .topRight], radius: 5.0)
     target.content.roundCorners([.bottomLeft, .bottomRight], radius: 5.0)
     }
     }
     */
    
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
                    
                    let sections = Dashboard.sections.filter({ (section) -> Bool in
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
                destination.entry = DeviceUser.shared.sheet?.entries.latest
                destination.sheet = DeviceUser.shared.sheet
                destination.source = "PhotoLibrary"
                
                if let coordinate = LocationManager.shared.currentLocation?.coordinate {
                    destination.latitude = coordinate.latitude
                    destination.longitude = coordinate.longitude
                }
                
                picker.dismiss(animated: true) {
                    Presenter.push(destination, animated: true, completion: nil)
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
            destination.entry = DeviceUser.shared.sheet?.entries.latest
            destination.sheet = DeviceUser.shared.sheet
            destination.source = "Camera"
            
            if let coordinate = LocationManager.shared.currentLocation?.coordinate {
                destination.latitude = coordinate.latitude
                destination.longitude = coordinate.longitude
            }
            
            picker.dismiss(animated: true) {
                Presenter.push(destination, animated: true, completion: nil)
            }
        }
    }
    
    // MARK: - Fab
    
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
    
    @objc func createTimesheet(_ sender: UITapGestureRecognizer) {
        sender.view?.touchAnimation()
        
        PKHUD.loading()
        
        delay(0.2) {
            self.fab.close()
            
            guard System.shared.state == .Off else { return }
            
            LocationManager.shared.isInKnownLocation({ (location) in
                PKHUD.hide()
                
                guard let location = location, let name = location.name else {
                    NotificationManager.shared.create_timesheet.post()
                    return
                }
                
                let alert = NYAlertViewController()
                alert.alertViewBackgroundColor = Theme.shared.active.primaryBackgroundColor
                
                alert.title = "Timeline"
                alert.message = "You are in a known location. Would you like to create an entry at \n\(name)?"
                
                alert.titleFont = UIFont(name: DEFAULT_SYSTEM_FONT_NAME, size: alert.titleFont.pointSize + 4)
                alert.titleColor = Theme.shared.active.primaryFontColor
                
                alert.messageFont = UIFont(name: DEFAULT_SYSTEM_FONT_NAME, size: alert.messageFont.pointSize)
                alert.messageColor = Color.darkGray
                
                alert.swipeDismissalGestureEnabled = true
                alert.backgroundTapDismissalGestureEnabled = true
                
                alert.buttonColor = Color.green.darken3
                alert.destructiveButtonColor = Color.blue.darken3
                alert.cancelButtonColor = Color.red.darken3
                
                alert.buttonTitleFont = UIFont(name: DEFAULT_SYSTEM_FONT_NAME, size: alert.buttonTitleFont.pointSize - 4)
                alert.destructiveButtonTitleFont = UIFont(name: DEFAULT_SYSTEM_FONT_NAME, size: alert.destructiveButtonTitleFont.pointSize - 4)
                alert.cancelButtonTitleFont = UIFont(name: DEFAULT_SYSTEM_FONT_NAME, size: alert.cancelButtonTitleFont.pointSize - 4)
                
                
                alert.addAction(NYAlertAction(title: "Yes, create entry at this location", style: .default, handler: { _ in
                    self.dismiss(animated: true, completion: nil)
                    PKHUD.loading()
                    
                    DeviceUser.shared.sheet = Sheet()
                    DeviceUser.shared.sheet?.create({ success in
                        guard success == true else {
                            PKHUD.failure()
                            return
                        }
                        let userInfo: [AnyHashable: Any] = ["location": location as Any]
                        NotificationManager.shared.create_entry.post(userInfo)
                    })
                }))
                
                alert.addAction(NYAlertAction(title: "No, just create an empty timesheet", style: UIAlertActionStyle.destructive, handler: { _ in
                    NotificationManager.shared.create_timesheet.post()
                    self.dismiss(animated: true, completion: nil)
                }))
                
                alert.addAction(NYAlertAction(title: "Cancel, don't create a new timesheet", style: UIAlertActionStyle.cancel, handler: { _ in
                    self.dismiss(animated: true, completion: nil)
                }))
                
                Presenter.present(alert, animated: true)
                
            })
        }
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
                        NotificationManager.shared.create_entry.post() })
                    alert?.addAction(UIAlertAction(title: "Traveling Mode", style: .default) { _ in
                        Generator.bump()
                        NotificationManager.shared.create_entry.post() })
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
                        NotificationManager.shared.create_traveling_entry.post() })
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
