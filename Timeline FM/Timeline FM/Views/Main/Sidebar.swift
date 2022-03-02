//
//  SidebarViewController.swift
//  Timesheets
//
//  Created by Zachary DeGeorge on 11/3/17.
//  Copyright © 2017 Timeline Software, LLC. All rights reserved.
//

import Material
import PKHUD
import UIKit
import CoreLocation

class Sidebar: UIViewController, UITableViewDelegate, UITableViewDataSource, ThemeSupportedProtocol {
    
    var navSections: [NavigationSection] {
        return Navigator.shared.sections
    }

    var _sectionNames: [String] = [String]()
    var sectionNames: [String] {
        if _sectionNames.count == 0 {
            var array = [String](repeating: String(), count: navSections.count)
            for section in navSections {
                array[section.index] = section.title
            }

            _sectionNames.append(contentsOf: array)
        }
        return _sectionNames
    }

    var _sectionIcons: [String] = [String]()
    var sectionIcons: [String] {
        if _sectionIcons.count == 0 {
            var array = [String](repeating: String(), count: navSections.count)
            for section in navSections {
                array[section.index] = section.icon
            }

            _sectionIcons.append(contentsOf: array)
        }
        return _sectionIcons
    }

    func resetSectionNames() {
        _sectionNames.removeAll()
    }

    var activeIndex: Int? {
        didSet {
            tableView?.reloadData()
        }
    }

    @IBOutlet var tableView: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.separatorStyle = .none
        
        SidebarHeader.register(tableView)
        SidebarMenu.register(tableView)
        SidebarFooter.register(tableView)

        applyTheme()
        
        let refreshControl = UIRefreshControl()
        refreshControl.alpha = 0.5
        refreshControl.addTarget(self, action: #selector(resetRefreshControl), for: UIControlEvents.valueChanged)
        tableView.refreshControl = refreshControl

        Notifications.shared.loaded_true.observe(self, selector: #selector(self.reloadTableView))
        Theme.shared.theme_changed.observe(self, selector: #selector(applyTheme))
    }
    
    @objc func resetRefreshControl(_ refresh: UIRefreshControl) {
        
        System.shared.alert(title: "Timeline", message: "Would you like to synchronize all your data?", handler: { (alert) in
            
            refresh.endRefreshing()
            
            PKHUD.loading()
            let previous = LocationManager.shared.getStateHoldValue()
            LocationManager.shared.holdState(true)
            Commander.shared.load { (success) in
                LocationManager.shared.holdState(previous)
                guard success == true else {
                    PKHUD.failure()
                    return
                }
                
                PKHUD.success()
            }
        }) { (alert) in
            refresh.endRefreshing()
        }
    }

    /*
     @objc func updateChatUnreadIndicator() {

     DispatchQueue.main.async {

     guard let index = self.navSections["Chat"], let cell = self.tableView.cellForRow(at: IndexPath(row: index, section: 1)) as? SidebarMenuCell else {
     return
     }

     let count = min(UIApplication.shared.applicationIconBadgeNumber, 99)

     if count <= 0 {
     cell.indicatorView.alpha = 0
     cell.indicatorLabel.text = nil
     } else {
     cell.indicatorView.alpha = 0.8
     cell.indicatorLabel.text = "\(count)"
     }
     }
     }

     override func viewWillAppear(_ animated: Bool) {
     tableView.reloadData()
     self.updateChatUnreadIndicator()
     }
     
     */
    
     @objc func reloadTableView() {
        DispatchQueue.main.async {
            self.tableView.reloadSections([0], with: .automatic)
        }
     }

    override func viewWillAppear(_: Bool) {
        tableView.reloadData()
        // self.updateChatUnreadIndicator()
    }

    @objc static func refresh() {
        if let drawer = UIApplication.shared.keyWindow?.rootViewController as? NavigationDrawerController, let sidebar = drawer.leftViewController as? Sidebar {
            sidebar.tableView.reloadData()
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellnames = sectionNames
        let cellIcons = sectionIcons

        switch indexPath.section {
        case 0:
            let cell = SidebarHeader.loadNib(tableView)

            cell.populate(DeviceUser.shared.user)
            cell.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(goToProfile)))

            cell.selectionStyle = .none
            return cell
        case 1:
            let cell = SidebarMenu.loadNib(tableView)

            cell.populate(cellnames[indexPath.row], cellIcons[indexPath.row])

            if indexPath.row == Navigator.shared.index(title: Login.section) {
                cell.view.backgroundColor = UIColor(hex: "979797")
            } else if indexPath.row == activeIndex {
                cell.view.backgroundColor = UIColor(hex: "FF9500")
            } else {
                cell.view.backgroundColor = UIColor.clear
            }
            
            if indexPath.row == Navigator.shared.index(title: ViewChats.section) {
                cell.setIndicator(count: Chatrooms.shared.unreadMessages) 
            }
            
            cell.button.tag = indexPath.row
            cell.button.addTarget(self, action: #selector(goToNavSection), for: .touchUpInside)

            cell.selectionStyle = .none
            return cell
        default:
            let cell = SidebarFooter.loadNib(tableView)

            cell.populate()
            cell.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(goToAbout)))

            cell.selectionStyle = .none
            return cell
        }
    }
    
    func goToSection(section: NavigationSection, options: UIWindow.TransitionOptions? = nil) {
        Navigator.shared.goTo(section: section, options: options)
    }
    
    @objc func goToNavSection(_ sender: FlatButton) {
        Generator.bump()
        
        sender.pulse()
        
        delay(0.2, closure: {
            self.goToSection(section: self.navSections[sender.tag])
        })
    }
    
    @objc func goToProfile(_ sender: UITapGestureRecognizer) {
        Generator.bump()
        
        Shortcuts.goProfile()
        
        if let drawer = UIApplication.shared.keyWindow?.rootViewController?.navigationDrawerController {
            drawer.closeLeftView()
        }
    }
    
    @objc func goToAbout(_ sender: UITapGestureRecognizer) {
        Generator.bump()
        
        Shortcuts.goAbout()
        
        if let drawer = UIApplication.shared.keyWindow?.rootViewController?.navigationDrawerController {
            drawer.closeLeftView()
        }
    }

    func numberOfSections(in _: UITableView) -> Int {
        return 3
    }

    /* This determines the height of the expanded cell */
    func tableView(_: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.section {
        case 0:
            return 175
        case 1:
            return 50
        case 2:
            return 120
        default:
            return 0
        }
    }

    func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 1
        case 1:
            return navSections.count
        case 2:
            return 1
        default:
            return 0
        }
    }

    func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        Generator.bump()

        switch indexPath.section {
        case 0:
            Shortcuts.goProfile()
            break
        case 1:
            self.goToSection(section: navSections[indexPath.row])
            break
        case 2:
            Shortcuts.goAbout()
            break
        default:
            break
        }
    }
    
    @objc func applyTheme() {
        view.backgroundColor = Theme.shared.active.sidebarColor
        tableView.backgroundColor = Theme.shared.active.sidebarColor
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
